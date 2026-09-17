local _, RCC = ...

local Election = RCC.ChatReportElection
local Output = RCC.ChatReportOutput
local Reports = RCC.ChatReportReports
local ReadyChecks = RCC.ReadyCheckController

local REPORT_ELECTION_DELAY = 1

local chatReportFrame = CreateFrame("Frame")
local reportTimer
local reportSession

local DIFFICULTY_TO_SETTING = {
    [16]  = "chatReport_mythicRaid",
    [233] = "chatReport_mythicRaid",
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
    if InCombatLockdown() or not IsInGroup() then
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

--------------------------------------------------------------------------------
--- Ready-check completion contract
--- The shared controller owns responses, roster membership, and their summary.
--- Chat Report owns eligibility, reporter election, and send deduplication only.
--- Announce when the shared summary is all-ready and the raid has a bench.
--- Only the elected reporter sends, after the existing collection window. A
--- skipped send does not consume the announcement. No retry queue is used.
--------------------------------------------------------------------------------

local function tryAnnounceAllReady()
    if not reportSession
        or reportSession.announced
        or ReadyChecks.GetCurrent() ~= reportSession.readyCheck
        or not shouldReport()
        or not Election.IsCurrentPlayerCandidate()
        or not Election.IsReporter()
    then
        return
    end

    local summary = reportSession.readyCheck.summary

    if summary.allReady and summary.hasBench
        and Output.Send("RCC: Everyone in raid is ready!", true)
    then
        reportSession.announced = true
    end
end

local function cancelReportSession()
    if reportTimer then
        reportTimer:Cancel()
        reportTimer = nil
    end

    reportSession = nil
    Election.Reset()
end

local function finishReportElection()
    reportTimer = nil

    if not reportSession
        or ReadyChecks.GetCurrent() ~= reportSession.readyCheck
    then
        return
    end

    Election.Finalize(reportSession.readyCheck.members)
    tryAnnounceAllReady()

    -- MRT suppresses missing-consumable reports, not the separate announcement
    -- that the active roster has confirmed ready while the bench is pending.
    if shouldReport()
        and Election.IsCurrentPlayerCandidate()
        and Election.IsReporter()
        and not Election.HasMrtReporter()
    then
        Reports.SendAll(true)
    end
end

local function onReadyCheckStarted(session)
    cancelReportSession()

    if not shouldReport() then
        return
    end

    reportSession = {
        readyCheck = session,
        announced = false,
    }

    Election.BroadcastIntent()
    reportTimer = C_Timer.NewTimer(REPORT_ELECTION_DELAY, finishReportElection)
end

local function onReadyCheckUpdated(session)
    if reportSession and reportSession.readyCheck == session then
        tryAnnounceAllReady()
    end
end

ReadyChecks.Subscribe({
    OnStarted = onReadyCheckStarted,
    OnUpdated = onReadyCheckUpdated,
    OnFinished = onReadyCheckUpdated,
    OnCancelled = cancelReportSession,
})

chatReportFrame:SetScript("OnEvent", function(_self, _event, ...)
    Election.HandleAddonMessage(...)
end)

chatReportFrame:RegisterEvent("CHAT_MSG_ADDON")

RCC.chatReport = {}

function RCC.chatReport.Test(toChat)
    Reports.SendAll(toChat)
end
