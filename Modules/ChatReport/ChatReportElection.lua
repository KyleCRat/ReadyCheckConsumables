local _, RCC = ...

RCC.ChatReportElection = RCC.ChatReportElection or {}
local Election = RCC.ChatReportElection

local F = RCC.F

local ADDON_PREFIX = "RCC"

local reportCandidates = {}
local mrtWillReport = false
local collecting = false
local electedReporter

C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

function Election.Reset()
    wipe(reportCandidates)
    mrtWillReport = false
    collecting = false
    electedReporter = nil
end

function Election.BroadcastIntent()
    local playerName = F.unitFullName("player")

    if not playerName then
        return
    end

    collecting = true
    reportCandidates[playerName] = true

    local chatType = F.chatType()

    if chatType ~= "SAY" then
        C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "REPORT", chatType)
    end
end

function Election.Finalize(members)
    collecting = false
    electedReporter = nil

    -- Use the current active roster at the end of the collection window. Keep
    -- this winner for the whole ready check: late intents or a departing winner
    -- must not cause a second client to repeat an already-sent announcement.
    -- A replacement election waits for the next ready check. The REPORT wire
    -- message stays unchanged for previous-release interoperability.
    for i = 1, #members do
        local name = members[i].key

        if reportCandidates[name]
            and (not electedReporter or name < electedReporter)
        then
            electedReporter = name
        end
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
        if collecting then
            reportCandidates[senderKey] = true
        end

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
    return electedReporter ~= nil
        and electedReporter == F.unitFullName("player")
end
