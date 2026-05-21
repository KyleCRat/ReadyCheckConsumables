local _, RCC = ...
local F = RCC.F
local RaidBuffStatus = RCC.RaidBuffStatus
local Timing = RCC.ConsumableTiming
local db = RCC.db

local SendChatMessage = SendChatMessage
local GetTime         = GetTime
local format          = format
local floor           = floor

local CURRENT_AUGMENT_XPAC = db.currentAugmentXpac

--------------------------------------------------------------------------------
--- Addon message coordination
--- When multiple players have RCC with chat reporting enabled, only one
--- should report. On READY_CHECK each eligible reporter broadcasts intent
--- via addon messages. After a short collection window the alphabetically
--- first candidate wins and is the sole reporter.
--- If MRT (Method Raid Tools) is also broadcasting report intent, RCC
--- defers entirely and lets MRT handle the report.
--------------------------------------------------------------------------------

local ADDON_PREFIX = "RCC"
local CHAT_MESSAGE_LIMIT = 220
local REPORT_ELECTION_DELAY = 1
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

local reportCandidates = {}
local mrtWillReport = false
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

local getRosterInfo = F.GetRosterInfo

--------------------------------------------------------------------------------
--- Class color helper
--- Wraps a name in its class color. Falls back to white if unknown.
--------------------------------------------------------------------------------

local function colorName(name, class)
    if not class then
        return name
    end

    local color = RAID_CLASS_COLORS[class]

    if not color then
        return name
    end

    return format("|c%s%s|r", color.colorStr, name)
end

--------------------------------------------------------------------------------
--- Output helper
--- When toChat is true, strips color codes and sends to chat.
--- When toChat is false/nil, prints locally.
--------------------------------------------------------------------------------

local function sendResults(msg, toChat)
    if not msg or msg == "" then
        return
    end

    if not toChat then
        print(msg)

        return
    end

    local chatType = F.chatType()
    msg = msg:gsub("|c%x%x%x%x%x%x%x%x", "")
    msg = msg:gsub("|r", "")
    SendChatMessage(msg, chatType)
end

local function sendChunked(prefix, entries, toChat)
    if not entries or #entries == 0 then
        return
    end

    local line = prefix or ""
    local hasEntry = false

    for i = 1, #entries do
        local entry = entries[i]
        local separator = hasEntry and ", " or ""

        if hasEntry
            and #line + #separator + #entry > CHAT_MESSAGE_LIMIT
        then
            sendResults(line, toChat)
            line = entry
        else
            line = line .. separator .. entry
        end

        hasEntry = true
    end

    sendResults(line, toChat)
end

local function appendEntries(target, source)
    for i = 1, #source do
        target[#target + 1] = source[i]
    end
end

local function forEachRosterMember(callback)
    local maxGroup = F.GetRaidDiffMaxGroup()

    for j = 1, 40 do
        local name, unit, subgroup, class = getRosterInfo(j)

        if not name then
            if not IsInRaid() then
                break
            end
        elseif subgroup <= maxGroup then
            if callback(name, unit, subgroup, class, j) == false then
                break
            end
        end
    end
end

local function forEachHelpfulAura(unit, callback)
    for i = 1, RCC.MAX_AURAS do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")

        if not aura then
            break
        end

        if not issecretvalue(aura.spellId)
            and callback(aura, aura.spellId) == true
        then
            break
        end
    end
end

--------------------------------------------------------------------------------
--- Food Report
--- Reports players with no food buff.
--------------------------------------------------------------------------------

local function reportFood(toChat)
    local missing = {}

    forEachRosterMember(function(name, unit, subgroup, class)
        local hasFood = false

        forEachHelpfulAura(unit, function(aura, spellID)
            if db.foodBuffIDs[spellID] or db.foodIconIDs[aura.icon] then
                hasFood = true

                return true
            end
        end)

        if not hasFood then
            missing[#missing + 1] = colorName(F.shortName(name), class)
        end
    end)

    if #missing == 0 then
        sendResults("Food: All Fed", toChat)

        return
    end

    sendChunked(format("No Food (%d): ", #missing), missing, toChat)
end

--------------------------------------------------------------------------------
--- Flask Report
--- Uses RCC.db.flaskBuffIDs spell ID table.
--- Reports missing flasks and flasks within the shared warning window.
--------------------------------------------------------------------------------

local function reportFlasks(toChat)
    local missing = {}
    local expiring = {}
    local now = GetTime()

    forEachRosterMember(function(name, unit, subgroup, class)
        local hasFlask = false
        local colored = colorName(F.shortName(name), class)

        forEachHelpfulAura(unit, function(aura, spellID)
            if db.flaskBuffIDs[spellID] then
                hasFlask = true

                local remaining = F.GetAuraRemaining(
                    aura.expirationTime,
                    now
                )

                if Timing.IsExpiringSoon(remaining) then
                    local mins = floor(remaining / 60)
                    local label = mins == 0 and "<1" or tostring(mins)
                    expiring[#expiring + 1] = format(
                        "%s(%s)",
                        colored,
                        label
                    )
                end

                return true
            end
        end)

        if not hasFlask then
            missing[#missing + 1] = colored
        end
    end)

    local totalBad = #missing + #expiring

    if totalBad == 0 then
        sendResults("Flasks: All Flasked", toChat)

        return
    end

    local entries = {}
    appendEntries(entries, missing)
    appendEntries(entries, expiring)
    sendChunked(format("No Flask (%d): ", totalBad), entries, toChat)
end

--------------------------------------------------------------------------------
--- Augment Rune Report
--- Uses RCC.db.augmentBuffIDs (spellId -> xpac mapping).
--- Reports missing runes and runes below CURRENT_AUGMENT_XPAC.
--------------------------------------------------------------------------------

local function reportAugments(toChat)
    local missing = {}
    local lowXpac = {}

    forEachRosterMember(function(name, unit, subgroup, class)
        local hasAugment = false
        local colored = colorName(F.shortName(name), class)

        forEachHelpfulAura(unit, function(aura, spellID)
            local auraXpac = db.augmentBuffIDs[spellID]

            if auraXpac then
                hasAugment = true

                if auraXpac < CURRENT_AUGMENT_XPAC then
                    local xpacName = db.augmentXpacNames[auraXpac]
                        or tostring(auraXpac)
                    lowXpac[#lowXpac + 1] = format(
                        "%s(%s)",
                        colored,
                        xpacName
                    )
                end

                return true
            end
        end)

        if not hasAugment then
            missing[#missing + 1] = colored
        end
    end)

    local totalBad = #missing + #lowXpac

    if totalBad == 0 then
        sendResults("Augments: All Augmented", toChat)

        return
    end

    local entries = {}
    appendEntries(entries, missing)
    appendEntries(entries, lowXpac)
    sendChunked(format("No Augment (%d): ", totalBad), entries, toChat)
end

--------------------------------------------------------------------------------
--- Raid Buff Report
--- Uses RCC.RaidBuffStatus. Only reports missing buffs when the
--- providing class IS present in the raid.
--- Output: "Buffs AP (2), Int (1)" or nothing if all present.
--------------------------------------------------------------------------------

local function reportBuffs(toChat)
    local buffsCount = RaidBuffStatus.GetCount()
    local buffInfos = {}
    local classPresent = {}
    local missingCount = {}

    for k = 1, buffsCount do
        buffInfos[k] = RaidBuffStatus.GetInfo(k)
        missingCount[k] = 0
    end

    forEachRosterMember(function(name, unit, subgroup, class)
        for k = 1, buffsCount do
            local info = buffInfos[k]

            if info and class == info.providerClass then
                classPresent[k] = true
            end
        end

        local hasBuff = {}

        forEachHelpfulAura(unit, function(aura)
            for k = 1, buffsCount do
                if RaidBuffStatus.AuraMatches(k, aura) then
                    hasBuff[k] = true
                end
            end
        end)

        for k = 1, buffsCount do
            if not hasBuff[k] then
                missingCount[k] = missingCount[k] + 1
            end
        end
    end)

    local parts = {}

    for k = 1, buffsCount do
        local info = buffInfos[k]

        if info and classPresent[k] and missingCount[k] > 0 then
            parts[#parts + 1] = format(
                "%s (%d)",
                info.label,
                missingCount[k]
            )
        end
    end

    if #parts == 0 then
        sendResults("Party Buffs: All Buffed", toChat)

        return
    end

    local label = GARRISON_MISSION_PARTY_BUFFS or "Buffs"
    sendChunked(label .. " ", parts, toChat)
end

local function sendConsumableReports(toChat)
    reportFood(toChat)
    reportFlasks(toChat)
    reportAugments(toChat)
    reportBuffs(toChat)
end

--------------------------------------------------------------------------------
--- Ready Check Handler
--- On READY_CHECK, eligible reporters broadcast intent via addon messages.
--- After a 1-second collection window the alphabetically first candidate
--- is elected as the sole reporter.
--------------------------------------------------------------------------------

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

local function resetReportElection()
    reportGeneration = reportGeneration + 1
    wipe(reportCandidates)
    mrtWillReport = false

    return reportGeneration
end

local function broadcastReportIntent()
    if not shouldReport() then
        return
    end

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

local function onReadyCheck(generation)
    if generation ~= reportGeneration then
        return
    end

    if not shouldReport() then
        return
    end

    if mrtWillReport then
        return
    end

    if not isElectedReporter() then
        return
    end

    sendConsumableReports(true)
end

local function onEvent(self, event, ...)
    if event == "READY_CHECK" then
        local generation = resetReportElection()
        broadcastReportIntent()
        C_Timer.After(REPORT_ELECTION_DELAY, function()
            onReadyCheck(generation)
        end)

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, _, sender = ...

        if prefix == ADDON_PREFIX and message == "REPORT" then
            local senderKey = F.fullName(sender)

            if senderKey then
                reportCandidates[senderKey] = true
            end

        elseif F.IsMrtPrefix(prefix) then
            local moduleName, msgType = F.ParseMrtMessage(message)

            if F.IsMrtRaidCheckReportMessage(moduleName, msgType) then
                mrtWillReport = true
            end
        end
    end
end

local chatReportFrame = CreateFrame("Frame")
chatReportFrame:RegisterEvent("READY_CHECK")
chatReportFrame:RegisterEvent("CHAT_MSG_ADDON")
chatReportFrame:SetScript("OnEvent", onEvent)

--------------------------------------------------------------------------------
--- Ready check completion announcement
--- Sent to raid chat when all tracked members are ready but benched members
--- have not yet responded, so the raid leader knows they can pull.
--------------------------------------------------------------------------------

function RCC.AnnounceAllReady()
    if not shouldReport() then
        return
    end

    local playerName = F.unitFullName("player")

    if not playerName or not reportCandidates[playerName] then
        return
    end

    if not isElectedReporter() then
        return
    end

    SendChatMessage("RCC: Everyone in raid is ready!", F.chatType())
end

--------------------------------------------------------------------------------
--- Test Interface (called via /rcc report and /rcc reportchat)
--------------------------------------------------------------------------------

RCC.chatReport = {}

function RCC.chatReport.Test(toChat)
    sendConsumableReports(toChat)
end
