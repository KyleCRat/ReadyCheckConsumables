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

function wipe(tableToClear)
    for key in pairs(tableToClear) do
        tableToClear[key] = nil
    end
end

local RCC = {
    settings = {},
    overrides = {},
}

function RCC.GetSetting(key)
    return RCC.settings[key] ~= false
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

local chunk = assert(loadfile("Modules/ContextualVisibility.lua"))

chunk("ReadyCheckConsumables", RCC)

local Context = RCC.DisplayContext
local Reason = RCC.DisplayReason
local Surface = RCC.DisplaySurface
local Visibility = RCC.ContextualVisibility

local context = Context.Create(Surface.RAID_FRAME)

assertEqual(Context.HasAny(context), false, "new context is empty")
assertEqual(
    Context.Activate(context, Reason.CAULDRON_DROP, "flask"),
    true,
    "first cauldron source activates"
)
assertEqual(
    Context.Activate(context, Reason.CAULDRON_DROP, "potion"),
    true,
    "second cauldron source activates independently"
)
assertEqual(
    Context.GetPrimaryReason(context),
    Reason.CAULDRON_DROP,
    "cauldron is initially primary"
)

Context.Activate(context, Reason.FEAST_DROP, "feast")
assertEqual(
    Context.GetPrimaryReason(context),
    Reason.FEAST_DROP,
    "feast outranks cauldron"
)

Context.Activate(context, Reason.READY_CHECK)
assertEqual(
    Context.GetPrimaryReason(context),
    Reason.READY_CHECK,
    "ready check outranks contextual sources"
)

Context.Deactivate(context, Reason.READY_CHECK)
Context.Deactivate(context, Reason.CAULDRON_DROP, "flask")
assertEqual(
    Context.IsActive(context, Reason.CAULDRON_DROP),
    true,
    "one cauldron source remains active"
)

Context.Deactivate(context, Reason.CAULDRON_DROP, "potion")
assertEqual(
    Context.IsActive(context, Reason.CAULDRON_DROP),
    false,
    "last source deactivates its reason"
)

assertEqual(
    Context.ShouldAutoOpen(context, Reason.FEAST_DROP, "feast"),
    true,
    "new source can auto-open"
)
Context.MarkAutoOpened(context, Reason.FEAST_DROP, "feast")
assertEqual(
    Context.ShouldAutoOpen(context, Reason.FEAST_DROP, "feast"),
    false,
    "handled source cannot auto-open twice"
)
Context.ResetReason(context, Reason.FEAST_DROP)
assertEqual(
    Context.ShouldAutoOpen(context, Reason.FEAST_DROP, "feast"),
    true,
    "new session clears handled sources"
)

local buttonContext = Context.Create(Surface.CONSUMABLE_FRAME)
local definition = {
    key = "food",
    settingKey = "icon_food",
    visibility = {
        reasons = {
            [Reason.READY_CHECK] = true,
        },
    },
}

Context.Activate(buttonContext, Reason.READY_CHECK)
assertEqual(
    Visibility.IsVisible(definition, buttonContext, { applicable = true }),
    true,
    "default reason policy shows applicable element"
)
assertEqual(
    Visibility.IsVisible(definition, buttonContext, { applicable = false }),
    false,
    "applicability is an independent gate"
)

RCC.settings.icon_food = false
assertEqual(
    Visibility.IsVisible(definition, buttonContext, { applicable = true }),
    false,
    "global setting is an independent gate"
)
RCC.settings.icon_food = true

RCC.overrides[Surface.CONSUMABLE_FRAME] = {
    food = {
        [Reason.READY_CHECK] = false,
        [Reason.BREAK_TIMER] = true,
    },
}
assertEqual(
    Visibility.IsVisible(definition, buttonContext, { applicable = true }),
    false,
    "false override replaces the default policy"
)

Context.Deactivate(buttonContext, Reason.READY_CHECK)
Context.Activate(buttonContext, Reason.BREAK_TIMER)
assertEqual(
    Visibility.IsVisible(definition, buttonContext, { applicable = true }),
    true,
    "true override can add a context"
)

print("ContextualVisibilityTest: PASS")
