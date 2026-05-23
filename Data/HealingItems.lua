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

RCC.Data = RCC.Data or {}

function RCC.Data.AddHealingPotionItems(itemIDs)
    if not itemIDs then return end

    for i = 1, #itemIDs do
        RCC.db.healingPotionItemIDs[#RCC.db.healingPotionItemIDs + 1] =
            itemIDs[i]
    end
end
