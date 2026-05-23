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
--- Healing Potion Spell IDs
--- Maps spell ID -> true for detecting healing potion aura buffs.
--- Stored for future use. Not currently used by the addon.
--------------------------------------------------------------------------------

RCC.db.healingPotionSpellIDs = {
    [1234768] = true, -- 12.0.0: Silvermoon Health Potion
    [1263074] = true, -- 12.0.0: Amani Extract
    [1236590] = true, -- 12.0.0: Refreshing Serum

    [1238009] = true, -- 11.2.0: Invigorating Healing Potion
    [431416]  = true, -- 11.0.0: Algari Healing Potion
    [431419]  = true, -- 11.0.0: Cavedweller's Delight

    [370511]  = true, -- 10.0.0: Refreshing Healing Potion

    [307192]  = true, -- 9.0.1: Spiritual Healing Potion

    [301308]  = true, -- 8.0.1: Abyssal Healing Potion
    [250870]  = true, -- 8.0.1: Coastal Healing Potion

    [188016]  = true, -- 7.0.1: Ancient Healing Potion

    [156438]  = true, -- 6.0.1: Healing Tonic

    [105708]  = true, -- 5.0.4: Healing Potion
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
