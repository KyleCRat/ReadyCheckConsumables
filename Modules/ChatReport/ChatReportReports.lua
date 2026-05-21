local _, RCC = ...

RCC.ChatReportReports = RCC.ChatReportReports or {}
local Reports = RCC.ChatReportReports

local F = RCC.F
local Output = RCC.ChatReportOutput
local RaidBuffStatus = RCC.RaidBuffStatus
local Timing = RCC.ConsumableTiming
local db = RCC.db

local GetTime = GetTime
local floor = floor
local format = format

local CURRENT_AUGMENT_XPAC = db.currentAugmentXpac

local function appendEntries(target, source)
    for i = 1, #source do
        target[#target + 1] = source[i]
    end
end

local function isPreviousExpansionUnlimitedAugment(augmentData)
    return augmentData.unlimited == true
        and augmentData.xpac == CURRENT_AUGMENT_XPAC - 1
end

local function isOutdatedAugment(augmentData)
    return augmentData.xpac < CURRENT_AUGMENT_XPAC
        and not isPreviousExpansionUnlimitedAugment(augmentData)
end

local function reportFood(toChat)
    local missing = {}

    F.ForEachActiveRosterMember(function(name, unit, subgroup, class)
        local hasFood = false

        F.ForEachHelpfulAura(unit, function(aura, spellID)
            if db.foodBuffIDs[spellID] or db.foodIconIDs[aura.icon] then
                hasFood = true

                return true
            end
        end)

        if not hasFood then
            missing[#missing + 1] = Output.ColorName(F.shortName(name), class)
        end
    end)

    if #missing == 0 then
        Output.Send("Food: All Fed", toChat)

        return
    end

    Output.SendChunked(format("No Food (%d): ", #missing), missing, toChat)
end

local function reportFlasks(toChat)
    local missing = {}
    local expiring = {}
    local now = GetTime()

    F.ForEachActiveRosterMember(function(name, unit, subgroup, class)
        local hasFlask = false
        local colored = Output.ColorName(F.shortName(name), class)

        F.ForEachHelpfulAura(unit, function(aura, spellID)
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
        Output.Send("Flasks: All Flasked", toChat)

        return
    end

    local entries = {}
    appendEntries(entries, missing)
    appendEntries(entries, expiring)
    Output.SendChunked(format("No Flask (%d): ", totalBad), entries, toChat)
end

local function reportAugments(toChat)
    local missing = {}
    local lowXpac = {}

    F.ForEachActiveRosterMember(function(name, unit, subgroup, class)
        local hasAugment = false
        local colored = Output.ColorName(F.shortName(name), class)

        F.ForEachHelpfulAura(unit, function(aura, spellID)
            local augmentData = db.augmentBuffIDs[spellID]

            if augmentData then
                hasAugment = true

                if isOutdatedAugment(augmentData) then
                    local xpacName = db.augmentXpacNames[augmentData.xpac]
                        or tostring(augmentData.xpac)
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
        Output.Send("Augments: All Augmented", toChat)

        return
    end

    local entries = {}
    appendEntries(entries, missing)
    appendEntries(entries, lowXpac)
    Output.SendChunked(format("No Augment (%d): ", totalBad), entries, toChat)
end

local function reportBuffs(toChat)
    local buffsCount = RaidBuffStatus.GetCount()
    local buffInfos = {}
    local classPresent = {}
    local missingCount = {}

    for k = 1, buffsCount do
        buffInfos[k] = RaidBuffStatus.GetInfo(k)
        missingCount[k] = 0
    end

    F.ForEachActiveRosterMember(function(name, unit, subgroup, class)
        for k = 1, buffsCount do
            local info = buffInfos[k]

            if info and class == info.providerClass then
                classPresent[k] = true
            end
        end

        local hasBuff = {}

        F.ForEachHelpfulAura(unit, function(aura)
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
        Output.Send("Party Buffs: All Buffed", toChat)

        return
    end

    local label = GARRISON_MISSION_PARTY_BUFFS or "Buffs"
    Output.SendChunked(label .. " ", parts, toChat)
end

function Reports.SendAll(toChat)
    reportFood(toChat)
    reportFlasks(toChat)
    reportAugments(toChat)
    reportBuffs(toChat)
end
