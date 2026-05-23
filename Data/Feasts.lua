local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Feast Item IDs (12.0.0 - Midnight)
--- Stored for future use. Not currently used by the addon.
--- "Hearty" variants are the same food but persist through death.
--------------------------------------------------------------------------------

RCC.db.feastItemIDs = {
    242745, -- [Epic] Hearty Blooming Feast       | 98 Stam, 65 Primary Stat
    266996, -- [Epic] Hearty Harandar Celebration | 98 Stam, 65 Primary Stat
    242744, -- [Epic] Hearty Quel'dorei Medley    | 98 Stam, 65 Primary Stat
    266985, -- [Epic] Hearty Silvermoon Parade    | 98 Stam, 65 Primary Stat
    266986, -- [Rare] Hearty Quel'dorei Medley    | 98 Stam, 65 Primary Stat

    242273, -- [Rare] Blooming Feast    | 98 Stam, 65 Highest Secondary Stat
    242272, -- [Rare] Quel'dorei Medley | 98 Stam, 65 Highest Secondary Stat

    255846, -- [Rare] Harandar Celebration   | 98 Stam, 50 Primary Stat
    255845, -- [Rare] Silvermoon Parade      | 98 Stam, 50 Primary Stat
    255847, -- [Rare] Impossibly Royal Roast | 98 Stam, 50 Primary Stat
}
