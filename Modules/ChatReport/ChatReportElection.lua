local _, RCC = ...

RCC.ChatReportElection = RCC.ChatReportElection or {}
local Election = RCC.ChatReportElection

local F = RCC.F

local ADDON_PREFIX = "RCC"

local reportCandidates = {}
local mrtWillReport = false

C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

local function isElectedReporter()
    local playerName = F.unitFullName("player")

    if not playerName then
        return false
    end

    for name in pairs(reportCandidates) do
        if name < playerName then
            return false
        end
    end

    return true
end

function Election.Reset()
    wipe(reportCandidates)
    mrtWillReport = false
end

function Election.BroadcastIntent()
    local playerName = F.unitFullName("player")

    if not playerName then
        return
    end

    reportCandidates[playerName] = true

    local chatType = F.chatType()

    if chatType ~= "SAY" then
        C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "REPORT", chatType)
    end
end

function Election.HandleAddonMessage(prefix, message, sender)
    if prefix == ADDON_PREFIX and message == "REPORT" then
        local senderKey = F.fullName(sender)

        if senderKey then
            reportCandidates[senderKey] = true
        end

        return
    end

    if F.IsMrtPrefix(prefix) then
        local moduleName, msgType = F.ParseMrtMessage(message)

        if F.IsMrtRaidCheckReportMessage(moduleName, msgType) then
            mrtWillReport = true
        end
    end
end

function Election.HasMrtReporter()
    return mrtWillReport == true
end

function Election.IsCurrentPlayerCandidate()
    local playerName = F.unitFullName("player")

    return playerName and reportCandidates[playerName] == true
end

function Election.IsReporter()
    return isElectedReporter()
end
