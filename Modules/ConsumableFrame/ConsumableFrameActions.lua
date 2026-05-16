local _, RCC = ...

RCC.ConsumableFrameActions = RCC.ConsumableFrameActions or {}

local Actions = RCC.ConsumableFrameActions

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

function Actions.GetItemUseMacro(itemID, targetSlot)
    if targetSlot then
        return format("/stopmacro [combat]\n/use item:%d\n/use %d",
                      itemID, targetSlot)
    end

    return format("/stopmacro [combat]\n/use item:%d", itemID)
end

function Actions.Disable(button)
    if not button or not button.click then return end

    disableClick(button)
end

function Actions.SetItemMacro(button, itemID, targetSlot)
    if not button or not button.click or InCombatLockdown() then return end

    button.click:SetAttribute("type", "macro")
    button.click:SetAttribute("macrotext1",
        Actions.GetItemUseMacro(itemID, targetSlot))

    enableClick(button)
end

function Actions.SetSpell(button, spellName, available)
    if not button or not button.click or InCombatLockdown() then return end

    button.click:SetAttribute("spell", spellName)
    button.click:SetAttribute("type", "spell")

    setClickAvailability(button, available == true)
end

function Actions.SetWeaponEnchantItem(button, itemID, available)
    if not button or not button.click or InCombatLockdown() then return end

    button.click:SetAttribute("spell", nil)
    button.click:SetAttribute("item", "item:" .. itemID)
    button.click:SetAttribute("type", "item")

    setClickAvailability(button, available == true)
end
