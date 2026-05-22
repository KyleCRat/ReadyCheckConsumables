local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Food = RCC.Consumables.Food or {}

local Food = RCC.Consumables.Food

local ItemCache = RCC.ConsumableFrameItemCache
local ItemCandidates = RCC.ConsumableFrameItemCandidates

local CacheKey = RCC.ConsumableItemCacheKey

function Food.GetItemCandidate(includeUnavailableCached)
    local foodCandidates = ItemCandidates.CollectAvailableFromList(
        RCC.db.foodItemIDs,
        ItemCandidates.BAGS_ONLY
    )
    local cachedFoodCandidate

    if includeUnavailableCached then
        cachedFoodCandidate = ItemCandidates.CreateFromList(
            RCC.db.foodItemIDs,
            ItemCache.Get(CacheKey.FOOD),
            ItemCandidates.BAGS_ONLY
        )
    end

    local foodCandidate = ItemCache.SelectCandidate(
        CacheKey.FOOD,
        foodCandidates,
        cachedFoodCandidate
    )
    local outOfCachedFood = ItemCache.IsUnavailableCachedCandidate(
        CacheKey.FOOD,
        foodCandidate
    )

    return foodCandidate, foodCandidates, outOfCachedFood
end
