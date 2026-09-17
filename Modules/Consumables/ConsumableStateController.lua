local _, RCC = ...
local Controller = {}
RCC.ConsumableStateController = Controller

local Inputs = RCC.ConsumableInputs
local Runtime = RCC.ConsumableRuntime
local F = RCC.F
local DEFAULT_REFRESH_DELAY_SECONDS = 0.2
local NEXT_FRAME_DELAY_SECONDS = 0
local MIN_DEADLINE_DELAY_SECONDS = 0.02
local SOURCES = {
    "inventory",
    "preferences",
    "context",
    "spells",
    "weapons",
    "roster",
    "playerAuras",
    "groupAuras",
    "cooldowns",
}
local consumers, inputs, pending = {}, {}, {}
local runtime = Runtime.Create()
local latestSnapshot, refreshTimer, deadlineTimer
local refreshing, combatPending = false, false
local publishing = false
local sourceRevision = 0
local allItemIDs = {}

for _, definition in ipairs(RCC.ConsumableCatalog.GetDefinitions()) do
    for itemID in pairs(Inputs.GetItemIDs(definition.key)) do allItemIDs[itemID] = true end
end

local function hasActiveConsumer()
    for _, consumer in pairs(consumers) do
        if not consumer.IsActive or consumer:IsActive() then return true end
    end
    return false
end

local function merge(source, scope)
    scope = scope or true
    if pending[source] == true or scope == true then
        pending[source] = true
    else
        local values = pending[source] or {}
        for key in pairs(scope) do values[key] = true end
        pending[source] = values
    end
end

local function invalidateAll()
    for _, source in ipairs(SOURCES) do merge(source) end
end

local function cancelDeadline()
    if deadlineTimer then deadlineTimer:Cancel(); deadlineTimer = nil end
end

local function getRefreshDelay(options)
    if options and options.nextFrame == true then
        return NEXT_FRAME_DELAY_SECONDS
    end

    return DEFAULT_REFRESH_DELAY_SECONDS
end

local function schedule(delaySeconds)
    if refreshing or refreshTimer or not hasActiveConsumer() then return end
    refreshTimer = C_Timer.NewTimer(delaySeconds or DEFAULT_REFRESH_DELAY_SECONDS, function()
        refreshTimer = nil
        Controller.FlushPending()
    end)
end

-- Omit options.scope to refresh the full source; otherwise supply an item-ID
-- or unit-token set. nextFrame skips the normal delay when scheduling a new
-- batch. An already scheduled batch keeps its timing and includes this change.
function Controller.Invalidate(source, options)
    merge(source, options and options.scope)
    schedule(getRefreshDelay(options))
end

local function storeInput(key, value)
    if not Inputs.Equal(inputs[key], value) then
        inputs[key] = value
        sourceRevision = sourceRevision + 1
    end
end

local function readInputs(dirty, now)
    -- Fixed topological order: context/roster -> observations; inventory ->
    -- cooldowns; applied enchant -> saved preference -> category selection.
    local resetGroup = dirty.groupAuras == true
    if dirty.context then
        local context = Inputs.ReadContext()
        if not Inputs.Equal(inputs.context, context) then
            storeInput("context", context)
            resetGroup = true
            dirty.playerAuras = true
        end
    end
    if dirty.inventory then
        storeInput("inventory", Inputs.ReadInventory(allItemIDs, inputs.inventory,
            type(dirty.inventory) == "table" and dirty.inventory or nil))
        dirty.cooldowns = true
    end
    if dirty.spells then storeInput("spells", Inputs.ReadSpells()) end
    if dirty.weapons then
        storeInput("weapons", Inputs.ReadWeapons(now))
        Inputs.RememberAppliedEnchants(inputs.weapons)
        dirty.preferences = true
    end
    if dirty.preferences then storeInput("preferences", Inputs.ReadPreferences()) end

    local groupUnits = type(dirty.groupAuras) == "table" and dirty.groupAuras or {}
    if dirty.roster then
        local roster = Inputs.ReadRoster()
        if dirty.roster == true then
            resetGroup = true
        else
            for unit, member in pairs(roster.units) do
                if not inputs.roster or not Inputs.Equal(member, inputs.roster.units[unit]) then groupUnits[unit] = true end
            end
        end
        storeInput("roster", roster)
    end
    if dirty.playerAuras then storeInput("playerAuras", RCC.HelpfulAuraScan.ScanUnit("player")) end
    if resetGroup or next(groupUnits) or dirty.roster then
        local previous = inputs.groupAuras
        if resetGroup then previous, groupUnits = nil, nil end
        storeInput("groupAuras", Inputs.ReadGroupAuras(inputs.roster, inputs.context, previous, groupUnits, now,
            dirty.playerAuras and inputs.playerAuras or nil))
    end
    if dirty.cooldowns then storeInput("cooldowns", Inputs.ReadCooldowns(inputs.inventory, now)) end
end

local function publish(snapshot)
    if publishing then return end
    publishing = true
    for _, consumer in pairs(consumers) do
        if (not consumer.IsActive or consumer:IsActive()) and consumer.ApplySnapshot then
            consumer:ApplySnapshot(snapshot)
        end
    end
    publishing = false
end

local function scheduleDeadline()
    cancelDeadline()
    if not hasActiveConsumer() then return end
    local deadline = Runtime.GetDeadline(runtime)
    if deadline then
        deadlineTimer = C_Timer.NewTimer(math.max(MIN_DEADLINE_DELAY_SECONDS, deadline - GetTime()), function()
            deadlineTimer = nil
            Controller.FlushPending()
        end)
    end
end

function Controller.FlushPending(force)
    if refreshing or publishing then return false end
    if refreshTimer then refreshTimer:Cancel(); refreshTimer = nil end
    if not force and not hasActiveConsumer() then cancelDeadline(); return false end
    if not latestSnapshot then invalidateAll() end

    local now = GetTime()
    local due, expiredSources = Runtime.GetDue(runtime, now)
    for source in pairs(expiredSources) do merge(source) end
    if not next(pending) and not next(due) and latestSnapshot then return false end

    -- Detach before querying/publishing: invalidations raised during this pass
    -- belong to the next batch, never to a table we're about to wipe.
    local dirty = pending
    pending = {}
    refreshing = true
    local previousRevision = sourceRevision
    readInputs(dirty, now)
    if latestSnapshot and previousRevision == sourceRevision and not next(due) then
        refreshing = false
        scheduleDeadline()
        if next(pending) then schedule() end
        return false
    end
    latestSnapshot = Runtime.Build(runtime, inputs, now, due)
    publish(latestSnapshot)
    refreshing = false
    scheduleDeadline()
    if next(pending) then schedule() end
    return true
end

-- Full refresh is an explicit opening/re-enabling boundary, not the default
-- event path. Cached state remains complete for consumers that were hidden.
function Controller.RefreshNow(force)
    -- A consumer may open/reflow itself while receiving this very snapshot.
    -- It must not recursively publish or schedule another full read.
    if refreshing or publishing then return false end
    if force then invalidateAll() end
    local changed = Controller.FlushPending(force)
    if not changed and latestSnapshot and hasActiveConsumer() then publish(latestSnapshot) end
    return changed
end

function Controller.RequestRefresh(options)
    invalidateAll()
    if options and options.force == true then
        -- Force requests still batch; login/settings initialization can occur
        -- before a visible consumer exists.
        if refreshTimer then refreshTimer:Cancel() end
        refreshTimer = C_Timer.NewTimer(getRefreshDelay(options), function()
            refreshTimer = nil
            Controller.FlushPending(true)
        end)
    else
        schedule(getRefreshDelay(options))
    end
end

function Controller.PrepareOutOfCombat()
    if InCombatLockdown() then return false end
    if combatPending then
        combatPending = false
        invalidateAll()
    end
    return Controller.FlushPending()
end

function Controller.RegisterConsumer(key, consumer)
    consumers[key] = consumer
    -- Consumers also register while the TOC is loading, before saved settings
    -- and later modules are ready. Login owns the first live observation.
    if latestSnapshot and (not consumer.IsActive or consumer:IsActive()) then
        consumer:ApplySnapshot(latestSnapshot)
        Controller.RequestRefresh({ nextFrame = true, force = true })
    end
    return true
end

function Controller.UnregisterConsumer(key)
    consumers[key] = nil
    if not hasActiveConsumer() then cancelDeadline() end
end

function Controller.GetLatestSnapshot()
    return latestSnapshot
end

local function rosterUnit(unit)
    if issecretvalue(unit) or type(unit) ~= "string" then return end
    if not inputs.roster then return end
    if inputs.roster.units[unit] then return unit end
    -- UNIT_AURA can name the player's raid token instead of "player".
    for token in pairs(inputs.roster.units) do
        if F.UnitIsUnitSafe(unit, token) then return token end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        Controller.RequestRefresh({ nextFrame = true, force = true })
    elseif event == "PLAYER_ENTERING_WORLD" then
        invalidateAll()
        schedule(NEXT_FRAME_DELAY_SECONDS)
    elseif event == "PLAYER_REGEN_DISABLED" then
        combatPending = true
        -- Refresh public data and reapply the combat visual policy immediately.
        invalidateAll()
        if hasActiveConsumer() then
            local changed = Controller.FlushPending()
            if not changed and latestSnapshot then publish(latestSnapshot) end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        Controller.PrepareOutOfCombat()
        if latestSnapshot then publish(latestSnapshot) end
    elseif event == "UNIT_AURA" or event == "UNIT_AURA_BLOCKED" or event == "UNIT_AURA_BLOCK_LIST_CLEARED" then
        if F.UnitIsUnitSafe(unit, "player") then Controller.Invalidate("playerAuras") end
        local token = rosterUnit(unit)
        if token then
            Controller.Invalidate("groupAuras", { scope = { [token] = true } })
        end
    elseif event == "UNIT_CONNECTION" or event == "UNIT_FLAGS" or event == "UNIT_PHASE" then
        local token = rosterUnit(unit)
        if token then
            Controller.Invalidate("roster", { scope = { [token] = true } })
            Controller.Invalidate("groupAuras", { scope = { [token] = true } })
        end
    elseif event == "UNIT_HEALTH" then
        -- Dead/ghost members are excluded from the raid-buff check. Watch only
        -- life-state transitions so resurrected members rejoin that check;
        -- ordinary damage/healing must not invalidate the cached observations.
        if not hasActiveConsumer() then return end
        if not inputs.context or not inputs.context.raidBuff then return end

        local token = rosterUnit(unit)
        if not token then return end

        local alive = Inputs.ReadLifeState(token)
        if alive ~= inputs.roster.units[token].alive then
            Controller.Invalidate("roster", { scope = { [token] = true } })
            Controller.Invalidate("groupAuras", { scope = { [token] = true } })
        end
    elseif event == "UNIT_IN_RANGE_UPDATE" then
        local token = rosterUnit(unit)
        if token then
            Controller.Invalidate("groupAuras", { scope = { [token] = true } })
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        Controller.Invalidate("roster")
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_DIFFICULTY_CHANGED" then
        Controller.Invalidate("context")
        Controller.Invalidate("roster")
    elseif event == "BAG_UPDATE_DELAYED" then
        Controller.Invalidate("inventory")
    elseif event == "ITEM_COUNT_CHANGED" or event == "ITEM_DATA_LOAD_RESULT" then
        if F.IsSafeNumber(unit) and allItemIDs[unit] then
            Controller.Invalidate("inventory", { scope = { [unit] = true } })
        end
    elseif event == "BAG_UPDATE_COOLDOWN" then
        Controller.Invalidate("cooldowns")
    elseif event == "WEAPON_ENCHANT_CHANGED" or event == "WEAPON_SLOT_CHANGED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        Controller.Invalidate("weapons")
    elseif event == "UNIT_INVENTORY_CHANGED" then
        if F.UnitIsUnitSafe(unit, "player") then Controller.Invalidate("weapons") end
    elseif event == "SPELLS_CHANGED" or event == "SPELL_DATA_LOAD_RESULT" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        if event ~= "PLAYER_SPECIALIZATION_CHANGED" or F.UnitIsUnitSafe(unit, "player") then
            Controller.Invalidate("spells")
            Controller.Invalidate("context")
            Controller.Invalidate("weapons")
        end
    end
end)

-- Lifecycle and combat reconciliation.
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

-- Player and group aura observations.
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("UNIT_AURA_BLOCKED")
eventFrame:RegisterEvent("UNIT_AURA_BLOCK_LIST_CLEARED")

-- Roster membership and raid-buff eligibility.
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("UNIT_CONNECTION")
eventFrame:RegisterEvent("UNIT_FLAGS")
eventFrame:RegisterEvent("UNIT_PHASE")
eventFrame:RegisterEvent("UNIT_IN_RANGE_UPDATE")
eventFrame:RegisterEvent("UNIT_HEALTH") -- Death/resurrection only; no health values read.

-- Instance-dependent selection and warning thresholds.
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")

-- Item availability, metadata, and repair cooldowns.
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("ITEM_COUNT_CHANGED")
eventFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")

-- Equipped weapons and their temporary enchants.
eventFrame:RegisterEvent("WEAPON_ENCHANT_CHANGED")
eventFrame:RegisterEvent("WEAPON_SLOT_CHANGED")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")

-- Known spell choices and specialization-dependent slot rules.
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("SPELL_DATA_LOAD_RESULT")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
