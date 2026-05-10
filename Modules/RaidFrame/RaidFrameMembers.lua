local _, RCC = ...

RCC.RaidFrameMembers = RCC.RaidFrameMembers or {}
local Members = RCC.RaidFrameMembers

local F       = RCC.F
local Columns = RCC.RaidFrameColumns
local ReadyCheck = RCC.RaidFrameReadyCheck

local GetTime = GetTime

local function scanMemberColumnData(unit, now, layout, context)
    return Columns.ScanUnitData(unit, now, layout, context)
end

function Members.ScanAll(state, layout, context)
    local maxGroup = F.GetRaidDiffMaxGroup()
    local now = GetTime()
    local count = 0

    wipe(state.members)
    wipe(state.unitToIndex)

    for j = 1, 40 do
        local name, unit, subgroup, class = F.GetRosterInfo(j)

        if not name then
            if not IsInRaid() then
                break
            end
        elseif subgroup <= maxGroup then
            count = count + 1

            local online    = UnitIsConnected(unit)
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

            if not state.rcStatus[unit] then
                state.rcStatus[unit] = ReadyCheck.PENDING
            end
        end
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
