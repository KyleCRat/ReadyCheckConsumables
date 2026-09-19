local _, RCC = ...
local Preferences = {}
RCC.ConsumablePreferences = Preferences
local Choice = RCC.ConsumableChoice

RCC.ConsumablePreferenceKey = {
    FOOD = "food",
    FLASK = "flask",
    AUGMENT = "augment",
    COMBAT_POTION = "combatPotion",
    HEALING_POTION = "healingPotion",
    VANTUS = "vantus",
    MAIN_HAND_TEMP_WEAPON_ENCHANT = "mainHandTempWeaponEnchant",
    OFF_HAND_TEMP_WEAPON_ENCHANT = "offHandTempWeaponEnchant",
    LETHAL_POISON = "lethalPoison",
    NON_LETHAL_POISON = "nonLethalPoison",
}

local function refreshPreferences()
    RCC.ConsumableMacros.ScheduleUpdate()
    RCC.ConsumableStateController.Invalidate("preferences", { nextFrame = true })
end

function Preferences.UsesProfilePreferences()
    return RCC.characterDB:Get("useProfileConsumablePreferences") == true
end

function Preferences.SetUseProfilePreferences(enabled)
    if Preferences.UsesProfilePreferences() == enabled then return end

    -- Changing ownership never copies, clears, or merges either store.
    RCC.characterDB:Set("useProfileConsumablePreferences", enabled)
    refreshPreferences()
end

local function getPreferenceDB()
    return Preferences.UsesProfilePreferences() and RCC.settingsDB or RCC.characterDB
end

function Preferences.CanPrefer(choice)
    return Choice.IsValid(choice)
        and (choice.kind ~= "item" or not RCC.db.preferenceBlockedItemIDs[choice.id])
end

function Preferences.GetChoices(preferences, key, capacity)
    local branches = preferences and preferences[key]

    return branches and branches[capacity or 1] or {}
end

function Preferences.GetItemID(preferences, key)
    local choice = Preferences.GetChoices(preferences, key)[1]

    if choice and choice.kind == "item" then return choice.id end
end

function Preferences.Read(previous)
    local preferences = CopyTable(getPreferenceDB():Get("consumablePreferences") or {})

    -- Old fleeting choices are not promoted to another rank or family.
    for key, branches in pairs(preferences) do
        for _, choices in pairs(branches) do
            for index = #choices, 1, -1 do
                if not Preferences.CanPrefer(choices[index]) then
                    table.remove(choices, index)
                end
            end
        end

        if previous and RCC.ConsumableInputs.Equal(previous[key], branches) then
            preferences[key] = previous[key]
        end
    end

    return preferences
end

function Preferences.IsPreferred(key, capacity, choice)
    local choices = getPreferenceDB():Get("consumablePreferences", key, capacity or 1)

    return Choice.Contains(choices, choice) ~= nil
end

-- Each capacity is independent. Preference order is selection age: adding a
-- choice to a full branch replaces its oldest choice, never another branch.
function Preferences.Toggle(key, capacity, choice)
    if not key or not Preferences.CanPrefer(choice) then return end

    capacity = capacity or 1
    local db = getPreferenceDB()
    local choices = CopyTable(db:Get("consumablePreferences", key, capacity) or {})
    local index = Choice.Contains(choices, choice)

    if index then
        table.remove(choices, index)
    else
        while #choices >= capacity do
            table.remove(choices, 1)
        end

        choices[#choices + 1] = Choice.Copy(choice)
    end

    db:Set("consumablePreferences", key, capacity, choices)
    refreshPreferences()
end
