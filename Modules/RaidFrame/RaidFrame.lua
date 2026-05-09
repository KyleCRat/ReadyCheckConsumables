local _, RCC = ...

local UI = RCC.UI
local Broadcast = RCC.RaidFrameBroadcast
local Columns = RCC.RaidFrameColumns
local Members = RCC.RaidFrameMembers
local Rows = RCC.RaidFrameRows
local TitleBar = RCC.RaidFrameTitleBar

local GetTime            = GetTime
local floor              = floor

--------------------------------------------------------------------------------
--- Constants
--------------------------------------------------------------------------------

local ROW_HEIGHT           = 30
local TITLE_HEIGHT         = 28
local V_PAD                = 0
local MAX_ROWS             = 40
local EXPIRE_WARN_SECONDS  = 600 -- 10 minutes
local NO_DURATION          = 0
local ADDON_REFRESH_DELAY  = 0.25
local FADE_OUT_DURATION    = 0.5
local DURABILITY_THRESHOLD = 50
local MISSING_BG           = { r = 0,   g = 0,   b = 0 }
local FONT_SIZE_NAME       = 16
local FONT_SIZE_TIME       = 14
local SCALE_MIN            = 50
local SCALE_MAX            = 150
local SCALE_STEP           = 5
local SCALE_BUTTON_WIDTH   = 86

local FONT = UI.FONT

local RC_PENDING = 0
local RC_READY   = 1
local RC_NOT     = 2

local RC_TEXTURES = {
    [RC_PENDING] = "Interface\\RaidFrame\\ReadyCheck-Waiting",
    [RC_READY]   = "Interface\\RaidFrame\\ReadyCheck-Ready",
    [RC_NOT]     = "Interface\\RaidFrame\\ReadyCheck-NotReady",
}

local LAYOUT = Columns.CreateLayout()

local broadcast = Broadcast.Create()
local durabilityData = broadcast:GetDurabilityData()
local oilData = broadcast:GetOilData()

--------------------------------------------------------------------------------
--- Frame creation
--------------------------------------------------------------------------------

local frame = CreateFrame("Frame", "RCRaidFrame", UIParent, "BackdropTemplate")
RCC.raidFrame = frame

frame:SetSize(LAYOUT.frameWidth, ROW_HEIGHT * 5 + LAYOUT.framePad * 2)
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

frame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

--------------------------------------------------------------------------------
--- Scale Popup Button
--------------------------------------------------------------------------------

frame.scaleButton = UI.CreateControlButton(frame, SCALE_BUTTON_WIDTH, 20, "")
frame.scaleButton:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 1, -3)

local scalePopup = UI.CreatePopupSlider(frame.scaleButton, {
    minValue = SCALE_MIN,
    maxValue = SCALE_MAX,
    step = SCALE_STEP,
    label = "Scale",

    formatValue = function(value)
        return value .. "%"
    end,

    onValueChanged = function(value)
        frame.scaleButton.text:SetText("Scale: " .. value .. "%")
        frame:SetScale(value / 100)

        if ReadyCheckConsumablesDB then
            ReadyCheckConsumablesDB.raidFrame_scale = value / 100
        end
    end,
})

local function syncScaleControl()
    local scale = ReadyCheckConsumablesDB
        and ReadyCheckConsumablesDB.raidFrame_scale
        or 1
    scalePopup:SetValue(floor(scale * 100 + 0.5))
end

frame.SyncScaleControl = syncScaleControl
syncScaleControl()

--------------------------------------------------------------------------------
--- Close Button
--------------------------------------------------------------------------------

frame.close = UI.CreateControlButton(
    frame, 0, 20, CLOSE or "x", "SecureHandlerClickTemplate"
)
frame.close:SetPoint("TOPLEFT", frame.scaleButton, "TOPRIGHT", 3, 0)
frame.close:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -1, -3)

frame.close:SetFrameRef("CLLRaidFrame", frame)
frame.close:SetAttribute("_onclick", [[
    self:GetFrameRef("CLLRaidFrame"):Hide()
]])

--------------------------------------------------------------------------------
--- Dragging and Positioning
--------------------------------------------------------------------------------

local function savePosition(self)
    self:StopMovingOrSizing()

    if not ReadyCheckConsumablesDB then
        return
    end

    local point, _, relPoint, x, y = self:GetPoint(1)
    ReadyCheckConsumablesDB.raidFramePos = {
        point    = point,
        relPoint = relPoint,
        x        = x,
        y        = y,
    }
end

frame:SetScript("OnDragStop", savePosition)

local positionRestored = false

local function restorePosition()
    if positionRestored then
        return
    end

    positionRestored = true

    if not ReadyCheckConsumablesDB then
        return
    end

    local pos = ReadyCheckConsumablesDB.raidFramePos

    if not pos then
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
end

--------------------------------------------------------------------------------
--- Title Bar
--------------------------------------------------------------------------------

local titleBar = TitleBar.Create(frame, LAYOUT, {
    titleHeight    = TITLE_HEIGHT,
    font           = FONT,
    fontSizeName   = FONT_SIZE_NAME,
    pendingTexture = RC_TEXTURES[RC_PENDING],
})

--------------------------------------------------------------------------------
--- Row creation (pre-allocate 40 rows)
--------------------------------------------------------------------------------

frame.rows = Rows.Create(frame, LAYOUT, {
    maxRows          = MAX_ROWS,
    titleHeight      = TITLE_HEIGHT,
    rowHeight        = ROW_HEIGHT,
    vPad             = V_PAD,
    font             = FONT,
    fontSizeName     = FONT_SIZE_NAME,
    fontSizeTime     = FONT_SIZE_TIME,
    missingBg        = MISSING_BG,
    rcPendingTexture = RC_TEXTURES[RC_PENDING],
})

--------------------------------------------------------------------------------
--- Member data storage
--------------------------------------------------------------------------------

local state = {
    members        = {},  -- [i] = { name, unit, class, online, isDead, columnData }
    unitToIndex    = {},  -- [unit] = i
    rcStatus       = {},  -- [unit] = RC_PENDING | RC_READY | RC_NOT
    activeCount    = 0,
    readyAnnounced = false,
}

local renderContext = {
    state      = state,
    readyCheck = {
        pending  = RC_PENDING,
        ready    = RC_READY,
        notReady = RC_NOT,
        textures = RC_TEXTURES,
    },
    shared = {
        oilData        = oilData,
        durabilityData = durabilityData,
    },
    rules = {
        expireWarnSeconds   = EXPIRE_WARN_SECONDS,
        noDuration          = NO_DURATION,
        durabilityThreshold = DURABILITY_THRESHOLD,
    },
}

--------------------------------------------------------------------------------
--- Title bar helpers
--------------------------------------------------------------------------------

local function refreshTitleBar()
    local columns = LAYOUT.columns
    local columnStates = {}

    for columnIndex = 1, #columns do
        local column = columns[columnIndex]
        local anyBad = false

        for memberIndex = 1, state.activeCount do
            local member = state.members[memberIndex]

            if member
                and member.online
                and column.IsBad(member, renderContext, column)
            then
                anyBad = true
                break
            end
        end

        columnStates[columnIndex] = anyBad
    end

    titleBar:RefreshColumns(
        columnStates,
        RC_TEXTURES[RC_READY],
        RC_TEXTURES[RC_NOT]
    )
end

local function updateTitleCount()
    local readyCount = 0

    for unit in pairs(state.unitToIndex) do
        local status = state.rcStatus[unit]

        if status == RC_READY or status == RC_NOT then
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

        if status == RC_PENDING then
            afkCount = afkCount + 1
        elseif status == RC_NOT then
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

local function refreshRow(index)
    local row = frame.rows[index]

    if not row then
        return
    end

    Columns.SyncExternalData(state.members[index], LAYOUT, renderContext)
    Rows.ApplyData(row, state.members[index], LAYOUT, renderContext)
    refreshTitleBar()
end

local function refreshAllRows()
    for i = 1, state.activeCount do
        Columns.SyncExternalData(state.members[i], LAYOUT, renderContext)
        Rows.ApplyData(frame.rows[i], state.members[i], LAYOUT, renderContext)
    end

    for i = state.activeCount + 1, MAX_ROWS do
        frame.rows[i]:Hide()
    end

    local height = LAYOUT.framePad * 2
        + TITLE_HEIGHT + LAYOUT.framePad
        + state.activeCount * ROW_HEIGHT
        + (state.activeCount > 1 and (state.activeCount - 1) * V_PAD or 0)

    frame:SetHeight(height)
    refreshTitleBar()
end

--------------------------------------------------------------------------------
--- Ready check lifecycle
--------------------------------------------------------------------------------

local hideTimer
local addonRefreshTimer
local fadeOutGroup
local showStartTime = 0

local function cancelFadeOut()
    if fadeOutGroup and fadeOutGroup:IsPlaying() then
        fadeOutGroup:Stop()
    end

    frame.isFadingOut = false
    frame:SetAlpha(1)
end

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
            refreshAllRows()
        end
    end)
end

fadeOutGroup = frame:CreateAnimationGroup()
local fadeOutAlpha = fadeOutGroup:CreateAnimation("Alpha")
fadeOutAlpha:SetFromAlpha(1)
fadeOutAlpha:SetToAlpha(0)
fadeOutAlpha:SetDuration(FADE_OUT_DURATION)
fadeOutGroup:SetScript("OnFinished", function()
    frame.isFadingOut = false
    frame:Hide()
    frame:SetAlpha(1)
end)

function frame:HideWithFade()
    if not self:IsShown() then
        return
    end

    if InCombatLockdown() then
        self:Hide()

        return
    end

    if self.isFadingOut then
        return
    end

    self.isFadingOut = true
    self:SetAlpha(1)
    fadeOutGroup:Play()
end

local function cancelHideTimer()
    if hideTimer then
        hideTimer:Cancel()
        hideTimer = nil
    end
end

local function startProgressBar(duration)
    local barWidth = LAYOUT.frameWidth - LAYOUT.framePad * 2

    titleBar:StartProgress(duration, barWidth)
end

function frame:OnReadyCheck(initiatorUnit, timeToHide)
    cancelHideTimer()
    cancelAddonRefreshTimer()
    cancelFadeOut()
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
                state.rcStatus[unit] = RC_READY
                break
            end
        end
    end

    refreshAllRows()
    updateTitleCount()

    if not self.manualShow then
        startProgressBar(timeToHide or 30)
    else
        titleBar:StopProgress()
    end

    restorePosition()
    self:SyncScaleControl()
    self:Show()
end

local TEST_DURATION = RCC.raidFrameTest.TEST_DURATION

function frame:OnTestReadyCheck(permanent)
    cancelHideTimer()
    cancelAddonRefreshTimer()
    cancelFadeOut()

    self.manualShow = permanent or false
    showStartTime = GetTime()

    Members.PopulateTestData(state, LAYOUT, renderContext, broadcast)
    broadcast:SendDurability()
    broadcast:SendOilStatus()

    refreshAllRows()
    updateTitleCount()

    startProgressBar(TEST_DURATION)

    restorePosition()
    self:SyncScaleControl()
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

    state.rcStatus[unit] = ready and RC_READY or RC_NOT
    refreshRow(index)

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
            self:HideWithFade()
        end

        return
    end

    local minShowTime = RCC.GetSetting("raidFrame_minShowTime")
    local elapsed = GetTime() - showStartTime
    local delay = max(minShowTime - elapsed, 0)

    hideTimer = C_Timer.NewTimer(delay, function()
        if not InCombatLockdown() then
            frame:HideWithFade()
        end
    end)
end

function frame:OnCombat()
    cancelHideTimer()
    cancelAddonRefreshTimer()
    cancelFadeOut()
    self:Hide()
end

function frame:OnUnitAura(unit)
    local index = Members.RefreshFromUnit(state, unit, LAYOUT, renderContext)

    if not index then
        return
    end

    refreshRow(index)
end

function frame:OnHide()
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("READY_CHECK_CONFIRM")
    self:UnregisterEvent("UPDATE_INVENTORY_DURABILITY")
    self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
    cancelHideTimer()
    cancelFadeOut()
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
        refreshAllRows()

        return
    end

    if event == "UNIT_INVENTORY_CHANGED" then
        if arg1 == "player" then
            C_Timer.After(0.2, function()
                broadcast:SendOilStatus()

                if self:IsShown() then
                    refreshAllRows()
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
