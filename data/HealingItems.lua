local _, RCC = ...
RCC.db = RCC.db or {}

-------------------------------------------------------------------------------
--- Healing Item Spell IDs
--- Maps spell ID -> true for detecting healthstone / healing potion usage.
-------------------------------------------------------------------------------

RCC.db.hsSpells = {
    [6262]    = true, -- Healthstone
    [105708]  = true, -- 5.0.4: Healing Potion
    [156438]  = true, -- 6.0.1: Healing Tonic
    [188016]  = true, -- 7.0.1: Ancient Healing Potion
    [250870]  = true, -- 8.0.1: Coastal Healing Potion
    [301308]  = true, -- 8.0.1: Abyssal Healing Potion
    [307192]  = true, -- 9.0.1: Spiritual Healing Potion
    [370511]  = true, -- 10.0.0: Refreshing Healing Potion
    [431419]  = true, -- 11.0.0: Cavedweller's Delight
    [431416]  = true, -- 11.0.0: Algari Healing Potion
    [1238009] = true, -- 11.2.0: Invigorating Healing Potion
    [1234768] = true, -- 12.0.0: Silvermoon Health Potion
    [1263074] = true, -- 12.0.0: Amani Extract
    [1236590] = true, -- 12.0.0: Refreshing Serum
}

-------------------------------------------------------------------------------
--- Healing Potion Item IDs
--- Used to check player inventory for healing potions.
--- All items are summed for total count.
-------------------------------------------------------------------------------

RCC.db.healingPotionItemIDs = {
    -- 12.0.0 - Full duration
    241304, 241305, -- Silvermoon Health Potion
    241298, 241299, -- Amani Extract
    241306, 241307, -- Refreshing Serum

    -- 11.2.0 - Fleeting
    244849,                 -- Fleeting Invigorating Healing Potion

    -- 11.2.0 - Full duration
    244835, 244838, 244839, -- Invigorating Healing Potion

    -- 11.0.0 - Fleeting
    212948, 212949, 212950, -- Fleeting Cavedweller's Delight
    212942, 212943, 212944, -- Fleeting Algari Healing Potion

    -- 11.0.0 - Full duration
    212242, 212243, 212244, -- Cavedweller's Delight
    211878, 211879, 211880, -- Algari Healing Potion
}
