local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format(
            "%s: expected %s, got %s",
            message,
            tostring(expected),
            tostring(actual)
        ))
    end
end

local refreshCount = 0

local RCC = {
    consumables = {
        IsShown = function()
            return false
        end,
    },
    raidFrame = {
        RefreshContextualVisibility = function()
            refreshCount = refreshCount + 1
        end,
    },
}

function CreateFrame()
    return {
        RegisterEvent = function() end,
        SetScript = function() end,
    }
end

function InCombatLockdown()
    return false
end

assert(loadfile("Settings.lua"))("ReadyCheckConsumables", RCC)

ReadyCheckConsumablesDB = nil
assertEqual(
    RCC.GetContextualVisibility("raidFrame", "food", "feastDrop", true),
    true,
    "missing database uses the definition default"
)

ReadyCheckConsumablesDB = {}

assertEqual(
    RCC.SetContextualVisibilityOverride(
        "raidFrame",
        "food",
        "feastDrop",
        false
    ),
    true,
    "false override is accepted"
)
assertEqual(
    RCC.GetContextualVisibility("raidFrame", "food", "feastDrop", true),
    false,
    "false override replaces the definition default"
)
assertEqual(refreshCount, 1, "setting an override refreshes visibility")

assertEqual(
    RCC.SetContextualVisibilityOverride(
        "consumableFrame",
        "food",
        "breakTimer",
        true
    ),
    true,
    "true override is accepted"
)
assertEqual(
    RCC.GetContextualVisibility(
        "consumableFrame",
        "food",
        "breakTimer",
        false
    ),
    true,
    "true override adds a context"
)

assertEqual(
    RCC.SetContextualVisibilityOverride(
        "raidFrame",
        "food",
        "feastDrop",
        nil
    ),
    true,
    "nil clears an override"
)
assertEqual(
    RCC.GetContextualVisibilityOverride(
        "raidFrame",
        "food",
        "feastDrop"
    ),
    nil,
    "cleared override is absent"
)
assertEqual(
    ReadyCheckConsumablesDB.contextualVisibility.raidFrame,
    nil,
    "clearing the last surface override prunes empty tables"
)

ReadyCheckConsumablesDB.contextualVisibility = "invalid"
assertEqual(
    RCC.SetContextualVisibilityOverride(
        "raidFrame",
        "flask",
        "readyCheck",
        true
    ),
    true,
    "malformed saved override storage is replaced"
)
assertEqual(
    RCC.GetContextualVisibilityOverride(
        "raidFrame",
        "flask",
        "readyCheck"
    ),
    true,
    "replacement storage contains the override"
)

assertEqual(
    RCC.SetContextualVisibilityOverride(
        "raidFrame",
        "flask",
        "readyCheck",
        "invalid"
    ),
    false,
    "non-boolean override is rejected"
)

print("SettingsContextualVisibilityTest: PASS")
