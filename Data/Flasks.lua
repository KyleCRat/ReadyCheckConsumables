local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Flask Buff Spell IDs
--- Maps spell ID -> true for detecting flask auras on players.
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
--- Flask Item IDs
--- `flaskItems` is the editable source of truth for flask families. Family
--- order controls fallback order; item order inside a family controls priority.
--- When a preferred flask is selected, fleeting items from that family are used
--- before the preferred item, then other qualities from the same family. If
--- none are available, selection falls back to the next family in this table.
--------------------------------------------------------------------------------

RCC.FlaskVariant = RCC.FlaskVariant or {
    FLEETING = "fleeting",
}

local FLEETING = RCC.FlaskVariant.FLEETING

RCC.db.flaskItems = {
    {
        -- Flask of Thalassian Resistance
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245927, variant = FLEETING, q = 2 },
            { itemID = 245926, variant = FLEETING, q = 1 },
            { itemID = 241320, q = 2 },
            { itemID = 241321, q = 1 },
        },
    },
    {
        -- Flask of the Magisters
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245932, variant = FLEETING, q = 2 },
            { itemID = 245933, variant = FLEETING, q = 1 },
            { itemID = 241322, q = 2 },
            { itemID = 241323, q = 1 },
        },
    },
    {
        -- Flask of the Blood Knights
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245930, variant = FLEETING, q = 2 },
            { itemID = 245931, variant = FLEETING, q = 1 },
            { itemID = 241324, q = 2 },
            { itemID = 241325, q = 1 },
        },
    },
    {
        -- Flask of the Shattered Sun
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245928, variant = FLEETING, q = 2 },
            { itemID = 245929, variant = FLEETING, q = 1 },
            { itemID = 241326, q = 2 },
            { itemID = 241327, q = 1 },
        },
    },
    {
        -- Flask of Alchemical Chaos
        xpac = RCC.THE_WAR_WITHIN,
        items = {
            { itemID = 212741, variant = FLEETING, q = 3 },
            { itemID = 212740, variant = FLEETING, q = 2 },
            { itemID = 212739, variant = FLEETING, q = 1 },
            { itemID = 212283, q = 3 },
            { itemID = 212282, q = 2 },
            { itemID = 212281, q = 1 },
        },
    },
    {
        -- Flask of Saving Graces
        xpac = RCC.THE_WAR_WITHIN,
        items = {
            { itemID = 212747, variant = FLEETING, q = 3 },
            { itemID = 212746, variant = FLEETING, q = 2 },
            { itemID = 212745, variant = FLEETING, q = 1 },
            { itemID = 212301, q = 3 },
            { itemID = 212300, q = 2 },
            { itemID = 212299, q = 1 },
        },
    },
    {
        -- Flask of Tempered Aggression
        xpac = RCC.THE_WAR_WITHIN,
        items = {
            { itemID = 212728, variant = FLEETING, q = 3 },
            { itemID = 212727, variant = FLEETING, q = 2 },
            { itemID = 212725, variant = FLEETING, q = 1 },
            { itemID = 212271, q = 3 },
            { itemID = 212270, q = 2 },
            { itemID = 212269, q = 1 },
        },
    },
    {
        -- Flask of Tempered Swiftness
        xpac = RCC.THE_WAR_WITHIN,
        items = {
            { itemID = 212731, variant = FLEETING, q = 3 },
            { itemID = 212730, variant = FLEETING, q = 2 },
            { itemID = 212729, variant = FLEETING, q = 1 },
            { itemID = 212274, q = 3 },
            { itemID = 212273, q = 2 },
            { itemID = 212272, q = 1 },
        },
    },
    {
        -- Flask of Tempered Mastery
        xpac = RCC.THE_WAR_WITHIN,
        items = {
            { itemID = 212738, variant = FLEETING, q = 3 },
            { itemID = 212736, variant = FLEETING, q = 2 },
            { itemID = 212735, variant = FLEETING, q = 1 },
            { itemID = 212280, q = 3 },
            { itemID = 212279, q = 2 },
            { itemID = 212278, q = 1 },
        },
    },
    {
        -- Flask of Tempered Versatility
        xpac = RCC.THE_WAR_WITHIN,
        items = {
            { itemID = 212734, variant = FLEETING, q = 3 },
            { itemID = 212733, variant = FLEETING, q = 2 },
            { itemID = 212732, variant = FLEETING, q = 1 },
            { itemID = 212277, q = 3 },
            { itemID = 212276, q = 2 },
            { itemID = 212275, q = 1 },
        },
    },
}

-- Derived lookup tables. Keep edits in `flaskItems` above; these are built
-- once at load time so bag scans can still use a flat item ID list while
-- selection code can quickly resolve an item ID back to its family data.
RCC.db.flaskItemIDs = {}
RCC.db.flaskItemData = {}

for familyIndex = 1, #RCC.db.flaskItems do
    local family = RCC.db.flaskItems[familyIndex]
    local items = family.items or {}

    family.index = familyIndex

    for itemIndex = 1, #items do
        local item = items[itemIndex]
        local itemID = item.itemID

        item.familyIndex = familyIndex
        item.itemIndex = itemIndex
        item.xpac = item.xpac or family.xpac

        RCC.db.flaskItemIDs[#RCC.db.flaskItemIDs + 1] = itemID
        RCC.db.flaskItemData[itemID] = item
    end
end

--------------------------------------------------------------------------------
--- Cauldron Item IDs (12.0.0 - Midnight)
--- Stored for future use. Not currently tracked by the addon.
--------------------------------------------------------------------------------

RCC.db.cauldronItemIDs = {
    241284, 241285, -- Voidlight Potion Cauldron
    241318, 241319, -- Cauldron of Sin'dorei Flasks
}
