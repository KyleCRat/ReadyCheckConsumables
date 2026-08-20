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

function Election.HandleAddonMessage(prefix, message, channel, sender)
    if issecretvalue(prefix) or issecretvalue(message) then
        return
    end

    local isRccReport = prefix == ADDON_PREFIX and message == "REPORT"
    local isMrtMessage = F.IsMrtPrefix(prefix)

    if not isRccReport and not isMrtMessage then
        return
    end

    local senderKey = F.GetTrustedGroupAddonSender(channel, sender)

    if not senderKey then
        return
    end

    if isRccReport then
        reportCandidates[senderKey] = true

        return
    end

    if isMrtMessage then
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
