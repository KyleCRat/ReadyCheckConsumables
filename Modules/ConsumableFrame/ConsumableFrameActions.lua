local _, RCC = ...

RCC.ConsumableFrameActions = RCC.ConsumableFrameActions or {}

local Actions = RCC.ConsumableFrameActions

-- Action descriptors are plain data returned by consumable modules. Missing or
-- malformed actions disable clickable overlays by default.
local ACTION_ITEM_MACRO = "itemMacro"
local ACTION_SPELL = "spell"
local ACTION_WEAPON_ENCHANT_ITEM = "weaponEnchantItem"

function Actions.CreateItemMacro(itemID, targetSlot)
    return {
        type = ACTION_ITEM_MACRO,
        itemID = itemID,
        targetSlot = targetSlot,
    }
end

function Actions.CreateSpell(spellName, available)
    return {
        type = ACTION_SPELL,
        spellName = spellName,
        available = available,
    }
end

function Actions.CreateWeaponEnchantItem(itemID, available)
    return {
        type = ACTION_WEAPON_ENCHANT_ITEM,
        itemID = itemID,
        available = available,
    }
end

local function enableClick(button)
    button.clickEnabled = true

    if not button.click or InCombatLockdown() then return end

    button.click:Show()
end

local function disableClick(button)
    button.clickEnabled = false

    if not button.click or InCombatLockdown() then return end

    button.click:Hide()
end

local function setClickAvailability(button, available)
    if available then
        enableClick(button)
    else
        disableClick(button)
    end
end

local function getItemUseMacro(itemID, targetSlot)
    if targetSlot then
        return format("/stopmacro [combat]\n/use item:%d\n/use %d",
                      itemID, targetSlot)
    end

    return format("/stopmacro [combat]\n/use item:%d", itemID)
end

local function disable(button)
    if not button or not button.click then return end

    disableClick(button)
end

local function setItemMacro(button, itemID, targetSlot)
    if not button or not button.click or InCombatLockdown() then return end

    button.click:SetAttribute("type", "macro")
    button.click:SetAttribute("macrotext1",
        getItemUseMacro(itemID, targetSlot))

    enableClick(button)
end

local function setSpell(button, spellName, available)
    if not button or not button.click or InCombatLockdown() then return end

    button.click:SetAttribute("spell", spellName)
    button.click:SetAttribute("type", "spell")

    setClickAvailability(button, available == true)
end

local function setWeaponEnchantItem(button, itemID, available)
    if not button or not button.click or InCombatLockdown() then return end

    button.click:SetAttribute("spell", nil)
    button.click:SetAttribute("item", "item:" .. itemID)
    button.click:SetAttribute("type", "item")

    setClickAvailability(button, available == true)
end

function Actions.Apply(button, action)
    if not button then return end

    if not action or not action.type then
        disable(button)

        return
    end

    if action.type == ACTION_ITEM_MACRO and action.itemID then
        setItemMacro(button, action.itemID, action.targetSlot)
    elseif action.type == ACTION_SPELL and action.spellName then
        setSpell(button, action.spellName, action.available)
    elseif action.type == ACTION_WEAPON_ENCHANT_ITEM and action.itemID then
        setWeaponEnchantItem(button, action.itemID, action.available)
    else
        disable(button)
    end
end
