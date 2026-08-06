local _, RCC = ...

RCC.Data.AddFeastItems({
    242745, -- [Epic] Hearty Blooming Feast       | 98 Stam, 65 Primary Stat
    266996, -- [Epic] Hearty Harandar Celebration | 98 Stam, 65 Primary Stat
    242744, -- [Epic] Hearty Quel'dorei Medley    | 98 Stam, 65 Primary Stat
    266985, -- [Epic] Hearty Silvermoon Parade    | 98 Stam, 65 Primary Stat
    266986, -- [Rare] Hearty Quel'dorei Medley    | 98 Stam, 65 Primary Stat

    242273, -- [Rare] Blooming Feast         | 98 Stam, 65 Highest Secondary Stat
    242272, -- [Rare] Quel'dorei Medley      | 98 Stam, 65 Highest Secondary Stat
    255846, -- [Rare] Harandar Celebration   | 98 Stam, 50 Primary Stat
    255845, -- [Rare] Silvermoon Parade      | 98 Stam, 50 Primary Stat
    255847, -- [Rare] Impossibly Royal Roast | 98 Stam, 50 Primary Stat
})

-- Placement spells observed by Northern Sky Raid Tools. Keeping explicit IDs
-- makes detection available before the client has cached the feast item data.
RCC.Data.AddFeastSpells({
    1259657, -- Quel'dorei Medley
    1278915, -- Hearty Quel'dorei Medley
    1259658, -- Harandar Celebration
    1278929, -- Hearty Harandar Celebration
    1237104, -- Blooming Feast
    1278909, -- Hearty Blooming Feast
    1259659, -- Silvermoon Parade
    1278895, -- Hearty Silvermoon Parade
})
