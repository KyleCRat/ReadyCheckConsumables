local _, RCC = ...

RCC.ConsumableCatalog = RCC.ConsumableCatalog or {}

local Catalog = RCC.ConsumableCatalog
local Reason = RCC.DisplayReason

local MAIN_HAND_INVENTORY_SLOT = 16
local OFF_HAND_INVENTORY_SLOT = 17

local STANDARD_VISIBILITY = {
    reasons = {
        [Reason.READY_CHECK] = true,
        [Reason.INSTANCE_ENTRY] = true,
        [Reason.CAULDRON_PICKUP] = true,
        [Reason.BREAK_TIMER] = true,
        [Reason.MANUAL_OPEN] = true,
    },
}

local STASIS_VISIBILITY = {
    reasons = {
        [Reason.BREAK_TIMER] = true,
    },
}

-- This array is the canonical button order for both personal consumable
-- surfaces. Definitions describe identity and product policy; widgets and
-- coordinates belong to the individual surfaces.
local DEFINITIONS = {
    {
        key = "food",
        label = "Food",
        settingKey = "icon_food",
        defaultIcon = RCC.db.foodIconID,
        temporaryClickable = true,
        tooltipAction = "eat",
        hasCooldown = true,
    },
    {
        key = "flask",
        label = "Flask",
        settingKey = "icon_flask",
        defaultIcon = RCC.db.flaskIconID,
        temporaryClickable = true,
        tooltipAction = "use",
    },
    {
        key = "consumableStasis",
        label = "Consumable Stasis",
        settingKey = "icon_consumableStasis",
        defaultIcon = 134062,
        temporaryClickable = true,
        tooltipAction = "use",
        hiddenByDefault = true,
        visibility = STASIS_VISIBILITY,
        settingsTooltip = "Consumable Stasis items pause the expiration of "
            .. "active consumable buffs during a break. Examples include "
            .. "Pausing Pylon and W-47CH D0G.",
    },
    {
        key = "mainHandTempWeaponEnchant",
        label = "Main-hand Enchant",
        weaponSlot = MAIN_HAND_INVENTORY_SLOT,
        settingKey = "icon_mhTempWeaponEnchant",
        defaultIcon = RCC.db.weaponEnchantIconID,
        temporaryClickable = true,
        tooltipAction = "apply to main hand",
    },
    {
        key = "offHandTempWeaponEnchant",
        label = "Off-hand Enchant",
        weaponSlot = OFF_HAND_INVENTORY_SLOT,
        settingKey = "icon_ohTempWeaponEnchant",
        defaultIcon = RCC.db.weaponEnchantIconID,
        temporaryClickable = true,
        tooltipAction = "apply to off hand",
        hiddenByDefault = true,
    },
    {
        key = "augment",
        label = "Augment Rune",
        settingKey = "icon_augment",
        defaultIcon = RCC.db.augmentIconID,
        temporaryClickable = true,
        tooltipAction = "use",
    },
    {
        key = "raidBuff",
        label = "Raid Buff",
        settingKey = "icon_raidBuff",
        defaultIcon = RCC.db.raidBuffIconID,
        temporaryClickable = true,
        tooltipAction = "cast",
    },
    {
        key = "hs",
        label = "Healthstone",
        settingKey = "icon_healthstone",
        defaultIcon = RCC.db.healthstoneIconID,
        temporaryClickable = false,
        tooltipAction = "use",
    },
    {
        key = "combatpot",
        label = "Combat Potion",
        settingKey = "icon_combatPotion",
        defaultIcon = RCC.db.combatPotionIconID,
        temporaryClickable = true,
        tooltipAction = "use",
    },
    {
        key = "healpot",
        label = "Healing Potion",
        settingKey = "icon_healPotion",
        defaultIcon = RCC.db.healingPotionIconID,
        temporaryClickable = true,
        tooltipAction = "use",
    },
    {
        key = "recuperate",
        label = "Recuperate",
        settingKey = "icon_recuperate",
        defaultIcon = RCC.db.recuperateIconID,
        temporaryClickable = true,
        tooltipAction = "cast",
    },
    {
        key = "vantus",
        label = "Vantus Rune",
        settingKey = "icon_vantus",
        defaultIcon = RCC.db.vantusIconID,
        temporaryClickable = true,
        tooltipAction = "use",
        hiddenByDefault = true,
    },
}

local BY_KEY = {}

for i = 1, #DEFINITIONS do
    local definition = DEFINITIONS[i]

    definition.visibility = definition.visibility or STANDARD_VISIBILITY
    definition.actionBarSettingKey = "consumablesActionBar_icon_"
        .. definition.key
    BY_KEY[definition.key] = definition
end

function Catalog.GetDefinitions()
    return DEFINITIONS
end

function Catalog.GetDefinition(key)
    return BY_KEY[key]
end

function Catalog.GetCount()
    return #DEFINITIONS
end

function Catalog.GetTemporarySettingKeys()
    local keys = {}

    for i = 1, #DEFINITIONS do
        keys[i] = DEFINITIONS[i].settingKey
    end

    return keys
end

