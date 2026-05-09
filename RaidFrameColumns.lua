local _, RCC = ...

RCC.RaidFrameColumns = RCC.RaidFrameColumns or {}
local Columns = RCC.RaidFrameColumns

local F = RCC.F
local db = RCC.db

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

local function isTimedAuraBad(member, context, column)
    local auras = member.auras
    local time = auras[column.auraTimeField]

    return not auras[column.auraHasField]
        or (time ~= context.noDuration
            and time < context.expireWarnSeconds)
end

local function isOilBad(member, context, column)
    local playerKey = member.key or F.fullName(member.name)
    local entries = context[column.contextField]
    local entry = entries and entries[playerKey]
    local time = entry and entry.time

    if time == nil or time == -1 then
        return false
    end

    return time == 0 or time < context.expireWarnSeconds
end

local function isIconAuraBad(member, context, column)
    return not member.auras[column.auraHasField]
end

local function isRaidBuffBad(member, context, column)
    local auraID = member.auras.raidBuff[column.index]

    return not auraID or auraID == false
end

local function isDurabilityBad(member, context, column)
    local playerKey = member.key or F.fullName(member.name)
    local entries = context[column.contextField]
    local pct = entries and entries[playerKey]

    if not pct then
        return false
    end

    return pct < context.durabilityThreshold
end

local function deriveColumnBuckets(columns)
    local timedColumns = {}
    local iconColumns = {}
    local raidBuffColumns = {}

    for columnIndex = 1, #columns do
        local column = columns[columnIndex]

        if column.columnType == COLUMN_TYPE.TIMED then
            timedColumns[#timedColumns + 1] = column
        elseif column.columnType == COLUMN_TYPE.ICON then
            iconColumns[#iconColumns + 1] = column
        elseif column.columnType == COLUMN_TYPE.RAID_BUFF then
            raidBuffColumns[#raidBuffColumns + 1] = column
        end
    end

    return timedColumns, iconColumns, raidBuffColumns
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
            auraHasField  = "hasFood",
            auraTimeField = "foodTime",
            auraIconField = "foodIconID",
            auraIDField   = "foodAuraID",
            timeField     = "foodTime",
            iconField     = "foodIcon",
            overlayField  = "foodOverlay",
            timeX         = x.foodTime,
            iconX         = x.food,
            titleX        = x.food,
            iconID        = db.food_icon_id,
            label         = "Food: Missing",
            IsBad         = isTimedAuraBad,
        },
        {
            columnType    = COLUMN_TYPE.TIMED,
            dataSource    = DATA_SOURCE.AURA,
            key           = "flask",
            auraHasField  = "hasFlask",
            auraTimeField = "flaskTime",
            auraIconField = "flaskIconID",
            auraIDField   = "flaskAuraID",
            timeField     = "flaskTime",
            iconField     = "flaskIcon",
            overlayField  = "flaskOverlay",
            timeX         = x.flaskTime,
            iconX         = x.flask,
            titleX        = x.flask,
            iconID        = db.flask_icon_id,
            label         = "Flask: Missing",
            IsBad         = isTimedAuraBad,
        },
        {
            columnType   = COLUMN_TYPE.TIMED,
            dataSource   = DATA_SOURCE.OIL,
            key          = "oil",
            contextField = "oilData",
            timeField    = "oilTime",
            iconField    = "oilIcon",
            overlayField = "oilOverlay",
            timeX        = x.oilTime,
            iconX        = x.oil,
            titleX       = x.oil,
            iconID       = db.weapon_enchant_icon_id,
            label        = "Weapon Oil: Unknown",
            IsBad        = isOilBad,
        },
        {
            columnType    = COLUMN_TYPE.ICON,
            dataSource    = DATA_SOURCE.AURA,
            key           = "augment",
            auraHasField  = "hasAugment",
            auraIconField = "augmentIconID",
            auraIDField   = "augmentAuraID",
            iconField     = "augmentIcon",
            overlayField  = "augmentOverlay",
            iconX         = x.augment,
            titleX        = x.augment,
            iconID        = db.augment_icon_id,
            label         = "Augment Rune: Missing",
            IsBad         = isIconAuraBad,
        },
        {
            columnType    = COLUMN_TYPE.ICON,
            dataSource    = DATA_SOURCE.AURA,
            key           = "vantus",
            auraHasField  = "hasVantus",
            auraIconField = "vantusIconID",
            auraIDField   = "vantusAuraID",
            iconField     = "vantusIcon",
            overlayField  = "vantusOverlay",
            iconX         = x.vantus,
            titleX        = x.vantus,
            iconID        = db.vantus_icon_id,
            label         = "Vantus Rune: Missing",
            IsBad         = isIconAuraBad,
        },
    }

    for raidBuffIndex = 1, raidBuffCount do
        columns[#columns + 1] = {
            columnType = COLUMN_TYPE.RAID_BUFF,
            dataSource = DATA_SOURCE.RAID_BUFF,
            key        = "raidBuff" .. raidBuffIndex,
            index      = raidBuffIndex,
            iconX      = x.raidBuff[raidBuffIndex],
            titleX     = x.raidBuff[raidBuffIndex],
            spellID    = db.raidBuffDefs[raidBuffIndex][3],
            IsBad      = isRaidBuffBad,
        }
    end

    columns[#columns + 1] = {
        columnType   = COLUMN_TYPE.DURABILITY,
        dataSource   = DATA_SOURCE.DURABILITY,
        key          = "durability",
        contextField = "durabilityData",
        titleX       = x.durability + (DURABILITY_WIDTH - ICON_SIZE) / 2,
        IsBad        = isDurabilityBad,
    }

    local timedColumns, iconColumns, raidBuffColumns = deriveColumnBuckets(columns)

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
        timedColumns    = timedColumns,
        iconColumns     = iconColumns,
        raidBuffColumns = raidBuffColumns,
    }
end
