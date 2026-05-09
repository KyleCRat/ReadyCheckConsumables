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

function Columns.CreateLayout()
    local iconSize        = ICON_SIZE
    local rcIconWidth     = RC_ICON_WIDTH
    local nameWidth       = NAME_WIDTH
    local timeWidth       = TIME_WIDTH
    local durabilityWidth = DURABILITY_WIDTH
    local hPad            = H_PAD
    local framePad        = FRAME_PAD
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
            IsBad        = function(member, context)
                local a = member.auras

                return not a.hasFood
                    or (a.foodTime ~= context.noDuration
                        and a.foodTime < context.expireWarnSeconds)
            end,
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
            IsBad        = function(member, context)
                local a = member.auras

                return not a.hasFlask
                    or (a.flaskTime ~= context.noDuration
                        and a.flaskTime < context.expireWarnSeconds)
            end,
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
            IsBad        = function(member, context)
                local playerKey = member.key or F.fullName(member.name)
                local oil = context.oilData[playerKey]
                local oilTime = oil and oil.time

                if oilTime == nil or oilTime == -1 then
                    return false
                end

                return oilTime == 0 or oilTime < context.expireWarnSeconds
            end,
        },
    }

    local iconColumns = {
        {
            key          = "augment",
            iconField    = "augmentIcon",
            overlayField = "augmentOverlay",
            iconX        = x.augment,
            iconID       = db.augment_icon_id,
            label        = "Augment Rune: Missing",
            IsBad        = function(member)
                return not member.auras.hasAugment
            end,
        },
        {
            key          = "vantus",
            iconField    = "vantusIcon",
            overlayField = "vantusOverlay",
            iconX        = x.vantus,
            iconID       = db.vantus_icon_id,
            label        = "Vantus Rune: Missing",
            IsBad        = function(member)
                return not member.auras.hasVantus
            end,
        },
    }

    local raidBuffColumns = {}
    for k = 1, raidBuffCount do
        local index = k

        raidBuffColumns[k] = {
            key       = "raidBuff" .. k,
            index     = index,
            iconX     = x.raidBuff[index],
            spellID   = db.raidBuffDefs[index][3],
            IsBad     = function(member)
                local auraID = member.auras.raidBuff[index]

                return not auraID or auraID == false
            end,
        }
    end

    local durabilityColumn = {
        key   = "durability",
        IsBad = function(member, context)
            local playerKey = member.key or F.fullName(member.name)
            local pct = context.durabilityData[playerKey]

            if not pct then
                return false
            end

            return pct < context.durabilityThreshold
        end,
    }

    local titleColumns = {
        [col.FOOD]       = timedColumns[1],
        [col.FLASK]      = timedColumns[2],
        [col.OIL]        = timedColumns[3],
        [col.AUGMENT]    = iconColumns[1],
        [col.VANTUS]     = iconColumns[2],
        [col.DURABILITY] = durabilityColumn,
    }

    for k = 1, raidBuffCount do
        titleColumns[col.VANTUS + k] = raidBuffColumns[k]
    end

    return {
        raidBuffCount   = raidBuffCount,
        frameWidth      = frameWidth,
        framePad        = framePad,
        iconSize        = iconSize,
        rcIconWidth     = rcIconWidth,
        nameWidth       = nameWidth,
        timeWidth       = timeWidth,
        durabilityWidth = durabilityWidth,
        col             = col,
        x               = x,
        titleX          = titleX,
        titleColumns    = titleColumns,
        timedColumns    = timedColumns,
        iconColumns     = iconColumns,
        raidBuffColumns = raidBuffColumns,
    }
end
