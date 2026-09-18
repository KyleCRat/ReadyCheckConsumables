local _, RCC = ...

local CombatPotion = {}
RCC.Consumables.CombatPotion = CombatPotion
local Selection = RCC.ConsumableSelection
local PREFERENCE_KEY = RCC.ConsumableItemCacheKey.COMBAT_POTION

CombatPotion.Inventory = { list = RCC.db.combatPotionItemIDs }

CombatPotion.Dependencies = {
    selection = { "inventory", "preferences.combatPotion" },
}

-- Fleeting overrides stay within the preferred family. Damage and mana macro
-- fallbacks may cross families within their type; utility stays in its family.
-- All carried items remain available for manual choice in the flyout.
local function canFallbackToFamily(preferredData, candidateData)
    return preferredData.type ~= RCC.CombatPotionType.UTILITY
        and preferredData.type == candidateData.type
end

function CombatPotion.Select(inputs)
    local choices = Selection.FamilyCandidates(inputs.inventory, {
        itemIDs = RCC.db.combatPotionItemIDs,
        itemData = RCC.db.combatPotionItemData,
        preferredID = inputs.preferences[PREFERENCE_KEY],
        canFallbackToFamily = canFallbackToFamily,
    })

    return Selection.Resolve(choices, {
        preferenceKey = PREFERENCE_KEY,
        selectionOnly = true,
    })
end
