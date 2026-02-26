local _, RCC = ...
local F = RCC.F
local db = RCC.db

local SendChatMessage = SendChatMessage
local GetTime         = GetTime
local format          = format
local floor           = floor
local ceil            = ceil

local CURRENT_RUNE_TIER = 6

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

-------------------------------------------------------------------------------
--- Class color helper
--- Wraps a name in its class color. Falls back to white if unknown.
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
--- Output helper
--- When toChat is true, strips color codes and sends to chat.
--- When toChat is false/nil, prints locally.
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
--- Food Report
--- Uses icon-based detection (matching existing RCC approach).
--- Reports players with no food buff.
-------------------------------------------------------------------------------

local function reportFood(toChat)
    local missing = {}
    local maxGroup = F.GetRaidDiffMaxGroup()

    for j = 1, 40 do
        local name, unit, subgroup, class = getRosterInfo(j)

        if not name then
            if not IsInRaid() then
                break
            end
        elseif subgroup <= maxGroup then
            local hasFood = false

            for i = 1, 40 do
                local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")

                if not aura then
                    break
                end

                if db.foodIconIDs[aura.icon] then
                    hasFood = true
                    break
                end
            end

            if not hasFood then
                missing[#missing + 1] = colorName(F.shortName(name), class)
            end
        end
    end

    if #missing == 0 then
        sendResults("Food: All present", toChat)

        return
    end

    local result = format("No Food (%d): ", #missing)

    for i = 1, #missing do
        result = result .. missing[i]

        if i < #missing then
            result = result .. ", "
        end

        if #result > 220 then
            sendResults(result, toChat)
            result = ""
        end
    end

    sendResults(result, toChat)
end

-------------------------------------------------------------------------------
--- Flask Report
--- Uses RCC.db.flaskBuffIDs spell ID table.
--- Reports missing flasks and flasks expiring within 10 minutes.
-------------------------------------------------------------------------------

local function reportFlasks(toChat)
    local missing = {}
    local expiring = {}
    local maxGroup = F.GetRaidDiffMaxGroup()
    local now = GetTime()

    for j = 1, 40 do
        local name, unit, subgroup, class = getRosterInfo(j)

        if not name then
            if not IsInRaid() then
                break
            end
        elseif subgroup <= maxGroup then
            local hasFlask = false
            local colored = colorName(F.shortName(name), class)

            for i = 1, 40 do
                local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")

                if not aura then
                    break
                end

                if db.flaskBuffIDs[aura.spellId] then
                    hasFlask = true
                    local remaining = aura.expirationTime - now

                    if remaining > 0 and remaining <= 600 then
                        local mins = floor(remaining / 60)
                        local label = mins == 0 and "<1" or tostring(mins)
                        expiring[#expiring + 1] = format("%s(%s)", colored, label)
                    end

                    break
                end
            end

            if not hasFlask then
                missing[#missing + 1] = colored
            end
        end
    end

    local totalBad = #missing + #expiring

    if totalBad == 0 then
        sendResults("Flasks: All present", toChat)

        return
    end

    local result = format("No Flask (%d): ", totalBad)

    for i = 1, #missing do
        local isLast = (i == #missing and #expiring == 0)
        result = result .. missing[i]

        if not isLast then
            result = result .. ", "
        end

        if #result > 220 then
            sendResults(result, toChat)
            result = ""
        end
    end

    for i = 1, #expiring do
        result = result .. expiring[i]

        if i < #expiring then
            result = result .. ", "
        end

        if #result > 220 then
            sendResults(result, toChat)
            result = ""
        end
    end

    sendResults(result, toChat)
end

-------------------------------------------------------------------------------
--- Augment Rune Report
--- Uses RCC.db.tableRunes (spellId -> tier mapping).
--- Reports missing runes and runes below CURRENT_RUNE_TIER.
-------------------------------------------------------------------------------

local function reportRunes(toChat)
    local missing = {}
    local lowTier = {}
    local maxGroup = F.GetRaidDiffMaxGroup()

    for j = 1, 40 do
        local name, unit, subgroup, class = getRosterInfo(j)

        if not name then
            if not IsInRaid() then
                break
            end
        elseif subgroup <= maxGroup then
            local hasRune = false
            local colored = colorName(F.shortName(name), class)

            for i = 1, 60 do
                local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")

                if not aura then
                    break
                end

                local tier = db.tableRunes[aura.spellId]

                if tier then
                    hasRune = true

                    if tier < CURRENT_RUNE_TIER then
                        lowTier[#lowTier + 1] = format("%s(%d)", colored, tier)
                    end

                    break
                end
            end

            if not hasRune then
                missing[#missing + 1] = colored
            end
        end
    end

    local totalBad = #missing + #lowTier

    if totalBad == 0 then
        sendResults("Runes: All present", toChat)

        return
    end

    local result = format("No Runes (%d): ", totalBad)

    for i = 1, #missing do
        local isLast = (i == #missing and #lowTier == 0)
        result = result .. missing[i]

        if not isLast then
            result = result .. ", "
        end

        if #result > 220 then
            sendResults(result, toChat)
            result = ""
        end
    end

    for i = 1, #lowTier do
        result = result .. lowTier[i]

        if i < #lowTier then
            result = result .. ", "
        end

        if #result > 220 then
            sendResults(result, toChat)
            result = ""
        end
    end

    sendResults(result, toChat)
end

-------------------------------------------------------------------------------
--- Raid Buff Report
--- Uses RCC.db.raidBuffs. Only reports missing buffs when the
--- providing class IS present in the raid.
--- Output: "Buffs AP (2), Int (1)" or nothing if all present.
-------------------------------------------------------------------------------

local function reportBuffs(toChat)
    local buffsList = db.raidBuffs
    local buffsCount = #buffsList
    local classPresent = {}
    local missingCount = {}
    local maxGroup = F.GetRaidDiffMaxGroup()

    for k = 1, buffsCount do
        missingCount[k] = 0
    end

    for j = 1, 40 do
        local name, unit, subgroup, class = getRosterInfo(j)

        if not name then
            if not IsInRaid() then
                break
            end
        elseif subgroup <= maxGroup then
            for k = 1, buffsCount do
                if class == buffsList[k][2] then
                    classPresent[k] = true
                end
            end

            local hasBuff = {}

            for i = 1, 40 do
                local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")

                if not aura then
                    break
                end

                for k = 1, buffsCount do
                    if aura.spellId == buffsList[k][3] then
                        hasBuff[k] = true
                    elseif buffsList[k][4] and aura.spellId == buffsList[k][4] then
                        hasBuff[k] = true
                    elseif buffsList[k][5] and buffsList[k][5][aura.spellId] then
                        hasBuff[k] = true
                    end
                end
            end

            for k = 1, buffsCount do
                if not hasBuff[k] then
                    missingCount[k] = missingCount[k] + 1
                end
            end
        end
    end

    local parts = {}

    for k = 1, buffsCount do
        if classPresent[k] and missingCount[k] > 0 then
            parts[#parts + 1] = format("%s (%d)", buffsList[k][1], missingCount[k])
        end
    end

    if #parts == 0 then
        sendResults("Buffs: All present", toChat)

        return
    end

    local label = GARRISON_MISSION_PARTY_BUFFS or "Buffs"
    local result = label .. " " .. table.concat(parts, ", ")
    sendResults(result, toChat)
end

-------------------------------------------------------------------------------
--- Ready Check Handler
--- Fires all reports 1 second after READY_CHECK to allow aura
--- data to propagate for all raid members.
-------------------------------------------------------------------------------

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

local function onReadyCheck()
    if not RCC.GetSetting("chatReport_enabled") then
        return
    end

    if not hasPermission() then
        return
    end

    if not isInstanceAllowed() then
        return
    end

    reportFood(true)
    reportFlasks(true)
    reportRunes(true)
    reportBuffs(true)
end

local function onEvent(self, event)
    if event ~= "READY_CHECK" then
        return
    end

    C_Timer.After(.25, onReadyCheck)
end

local chatReportFrame = CreateFrame("Frame")
chatReportFrame:RegisterEvent("READY_CHECK")
chatReportFrame:SetScript("OnEvent", onEvent)

-------------------------------------------------------------------------------
--- Test Interface (called via /rcc report and /rcc reportchat)
-------------------------------------------------------------------------------

RCC.chatReport = {}

function RCC.chatReport.Test(toChat)
    reportFood(toChat)
    reportFlasks(toChat)
    reportRunes(toChat)
    reportBuffs(toChat)
end
