local _, RCC = ...

RCC.ConsumableFrameActions = RCC.ConsumableFrameActions or {}

local Actions = RCC.ConsumableFrameActions
local ItemCache = RCC.ConsumableFrameItemCache

-- Action descriptors are plain data returned by consumable modules. Missing or
-- malformed actions disable clickable overlays by default.
RCC.ConsumableActionType = RCC.ConsumableActionType or {
    ITEM_MACRO          = "itemMacro",
    SPELL               = "spell",
    WEAPON_ENCHANT_ITEM = "weaponEnchantItem",
}

local ActionType = RCC.ConsumableActionType

local function scheduleConsumableFrameUpdate()
    C_Timer.After(0, function()
        if RCC.consumables
            and RCC.consumables:IsShown()
            and not InCombatLockdown()
        then
            RCC.consumables:Update()
        end
    end)
end

local function cacheClickedItem(self)
    if not ItemCache then return end

    ItemCache.Set(self.rccItemCacheKey, self.rccItemCacheID)
    scheduleConsumableFrameUpdate()
end

local function setClickCache(button, cacheKey, itemID)
    if not button or not button.click or InCombatLockdown() then return end

    button.click.rccItemCacheKey = cacheKey
    button.click.rccItemCacheID = itemID

    if cacheKey and itemID then
        button.click:SetScript("PostClick", cacheClickedItem)
    else
        button.click:SetScript("PostClick", nil)
    end
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

    setClickCache(button)
    disableClick(button)
end

local function setItemMacro(button, itemID, targetSlot, cacheKey)
    if not button or not button.click or InCombatLockdown() then return end

    button.click:SetAttribute("type", "macro")
    button.click:SetAttribute("macrotext1",
        getItemUseMacro(itemID, targetSlot))
    setClickCache(button, cacheKey, itemID)

    enableClick(button)
end

local function setSpell(button, spellName, available)
    if not button or not button.click or InCombatLockdown() then return end

    setClickCache(button)
    button.click:SetAttribute("spell", spellName)
    button.click:SetAttribute("type", "spell")

    setClickAvailability(button, available == true)
end

local function setWeaponEnchantItem(button, itemID, targetSlot, available,
                                    cacheKey)
    if not button or not button.click or InCombatLockdown() then return end

    if not targetSlot then
        setClickCache(button)
        disableClick(button)

        return
    end

    button.click:SetAttribute("spell", nil)
    button.click:SetAttribute("item", nil)
    button.click:SetAttribute("target-slot", nil)
    button.click:SetAttribute("type", "macro")
    button.click:SetAttribute("macrotext1",
        getItemUseMacro(itemID, targetSlot))
    setClickCache(button, cacheKey, itemID)

    setClickAvailability(button, available == true)
end

function Actions.Apply(button, action)
    if not button then return end

    if not action or not action.type then
        disable(button)

        return
    end

    if action.type == ActionType.ITEM_MACRO and action.itemID then
        setItemMacro(
            button,
            action.itemID,
            action.targetSlot,
            action.cacheKey
        )
    elseif action.type == ActionType.SPELL and action.spellName then
        setSpell(button, action.spellName, action.available)
    elseif action.type == ActionType.WEAPON_ENCHANT_ITEM
        and action.itemID and action.targetSlot
    then
        setWeaponEnchantItem(
            button,
            action.itemID,
            action.targetSlot,
            action.available,
            action.cacheKey
        )
    else
        disable(button)
    end
end
