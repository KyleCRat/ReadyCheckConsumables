local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.DamagePotion = RCC.Consumables.DamagePotion or {}

local DamagePotion = RCC.Consumables.DamagePotion

-- This module is still named DamagePotion because that is the existing frame
-- button/API name, but it now owns the shared-cooldown potion button. That
-- button can show and cache damage, mana, and utility potions from the flyout.
--
-- Potion type is only used after the player has cached a preferred potion. Once
-- a type is cached, automatic fallback stays within that type so a selected
-- damage potion never falls through to a mana or utility potion, and vice versa.
-- Utility potion families are stricter: they only fallback inside the cached
-- family because different utility families can do completely different things.
-- When the frame asks to include unavailable cached items, the primary button
-- shows the cached preference even if the macro will fallback to another item.
-- Healing potions intentionally stay in HealingPotion.lua because they use a
-- separate cooldown and simpler selection rules.

local ItemCache = RCC.ConsumableFrameItemCache
local ItemCandidates = RCC.ConsumableFrameItemCandidates

local CacheKey = RCC.ConsumableItemCacheKey
local UTILITY = RCC.PotionType.UTILITY
local FLEETING = RCC.PotionVariant.FLEETING
local NO_ORDER = 999999

-- TODO: Consider renaming this module once the shared-cooldown potion button
-- work settles. This file handles damage, mana, and utility potion types;
-- healing potions stay separate because they have their own cooldown and
-- simpler selection rules.

-- Higher priority wins. Ties are broken by the family and item order from
-- Data/Potions.lua, which keeps the selection rules editable in the data table.
local Priority = {
    SAME_FAMILY_FLEETING = 5,
    CACHED_ITEM = 4,
    SAME_FAMILY_OTHER_ITEM = 3,
    SAME_TYPE_OTHER_FAMILY = 2,
    UNCACHED_FALLBACK = 1,
}

local function getPotionData(itemID)
    return itemID
        and RCC.db.potionItemData
        and RCC.db.potionItemData[itemID]
end

local function addPotionData(candidate)
    if candidate and candidate.itemID then
        candidate.data = getPotionData(candidate.itemID)
    end

    return candidate
end

local function getOrderValue(value)
    return value or NO_ORDER
end

local function collectPotionCandidatesInBags()
    local candidates = ItemCandidates.CollectAvailableFromList(
        RCC.db.potionItemIDs,
        ItemCandidates.BAGS_ONLY
    )

    for i = 1, #candidates do
        addPotionData(candidates[i])
    end

    return candidates
end

local function createSelectionContext(cachedItemID)
    return {
        cachedItemID = cachedItemID,
        cachedData = getPotionData(cachedItemID),
    }
end

local function canFallbackToOtherFamilies(cachedData)
    return cachedData and cachedData.type ~= UTILITY
end

local function getCandidatePriority(candidate, context)
    local data = candidate and candidate.data
    local cachedData = context.cachedData

    if not data then return end

    if not cachedData then
        return Priority.UNCACHED_FALLBACK
    elseif data.type ~= cachedData.type then
        return
    elseif data.familyIndex ~= cachedData.familyIndex then
        if not canFallbackToOtherFamilies(cachedData) then return end

        return Priority.SAME_TYPE_OTHER_FAMILY
    elseif data.variant == FLEETING then
        return Priority.SAME_FAMILY_FLEETING
    elseif candidate.itemID == context.cachedItemID then
        return Priority.CACHED_ITEM
    end

    return Priority.SAME_FAMILY_OTHER_ITEM
end

local function getCandidateScore(candidate, context)
    local data = candidate and candidate.data

    if not data then return end

    local priority = getCandidatePriority(candidate, context)

    if not priority then return end

    return {
        priority = priority,
        familyOrder = getOrderValue(data.familyIndex),
        itemOrder = getOrderValue(data.itemIndex),
        itemID = candidate.itemID or 0,
    }
end

local function isBetterPotionCandidate(candidate, currentSelection,
                                       context)
    local candidateScore = getCandidateScore(candidate, context)
    local currentScore = getCandidateScore(currentSelection, context)

    if not currentScore then return candidateScore ~= nil end
    if not candidateScore then return false end

    if candidateScore.priority ~= currentScore.priority then
        return candidateScore.priority > currentScore.priority
    elseif candidateScore.familyOrder ~= currentScore.familyOrder then
        return candidateScore.familyOrder < currentScore.familyOrder
    elseif candidateScore.itemOrder ~= currentScore.itemOrder then
        return candidateScore.itemOrder < currentScore.itemOrder
    end

    return candidateScore.itemID > currentScore.itemID
end

local function selectPreferredPotionCandidate(candidates, context)
    return ItemCandidates.SelectBest(candidates, function(candidate,
                                                         currentSelection)
        return isBetterPotionCandidate(candidate, currentSelection, context)
    end)
end

local function createCachedCandidate(context)
    if not context.cachedData then return end

    return addPotionData(ItemCandidates.CreateFromList(
        RCC.db.potionItemIDs,
        context.cachedItemID,
        ItemCandidates.BAGS_ONLY
    ))
end

local function getDisplayCandidate(context, selectedCandidate,
                                   includeUnavailableCached)
    if not includeUnavailableCached then
        return selectedCandidate
    end

    return createCachedCandidate(context) or selectedCandidate
end

local function getPotionItemCandidate(cacheKey, includeUnavailableCached)
    local cachedItemID = ItemCache.Get(cacheKey)
    local context = createSelectionContext(cachedItemID)
    local candidates = collectPotionCandidatesInBags()
    local selectedCandidate = selectPreferredPotionCandidate(candidates, context)
    local displayCandidate = getDisplayCandidate(
        context,
        selectedCandidate,
        includeUnavailableCached
    )

    local outOfCachedItem = ItemCache.IsUnavailableCachedCandidate(
        cacheKey,
        displayCandidate
    )

    return displayCandidate, candidates, outOfCachedItem
end

function DamagePotion.CollectItemsInBags()
    return collectPotionCandidatesInBags()
end

function DamagePotion.GetItemCandidate(includeUnavailableCached, cacheKey)
    return getPotionItemCandidate(
        cacheKey or CacheKey.DAMAGE_POTION,
        includeUnavailableCached
    )
end
