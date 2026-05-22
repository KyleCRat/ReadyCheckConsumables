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
local CACHE_COMMIT_DELAY = 0.1
local CACHE_ERROR_SUPPRESS_WINDOW = 0.5
local CACHE_ACTION_SET = "set"
local CACHE_ACTION_CLEAR = "clear"
local pendingCacheAction
local pendingCacheToken = 0
local lastErrorTime = 0
local cacheEventFrame = CreateFrame("Frame")

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

local function unregisterCacheEvents()
    cacheEventFrame:UnregisterEvent("UI_ERROR_MESSAGE")
    cacheEventFrame:UnregisterEvent("UI_ERROR_POPUP")
    cacheEventFrame:UnregisterEvent("UI_INFO_MESSAGE")
end

local function clearPendingCacheAction()
    pendingCacheAction = nil
    pendingCacheToken = pendingCacheToken + 1
    lastErrorTime = GetTime()
    unregisterCacheEvents()
end

local function commitPendingCacheAction(token)
    if token ~= pendingCacheToken or not pendingCacheAction then return end

    local action = pendingCacheAction

    pendingCacheAction = nil
    unregisterCacheEvents()

    if action.type == CACHE_ACTION_SET then
        ItemCache.Set(action.cacheKey, action.itemID)
    elseif action.type == CACHE_ACTION_CLEAR then
        ItemCache.Clear(action.cacheKey)
    end

    scheduleConsumableFrameUpdate()
end

local function queuePendingCacheAction(action)
    if not ItemCache or not action or not action.cacheKey then return end

    if GetTime() - lastErrorTime < CACHE_ERROR_SUPPRESS_WINDOW then
        return
    end

    -- Use errors can fire during the secure action before PostClick runs, so
    -- start watching in PreClick and commit only after a quiet frame window.
    pendingCacheAction = action
    pendingCacheToken = pendingCacheToken + 1

    local token = pendingCacheToken

    cacheEventFrame:RegisterEvent("UI_ERROR_MESSAGE")
    cacheEventFrame:RegisterEvent("UI_ERROR_POPUP")
    cacheEventFrame:RegisterEvent("UI_INFO_MESSAGE")
    C_Timer.After(CACHE_COMMIT_DELAY, function()
        commitPendingCacheAction(token)
    end)
end

cacheEventFrame:SetScript("OnEvent", function()
    if pendingCacheAction then
        clearPendingCacheAction()
    end
end)

local function cacheClickedItem(self)
    queuePendingCacheAction({
        type = CACHE_ACTION_SET,
        cacheKey = self.consumableFrameItemCacheKey,
        itemID = self.consumableFrameItemCacheID,
    })
end

local function clearClickedItemCache(self)
    queuePendingCacheAction({
        type = CACHE_ACTION_CLEAR,
        cacheKey = self.consumableFrameItemCacheKey,
    })
end

local function setClickCache(button, cacheKey, itemID)
    if not button or not button.click or InCombatLockdown() then return end

    local click = button.click

    if click.consumableFrameItemCacheMode == CACHE_ACTION_SET
        and click.consumableFrameItemCacheKey == cacheKey
        and click.consumableFrameItemCacheID == itemID
    then
        return
    end

    click.consumableFrameItemCacheMode = CACHE_ACTION_SET
    click.consumableFrameItemCacheKey = cacheKey
    click.consumableFrameItemCacheID = itemID

    if cacheKey and itemID then
        click:SetScript("PreClick", cacheClickedItem)
    else
        click:SetScript("PreClick", nil)
    end
end

local function setClickCacheClear(button, cacheKey)
    if not button or not button.click or InCombatLockdown() then return end

    local click = button.click

    if click.consumableFrameItemCacheMode == CACHE_ACTION_CLEAR
        and click.consumableFrameItemCacheKey == cacheKey
        and click.consumableFrameItemCacheID == nil
    then
        return
    end

    click.consumableFrameItemCacheMode = CACHE_ACTION_CLEAR
    click.consumableFrameItemCacheKey = cacheKey
    click.consumableFrameItemCacheID = nil

    if cacheKey then
        click:SetScript("PreClick", clearClickedItemCache)
    else
        click:SetScript("PreClick", nil)
    end
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
        setClickCache(button)
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
        click:SetAttribute("type", "macro")
        click:SetAttribute("macrotext1", macroText)
        setClickCache(button, cacheKey, itemID)
        click.consumableFrameActionSignature = signature
    end

    enableClick(button)
end

local function setSpell(button, spell, available, cacheKey)
    if not button or not button.click or InCombatLockdown() then return end

    local click = button.click
    local signature = table.concat({
        ActionType.SPELL,
        tostring(spell),
        tostring(cacheKey or ""),
    }, "|")

    if click.consumableFrameActionSignature ~= signature then
        setClickCacheClear(button, cacheKey)
        click:SetAttribute("spell", spell)
        click:SetAttribute("type", "spell")
        click.consumableFrameActionSignature = signature
    end

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

    local click = button.click
    local macroText = getItemUseMacro(itemID, targetSlot)
    local signature = table.concat({
        ActionType.WEAPON_ENCHANT_ITEM,
        tostring(itemID),
        tostring(targetSlot),
        tostring(cacheKey or ""),
    }, "|")

    if click.consumableFrameActionSignature ~= signature then
        click:SetAttribute("spell", nil)
        click:SetAttribute("item", nil)
        click:SetAttribute("target-slot", nil)
        click:SetAttribute("type", "macro")
        click:SetAttribute("macrotext1", macroText)
        setClickCache(button, cacheKey, itemID)
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
    elseif action.type == ActionType.SPELL
        and (action.spellID or action.spellName)
    then
        setSpell(
            button,
            action.spellID or action.spellName,
            action.available,
            action.cacheKey
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
