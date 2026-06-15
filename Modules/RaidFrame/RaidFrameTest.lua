local _, RCC = ...

RCC.RaidFrameTest = RCC.RaidFrameTest or {}
local Test = RCC.RaidFrameTest

local F = RCC.F
local Cauldron = RCC.RaidFrameCauldron
local Columns = RCC.RaidFrameColumns
local COLUMN_TYPE = Columns.COLUMN_TYPE
local DATA_SOURCE = Columns.DATA_SOURCE
local ReadyCheck = RCC.RaidFrameReadyCheck

local GetTime = GetTime
local UnitName = UnitName
local UnitClass = UnitClass

--------------------------------------------------------------------------------
--- Constants / Test data
--------------------------------------------------------------------------------

local ALL_CLASSES = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK",
    "DRUID", "DEMONHUNTER", "EVOKER",
}

local TEST_NAMES = {
    "Thunderclap", "Lightforge", "Windrunner", "Shadowstep", "Faithweaver",
    "Frostmourne", "Tidecaller", "Frostbolt", "Felblood", "Mistwalker",
    "Moonfire", "Havocblade", "Scalewing",
}

--------------------------------------------------------------------------------
--- Timer lifecycle
--------------------------------------------------------------------------------

local function cancelTimers(self)
    self.timers = self.timers or {}

    for i = 1, #self.timers do
        self.timers[i]:Cancel()
    end

    wipe(self.timers)
end

local function invalidateRun(self)
    self.runID = (self.runID or 0) + 1
end

local function addTimer(self, runID, delay, callback)
    local timer = C_Timer.NewTimer(delay, function()
        if self.runID ~= runID or not self.active then
            return
        end

        callback()
    end)

    self.timers[#self.timers + 1] = timer
end

--------------------------------------------------------------------------------
--- Synthetic member generation
--------------------------------------------------------------------------------

local function randomBool()
    return math.random() > 0.35
end

local function generateTempWeaponEnchantData()
    local roll = math.random()

    if roll < 0.5 then
        return {
            time    = math.random(60, 3600),
            itemID  = 0,
            iconID  = RCC.db.weaponEnchantIconID,
            spellID = 0,
        }
    end

    if roll < 0.7 then
        return { time = 0, itemID = 0 }
    end

    if roll < 0.85 then
        return { time = -1, itemID = 0 }
    end

    return nil
end

local function generateSyntheticMembers(excludeClass)
    local members = {}

    for i = 1, #ALL_CLASSES do
        if ALL_CLASSES[i] ~= excludeClass then
            members[#members + 1] = {
                name              = TEST_NAMES[i],
                class             = ALL_CLASSES[i],
                online            = math.random() > 0.1,
                isDead            = math.random() > 0.9,
                durability        = math.random(10, 100),
                tempWeaponEnchant = generateTempWeaponEnchantData(),
            }
        end
    end

    return members
end

local function applySyntheticAuraData(data, column)
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

local function applySyntheticRaidBuffData(data)
    data.has = randomBool()
    data.auraID = nil
end

local function copySyntheticColumnData(data)
    local copy = {}

    for key, value in pairs(data) do
        if key ~= "auraID" then
            if type(value) == "table" then
                copy[key] = copySyntheticColumnData(value)
            else
                copy[key] = value
            end
        end
    end

    return copy
end

local function playerColumnIsGood(playerMember, context, column)
    if not playerMember or not column.IsBad then
        return false
    end

    return not column.IsBad(playerMember, context, column)
end

local function shouldMirrorPlayerColumn(column)
    return column.columnType == COLUMN_TYPE.ICON
        or column.columnType == COLUMN_TYPE.RAID_BUFF
end

local function createSyntheticColumnData(layout, context, playerMember)
    local columnData = Columns.CreateColumnData(layout)

    for columnIndex = 1, #layout.columns do
        local column = layout.columns[columnIndex]
        local data = columnData[column.key]
        local playerData = playerMember
            and playerMember.columnData
            and playerMember.columnData[column.key]

        if data then
            if shouldMirrorPlayerColumn(column)
                and playerData
                and playerColumnIsGood(playerMember, context, column)
            then
                columnData[column.key] = copySyntheticColumnData(playerData)
            elseif column.dataSource == DATA_SOURCE.AURA then
                applySyntheticAuraData(data, column)
            elseif column.dataSource == DATA_SOURCE.RAID_BUFF then
                applySyntheticRaidBuffData(data)
            end
        end
    end

    return columnData
end

local function populateSyntheticState(self)
    local env = self.env
    local state = env.state
    local layout = env.layout
    local context = env.context
    local broadcast = env.broadcast
    local includeCauldrons = self.includeCauldrons == true

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
        columnData = Columns.ScanUnitData("player", GetTime(), layout, context),
    }
    state.unitToIndex["player"] = 1
    state.rcStatus["player"] = ReadyCheck.READY

    if includeCauldrons and Cauldron then
        Cauldron.SetSyntheticTestEntry(state.members[1].key, 1)
    end

    local fakeMembers = generateSyntheticMembers(playerClass)
    local count = 1

    for i = 1, #fakeMembers do
        count = count + 1

        local member = fakeMembers[i]
        local fakeUnit = "rccTest" .. count
        local playerKey = F.fullName(member.name)

        state.members[count] = {
            name       = playerKey,
            key        = playerKey,
            unit       = fakeUnit,
            class      = member.class,
            online     = member.online,
            isDead     = member.isDead,
            columnData = createSyntheticColumnData(layout, context, state.members[1]),
        }

        state.unitToIndex[fakeUnit] = count
        state.rcStatus[fakeUnit] = ReadyCheck.PENDING

        if includeCauldrons and Cauldron then
            Cauldron.SetSyntheticTestEntry(playerKey, count)
        end

        broadcast:SetDurability(playerKey, member.durability)

        if member.tempWeaponEnchant then
            broadcast:SetTempWeaponEnchantStatus(
                playerKey,
                member.tempWeaponEnchant
            )
        end
    end

    state.activeCount = count
end

--------------------------------------------------------------------------------
--- Synthetic ready-check session
--------------------------------------------------------------------------------

local function scheduleSyntheticResponses(self, runID, duration)
    local state = self.env.state
    local frame = self.env.frame

    for unit in pairs(state.unitToIndex) do
        if unit ~= "player" then
            local roll = math.random()

            if roll > 0.25 then
                local delay = math.random(1, duration)
                local ready = roll > 0.5

                addTimer(self, runID, delay, function()
                    if frame:IsShown() then
                        frame:OnReadyCheckConfirm(unit, ready)
                    end
                end)
            end
        end
    end
end

--------------------------------------------------------------------------------
--- Export
--------------------------------------------------------------------------------

function Test:Attach(env)
    self.env = env
    self.timers = self.timers or {}
    self.runID = self.runID or 0
    self.active = self.active or false
end

function Test:Cancel()
    invalidateRun(self)
    cancelTimers(self)
    self.active = false
end

function Test:Stop()
    local wasActive = self.active

    self:Cancel()

    if self.env and self.env.frame then
        self.env.frame:Hide()
    end

    return wasActive
end

function Test:Finish()
    if not self.active then
        return
    end

    self.active = false
    invalidateRun(self)
    cancelTimers(self)

    if self.env and self.env.frame and self.env.frame:IsShown() then
        self.env.frame:OnReadyCheckFinished()
    end
end

function Test:Start(permanent, duration, options)
    local env = self.env

    if not env or InCombatLockdown() then
        return false
    end

    duration = duration or 15

    self:Cancel()

    local runID = self.runID
    self.active = true
    self.includeCauldrons = options
        and options.includeCauldrons == true
        and Cauldron
        and Cauldron.BeginSyntheticTestData()
        or false

    env.beginDisplay(permanent or false, {
        includeCauldrons = self.includeCauldrons,
    })
    populateSyntheticState(self)
    env.broadcast:SendDurability()
    env.broadcast:SendTempWeaponEnchantStatus()
    env.showDisplay(duration, true)

    scheduleSyntheticResponses(self, runID, duration)

    return true
end

function Test:StartCauldronOnly()
    local env = self.env

    if not env
        or not env.beginCauldron
        or not env.showCauldron
        or InCombatLockdown()
        or not Cauldron
    then
        return false
    end

    self:Cancel()
    self.active = true
    self.includeCauldrons = Cauldron.BeginSyntheticTestData()

    if not self.includeCauldrons then
        self.active = false

        return false
    end

    env.beginCauldron()
    populateSyntheticState(self)
    env.showCauldron()

    return true
end
