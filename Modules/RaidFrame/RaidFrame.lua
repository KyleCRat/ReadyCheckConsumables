local _, RCC = ...

local Broadcast       = RCC.RaidFrameBroadcast
local Columns         = RCC.RaidFrameColumns
local Controls        = RCC.RaidFrameControls
local FrameAnimations = RCC.FrameAnimations
local Members         = RCC.RaidFrameMembers
local ReadyCheck      = RCC.RaidFrameReadyCheck
local Rows            = RCC.RaidFrameRows
local TitleBar        = RCC.RaidFrameTitleBar

local GetTime = GetTime

--------------------------------------------------------------------------------
--- Constants
--------------------------------------------------------------------------------

local ADDON_REFRESH_DELAY = 0.25
local FADE_OUT_DURATION   = 0.5

local LAYOUT = Columns.CreateLayout()

local broadcast      = Broadcast.Create()
local durabilityData = broadcast:GetDurabilityData()
local oilData        = broadcast:GetOilData()

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
        oilData        = oilData,
        durabilityData = durabilityData,
    },
    rules = Columns.RULES,
}

--------------------------------------------------------------------------------
--- Ready check summary helpers
--------------------------------------------------------------------------------

local function updateTitleCount()
    local readyCount = 0

    for unit in pairs(state.unitToIndex) do
        local status = state.rcStatus[unit]

        if status == ReadyCheck.READY or status == ReadyCheck.NOT_READY then
            readyCount = readyCount + 1
        end
    end

    titleBar:SetReadyCount(readyCount, state.activeCount)

    return readyCount
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

local function showFinishedSummary()
    local notReadyCount, afkCount = getFinishedCounts()

    titleBar:ShowFinishedSummary(notReadyCount, afkCount)

    if notReadyCount == 0
        and afkCount == 0
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
    Rows.RefreshRow(frame.rows[index], state.members[index], LAYOUT, renderContext)
    titleBar:RefreshFromMembers(
        state.members,
        state.activeCount,
        LAYOUT,
        renderContext
    )
end

local function refreshAllRowsAndTitle()
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

function frame:OnReadyCheck(initiatorUnit, timeToHide)
    cancelHideTimer()
    cancelAddonRefreshTimer()
    fadeOut:Cancel()
    state.readyAnnounced = false
    wipe(state.rcStatus)
    broadcast:Reset()

    -- Broadcast even when the local raid frame is disabled so other RCC users
    -- can still see this player's durability and weapon oil status.
    broadcast:SendDurability()
    broadcast:SendOilStatus()

    if not RCC.GetSetting("raidFrame_enabled") then
        return
    end

    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("READY_CHECK_CONFIRM")
    self:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    self:RegisterEvent("UNIT_INVENTORY_CHANGED")

    self.manualShow = (timeToHide == 0)
    showStartTime = GetTime()

    Members.ScanAll(state, LAYOUT, renderContext)

    -- The initiator never receives READY_CHECK_CONFIRM for themselves;
    -- auto-mark them as ready so their row shows a check immediately.
    if initiatorUnit then
        for unit in pairs(state.unitToIndex) do
            if UnitIsUnit(unit, initiatorUnit) then
                state.rcStatus[unit] = ReadyCheck.READY
                break
            end
        end
    end

    refreshAllRowsAndTitle()
    updateTitleCount()

    if not self.manualShow then
        titleBar:StartProgress(timeToHide or 30)
    else
        titleBar:StopProgress()
    end

    controls:RestorePosition()
    controls:SyncScale()
    self:Show()
end

local TEST_DURATION = RCC.raidFrameTest.TEST_DURATION

function frame:OnTestReadyCheck(permanent)
    cancelHideTimer()
    cancelAddonRefreshTimer()
    fadeOut:Cancel()

    self.manualShow = permanent or false
    showStartTime = GetTime()

    Members.PopulateTestData(state, LAYOUT, renderContext, broadcast)
    broadcast:SendDurability()
    broadcast:SendOilStatus()

    refreshAllRowsAndTitle()
    updateTitleCount()

    titleBar:StartProgress(TEST_DURATION)

    controls:RestorePosition()
    controls:SyncScale()
    self:Show()

    for unit in pairs(state.unitToIndex) do
        if unit ~= "player" then
            local roll = math.random()

            if roll > 0.25 then
                local delay = math.random(1, TEST_DURATION)
                local ready = roll > 0.5

                C_Timer.After(delay, function()
                    if not self:IsShown() then
                        return
                    end

                    self:OnReadyCheckConfirm(unit, ready)
                end)
            end
        end
    end

    if not permanent then
        C_Timer.After(TEST_DURATION, function()
            if not self:IsShown() then
                return
            end

            self:OnReadyCheckFinished()
        end)
    end
end

function frame:OnReadyCheckConfirm(unit, ready)
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

function frame:OnCombat()
    cancelHideTimer()
    cancelAddonRefreshTimer()
    fadeOut:Cancel()
    self:Hide()
end

function frame:OnUnitAura(unit)
    local index = Members.RefreshFromUnit(state, unit, LAYOUT, renderContext)

    if not index then
        return
    end

    refreshRowAndTitle(index)
end

function frame:OnHide()
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("READY_CHECK_CONFIRM")
    self:UnregisterEvent("UPDATE_INVENTORY_DURABILITY")
    self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
    cancelHideTimer()
    fadeOut:Cancel()
    titleBar:StopProgress()
    self.manualShow = false
end

--------------------------------------------------------------------------------
--- Event wiring
--------------------------------------------------------------------------------

frame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
    if event == "READY_CHECK" then
        if InCombatLockdown() then
            return
        end

        local initiatorUnit, duration = arg1, arg2
        self:OnReadyCheck(initiatorUnit, duration)

        return
    end

    if event == "READY_CHECK_CONFIRM" then
        local unit, isReady = arg1, arg2
        self:OnReadyCheckConfirm(unit, isReady)

        return
    end

    if event == "READY_CHECK_FINISHED" then
        self:OnReadyCheckFinished()

        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        self:OnCombat()

        return
    end

    if event == "UPDATE_INVENTORY_DURABILITY" then
        broadcast:SendDurability()
        refreshAllRowsAndTitle()

        return
    end

    if event == "UNIT_INVENTORY_CHANGED" then
        if arg1 == "player" then
            C_Timer.After(0.2, function()
                broadcast:SendOilStatus()

                if self:IsShown() then
                    refreshAllRowsAndTitle()
                end
            end)
        end

        return
    end

    if event == "UNIT_AURA" then
        local unit = arg1
        self:OnUnitAura(unit)

        return
    end

    if event == "CHAT_MSG_ADDON" then
        if broadcast:HandleAddonMessage(arg1, arg2, arg4) then
            scheduleAddonRefresh()
        end

        return
    end

    if event == "ADDON_LOADED" then
        local addonName = arg1

        if addonName == "ReadyCheckConsumables" then
            ReadyCheckConsumablesDB = ReadyCheckConsumablesDB or {}
            self:UnregisterEvent("ADDON_LOADED")
        end

        return
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
