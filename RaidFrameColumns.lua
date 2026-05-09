local _, RCC = ...

RCC.RaidFrameColumns = RCC.RaidFrameColumns or {}
local Columns = RCC.RaidFrameColumns

local db        = RCC.db
local Renderers = RCC.RaidFrameColumnRenderers

local ICON_SIZE        = 26
local NAME_WIDTH       = 150
local RC_ICON_WIDTH    = 24
local TIME_WIDTH       = 30
local H_PAD            = 3
local FRAME_PAD        = 3
local DURABILITY_WIDTH = 42

local COLUMN_TYPE = {
    TIMED      = "timed",
    ICON       = "icon",
    RAID_BUFF  = "raidBuff",
    DURABILITY = "durability",
}

local DATA_SOURCE = {
    AURA       = "aura",
    OIL        = "oil",
    RAID_BUFF  = "raidBuff",
    DURABILITY = "durability",
}

local function getColumnData(member, column)
    return member.columnData and member.columnData[column.key]
end

local function isTimedAuraBad(member, context, column)
    local data = getColumnData(member, column)

    if not data or not data.has then
        return true
    end

    if not data.time or data.time == context.noDuration then
        return false
    end

    return data.time < context.expireWarnSeconds
end

local function isOilBad(member, context, column)
    local data = getColumnData(member, column)
    local time = data and data.time

    if time == nil or time == -1 then
        return false
    end

    return time == 0 or time < context.expireWarnSeconds
end

local function isIconAuraBad(member, context, column)
    local data = getColumnData(member, column)

    return not data or not data.has
end

local function isRaidBuffBad(member, context, column)
    local data = getColumnData(member, column)

    return not data or not data.has
end

local function isDurabilityBad(member, context, column)
    local data = getColumnData(member, column)
    local pct = data and data.percent

    if not pct then
        return false
    end

    return pct < context.durabilityThreshold
end

local function createTimedAuraData()
    return {
        has    = false,
        time   = 0,
        auraID = nil,
        iconID = nil,
    }
end

local function createIconAuraData()
    return {
        has    = false,
        auraID = nil,
        iconID = nil,
    }
end

local function createRaidBuffData()
    return {
        has    = false,
        auraID = nil,
    }
end

local function createOilData()
    return {
        has    = false,
        time   = nil,
        itemID = nil,
    }
end

local function createDurabilityData()
    return {
        has     = false,
        percent = nil,
    }
end

local function setTimedAuraData(data, aura, remaining)
    data.has    = true
    data.time   = remaining
    data.auraID = aura.auraInstanceID
    data.iconID = aura.icon
end

local function setIconAuraData(data, aura)
    data.has    = true
    data.auraID = aura.auraInstanceID
    data.iconID = aura.icon
end

local function collectFoodAura(data, aura, scanContext)
    local spellID = aura.spellId
    local iconID = aura.icon

    if not spellID and not iconID then
        return
    end

    if not (spellID and db.foodBuffIDs[spellID])
        and not (iconID and db.foodIconIDs[iconID])
    then
        return
    end

    if iconID and db.eatingIconIDs[iconID] then
        data.isEating = true
        setTimedAuraData(data, aura, scanContext.remaining)
    elseif not data.isEating then
        setTimedAuraData(data, aura, scanContext.remaining)
    end
end

local function collectFlaskAura(data, aura, scanContext)
    local spellID = aura.spellId

    if not spellID or data.has or not db.flaskBuffIDs[spellID] then
        return
    end

    setTimedAuraData(data, aura, scanContext.remaining)
end

local function collectAugmentAura(data, aura)
    local spellID = aura.spellId

    if not spellID or data.has or not db.augmentBuffIDs[spellID] then
        return
    end

    setIconAuraData(data, aura)
end

local function collectVantusAura(data, aura)
    local spellID = aura.spellId

    if not spellID or data.has or not db.vantusBuffIDs[spellID] then
        return
    end

    setIconAuraData(data, aura)
end

local function collectRaidBuffAura(data, aura, scanContext, column)
    local spellID = aura.spellId

    if not spellID or data.has then
        return
    end

    if spellID == column.spellID
        or (column.altSpellID and spellID == column.altSpellID)
        or (column.equivalentSpellIDs and column.equivalentSpellIDs[spellID])
    then
        data.has = true
        data.auraID = aura.auraInstanceID or true
    end
end

local function syncOilData(data, member, context)
    local playerKey = member.key

    if not playerKey then
        data.has    = false
        data.time   = nil
        data.itemID = nil

        return
    end

    local entry = context.oilData[playerKey]
    local time = entry and entry.time

    data.has    = time and time > 0 or false
    data.time   = time
    data.itemID = entry and entry.item or nil
end

local function syncDurabilityData(data, member, context)
    local playerKey = member.key

    if not playerKey then
        data.has     = false
        data.percent = nil

        return
    end

    local percent = context.durabilityData[playerKey]

    data.has     = percent ~= nil
    data.percent = percent
end

local function createColumnData(layout)
    local columnData = {}

    for columnIndex = 1, #layout.columns do
        local column = layout.columns[columnIndex]

        if column.CreateData then
            columnData[column.key] = column.CreateData(column)
        end
    end

    return columnData
end

function Columns.CreateColumnData(layout)
    return createColumnData(layout)
end

function Columns.ScanUnitData(unit, now, layout, context)
    local columnData = createColumnData(layout)
    local scanContext = {
        remaining = context.noDuration,
    }

    for auraIndex = 1, 60 do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, auraIndex, "HELPFUL")

        if not aura then
            break
        end

        if not issecretvalue(aura.spellId) then
            local expiry = aura.expirationTime

            scanContext.remaining = (expiry and expiry > 0)
                and (expiry - now)
                or context.noDuration

            for columnIndex = 1, #layout.columns do
                local column = layout.columns[columnIndex]

                if column.CollectAura then
                    column.CollectAura(
                        columnData[column.key],
                        aura,
                        scanContext,
                        column
                    )
                end
            end
        end
    end

    return columnData
end

function Columns.SyncExternalData(member, layout, context)
    if not member then
        return
    end

    member.columnData = member.columnData or createColumnData(layout)

    for columnIndex = 1, #layout.columns do
        local column = layout.columns[columnIndex]

        if column.SyncData then
            local data = member.columnData[column.key]

            if not data then
                data = column.CreateData(column)
                member.columnData[column.key] = data
            end

            column.SyncData(data, member, context, column)
        end
    end
end

function Columns.CreateLayout()
    local raidBuffCount = #db.raidBuffDefs

    local frameWidth = FRAME_PAD
        + RC_ICON_WIDTH + H_PAD
        + NAME_WIDTH + H_PAD
        + TIME_WIDTH + ICON_SIZE + H_PAD       -- food
        + TIME_WIDTH + ICON_SIZE + H_PAD       -- flask
        + TIME_WIDTH + ICON_SIZE + H_PAD       -- oil
        + ICON_SIZE + H_PAD                    -- augment
        + ICON_SIZE + H_PAD                    -- vantus
        + (ICON_SIZE + H_PAD) * raidBuffCount  -- raid buffs
        + DURABILITY_WIDTH + H_PAD
        + FRAME_PAD

    local x = {
        raidBuff = {},
    }

    x.readyIconCenter = RC_ICON_WIDTH / 2
    x.name            = RC_ICON_WIDTH + H_PAD
    x.food            = RC_ICON_WIDTH + H_PAD + NAME_WIDTH + H_PAD + TIME_WIDTH
    x.foodTime        = x.food - TIME_WIDTH
    x.flask           = x.food + ICON_SIZE + H_PAD + TIME_WIDTH
    x.flaskTime       = x.flask - TIME_WIDTH
    x.oil             = x.flask + ICON_SIZE + H_PAD + TIME_WIDTH
    x.oilTime         = x.oil - TIME_WIDTH
    x.augment         = x.oil + ICON_SIZE + H_PAD
    x.vantus          = x.augment + ICON_SIZE + H_PAD

    for raidBuffIndex = 1, raidBuffCount do
        x.raidBuff[raidBuffIndex] = x.vantus
            + raidBuffIndex * (ICON_SIZE + H_PAD)
    end

    x.durability = x.raidBuff[raidBuffCount] + ICON_SIZE + H_PAD

    local columns = {
        {
            columnType    = COLUMN_TYPE.TIMED,
            dataSource    = DATA_SOURCE.AURA,
            key           = "food",
            timeField     = "foodTime",
            iconField     = "foodIcon",
            overlayField  = "foodOverlay",
            timeX         = x.foodTime,
            iconX         = x.food,
            titleX        = x.food,
            iconID        = db.food_icon_id,
            label         = "Food: Missing",
            CreateData    = createTimedAuraData,
            CollectAura   = collectFoodAura,
            CreateCell    = Renderers.TIMED.CreateCell,
            RenderCell    = Renderers.TIMED.RenderAuraCell,
            IsBad         = isTimedAuraBad,
        },
        {
            columnType    = COLUMN_TYPE.TIMED,
            dataSource    = DATA_SOURCE.AURA,
            key           = "flask",
            timeField     = "flaskTime",
            iconField     = "flaskIcon",
            overlayField  = "flaskOverlay",
            timeX         = x.flaskTime,
            iconX         = x.flask,
            titleX        = x.flask,
            iconID        = db.flask_icon_id,
            label         = "Flask: Missing",
            CreateData    = createTimedAuraData,
            CollectAura   = collectFlaskAura,
            CreateCell    = Renderers.TIMED.CreateCell,
            RenderCell    = Renderers.TIMED.RenderAuraCell,
            IsBad         = isTimedAuraBad,
        },
        {
            columnType   = COLUMN_TYPE.TIMED,
            dataSource   = DATA_SOURCE.OIL,
            key          = "oil",
            timeField    = "oilTime",
            iconField    = "oilIcon",
            overlayField = "oilOverlay",
            timeX        = x.oilTime,
            iconX        = x.oil,
            titleX       = x.oil,
            iconID       = db.weapon_enchant_icon_id,
            label        = "Weapon Oil: Unknown",
            CreateData   = createOilData,
            SyncData     = syncOilData,
            CreateCell   = Renderers.TIMED.CreateCell,
            RenderCell   = Renderers.TIMED.RenderOilCell,
            IsBad        = isOilBad,
        },
        {
            columnType    = COLUMN_TYPE.ICON,
            dataSource    = DATA_SOURCE.AURA,
            key           = "augment",
            iconField     = "augmentIcon",
            overlayField  = "augmentOverlay",
            iconX         = x.augment,
            titleX        = x.augment,
            iconID        = db.augment_icon_id,
            label         = "Augment Rune: Missing",
            CreateData    = createIconAuraData,
            CollectAura   = collectAugmentAura,
            CreateCell    = Renderers.ICON.CreateCell,
            RenderCell    = Renderers.ICON.RenderAuraCell,
            IsBad         = isIconAuraBad,
        },
        {
            columnType    = COLUMN_TYPE.ICON,
            dataSource    = DATA_SOURCE.AURA,
            key           = "vantus",
            iconField     = "vantusIcon",
            overlayField  = "vantusOverlay",
            iconX         = x.vantus,
            titleX        = x.vantus,
            iconID        = db.vantus_icon_id,
            label         = "Vantus Rune: Missing",
            CreateData    = createIconAuraData,
            CollectAura   = collectVantusAura,
            CreateCell    = Renderers.ICON.CreateCell,
            RenderCell    = Renderers.ICON.RenderAuraCell,
            IsBad         = isIconAuraBad,
        },
    }

    for raidBuffIndex = 1, raidBuffCount do
        local buffDef = db.raidBuffDefs[raidBuffIndex]

        columns[#columns + 1] = {
            columnType         = COLUMN_TYPE.RAID_BUFF,
            dataSource         = DATA_SOURCE.RAID_BUFF,
            key                = "raidBuff" .. raidBuffIndex,
            index              = raidBuffIndex,
            iconX              = x.raidBuff[raidBuffIndex],
            titleX             = x.raidBuff[raidBuffIndex],
            spellID            = buffDef[3],
            altSpellID         = buffDef[4],
            equivalentSpellIDs = buffDef[5],
            CreateData         = createRaidBuffData,
            CollectAura        = collectRaidBuffAura,
            CreateCell         = Renderers.RAID_BUFF.CreateCell,
            RenderCell         = Renderers.RAID_BUFF.RenderCell,
            IsBad              = isRaidBuffBad,
        }
    end

    columns[#columns + 1] = {
        columnType   = COLUMN_TYPE.DURABILITY,
        dataSource   = DATA_SOURCE.DURABILITY,
        key          = "durability",
        textField    = "durabilityText",
        textX        = x.durability,
        titleX       = x.durability + (DURABILITY_WIDTH - ICON_SIZE) / 2,
        CreateData   = createDurabilityData,
        SyncData     = syncDurabilityData,
        CreateCell   = Renderers.DURABILITY.CreateCell,
        RenderCell   = Renderers.DURABILITY.RenderCell,
        IsBad        = isDurabilityBad,
    }

    return {
        raidBuffCount   = raidBuffCount,
        frameWidth      = frameWidth,
        framePad        = FRAME_PAD,
        iconSize        = ICON_SIZE,
        rcIconWidth     = RC_ICON_WIDTH,
        nameWidth       = NAME_WIDTH,
        timeWidth       = TIME_WIDTH,
        durabilityWidth = DURABILITY_WIDTH,
        x               = x,
        columns         = columns,
    }
end
