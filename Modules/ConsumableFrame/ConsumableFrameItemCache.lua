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

local cachedItemIDs = {}

local function scheduleMacroUpdate()
    RCC.ConsumableMacros.ScheduleUpdate()
end

local function getSavedCache()
    if not ReadyCheckConsumablesDB then return end

    ReadyCheckConsumablesDB.consumableItemCache =
        ReadyCheckConsumablesDB.consumableItemCache or {}

    return ReadyCheckConsumablesDB.consumableItemCache
end

function Cache.CanPrefer(itemID)
    return type(itemID) == "number" and not RCC.db.preferenceBlockedItemIDs[itemID]
end

function Cache.Set(cacheKey, itemID)
    if not cacheKey or not Cache.CanPrefer(itemID) then return end

    local previousItemID = Cache.Get(cacheKey)

    cachedItemIDs[cacheKey] = itemID

    local savedCache = getSavedCache()

    if savedCache then
        savedCache[cacheKey] = itemID
    end

    if previousItemID ~= itemID then
        scheduleMacroUpdate()
        RCC.ConsumableStateController.Invalidate("preferences", { nextFrame = true })
    end
end

function Cache.Clear(cacheKey)
    if not cacheKey then return end

    local previousItemID = Cache.Get(cacheKey)

    cachedItemIDs[cacheKey] = nil

    local savedCache = getSavedCache()

    if savedCache then
        savedCache[cacheKey] = nil
    end

    if previousItemID ~= nil then
        scheduleMacroUpdate()
        RCC.ConsumableStateController.Invalidate("preferences", { nextFrame = true })
    end
end

function Cache.Get(cacheKey)
    if not cacheKey then return end

    local savedCache = getSavedCache()
    local savedItemID = savedCache and savedCache[cacheKey]

    -- Older versions allowed fleeting preferences. Ignore those choices without
    -- inventing a regular item/rank or changing SavedVariables during a read.
    if Cache.CanPrefer(savedItemID) then
        return savedItemID
    end

    local cachedItemID = cachedItemIDs[cacheKey]

    if Cache.CanPrefer(cachedItemID) then
        return cachedItemID
    end
end
