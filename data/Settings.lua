local _, RCC = ...
RCC.db = RCC.db or {}

-------------------------------------------------------------------------------
--- Expansion Constants
-------------------------------------------------------------------------------

local SHADOWLANDS    = 9
local DRAGONFLIGHT   = 10
local THE_WAR_WITHIN = 11
local MIDNIGHT       = 12

-------------------------------------------------------------------------------
--- Per-Expansion Settings
--- Icon and item overrides per expansion. The resolution loop below
--- iterates oldest-to-newest so the most recent expansion wins.
-------------------------------------------------------------------------------

RCC.settings = {
    [SHADOWLANDS] = {
        rune           = { item_id = 181468, icon_id = 134078 },
        unlimited_rune = { item_id = 190384, icon_id = 4224736 },
        armor_kit      = { item_id = 3528447 },
    },
    [DRAGONFLIGHT] = {},
    [THE_WAR_WITHIN] = {
        rune           = { item_id = 224572, icon_id = 4549102 },
        unlimited_rune = { item_id = 243191, icon_id = 3566863 },
        flask          = { icon_id = 3566840 },
    },
    [MIDNIGHT] = {
        flask = { icon_id = 7548902 },
    },
}

-- Sorted expansion IDs for deterministic oldest-to-newest iteration
RCC.ordered_xpac_ids = {}
for xpac_id in pairs(RCC.settings) do
    table.insert(RCC.ordered_xpac_ids, xpac_id)
end
table.sort(RCC.ordered_xpac_ids)

-------------------------------------------------------------------------------
--- Resolve icon and item IDs from settings
--- Loops oldest -> newest so the latest expansion overrides earlier ones.
-------------------------------------------------------------------------------

-- Defaults
RCC.db.weapon_enchant_icon_id  = 463543
RCC.db.food_icon_id            = 136000
RCC.db.flask_icon_id           = 3528447
RCC.db.armor_kit_icon_id       = 3566840
RCC.db.healthstone_item_id     = 5512
RCC.db.healthstone_icon_id     = 538745

for _, xpac_id in ipairs(RCC.ordered_xpac_ids) do
    local xpac = RCC.settings[xpac_id]
    if xpac then
        if xpac.rune then
            RCC.db.rune_item_id = xpac.rune.item_id
            RCC.db.rune_icon_id = xpac.rune.icon_id
        end

        if xpac.unlimited_rune then
            RCC.db.unlimited_rune_item_id = xpac.unlimited_rune.item_id
            RCC.db.unlimited_rune_icon_id = xpac.unlimited_rune.icon_id
        end

        if xpac.food and xpac.food.icon_id then
            RCC.db.food_icon_id = xpac.food.icon_id
        end

        if xpac.weapon_enchants and xpac.weapon_enchants.icon_id then
            RCC.db.weapon_enchant_icon_id = xpac.weapon_enchants.icon_id
        end

        if xpac.armor_kit and xpac.armor_kit.icon_id then
            RCC.db.armor_kit_icon_id = xpac.armor_kit.icon_id
        end

        if xpac.flask and xpac.flask.icon_id then
            RCC.db.flask_icon_id = xpac.flask.icon_id
        end
    end
end
