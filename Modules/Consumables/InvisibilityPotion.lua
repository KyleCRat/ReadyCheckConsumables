local _, RCC = ...

local InvisibilityPotion = {}
RCC.Consumables.InvisibilityPotion = InvisibilityPotion
local Selection = RCC.ConsumableSelection
local PREFERENCE_KEY = RCC.ConsumablePreferenceKey.INVISIBILITY_POTION

InvisibilityPotion.Inventory = {
    list = RCC.db.invisibilityPotionItemIDs,
    cooldownItemIDs = RCC.db.invisibilityPotionItemIDs,
}

-- Invisibility is an on-demand utility, not a buff to keep active for readiness.
-- Inventory and cooldowns are sufficient; this button never requests aura scans.
InvisibilityPotion.Dependencies = {
    selection = { "inventory", "cooldowns", "preferences.invisibilityPotion" },
}

function InvisibilityPotion.Select(inputs)
    local choices = Selection.FamilyCandidates(inputs.inventory, {
        itemIDs = RCC.db.invisibilityPotionItemIDs,
        itemData = RCC.db.invisibilityPotionItemData,
        preferredID = RCC.ConsumablePreferences.GetItemID(inputs.preferences, PREFERENCE_KEY),
    })

    choices.defaultCandidate = Selection.Item(inputs.inventory, RCC.db.invisibilityPotionItemIDs[1])
    Selection.ApplyItemCooldowns(choices, inputs.cooldowns, InvisibilityPotion.Inventory.cooldownItemIDs)

    return Selection.Resolve(choices, { preferenceKey = PREFERENCE_KEY })
end
