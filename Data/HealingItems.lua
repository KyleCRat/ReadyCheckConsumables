local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Healthstone
--------------------------------------------------------------------------------

RCC.db.healthstoneItemIDs = {
    [5512]   = { priority = 1 }, -- Healthstone
    [224464] = { priority = 2 }, -- Demonic Healthstone
}

RCC.db.healthstoneSpellIDs = {
    [6262] = true, -- Create Healthstone
}

--------------------------------------------------------------------------------
--- Healing Potion Item IDs
--- Used to check player inventory for healing potions.
--- Expansion files append their rows in priority order from strongest to
--- weakest for automatic selection. With a saved preference, matching fleeting
--- items override it; macro fallbacks try its family before other families.
--------------------------------------------------------------------------------

RCC.db.healingPotionItemIDs = {}
RCC.db.healingPotionItemData = {}

-- Automatic primary for buttons and macros inside a Brawler's Guild venue.
-- Keep it separate from the unrestricted potion list. These are UI map IDs;
-- Bizmo's Brawlpub has its own floor, separate from the Deeprun Tram (499).
RCC.db.brawlersGuildHealingPotionItemID = 253011
RCC.db.preferenceBlockedItemIDs[RCC.db.brawlersGuildHealingPotionItemID] = true
RCC.db.brawlersGuildMapIDs = {
    [500] = true, -- Bizmo's Brawlpub
    [503] = true, -- Brawl'gar Arena
}

RCC.Data = RCC.Data or {}

function RCC.Data.AddHealingPotionItems(items)
    if not items then return end

    for _, item in ipairs(items) do
        RCC.db.healingPotionItemIDs[#RCC.db.healingPotionItemIDs + 1] = item.itemID
        RCC.db.healingPotionItemData[item.itemID] = item

        if item.variant == RCC.ConsumableVariant.FLEETING then
            RCC.db.preferenceBlockedItemIDs[item.itemID] = true
        end
    end
end
