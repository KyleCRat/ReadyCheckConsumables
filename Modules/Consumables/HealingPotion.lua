local _, RCC = ...
local HealingPotion = {}
RCC.Consumables.HealingPotion = HealingPotion
local S = RCC.ConsumableSelection
local KEY = RCC.ConsumableItemCacheKey.HEALING_POTION

HealingPotion.Inventory = {
    list = RCC.db.healingPotionItemIDs,
    itemID = RCC.db.brawlersGuildHealingPotionItemID,
}

HealingPotion.Dependencies = {
    selection = { "inventory", "preferences.healingPotion", "context.uiMapID" },
}

function HealingPotion.Select(inputs, preserveUnavailable)
    local candidates = S.List(inputs.inventory, RCC.db.healingPotionItemIDs)

    if RCC.db.brawlersGuildMapIDs[inputs.context.uiMapID] then
        local brawlersPotion = S.Item(inputs.inventory, RCC.db.brawlersGuildHealingPotionItemID)

        if brawlersPotion and brawlersPotion.count > 0 then
            table.insert(candidates, 1, brawlersPotion)

            -- The venue potion is automatic, not a saved preference. Normal
            -- potions remain in the flyout so their preferences can still be set.
            return S.WithItemAction(S.Result(brawlersPotion, candidates), {
                selectionOnly = true,
            })
        end
    end

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
