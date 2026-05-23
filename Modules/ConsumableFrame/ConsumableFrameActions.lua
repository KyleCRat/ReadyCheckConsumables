local _, RCC = ...

RCC.ConsumableFrameActions = RCC.ConsumableFrameActions or {}

local Actions = RCC.ConsumableFrameActions
local ItemCache = RCC.ConsumableFrameItemCache

-- Action descriptors are plain data returned by consumable modules. Missing or
-- malformed actions disable clickable overlays by default.
RCC.ConsumableActionType = RCC.ConsumableActionType or {
    ITEM_MACRO          = "itemMacro",
    ITEM_CACHE_SELECT   = "itemCacheSelect",
    SPELL               = "spell",
    WEAPON_ENCHANT_ITEM = "weaponEnchantItem",
}

local ActionType = RCC.ConsumableActionType

-- Click contract:
-- LeftButton uses secure action attributes with the "1" suffix.
-- RightButton only stores the preferred item through PreClick.
-- Do not set "2" suffix action attributes unless right-click should consume.
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

local function preferClickedItem(self, mouseButton)
    if mouseButton ~= "RightButton" then return end

    local cacheKey = self.consumableFrameItemCacheKey
    local itemID = self.consumableFrameItemCacheID

    if not cacheKey or not itemID then return end

    ItemCache.Set(cacheKey, itemID)
    scheduleConsumableFrameUpdate()
end

local function setRightClickPreference(button, cacheKey, itemID)
    if not button or not button.click or InCombatLockdown() then return end

    local click = button.click

    if click.consumableFrameItemCacheKey == cacheKey
        and click.consumableFrameItemCacheID == itemID
    then
        return
    end

    click.consumableFrameItemCacheKey = cacheKey
    click.consumableFrameItemCacheID = itemID

    if cacheKey and itemID then
        click:SetScript("PreClick", preferClickedItem)
    else
        click:SetScript("PreClick", nil)
    end
end

local function clearLeftClickAction(click)
    click:SetAttribute("type1", nil)
    click:SetAttribute("spell1", nil)
    click:SetAttribute("macrotext1", nil)
end

local function enableClick(button)
    button.clickEnabled = true

    if not button.click or InCombatLockdown() then return end

    if not button.click:IsShown() then
        button.click:Show()
    end
end

local function disableClick(button)
    button.clickEnabled = false

    if not button.click or InCombatLockdown() then return end

    if button.click:IsShown() then
        button.click:Hide()
    end
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

    if not InCombatLockdown() then
        button.click.consumableFrameActionSignature = nil
        clearLeftClickAction(button.click)
        setRightClickPreference(button)
    end

    disableClick(button)
end

local function setItemMacro(button, itemID, targetSlot, cacheKey)
    if not button or not button.click or InCombatLockdown() then return end

    local click = button.click
    local macroText = getItemUseMacro(itemID, targetSlot)
    local signature = table.concat({
        ActionType.ITEM_MACRO,
        tostring(itemID),
        tostring(targetSlot or ""),
        tostring(cacheKey or ""),
    }, "|")

    if click.consumableFrameActionSignature ~= signature then
        clearLeftClickAction(click)
        click:SetAttribute("type1", "macro")
        click:SetAttribute("macrotext1", macroText)
        setRightClickPreference(button, cacheKey, itemID)
        click.consumableFrameActionSignature = signature
    end

    enableClick(button)
end

local function setPreferenceOnly(button, itemID, cacheKey)
    if not button or not button.click or InCombatLockdown() then return end

    if not itemID or not cacheKey then
        setRightClickPreference(button)
        disableClick(button)

        return
    end

    local click = button.click
    local signature = table.concat({
        ActionType.ITEM_CACHE_SELECT,
        tostring(itemID),
        tostring(cacheKey),
    }, "|")

    if click.consumableFrameActionSignature ~= signature then
        clearLeftClickAction(click)
        setRightClickPreference(button, cacheKey, itemID)
        click.consumableFrameActionSignature = signature
    end

    enableClick(button)
end

local function setSpell(button, spell, available)
    if not button or not button.click or InCombatLockdown() then return end

    local click = button.click
    local signature = table.concat({
        ActionType.SPELL,
        tostring(spell),
    }, "|")

    if click.consumableFrameActionSignature ~= signature then
        setRightClickPreference(button)
        clearLeftClickAction(click)
        click:SetAttribute("spell1", spell)
        click:SetAttribute("type1", "spell")
        click.consumableFrameActionSignature = signature
    end

    setClickAvailability(button, available == true)
end

local function setWeaponEnchantItem(button, itemID, targetSlot, available,
                                    cacheKey)
    if not button or not button.click or InCombatLockdown() then return end

    if not targetSlot then
        setRightClickPreference(button)
        disableClick(button)

        return
    end

    local click = button.click
    local macroText = getItemUseMacro(itemID, targetSlot)
    local signature = table.concat({
        ActionType.WEAPON_ENCHANT_ITEM,
        tostring(itemID),
        tostring(targetSlot),
        tostring(cacheKey or ""),
    }, "|")

    if click.consumableFrameActionSignature ~= signature then
        clearLeftClickAction(click)
        click:SetAttribute("type1", "macro")
        click:SetAttribute("macrotext1", macroText)
        setRightClickPreference(button, cacheKey, itemID)
        click.consumableFrameActionSignature = signature
    end

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
    elseif action.type == ActionType.ITEM_CACHE_SELECT
        and action.itemID and action.cacheKey
    then
        setPreferenceOnly(
            button,
            action.itemID,
            action.cacheKey
        )
    elseif action.type == ActionType.SPELL
        and (action.spellID or action.spellName)
    then
        setSpell(
            button,
            action.spellID or action.spellName,
            action.available
        )
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
