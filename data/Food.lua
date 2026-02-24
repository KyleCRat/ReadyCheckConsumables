local _, RCC = ...
RCC.db = RCC.db or {}

-------------------------------------------------------------------------------
--- Food Item IDs (12.0.0 - Midnight)
--- Stored for future use. Not currently used by the addon.
--- "Hearty" variants are the same food but persist through death.
-------------------------------------------------------------------------------

RCC.db.foodItemIDs = {
    -- Alcohol
    262880, -- Vintage Purple Stuff

    ----------------------------------------------------------------------------
    --- Feasts

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


    ----------------------------------------------------------------------------
    --- Personal Food

    242275, -- [Rare] Royal Roast                   | 50 Primary Stat
    242279, -- [Rare] Baked Lucky Loa               | 46 Primary Stat

    242274, -- [Rare] Champion's Bento              | 65 Highest Secondary Stat
    255848, -- [Rare] Flora Frenzy                  | 65 Highest Secondary Stat

    242287, -- [Rare] Arcano Cutlets                | 59 Critical Strike
    242278, -- [Rare] Tasty Smoked Tetra            | 59 Critical Strike
    242283, -- [Rare] Sun-Seared Lumifin            | 59 Critical Strike
    242277, -- [Rare] Crimson Calamari              | 59 Haste
    242286, -- [Rare] Fel-Kissed Filet              | 59 Haste
    242282, -- [Rare] Null and Void Plate           | 59 Haste
    242285, -- [Rare] Warped Wise Wings             | 59 Mastery
    242281, -- [Rare] Glitter Skewers               | 59 Mastery
    242276, -- [Rare] Braised Blood Hunter          | 59 Versatility
    242280, -- [Rare] Buttered Root Crab            | 59 Versatility
    242284, -- [Rare] Void-Kissed Fish Rolls        | 59 Versatility

    242747, -- [Rare] Hearty Royal Roast            | 50 Primary Stat
    268679, -- [Rare] Hearty Impossibly Royal Roast | 50 Primary Stat
    242751, -- [Rare] Hearty Rootland Surprise      | 46 Primary Stat
    242760, -- [Rare] Hearty Twilight Angler's Medl | 35 Primary Stat
    242761, -- [Rare] Hearty Spellfire Filet        | 35 Primary Stat
    242769, -- [Rare] Hearty Bloom Skewers          | 25 Primary Stat
    242770, -- [Rare] Hearty Mana-Infused Stew      | 25 Primary Stat

    242746, -- [Rare] Hearty Champion's Bento       | 65 Highest Secondary Stat
    268680, -- [Rare] Hearty Flora Frenzy           | 65 Highest Secondary Stat

    242750, -- [Rare] Hearty Tasty Smoked Tetra     | 59 Critical Strike
    242759, -- [Rare] Hearty Arcano Cutlets         | 59 Critical Strike
    242755, -- [Rare] Hearty Sun-Seared Lumifin     | 59 Critical Strike

    242749, -- [Rare] Hearty Crimson Calamari       | 59 Haste
    242758, -- [Rare] Hearty Fel-Kissed Filet       | 59 Haste
    242754, -- [Rare] Hearty Null and Void Plate    | 59 Haste

    242753, -- [Rare] Hearty Glitter Skewers        | 59 Mastery
    242757, -- [Rare] Hearty Warped Wise Wings      | 59 Mastery

    242752, -- [Rare] Hearty Buttered Root Crab     | 59 Versatility
    242756, -- [Rare] Hearty Void-Kissed Fish Rolls | 59 Versatility
    242748, -- [Rare] Hearty Braised Blood Hunter   | 59 Versatility
    242766, -- [Rare] Hearty Felberry Figs          | 46 Versatility

    242767, -- [Rare] Hearty Hearthflame Supper     | 22 Critical Strike, 22 Haste
    242775, -- [Rare] Hearty Portable Snack         | 16 Critical Strike, 16 Haste

    242762, -- [Rare] Hearty Wise Tails             | 22 Critical Strike, 22 Versatility
    242771, -- [Rare] Hearty Spiced Biscuits        | 16 Critical Strike, 16 Versatility

    242764, -- [Rare] Hearty Eversong Pudding       | 22 Mastery, 22 Critical Strike
    242773, -- [Rare] Hearty Forager's Medley       | 16 Mastery, 16 Critical Strike

    242768, -- [Rare] Hearty Bloodthistle-Wrapped C | 22 Mastery, 22 Haste
    242776, -- [Rare] Hearty Farstrider Rations     | 16 Mastery, 16 Haste

    242763, -- [Rare] Hearty Fried Bloomtail        | 22 Mastery, 22 Versatility
    242772, -- [Rare] Hearty Silvermoon Standard    | 16 Mastery, 16 Versatility

    242765, -- [Rare] Hearty Sunwell Delight        | 22 Versatility, 22 Haste
    242774, -- [Rare] Hearty Quick Sandwich         | 16 Versatility, 16 Haste


    242288, -- [Uncm] Twilight Angler's Medley      | 35 Primary Stat
    242289, -- [Uncm] Spellfire Filet               | 35 Primary Stat

    242295, -- [Uncm] Hearthflame Supper            | 22 Critical Strike, 22 Haste
    242290, -- [Uncm] Wise Tails                    | 22 Critical Strike, 22 Versatility
    242292, -- [Uncm] Eversong Pudding              | 22 Mastery, 22 Critical Strike
    242296, -- [Uncm] Bloodthistle-Wrapped Cutlets  | 22 Mastery, 22 Haste
    242291, -- [Uncm] Fried Bloomtail               | 22 Mastery, 22 Versatility
    242293, -- [Uncm] Sunwell Delight               | 22 Versatility, 22 Haste

    242294, -- [Uncm] Felberry Figs                 | 46 Versatility

    242297, -- [Uncm] Mana Lily Tea                 | Mana
    242298, -- [Uncm] Argentleaf Tea                | Mana
    242299, -- [Uncm] Sanguithorn Tea               | Mana
    242300, -- [Uncm] Tranquility Bloom Tea         | Mana
    242301, -- [Uncm] Azeroot Tea                   | Mana
    249689, -- [Uncm] Ghostflower Tea with Sunfruit | Mana

    ----------------------------------------------------------------------------
    --- Boon

    -- Epic Boon's
    267240, -- Boon of Fortitude
    267235, -- Boon of Vitality
    267236, -- Boon of Speed
    267238, -- Boon of Potency
    267239, -- Boon of Possibilities
    267648, -- Boon of Vigor
    267241, -- Boon of Abstinence
    267237, -- Boon of Power

    -- Rare Boon's
    260878, -- Boon of Possibilities
    260879, -- Boon of Power
    260882, -- Boon of Potency
    260884, -- Boon of Abstinence
    260910, -- Boon of Vitality
    260911, -- Boon of Fortitude
    264668, -- Boon of Speed
    267649, -- Boon of Vigor

    -- Uncommon Boon's
    267647, -- Boon of Vigor
    267243, -- Boon of Vitality
    267242, -- Boon of Speed
}

-------------------------------------------------------------------------------
--- Food Buff Spell IDs
--- Maps spell ID -> true for detecting Well Fed auras on players.
--- Also detected by icon ID (136000) as a fallback.
-------------------------------------------------------------------------------

RCC.db.foodBuffIDs = {
    -- 8.0.1 - Battle for Azeroth
    [257413] = true, -- Haste 5
    [257415] = true, -- Haste 7
    [297034] = true, -- Haste 9
    [257418] = true, -- Mastery 5
    [257420] = true, -- Mastery 7
    [297035] = true, -- Mastery 9
    [257408] = true, -- Crit 5
    [257410] = true, -- Crit 7
    [297039] = true, -- Crit 9
    [185736] = true, -- Versatility 3
    [257422] = true, -- Versatility 5
    [257424] = true, -- Versatility 7
    [297037] = true, -- Versatility 9
    [259449] = true, -- Intellect 7
    [259455] = true, -- Intellect 10
    [290468] = true, -- Intellect 8
    [297117] = true, -- Intellect 10
    [259452] = true, -- Strength 7
    [259456] = true, -- Strength 10
    [290469] = true, -- Strength 8
    [297118] = true, -- Strength 10
    [259448] = true, -- Agility 7
    [259454] = true, -- Agility 10
    [290467] = true, -- Agility 8
    [297116] = true, -- Agility 10
    [259453] = true, -- Stamina 11
    [259457] = true, -- Stamina 15
    [288074] = true, -- Stamina 11
    [288075] = true, -- Stamina 15
    [297119] = true, -- Stamina 16
    [297040] = true, -- Stamina 19
    [285719] = true, -- Rebirth Well Fed 5
    [285720] = true, -- Rebirth Well Fed 8
    [285721] = true, -- Rebirth Well Fed 8
    [286171] = true, -- Melee atk speed reduction 10

    -- 10.0.0 - Dragonflight
    [308488] = true, -- Haste 30
    [308506] = true, -- Mastery 30
    [308434] = true, -- Crit 30
    [308514] = true, -- Versatility 30
    [327708] = true, -- Intellect 20
    [327706] = true, -- Strength 20
    [327709] = true, -- Agility 20
    [308525] = true, -- Stamina 30
    [327707] = true, -- Stamina 30
    [308637] = true, -- Special 30
    [308474] = true, -- Haste 18
    [308504] = true, -- Mastery 18
    [308430] = true, -- Crit 18
    [308509] = true, -- Versatility 18
    [327704] = true, -- Intellect 18
    [327701] = true, -- Strength 18
    [327705] = true, -- Agility 18
    [327702] = true, -- Stamina 18
    [382145] = true, -- Haste 70
    [382150] = true, -- Mastery 70
    [382146] = true, -- Crit 70
    [382149] = true, -- Versatility 70
    [396092] = true, -- Intellect 90
    [382246] = true, -- Stamina 70
    [382247] = true, -- Stamina 90
    [382152] = true, -- Haste/Crit 90
    [382153] = true, -- Haste/Versatility 90
    [382157] = true, -- Versatility/Mastery 90
    [382230] = true, -- Stamina/Strength 70
    [382231] = true, -- Stamina/Agility 70
    [382232] = true, -- Stamina/Intellect 70
    [382154] = true, -- Haste/Mastery 90
    [382155] = true, -- Crit/Versatility 90
    [382156] = true, -- Crit/Mastery 90
    [382234] = true, -- Stamina/Strength 90
    [382235] = true, -- Stamina/Agility 90
    [382236] = true, -- Stamina/Intellect 90
}
