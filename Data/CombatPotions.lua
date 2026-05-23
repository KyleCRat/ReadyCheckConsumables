local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Potion Spell IDs
--- Maps spell ID -> true for detecting potion usage via aura scanning.
--- Stored for future use. Not currently used by the addon.
--------------------------------------------------------------------------------

RCC.db.potionBuffIDs = {
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

--------------------------------------------------------------------------------
--- Combat Potion Item IDs
--- `combatPotionItems` is the editable source of truth for combat potion
--- families. Family order controls fallback order; item order inside a family
--- controls priority when quality metadata is incomplete.
--------------------------------------------------------------------------------

RCC.CombatPotionType = RCC.CombatPotionType or {
    MANA    = "mana_potion",
    DAMAGE  = "damage_potion",
    UTILITY = "utility_potion",
}

RCC.CombatPotionVariant = RCC.CombatPotionVariant or {
    FLEETING = "fleeting",
}

local MANA     = RCC.CombatPotionType.MANA
local DAMAGE   = RCC.CombatPotionType.DAMAGE
local UTILITY  = RCC.CombatPotionType.UTILITY
local FLEETING = RCC.CombatPotionVariant.FLEETING

RCC.db.combatPotionItems = {
    {
        -- Lightfused Mana Potion
        type = MANA,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245917, variant = FLEETING, q = 2 }, -- Fleeting Lightfused Mana Potion
            { itemID = 245916, variant = FLEETING, q = 1 }, -- Fleeting Lightfused Mana Potion
            { itemID = 241300, q = 2 }, -- Lightfused Mana Potion
            { itemID = 241301, q = 1 }, -- Lightfused Mana Potion
        },
    },
    {
        -- Light's Potential
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245897, variant = FLEETING }, -- Fleeting Light's Potential
            { itemID = 245898, variant = FLEETING }, -- Fleeting Light's Potential
            { itemID = 241308 }, -- Light's Potential
            { itemID = 241309 }, -- Light's Potential
        },
    },
    {
        -- Draught of Rampant Abandon
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245910, variant = FLEETING }, -- Fleeting Draught of Rampant Abandon
            { itemID = 245911, variant = FLEETING }, -- Fleeting Draught of Rampant Abandon
            { itemID = 241292 }, -- Draught of Rampant Abandon
            { itemID = 241293 }, -- Draught of Rampant Abandon
        },
    },
    {
        -- Potion of Recklessness
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245902, variant = FLEETING }, -- Fleeting Potion of Recklessness
            { itemID = 245903, variant = FLEETING }, -- Fleeting Potion of Recklessness
            { itemID = 241288 }, -- Potion of Recklessness
            { itemID = 241289 }, -- Potion of Recklessness
        },
    },
    {
        -- Potion of Zealotry
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245900, variant = FLEETING }, -- Fleeting Potion of Zealotry
            { itemID = 245901, variant = FLEETING }, -- Fleeting Potion of Zealotry
            { itemID = 241296 }, -- Potion of Zealotry
            { itemID = 241297 }, -- Potion of Zealotry
        },
    },
    {
        -- Light's Preservation
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 241286 }, -- Light's Preservation
            { itemID = 241287 }, -- Light's Preservation
        },
    },
    {
        -- Potion of Devoured Dreams
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245904, variant = FLEETING }, -- Fleeting Potion of Devoured Dreams
            { itemID = 245905, variant = FLEETING }, -- Fleeting Potion of Devoured Dreams
            { itemID = 241294 }, -- Potion of Devoured Dreams
            { itemID = 241295 }, -- Potion of Devoured Dreams
        },
    },
    {
        -- Void-Shrouded Tincture (Invisibility)
        type = UTILITY,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 241302 }, -- Void-Shrouded Tincture
            { itemID = 241303 }, -- Void-Shrouded Tincture
        },
    },
    {
        -- Enlightenment Tonic (Slow Fall)
        type = UTILITY,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 241338 }, -- Enlightenment Tonic
            { itemID = 241339 }, -- Enlightenment Tonic
        },
    },
    {
        -- Tempered Potion
        type = DAMAGE,
        xpac = RCC.THE_WAR_WITHIN,
        items = {
            { itemID = 212969, variant = FLEETING }, -- Fleeting Tempered Potion
            { itemID = 212970, variant = FLEETING }, -- Fleeting Tempered Potion
            { itemID = 212971, variant = FLEETING }, -- Fleeting Tempered Potion
            { itemID = 212263 }, -- Tempered Potion
            { itemID = 212264 }, -- Tempered Potion
            { itemID = 212265 }, -- Tempered Potion
        },
    },
    {
        -- Potion of Unwavering Focus
        type = DAMAGE,
        xpac = RCC.THE_WAR_WITHIN,
        items = {
            { itemID = 212963, variant = FLEETING }, -- Fleeting Potion of Unwavering Focus
            { itemID = 212964, variant = FLEETING }, -- Fleeting Potion of Unwavering Focus
            { itemID = 212965, variant = FLEETING }, -- Fleeting Potion of Unwavering Focus
            { itemID = 212257 }, -- Potion of Unwavering Focus
            { itemID = 212258 }, -- Potion of Unwavering Focus
            { itemID = 212259 }, -- Potion of Unwavering Focus
        },
    },
    {
        -- Frontline Potion
        type = UTILITY,
        xpac = RCC.THE_WAR_WITHIN,
        items = {
            { itemID = 212966, variant = FLEETING }, -- Fleeting Frontline Potion
            { itemID = 212967, variant = FLEETING }, -- Fleeting Frontline Potion
            { itemID = 212968, variant = FLEETING }, -- Fleeting Frontline Potion
            { itemID = 212260 }, -- Frontline Potion
            { itemID = 212261 }, -- Frontline Potion
            { itemID = 212262 }, -- Frontline Potion
        },
    },
}

-- Derived lookup tables. Keep edits in `combatPotionItems` above; these are
-- built once at load time so existing bag scans can still use a flat item ID
-- list while selection code can quickly resolve an item ID back to its family
-- data.
RCC.db.combatPotionItemIDs = {}
RCC.db.combatPotionItemData = {}

for familyIndex = 1, #RCC.db.combatPotionItems do
    local family = RCC.db.combatPotionItems[familyIndex]
    local items = family.items or {}

    -- Store the ordered family position for fallback priority decisions.
    family.index = familyIndex

    for itemIndex = 1, #items do
        local item = items[itemIndex]
        local itemID = item.itemID

        -- Copy family-level metadata onto each item so candidate selection only
        -- needs the item ID after a bag scan.
        item.familyIndex = familyIndex
        item.itemIndex = itemIndex
        item.type = family.type
        item.xpac = item.xpac or family.xpac

        -- Preserve the old flat-list API and add a reverse itemID -> data map.
        RCC.db.combatPotionItemIDs[#RCC.db.combatPotionItemIDs + 1] = itemID
        RCC.db.combatPotionItemData[itemID] = item
    end
end
