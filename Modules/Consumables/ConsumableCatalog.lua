local _, RCC = ...

RCC.ConsumableCatalog = RCC.ConsumableCatalog or {}

local Catalog = RCC.ConsumableCatalog
local Reason = RCC.DisplayReason
local Surface = RCC.DisplaySurface.CONSUMABLE_FRAME
local Visibility = RCC.ContextualVisibility

local MAIN_HAND_INVENTORY_SLOT = INVSLOT_MAINHAND
local OFF_HAND_INVENTORY_SLOT = INVSLOT_OFFHAND
local SINGLE_CAPACITY = { 1 }

local OPEN_EVENTS = {
    {
        reason = Reason.READY_CHECK,
        label = "Ready Check",
        matrixLabel = "Ready\nCheck",
        tooltip = "Show %s when a ready check opens the frame.",
    },
    {
        reason = Reason.INSTANCE_ENTRY,
        label = "Instance Entry",
        matrixLabel = "Instance\nEntry",
        tooltip = "Show %s when entering an enabled instance type.",
    },
    {
        reason = Reason.CAULDRON_PICKUP,
        label = "Cauldron Pickup",
        matrixLabel = "Cauldron\nPickup",
        tooltip = "Show %s after collecting a consumable from a cauldron.",
    },
    {
        reason = Reason.BREAK_TIMER,
        label = "Break Timer",
        matrixLabel = "Break\nTimer",
        tooltip = "Show %s when BigWigs or DBM starts a break timer.",
    },
}

function Catalog.GetFrameOpenEvents()
    return OPEN_EVENTS
end

function Catalog.GetFrameEventEnabled(definition, reason)
    return RCC.GetContextualVisibility(
        Surface,
        definition.key,
        reason,
        Visibility.GetReasonDefault(definition, reason)
    )
end

-- The four event choices are the only per-button enablement settings for the
-- temporary frame. Turning all of them off also excludes manual openings.
function Catalog.IsFrameCategoryEnabled(definition)
    for _, event in ipairs(OPEN_EVENTS) do
        if Catalog.GetFrameEventEnabled(definition, event.reason) then
            return true
        end
    end

    return false
end

local STANDARD_VISIBILITY = {
    IsEnabled = Catalog.IsFrameCategoryEnabled,
    reasons = {
        [Reason.READY_CHECK] = true,
        [Reason.INSTANCE_ENTRY] = true,
        [Reason.CAULDRON_PICKUP] = true,
        [Reason.BREAK_TIMER] = true,
        [Reason.MANUAL_OPEN] = true,
    },
}

local STASIS_VISIBILITY = {
    IsEnabled = Catalog.IsFrameCategoryEnabled,
    reasons = {
        [Reason.BREAK_TIMER] = true,
    },
}

local OPTIONAL_VISIBILITY = {
    IsEnabled = Catalog.IsFrameCategoryEnabled,
    reasons = {
        [Reason.MANUAL_OPEN] = true,
    },
}

-- This array is the canonical button order for both personal consumable
-- surfaces. Definitions describe identity and product policy; widgets and
-- coordinates belong to the individual surfaces. Logic and presenter modules
-- load before this catalog so definitions hold references to those tables.
local DEFINITIONS = {
    {
        key = "food",
        logic = RCC.Consumables.Food,
        presenter = RCC.ConsumablePresenters.Food,
        label = "Food",
        defaultIcon = RCC.db.foodIconID,
        temporaryClickable = true,
        tooltipAction = "eat",
        hasCooldown = true,
    },
    {
        key = "flask",
        logic = RCC.Consumables.Flask,
        presenter = RCC.ConsumablePresenters.Flask,
        label = "Flask",
        defaultIcon = RCC.db.flaskIconID,
        temporaryClickable = true,
        tooltipAction = "use",
    },
    {
        key = "consumableStasis",
        logic = RCC.Consumables.ConsumableStasis,
        presenter = RCC.ConsumablePresenters.ConsumableStasis,
        label = "Consumable Stasis",
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
        logic = RCC.Consumables.WeaponEnchant,
        presenter = RCC.ConsumablePresenters.WeaponEnchant,
        label = "Main-hand Enchant",
        weaponSlot = MAIN_HAND_INVENTORY_SLOT,
        defaultIcon = RCC.db.weaponEnchantIconID,
        temporaryClickable = true,
        tooltipAction = "apply to main hand",
    },
    {
        key = "offHandTempWeaponEnchant",
        logic = RCC.Consumables.WeaponEnchant,
        presenter = RCC.ConsumablePresenters.WeaponEnchant,
        label = "Off-hand Enchant",
        weaponSlot = OFF_HAND_INVENTORY_SLOT,
        defaultIcon = RCC.db.weaponEnchantIconID,
        temporaryClickable = true,
        tooltipAction = "apply to off hand",
        hiddenByDefault = true,
        actionBarHideWhenInapplicable = true,
    },
    {
        key = "lethalPoison",
        logic = RCC.Consumables.RoguePoison,
        presenter = RCC.ConsumablePresenters.RoguePoison,
        classToken = "ROGUE",
        poisonType = "lethal",
        supportedCapacities = { 1, 2 },
        label = "Lethal Poison",
        defaultIcon = RCC.db.roguePoisonFallbackIcons.lethal,
        temporaryClickable = true,
        tooltipAction = "apply",
        actionBarHideWhenInapplicable = true,
        settingsTooltip = "Rogues only: apply a lethal poison or hover to choose another known poison",
    },
    {
        key = "nonLethalPoison",
        logic = RCC.Consumables.RoguePoison,
        presenter = RCC.ConsumablePresenters.RoguePoison,
        classToken = "ROGUE",
        poisonType = "nonLethal",
        supportedCapacities = { 1, 2 },
        label = "Non-lethal Poison",
        defaultIcon = RCC.db.roguePoisonFallbackIcons.nonLethal,
        temporaryClickable = true,
        tooltipAction = "apply",
        actionBarHideWhenInapplicable = true,
        settingsTooltip = "Rogues only: apply a non-lethal poison or hover to choose another known poison",
    },
    {
        key = "augment",
        logic = RCC.Consumables.Augment,
        presenter = RCC.ConsumablePresenters.Augment,
        label = "Augment Rune",
        defaultIcon = RCC.db.augmentIconID,
        temporaryClickable = true,
        tooltipAction = "use",
        hasCooldown = true,
    },
    {
        key = "raidBuff",
        logic = RCC.Consumables.RaidBuff,
        presenter = RCC.ConsumablePresenters.RaidBuff,
        label = "Raid Buff",
        defaultIcon = RCC.db.raidBuffIconID,
        temporaryClickable = true,
        tooltipAction = "cast",
        actionBarHideWhenInapplicable = true,
    },
    {
        key = "hs",
        logic = RCC.Consumables.Healthstone,
        presenter = RCC.ConsumablePresenters.Healthstone,
        label = "Healthstone",
        defaultIcon = RCC.db.healthstoneIconID,
        temporaryClickable = false,
        tooltipAction = "use",
    },
    {
        key = "combatpot",
        logic = RCC.Consumables.CombatPotion,
        presenter = RCC.ConsumablePresenters.CombatPotion,
        label = "Combat Potion",
        defaultIcon = RCC.db.combatPotionIconID,
        temporaryClickable = true,
        tooltipAction = "use",
        hasCooldown = true,
    },
    {
        key = "healpot",
        logic = RCC.Consumables.HealingPotion,
        presenter = RCC.ConsumablePresenters.HealingPotion,
        label = "Healing Potion",
        defaultIcon = RCC.db.healingPotionIconID,
        temporaryClickable = true,
        tooltipAction = "use",
        hasCooldown = true,
    },
    {
        key = "invisibilityPotion",
        logic = RCC.Consumables.InvisibilityPotion,
        presenter = RCC.ConsumablePresenters.InvisibilityPotion,
        label = "Invisibility Potion",
        visibility = OPTIONAL_VISIBILITY,
        defaultIcon = RCC.db.invisibilityPotionIcon,
        temporaryClickable = true,
        tooltipAction = "use",
        hasCooldown = true,
        settingsTooltip = "Use an invisibility potion or choose a preferred one from the flyout",
    },
    {
        key = "glide",
        logic = RCC.Consumables.Glide,
        presenter = RCC.ConsumablePresenters.Glide,
        label = "Glide",
        visibility = OPTIONAL_VISIBILITY,
        defaultIcon = RCC.db.glideIcon,
        temporaryClickable = true,
        tooltipAction = "use",
        hasCooldown = true,
        settingsTooltip = "Use a glider kit or collected parasol toy, with a preferred choice from the flyout",
    },
    {
        key = "recuperate",
        logic = RCC.Consumables.Recuperate,
        presenter = RCC.ConsumablePresenters.Recuperate,
        label = "Recuperate",
        visibility = OPTIONAL_VISIBILITY,
        defaultIcon = RCC.db.recuperateIconID,
        temporaryClickable = true,
        tooltipAction = "cast",
    },
    {
        key = "inkyBlackPotion",
        logic = RCC.Consumables.InkyBlackPotion,
        presenter = RCC.ConsumablePresenters.InkyBlackPotion,
        label = "Inky Black Potion",
        visibility = OPTIONAL_VISIBILITY,
        defaultIcon = RCC.db.inkyBlackPotionIconID,
        temporaryClickable = true,
        tooltipAction = "use",
    },
    {
        key = "repair",
        logic = RCC.Consumables.Repair,
        presenter = RCC.ConsumablePresenters.Repair,
        label = "Repair",
        visibility = OPTIONAL_VISIBILITY,
        defaultIcon = RCC.db.repairIconID,
        temporaryClickable = true,
        tooltipAction = "use",
        hasCooldown = true,
        settingsTooltip = "Prefer a ready reusable repair device, then "
            .. "fall back to a ready consumable repair item.",
    },
    {
        key = "vantus",
        logic = RCC.Consumables.Vantus,
        presenter = RCC.ConsumablePresenters.Vantus,
        label = "Vantus Rune",
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
    definition.supportedCapacities = definition.supportedCapacities
        or SINGLE_CAPACITY
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

-- Definitions declare the allowed counts; the logic chooses the current one
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
