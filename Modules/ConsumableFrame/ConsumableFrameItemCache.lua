local _, RCC = ...

RCC.ConsumableFrameItemCache = RCC.ConsumableFrameItemCache or {}

local Cache = RCC.ConsumableFrameItemCache

RCC.ConsumableItemCacheKey = RCC.ConsumableItemCacheKey or {
    FOOD                          = "food",
    FLASK                         = "flask",
    AUGMENT                       = "augment",
    COMBAT_POTION                 = "combatPotion",
    HEALING_POTION                = "healingPotion",
    VANTUS                        = "vantus",
    MAIN_HAND_TEMP_WEAPON_ENCHANT = "mainHandTempWeaponEnchant",
    OFF_HAND_TEMP_WEAPON_ENCHANT  = "offHandTempWeaponEnchant",
}

local function refreshPreferences()
    RCC.ConsumableMacros.ScheduleUpdate()
    RCC.ConsumableStateController.Invalidate("preferences", { nextFrame = true })
end

function Cache.UsesProfilePreferences()
    return RCC.characterDB:Get("useProfileConsumablePreferences") == true
end

function Cache.SetUseProfilePreferences(enabled)
    if Cache.UsesProfilePreferences() == enabled then return end

    -- This choice belongs to the character, never the selected profile.
    -- Switching stores does not copy, merge, or clear either set of choices.
    RCC.characterDB:Set("useProfileConsumablePreferences", enabled)
    refreshPreferences()
end

local function getPreferenceDB()
    if Cache.UsesProfilePreferences() then
        return RCC.settingsDB
    end

    return RCC.characterDB
end

function Cache.CanPrefer(itemID)
    return type(itemID) == "number" and not RCC.db.preferenceBlockedItemIDs[itemID]
end

function Cache.Set(cacheKey, itemID)
    if not cacheKey or not Cache.CanPrefer(itemID) then return end
    if not RCC.settingsDB then return end

    local previousItemID = Cache.Get(cacheKey)

    getPreferenceDB():Set("consumableItemCache", cacheKey, itemID)

    if previousItemID ~= itemID then
        refreshPreferences()
    end
end

function Cache.Clear(cacheKey)
    if not cacheKey then return end
    if not RCC.settingsDB then return end

    local previousItemID = Cache.Get(cacheKey)

    getPreferenceDB():ResetPath("consumableItemCache", cacheKey)

    if previousItemID ~= nil then
        refreshPreferences()
    end
end

function Cache.Get(cacheKey)
    if not cacheKey then return end
    if not RCC.settingsDB then return end

    local savedItemID = getPreferenceDB():Get("consumableItemCache", cacheKey)

    -- Older versions allowed fleeting preferences. Ignore those choices without
    -- inventing a regular item/rank or changing SavedVariables during a read.
    if Cache.CanPrefer(savedItemID) then
        return savedItemID
    end
end
