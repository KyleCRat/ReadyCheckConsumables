local _, RCC = ...

-- Stable tie-break order within automatic selection. Toys are collected in the
-- Toy Box, not counted in bags. Keep both kinds here so additions feed every
-- ownership, cooldown, preference, and flyout list from one registration.
RCC.db.glideItems = {
    { itemID = 212524, isToy = true }, -- Delicate Crimson Parasol
    { itemID = 212525, isToy = true }, -- Delicate Ebony Parasol
    { itemID = 212500, isToy = true }, -- Delicate Silk Parasol
    { itemID = 212523, isToy = true }, -- Delicate Jade Parasol
    { itemID = 182694, isToy = true }, -- Stylish Black Parasol
    { itemID = 182696, isToy = true }, -- The Countess's Parasol
    { itemID = 182695, isToy = true }, -- Weathered Purple Parasol
    { itemID = 109076 }, -- Goblin Glider Kit
}

RCC.db.glideItemIDs = {}
RCC.db.glideToyItemIDs = {}
RCC.db.glideCooldownItemIDs = {}
RCC.db.glideDefaultItemID = 109076

for _, item in ipairs(RCC.db.glideItems) do
    local ids = item.isToy and RCC.db.glideToyItemIDs or RCC.db.glideItemIDs

    ids[#ids + 1] = item.itemID
    RCC.db.glideCooldownItemIDs[#RCC.db.glideCooldownItemIDs + 1] = item.itemID
end
