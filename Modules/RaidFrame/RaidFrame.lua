local _, RCC = ...

local Broadcast       = RCC.RaidFrameBroadcast
local Cauldron        = RCC.RaidFrameCauldron
local Columns         = RCC.RaidFrameColumns
local Controls        = RCC.RaidFrameControls
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

local ADDON_REFRESH_DELAY = 0.25
local FADE_OUT_DURATION   = 0.5

local DISPLAY_MODE = {
    READY_CHECK = "readyCheck",
    CAULDRON    = "cauldron",
}

local LAYOUT = Columns.CreateLayout()

local broadcast             = Broadcast.Create()
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
    shared = {
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

local function setDisplayMode(mode, options)
    if mode ~= DISPLAY_MODE.READY_CHECK then
        unregisterReadyCheckEvents()
    end

    if options and options.includeCauldrons ~= nil then
        frame.includeCauldronColumns = options.includeCauldrons
    elseif frame.includeCauldronColumns == nil then
        frame.includeCauldronColumns = true
    end

    frame.displayMode = mode
    Columns.ConfigureLayout(LAYOUT, mode, {
        includeCauldrons = frame.includeCauldronColumns,
    })
    frame:SetWidth(LAYOUT.frameWidth)
    titleBar:ApplyLayout(LAYOUT)
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

        if RCC.AnnounceAllReady then
            RCC.AnnounceAllReady()
        end
    end
end

local function refreshRowAndTitle(index)
    setDisplayMode(frame.displayMode or DISPLAY_MODE.READY_CHECK)
    Rows.RefreshRow(frame.rows[index], state.members[index], LAYOUT, renderContext)
    titleBar:RefreshFromMembers(
        state.members,
        state.activeCount,
        LAYOUT,
        renderContext
    )
end

local function refreshAllRowsAndTitle()
    setDisplayMode(frame.displayMode or DISPLAY_MODE.READY_CHECK)
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
    if RCC.ReadyCheckTest then
        RCC.ReadyCheckTest:Cancel()
    elseif Test then
        Test:Cancel()
    end
end

local function beginReadyCheckDisplay(manualShow, options)
    cancelHideTimer()
    cancelAddonRefreshTimer()
    fadeOut:Cancel()
    state.readyAnnounced = false
    setDisplayMode(DISPLAY_MODE.READY_CHECK, options)
    registerReadyCheckEvents()

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

local function canShowCauldronOnly()
    return Cauldron
        and Cauldron.IsEnabled()
        and Cauldron.HasActiveCauldron()
        and Cauldron.ShouldShowOutsideReadyCheck()
        and not InCombatLockdown()
end

local function beginCauldronDisplay()
    cancelHideTimer()
    cancelAddonRefreshTimer()
    fadeOut:Cancel()
    titleBar:StopProgress()
    setDisplayMode(DISPLAY_MODE.CAULDRON, { includeCauldrons = true })
    wipe(state.rcStatus)
end

local function showCauldronDisplayFromState()
    titleBar:SetHeaderText("Cauldrons")
    refreshAllRowsAndTitle()

    controls:RestorePosition()
    controls:SyncScale()
    frame:Show()

    return true
end

local function showCauldronDisplay()
    if not canShowCauldronOnly() then
        return false
    end

    beginCauldronDisplay()
    Members.ScanAll(state, LAYOUT, renderContext)

    return showCauldronDisplayFromState()
end

local function broadcastPlayerTimedConsumables()
    local columnData = Columns.ScanUnitData(
        "player",
        GetTime(),
        LAYOUT,
        renderContext
    )

    broadcast:SendTimedConsumableStatuses(columnData)
end

local function scheduleTempWeaponEnchantRefresh()
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

    if enabled then
        beginReadyCheckDisplay(timeToHide == 0, { includeCauldrons = true })
    else
        setDisplayMode(DISPLAY_MODE.READY_CHECK, { includeCauldrons = true })
        registerReadyCheckEvents()
        cancelHideTimer()
        cancelAddonRefreshTimer()
        fadeOut:Cancel()
        state.readyAnnounced = false
    end

    wipe(state.rcStatus)
    broadcast:Reset()

    -- Broadcast even when the local raid frame is disabled so other RCC users
    -- can still see this player's consumable, durability, and temp weapon
    -- enchant status.
    broadcastPlayerTimedConsumables()
    broadcast:SendDurability()
    broadcast:SendTempWeaponEnchantStatus()

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

function frame:OnReadyCheckFinished()
    titleBar:StopProgress()
    showFinishedSummary()

    if not self:IsShown() then
        unregisterReadyCheckEvents()
        cancelTempWeaponEnchantTimer()
        self.displayMode = nil
        self.includeCauldronColumns = nil

        return
    end

    if self.manualShow then
        return
    end

    cancelHideTimer()

    if not RCC.GetSetting("raidFrame_minShow") then
        if not InCombatLockdown() then
            fadeOut:Hide()
        end

        return
    end

    local minShowTime = RCC.GetSetting("raidFrame_minShowTime")
    local elapsed = GetTime() - showStartTime
    local delay = max(minShowTime - elapsed, 0)

    hideTimer = C_Timer.NewTimer(delay, function()
        if not InCombatLockdown() then
            fadeOut:Hide()
        end
    end)
end

function frame:ShowCauldronTracking()
    showCauldronDisplay()
end

function frame:RefreshCauldronTracking(allowAutoShow)
    if InCombatLockdown() then
        return
    end

    if self.displayMode == DISPLAY_MODE.READY_CHECK and self:IsShown() then
        refreshAllRowsAndTitle()

        return
    end

    if self.displayMode == DISPLAY_MODE.CAULDRON and self:IsShown() then
        if canShowCauldronOnly() then
            Members.ScanAll(state, LAYOUT, renderContext)
            showCauldronDisplayFromState()

            return
        end

        self:Hide()

        return
    end

    if allowAutoShow and showCauldronDisplay() then
        return
    end

    if self.displayMode == DISPLAY_MODE.CAULDRON then
        self:Hide()
    end
end

function frame:HideCauldronTracking()
    if self.displayMode == DISPLAY_MODE.CAULDRON then
        self:Hide()
    elseif self.displayMode == DISPLAY_MODE.READY_CHECK and self:IsShown() then
        refreshAllRowsAndTitle()
    end
end

function frame:OnCombat()
    cancelSyntheticReadyCheck()

    unregisterReadyCheckEvents()
    cancelHideTimer()
    cancelAddonRefreshTimer()
    cancelTempWeaponEnchantTimer()
    fadeOut:Cancel()
    self:Hide()
end

function frame:OnUnitAura(unit)
    -- Synthetic rows are not live unit tokens; only the player row can update.
    if Test and Test.active and unit ~= "player" then
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

    unregisterReadyCheckEvents()
    cancelHideTimer()
    cancelTempWeaponEnchantTimer()
    fadeOut:Cancel()
    titleBar:StopProgress()
    self.manualShow = false
    self.displayMode = nil
    self.includeCauldronColumns = nil
end

if Test then
    Test:Attach({
        frame            = frame,
        state            = state,
        layout           = LAYOUT,
        context          = renderContext,
        broadcast        = broadcast,
        beginDisplay     = beginReadyCheckDisplay,
        showDisplay      = showReadyCheckDisplay,
        beginCauldron    = beginCauldronDisplay,
        showCauldron     = showCauldronDisplayFromState,
    })
end

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
    broadcast:SendDurability()
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
    if unit == "player" then
        broadcastPlayerTimedConsumables()
    end

    self:OnUnitAura(unit)
end

local function onChatMsgAddon(_self, prefix, message, _channel, sender)
    if broadcast:HandleAddonMessage(prefix, message, sender) then
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
