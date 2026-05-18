local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Expansion Constants
--------------------------------------------------------------------------------

local SHADOWLANDS    = 9
local DRAGONFLIGHT   = 10
local THE_WAR_WITHIN = 11
local MIDNIGHT       = 12

--------------------------------------------------------------------------------
--- Per-Expansion Settings
--- Default icon overrides per expansion. Item selection lives in the
--- data-specific lookup tables. The resolution loop below iterates
--- oldest-to-newest so the most recent expansion wins.
--------------------------------------------------------------------------------

RCC.settings = {
    [SHADOWLANDS] = {
        augment       = { iconID = 134078 },
        armorKit      = { itemID = 3528447 },
    },
    [DRAGONFLIGHT] = {},
    [THE_WAR_WITHIN] = {
        augment       = { iconID = 4549102 },
        flask         = { iconID = 3566840 },
        vantusRune    = { iconID = 4638737 },
    },
    [MIDNIGHT] = {
        augment       = { iconID = 4549099 },
        flask         = { iconID = 7548902 },
        vantusRune    = { iconID = 5976918 },
        potion        = { iconID = 7548911 },
        healingPotion = { iconID = 7548909 },
        weaponEnchant = { iconID = 7548985 },
    },
}

-- Sorted expansion IDs for deterministic oldest-to-newest iteration.
local orderedXpacIDs = {}
for xpacID in pairs(RCC.settings) do
    orderedXpacIDs[#orderedXpacIDs + 1] = xpacID
end
table.sort(orderedXpacIDs)

--------------------------------------------------------------------------------
--- Resolve icon and item IDs from settings
--- Loops oldest -> newest so the latest expansion overrides earlier ones.
--------------------------------------------------------------------------------

-- Defaults
RCC.db.weaponEnchantIconID  = 463543
RCC.db.foodIconID           = 136000
RCC.db.flaskIconID          = 3528447
RCC.db.armorKitIconID       = 3566840
RCC.db.healthstoneItemID    = 5512
RCC.db.healthstoneIconID    = 538745
RCC.db.potionIconID         = 650640   -- trade_alchemy_potiona4
RCC.db.healingPotionIconID  = 5931169  -- inv_flask_red
RCC.db.vantusIconID         = 4638737  -- inv_10_inscription_glyphs_color5

local iconKeys = {
    { setting = "augment",       dbKey = "augmentIconID" },
    { setting = "food",          dbKey = "foodIconID" },
    { setting = "flask",         dbKey = "flaskIconID" },
    { setting = "potion",        dbKey = "potionIconID" },
    { setting = "healingPotion", dbKey = "healingPotionIconID" },
    { setting = "weaponEnchant", dbKey = "weaponEnchantIconID" },
    { setting = "armorKit",      dbKey = "armorKitIconID" },
    { setting = "healthstone",   dbKey = "healthstoneIconID" },
    { setting = "vantusRune",    dbKey = "vantusIconID" },
}

for _, xpacID in ipairs(orderedXpacIDs) do
    local xpac = RCC.settings[xpacID]

    if xpac then
        for _, key in ipairs(iconKeys) do
            local entry = xpac[key.setting]

            if entry and entry.iconID then
                RCC.db[key.dbKey] = entry.iconID
            end
        end
    end
end
