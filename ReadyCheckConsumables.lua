local ADDON_NAME, RCC = ...

RCC.color = "cff00cc"
RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Helpers
--------------------------------------------------------------------------------

local consumablesShowStart = 0

local function cancelDelay(self)
    if self.cancelDelay then
        self.cancelDelay:Cancel()
        self.cancelDelay = nil
    end
end

local function startMinShowDelay(self)
    if not RCC.GetSetting("consumables_minShow") then
        self:Hide()

        return
    end

    local minShowTime = RCC.GetSetting("consumables_minShowTime")
    local elapsed = GetTime() - consumablesShowStart
    local delay = max(minShowTime - elapsed, 0)

    if delay == 0 then
        self:Hide()

        return
    end

    self.drag:Show()
    self.close:Show()

    self.cancelDelay = C_Timer.NewTimer(delay, function()
        if not InCombatLockdown() then
            RCC.consumables:Hide()
        end
    end)
end

--------------------------------------------------------------------------------
--- READY_CHECK
--------------------------------------------------------------------------------

local function onReadyCheck(self, initiatorUnit)
    if InCombatLockdown() then
        return
    end

    if not RCC.GetSetting("consumables_enabled") then
        self:Hide()

        return
    end

    consumablesShowStart = GetTime()

    self:SetScale(RCC.GetSetting("consumables_scale"))
    self:Show()
    self:Update()
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("UNIT_INVENTORY_CHANGED")
    self:RegisterEvent("READY_CHECK_CONFIRM")

    cancelDelay(self)

    if initiatorUnit and UnitIsUnit(initiatorUnit, "player") then
        self:Repos(true)
    else
        self:Repos()
    end
end

--------------------------------------------------------------------------------
--- READY_CHECK_FINISHED
--------------------------------------------------------------------------------

local function onReadyCheckFinished(self)
    if not self:IsShown() then
        cancelDelay(self)

        return
    end

    if InCombatLockdown() then
        cancelDelay(self)
        self:Hide()

        return
    end

    if self.cancelDelay then
        return
    end

    startMinShowDelay(self)
end

--------------------------------------------------------------------------------
--- READY_CHECK_CONFIRM
--------------------------------------------------------------------------------

local function onReadyCheckConfirm(self, unit)
    if not unit or not UnitIsUnit(unit, "player") then
        return
    end

    self:UnregisterEvent("READY_CHECK_CONFIRM")
    startMinShowDelay(self)
end

--------------------------------------------------------------------------------
--- PLAYER_REGEN_DISABLED
--------------------------------------------------------------------------------

local function onCombat(self)
    self:Hide()
end

--------------------------------------------------------------------------------
--- UNIT_AURA
--------------------------------------------------------------------------------

local function onUnitAura(self, unit)
    if unit == "player" then
        self:Update()
    end
end

--------------------------------------------------------------------------------
--- UNIT_INVENTORY_CHANGED
--------------------------------------------------------------------------------

local function onInventoryChanged(self, unit)
    if unit == "player" then
        C_Timer.After(0.2, function() self:Update() end)
    end
end

--------------------------------------------------------------------------------
--- Dispatch
--------------------------------------------------------------------------------

local eventHandlers = {
    READY_CHECK            = onReadyCheck,
    READY_CHECK_FINISHED   = onReadyCheckFinished,
    READY_CHECK_CONFIRM    = onReadyCheckConfirm,
    PLAYER_REGEN_DISABLED  = onCombat,
    UNIT_AURA              = onUnitAura,
    UNIT_INVENTORY_CHANGED = onInventoryChanged,
}

RCC.consumables:SetScript("OnEvent", function(self, event, ...)
    local handler = eventHandlers[event]

    if handler then
        handler(self, ...)
    end
end)

RCC.consumables:SetScript("OnHide", function(self)
    RCC.consumables:OnHide()

    if not InCombatLockdown() then
        self.drag:Hide()
        self.close:Hide()
    end
end)

RCC.consumables:RegisterEvent("READY_CHECK")
RCC.consumables:RegisterEvent("READY_CHECK_FINISHED")
RCC.consumables:RegisterEvent("PLAYER_REGEN_DISABLED")
