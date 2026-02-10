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
}
