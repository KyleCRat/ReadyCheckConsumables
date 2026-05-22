local _, RCC = ...

RCC.ConsumableFrameController = RCC.ConsumableFrameController or {}

local Controller = RCC.ConsumableFrameController
local Auras = RCC.ConsumableFrameAuras
local Buttons = RCC.ConsumableFrameButtons
local Food = RCC.Consumables.Food
local Flask = RCC.Consumables.Flask
local Augment = RCC.Consumables.Augment
local Healthstone = RCC.Consumables.Healthstone
local DamagePotion = RCC.Consumables.DamagePotion
local HealingPotion = RCC.Consumables.HealingPotion
local Recuperate = RCC.Consumables.Recuperate
local RaidBuff = RCC.Consumables.RaidBuff
local Vantus = RCC.Consumables.Vantus
local WeaponEnchant = RCC.Consumables.WeaponEnchant

local GetTime = GetTime

--------------------------------------------------------------------------------
--- State
--------------------------------------------------------------------------------

local frame
local consumablesShowStart = 0
local wasInInstance
local instanceOpenPending

local INSTANCE_OPEN_DELAY = 0.5

--------------------------------------------------------------------------------
--- Timer lifecycle
--------------------------------------------------------------------------------

local function cancelMinShowDelay(self)
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
            self:Hide()
        end
    end)
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
            self:Hide()
        end
    end)
end

--------------------------------------------------------------------------------
--- Frame visibility
--------------------------------------------------------------------------------

local function showConsumableFrame(self, isInitiator, registerConfirm)
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
    self:RegisterEvent("BAG_UPDATE_DELAYED")

    if registerConfirm then
        self:RegisterEvent("READY_CHECK_CONFIRM")
    end

    cancelMinShowDelay(self)
    cancelInstanceHideDelay(self)
    self:Repos(isInitiator)

    return true
end

local function hideImmediately(self)
    instanceOpenPending = false
    cancelMinShowDelay(self)
    cancelInstanceHideDelay(self)
    self.anchor:Hide()

    if not InCombatLockdown() then
        self.drag:Hide()
        self.close:Hide()
    end

    self:Hide()
end

local function unregisterLiveEvents(self)
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
    self:UnregisterEvent("BAG_UPDATE_DELAYED")
    self:UnregisterEvent("READY_CHECK_CONFIRM")
end

--------------------------------------------------------------------------------
--- Update pipeline
--------------------------------------------------------------------------------

function RCC.consumables:Update()
    self:UpdateReadyCheckAnchor()
    local buttons = self.buttons

    local now = GetTime()
    local auraState = Auras.ScanPlayer(now)

    Food.Update(buttons.food, auraState)
    Healthstone.Update(buttons.hs)
    Flask.Update(buttons.flask, auraState)
    WeaponEnchant.Update(buttons)
    Augment.Update(buttons.augment, auraState)
    RaidBuff.Update(buttons.raidBuff)
    DamagePotion.Update(buttons.dmgpot)
    HealingPotion.Update(buttons.healpot)
    Recuperate.Update(buttons.recuperate)
    Vantus.Update(buttons.vantus, auraState)

    if not InCombatLockdown() then
        Buttons.ApplyLayout(self, buttons)
    end

    Buttons.UpdateUnavailableOverlays(buttons)
end

--------------------------------------------------------------------------------
--- Ready-check lifecycle
--------------------------------------------------------------------------------

local function onReadyCheck(self, initiatorUnit)
    instanceOpenPending = false

    local isInitiator = RCC.F.UnitIsUnitSafe(initiatorUnit, "player")

    return showConsumableFrame(self, isInitiator, true)
end

local function onReadyCheckFinished(self)
    if not self:IsShown() then
        cancelMinShowDelay(self)

        return
    end

    if InCombatLockdown() then
        hideImmediately(self)

        return
    end

    if self.cancelDelay then
        return
    end

    startMinShowDelay(self)
end

local function onReadyCheckConfirm(self, unit)
    if not RCC.F.UnitIsUnitSafe(unit, "player") then
        return
    end

    self:UnregisterEvent("READY_CHECK_CONFIRM")
    startMinShowDelay(self)
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

        if showConsumableFrame(self, true, false) then
            startInstanceHideDelay(self)
        end
    end)
end

--------------------------------------------------------------------------------
--- Live updates
--------------------------------------------------------------------------------

local function onUnitAura(self, unit)
    if RCC.F.UnitIsUnitSafe(unit, "player") then
        self:Update()
    end
end

local function scheduleLiveUpdate(self)
    C_Timer.After(0.2, function()
        if self:IsShown() and not InCombatLockdown() then
            self:Update()
        end
    end)
end

local function onInventoryChanged(self, unit)
    if RCC.F.UnitIsUnitSafe(unit, "player") then
        scheduleLiveUpdate(self)
    end
end

local function onBagUpdateDelayed(self)
    scheduleLiveUpdate(self)
end

--------------------------------------------------------------------------------
--- Event wiring
--------------------------------------------------------------------------------

local eventHandlers = {
    READY_CHECK            = onReadyCheck,
    READY_CHECK_FINISHED   = onReadyCheckFinished,
    READY_CHECK_CONFIRM    = onReadyCheckConfirm,
    PLAYER_REGEN_DISABLED  = onCombat,
    PLAYER_ENTERING_WORLD   = onPlayerEnteringWorld,
    UNIT_AURA              = onUnitAura,
    UNIT_INVENTORY_CHANGED = onInventoryChanged,
    BAG_UPDATE_DELAYED     = onBagUpdateDelayed,
}

local function onEvent(self, event, ...)
    local handler = eventHandlers[event]

    if handler then
        handler(self, ...)
    end
end

local function onHide(self)
    instanceOpenPending = false
    unregisterLiveEvents(self)
    self.anchor:Hide()
    cancelMinShowDelay(self)
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

    frame:SetScript("OnEvent", onEvent)
    frame:SetScript("OnHide", onHide)

    frame:RegisterEvent("READY_CHECK")
    frame:RegisterEvent("READY_CHECK_FINISHED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function Controller.StartReadyCheck(initiatorUnit)
    if not frame then return false end

    return onReadyCheck(frame, initiatorUnit)
end

function Controller.FinishReadyCheck()
    if not frame then return end

    return onReadyCheckFinished(frame)
end

function Controller.HideImmediately()
    if not frame then return end

    hideImmediately(frame)
end

function RCC.consumables:HideImmediately()
    Controller.HideImmediately()
end

Controller.Attach(RCC.consumables)
