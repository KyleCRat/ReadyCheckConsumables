local _, RCC = ...

RCC.ConsumableCatalog = RCC.ConsumableCatalog or {}

local Catalog = RCC.ConsumableCatalog
local Reason = RCC.DisplayReason

local MAIN_HAND_INVENTORY_SLOT = INVSLOT_MAINHAND
local OFF_HAND_INVENTORY_SLOT = INVSLOT_OFFHAND
local SINGLE_CAPACITY = { 1 }

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
        domain = "Food",
        label = "Food",
        settingKey = "icon_food",
        defaultIcon = RCC.db.foodIconID,
        temporaryClickable = true,
        tooltipAction = "eat",
        hasCooldown = true,
    },
    {
        key = "flask",
        domain = "Flask",
        label = "Flask",
        settingKey = "icon_flask",
        defaultIcon = RCC.db.flaskIconID,
        temporaryClickable = true,
        tooltipAction = "use",
    },
    {
        key = "consumableStasis",
        domain = "ConsumableStasis",
        label = "Consumable Stasis",
        settingKey = "icon_consumableStasis",
        defaultIcon = 134062,
        temporaryClickable = true,
        tooltipAction = "use",
        hasCooldown = true,
        hiddenByDefault = true,
        visibility = STASIS_VISIBILITY,
        settingsTooltip = "Consumable Stasis items pause the expiration of "
            .. "active consumable buffs during a break. Examples include "
            .. "Pausing Pylon and W-47CH D0G.",
    },
    {
        key = "mainHandTempWeaponEnchant",
        domain = "WeaponEnchant",
        label = "Main-hand Enchant",
        weaponSlot = MAIN_HAND_INVENTORY_SLOT,
        settingKey = "icon_mhTempWeaponEnchant",
        defaultIcon = RCC.db.weaponEnchantIconID,
        temporaryClickable = true,
        tooltipAction = "apply to main hand",
    },
    {
        key = "offHandTempWeaponEnchant",
        domain = "WeaponEnchant",
        label = "Off-hand Enchant",
        weaponSlot = OFF_HAND_INVENTORY_SLOT,
        settingKey = "icon_ohTempWeaponEnchant",
        defaultIcon = RCC.db.weaponEnchantIconID,
        temporaryClickable = true,
        tooltipAction = "apply to off hand",
        hiddenByDefault = true,
        actionBarHideWhenInapplicable = true,
    },
    {
        key = "lethalPoison",
        domain = "RoguePoison",
        classToken = "ROGUE",
        poisonType = "lethal",
        supportedCapacities = { 1, 2 },
        label = "Lethal Poison",
        settingKey = "icon_lethalPoison",
        defaultIcon = RCC.db.roguePoisonFallbackIconID,
        temporaryClickable = true,
        tooltipAction = "apply",
        actionBarHideWhenInapplicable = true,
        settingsTooltip = "Rogues only: apply a lethal poison or hover to choose another known poison",
    },
    {
        key = "nonLethalPoison",
        domain = "RoguePoison",
        classToken = "ROGUE",
        poisonType = "nonLethal",
        supportedCapacities = { 1, 2 },
        label = "Non-lethal Poison",
        settingKey = "icon_nonLethalPoison",
        defaultIcon = RCC.db.roguePoisonFallbackIconID,
        temporaryClickable = true,
        tooltipAction = "apply",
        actionBarHideWhenInapplicable = true,
        settingsTooltip = "Rogues only: apply a non-lethal poison or hover to choose another known poison",
    },
    {
        key = "augment",
        domain = "Augment",
        label = "Augment Rune",
        settingKey = "icon_augment",
        defaultIcon = RCC.db.augmentIconID,
        temporaryClickable = true,
        tooltipAction = "use",
        hasCooldown = true,
    },
    {
        key = "raidBuff",
        domain = "RaidBuff",
        label = "Raid Buff",
        settingKey = "icon_raidBuff",
        defaultIcon = RCC.db.raidBuffIconID,
        temporaryClickable = true,
        tooltipAction = "cast",
    },
    {
        key = "hs",
        domain = "Healthstone",
        label = "Healthstone",
        settingKey = "icon_healthstone",
        defaultIcon = RCC.db.healthstoneIconID,
        temporaryClickable = false,
        tooltipAction = "use",
    },
    {
        key = "combatpot",
        domain = "CombatPotion",
        label = "Combat Potion",
        settingKey = "icon_combatPotion",
        defaultIcon = RCC.db.combatPotionIconID,
        temporaryClickable = true,
        tooltipAction = "use",
        hasCooldown = true,
    },
    {
        key = "healpot",
        domain = "HealingPotion",
        label = "Healing Potion",
        settingKey = "icon_healPotion",
        defaultIcon = RCC.db.healingPotionIconID,
        temporaryClickable = true,
        tooltipAction = "use",
        hasCooldown = true,
    },
    {
        key = "recuperate",
        domain = "Recuperate",
        label = "Recuperate",
        settingKey = "icon_recuperate",
        defaultIcon = RCC.db.recuperateIconID,
        temporaryClickable = true,
        tooltipAction = "cast",
    },
    {
        key = "inkyBlackPotion",
        domain = "InkyBlackPotion",
        label = "Inky Black Potion",
        settingKey = "icon_inkyBlackPotion",
        defaultIcon = RCC.db.inkyBlackPotionIconID,
        temporaryClickable = true,
        tooltipAction = "use",
    },
    {
        key = "repair",
        domain = "Repair",
        label = "Repair",
        settingKey = "icon_repair",
        defaultIcon = RCC.db.repairIconID,
        temporaryClickable = true,
        tooltipAction = "use",
        hasCooldown = true,
        settingsTooltip = "Prefer a ready reusable repair device, then "
            .. "fall back to a ready consumable repair item.",
    },
    {
        key = "vantus",
        domain = "Vantus",
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
    definition.supportedCapacities = definition.supportedCapacities or SINGLE_CAPACITY
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

-- Definitions declare the allowed counts; the domain chooses the current one
-- from its inputs. Neither the renderer nor the saved preference branches
-- decide which count a category may select.
function Catalog.SupportsCapacity(definition, capacity)
    for _, supported in ipairs(definition.supportedCapacities) do
        if supported == capacity then return true end
    end

    return false
end

-- Class does not change during a session. Unlike equipment or learned spells,
-- a different class cannot become applicable later, so do not request its data.
function Catalog.IsAvailableToPlayer(definition)
    return not definition.classToken
        or definition.classToken == RCC.ConsumableInputs.ReadClassToken()
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
