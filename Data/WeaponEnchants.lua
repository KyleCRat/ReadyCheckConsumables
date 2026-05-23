local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Weapon Enchant / Oil Lookup
--- Maps enchant ID -> { item, spellID, [icon], [q], [xpac] }.
--- Used by the consumable frame to detect and display weapon buffs.
--- Detected via GetWeaponEnchantInfo(); only weapon-slot enchants belong here.
--- Spell-based weapon enchants stay in this root file. Item-based weapon
--- enchants are appended by expansion files.
--------------------------------------------------------------------------------

local MAIN_HAND_INVENTORY_SLOT = 16
local OFF_HAND_INVENTORY_SLOT = 17

RCC.db.weaponEnchants = {}
RCC.db.weaponEnchantItemIDs = {}

RCC.Data = RCC.Data or {}

local function addWeaponEnchant(enchantID, enchantData)
    RCC.db.weaponEnchants[enchantID] = enchantData

    if enchantData.item then
        RCC.db.weaponEnchantItemIDs[enchantData.item] = enchantData
    end
end

function RCC.Data.AddWeaponEnchants(enchantIDs)
    if not enchantIDs then return end

    for enchantID, enchantData in pairs(enchantIDs) do
        addWeaponEnchant(enchantID, enchantData)
    end
end

RCC.Data.AddWeaponEnchants({
    ----------------------------------------------------------------------------
    --- Shaman Enchants (spellID = spell-based, not item-based)
    ---
    [5401] = { -- Windfury Weapon
        spellID = 33757,
        spellSlots = {
            [MAIN_HAND_INVENTORY_SLOT] = { priority = 1 },
        },
    },
    [5400] = { -- Flametongue Weapon
        spellID = 318038,
        spellSlots = {
            [MAIN_HAND_INVENTORY_SLOT] = {
                priority = 3,
                blockedByKnownEnchants = { 5401 },
            },
            [OFF_HAND_INVENTORY_SLOT] = {
                priority = 1,
                requiresKnownEnchants = { 5401 },
            },
        },
    },
    [6498] = { -- Earthliving Weapon
        spellID = 382021,
        spellSlots = {
            [MAIN_HAND_INVENTORY_SLOT] = { priority = 2 },
        },
    },

    ----------------------------------------------------------------------------
    --- Paladin Lightsmith Enchants (spellID = spell-based, not item-based)
    ---
    [7143] = { -- Rite of Sanctification
        spellID = 433568,
        spellSlots = {
            [MAIN_HAND_INVENTORY_SLOT] = { priority = 1 },
        },
    },
    [7144] = { -- Rite of Adjuration
        spellID = 433583,
        spellSlots = {
            [MAIN_HAND_INVENTORY_SLOT] = { priority = 1 },
        },
    },
})
