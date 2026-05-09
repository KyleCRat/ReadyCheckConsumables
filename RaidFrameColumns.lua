local _, RCC = ...

RCC.RaidFrameColumns = RCC.RaidFrameColumns or {}
local Columns = RCC.RaidFrameColumns

local db = RCC.db

function Columns.CreateLayout(options)
    local iconSize        = options.iconSize
    local rcIconWidth     = options.rcIconWidth
    local nameWidth       = options.nameWidth
    local timeWidth       = options.timeWidth
    local durabilityWidth = options.durabilityWidth
    local hPad            = options.hPad
    local framePad        = options.framePad
    local raidBuffCount   = #db.raidBuffDefs

    local col = {
        FOOD       = 1,
        FLASK      = 2,
        OIL        = 3,
        AUGMENT    = 4,
        VANTUS     = 5,
        DURABILITY = 5 + raidBuffCount + 1,
    }

    local frameWidth = framePad
        + rcIconWidth + hPad
        + nameWidth + hPad
        + timeWidth + iconSize + hPad  -- food
        + timeWidth + iconSize + hPad  -- flask
        + timeWidth + iconSize + hPad  -- oil
        + (iconSize + hPad) * (2 + raidBuffCount)  -- augment + vantus + raid buffs
        + durabilityWidth + hPad
        + framePad

    local x = {
        raidBuff = {},
    }

    x.readyIconCenter = rcIconWidth / 2
    x.name            = rcIconWidth + hPad
    x.food            = rcIconWidth + hPad + nameWidth + hPad + timeWidth
    x.foodTime        = x.food - timeWidth
    x.flask           = x.food + iconSize + hPad + timeWidth
    x.flaskTime       = x.flask - timeWidth
    x.oil             = x.flask + iconSize + hPad + timeWidth
    x.oilTime         = x.oil - timeWidth
    x.augment         = x.oil + iconSize + hPad
    x.vantus          = x.augment + iconSize + hPad

    for k = 1, raidBuffCount do
        x.raidBuff[k] = x.vantus + k * (iconSize + hPad)
    end

    x.durability = x.raidBuff[raidBuffCount] + iconSize + hPad

    local titleX = {
        [col.FOOD]    = x.food,
        [col.FLASK]   = x.flask,
        [col.OIL]     = x.oil,
        [col.AUGMENT] = x.augment,
        [col.VANTUS]  = x.vantus,
    }

    for k = 1, raidBuffCount do
        titleX[col.VANTUS + k] = x.raidBuff[k]
    end

    titleX[col.DURABILITY] = x.durability
        + (durabilityWidth - iconSize) / 2

    local timedColumns = {
        {
            key          = "food",
            timeField    = "foodTime",
            iconField    = "foodIcon",
            overlayField = "foodOverlay",
            timeX        = x.foodTime,
            iconX        = x.food,
            iconID       = db.food_icon_id,
            label        = "Food: Missing",
        },
        {
            key          = "flask",
            timeField    = "flaskTime",
            iconField    = "flaskIcon",
            overlayField = "flaskOverlay",
            timeX        = x.flaskTime,
            iconX        = x.flask,
            iconID       = db.flask_icon_id,
            label        = "Flask: Missing",
        },
        {
            key          = "oil",
            timeField    = "oilTime",
            iconField    = "oilIcon",
            overlayField = "oilOverlay",
            timeX        = x.oilTime,
            iconX        = x.oil,
            iconID       = db.weapon_enchant_icon_id,
            label        = "Weapon Oil: Unknown",
        },
    }

    return {
        raidBuffCount = raidBuffCount,
        frameWidth    = frameWidth,
        col           = col,
        x             = x,
        titleX        = titleX,
        timedColumns  = timedColumns,
    }
end
