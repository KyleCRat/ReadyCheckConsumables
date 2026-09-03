local _, RCC = ...

RCC.ConsumableFrameController = RCC.ConsumableFrameController or {}

local Controller = RCC.ConsumableFrameController
local DisplayContext = RCC.DisplayContext
local StateController = RCC.ConsumableStateController
local Surface = RCC.ConsumableSurface

local GetTime = GetTime

--------------------------------------------------------------------------------
--- State
--------------------------------------------------------------------------------

local frame
local readyCheckShowStart = 0
local wasInInstance
local wasInScenario
local instanceOpenPending
local instanceStateInitialized = false
local readyCheckButtonsHooked
local displayContext = DisplayContext.Create(
    RCC.DisplaySurface.CONSUMABLE_FRAME
)

local Reason = RCC.DisplayReason
local INSTANCE_OPEN_DELAY = 0.5

--------------------------------------------------------------------------------
--- Timer lifecycle
--------------------------------------------------------------------------------

local function cancelReadyCheckHideDelay(self)
    if self.readyCheckHideDelay then
        self.readyCheckHideDelay:Cancel()
        self.readyCheckHideDelay = nil
    end
end

local function cancelInstanceHideDelay(self)
    if self.instanceHideDelay then
        self.instanceHideDelay:Cancel()
        self.instanceHideDelay = nil
    end
end

local function updateOrHideAfterReasonChange(self)
    if not DisplayContext.HasAny(displayContext) then
        self:Hide()

        return
    end

    if InCombatLockdown() then
        return
    end

    self:Update()

    if not DisplayContext.IsActive(displayContext, Reason.READY_CHECK) then
        self:Repos(true)
    end
end

local function deactivateReason(self, reason)
    if not DisplayContext.Deactivate(displayContext, reason) then
        return false
    end

    if reason == Reason.READY_CHECK then
        self:UnregisterEvent("READY_CHECK_CONFIRM")
    end

    updateOrHideAfterReasonChange(self)

    return true
end

local function startInstanceHideDelay(self)
    cancelInstanceHideDelay(self)

    if not RCC.GetSetting("consumables_instanceHide") then
        return
    end

    local delay = RCC.GetSetting("consumables_instanceHideTime")

    self.instanceHideDelay = C_Timer.NewTimer(delay, function()
        self.instanceHideDelay = nil

        if not InCombatLockdown() then
            deactivateReason(self, Reason.INSTANCE_ENTRY)
        end
    end)
end

local function startReadyCheckHideDelay(self)
    if not RCC.GetSetting("consumables_minShow") then
        deactivateReason(self, Reason.READY_CHECK)

        return
    end

    local minShowTime = RCC.GetSetting("consumables_minShowTime")
    local elapsed = GetTime() - readyCheckShowStart
    local delay = max(minShowTime - elapsed, 0)

    if delay == 0 then
        deactivateReason(self, Reason.READY_CHECK)

        return
    end

    self.drag:Show()
    self.close:Show()

    self.readyCheckHideDelay = C_Timer.NewTimer(delay, function()
        self.readyCheckHideDelay = nil

        if not InCombatLockdown() then
            deactivateReason(self, Reason.READY_CHECK)
        end
    end)
end

--------------------------------------------------------------------------------
--- Frame visibility
--------------------------------------------------------------------------------

local function showConsumableFrame(self, isInitiator, registerConfirm,
                                   forceRepos)
    if InCombatLockdown() then
        return false
    end

    if not RCC.GetSetting("consumables_enabled") then
        self:Hide()

        return false
    end

    local wasShown = self:IsShown()

    self:SetScale(RCC.GetSetting("consumables_scale"))
    self:ApplyLayout()
    self:Show()
    self:Update()

    if registerConfirm then
        self:RegisterEvent("READY_CHECK_CONFIRM")
    end

    if forceRepos or not wasShown then
        self:Repos(isInitiator)
    end

    return true
end

local function activateAndShow(self, reason, isInitiator, registerConfirm,
                               forceRepos)
    DisplayContext.Activate(displayContext, reason)

    if showConsumableFrame(
        self,
        isInitiator,
        registerConfirm,
        forceRepos
    ) then
        return true
    end

    DisplayContext.Deactivate(displayContext, reason)

    return false
end

local function hideImmediately(self)
    instanceOpenPending = false
    cancelReadyCheckHideDelay(self)
    cancelInstanceHideDelay(self)
    self.anchor:Hide()

    if not InCombatLockdown() then
        self.drag:Hide()
        self.close:Hide()
    end

    self:Hide()
end

local function handleLocalReadyCheckResponse(self)
    if not DisplayContext.IsActive(displayContext, Reason.READY_CHECK) then
        return
    end

    if not self:IsShown() then
        cancelReadyCheckHideDelay(self)
        DisplayContext.Deactivate(displayContext, Reason.READY_CHECK)

        return
    end

    if InCombatLockdown() then
        hideImmediately(self)

        return
    end

    self:UnregisterEvent("READY_CHECK_CONFIRM")

    if self.readyCheckHideDelay then
        return
    end

    startReadyCheckHideDelay(self)
end

local function hookBlizzardReadyCheckButtons()
    if readyCheckButtonsHooked then
        return
    end

    if not ReadyCheckFrameYesButton or not ReadyCheckFrameNoButton then
        return
    end

    local function onReadyCheckButtonClick()
        if frame then
            handleLocalReadyCheckResponse(frame)
        end
    end

    ReadyCheckFrameYesButton:HookScript("OnClick", onReadyCheckButtonClick)
    ReadyCheckFrameNoButton:HookScript("OnClick", onReadyCheckButtonClick)
    readyCheckButtonsHooked = true
end

local function unregisterTransientEvents(self)
    self:UnregisterEvent("READY_CHECK_CONFIRM")
end

--------------------------------------------------------------------------------
--- Update pipeline
--------------------------------------------------------------------------------

function RCC.consumables:Update()
    return StateController.RefreshNow(true)
end

--------------------------------------------------------------------------------
--- Ready-check lifecycle
--------------------------------------------------------------------------------

local function onReadyCheck(self, initiatorUnit)
    instanceOpenPending = false
    readyCheckShowStart = GetTime()
    cancelReadyCheckHideDelay(self)
    hookBlizzardReadyCheckButtons()

    local isInitiator = RCC.F.UnitIsUnitSafe(initiatorUnit, "player")

    return activateAndShow(
        self,
        Reason.READY_CHECK,
        isInitiator,
        true,
        true
    )
end

local function onReadyCheckFinished(self)
    if not DisplayContext.IsActive(displayContext, Reason.READY_CHECK) then
        return
    end

    if not self:IsShown() then
        cancelReadyCheckHideDelay(self)
        DisplayContext.Deactivate(displayContext, Reason.READY_CHECK)

        return
    end

    if InCombatLockdown() then
        hideImmediately(self)

        return
    end

    if self.readyCheckHideDelay then
        return
    end

    startReadyCheckHideDelay(self)
end

local function onReadyCheckConfirm(self, unit)
    if not RCC.F.UnitIsUnitSafe(unit, "player") then
        return
    end

    handleLocalReadyCheckResponse(self)
end

local function onCombat(self)
    hideImmediately(self)
end

--------------------------------------------------------------------------------
--- Instance lifecycle
--------------------------------------------------------------------------------

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

local function scheduleInstanceOpen(self)
    if instanceOpenPending
        or not RCC.GetSetting("consumables_instanceOpen")
    then
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

        if activateAndShow(
            self,
            Reason.INSTANCE_ENTRY,
            true,
            false,
            false
        ) then
            startInstanceHideDelay(self)
        end
    end)
end

local function onPlayerEnteringWorld(self, isInitialLogin, isReloadingUi)
    local inInstance, instanceType = IsInInstance()
    local inScenario = inInstance and instanceType == "scenario"
    local initialWorldEntry = isInitialLogin or isReloadingUi
    local enteredInstance = instanceStateInitialized
        and inInstance and not wasInInstance
        and not initialWorldEntry
    local enteredScenario = instanceStateInitialized
        and inScenario and not wasInScenario
        and not initialWorldEntry

    wasInInstance = inInstance
    wasInScenario = inScenario
    instanceStateInitialized = true

    if enteredInstance or enteredScenario then
        scheduleInstanceOpen(self)
    end
end

local function onScenarioDataUpdate(self)
    local inInstance, instanceType = IsInInstance()
    local inScenario = inInstance and instanceType == "scenario"
    local enteredScenario = instanceStateInitialized
        and inScenario and not wasInScenario

    wasInScenario = inScenario

    if enteredScenario then
        scheduleInstanceOpen(self)
    end
end


local eventHandlers = {
    READY_CHECK               = onReadyCheck,
    READY_CHECK_FINISHED      = onReadyCheckFinished,
    READY_CHECK_CONFIRM       = onReadyCheckConfirm,
    PLAYER_REGEN_DISABLED     = onCombat,
    PLAYER_ENTERING_WORLD     = onPlayerEnteringWorld,
    SCENARIO_UPDATE           = onScenarioDataUpdate,
    ACTIVE_DELVE_DATA_UPDATE  = onScenarioDataUpdate,
}

local function onEvent(self, event, ...)
    local handler = eventHandlers[event]

    if handler then
        handler(self, ...)
    end
end

local function onHide(self)
    instanceOpenPending = false
    DisplayContext.Clear(displayContext)
    unregisterTransientEvents(self)
    self.anchor:Hide()
    cancelReadyCheckHideDelay(self)
    cancelInstanceHideDelay(self)
    if not InCombatLockdown() then
        self.drag:Hide()
        self.close:Hide()
    end
end

--------------------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------------------

function Controller.Attach(consumablesFrame)
    frame = consumablesFrame
    frame.displayContext = displayContext
    hookBlizzardReadyCheckButtons()

    frame:SetScript("OnEvent", onEvent)
    frame:SetScript("OnHide", onHide)

    frame:RegisterEvent("READY_CHECK")
    frame:RegisterEvent("READY_CHECK_FINISHED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("SCENARIO_UPDATE")
    frame:RegisterEvent("ACTIVE_DELVE_DATA_UPDATE")

    StateController.RegisterConsumer("temporaryConsumablesFrame", {
        IsActive = function()
            return frame:IsShown()
        end,
        ApplySnapshot = function(_, snapshot)
            frame:UpdateReadyCheckAnchor()
            Surface.ApplySnapshot(frame.surface, snapshot)

            if not InCombatLockdown() then
                Surface.ApplyTemporaryLayout(frame.surface, displayContext)
            end
        end,
    })
end

function Controller.StartReadyCheck(initiatorUnit)
    if not frame then return false end

    return onReadyCheck(frame, initiatorUnit)
end

function Controller.FinishReadyCheck()
    if not frame then return end

    return onReadyCheckFinished(frame)
end

function Controller.OpenForCauldronPickup()
    if not frame
        or not RCC.GetSetting("consumables_enabled")
        or not RCC.GetSetting("consumables_cauldronOpen")
        or InCombatLockdown()
    then
        return false
    end

    return activateAndShow(
        frame,
        Reason.CAULDRON_PICKUP,
        true,
        false,
        false
    )
end

function Controller.OpenForBreakTimer()
    if not frame
        or not RCC.GetSetting("consumables_enabled")
        or not RCC.GetSetting("consumables_breakOpen")
        or InCombatLockdown()
    then
        return false
    end

    return activateAndShow(
        frame,
        Reason.BREAK_TIMER,
        true,
        false,
        false
    )
end

function Controller.OpenManually()
    if not frame then return false end

    return activateAndShow(
        frame,
        Reason.MANUAL_OPEN,
        true,
        false,
        true
    )
end

function Controller.GetDisplayContext()
    return displayContext
end

function Controller.HideImmediately()
    if not frame then return end

    hideImmediately(frame)
end

function RCC.consumables:HideImmediately()
    Controller.HideImmediately()
end

Controller.Attach(RCC.consumables)
