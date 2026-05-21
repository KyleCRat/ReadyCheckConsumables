local _, RCC = ...

local Election = RCC.ChatReportElection
local Output = RCC.ChatReportOutput
local Reports = RCC.ChatReportReports

local REPORT_ELECTION_DELAY = 1

local reportGeneration = 0

local DIFFICULTY_TO_SETTING = {
    [16]  = "chatReport_mythicRaid",
    [15]  = "chatReport_heroicRaid",
    [14]  = "chatReport_normalRaid",
    [5]   = "chatReport_normalRaid",  -- Story mode (legacy)
    [220] = "chatReport_normalRaid",  -- Story mode
    [17]  = "chatReport_lfr",
    [8]   = "chatReport_mythicDungeon",
    [2]   = "chatReport_heroicDungeon",
    [1]   = "chatReport_normalDungeon",
}

local function hasPermission()
    if not IsInRaid() then
        return true
    end

    local perm = RCC.GetSetting("chatReport_permission")

    if perm == "any" then
        return true
    end

    if perm == "assist" then
        return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    end

    return UnitIsGroupLeader("player")
end

local function isInstanceAllowed()
    local _, _, difficultyID = GetInstanceInfo()
    local key = DIFFICULTY_TO_SETTING[difficultyID]

    if not key then
        return false
    end

    return RCC.GetSetting(key)
end

local function shouldReport()
    if InCombatLockdown() then
        return false
    end

    if not RCC.GetSetting("chatReport_enabled") then
        return false
    end

    if not hasPermission() then
        return false
    end

    if not isInstanceAllowed() then
        return false
    end

    return true
end

local function nextReportGeneration()
    reportGeneration = reportGeneration + 1

    return reportGeneration
end

local function sendReadyCheckReports(generation)
    if generation ~= reportGeneration then
        return
    end

    if not shouldReport() then
        return
    end

    if Election.HasMrtReporter() then
        return
    end

    if Election.IsReporter() then
        Reports.SendAll(true)
    end
end

local function onReadyCheck()
    Election.Reset()

    local generation = nextReportGeneration()

    if not shouldReport() then
        return
    end

    Election.BroadcastIntent()
    C_Timer.After(REPORT_ELECTION_DELAY, function()
        sendReadyCheckReports(generation)
    end)
end

local function onAddonMessage(...)
    local prefix, message, _, sender = ...

    Election.HandleAddonMessage(prefix, message, sender)
end

local function onEvent(self, event, ...)
    if event == "READY_CHECK" then
        onReadyCheck()

        return
    end

    if event == "CHAT_MSG_ADDON" then
        onAddonMessage(...)
    end
end

local chatReportFrame = CreateFrame("Frame")
chatReportFrame:RegisterEvent("READY_CHECK")
chatReportFrame:RegisterEvent("CHAT_MSG_ADDON")
chatReportFrame:SetScript("OnEvent", onEvent)

function RCC.AnnounceAllReady()
    if shouldReport()
        and Election.IsCurrentPlayerCandidate()
        and Election.IsReporter()
    then
        Output.Send("RCC: Everyone in raid is ready!", true)
    end
end

RCC.chatReport = {}

function RCC.chatReport.Test(toChat)
    Reports.SendAll(toChat)
end
