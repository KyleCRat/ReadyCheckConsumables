local _, RCC = ...
RCC.db = RCC.db or {}

-------------------------------------------------------------------------------
--- Flask Buff Spell IDs
--- Maps spell ID -> true for detecting flask auras on players.
-------------------------------------------------------------------------------

RCC.db.flaskBuffIDs = {
    -- 12.0.0 - Midnight
    [1235057] = true, -- Flask of Thalassian Resistance (Vers)
    [1235108] = true, -- Flask of the Magisters (Mastery)
    [1235110] = true, -- Flask of the Blood Knights (Haste)
    [1235111] = true, -- Flask of the Shattered Sun (Crit)

    -- 11.0.0 - The War Within
    [432021] = true, -- Flask of Alchemical Chaos
    [432473] = true, -- Flask of Saving Graces
    [431971] = true, -- Flask of Tempered Aggression
    [431972] = true, -- Flask of Tempered Swiftness
    [431974] = true, -- Flask of Tempered Mastery
    [431973] = true, -- Flask of Tempered Versatility

    -- 10.0.0 - Dragonflight
    [371339] = true, -- Phial of Elemental Chaos
    [374000] = true, -- Iced Phial of Corrupting Rage
    [371354] = true, -- Phial of the Eye in the Storm
    [371204] = true, -- Phial of Still Air
    [370662] = true, -- Phial of Icy Preservation
    [373257] = true, -- Phial of Glacial Fury
    [371386] = true, -- Phial of Charged Isolation
    [370652] = true, -- Phial of Static Empowerment
    [371172] = true, -- Phial of Tepid Versatility
    [371186] = true, -- Charged Phial of Alacrity

    -- 9.0.1 - Shadowlands
    [307187] = true, -- Spectral Stamina Flask
    [307185] = true, -- Spectral Flask of Power
    [307166] = true, -- Eternal Flask

    -- 8.0.1 - Battle for Azeroth
    [251838] = true, -- Flask of the Vast Horizon (Stamina)
    [251837] = true, -- Flask of Endless Fathoms (Intellect)
    [251836] = true, -- Flask of the Currents (Agility)
    [251839] = true, -- Flask of the Undertow (Strength)
    [298839] = true, -- Greater Flask of the Vast Horizon (Stamina)
    [298837] = true, -- Greater Flask of Endless Fathoms (Intellect)
    [298836] = true, -- Greater Flask of the Currents (Agility)
    [298841] = true, -- Greater Flask of the Undertow (Strength)
}

-------------------------------------------------------------------------------
--- Flask Item IDs
--- Used to check player inventory for flask items to offer the
--- click-to-use button. Order matters: first match wins.
-------------------------------------------------------------------------------

RCC.db.flaskItemIDs = {
    -- 12.0.0 - Fleeting
    245927, 245926, -- Fleeting Flask of Thalassian Resistance
    245932, 245933, -- Fleeting Flask of the Magisters
    245930, 245931, -- Fleeting Flask of the Blood Knights
    245928, 245929, -- Fleeting Flask of the Shattered Sun

    -- 12.0.0 - Full duration
    241320, 241321, -- Flask of Thalassian Resistance
    241322, 241323, -- Flask of the Magisters
    241324, 241325, -- Flask of the Blood Knights
    241326, 241327, -- Flask of the Shattered Sun

    -- 11.0.0 - Fleeting
    212741, 212740, 212739, -- Fleeting Flask of Alchemical Chaos
    212747, 212746, 212745, -- Fleeting Flask of Saving Graces
    212728, 212727, 212725, -- Fleeting Flask of Tempered Aggression
    212731, 212730, 212729, -- Fleeting Flask of Tempered Swiftness
    212738, 212736, 212735, -- Fleeting Flask of Tempered Mastery
    212734, 212733, 212732, -- Fleeting Flask of Tempered Versatility

    -- 11.0.0 - Full duration
    212283, 212282, 212281, -- Flask of Alchemical Chaos
    212301, 212300, 212299, -- Flask of Saving Graces
    212271, 212270, 212269, -- Flask of Tempered Aggression
    212274, 212273, 212272, -- Flask of Tempered Swiftness
    212280, 212279, 212278, -- Flask of Tempered Mastery
    212277, 212276, 212275, -- Flask of Tempered Versatility
}

-------------------------------------------------------------------------------
--- Cauldron Item IDs (12.0.0 - Midnight)
--- Stored for future use. Not currently tracked by the addon.
-------------------------------------------------------------------------------

RCC.db.cauldronItemIDs = {
    241284, 241285, -- Voidlight Potion Cauldron
    241318, 241319, -- Cauldron of Sin'dorei Flasks
}
