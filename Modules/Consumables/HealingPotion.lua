local _, RCC = ...
local HealingPotion = {}
RCC.Consumables.HealingPotion = HealingPotion
local S = RCC.ConsumableSelection
local KEY = RCC.ConsumableItemCacheKey.HEALING_POTION

HealingPotion.Inventory = { list = RCC.db.healingPotionItemIDs }

HealingPotion.Dependencies = { selection = { "inventory", "preferences.healingPotion" } }

function HealingPotion.Select(inputs, preserveUnavailable)
    local candidates = S.List(inputs.inventory, RCC.db.healingPotionItemIDs)
    local preferredID = inputs.preferences[KEY]
    local selected = S.Preferred(candidates, preferredID)
    -- UI preserves an unavailable preference; macros use the available fallback.
    if preserveUnavailable then
        selected = S.CachedList(inputs.inventory, RCC.db.healingPotionItemIDs, preferredID) or selected
    end
    return S.WithItemAction(S.Result(selected, candidates, preferredID), {
        preferenceKey = KEY, selectionOnly = true,
    })
end

function HealingPotion.GetItemCandidate(preserveUnavailable)
    return S.Unpack(HealingPotion.Select(RCC.ConsumableInputs.ReadSelection("healpot"), preserveUnavailable))
end
