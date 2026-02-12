local _, RCC = ...
RCC.db = RCC.db or {}

-------------------------------------------------------------------------------
--- Food Item IDs (12.0.0 - Midnight)
--- Stored for future use. Not currently used by the addon.
--- "Hearty" variants are the same food but persist through death.
-------------------------------------------------------------------------------

RCC.db.foodItemIDs = {
    -- Epic
    262880, -- Vintage Purple Stuff
    242745, -- Hearty Blooming Feast
    266996, -- Hearty Harandar Celebration
    242744, -- Hearty Quel'dorei Medley
    267240, -- Boon of Fortitude
    266985, -- Hearty Silvermoon Parade
    267235, -- Boon of Vitality
    267236, -- Boon of Speed
    267238, -- Boon of Potency
    267239, -- Boon of Possibilities
    267648, -- Boon of Vigor
    267241, -- Boon of Abstinence
    267237, -- Boon of Power

    -- Rare
    255845, -- Silvermoon Parade
    242272, -- Quel'dorei Medley
    255846, -- Harandar Celebration
    242273, -- Blooming Feast
    242748, -- Hearty Braised Blood Hunter
    242776, -- Hearty Farstrider Rations
    242771, -- Hearty Spiced Biscuits
    242276, -- Braised Blood Hunter
    264391, -- Sanctified Touch
    242773, -- Hearty Forager's Medley
    242283, -- Sun-Seared Lumifin
    242287, -- Arcano Cutlets
    242775, -- Hearty Portable Snack
    255848, -- Flora Frenzy
    255847, -- Impossibly Royal Roast
    242286, -- Fel-Kissed Filet
    242762, -- Hearty Wise Tails
    242766, -- Hearty Felberry Figs
    242274, -- Champion's Bento
    242772, -- Hearty Silvermoon Standard
    242285, -- Warped Wise Wings
    242746, -- Hearty Champion's Bento
    242754, -- Hearty Null and Void Plate
    242759, -- Hearty Arcano Cutlets
    242768, -- Hearty Bloodthistle-Wrapped Cutlets
    242769, -- Hearty Bloom Skewers
    242277, -- Crimson Calamari
    242280, -- Buttered Root Crab
    242282, -- Null and Void Plate
    242275, -- Royal Roast
    242281, -- Glitter Skewers
    242757, -- Hearty Warped Wise Wings
    242763, -- Hearty Fried Bloomtail
    242765, -- Hearty Sunwell Delight
    242774, -- Hearty Quick Sandwich
    267649, -- Boon of Vigor
    242284, -- Void-Kissed Fish Rolls
    242751, -- Hearty Rootland Surprise
    242755, -- Hearty Sun-Seared Lumifin
    267000, -- Hearty Flora Frenzy
    242747, -- Hearty Royal Roast
    242760, -- Hearty Twilight Angler's Medley
    242750, -- Hearty Tasty Smoked Tetra
    242758, -- Hearty Fel-Kissed Filet
    242753, -- Hearty Glitter Skewers
    266986, -- Hearty Quel'dorei Medley
    268680, -- Hearty Flora Frenzy
    242749, -- Hearty Crimson Calamari
    242756, -- Hearty Void-Kissed Fish Rolls
    242767, -- Hearty Hearthflame Supper
    242278, -- Tasty Smoked Tetra
    242764, -- Hearty Eversong Pudding
    242770, -- Hearty Mana-Infused Stew
    242752, -- Hearty Buttered Root Crab
    260911, -- Boon of Fortitude
    264668, -- Boon of Speed
    268679, -- Hearty Impossibly Royal Roast
    242279, -- Baked Lucky Loa
    260882, -- Boon of Potency
    260884, -- Boon of Abstinence
    242761, -- Hearty Spellfire Filet
    260878, -- Boon of Possibilities
    260879, -- Boon of Power
    260910, -- Boon of Vitality

    -- Uncommon
    267647, -- Boon of Vigor
    242296, -- Bloodthistle-wrapped Cutlets
    242298, -- Argentleaf Tea
    242301, -- Azeroot Tea
    242288, -- Twilight Angler's Medley
    242294, -- Felberry Figs
    242297, -- Mana Lily Tea
    242300, -- Tranquility Bloom Tea
    242299, -- Sanguithorn Tea
    242293, -- Sunwell Delight
    242295, -- Hearthflame Supper
    242291, -- Fried Bloomtail
    242290, -- Wise Tails
    242289, -- Spellfire Filet
    249689, -- Ghostflower Tea with Sunfruit
    267243, -- Boon of Vitality
    267242, -- Boon of Speed
    242292, -- Eversong Pudding
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
