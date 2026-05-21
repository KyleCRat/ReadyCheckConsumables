local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Augment Rune Spell IDs
--- Maps spell ID -> data for detecting augment rune auras.
--- Higher xpac = more current expansion.
--------------------------------------------------------------------------------

RCC.db.augmentXpacNames = {
    [7]  = "Legion",
    [8]  = "BfA",
    [9]  = "SL",
    [10] = "DF",
    [11] = "TWW",
    [12] = "MN",
}

RCC.db.augmentBuffIDs = {
    -- Midnight
    [1264426] = { xpac = 12, unlimited = false }, -- 12.0.0: Void-Touched Augment Rune

    -- The War Within
    [1242347] = { xpac = 11, unlimited = false }, -- 11.2.0: Soulgorged Augmentation
    [1234969] = { xpac = 11, unlimited = true  }, -- 11.2.0: Ethereal Augmentation
    [453250]  = { xpac = 11, unlimited = false }, -- 11.0.0: Crystallization

    -- Dragonflight
    [393438]  = { xpac = 10, unlimited = false }, -- 10.0.0: Draconic Augmentation

    -- Shadowlands
    [367405]  = { xpac = 9,  unlimited = false }, -- 9.2.0:  Eternal Augmentation
    [347901]  = { xpac = 9,  unlimited = false }, -- 9.0.2:  Veiled Augmentation

    -- Battle for Azeroth
    [317065]  = { xpac = 8,  unlimited = false }, -- 8.3.0:  Battle-Scarred Augmentation
    [270058]  = { xpac = 8,  unlimited = false }, -- 8.1.0:  Battle-Scarred Augmentation

    -- Legion
    [224001]  = { xpac = 7,  unlimited = false }, -- 7.0.3:  Defiled Augmentation
}

local maxXpac = 0

for _, data in pairs(RCC.db.augmentBuffIDs) do
    local xpac = data.xpac

    if xpac > maxXpac then
        maxXpac = xpac
    end
end

RCC.db.currentAugmentXpac = maxXpac

--------------------------------------------------------------------------------
--- Augment Rune Item IDs
--- Maps item ID -> { xpac, priority, unlimited } for bag scanning.
--- Higher xpac wins. Within same xpac, higher priority wins.
--- Unlimited runes are not consumed on use.
--------------------------------------------------------------------------------

RCC.db.augmentItemIDs = {
    -- Midnight
    [259085] = { xpac = 12, priority = 1, unlimited = false }, -- 12.0.0: Void-Touched Augment Rune

    -- The War Within
    [243191] = { xpac = 11, priority = 2, unlimited = true  }, -- 11.2.0: Ethereal Augment Rune
    [246492] = { xpac = 11, priority = 1, unlimited = false }, -- 11.2.0: Soulgorged Augment Rune
    [224572] = { xpac = 11, priority = 0, unlimited = false }, -- 11.0.0: Crystallized Augment Rune

    -- Dragonflight
    [211495] = { xpac = 10, priority = 1, unlimited = true  }, -- 10.2.0: Dreambound Augment Rune
    [201325] = { xpac = 10, priority = 0, unlimited = false }, -- 10.0.0: Draconic Augment Rune

    -- Shadowlands
    [190384] = { xpac = 9, priority = 1, unlimited = false }, --  9.2.0: Eternal Augment Rune
    [181468] = { xpac = 9, priority = 0, unlimited = false }, --  9.0.1: Veiled Augment Rune

    -- Battle for Azeroth
    [174906] = { xpac = 8, priority = 1, unlimited = false }, --  8.3.0: Lightning-Forged Augment Rune
    [160053] = { xpac = 8, priority = 0, unlimited = false }, --  8.0.1: Battle-Scarred Augment Rune

    -- Legion
    [153023] = { xpac = 7, priority = 1, unlimited = false }, --  7.3.0: Lightforged Augment Rune
    [140587] = { xpac = 7, priority = 0, unlimited = false }, --  7.0.3: Defiled Augment Rune

    -- Warlords of Draenor
    [128482] = { xpac = 6, priority = 1, unlimited = false }, --  6.2.0: Empowered Augment Rune
    [128475] = { xpac = 6, priority = 1, unlimited = false }, --  6.2.0: Empowered Augment Rune
    [118630] = { xpac = 6, priority = 0, unlimited = false }, --  6.0.1: Hyper Augment Rune
    [118631] = { xpac = 6, priority = 0, unlimited = false }, --  6.0.1: Stout Augment Rune
    [118632] = { xpac = 6, priority = 0, unlimited = false }, --  6.0.1: Focus Augment Rune
}
