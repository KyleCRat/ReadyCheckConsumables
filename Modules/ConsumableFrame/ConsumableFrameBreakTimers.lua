local _, RCC = ...

local Controller = RCC.ConsumableFrameController

local GetTime = GetTime
local abs = math.abs
local tonumber = tonumber
local type = type

local MAX_BREAK_SECONDS = 3600
local DUPLICATE_WINDOW = 1

-- Both boss mods translate the other's break comms, so a mixed install can
-- report the same timer through both callbacks.
local bigWigsCallbackOwner = {}
local bigWigsRegistered
local dbmRegistered
local lastBreakDuration
local lastBreakTime

local function isDuplicateBreak(duration, now)
    return lastBreakTime
        and now - lastBreakTime <= DUPLICATE_WINDOW
        and abs(duration - lastBreakDuration) <= DUPLICATE_WINDOW
end

local function openForBreakTimer(duration)
    duration = tonumber(duration)

    if not duration or duration <= 0 or duration > MAX_BREAK_SECONDS then
        return
    end

    local now = GetTime()

    if isDuplicateBreak(duration, now) then
        return
    end

    if Controller.OpenForBreakTimer() then
        lastBreakDuration = duration
        lastBreakTime = now
    end
end

local function onBigWigsStartBreak(_, _, seconds, _, _, reboot)
    if reboot then return end

    openForBreakTimer(seconds)
end

local function registerBigWigs()
    local loader = _G.BigWigsLoader

    if bigWigsRegistered
        or type(loader) ~= "table"
        or type(loader.RegisterMessage) ~= "function"
    then
        return false
    end

    loader.RegisterMessage(
        bigWigsCallbackOwner,
        "BigWigs_StartBreak",
        onBigWigsStartBreak
    )
    bigWigsRegistered = true

    return true
end

local function onDBMTimerBegin(_, _, _, duration, _, timerType)
    if timerType == "break" then
        openForBreakTimer(duration)
    end
end

local function registerDBM()
    local dbm = _G.DBM

    if dbmRegistered
        or type(dbm) ~= "table"
        or type(dbm.RegisterCallback) ~= "function"
    then
        return false
    end

    dbm:RegisterCallback("DBM_TimerBegin", onDBMTimerBegin)
    dbmRegistered = true

    return true
end

local function providerCanStillLoad(addonName, registered)
    return not registered and C_AddOns.DoesAddOnExist(addonName)
end

local function updateProviderRegistration(self)
    registerBigWigs()
    registerDBM()

    if not providerCanStillLoad("BigWigs", bigWigsRegistered)
        and not providerCanStillLoad("DBM-Core", dbmRegistered)
    then
        self:UnregisterEvent("ADDON_LOADED")
    end
end

local providerFrame = CreateFrame("Frame")
providerFrame:SetScript("OnEvent", function(self, _, addonName)
    if addonName == "BigWigs" or addonName == "DBM-Core" then
        updateProviderRegistration(self)
    end
end)
providerFrame:RegisterEvent("ADDON_LOADED")
updateProviderRegistration(providerFrame)
