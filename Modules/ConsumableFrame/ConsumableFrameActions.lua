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
        cacheKey = self.rccItemCacheKey,
        itemID = self.rccItemCacheID,
    })
end

local function clearClickedItemCache(self)
    queuePendingCacheAction({
        type = CACHE_ACTION_CLEAR,
        cacheKey = self.rccItemCacheKey,
    })
end

local function setClickCache(button, cacheKey, itemID)
    if not button or not button.click or InCombatLockdown() then return end

    button.click.rccItemCacheKey = cacheKey
    button.click.rccItemCacheID = itemID

    if cacheKey and itemID then
        button.click:SetScript("PreClick", cacheClickedItem)
    else
        button.click:SetScript("PreClick", nil)
    end
end

local function setClickCacheClear(button, cacheKey)
    if not button or not button.click or InCombatLockdown() then return end

    button.click.rccItemCacheKey = cacheKey
    button.click.rccItemCacheID = nil

    if cacheKey then
        button.click:SetScript("PreClick", clearClickedItemCache)
    else
        button.click:SetScript("PreClick", nil)
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

local function setSpell(button, spell, available, cacheKey)
    if not button or not button.click or InCombatLockdown() then return end

    setClickCacheClear(button, cacheKey)
    button.click:SetAttribute("spell", spell)
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
