local _, RCC = ...

RCC.RaidFrameMembers = RCC.RaidFrameMembers or {}
local Members = RCC.RaidFrameMembers

local F       = RCC.F
local Columns = RCC.RaidFrameColumns

local GetTime = GetTime

local function scanMemberColumnData(unit, now, layout, context)
    return Columns.ScanUnitData(unit, now, layout, context)
end

function Members.ScanAll(state, layout, context)
    local session = state.readyCheck

    -- Preview rows already contain synthetic consumable data. Never replace it
    -- by scanning their fake unit tokens during a settings/provision refresh.
    if session and session.synthetic then
        return
    end

    local now = GetTime()
    local count = 0

    wipe(state.members)
    wipe(state.unitToIndex)

    local function addMember(name, unit, class, online)
        count = count + 1

        local isDead    = UnitIsDeadOrGhost(unit)
        local playerKey = F.fullName(name)

        state.members[count] = {
            name       = name,
            key        = playerKey,
            unit       = unit,
            class      = class,
            online     = online,
            isDead     = isDead,
            columnData = scanMemberColumnData(unit, now, layout, context),
        }

        state.unitToIndex[unit] = count
    end

    if session then
        -- Ready-check rows follow the controller's roster, including its frozen
        -- final result. Provision-only displays use the current group instead.
        for i = 1, #session.members do
            local member = session.members[i]

            addMember(member.name, member.unit, member.class, member.online)
        end
    else
        F.ForEachActiveRosterMember(function(name, unit, _subgroup, class, online)
            addMember(name, unit, class, online)
        end)
    end

    state.activeCount = count
end

function Members.RefreshFromUnit(state, unit, layout, context)
    local index = state.unitToIndex[unit]

    if not index then
        return nil
    end

    local member = state.members[index]

    if not member then
        return nil
    end

    member.online     = UnitIsConnected(unit)
    member.isDead     = UnitIsDeadOrGhost(unit)
    member.columnData = scanMemberColumnData(unit, GetTime(), layout, context)

    return index, member
end
