local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Permanent Enchantments
--- Stored for future use. Not currently used by the addon.
--- Permanent enchant rows currently use item IDs only; enchant IDs not yet
--- collected.
--- Expansion files append their rows so the rest of the addon can keep reading
--- one combined enchant table.
--------------------------------------------------------------------------------

RCC.db.enchantIDs = {}

RCC.Data = RCC.Data or {}

function RCC.Data.AddEnchantItems(enchantItems)
    if not enchantItems then return end

    for slot, itemIDs in pairs(enchantItems) do
        RCC.db.enchantIDs[slot] = itemIDs
    end
end

--------------------------------------------------------------------------------
--- Non-Weapon Enchants
--- These use the enchant system but are applied to non-weapon slots.
--- Cannot be detected via GetWeaponEnchantInfo().
--- Stored for future use. Not currently used by the addon.
--------------------------------------------------------------------------------

RCC.db.spellthreadEnchantIDs = {
    -- 11.0.0 - The War Within
    [7537] = { item = 222890, icon = 4549251, q = 3 }, -- Weavercloth Spellthread
    [7536] = { item = 222889, icon = 4549251, q = 2 }, -- Weavercloth Spellthread
    [7535] = { item = 222888, icon = 4549251, q = 1 }, -- Weavercloth Spellthread
    [7534] = { item = 222893, icon = 4549251, q = 3 }, -- Sunset Spellthread
    [7533] = { item = 222892, icon = 4549251, q = 2 }, -- Sunset Spellthread
    [7532] = { item = 222891, icon = 4549251, q = 1 }, -- Sunset Spellthread
    [7531] = { item = 222896, icon = 4549251, q = 3 }, -- Daybreak Spellthread
    [7530] = { item = 222895, icon = 4549251, q = 2 }, -- Daybreak Spellthread
    [7529] = { item = 222894, icon = 4549251, q = 1 }, -- Daybreak Spellthread

    -- 10.0.0 - Dragonflight
    [6538] = { item = 194010, icon = 4549251, q = 3 }, -- Vibrant Spellthread
    [6537] = { item = 194009, icon = 4549251, q = 2 }, -- Vibrant Spellthread
    [6536] = { item = 194008, icon = 4549251, q = 1 }, -- Vibrant Spellthread
    [6541] = { item = 194013, icon = 4549250, q = 3 }, -- Frozen Spellthread
    [6540] = { item = 194012, icon = 4549250, q = 2 }, -- Frozen Spellthread
    [6539] = { item = 194011, icon = 4549250, q = 1 }, -- Frozen Spellthread
    [6544] = { item = 194016, icon = 4549249, q = 3 }, -- Temporal Spellthread
    [6543] = { item = 194015, icon = 4549249, q = 2 }, -- Temporal Spellthread
    [6542] = { item = 194014, icon = 4549249, q = 1 }, -- Temporal Spellthread
}

RCC.db.armorKitEnchantIDs = {
    -- 11.0.0 - The War Within
    [7601] = { item = 219911, icon = 5975854, q = 3 }, -- Stormbound Armor Kit
    [7600] = { item = 219910, icon = 5975854, q = 2 }, -- Stormbound Armor Kit
    [7599] = { item = 219909, icon = 5975854, q = 1 }, -- Stormbound Armor Kit
    [7598] = { item = 219914, icon = 5975933, q = 3 }, -- Dual Layered Armor Kit
    [7597] = { item = 219913, icon = 5975933, q = 2 }, -- Dual Layered Armor Kit
    [7596] = { item = 219912, icon = 5975933, q = 1 }, -- Dual Layered Armor Kit
    [7595] = { item = 219908, icon = 5975753, q = 3 }, -- Defender's Armor Kit
    [7594] = { item = 219907, icon = 5975753, q = 2 }, -- Defender's Armor Kit
    [7593] = { item = 219906, icon = 5975753, q = 1 }, -- Defender's Armor Kit
    [6830] = { item = 204702, icon = 5088845, q = 3 }, -- Lambent Armor Kit
    [6829] = { item = 204701, icon = 5088845, q = 2 }, -- Lambent Armor Kit
    [6828] = { item = 204700, icon = 5088845, q = 1 }, -- Lambent Armor Kit

    -- 10.0.0 - Dragonflight
    [6493] = { item = 193567, icon = 4559209, q = 3 }, -- Reinforced Armor Kit
    [6492] = { item = 193563, icon = 4559209, q = 2 }, -- Reinforced Armor Kit
    [6491] = { item = 193559, icon = 4559209, q = 1 }, -- Reinforced Armor Kit
    [6490] = { item = 193565, icon = 4559217, q = 3 }, -- Fierce Armor Kit
    [6489] = { item = 193561, icon = 4559217, q = 2 }, -- Fierce Armor Kit
    [6488] = { item = 193557, icon = 4559217, q = 1 }, -- Fierce Armor Kit
    [6496] = { item = 193564, icon = 4559216, q = 3 }, -- Frosted Armor Kit
    [6495] = { item = 193560, icon = 4559216, q = 2 }, -- Frosted Armor Kit
    [6494] = { item = 193556, icon = 4559216, q = 1 }, -- Frosted Armor Kit
}

RCC.db.beltClaspEnchantIDs = {
    -- 10.1.0 - Dragonflight
    [6904] = { item = 205039, icon = 4559225, q = 3 }, -- Shadowed Belt Clasp
    [6905] = { item = 205044, icon = 4559225, q = 2 }, -- Shadowed Belt Clasp
    [6906] = { item = 205043, icon = 4559225, q = 1 }, -- Shadowed Belt Clasp
}
