local _, RCC = ...

RCC.ChatReportReports = RCC.ChatReportReports or {}
local Reports = RCC.ChatReportReports

local F = RCC.F
local AuraScan = RCC.HelpfulAuraScan
local FoodAuras = RCC.FoodAuras
local Output = RCC.ChatReportOutput
local Broadcast = RCC.RaidFrameBroadcast
local RaidBuffStatus = RCC.RaidBuffStatus
local Timing = RCC.ConsumableTiming
local db = RCC.db

local GetTime = GetTime
local floor = floor
local format = format

local CURRENT_AUGMENT_XPAC = db.currentAugmentXpac
local FOOD_AURA_TYPE = FoodAuras.Type
local REPAIR_DURABILITY_THRESHOLD = 15

local function appendEntries(target, source)
    for i = 1, #source do
        target[#target + 1] = source[i]
    end
end

local function scanAuraRoster(now)
    local result = {
        available = true,
        members = {},
    }

    F.ForEachActiveRosterMember(function(name, unit, subgroup, class, online)
        if not online then return end

        local scan = AuraScan.ScanUnit(unit, now)

        if not scan.available then
            result.available = false
            result.members = nil

            return false
        end

        result.members[#result.members + 1] = {
            auras = scan.auras,
            class = class,
            name = name,
        }
    end)

    return result
end

local function getReportData()
    return Broadcast.GetReportData()
end

local function isPreviousExpansionUnlimitedAugment(augmentData)
    return augmentData.unlimited == true
        and augmentData.xpac == CURRENT_AUGMENT_XPAC - 1
end

local function isOutdatedAugment(augmentData)
    return augmentData.xpac < CURRENT_AUGMENT_XPAC
        and not isPreviousExpansionUnlimitedAugment(augmentData)
end

local function reportOffline(toChat)
    local offline = {}

    F.ForEachActiveRosterMember(function(name, unit, subgroup, class, online)
        if not online then
            offline[#offline + 1] = Output.ColorName(F.shortName(name), class)
        end
    end)

    if #offline > 0 then
        Output.SendChunked(format("Offline (%d): ", #offline), offline, toChat)
    end
end

local function reportFood(toChat, members)
    local missing = {}
    local expiring = {}

    for memberIndex = 1, #members do
        local member = members[memberIndex]
        local hasFood = false
        local colored = Output.ColorName(
            F.shortName(member.name),
            member.class
        )

        for auraIndex = 1, #member.auras do
            local aura = member.auras[auraIndex]
            local auraType = FoodAuras.GetType(aura)

            if auraType == FOOD_AURA_TYPE.WELL_FED then
                hasFood = true
                local remaining = aura.remaining

                if Timing.IsExpiringSoon(remaining) then
                    expiring[#expiring + 1] = format(
                        "%s(%s)",
                        colored,
                        F.FormatDuration(remaining)
                    )
                end

                break
            end
        end

        if not hasFood then
            missing[#missing + 1] = colored
        end
    end

    local totalBad = #missing + #expiring

    if totalBad == 0 then
        Output.Send("Food: All Fed", toChat)

        return
    end

    local entries = {}
    appendEntries(entries, missing)
    appendEntries(entries, expiring)
    Output.SendChunked(format("No Food (%d): ", totalBad), entries, toChat)
end

local function reportFlasks(toChat, members)
    local missing = {}
    local expiring = {}

    for memberIndex = 1, #members do
        local member = members[memberIndex]
        local hasFlask = false
        local colored = Output.ColorName(
            F.shortName(member.name),
            member.class
        )

        for auraIndex = 1, #member.auras do
            local aura = member.auras[auraIndex]
            local spellID = aura.spellID

            if db.flaskBuffIDs[spellID] then
                hasFlask = true
                local remaining = aura.remaining

                if Timing.IsExpiringSoon(remaining) then
                    expiring[#expiring + 1] = format(
                        "%s(%s)",
                        colored,
                        F.FormatDuration(remaining)
                    )
                end

                break
            end
        end

        if not hasFlask then
            missing[#missing + 1] = colored
        end
    end

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

local function reportAugments(toChat, members)
    local missing = {}
    local lowXpac = {}

    for memberIndex = 1, #members do
        local member = members[memberIndex]
        local hasAugment = false
        local colored = Output.ColorName(
            F.shortName(member.name),
            member.class
        )

        for auraIndex = 1, #member.auras do
            local aura = member.auras[auraIndex]
            local spellID = aura.spellID
            local augmentData = db.augmentBuffIDs[spellID]

            if augmentData then
                hasAugment = true

                if isOutdatedAugment(augmentData) then
                    local xpacName = RCC.xpacShortNames[augmentData.xpac]
                        or tostring(augmentData.xpac)
                    lowXpac[#lowXpac + 1] = format(
                        "%s(%s)",
                        colored,
                        xpacName
                    )
                end

                break
            end
        end

        if not hasAugment then
            missing[#missing + 1] = colored
        end
    end

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

local function reportBuffs(toChat, members)
    local buffsCount = RaidBuffStatus.GetCount()
    local buffInfos = {}
    local classPresent = {}
    local missingCount = {}

    for k = 1, buffsCount do
        buffInfos[k] = RaidBuffStatus.GetInfo(k)
        missingCount[k] = 0
    end

    for memberIndex = 1, #members do
        local member = members[memberIndex]

        for k = 1, buffsCount do
            local info = buffInfos[k]

            if info and member.class == info.providerClass then
                classPresent[k] = true
            end
        end

        local hasBuff = {}

        for auraIndex = 1, #member.auras do
            local aura = member.auras[auraIndex]

            for k = 1, buffsCount do
                if RaidBuffStatus.AuraMatches(k, aura) then
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

local function reportRepairs(toChat)
    local reportData = getReportData()
    local durabilityData = reportData and reportData.durabilityData

    if not durabilityData then
        return
    end

    local repairs = {}

    F.ForEachActiveRosterMember(function(name, unit, subgroup, class, online)
        if not online then return end

        local pct = durabilityData[name]

        if not F.IsSafeNumber(pct) then
            return
        end

        if pct < REPAIR_DURABILITY_THRESHOLD then
            repairs[#repairs + 1] = format(
                "%s(%d%%)",
                Output.ColorName(F.shortName(name), class),
                floor(pct)
            )
        end
    end)

    if #repairs > 0 then
        Output.SendChunked(
            format("Repair (%d): ", #repairs),
            repairs,
            toChat
        )
    end
end

local function reportWeaponEnchants(toChat)
    local reportData = getReportData()
    local tempWeaponEnchantData =
        reportData and reportData.tempWeaponEnchantData

    if not tempWeaponEnchantData then
        return
    end

    local missing = {}
    local noWeapon = {}
    local expiring = {}

    F.ForEachActiveRosterMember(function(name, unit, subgroup, class, online)
        if not online then return end

        local status = tempWeaponEnchantData[name]
        local remaining = status and status.time

        if not F.IsSafeNumber(remaining) then
            return
        end

        local colored = Output.ColorName(F.shortName(name), class)

        if remaining == Broadcast.TempWeaponEnchantStatus.MISSING then
            missing[#missing + 1] = colored
        elseif remaining == Broadcast.TempWeaponEnchantStatus.NO_WEAPON then
            noWeapon[#noWeapon + 1] = format("%s(no weapon)", colored)
        elseif remaining > 0 and Timing.IsExpiringSoon(remaining) then
            expiring[#expiring + 1] = format(
                "%s(%s)",
                colored,
                F.FormatDuration(remaining)
            )
        end
    end)

    local totalBad = #missing + #noWeapon + #expiring

    if totalBad == 0 then
        return
    end

    local entries = {}
    appendEntries(entries, missing)
    appendEntries(entries, noWeapon)
    appendEntries(entries, expiring)
    Output.SendChunked(
        format("Weapon Enchant (%d): ", totalBad),
        entries,
        toChat
    )
end

function Reports.SendAll(toChat)
    local auraRoster = scanAuraRoster(GetTime())

    if auraRoster.available then
        reportFood(toChat, auraRoster.members)
        reportFlasks(toChat, auraRoster.members)
        reportAugments(toChat, auraRoster.members)
        reportBuffs(toChat, auraRoster.members)
    end

    reportWeaponEnchants(toChat)
    reportRepairs(toChat)
    reportOffline(toChat)
end
