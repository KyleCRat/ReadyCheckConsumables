local _, RCC = ...

RCC.RaidFrameColumns = RCC.RaidFrameColumns or {}
local Columns = RCC.RaidFrameColumns

local db        = RCC.db
local Renderers = RCC.RaidFrameColumnRenderers

local GetSpellInfo = C_Spell.GetSpellInfo

local ICON_SIZE        = 26
local NAME_WIDTH       = 150
local RC_ICON_WIDTH    = 24
local TIME_WIDTH       = 30
local H_PAD            = 3
local FRAME_PAD        = 3
local DURABILITY_WIDTH = 42
local FALLBACK_SPELL_ICON = 134400  -- INV_Misc_QuestionMark

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

Columns.COLUMN_TYPE = COLUMN_TYPE
Columns.DATA_SOURCE = DATA_SOURCE
Columns.RULES = {
    expireWarnSeconds   = 600, -- 10 minutes
    noDuration          = 0,
    durabilityThreshold = 50,
}

local CREATE_CELL_BY_COLUMN_TYPE = {
    [COLUMN_TYPE.TIMED]      = Renderers.TIMED.CreateCell,
    [COLUMN_TYPE.ICON]       = Renderers.ICON.CreateCell,
    [COLUMN_TYPE.RAID_BUFF]  = Renderers.RAID_BUFF.CreateCell,
    [COLUMN_TYPE.DURABILITY] = Renderers.DURABILITY.CreateCell,
}

local RENDER_CELL_BY_DATA_SOURCE = {
    [DATA_SOURCE.AURA] = {
        [COLUMN_TYPE.TIMED] = Renderers.TIMED.RenderAuraCell,
        [COLUMN_TYPE.ICON]  = Renderers.ICON.RenderAuraCell,
    },
    [DATA_SOURCE.OIL] = {
        [COLUMN_TYPE.TIMED] = Renderers.TIMED.RenderOilCell,
    },
    [DATA_SOURCE.RAID_BUFF] = {
        [COLUMN_TYPE.RAID_BUFF] = Renderers.RAID_BUFF.RenderCell,
    },
    [DATA_SOURCE.DURABILITY] = {
        [COLUMN_TYPE.DURABILITY] = Renderers.DURABILITY.RenderCell,
    },
}

local RAID_BUFF_COUNT = #db.raidBuffDefs
local ICON_STEP       = ICON_SIZE + H_PAD

local READY_ICON_CENTER_X = RC_ICON_WIDTH / 2
local NAME_X              = RC_ICON_WIDTH + H_PAD
local FOOD_ICON_X         = NAME_X + NAME_WIDTH + H_PAD + TIME_WIDTH
local FOOD_TIME_X         = FOOD_ICON_X - TIME_WIDTH
local FLASK_ICON_X        = FOOD_ICON_X + ICON_STEP + TIME_WIDTH
local FLASK_TIME_X        = FLASK_ICON_X - TIME_WIDTH
local OIL_ICON_X          = FLASK_ICON_X + ICON_STEP + TIME_WIDTH
local OIL_TIME_X          = OIL_ICON_X - TIME_WIDTH
local AUGMENT_ICON_X      = OIL_ICON_X + ICON_STEP
local VANTUS_ICON_X       = AUGMENT_ICON_X + ICON_STEP

local function getRaidBuffX(raidBuffIndex)
    return VANTUS_ICON_X + raidBuffIndex * ICON_STEP
end

local RAID_BUFF_X = {}

for raidBuffIndex = 1, RAID_BUFF_COUNT do
    RAID_BUFF_X[raidBuffIndex] = getRaidBuffX(raidBuffIndex)
end

local DURABILITY_X       = getRaidBuffX(RAID_BUFF_COUNT) + ICON_STEP
local DURABILITY_TITLE_X = DURABILITY_X + (DURABILITY_WIDTH - ICON_SIZE) / 2

local FRAME_WIDTH = FRAME_PAD
    + RC_ICON_WIDTH + H_PAD
    + NAME_WIDTH + H_PAD
    + TIME_WIDTH + ICON_SIZE + H_PAD      -- food
    + TIME_WIDTH + ICON_SIZE + H_PAD      -- flask
    + TIME_WIDTH + ICON_SIZE + H_PAD      -- oil
    + ICON_SIZE + H_PAD                   -- augment
    + ICON_SIZE + H_PAD                   -- vantus
    + ICON_STEP * RAID_BUFF_COUNT         -- raid buffs
    + DURABILITY_WIDTH + H_PAD
    + FRAME_PAD

local LAYOUT_X = {
    readyIconCenter = READY_ICON_CENTER_X,
    name            = NAME_X,
    food            = FOOD_ICON_X,
    foodTime        = FOOD_TIME_X,
    flask           = FLASK_ICON_X,
    flaskTime       = FLASK_TIME_X,
    oil             = OIL_ICON_X,
    oilTime         = OIL_TIME_X,
    augment         = AUGMENT_ICON_X,
    vantus          = VANTUS_ICON_X,
    raidBuff        = RAID_BUFF_X,
    durability      = DURABILITY_X,
}

--------------------------------------------------------------------------------
--- Shared helpers
--------------------------------------------------------------------------------

local function getColumnData(member, column)
    return member.columnData and member.columnData[column.key]
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

local function isTimedDataBad(data, rules)
    if not data or not data.has then
        return true
    end

    if not data.time or data.time == rules.noDuration then
        return false
    end

    return data.time < rules.expireWarnSeconds
end

--------------------------------------------------------------------------------
--- Food Column
--------------------------------------------------------------------------------

local function createFoodData()
    return {
        has    = false,
        time   = 0,
        auraID = nil,
        iconID = nil,
    }
end

local function refreshFoodDisplayData(data, rules)
    -- Show Eating/Drinking while the real Well Fed state still needs refresh.
    local displayData = data.wellFed
    local isEating = false

    if data.eating.has and isTimedDataBad(data.wellFed, rules) then
        displayData = data.eating
        isEating = true
    end

    data.has      = displayData.has
    data.time     = displayData.time
    data.auraID   = displayData.auraID
    data.iconID   = displayData.iconID
    data.isEating = isEating
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

    data.wellFed = data.wellFed or createFoodData()
    data.eating  = data.eating or createFoodData()

    if iconID and db.eatingIconIDs[iconID] then
        setTimedAuraData(data.eating, aura, scanContext.remaining)
    else
        setTimedAuraData(data.wellFed, aura, scanContext.remaining)
    end

    refreshFoodDisplayData(data, scanContext.rules)
end

local function isFoodBad(member, context, column)
    local data = getColumnData(member, column)

    if data and data.wellFed then
        return isTimedDataBad(data.wellFed, context.rules)
    end

    return isTimedDataBad(data, context.rules)
end

local foodColumn = {
    columnType   = COLUMN_TYPE.TIMED,
    dataSource   = DATA_SOURCE.AURA,
    key          = "food",
    timeX        = FOOD_TIME_X,
    iconX        = FOOD_ICON_X,
    titleX       = FOOD_ICON_X,
    iconID       = db.food_icon_id,
    label        = "Food: Missing",
    CreateData   = createFoodData,
    CollectAura  = collectFoodAura,
    IsBad        = isFoodBad,
}

--------------------------------------------------------------------------------
--- Flask Column
--------------------------------------------------------------------------------

local function createFlaskData()
    return {
        has    = false,
        time   = 0,
        auraID = nil,
        iconID = nil,
    }
end

local function collectFlaskAura(data, aura, scanContext)
    local spellID = aura.spellId

    if not spellID or data.has or not db.flaskBuffIDs[spellID] then
        return
    end

    setTimedAuraData(data, aura, scanContext.remaining)
end

local function isFlaskBad(member, context, column)
    return isTimedDataBad(getColumnData(member, column), context.rules)
end

local flaskColumn = {
    columnType   = COLUMN_TYPE.TIMED,
    dataSource   = DATA_SOURCE.AURA,
    key          = "flask",
    timeX        = FLASK_TIME_X,
    iconX        = FLASK_ICON_X,
    titleX       = FLASK_ICON_X,
    iconID       = db.flask_icon_id,
    label        = "Flask: Missing",
    CreateData   = createFlaskData,
    CollectAura  = collectFlaskAura,
    IsBad        = isFlaskBad,
}

--------------------------------------------------------------------------------
--- Weapon Oil Column
--------------------------------------------------------------------------------

local function createOilData()
    return {
        has    = false,
        time   = nil,
        itemID = nil,
    }
end

local function syncOilData(data, member, context)
    local playerKey = member.key

    if not playerKey then
        data.has    = false
        data.time   = nil
        data.itemID = nil

        return
    end

    local entry = context.shared.oilData[playerKey]
    local time = entry and entry.time

    data.has    = time and time > 0 or false
    data.time   = time
    data.itemID = entry and entry.item or nil
end

local function isOilBad(member, context, column)
    local data = getColumnData(member, column)
    local time = data and data.time

    if time == nil or time == -1 then
        return false
    end

    return time == 0 or time < context.rules.expireWarnSeconds
end

local oilColumn = {
    columnType   = COLUMN_TYPE.TIMED,
    dataSource   = DATA_SOURCE.OIL,
    key          = "oil",
    timeX        = OIL_TIME_X,
    iconX        = OIL_ICON_X,
    titleX       = OIL_ICON_X,
    iconID       = db.weapon_enchant_icon_id,
    label        = "Weapon Oil: Unknown",
    CreateData   = createOilData,
    SyncData     = syncOilData,
    IsBad        = isOilBad,
}

--------------------------------------------------------------------------------
--- Augment Rune Column
--------------------------------------------------------------------------------

local function createAugmentData()
    return {
        has    = false,
        auraID = nil,
        iconID = nil,
    }
end

local function collectAugmentAura(data, aura)
    local spellID = aura.spellId

    if not spellID or data.has or not db.augmentBuffIDs[spellID] then
        return
    end

    setIconAuraData(data, aura)
end

local function isAugmentBad(member, context, column)
    local data = getColumnData(member, column)

    return not data or not data.has
end

local augmentColumn = {
    columnType   = COLUMN_TYPE.ICON,
    dataSource   = DATA_SOURCE.AURA,
    key          = "augment",
    iconX        = AUGMENT_ICON_X,
    titleX       = AUGMENT_ICON_X,
    iconID       = db.augment_icon_id,
    label        = "Augment Rune: Missing",
    CreateData   = createAugmentData,
    CollectAura  = collectAugmentAura,
    IsBad        = isAugmentBad,
}

--------------------------------------------------------------------------------
--- Vantus Rune Column
--------------------------------------------------------------------------------

local function createVantusData()
    return {
        has    = false,
        auraID = nil,
        iconID = nil,
    }
end

local function collectVantusAura(data, aura)
    local spellID = aura.spellId

    if not spellID or data.has or not db.vantusBuffIDs[spellID] then
        return
    end

    setIconAuraData(data, aura)
end

local function isVantusBad(member, context, column)
    local data = getColumnData(member, column)

    return not data or not data.has
end

local vantusColumn = {
    columnType   = COLUMN_TYPE.ICON,
    dataSource   = DATA_SOURCE.AURA,
    key          = "vantus",
    iconX        = VANTUS_ICON_X,
    titleX       = VANTUS_ICON_X,
    iconID       = db.vantus_icon_id,
    label        = "Vantus Rune: Missing",
    CreateData   = createVantusData,
    CollectAura  = collectVantusAura,
    IsBad        = isVantusBad,
}

--------------------------------------------------------------------------------
--- Raid Buff Columns
--------------------------------------------------------------------------------

local function createRaidBuffData()
    return {
        has    = false,
        auraID = nil,
    }
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

local function isRaidBuffBad(member, context, column)
    local data = getColumnData(member, column)

    return not data or not data.has
end

local function getRaidBuffIconID(spellID)
    local info = spellID and GetSpellInfo(spellID)

    return info and info.iconID or FALLBACK_SPELL_ICON
end

local function createRaidBuffColumn(raidBuffIndex)
    local buffDef = db.raidBuffDefs[raidBuffIndex]
    local spellID = buffDef[3]

    return {
        columnType         = COLUMN_TYPE.RAID_BUFF,
        dataSource         = DATA_SOURCE.RAID_BUFF,
        key                = "raidBuff" .. raidBuffIndex,
        index              = raidBuffIndex,
        iconX              = RAID_BUFF_X[raidBuffIndex],
        titleX             = RAID_BUFF_X[raidBuffIndex],
        iconID             = getRaidBuffIconID(spellID),
        spellID            = spellID,
        altSpellID         = buffDef[4],
        equivalentSpellIDs = buffDef[5],
        CreateData         = createRaidBuffData,
        CollectAura        = collectRaidBuffAura,
        IsBad              = isRaidBuffBad,
    }
end

--------------------------------------------------------------------------------
--- Durability Column
--------------------------------------------------------------------------------

local function createDurabilityData()
    return {
        has     = false,
        percent = nil,
    }
end

local function syncDurabilityData(data, member, context)
    local playerKey = member.key

    if not playerKey then
        data.has     = false
        data.percent = nil

        return
    end

    local percent = context.shared.durabilityData[playerKey]

    data.has     = percent ~= nil
    data.percent = percent
end

local function isDurabilityBad(member, context, column)
    local data = getColumnData(member, column)
    local pct = data and data.percent

    if not pct then
        return false
    end

    return pct <= context.rules.durabilityThreshold
end

local durabilityColumn = {
    columnType = COLUMN_TYPE.DURABILITY,
    dataSource = DATA_SOURCE.DURABILITY,
    key        = "durability",
    textX      = DURABILITY_X,
    titleX     = DURABILITY_TITLE_X,
    CreateData = createDurabilityData,
    SyncData   = syncDurabilityData,
    IsBad      = isDurabilityBad,
}

--------------------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------------------

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

function Columns.CreateCell(row, column, layout, options)
    local createCell = CREATE_CELL_BY_COLUMN_TYPE[column.columnType]

    if not createCell then
        error("Raid frame column has no cell creator: " .. tostring(column.key), 2)
    end

    createCell(row, column, layout, options)
end

function Columns.RenderCell(row, member, column, context)
    local renderers = RENDER_CELL_BY_DATA_SOURCE[column.dataSource]
    local renderCell = renderers and renderers[column.columnType]

    if not renderCell then
        error("Raid frame column has no renderer: " .. tostring(column.key), 2)
    end

    renderCell(row, member, column, context)
end

function Columns.ScanUnitData(unit, now, layout, context)
    local columnData = createColumnData(layout)
    local rules = context.rules
    local scanContext = {
        remaining = rules.noDuration,
        rules     = rules,
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
                or rules.noDuration

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
    local columns = {
        foodColumn,
        flaskColumn,
        oilColumn,
        augmentColumn,
        vantusColumn,
    }

    for raidBuffIndex = 1, RAID_BUFF_COUNT do
        columns[#columns + 1] = createRaidBuffColumn(raidBuffIndex)
    end

    columns[#columns + 1] = durabilityColumn

    return {
        raidBuffCount   = RAID_BUFF_COUNT,
        frameWidth      = FRAME_WIDTH,
        framePad        = FRAME_PAD,
        iconSize        = ICON_SIZE,
        rcIconWidth     = RC_ICON_WIDTH,
        nameWidth       = NAME_WIDTH,
        timeWidth       = TIME_WIDTH,
        durabilityWidth = DURABILITY_WIDTH,
        x               = LAYOUT_X,
        columns         = columns,
    }
end
