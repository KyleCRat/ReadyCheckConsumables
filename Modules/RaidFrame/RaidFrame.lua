local _, RCC = ...

local Broadcast       = RCC.RaidFrameBroadcast
local Cauldron        = RCC.RaidFrameCauldron
local Columns         = RCC.RaidFrameColumns
local Controls        = RCC.RaidFrameControls
local DisplayContext  = RCC.DisplayContext
local Feast           = RCC.RaidFrameFeast
local FrameAnimations = RCC.FrameAnimations
local Members         = RCC.RaidFrameMembers
local ReadyCheck      = RCC.RaidFrameReadyCheck
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

local state = {
    members        = {},  -- [i] = { name, unit, class, online, isDead, columnData }
    unitToIndex    = {},  -- [unit] = i
    rcStatus       = {},  -- [unit] = ReadyCheck status
    activeCount    = 0,
    readyAnnounced = false,
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

local function registerReadyCheckEvents()
    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("READY_CHECK_CONFIRM")
    frame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    frame:RegisterEvent("WEAPON_ENCHANT_CHANGED")
    frame:RegisterEvent("WEAPON_SLOT_CHANGED")
end

local function unregisterReadyCheckEvents()
    frame:UnregisterEvent("UNIT_AURA")
    frame:UnregisterEvent("READY_CHECK_CONFIRM")
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
        registerReadyCheckEvents()

        return
    end

    unregisterReadyCheckEvents()

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
--- Ready check summary helpers
--------------------------------------------------------------------------------

local function updateTitleCount()
    local respondedCount = 0

    for unit in pairs(state.unitToIndex) do
        local status = state.rcStatus[unit]

        if status == ReadyCheck.READY or status == ReadyCheck.NOT_READY then
            respondedCount = respondedCount + 1
        end
    end

    titleBar:SetRespondedCount(respondedCount, state.activeCount)

    return respondedCount
end

local function getFinishedCounts()
    local notReadyCount = 0
    local afkCount      = 0

    for i = 1, state.activeCount do
        local member = state.members[i]

        if not member then break end

        local status = state.rcStatus[member.unit]

        if status == ReadyCheck.PENDING then
            afkCount = afkCount + 1
        elseif status == ReadyCheck.NOT_READY then
            notReadyCount = notReadyCount + 1
        end
    end

    return notReadyCount, afkCount
end

local function allActiveMembersReady()
    if state.activeCount == 0 then
        return false
    end

    for i = 1, state.activeCount do
        local member = state.members[i]

        if not member
            or state.rcStatus[member.unit] ~= ReadyCheck.READY
        then
            return false
        end
    end

    return true
end

local function showFinishedSummary()
    local notReadyCount, afkCount = getFinishedCounts()

    titleBar:ShowFinishedSummary(notReadyCount, afkCount)

    if allActiveMembersReady()
        and not state.readyAnnounced
        and GetNumGroupMembers() > state.activeCount
    then
        state.readyAnnounced = true

        RCC.AnnounceAllReady()
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
    if addonRefreshTimer or not frame:IsShown() then
        return
    end

    addonRefreshTimer = C_Timer.NewTimer(ADDON_REFRESH_DELAY, function()
        addonRefreshTimer = nil

        if frame:IsShown() then
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
    state.readyAnnounced = false
    DisplayContext.Activate(displayContext, Reason.READY_CHECK)
    syncProvisionReasons()
    configureDisplay()

    frame.manualShow = manualShow or false
    showStartTime = GetTime()
end

local function showReadyCheckDisplay(duration, showProgress)
    refreshAllRowsAndTitle()
    updateTitleCount()

    if showProgress then
        titleBar:StartProgress(duration or 30)
    else
        titleBar:StopProgress()
    end

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
    wipe(state.rcStatus)
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
    if readyCheckBroadcastTimer then
        return
    end

    cancelTempWeaponEnchantTimer()

    tempWeaponEnchantTimer = C_Timer.NewTimer(0.2, function()
        tempWeaponEnchantTimer = nil
        broadcast:SendTempWeaponEnchantStatus()

        if frame:IsShown() then
            refreshAllRowsAndTitle()
        end
    end)
end

function frame:OnReadyCheck(initiatorUnit, timeToHide)
    cancelSyntheticReadyCheck()

    local enabled = RCC.GetSetting("raidFrame_enabled")

    beginReadyCheckDisplay(timeToHide == 0)

    wipe(state.rcStatus)
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

    -- The initiator never receives READY_CHECK_CONFIRM for themselves;
    -- auto-mark them as ready so their row shows a check immediately.
    if not issecretvalue(initiatorUnit) and initiatorUnit then
        for unit in pairs(state.unitToIndex) do
            if RCC.F.UnitIsUnitSafe(unit, initiatorUnit) then
                state.rcStatus[unit] = ReadyCheck.READY
                break
            end
        end
    end

    showReadyCheckDisplay(timeToHide or 30, not self.manualShow)
end

function frame:OnReadyCheckConfirm(unit, ready)
    if not DisplayContext.IsActive(displayContext, Reason.READY_CHECK) then
        return
    end

    if issecretvalue(unit) or issecretvalue(ready) then return end

    local index = state.unitToIndex[unit]

    if not index then
        return
    end

    state.rcStatus[unit] = ready and ReadyCheck.READY or ReadyCheck.NOT_READY
    refreshRowAndTitle(index)

    local responded = updateTitleCount()

    if responded >= state.activeCount then
        titleBar:StopProgress()
        showFinishedSummary()
    end
end

local function closeReadyCheckDisplay(self)
    if not DisplayContext.Deactivate(displayContext, Reason.READY_CHECK) then
        return
    end

    cancelReadyCheckBroadcastTimer()
    self.manualShow = false

    -- Finishing a ready check closes the whole visible raid-status session.
    -- Active provision reasons may be reused by their owners, but they do not
    -- inherit the frame when the ready-check display closes.
    syncDisplayEvents()
    fadeOut:Hide()
end

function frame:OnReadyCheckFinished()
    if not DisplayContext.IsActive(displayContext, Reason.READY_CHECK) then
        return
    end

    cancelReadyCheckBroadcastTimer()
    titleBar:StopProgress()
    showFinishedSummary()

    if not self:IsShown() then
        cancelTempWeaponEnchantTimer()
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
    unregisterReadyCheckEvents()
    cancelHideTimer()
    cancelAddonRefreshTimer()
    cancelReadyCheckBroadcastTimer()
    cancelTempWeaponEnchantTimer()
    fadeOut:Cancel()
    self:Hide()
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
    unregisterReadyCheckEvents()
    cancelHideTimer()
    cancelAddonRefreshTimer()
    cancelReadyCheckBroadcastTimer()
    cancelTempWeaponEnchantTimer()
    fadeOut:Cancel()
    titleBar:StopProgress()
    self.manualShow = false
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
--- Event wiring
--------------------------------------------------------------------------------

local function onReadyCheck(self, initiatorUnit, duration)
    if InCombatLockdown() then
        return
    end

    self:OnReadyCheck(initiatorUnit, duration)
end

local function onReadyCheckConfirm(self, unit, isReady)
    self:OnReadyCheckConfirm(unit, isReady)
end

local function onReadyCheckFinished(self)
    self:OnReadyCheckFinished()
end

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

local function onAddonLoaded(self, addonName)
    if addonName ~= "ReadyCheckConsumables" then
        return
    end

    ReadyCheckConsumablesDB = ReadyCheckConsumablesDB or {}
    self:UnregisterEvent("ADDON_LOADED")
end

local EVENT_HANDLERS = {
    ADDON_LOADED                = onAddonLoaded,
    CHAT_MSG_ADDON              = onChatMsgAddon,
    PLAYER_REGEN_DISABLED       = onPlayerRegenDisabled,
    READY_CHECK                 = onReadyCheck,
    READY_CHECK_CONFIRM         = onReadyCheckConfirm,
    READY_CHECK_FINISHED        = onReadyCheckFinished,
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

frame:RegisterEvent("READY_CHECK")
frame:RegisterEvent("READY_CHECK_FINISHED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("ADDON_LOADED")
