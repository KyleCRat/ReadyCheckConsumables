local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Augment = RCC.Consumables.Augment or {}

local Augment = RCC.Consumables.Augment

local ItemCache = RCC.ConsumableFrameItemCache
local ItemCandidates = RCC.ConsumableFrameItemCandidates

local CacheKey = RCC.ConsumableItemCacheKey

local function isBetterAugmentCandidate(candidate, best, preferUnlimited)
    local data = candidate.data or {}
    local bestData = best.data or {}
    local unlimited = data.unlimited == true
    local bestUnlimited = bestData.unlimited == true

    if preferUnlimited and unlimited ~= bestUnlimited then
        return unlimited
    end

    local xpac = data.xpac or 0
    local priority = data.priority or 0
    local bestXpac = bestData.xpac or 0
    local bestPriority = bestData.priority or 0

    return xpac > bestXpac
        or (xpac == bestXpac and priority > bestPriority)
        or (xpac == bestXpac and priority == bestPriority
            and candidate.itemID > (best.itemID or 0))
end

local function sortAugmentCandidates(candidates, preferUnlimited)
    table.sort(candidates, function(a, b)
        return isBetterAugmentCandidate(a, b, preferUnlimited)
    end)
end

function Augment.GetCountText(candidate)
    local data = candidate and candidate.data

    if data and data.unlimited then
        return ""
    end

    return tostring(candidate and candidate.count or 0)
end

function Augment.CollectItemsInBags()
    local preferUnlimited =
        RCC.GetSetting("consumables_preferUnlimitedAugment")
    local candidates = ItemCandidates.CollectAvailableFromMap(
        RCC.db.augmentItemIDs,
        ItemCandidates.BAGS_ONLY
    )

    sortAugmentCandidates(candidates, preferUnlimited)

    return candidates
end

function Augment.GetItemCandidate(includeUnavailableCached)
    local augmentCandidates = Augment.CollectItemsInBags()
    local cachedAugmentCandidate

    if includeUnavailableCached then
        cachedAugmentCandidate = ItemCandidates.CreateFromMap(
            RCC.db.augmentItemIDs,
            ItemCache.Get(CacheKey.AUGMENT),
            ItemCandidates.BAGS_ONLY
        )
    end

    local augmentCandidate = ItemCache.SelectCandidate(
        CacheKey.AUGMENT,
        augmentCandidates,
        cachedAugmentCandidate
    )
    local outOfCachedAugment = ItemCache.IsUnavailableCachedCandidate(
        CacheKey.AUGMENT,
        augmentCandidate
    )

    return augmentCandidate, augmentCandidates, outOfCachedAugment
end
