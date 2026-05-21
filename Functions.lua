local _, RCC = ...

RCC.F = RCC.F or {}
local F = RCC.F

-- Fallback max group when difficulty is not in the lookup table
local DEFAULT_RAID_GROUP_COUNT = 6
local SECONDS_PER_MINUTE = 60

-- C_UnitAuras has no count API; nil marks the end of the aura list.
RCC.MAX_AURAS = 255

local durationFormatter = CreateFromMixins(SecondsFormatterMixin)
durationFormatter:Init(
    SecondsFormatterConstants.ZeroApproximationThreshold,
    SecondsFormatter.Abbreviation.OneLetter,
    SecondsFormatterConstants.RoundUpLastUnit,
    SecondsFormatterConstants.ConvertToLower,
    SecondsFormatterConstants.DontRoundUpIntervals
)
durationFormatter:SetDesiredUnitCount(1)
durationFormatter:SetMinInterval(SecondsFormatter.Interval.Minutes)
durationFormatter:SetStripIntervalWhitespace(true)

-- Maps WoW difficulty IDs to the highest raid group number that
-- should be included when iterating the roster. Players in groups
-- beyond this number are considered bench/overflow and skipped.
-- Value = number of groups (each group holds 5 players).
local GROUP_COUNT_BY_CONTENT_TYPE = {
    [1]   = 1, -- Party Normal
    [2]   = 1, -- Party Heroic
    [8]   = 1, -- Party Mythic
    [16]  = 4, -- Raid Mythic (20-player)
    [14]  = 6, -- Raid Normal (up to 30-player)
    [15]  = 6, -- Raid Heroic (up to 30-player)
    [17]  = 6, -- LFR
    [151] = 6, -- LFR
    [33]  = 6, -- Timewalking Raid
}

local MRT_PREFIXES = {
    "EXRTADD", "MRTADDA", "MRTADDB", "MRTADDC", "MRTADDD",
    "MRTADDE", "MRTADDF", "MRTADDG", "MRTADDH", "MRTADDI",
}

local isMrtPrefix = {}

local MRT_RAIDCHECK_REPORT_TYPES = {
    FOOD        = true,
    FLASK       = true,
    RUNES       = true,
    BUFFS       = true,
    REPORT_KITS = true,
    REPORT_OILS = true,
}

for _, prefix in ipairs(MRT_PREFIXES) do
    C_ChatInfo.RegisterAddonMessagePrefix(prefix)
    isMrtPrefix[prefix] = true
end

function F.IsMrtPrefix(prefix)
    return isMrtPrefix[prefix] == true
end

function F.ParseMrtMessage(message)
    if not message then
        return nil
    end

    return strsplit("\t", message)
end

function F.IsMrtRaidCheckReportMessage(moduleName, msgType)
    return moduleName == "raidcheck"
        and MRT_RAIDCHECK_REPORT_TYPES[msgType] == true
end

function F.FormatDuration(seconds)
    if not seconds then
        return ""
    end

    if seconds < 0 then
        seconds = 0
    elseif seconds > 0 and seconds < SECONDS_PER_MINUTE then
        seconds = SECONDS_PER_MINUTE
    end

    return durationFormatter:Format(seconds)
end

function F.IsSafeNumber(value)
    return not issecretvalue(value)
        and type(value) == "number"
end

function F.GetAuraRemaining(expiry, now)
    if not F.IsSafeNumber(expiry) then
        return nil
    end

    if expiry <= 0 then
        return nil
    end

    return expiry - now
end

function F.StoreAuraID(data, aura)
    local auraID = aura and aura.auraInstanceID

    if auraID and not issecretvalue(auraID) then
        data.auraID = auraID
    else
        data.auraID = true
    end
end

function F.UnitIsUnitSafe(unit, otherUnit)
    if issecretvalue(unit) or issecretvalue(otherUnit) then
        return false
    end

    if not unit or not otherUnit then
        return false
    end

    local matches = UnitIsUnit(unit, otherUnit)

    if issecretvalue(matches) then
        return false
    end

    return matches == true
end

function F.GetRaidDiffMaxGroup()
    local _, instance_type, difficulty = GetInstanceInfo()

    if not IsInRaid() and (instance_type == "party" or
                           instance_type == "scenario") then
        return 1
    end

    if instance_type ~= "raid" then
        return 8
    end

    if difficulty and GROUP_COUNT_BY_CONTENT_TYPE[difficulty] then
        return GROUP_COUNT_BY_CONTENT_TYPE[difficulty]
    end

    return DEFAULT_RAID_GROUP_COUNT
end

function F.chatType()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    end

    if IsInRaid(LE_PARTY_CATEGORY_HOME) then
        return "RAID"
    end

    if IsInGroup(LE_PARTY_CATEGORY_HOME) then
        return "PARTY"
    end

    return "SAY"
end

function F.shortName(fullName)
    return (strsplit("-", fullName))
end

local function getNormalizedRealm()
    local realm = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()

    if not realm then
        return nil
    end

    return realm:gsub("%s+", "")
end

function F.fullName(name)
    if not name or name == "" then
        return nil
    end

    if name:find("-", 1, true) then
        return name
    end

    local realm = getNormalizedRealm()

    if realm and realm ~= "" then
        return name .. "-" .. realm
    end

    return name
end

function F.unitFullName(unit)
    return F.fullName(GetUnitName(unit, true) or UnitName(unit))
end


--------------------------------------------------------------------------------
--- GetRosterInfo(index)
--- Returns full name, unit, subgroup, class for a single roster slot.
--- Works in both raid and party. Returns nil when no player at index.
--- Party order: 1=player, 2=party1, 3=party2, 4=party3, 5=party4.
--------------------------------------------------------------------------------

function F.GetRosterInfo(index)
    if IsInRaid() then
        local name, _, subgroup, _, _, class = GetRaidRosterInfo(index)

        if not name then
            return nil
        end

        return F.fullName(name), "raid" .. index, subgroup, class
    end

    if index > 5 then
        return nil
    end

    local unit = index == 1 and "player" or "party" .. (index - 1)

    if not UnitExists(unit) then
        return nil
    end

    local name = GetUnitName(unit, true)

    if not name then
        return nil
    end

    local _, fileName = UnitClass(unit)

    return F.fullName(name), unit, 1, fileName
end

--------------------------------------------------------------------------------
--- ForEachActiveRosterMember(callback)
--- Iterates party/raid members within the active instance groups.
--- Callback receives fullName, unit, subgroup, class, rosterIndex.
--- Return false from the callback to stop iteration early.
--------------------------------------------------------------------------------

function F.ForEachActiveRosterMember(callback)
    local maxGroup = F.GetRaidDiffMaxGroup()

    for j = 1, 40 do
        local name, unit, subgroup, class = F.GetRosterInfo(j)

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

--------------------------------------------------------------------------------
--- ForEachHelpfulAura(unit, callback)
--- Iterates helpful auras and skips secret spell IDs before callback.
--- Callback receives aura, spellID, auraIndex.
--- Return true from the callback to stop iteration early.
--------------------------------------------------------------------------------

function F.ForEachHelpfulAura(unit, callback)
    for i = 1, RCC.MAX_AURAS do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")

        if not aura then
            break
        end

        local spellID = aura.spellId or aura.spellID

        if not issecretvalue(spellID)
            and callback(aura, spellID, i) == true
        then
            break
        end
    end
end

--------------------------------------------------------------------------------
--- hasClassInRoster(className)
--- Returns true if any roster member within active groups is the given class.
--------------------------------------------------------------------------------

function F.hasClassInRoster(className)
    local found = false

    F.ForEachActiveRosterMember(function(name, unit, subgroup, class)
        if class == className then
            found = true

            return false
        end
    end)

    return found
end
