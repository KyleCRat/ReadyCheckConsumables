local _, RCC = ...
RCC.db = RCC.db or {}

-------------------------------------------------------------------------------
--- Potion Spell IDs
--- Maps spell ID -> true for detecting potion usage via aura scanning.
-------------------------------------------------------------------------------

RCC.db.tablePotion = {
    -- 12.0.0 - Midnight
    [1236616] = true, -- Light's Potential
    [1236998] = true, -- Draught of Rampant Abandon
    [1236994] = true, -- Potion of Recklessness
    [1238443] = true, -- Potion of Zealotry
    [1235568] = true, -- Light's Preservation
    [1236648] = true, -- Lightfused Mana Potion
    [1239479] = true, -- Potion of Devoured Dreams

    -- 11.2.0
    [1247091] = true, -- Shrouded in Shadows

    -- 11.0.0 - The War Within
    [431932] = true, -- Tempered Potion
    [431419] = true, -- Cavedweller's Delight
    [431416] = true, -- Algari Healing Potion
    [431424] = true, -- Treading Lightly
    [431418] = true, -- Algari Mana Potion
    [460074] = true, -- Grotesque Vial
    [431914] = true, -- Potion of Unwavering Focus
    [431422] = true, -- Slumbering Soul Serum
    [431941] = true, -- Potion of the Reborn Cheetah
    [431432] = true, -- Draught of Shocking Revelations
    [431925] = true, -- Frontline Potion
    [453040] = true, -- Potion Bomb of Speed
    [453162] = true, -- Potion Bomb of Recovery
    [453205] = true, -- Potion Bomb of Power

    -- 10.0.0 - Dragonflight
    [370607] = true,
    [371028] = true,
    [371024] = true,
    [371033] = true,
    [371134] = true,
    [371152] = true,
    [371039] = true,
    [371167] = true,

    -- 9.0.1 - Shadowlands
    [307159] = true, -- Agility
    [307162] = true, -- Intellect
    [307163] = true, -- Stamina
    [307164] = true, -- Strength
    [307160] = true, -- Armor
    [307161] = true, -- Mana sleep
    [307194] = true, -- Mana+hp
    [307193] = true, -- Mana
    [307497] = true, -- Potion of Deathly Fixation
    [307494] = true, -- Potion of Empowered Exorcisms
    [307496] = true, -- Potion of Divine Awakening
    [307495] = true, -- Potion of Phantom Fire
    [322302] = true, -- Potion of Sacrificial Anima
    [344314] = true, -- Run
    [307199] = true, -- Potion of Soul Purity
    [342890] = true, -- Potion of Unhindered Passing
    [307196] = true, -- Potion of Shadow Sight
    [307195] = true, -- Invisibility

    -- 8.2.0 - Battle for Azeroth
    [298152] = true, -- Intellect
    [298146] = true, -- Agility
    [298153] = true, -- Stamina
    [298154] = true, -- Strength
    [298155] = true, -- Armor
    [298225] = true, -- Potion of Empowered Proximity
    [298317] = true, -- Potion of Focused Resolve
    [300714] = true, -- Potion of Unbridled Fury
    [300741] = true, -- Potion of Wild Mending
    [251316] = true, -- Potion of Bursting Blood
    [269853] = true, -- Potion of Rising Death
    [250873] = true, -- Invisibility
    [250878] = true, -- Run haste
    [251143] = true, -- Fall

    -- 8.0.1 - Battle for Azeroth
    [279152] = true, -- Agility
    [279151] = true, -- Intellect
    [279154] = true, -- Stamina
    [279153] = true, -- Strength
    [251231] = true, -- Armor

    -- Legacy
    [188024] = true, -- Run haste
    [250871] = true, -- Mana
    [252753] = true, -- Mana channel
    [250872] = true, -- Mana+hp
}

-------------------------------------------------------------------------------
--- Damage Potion Item IDs
--- Used to check player inventory for combat potions. Order matters:
--- first match wins for icon display, all are summed for count.
-------------------------------------------------------------------------------

RCC.db.potionItemIDs = {
    -- 12.0.0 - Fleeting
    245897, 245898, -- Fleeting Light's Potential
    245910, 245911, -- Fleeting Draught of Rampant Abandon
    245902, 245903, -- Fleeting Potion of Recklessness
    245900, 245901, -- Fleeting Potion of Zealotry
    245916, 245917, -- Fleeting Lightfused Mana Potion
    245904, 245905, -- Fleeting Potion of Devoured Dreams

    -- 12.0.0 - Full duration
    241308, 241309, -- Light's Potential
    241292, 241293, -- Draught of Rampant Abandon
    241288, 241289, -- Potion of Recklessness
    241296, 241297, -- Potion of Zealotry
    241286, 241287, -- Light's Preservation
    241300, 241301, -- Lightfused Mana Potion
    241294, 241295, -- Potion of Devoured Dreams

    -- 11.0.0 - Fleeting
    212969, 212970, 212971, -- Fleeting Tempered Potion
    212963, 212964, 212965, -- Fleeting Potion of Unwavering Focus
    212966, 212967, 212968, -- Fleeting Frontline Potion

    -- 11.0.0 - Full duration
    212263, 212264, 212265, -- Tempered Potion
    212257, 212258, 212259, -- Potion of Unwavering Focus
    212260, 212261, 212262, -- Frontline Potion
}

-------------------------------------------------------------------------------
--- Utility Potions (12.0.0 - Midnight)
--- Stored for future use. Not currently tracked by the addon.
-------------------------------------------------------------------------------

RCC.db.utilityPotionItemIDs = {
    241302, 241303, -- Void-Shrouded Tincture (invisibility)
    241338, 241339, -- Enlightenment Tonic (slow fall)
}
