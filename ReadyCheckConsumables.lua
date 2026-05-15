local ADDON_NAME, RCC = ...

RCC.color = "cff00cc"
RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Helpers
--------------------------------------------------------------------------------

local consumablesShowStart = 0
local wasInInstance
local instanceOpenPending

local INSTANCE_OPEN_DELAY = 0.5

local function cancelDelay(self)
    if self.cancelDelay then
        self.cancelDelay:Cancel()
        self.cancelDelay = nil
    end
end

local function cancelInstanceHideDelay(self)
    if self.instanceHideDelay then
        self.instanceHideDelay:Cancel()
        self.instanceHideDelay = nil
    end
end

local function startInstanceHideDelay(self)
    cancelInstanceHideDelay(self)

    if not RCC.GetSetting("consumables_instanceHide") then
        return
    end

    local delay = RCC.GetSetting("consumables_instanceHideTime")

    self.instanceHideDelay = C_Timer.NewTimer(delay, function()
        if not InCombatLockdown() then
            RCC.consumables:Hide()
        end
    end)
end

local function shouldOpenForInstanceType(instanceType)
    if instanceType == "party" then
        return RCC.GetSetting("consumables_instanceOpenParty")
    elseif instanceType == "raid" then
        return RCC.GetSetting("consumables_instanceOpenRaid")
    elseif instanceType == "scenario" then
        return RCC.GetSetting("consumables_instanceOpenScenario")
    elseif instanceType == "pvp" then
        return RCC.GetSetting("consumables_instanceOpenPvp")
    elseif instanceType == "arena" then
        return RCC.GetSetting("consumables_instanceOpenArena")
    end

    return false
end

local function showConsumablesFrame(self, isInitiator, registerConfirm)
    if InCombatLockdown() then
        return false
    end

    if not RCC.GetSetting("consumables_enabled") then
        self:Hide()

        return false
    end

    consumablesShowStart = GetTime()

    self:SetScale(RCC.GetSetting("consumables_scale"))
    self:Show()
    self:Update()
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("UNIT_INVENTORY_CHANGED")

    if registerConfirm then
        self:RegisterEvent("READY_CHECK_CONFIRM")
    end

    cancelDelay(self)
    cancelInstanceHideDelay(self)
    self:Repos(isInitiator)

    return true
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
    local isInitiator = initiatorUnit and UnitIsUnit(initiatorUnit, "player")

    showConsumablesFrame(self, isInitiator, true)
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
--- PLAYER_ENTERING_WORLD
--------------------------------------------------------------------------------

local function onPlayerEnteringWorld(self, isInitialLogin, isReloadingUi)
    local inInstance, instanceType = IsInInstance()
    local enteredInstance = inInstance and not wasInInstance
        and not isInitialLogin and not isReloadingUi

    wasInInstance = inInstance

    if not enteredInstance then
        return
    end

    if not RCC.GetSetting("consumables_instanceOpen") then
        return
    end

    if not shouldOpenForInstanceType(instanceType) then
        return
    end

    instanceOpenPending = true

    C_Timer.After(INSTANCE_OPEN_DELAY, function()
        if not instanceOpenPending then
            return
        end

        instanceOpenPending = false

        local stillInInstance, currentInstanceType = IsInInstance()

        if InCombatLockdown() or not stillInInstance
            or not shouldOpenForInstanceType(currentInstanceType)
        then
            return
        end

        if showConsumablesFrame(self, true, false) then
            startInstanceHideDelay(self)
        end
    end)
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
        C_Timer.After(0.2, function()
            if self:IsShown() and not InCombatLockdown() then
                self:Update()
            end
        end)
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
    PLAYER_ENTERING_WORLD   = onPlayerEnteringWorld,
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
    instanceOpenPending = false
    RCC.consumables:OnHide()
    cancelInstanceHideDelay(self)

    if not InCombatLockdown() then
        self.drag:Hide()
        self.close:Hide()
    end
end)

RCC.consumables:RegisterEvent("READY_CHECK")
RCC.consumables:RegisterEvent("READY_CHECK_FINISHED")
RCC.consumables:RegisterEvent("PLAYER_REGEN_DISABLED")
RCC.consumables:RegisterEvent("PLAYER_ENTERING_WORLD")
