local _, RCC = ...

local Broadcast       = RCC.RaidFrameBroadcast
local Cauldron        = RCC.RaidFrameCauldron
local Columns         = RCC.RaidFrameColumns
local Controls        = RCC.RaidFrameControls
local DisplayContext  = RCC.DisplayContext
local Feast           = RCC.RaidFrameFeast
local FrameAnimations = RCC.FrameAnimations
local Members         = RCC.RaidFrameMembers
local ReadyChecks     = RCC.ReadyCheckController
local Rows            = RCC.RaidFrameRows
local Test            = RCC.RaidFrameTest
local TitleBar        = RCC.RaidFrameTitleBar

local GetTime = GetTime

--------------------------------------------------------------------------------
--- Constants
--------------------------------------------------------------------------------

local ADDON_REFRESH_DELAY         = 0.25
local READY_CHECK_BROADCAST_DELAY = 0.2
local FADE_OUT_DURATION           = 0.5
local FEAST_SOURCE                = "feast"

local Reason = RCC.DisplayReason
local displayContext = DisplayContext.Create(RCC.DisplaySurface.RAID_FRAME)
local LAYOUT = Columns.CreateLayout()

local broadcast             = Broadcast.Create()
local presenceData          = broadcast:GetPresenceData()
local foodData              = broadcast:GetFoodData()
local flaskData             = broadcast:GetFlaskData()
local durabilityData        = broadcast:GetDurabilityData()
local tempWeaponEnchantData = broadcast:GetTempWeaponEnchantData()

--------------------------------------------------------------------------------
--- Frame creation
--------------------------------------------------------------------------------

local frame   = CreateFrame("Frame", "RCRaidFrame", UIParent, "BackdropTemplate")
RCC.raidFrame = frame

frame:SetWidth(LAYOUT.frameWidth)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:SetFrameStrata("HIGH")
frame:SetToplevel(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:Hide()

frame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
frame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
frame:SetBackdropBorderColor(0, 0, 0, 1)

local controls = Controls.Create(frame)

--------------------------------------------------------------------------------
--- Title Bar
--------------------------------------------------------------------------------

local titleBar = TitleBar.Create(frame, LAYOUT)

--------------------------------------------------------------------------------
--- Row creation (pre-allocate 40 rows)
--------------------------------------------------------------------------------

frame.rows = Rows.Create(frame, titleBar, LAYOUT)
frame:SetHeight(frame.rows.initialFrameHeight)

--------------------------------------------------------------------------------
--- Member data storage
--------------------------------------------------------------------------------

-- state.readyCheck is a read-only reference to the shared session, not row-owned
-- response storage. Closing this display must never cancel that session.
local state = {
    members        = {},  -- [i] = { name, unit, class, online, isDead, columnData }
    unitToIndex    = {},  -- [unit] = i
    activeCount    = 0,
}

local renderContext = {
    state  = state,
    display = displayContext,
    shared = {
        presenceData          = presenceData,
        foodData              = foodData,
        flaskData             = flaskData,
        durabilityData        = durabilityData,
        tempWeaponEnchantData = tempWeaponEnchantData,
    },
    rules = Columns.RULES,
}

local function registerReadyCheckDataEvents()
    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    frame:RegisterEvent("WEAPON_ENCHANT_CHANGED")
    frame:RegisterEvent("WEAPON_SLOT_CHANGED")
end

local function unregisterReadyCheckDataEvents()
    frame:UnregisterEvent("UNIT_AURA")
    frame:UnregisterEvent("UPDATE_INVENTORY_DURABILITY")
    frame:UnregisterEvent("UNIT_INVENTORY_CHANGED")
    frame:UnregisterEvent("WEAPON_ENCHANT_CHANGED")
    frame:UnregisterEvent("WEAPON_SLOT_CHANGED")
end

local function syncProvisionReasons()
    if Feast.IsEnabled() and Feast.IsActive() then
        DisplayContext.Activate(
            displayContext,
            Reason.FEAST_DROP,
            FEAST_SOURCE
        )
    else
        DisplayContext.Deactivate(
            displayContext,
            Reason.FEAST_DROP,
            FEAST_SOURCE
        )
    end

    if Cauldron.IsEnabled() then
        for i = 1, #Cauldron.TRACKED_CAULDRON_TYPES do
            local kind = Cauldron.TRACKED_CAULDRON_TYPES[i]

            if Cauldron.IsActive(kind) then
                DisplayContext.Activate(
                    displayContext,
                    Reason.CAULDRON_DROP,
                    kind
                )
            else
                DisplayContext.Deactivate(
                    displayContext,
                    Reason.CAULDRON_DROP,
                    kind
                )
            end
        end
    else
        DisplayContext.Deactivate(displayContext, Reason.CAULDRON_DROP)
    end
end

local function syncDisplayEvents()
    if DisplayContext.IsActive(displayContext, Reason.READY_CHECK) then
        registerReadyCheckDataEvents()

        return
    end

    unregisterReadyCheckDataEvents()

    if frame:IsShown() and DisplayContext.HasAny(displayContext) then
        frame:RegisterEvent("UNIT_AURA")
    end
end

local function configureDisplay()
    Columns.ConfigureLayout(LAYOUT, displayContext)
    frame:SetWidth(LAYOUT.frameWidth)
    titleBar:ApplyLayout(LAYOUT)
    syncDisplayEvents()
end

--------------------------------------------------------------------------------
--- Ready check summary presentation (counts belong to ReadyCheckState)
--------------------------------------------------------------------------------

local function refreshReadyCheckSummary()
    local session = state.readyCheck

    if not session then
        return
    end

    local summary = session.summary

    if not session.inProgress or summary.allResponded then
        titleBar:StopProgress()
        titleBar:ShowFinishedSummary(summary)
    else
        titleBar:SetRespondedCount(summary.respondedCount, summary.activeCount)
    end
end

local function refreshRowAndTitle(index)
    configureDisplay()
    Rows.RefreshRow(frame.rows[index], state.members[index], LAYOUT, renderContext)
    titleBar:RefreshFromMembers(
        state.members,
        state.activeCount,
        LAYOUT,
        renderContext
    )
end

local function refreshAllRowsAndTitle()
    configureDisplay()
    frame:SetHeight(Rows.RefreshAll(frame.rows, state, LAYOUT, renderContext))
    titleBar:RefreshFromMembers(
        state.members,
        state.activeCount,
        LAYOUT,
        renderContext
    )
end

--------------------------------------------------------------------------------
--- Ready check lifecycle
--------------------------------------------------------------------------------

local hideTimer
local addonRefreshTimer
local readyCheckBroadcastTimer
local tempWeaponEnchantTimer
local fadeOut = FrameAnimations.CreateFadeOut(frame, {
    duration = FADE_OUT_DURATION,
})
local showStartTime = 0

local function cancelAddonRefreshTimer()
    if addonRefreshTimer then
        addonRefreshTimer:Cancel()
        addonRefreshTimer = nil
    end
end

local function cancelReadyCheckBroadcastTimer()
    if readyCheckBroadcastTimer then
        readyCheckBroadcastTimer:Cancel()
        readyCheckBroadcastTimer = nil
    end
end

local function cancelTempWeaponEnchantTimer()
    if tempWeaponEnchantTimer then
        tempWeaponEnchantTimer:Cancel()
        tempWeaponEnchantTimer = nil
    end
end

local function scheduleAddonRefresh()
    if addonRefreshTimer
        or not frame:IsShown()
        or fadeOut.isFadingOut
    then
        return
    end

    addonRefreshTimer = C_Timer.NewTimer(ADDON_REFRESH_DELAY, function()
        addonRefreshTimer = nil

        if frame:IsShown() and not fadeOut.isFadingOut then
            refreshAllRowsAndTitle()
        end
    end)
end

local function cancelHideTimer()
    if hideTimer then
        hideTimer:Cancel()
        hideTimer = nil
    end
end

local function cancelSyntheticReadyCheck()
    RCC.ReadyCheckTest:Cancel()
end

local function beginReadyCheckDisplay(manualShow)
    cancelHideTimer()
    cancelAddonRefreshTimer()
    fadeOut:Cancel()
    DisplayContext.Activate(displayContext, Reason.READY_CHECK)
    syncProvisionReasons()
    configureDisplay()

    frame.manualShow = manualShow or false
    showStartTime = GetTime()
end

local function showReadyCheckDisplay(duration, showProgress)
    refreshAllRowsAndTitle()

    if showProgress then
        titleBar:StartProgress(duration or 30)
    else
        titleBar:StopProgress()
    end

    refreshReadyCheckSummary()

    controls:RestorePosition()
    controls:SyncScale()
    frame:Show()
end

local function canShowProvisionOnly(ignoreAutoShowSetting)
    if InCombatLockdown() then
        return false
    end

    local feastActive = DisplayContext.IsActive(
        displayContext,
        Reason.FEAST_DROP
    )
    local cauldronActive = DisplayContext.IsActive(
        displayContext,
        Reason.CAULDRON_DROP
    )

    if ignoreAutoShowSetting then
        return feastActive or cauldronActive
    end

    return feastActive and Feast.ShouldShowOutsideReadyCheck()
        or cauldronActive and Cauldron.ShouldShowOutsideReadyCheck()
end

local function beginProvisionDisplay()
    cancelHideTimer()
    cancelAddonRefreshTimer()
    fadeOut:Cancel()
    titleBar:StopProgress()
    syncProvisionReasons()
    configureDisplay()
    state.readyCheck = nil
end

local function getProvisionHeaderText()
    local feastActive = Feast.IsActive()
    local cauldronActive = Cauldron.HasActiveCauldron()

    if feastActive and cauldronActive then
        return "Feast & Cauldrons"
    elseif feastActive then
        return "Feast"
    end

    return "Cauldrons"
end

local function showProvisionDisplayFromState()
    fadeOut:Cancel()
    titleBar:SetHeaderText(getProvisionHeaderText())
    refreshAllRowsAndTitle()

    controls:RestorePosition()
    controls:SyncScale()
    frame:Show()
    syncDisplayEvents()

    return true
end

local function showProvisionDisplay(ignoreAutoShowSetting)
    syncProvisionReasons()

    if not canShowProvisionOnly(ignoreAutoShowSetting) then
        return false
    end

    beginProvisionDisplay()
    Members.ScanAll(state, LAYOUT, renderContext)

    return showProvisionDisplayFromState()
end

local function scanPlayerTimedConsumables()
    return Columns.ScanUnitData(
        "player",
        GetTime(),
        LAYOUT,
        renderContext,
        LAYOUT.broadcastColumns
    )
end

local function broadcastPlayerTimedConsumables()
    local columnData = scanPlayerTimedConsumables()

    broadcast:SendTimedConsumableStatuses(columnData)
end

local function scheduleReadyCheckBroadcast()
    cancelReadyCheckBroadcastTimer()

    readyCheckBroadcastTimer = C_Timer.NewTimer(
        READY_CHECK_BROADCAST_DELAY,
        function()
            readyCheckBroadcastTimer = nil

            if not DisplayContext.IsActive(
                displayContext,
                Reason.READY_CHECK
            ) then
                return
            end

            local columnData = scanPlayerTimedConsumables()

            broadcast:SendReadyCheckStatuses(columnData)

            if frame:IsShown() then
                refreshAllRowsAndTitle()
            end
        end
    )
end

local function scheduleTempWeaponEnchantRefresh()
    if readyCheckBroadcastTimer or fadeOut.isFadingOut then
        return
    end

    cancelTempWeaponEnchantTimer()

    tempWeaponEnchantTimer = C_Timer.NewTimer(0.2, function()
        tempWeaponEnchantTimer = nil
        broadcast:SendTempWeaponEnchantStatus()

        if frame:IsShown() and not fadeOut.isFadingOut then
            refreshAllRowsAndTitle()
        end
    end)
end

function frame:OnReadyCheckStarted(session)
    cancelSyntheticReadyCheck()

    local enabled = RCC.GetSetting("raidFrame_enabled")

    state.readyCheck = session
    beginReadyCheckDisplay(false)

    cancelTempWeaponEnchantTimer()
    broadcast:Reset()

    -- Broadcast even when the local raid frame is disabled so other RCC users
    -- can still see this player's consumable, durability, and temp weapon
    -- enchant status. The short delay lets every client initialize and clear
    -- its ready-check state before status messages arrive.
    scheduleReadyCheckBroadcast()

    if not enabled then
        return
    end

    Members.ScanAll(state, LAYOUT, renderContext)

    showReadyCheckDisplay(session.duration, true)
end

function frame:OnReadyCheckUpdated(session, change)
    if state.readyCheck ~= session
        or not DisplayContext.IsActive(displayContext, Reason.READY_CHECK)
        or not self:IsShown()
    then
        return
    end

    if change.rosterChanged then
        Members.ScanAll(state, LAYOUT, renderContext)
        refreshAllRowsAndTitle()
    else
        for i = 1, state.activeCount do
            if state.members[i].key == change.playerKey then
                refreshRowAndTitle(i)
                break
            end
        end
    end

    refreshReadyCheckSummary()
end

local function closeReadyCheckDisplay(self)
    if not DisplayContext.Deactivate(displayContext, Reason.READY_CHECK) then
        return
    end

    cancelHideTimer()
    cancelAddonRefreshTimer()
    cancelReadyCheckBroadcastTimer()
    cancelTempWeaponEnchantTimer()
    self.manualShow = false

    -- Finishing a ready check closes the whole visible raid-status session.
    -- Active provision reasons may be reused by their owners, but they do not
    -- inherit the frame when the ready-check display closes.
    syncDisplayEvents()
    fadeOut:Hide()
end

function frame:OnReadyCheckFinished(session)
    if state.readyCheck ~= session
        or not DisplayContext.IsActive(displayContext, Reason.READY_CHECK)
    then
        return
    end

    cancelReadyCheckBroadcastTimer()
    refreshReadyCheckSummary()

    if not self:IsShown() then
        closeReadyCheckDisplay(self)

        return
    end

    if self.manualShow then
        return
    end

    cancelHideTimer()

    if not RCC.GetSetting("raidFrame_minShow") then
        if not InCombatLockdown() then
            closeReadyCheckDisplay(self)
        end

        return
    end

    local minShowTime = RCC.GetSetting("raidFrame_minShowTime")
    local elapsed = GetTime() - showStartTime
    local delay = max(minShowTime - elapsed, 0)

    hideTimer = C_Timer.NewTimer(delay, function()
        hideTimer = nil

        if not InCombatLockdown()
            and DisplayContext.IsActive(
                displayContext,
                Reason.READY_CHECK
            )
        then
            closeReadyCheckDisplay(self)
        end
    end)
end

function frame:ShowProvisionTracking()
    return showProvisionDisplay()
end

function frame:OpenProvisionTracking()
    return showProvisionDisplay(true)
end

local function refreshShownDisplay(self, rescanMembers)
    -- READY_CHECK has already been removed while its last visual state fades.
    -- Do not let passive provision refreshes rebuild the still-visible frame.
    if fadeOut.isFadingOut then
        return false
    end

    if not self:IsShown() then
        configureDisplay()

        return false
    end

    fadeOut:Cancel()
    configureDisplay()

    if rescanMembers then
        Members.ScanAll(state, LAYOUT, renderContext)
    end

    if DisplayContext.IsActive(displayContext, Reason.READY_CHECK) then
        refreshAllRowsAndTitle()

        return true
    end

    if canShowProvisionOnly() then
        return showProvisionDisplayFromState()
    end

    self:Hide()

    return false
end

function frame:ActivateDisplayReason(reason, sourceKey, allowAutoShow)
    if InCombatLockdown() then
        return false
    end

    local shouldAutoOpen = DisplayContext.ShouldAutoOpen(
        displayContext,
        reason,
        sourceKey
    )

    DisplayContext.Activate(displayContext, reason, sourceKey)

    if self:IsShown() then
        local refreshed = refreshShownDisplay(self, true)

        if shouldAutoOpen then
            DisplayContext.MarkAutoOpened(
                displayContext,
                reason,
                sourceKey
            )
        end

        return refreshed
    end

    if DisplayContext.IsActive(displayContext, Reason.READY_CHECK) then
        if shouldAutoOpen then
            DisplayContext.MarkAutoOpened(
                displayContext,
                reason,
                sourceKey
            )
        end

        syncDisplayEvents()

        return false
    end

    if allowAutoShow and shouldAutoOpen and showProvisionDisplay() then
        DisplayContext.MarkAutoOpened(
            displayContext,
            reason,
            sourceKey
        )

        return true
    end

    configureDisplay()

    return false
end

function frame:DeactivateDisplayReason(reason, sourceKey)
    if not DisplayContext.Deactivate(displayContext, reason, sourceKey) then
        return false
    end

    syncProvisionReasons()

    if self:IsShown() then
        refreshShownDisplay(self, true)
    else
        configureDisplay()
    end

    return true
end

function frame:ResetDisplayReason(reason)
    DisplayContext.ResetReason(displayContext, reason)

    if InCombatLockdown() then
        return
    end

    syncProvisionReasons()

    if self:IsShown() then
        refreshShownDisplay(self, true)
    else
        configureDisplay()
    end
end

function frame:GetDisplayContext()
    return displayContext
end

function frame:GetColumnDefinitions()
    return Columns.GetDefinitions(LAYOUT)
end

function frame:RefreshContextualVisibility()
    if InCombatLockdown() then
        return false
    end

    syncProvisionReasons()

    return refreshShownDisplay(self, true)
end

function frame:ApplyProfile()
    controls:RestorePosition(true)
    controls:SyncScale()

    if not RCC.GetSetting("raidFrame_enabled") then
        self:Hide()

        return
    end

    self:RefreshContextualVisibility()

    if state.readyCheck and not state.readyCheck.inProgress then
        self:OnReadyCheckFinished(state.readyCheck)
    end
end

function frame:RefreshProvisionTracking(allowAutoShow)
    if InCombatLockdown() then
        return false
    end

    syncProvisionReasons()

    if self:IsShown() then
        return refreshShownDisplay(self, true)
    end

    if allowAutoShow then
        return showProvisionDisplay()
    end

    configureDisplay()

    return false
end

function frame:HideProvisionTracking()
    if not DisplayContext.IsActive(displayContext, Reason.READY_CHECK) then
        self:Hide()
    elseif self:IsShown() then
        refreshAllRowsAndTitle()
    end
end

function frame:ShowCauldronTracking()
    return self:ShowProvisionTracking()
end

function frame:RefreshCauldronTracking(allowAutoShow)
    return self:RefreshProvisionTracking(allowAutoShow)
end

function frame:HideCauldronTracking()
    self:HideProvisionTracking()
end

function frame:OnCombat()
    cancelSyntheticReadyCheck()

    DisplayContext.Clear(displayContext)
    unregisterReadyCheckDataEvents()
    cancelHideTimer()
    cancelAddonRefreshTimer()
    cancelReadyCheckBroadcastTimer()
    cancelTempWeaponEnchantTimer()
    fadeOut:Cancel()
    self:Hide()
    state.readyCheck = nil
end

function frame:OnUnitAura(unit)
    -- Synthetic rows are not live unit tokens; only the player row can update.
    if Test.active and unit ~= "player" then
        return
    end

    local index = Members.RefreshFromUnit(state, unit, LAYOUT, renderContext)

    if not index then
        return
    end

    refreshRowAndTitle(index)
end

function frame:OnHide()
    cancelSyntheticReadyCheck()

    DisplayContext.Deactivate(displayContext, Reason.READY_CHECK)
    unregisterReadyCheckDataEvents()
    cancelHideTimer()
    cancelAddonRefreshTimer()
    cancelReadyCheckBroadcastTimer()
    cancelTempWeaponEnchantTimer()
    fadeOut:Cancel()
    titleBar:StopProgress()
    self.manualShow = false
    state.readyCheck = nil
end

Test:Attach({
    frame            = frame,
    state            = state,
    layout           = LAYOUT,
    context          = renderContext,
    broadcast        = broadcast,
    beginDisplay     = beginReadyCheckDisplay,
    showDisplay      = showReadyCheckDisplay,
    beginCauldron    = beginProvisionDisplay,
    showCauldron     = showProvisionDisplayFromState,
    syncProvision    = syncProvisionReasons,
})

--------------------------------------------------------------------------------
--- Shared ready-check subscriptions and display-only event wiring
--------------------------------------------------------------------------------

ReadyChecks.Subscribe({
    OnStarted = function(session)
        frame:OnReadyCheckStarted(session)
    end,
    OnUpdated = function(session, change)
        frame:OnReadyCheckUpdated(session, change)
    end,
    OnFinished = function(session)
        frame:OnReadyCheckFinished(session)
    end,
    OnCancelled = function(session)
        if state.readyCheck == session then
            closeReadyCheckDisplay(frame)
        end
    end,
})

local function onPlayerRegenDisabled(self)
    self:OnCombat()
end

local function onUpdateInventoryDurability()
    if not readyCheckBroadcastTimer then
        broadcast:SendDurability()
    end

    refreshAllRowsAndTitle()
end

local function onUnitInventoryChanged(self, unit)
    if unit ~= "player" then
        return
    end

    scheduleTempWeaponEnchantRefresh()
end

local function onWeaponEnchantChanged()
    scheduleTempWeaponEnchantRefresh()
end

local function onUnitAura(self, unit)
    if issecretvalue(unit) then
        return
    end

    if unit == "player" and not readyCheckBroadcastTimer then
        broadcastPlayerTimedConsumables()
    end

    self:OnUnitAura(unit)
end

local function onChatMsgAddon(_self, prefix, message, channel, sender)
    if broadcast:HandleAddonMessage(prefix, message, channel, sender) then
        scheduleAddonRefresh()
    end
end

local EVENT_HANDLERS = {
    CHAT_MSG_ADDON              = onChatMsgAddon,
    PLAYER_REGEN_DISABLED       = onPlayerRegenDisabled,
    UNIT_AURA                   = onUnitAura,
    UNIT_INVENTORY_CHANGED      = onUnitInventoryChanged,
    UPDATE_INVENTORY_DURABILITY = onUpdateInventoryDurability,
    WEAPON_ENCHANT_CHANGED      = onWeaponEnchantChanged,
    WEAPON_SLOT_CHANGED         = onWeaponEnchantChanged,
}

frame:SetScript("OnEvent", function(self, event, ...)
    local handler = EVENT_HANDLERS[event]

    if handler then
        handler(self, ...)
    end
end)

frame:SetScript("OnHide", function(self)
    self:OnHide()
end)

frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("CHAT_MSG_ADDON")
