local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(
            (message or "values differ")
                .. ": expected " .. tostring(expected)
                .. ", got " .. tostring(actual),
            2
        )
    end
end

local function assertKeys(columns, expected, message)
    assertEqual(#columns, #expected, message .. " count")

    for i = 1, #expected do
        assertEqual(columns[i].key, expected[i], message .. " key " .. i)
    end
end

function wipe(tableToClear)
    for key in pairs(tableToClear) do
        tableToClear[key] = nil
    end
end

local activeCauldrons = {
    flask = false,
    potion = false,
}

local RCC = {
    db = {
        foodIconID = 1,
        flaskIconID = 2,
        weaponEnchantIconID = 3,
        augmentIconID = 4,
        vantusIconID = 5,
        combatPotionIconID = 6,
        flaskBuffIDs = {},
        augmentBuffIDs = {},
        vantusBuffIDs = {},
    },
    F = {
        StoreAuraID = function() end,
    },
    FoodAuras = {
        Type = {
            EATING = "eating",
        },
    },
    RaidFrameBroadcast = {
        TempWeaponEnchantStatus = {
            MISSING = 0,
            NO_WEAPON = -1,
            UNKNOWN = -2,
        },
    },
    RaidFrameCauldron = {
        KIND_FLASK = "flask",
        KIND_POTION = "potion",
        IsActive = function(kind)
            return activeCauldrons[kind] == true
        end,
        GetCount = function() return 0 end,
        GetTarget = function() return 0 end,
    },
    RaidFrameColumnRenderers = {
        TIMED = {
            CreateCell = function() end,
            RenderAuraCell = function() end,
            RenderTempWeaponEnchantCell = function() end,
        },
        ICON = {
            CreateCell = function() end,
            RenderAuraCell = function() end,
        },
        RAID_BUFF = {
            CreateCell = function() end,
            RenderCell = function() end,
        },
        DURABILITY = {
            CreateCell = function() end,
            RenderCell = function() end,
        },
        CAULDRON = {
            CreateCell = function() end,
            RenderCell = function() end,
        },
        SetCellShown = function() end,
        PositionCell = function() end,
    },
    RaidBuffStatus = {
        GetCount = function() return 2 end,
        GetInfo = function(index)
            return {
                iconID = 100 + index,
                spellID = 200 + index,
            }
        end,
        CreateData = function() return { has = false } end,
        CollectAura = function() end,
        IsMissing = function() return false end,
    },
    ConsumableTiming = {
        IsExpiringSoon = function() return false end,
    },
    overrides = {},
}

function RCC.GetSetting()
    return true
end

function RCC.GetContextualVisibility(surface, elementKey, reason, defaultValue)
    local surfaceOverrides = RCC.overrides[surface]
    local elementOverrides = surfaceOverrides and surfaceOverrides[elementKey]
    local value = elementOverrides and elementOverrides[reason]

    if value ~= nil then
        return value
    end

    return defaultValue
end

assert(loadfile("Modules/ContextualVisibility.lua"))(
    "ReadyCheckConsumables",
    RCC
)
assert(loadfile("Modules/RaidFrame/RaidFrameColumns.lua"))(
    "ReadyCheckConsumables",
    RCC
)

local Columns = RCC.RaidFrameColumns
local Context = RCC.DisplayContext
local Reason = RCC.DisplayReason
local Surface = RCC.DisplaySurface
local layout = Columns.CreateLayout()

assertKeys(layout.activeColumns, {
    "food",
    "flask",
    "tempWeaponEnchant",
    "augment",
    "vantus",
    "raidBuff1",
    "raidBuff2",
    "durability",
}, "default ready-check layout")
assertEqual(layout.showReadyIcon, true, "ready check shows response icon")
assertEqual(#layout.broadcastColumns, 2, "broadcast acquisition is explicit")
assertEqual(layout.broadcastColumns[1].key, "food", "food is broadcast-scanned")
assertEqual(layout.broadcastColumns[2].key, "flask", "flask is broadcast-scanned")

for i = 1, #layout.columns do
    local column = layout.columns[i]

    assertEqual(
        type(column.titleX),
        "number",
        column.key .. " has a construction title position"
    )

    if column.columnType == Columns.COLUMN_TYPE.TIMED then
        assertEqual(type(column.timeX), "number", column.key .. " time position")
        assertEqual(type(column.iconX), "number", column.key .. " icon position")
    elseif column.columnType == Columns.COLUMN_TYPE.CAULDRON then
        assertEqual(type(column.countX), "number", column.key .. " count position")
        assertEqual(type(column.iconX), "number", column.key .. " icon position")
    elseif column.columnType == Columns.COLUMN_TYPE.DURABILITY then
        assertEqual(type(column.textX), "number", column.key .. " text position")
    else
        assertEqual(type(column.iconX), "number", column.key .. " icon position")
    end
end

local context = Context.Create(Surface.RAID_FRAME)

Columns.ConfigureLayout(layout, context)
assertKeys(layout.activeColumns, {}, "empty context")
assertEqual(layout.frameWidth, 162, "empty context width")

Context.Activate(context, Reason.FEAST_DROP, "feast")
Columns.ConfigureLayout(layout, context)
assertKeys(layout.activeColumns, { "food" }, "feast layout")
assertEqual(layout.columnsByKey.food.timeX, 156, "feast food time position")
assertEqual(layout.columnsByKey.food.iconX, 186, "feast food icon position")
assertEqual(layout.frameWidth, 221, "feast layout width")

activeCauldrons.flask = true
activeCauldrons.potion = true
Context.Activate(context, Reason.CAULDRON_DROP, "flask")
Context.Activate(context, Reason.CAULDRON_DROP, "potion")
Columns.ConfigureLayout(layout, context)
assertKeys(layout.activeColumns, {
    "food",
    "cauldronFlask",
    "cauldronPotion",
}, "combined provision layout")
assertEqual(
    layout.columnsByKey.cauldronFlask.countX,
    215,
    "flask cauldron follows food without a gap"
)
assertEqual(
    layout.columnsByKey.cauldronPotion.countX,
    276,
    "potion cauldron follows flask without a gap"
)
assertEqual(layout.frameWidth, 343, "combined provision width")

Context.ResetReason(context, Reason.FEAST_DROP)
Columns.ConfigureLayout(layout, context)
assertKeys(layout.activeColumns, {
    "cauldronFlask",
    "cauldronPotion",
}, "cauldron-only layout")
assertEqual(
    layout.columnsByKey.cauldronFlask.countX,
    156,
    "first cauldron starts after the name"
)
assertEqual(layout.frameWidth, 284, "cauldron-only width")

Context.Activate(context, Reason.READY_CHECK)
RCC.overrides[Surface.RAID_FRAME] = {
    food = {
        [Reason.READY_CHECK] = false,
    },
    flask = {
        [Reason.READY_CHECK] = false,
    },
}
Columns.ConfigureLayout(layout, context)
assertEqual(
    layout.columnsByKey.tempWeaponEnchant.timeX,
    180,
    "arbitrary hidden columns leave no gap"
)

RCC.overrides[Surface.RAID_FRAME] = nil
Columns.ConfigureLayout(layout, context)
assertEqual(
    layout.columnsByKey.food.timeX,
    180,
    "ready-check food position restored"
)

local secondContext = Context.Create(Surface.RAID_FRAME)

Context.Activate(secondContext, Reason.FEAST_DROP, "feast")

local secondLayout = Columns.CreateLayout(secondContext)

assertEqual(
    secondLayout.columnsByKey.food.timeX,
    156,
    "second layout receives independent positions"
)
assertEqual(
    layout.columnsByKey.food.timeX,
    180,
    "first layout positions are not mutated by the second"
)

print("RaidFrameColumnsLayoutTest: PASS")
