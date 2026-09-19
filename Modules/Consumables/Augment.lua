local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Augment = RCC.Consumables.Augment or {}

local Augment = RCC.Consumables.Augment

local S = RCC.ConsumableSelection

local CacheKey = RCC.ConsumableItemCacheKey

Augment.Inventory = {
    map = RCC.db.augmentItemIDs,
    cooldownItemIDs = {},
}

for itemID, data in pairs(RCC.db.augmentItemIDs) do
    if data.unlimited then
        local itemIDs = Augment.Inventory.cooldownItemIDs
        itemIDs[#itemIDs + 1] = itemID
    end
end

Augment.Dependencies = {
    selection = {
        "inventory",
        "cooldowns",
        "preferences.augment",
        "preferences.preferUnlimitedAugment",
    },
    observation = { "playerAuras" },
    evaluation = { "instance.warningSeconds" },
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

function Augment.GetCountText(candidate)
    local data = candidate and candidate.data

    if data and data.unlimited then
        return ""
    end

    return tostring(candidate and candidate.count or 0)
end

-- Prefer Unlimited changes automatic ordering, not an explicit item choice.
-- Cooldowns are display-only and never cause a different rune to be selected.
function Augment.Select(inputs)
    local preferUnlimited = inputs.preferences.preferUnlimitedAugment
    local candidates = S.Map(inputs.inventory, RCC.db.augmentItemIDs, {
        compare = function(a, b)
            return isBetterAugmentCandidate(a, b, preferUnlimited)
        end,
    })

    local preferredID = inputs.preferences[CacheKey.AUGMENT]
    local preferred = S.FindMapItem(inputs.inventory, RCC.db.augmentItemIDs, preferredID)

    local selection = {
        preferred = preferred,
        fallbacks = candidates,
        candidates = candidates,
    }

    S.ApplyItemCooldowns(selection, inputs.cooldowns, Augment.Inventory.cooldownItemIDs)

    return S.Resolve(selection, {
        preferenceKey = CacheKey.AUGMENT,
    })
end

function Augment.Observe(inputs)
    return RCC.ConsumableEffects.Observe(inputs.playerAuras, RCC.db.augmentBuffIDs)
end

function Augment.Evaluate(selection, observation, inputs, now)
    return RCC.ConsumableEffects.Evaluate(selection, observation, inputs.instance, now)
end
