local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.DamagePotion = RCC.Consumables.DamagePotion or {}

local DamagePotion = RCC.Consumables.DamagePotion

local ItemCache = RCC.ConsumableFrameItemCache
local ItemCandidates = RCC.ConsumableFrameItemCandidates

local CacheKey = RCC.ConsumableItemCacheKey

function DamagePotion.CollectItemsInBags()
    return ItemCandidates.CollectAvailableFromList(
        RCC.db.potionItemIDs,
        ItemCandidates.BAGS_ONLY
    )
end

function DamagePotion.GetItemCandidate(includeUnavailableCached)
    local potionCandidates = DamagePotion.CollectItemsInBags()
    local cachedPotionCandidate

    if includeUnavailableCached then
        cachedPotionCandidate = ItemCandidates.CreateFromList(
            RCC.db.potionItemIDs,
            ItemCache.Get(CacheKey.DAMAGE_POTION),
            ItemCandidates.BAGS_ONLY
        )
    end

    local potionCandidate = ItemCache.SelectCandidate(
        CacheKey.DAMAGE_POTION,
        potionCandidates,
        cachedPotionCandidate
    )
    local outOfCachedPotion = ItemCache.IsUnavailableCachedCandidate(
        CacheKey.DAMAGE_POTION,
        potionCandidate
    )

    return potionCandidate, potionCandidates, outOfCachedPotion
end
