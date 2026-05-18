local _, RCC = ...

RCC.ConsumableFrameItemCache = RCC.ConsumableFrameItemCache or {}

local Cache = RCC.ConsumableFrameItemCache

RCC.ConsumableItemCacheKey = RCC.ConsumableItemCacheKey or {
    FOOD                          = "food",
    FLASK                         = "flask",
    AUGMENT                       = "augment",
    VANTUS                        = "vantus",
    MAIN_HAND_TEMP_WEAPON_ENCHANT = "mainHandTempWeaponEnchant",
    OFF_HAND_TEMP_WEAPON_ENCHANT  = "offHandTempWeaponEnchant",
}

local cachedItemIDs = {}

local function getSavedCache()
    if not ReadyCheckConsumablesDB then return end

    ReadyCheckConsumablesDB.consumableItemCache =
        ReadyCheckConsumablesDB.consumableItemCache or {}

    return ReadyCheckConsumablesDB.consumableItemCache
end

function Cache.Set(cacheKey, itemID)
    if not cacheKey or not itemID then return end

    cachedItemIDs[cacheKey] = itemID

    local savedCache = getSavedCache()

    if savedCache then
        savedCache[cacheKey] = itemID
    end
end

function Cache.Clear(cacheKey)
    if not cacheKey then return end

    cachedItemIDs[cacheKey] = nil

    local savedCache = getSavedCache()

    if savedCache then
        savedCache[cacheKey] = nil
    end
end

function Cache.Get(cacheKey)
    if not cacheKey then return end

    local savedCache = getSavedCache()
    local savedItemID = savedCache and savedCache[cacheKey]

    if type(savedItemID) == "number" then
        return savedItemID
    end

    local cachedItemID = cachedItemIDs[cacheKey]

    if type(cachedItemID) == "number" then
        return cachedItemID
    end
end

function Cache.FindCandidate(candidates, itemID)
    if not candidates or not itemID then return end

    for i = 1, #candidates do
        local candidate = candidates[i]

        if candidate.itemID == itemID then
            return candidate
        end
    end
end

function Cache.SelectCandidate(cacheKey, candidates, unavailableCandidate)
    local cachedItemID = Cache.Get(cacheKey)
    local cachedCandidate = Cache.FindCandidate(candidates, cachedItemID)

    if cachedCandidate then
        return cachedCandidate
    end

    if unavailableCandidate
        and cachedItemID
        and unavailableCandidate.itemID == cachedItemID
    then
        return unavailableCandidate
    end

    return candidates and candidates[1]
end

function Cache.IsUnavailableCachedCandidate(cacheKey, candidate)
    if not candidate or not candidate.itemID then return false end

    return candidate.itemID == Cache.Get(cacheKey)
           and (candidate.count or 0) <= 0
end
