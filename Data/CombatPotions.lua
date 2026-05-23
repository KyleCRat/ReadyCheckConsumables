local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Combat Potion Item IDs
--- `combatPotionItems` is the editable source of truth for combat potion
--- families. Family order controls fallback order; item order inside a family
--- controls priority when quality metadata is incomplete.
--------------------------------------------------------------------------------

RCC.CombatPotionType = RCC.CombatPotionType or {
    MANA    = "mana_potion",
    DAMAGE  = "damage_potion",
    UTILITY = "utility_potion",
}

RCC.CombatPotionVariant = RCC.CombatPotionVariant or {
    FLEETING = "fleeting",
}

-- Expansion files append their rows through AddCombatPotionItems so the rest
-- of the addon can keep reading one combined set of combat potion tables.
RCC.db.combatPotionItemIDs = {}
RCC.db.combatPotionItemData = {}
RCC.db.combatPotionItems = {}

RCC.Data = RCC.Data or {}

function RCC.Data.AddCombatPotionItems(families)
    if not families then return end

    for i = 1, #families do
        local family = families[i]
        local items = family.items or {}
        local familyIndex = #RCC.db.combatPotionItems + 1

        family.index = familyIndex
        RCC.db.combatPotionItems[familyIndex] = family

        for itemIndex = 1, #items do
            local item = items[itemIndex]
            local itemID = item.itemID

            item.familyIndex = familyIndex
            item.itemIndex = itemIndex
            item.type = family.type
            item.xpac = item.xpac or family.xpac

            RCC.db.combatPotionItemIDs[#RCC.db.combatPotionItemIDs + 1] =
                itemID
            RCC.db.combatPotionItemData[itemID] = item
        end
    end
end
