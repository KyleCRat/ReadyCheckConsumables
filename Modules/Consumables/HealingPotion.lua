local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.HealingPotion = RCC.Consumables.HealingPotion or {}

local HealingPotion = RCC.Consumables.HealingPotion

local ItemCache = RCC.ConsumableFrameItemCache
local ItemCandidates = RCC.ConsumableFrameItemCandidates

local CacheKey = RCC.ConsumableItemCacheKey

function HealingPotion.CollectItemsInBags()
    return ItemCandidates.CollectAvailableFromList(
        RCC.db.healingPotionItemIDs,
        ItemCandidates.BAGS_ONLY
    )
end

function HealingPotion.GetItemCandidate(includeUnavailableCached)
    local potionCandidates = HealingPotion.CollectItemsInBags()
    local cachedPotionCandidate

    if includeUnavailableCached then
        cachedPotionCandidate = ItemCandidates.CreateFromList(
            RCC.db.healingPotionItemIDs,
            ItemCache.Get(CacheKey.HEALING_POTION),
            ItemCandidates.BAGS_ONLY
        )
    end

    local potionCandidate = ItemCache.SelectCandidate(
        CacheKey.HEALING_POTION,
        potionCandidates,
        cachedPotionCandidate
    )
    local outOfCachedPotion = ItemCache.IsUnavailableCachedCandidate(
        CacheKey.HEALING_POTION,
        potionCandidate
    )

    return potionCandidate, potionCandidates, outOfCachedPotion
end
