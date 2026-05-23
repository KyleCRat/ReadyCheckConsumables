local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.HealingPotion = RCC.Consumables.HealingPotion or {}

local HealingPotion = RCC.Consumables.HealingPotion

local ItemCache = RCC.ConsumableFrameItemCache
local ItemCandidates = RCC.ConsumableFrameItemCandidates

local CacheKey = RCC.ConsumableItemCacheKey
local HEALING_POTION = CacheKey.HEALING_POTION

function HealingPotion.CollectItemsInBags()
    return ItemCandidates.CollectAvailableFromList(
        RCC.db.healingPotionItemIDs,
        ItemCandidates.BAGS_ONLY
    )
end

local function createCachedPotionCandidate(cachedItemID)
    return ItemCandidates.CreateFromList(
        RCC.db.healingPotionItemIDs,
        cachedItemID,
        ItemCandidates.BAGS_ONLY
    )
end

local function selectPotionCandidate(potionCandidates)
    local cachedItemID = ItemCache.Get(HEALING_POTION)
    local cachedPotionCandidate = ItemCache.FindCandidate(
        potionCandidates,
        cachedItemID
    )

    -- Macro selection uses the cached potion when it is available, then falls
    -- back to list order from Data/HealingItems.lua.
    return cachedPotionCandidate or potionCandidates[1]
end

local function getDisplayPotionCandidate(selectedPotionCandidate,
                                         includeUnavailableCached)
    if not includeUnavailableCached then
        return selectedPotionCandidate
    end

    -- Frame display preserves the cached preference even when its count is 0.
    return createCachedPotionCandidate(ItemCache.Get(HEALING_POTION))
        or selectedPotionCandidate
end

function HealingPotion.GetItemCandidate(includeUnavailableCached)
    local potionCandidates = HealingPotion.CollectItemsInBags()
    local selectedPotionCandidate = selectPotionCandidate(potionCandidates)
    local displayPotionCandidate = getDisplayPotionCandidate(
        selectedPotionCandidate,
        includeUnavailableCached
    )
    local outOfCachedPotion = ItemCache.IsUnavailableCachedCandidate(
        HEALING_POTION,
        displayPotionCandidate
    )

    return displayPotionCandidate, potionCandidates, outOfCachedPotion
end
