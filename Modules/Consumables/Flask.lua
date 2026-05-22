local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Flask = RCC.Consumables.Flask or {}

local Flask = RCC.Consumables.Flask

local ItemCache = RCC.ConsumableFrameItemCache
local ItemCandidates = RCC.ConsumableFrameItemCandidates

local CacheKey = RCC.ConsumableItemCacheKey

function Flask.GetItemCandidate(includeUnavailableCached)
    local flaskCandidates = ItemCandidates.CollectAvailableFromList(
        RCC.db.flaskItemIDs,
        ItemCandidates.BAGS_ONLY
    )
    local cachedFlaskCandidate

    if includeUnavailableCached then
        cachedFlaskCandidate = ItemCandidates.CreateFromList(
            RCC.db.flaskItemIDs,
            ItemCache.Get(CacheKey.FLASK),
            ItemCandidates.BAGS_ONLY
        )
    end

    local flaskCandidate = ItemCache.SelectCandidate(
        CacheKey.FLASK,
        flaskCandidates,
        cachedFlaskCandidate
    )
    local outOfCachedFlask = ItemCache.IsUnavailableCachedCandidate(
        CacheKey.FLASK,
        flaskCandidate
    )

    return flaskCandidate, flaskCandidates, outOfCachedFlask
end
