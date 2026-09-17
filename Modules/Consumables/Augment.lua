local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Augment = RCC.Consumables.Augment or {}

local Augment = RCC.Consumables.Augment

local S = RCC.ConsumableSelection

local CacheKey = RCC.ConsumableItemCacheKey

Augment.Inventory = { map = RCC.db.augmentItemIDs }

Augment.Dependencies = {
    selection = { "inventory", "preferences.augment", "preferences.preferUnlimitedAugment" },
    observation = { "playerAuras" }, evaluation = { "context.warningSeconds" },
    expiration = "playerAuras",
}

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

function Augment.Select(inputs, preserveUnavailable)
    local candidates = S.Map(inputs.inventory, RCC.db.augmentItemIDs)
    sortAugmentCandidates(candidates, inputs.preferences.preferUnlimitedAugment)
    local preferredID = inputs.preferences[CacheKey.AUGMENT]
    local cached = preserveUnavailable and S.CachedMap(inputs.inventory, RCC.db.augmentItemIDs, preferredID)
    return S.WithItemAction(S.Result(S.Preferred(candidates, preferredID, cached), candidates, preferredID), {
        preferenceKey = CacheKey.AUGMENT,
    })
end

function Augment.GetItemCandidate(preserveUnavailable)
    return S.Unpack(Augment.Select(RCC.ConsumableInputs.ReadSelection("augment"), preserveUnavailable))
end

function Augment.Observe(inputs)
    return RCC.ConsumableEffects.Observe(inputs.playerAuras, RCC.db.augmentBuffIDs)
end

function Augment.Evaluate(selection, observation, inputs, now)
    return RCC.ConsumableEffects.Evaluate(selection, observation, inputs.context, now)
end
