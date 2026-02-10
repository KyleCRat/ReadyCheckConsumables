local _, RCC = ...
RCC.db = RCC.db or {}

-------------------------------------------------------------------------------
--- Flask Buff IDs
--- Maps spell ID -> stat tier for detecting flask auras on players.
-------------------------------------------------------------------------------

RCC.db.flaskBuffIDs = {
    -- 8.0.1 - Battle for Azeroth
    [251838] = 15, -- Flask of the Vast Horizon (Stamina)
    [251837] = 15, -- Flask of Endless Fathoms (Intellect)
    [251836] = 15, -- Flask of the Currents (Agility)
    [251839] = 15, -- Flask of the Undertow (Strength)
    [298839] = 22, -- Greater Flask of the Vast Horizon (Stamina)
    [298837] = 22, -- Greater Flask of Endless Fathoms (Intellect)
    [298836] = 22, -- Greater Flask of the Currents (Agility)
    [298841] = 22, -- Greater Flask of the Undertow (Strength)

    -- 9.0.1 - Shadowlands
    [307187] = 26, -- Spectral Stamina Flask
    [307185] = 18, -- Spectral Flask of Power
    [307166] = 70, -- Eternal Flask

    -- 10.0.0 - Dragonflight
    [371339] = 70, -- Phial of Elemental Chaos
    [374000] = 70, -- Iced Phial of Corrupting Rage
    [371354] = 70, -- Phial of the Eye in the Storm
    [371204] = 70, -- Phial of Still Air
    [370662] = 70, -- Phial of Icy Preservation
    [373257] = 70, -- Phial of Glacial Fury
    [371386] = 70, -- Phial of Charged Isolation
    [370652] = 70, -- Phial of Static Empowerment
    [371172] = 70, -- Phial of Tepid Versatility
    [371186] = 70, -- Charged Phial of Alacrity

    -- 11.0.0 - The War Within
    [432021] = 70, -- Flask of Alchemical Chaos
    [432473] = 70, -- Flask of Saving Graces
    [431971] = 70, -- Flask of Tempered Aggression
    [431972] = 70, -- Flask of Tempered Swiftness
    [431974] = 70, -- Flask of Tempered Mastery
    [431973] = 70, -- Flask of Tempered Versatility
}

-------------------------------------------------------------------------------
--- Flask Item IDs
--- Used to check player inventory for flask items to offer the
--- click-to-use button. Order matters: first match wins.
-------------------------------------------------------------------------------

RCC.db.flaskItemIDs = {
    -- 11.0.0 - Fleeting (shorter duration)
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
