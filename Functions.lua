local _, RCC = ...
RCC.F = RCC.F or {}
F = RCC.F

local MAX_RAID_GROUP = 5

local DIFF_TO_MAX_GROUP = {
    [8] = 1,    --party mythic
    [1] = 1,    --party normal
    [2] = 1,    --party hc
    [14] = 6,   --raid normal
    [15] = 6,   --raid hc
    [16] = 4,   --raid mythic
    [3] = 2,    --10ppl
    [5] = 2,    --10ppl
    [9] = 8,    --40ppl
    [186] = 8,  --classic 40ppl
    [148] = 4,  --classic 20ppl
    [185] = 4,  --classic 20ppl
    [175] = 2,  --bc 10ppl
    [176] = 5,  --bc 25ppl
    [151] = 6,  --lfr
    [17] = 6,   --lfr
    [7] = 5,    --lfr [legacy]
    [33] = 6,   --timewalk raid
    [18] = 8,   --event 40ppl
    [193] = 2,  --10ppl hc
    [194] = 5,  --25ppl hc
}

function F.IterateRoster(maxGroup, index)
    index = (index or 0) + 1
    maxGroup = maxGroup or 8

    if IsInRaid() then
        if index > GetNumGroupMembers() then
            return
        end
        local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(index)
        if subgroup > maxGroup then
            return ExRT.F.IterateRoster(maxGroup,index)
        end
        local guid = UnitGUID(name or "raid"..index)
        name = name or ""
        return index, name, subgroup, fileName, guid, rank, level, online, isDead, combatRole, "raid"..index
        else
        local name, rank, subgroup, level, class, fileName, online, isDead, combatRole, _

        local unit = index == 1 and "player" or "party"..(index-1)

        local guid = UnitGUID(unit)
        if not guid then
            return
        end

        subgroup = 1
        name = GetUnitName(unit, true) or ""
        class, fileName = UnitClass(unit)

        if UnitIsGroupLeader(unit) then
            rank = 2
            else
            rank = 1
        end

        level = UnitLevel(unit)

        if UnitIsConnected(unit) then
            online = true
        end

        if UnitIsDeadOrGhost(unit) then
            isDead = true
        end

        combatRole = UnitGroupRolesAssigned(unit)

        return index, name, subgroup, fileName, guid, rank, level, online, isDead, combatRole, unit
    end
end

function F.GetRaidDiffMaxGroup()
    local _,instance_type,difficulty = GetInstanceInfo()
    if (instance_type == "party" or instance_type == "scenario") and not IsInRaid() then
        return 1
        elseif instance_type ~= "raid" then
        return 8
        elseif difficulty and DIFF_TO_MAX_GROUP[difficulty] then
        return DIFF_TO_MAX_GROUP[difficulty]
        else
        return MAX_RAID_GROUP
    end
end
