local _, RCC = ...
RCC.F = RCC.F or {}
local F = RCC.F

-- Fallback max group when difficulty is not in the lookup table
local DEFAULT_RAID_GROUP_COUNT = 6

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

-------------------------------------------------------------------------------
--- GetRosterInfo(index)
--- Returns name, unit, subgroup, class for a single roster slot.
--- Works in both raid and party. Returns nil when no player at index.
--- Party order: 1=player, 2=party1, 3=party2, 4=party3, 5=party4.
-------------------------------------------------------------------------------

function F.GetRosterInfo(index)
    if IsInRaid() then
        local name, _, subgroup, _, _, class = GetRaidRosterInfo(index)

        if not name then
            return nil
        end

        return name, "raid" .. index, subgroup, class
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

    return name, unit, 1, fileName
end

-------------------------------------------------------------------------------
--- hasClassInRoster(className)
--- Returns true if any roster member within active groups is the given class.
-------------------------------------------------------------------------------

function F.hasClassInRoster(className)
    for j = 1, 40 do
        local name, _, _, class = F.GetRosterInfo(j)

        if not name then
            if not IsInRaid() then
                return false
            end
        elseif class == className then
            return true
        end
    end

    return false
end
