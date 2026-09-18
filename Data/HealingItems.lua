local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Healthstone
--------------------------------------------------------------------------------

RCC.db.healthstoneItemIDs = {
    [5512]   = true, -- Healthstone
    [224464] = true, -- Demonic Healthstone
}

RCC.db.healthstoneSpellIDs = {
    [6262] = true, -- Create Healthstone
}

--------------------------------------------------------------------------------
--- Healing Potion Item IDs
--- Used to check player inventory for healing potions.
--- Expansion files append their rows in priority order from strongest to
--- weakest. If the preferred healing potion is unavailable, the macro falls
--- back to the first available item found from top to bottom.
--------------------------------------------------------------------------------

RCC.db.healingPotionItemIDs = {}

-- Automatic primary for buttons and macros inside a Brawler's Guild venue.
-- Keep it separate from the unrestricted potion list. These are UI map IDs;
-- Bizmo's Brawlpub has its own floor, separate from the Deeprun Tram (499).
RCC.db.brawlersGuildHealingPotionItemID = 253011
RCC.db.brawlersGuildMapIDs = {
    [500] = true, -- Bizmo's Brawlpub
    [503] = true, -- Brawl'gar Arena
}

RCC.Data = RCC.Data or {}

function RCC.Data.AddHealingPotionItems(itemIDs)
    if not itemIDs then return end

    for i = 1, #itemIDs do
        RCC.db.healingPotionItemIDs[#RCC.db.healingPotionItemIDs + 1] =
            itemIDs[i]
    end
end
