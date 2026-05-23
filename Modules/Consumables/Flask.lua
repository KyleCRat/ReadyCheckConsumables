local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Flask = RCC.Consumables.Flask or {}

local Flask = RCC.Consumables.Flask

local ItemCache = RCC.ConsumableFrameItemCache
local ItemCandidates = RCC.ConsumableFrameItemCandidates

local CacheKey = RCC.ConsumableItemCacheKey
local FLEETING = RCC.FlaskVariant.FLEETING
local FLASK = CacheKey.FLASK
local NO_ORDER = 999999

-- Higher priority wins. Ties use family and item order from Data/Flasks.lua.
local Priority = {
    SAME_FAMILY_FLEETING = 4,
    CACHED_ITEM = 3,
    SAME_FAMILY_OTHER_ITEM = 2,
    FALLBACK_FAMILY = 1,
}

local function getFlaskData(itemID)
    return itemID
        and RCC.db.flaskItemData
        and RCC.db.flaskItemData[itemID]
end

local function addFlaskData(candidate)
    if candidate and candidate.itemID then
        candidate.data = getFlaskData(candidate.itemID)
    end

    return candidate
end

local function getOrderValue(value)
    return value or NO_ORDER
end

local function collectFlaskCandidatesInBags()
    local candidates = ItemCandidates.CollectAvailableFromList(
        RCC.db.flaskItemIDs,
        ItemCandidates.BAGS_ONLY
    )

    for i = 1, #candidates do
        addFlaskData(candidates[i])
    end

    return candidates
end

local function createSelectionContext(cachedItemID)
    return {
        cachedItemID = cachedItemID,
        cachedData = getFlaskData(cachedItemID),
    }
end

local function getCandidatePriority(candidate, context)
    local data = candidate and candidate.data
    local cachedData = context.cachedData

    if not data then return end

    if not cachedData then
        return Priority.FALLBACK_FAMILY
    elseif data.familyIndex ~= cachedData.familyIndex then
        return Priority.FALLBACK_FAMILY
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

local function isBetterFlaskCandidate(candidate, currentSelection, context)
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

local function selectPreferredFlaskCandidate(candidates, context)
    return ItemCandidates.SelectBest(candidates, function(candidate,
                                                         currentSelection)
        return isBetterFlaskCandidate(candidate, currentSelection, context)
    end)
end

local function createCachedCandidate(context)
    if not context.cachedData then return end

    return addFlaskData(ItemCandidates.CreateFromList(
        RCC.db.flaskItemIDs,
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

function Flask.GetItemCandidate(includeUnavailableCached)
    local cachedItemID = ItemCache.Get(FLASK)
    local context = createSelectionContext(cachedItemID)
    local flaskCandidates = collectFlaskCandidatesInBags()
    local selectedCandidate = selectPreferredFlaskCandidate(
        flaskCandidates,
        context
    )
    local displayCandidate = getDisplayCandidate(
        context,
        selectedCandidate,
        includeUnavailableCached
    )
    local outOfCachedFlask = ItemCache.IsUnavailableCachedCandidate(
        FLASK,
        displayCandidate
    )

    return displayCandidate, flaskCandidates, outOfCachedFlask
end
