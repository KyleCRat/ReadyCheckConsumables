local _, RCC = ...
RCC.F = RCC.F or {}
F = RCC.F

-- Fallback max group when difficulty is not in the lookup table
local DEFAULT_RAID_GROUP_COUNT = 5

-- Maps WoW difficulty IDs to the highest raid group number that
-- should be included when iterating the roster. Players in groups
-- beyond this number are considered bench/overflow and skipped.
-- Value = number of groups (each group holds 5 players).
local GROUP_COUNT_BY_CONTENT_TYPE = {
    -- Parties (1 group = 5 players)
    [1]   = 1, -- Party Normal
    [2]   = 1, -- Party Heroic
    [8]   = 1, -- Party Mythic

    -- Raids
    [16]  = 4, -- Raid Mythic (20-player, 4 groups)
    [14]  = 6, -- Raid Normal (up to 30-player, 6 groups)
    [15]  = 6, -- Raid Heroic (up to 30-player, 6 groups)
    [9]   = 8, -- Raid 40-player
    [18]  = 8, -- Event 40-player

    -- LFR
    [7]   = 5, -- LFR (legacy)
    [17]  = 6, -- LFR
    [151] = 6, -- LFR

    -- Timewalking
    [33]  = 6, -- Timewalking Raid

    -- Legacy 10/25-player
    [3]   = 2, -- 10-player Normal
    [5]   = 2, -- 10-player Heroic
    [193] = 2, -- 10-player Heroic (alternate)
    [176] = 5, -- 25-player Normal
    [194] = 5, -- 25-player Heroic

    -- Classic
    [175] = 2, -- Classic 10-player
    [148] = 4, -- Classic 20-player
    [185] = 4, -- Classic 20-player (alternate)
    [186] = 8, -- Classic 40-player
}

local function iterateRaid(maxGroup, index)
    if index > GetNumGroupMembers() then
        return
    end

    local name, rank, subgroup, _, _, fileName,
        _, online, isDead, _, _, combatRole = GetRaidRosterInfo(index)

    if subgroup > maxGroup then
        return F.IterateRoster(maxGroup, index)
    end

    local unit = "raid" .. index
    local guid = UnitGUID(name or unit)
    name = name or ""

    return index, name, subgroup, fileName, guid,
        rank, nil, online, isDead, combatRole, unit
end

local function iterateParty(index)
    local unit = index == 1 and "player" or "party" .. (index - 1)
    local guid = UnitGUID(unit)

    if not guid then
        return
    end

    local name = GetUnitName(unit, true) or ""
    local _, fileName = UnitClass(unit)
    local rank = UnitIsGroupLeader(unit) and 2 or 1
    local level = UnitLevel(unit)
    local online = UnitIsConnected(unit) or nil
    local isDead = UnitIsDeadOrGhost(unit) or nil
    local combatRole = UnitGroupRolesAssigned(unit)

    return index, name, 1, fileName, guid,
        rank, level, online, isDead, combatRole, unit
end

function F.IterateRoster(maxGroup, index)
    index = (index or 0) + 1
    maxGroup = maxGroup or 8

    if IsInRaid() then
        return iterateRaid(maxGroup, index)
    end

    return iterateParty(index)
end

function F.GetRaidDiffMaxGroup()
    local _, instance_type, difficulty = GetInstanceInfo()

    if not IsInRaid() and (instance_type == "party" or
                           instance_type == "scenario") then
       return 1

    elseif instance_type ~= "raid" then
        return 8

    elseif difficulty and GROUP_COUNT_BY_CONTENT_TYPE[difficulty] then
    return GROUP_COUNT_BY_CONTENT_TYPE[difficulty]

    else
        return DEFAULT_RAID_GROUP_COUNT

    end
end

function F.chatType()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    end

    if IsInRaid() then
        return "RAID"
    end

    if IsInGroup() then
        return "PARTY"
    end

    return "SAY"
end

function F.shortName(fullName)
    local name = strsplit("-", fullName)

    return name
end
