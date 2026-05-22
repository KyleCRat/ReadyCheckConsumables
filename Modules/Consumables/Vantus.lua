local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Vantus = RCC.Consumables.Vantus or {}

local Vantus = RCC.Consumables.Vantus

local ItemCache = RCC.ConsumableFrameItemCache
local ItemCandidates = RCC.ConsumableFrameItemCandidates

local CacheKey = RCC.ConsumableItemCacheKey

function Vantus.GetRuneIDsForCurrentRaid()
    local instanceID = select(8, GetInstanceInfo())

    return RCC.db.vantusItemsByRaid[instanceID]
end

function Vantus.GetItemCandidate(vantusRuneIDs, includeUnavailableCached)
    local candidates = ItemCandidates.CollectAvailableFromList(
        vantusRuneIDs,
        ItemCandidates.BAGS_ONLY
    )
    local cachedCandidate

    if includeUnavailableCached then
        cachedCandidate = ItemCandidates.CreateFromList(
            vantusRuneIDs,
            ItemCache.Get(CacheKey.VANTUS),
            ItemCandidates.BAGS_ONLY
        )
    end

    local candidate = ItemCache.SelectCandidate(
        CacheKey.VANTUS,
        candidates,
        cachedCandidate
    )
    local outOfCachedItem = ItemCache.IsUnavailableCachedCandidate(
        CacheKey.VANTUS,
        candidate
    )

    return candidate, candidates, outOfCachedItem
end

function Vantus.GetFallbackItem(vantusRuneIDs)
    local itemID = vantusRuneIDs[1]

    return itemID, ItemCandidates.GetIcon(itemID)
end
