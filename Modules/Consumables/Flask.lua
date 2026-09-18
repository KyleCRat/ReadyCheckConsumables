local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Flask = RCC.Consumables.Flask or {}

local Flask = RCC.Consumables.Flask

local S = RCC.ConsumableSelection

local CacheKey = RCC.ConsumableItemCacheKey
local FLEETING = RCC.FlaskVariant.FLEETING
local FLASK = CacheKey.FLASK
local NO_ORDER = 999999

Flask.Inventory = { list = RCC.db.flaskItemIDs }

Flask.Dependencies = {
    selection = { "inventory", "preferences.flask" },
    observation = { "playerAuras" },
    evaluation = { "instance.warningSeconds" },
    expiration = "playerAuras",
}

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

local function collectFlaskCandidates(inventory)
    local candidates = S.List(inventory, RCC.db.flaskItemIDs)

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
    return S.Best(candidates, function(candidate, currentSelection)
        return isBetterFlaskCandidate(candidate, currentSelection, context)
    end)
end

function Flask.Select(inputs, preserveUnavailable)
    local preferredID = inputs.preferences[FLASK]
    local context = createSelectionContext(preferredID)
    local candidates = collectFlaskCandidates(inputs.inventory)
    local selected = selectPreferredFlaskCandidate(candidates, context)

    if preserveUnavailable and context.cachedData then
        selected = addFlaskData(S.CachedList(inputs.inventory, RCC.db.flaskItemIDs, preferredID)) or selected
    end

    return S.WithItemAction(S.Result(selected, candidates, preferredID), { preferenceKey = FLASK })
end

function Flask.GetItemCandidate(preserveUnavailable)
    return S.Unpack(Flask.Select(RCC.ConsumableInputs.ReadSelection("flask"), preserveUnavailable))
end

function Flask.Observe(inputs)
    return RCC.ConsumableEffects.Observe(inputs.playerAuras, RCC.db.flaskBuffIDs)
end

function Flask.Evaluate(selection, observation, inputs, now)
    return RCC.ConsumableEffects.Evaluate(selection, observation, inputs.instance, now)
end
