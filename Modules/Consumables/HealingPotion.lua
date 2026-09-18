local _, RCC = ...

local HealingPotion = {}
RCC.Consumables.HealingPotion = HealingPotion
local Selection = RCC.ConsumableSelection
local PREFERENCE_KEY = RCC.ConsumableItemCacheKey.HEALING_POTION

HealingPotion.Inventory = {
    list = RCC.db.healingPotionItemIDs,
    itemID = RCC.db.brawlersGuildHealingPotionItemID,
}

HealingPotion.Dependencies = {
    selection = { "inventory", "preferences.healingPotion", "location.uiMapID" },
}

function HealingPotion.Select(inputs)
    local choices = Selection.FamilyCandidates(inputs.inventory, {
        itemIDs = RCC.db.healingPotionItemIDs,
        itemData = RCC.db.healingPotionItemData,
        preferredID = inputs.preferences[PREFERENCE_KEY],
    })

    if RCC.db.brawlersGuildMapIDs[inputs.location.uiMapID] then
        local guildPotion = Selection.Item(inputs.inventory, RCC.db.brawlersGuildHealingPotionItemID)

        if guildPotion and guildPotion.count > 0 then
            -- The venue override precedes matching fleeting items. Its own
            -- count/action are displayed, without changing the normal choice.
            table.insert(choices.overrides, 1, guildPotion)
            table.insert(choices.candidates, 1, guildPotion)
        end
    end

    return Selection.Resolve(choices, {
        preferenceKey = PREFERENCE_KEY,
        selectionOnly = true,
    })
end
