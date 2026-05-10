local _, RCC = ...

RCC.RaidFrameMembers = RCC.RaidFrameMembers or {}
local Members = RCC.RaidFrameMembers

local F       = RCC.F
local Columns = RCC.RaidFrameColumns
local DATA_SOURCE = Columns.DATA_SOURCE

local GetTime = GetTime
local UnitName = UnitName

local function scanMemberColumnData(unit, now, layout, context)
    return Columns.ScanUnitData(unit, now, layout, context)
end

local function randomBool()
    return math.random() > 0.35
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
                state.rcStatus[unit] = context.readyCheck.pending
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


--------------------------------------------------------------------------------
--- Member Test Data
--------------------------------------------------------------------------------

local function applyTestAuraData(data, column)
    local hasAura = randomBool()

    data.has = hasAura
    data.auraID = nil

    if data.time ~= nil then
        data.time = hasAura and math.random(60, 3600) or 0
    end

    if data.iconID ~= nil or column.iconID then
        data.iconID = hasAura and column.iconID or nil
    end
end

local function applyTestRaidBuffData(data)
    data.has = randomBool()
    data.auraID = nil
end

local function createTestColumnData(layout)
    local columnData = Columns.CreateColumnData(layout)

    for columnIndex = 1, #layout.columns do
        local column = layout.columns[columnIndex]
        local data = columnData[column.key]

        if data then
            if column.dataSource == DATA_SOURCE.AURA then
                applyTestAuraData(data, column)
            elseif column.dataSource == DATA_SOURCE.RAID_BUFF then
                applyTestRaidBuffData(data)
            end
        end
    end

    return columnData
end

function Members.PopulateTestData(state, layout, context, broadcast)
    wipe(state.members)
    wipe(state.unitToIndex)
    wipe(state.rcStatus)
    broadcast:Reset()

    local playerName = F.unitFullName("player") or UnitName("player")
    local _, playerClass = UnitClass("player")

    state.members[1] = {
        name       = playerName,
        key        = F.fullName(playerName),
        unit       = "player",
        class      = playerClass,
        online     = true,
        isDead     = false,
        columnData = scanMemberColumnData("player", GetTime(), layout, context),
    }
    state.unitToIndex["player"] = 1
    state.rcStatus["player"] = context.readyCheck.ready

    local fakeMembers = RCC.raidFrameTest.generateTestMembers(playerClass)
    local count = 1

    for i = 1, #fakeMembers do
        count = count + 1

        local fm = fakeMembers[i]
        local fakeUnit = "raid" .. count
        local playerKey = F.fullName(fm.name)

        state.members[count] = {
            name       = playerKey,
            key        = playerKey,
            unit       = fakeUnit,
            class      = fm.class,
            online     = fm.online,
            isDead     = fm.isDead,
            columnData = createTestColumnData(layout),
        }

        state.unitToIndex[fakeUnit] = count
        state.rcStatus[fakeUnit] = context.readyCheck.pending

        broadcast:SetDurability(playerKey, fm.durability)

        if fm.oil then
            broadcast:SetOilStatus(playerKey, fm.oil)
        end
    end

    state.activeCount = count
end
