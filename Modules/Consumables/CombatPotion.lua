local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.CombatPotion = RCC.Consumables.CombatPotion or {}

local CombatPotion = RCC.Consumables.CombatPotion

-- This module owns the shared-cooldown combat potion button. That button can
-- show and cache damage, mana, and utility potions from the flyout.
--
-- Potion type is only used after the player has cached a preferred potion. Once
-- a type is cached, automatic fallback stays within that type so a selected
-- damage-family potion never falls through to mana or utility, and vice versa.
-- Utility potion families are stricter: they only fallback inside the cached
-- family because different utility families can do completely different things.
-- When the frame asks to include unavailable cached items, the primary button
-- shows the cached preference even if the macro will fallback to another item.
-- Healing potions intentionally stay in HealingPotion.lua because they use a
-- separate cooldown and simpler selection rules.

local S = RCC.ConsumableSelection

local CacheKey = RCC.ConsumableItemCacheKey
local UTILITY = RCC.CombatPotionType.UTILITY
local FLEETING = RCC.CombatPotionVariant.FLEETING
local NO_ORDER = 999999

CombatPotion.Inventory = { list = RCC.db.combatPotionItemIDs }

CombatPotion.Dependencies = { selection = { "inventory", "preferences.combatPotion" } }

-- Higher priority wins. Ties are broken by the family and item order from
-- Data/CombatPotions.lua, which keeps the selection rules editable in the data
-- table.
local Priority = {
    SAME_FAMILY_FLEETING = 5,
    CACHED_ITEM = 4,
    SAME_FAMILY_OTHER_ITEM = 3,
    SAME_TYPE_OTHER_FAMILY = 2,
    UNCACHED_FALLBACK = 1,
}

local function getPotionData(itemID)
    return itemID
        and RCC.db.combatPotionItemData
        and RCC.db.combatPotionItemData[itemID]
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

local function collectPotionCandidates(inventory)
    local candidates = S.List(inventory, RCC.db.combatPotionItemIDs)

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

local function isBetterPotionCandidate(candidate, currentSelection, context)
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
    local selected = S.Best(candidates, function(candidate, currentSelection)
        return isBetterPotionCandidate(candidate, currentSelection, context)
    end)

    -- Best starts with the first candidate even if none match the saved
    -- potion type/family. Keep those items in the flyout, not in auto-selection.
    if selected and getCandidatePriority(selected, context) then
        return selected
    end
end

function CombatPotion.Select(inputs, preserveUnavailable)
    local preferredID = inputs.preferences[CacheKey.COMBAT_POTION]
    local context = createSelectionContext(preferredID)
    local candidates = collectPotionCandidates(inputs.inventory)
    local selected = selectPreferredPotionCandidate(candidates, context)

    if preserveUnavailable and context.cachedData then
        selected = addPotionData(S.CachedList(inputs.inventory, RCC.db.combatPotionItemIDs, preferredID)) or selected
    end

    return S.WithItemAction(S.Result(selected, candidates, preferredID), {
        preferenceKey = CacheKey.COMBAT_POTION,
        selectionOnly = true,
    })
end

function CombatPotion.GetItemCandidate(preserveUnavailable)
    return S.Unpack(CombatPotion.Select(RCC.ConsumableInputs.ReadSelection("combatpot"), preserveUnavailable))
end
