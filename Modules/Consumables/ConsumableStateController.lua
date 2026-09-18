local _, RCC = ...
local Controller = {}
RCC.ConsumableStateController = Controller

local Inputs = RCC.ConsumableInputs
local Runtime = RCC.ConsumableRuntime
local Demand = RCC.ConsumableDemand
local F = RCC.F
local DEFAULT_REFRESH_DELAY_SECONDS = 0.2
local NEXT_FRAME_DELAY_SECONDS = 0
local MIN_DEADLINE_DELAY_SECONDS = 0.02
local consumers, inputs, pending = {}, {}, {}
local runtime = Runtime.Create()
local demand = Demand.Build({})
local latestSnapshot, refreshTimer, deadlineTimer
local refreshing, combatPending = false, false
local publishing = false
local sourceRevision = 0
local demandDirty, refreshRequested = false, false
local eventFrame = CreateFrame("Frame")

local function setEventEnabled(event, enabled)
    if enabled then
        eventFrame:RegisterEvent(event)
    else
        eventFrame:UnregisterEvent(event)
    end
end

local function updateEventSubscriptions()
    local sources = demand.sources

    -- playerAuras / groupAuras: both use the same aura notifications. The
    -- handler routes each affected unit to the requested player/group input.
    local auras = sources.playerAuras or sources.groupAuras
    setEventEnabled("UNIT_AURA", auras)
    setEventEnabled("UNIT_AURA_BLOCKED", auras)
    setEventEnabled("UNIT_AURA_BLOCK_LIST_CLEARED", auras)

    -- roster: group membership/composition, also needed by Healthstone's
    -- Warlock check even when no group-aura checks are requested.
    setEventEnabled("GROUP_ROSTER_UPDATE", sources.roster)

    -- groupAuras: changes to whether a member can be checked. These may also
    -- refresh that member's roster eligibility; health events only matter when
    -- alive/dead state changes, not on ordinary damage or healing.
    setEventEnabled("UNIT_CONNECTION", sources.groupAuras)
    setEventEnabled("UNIT_FLAGS", sources.groupAuras)
    setEventEnabled("UNIT_PHASE", sources.groupAuras)
    setEventEnabled("UNIT_IN_RANGE_UPDATE", sources.groupAuras)
    setEventEnabled("UNIT_HEALTH", sources.groupAuras)

    -- inventory: carried item counts and asynchronously loaded item metadata.
    setEventEnabled("BAG_UPDATE_DELAYED", sources.inventory)
    setEventEnabled("ITEM_COUNT_CHANGED", sources.inventory)
    setEventEnabled("ITEM_DATA_LOAD_RESULT", sources.inventory)

    -- cooldowns: repair-device availability, separate from inventory counts.
    setEventEnabled("BAG_UPDATE_COOLDOWN", sources.cooldowns)

    -- weapons: equipped weapons, slot applicability, and temporary enchants.
    setEventEnabled("WEAPON_ENCHANT_CHANGED", sources.weapons)
    setEventEnabled("WEAPON_SLOT_CHANGED", sources.weapons)
    setEventEnabled("PLAYER_EQUIPMENT_CHANGED", sources.weapons)
    setEventEnabled("UNIT_INVENTORY_CHANGED", sources.weapons)

    -- location: local map/venue changes affect item selection only. They do
    -- not refresh instance rules, inventory counts, or aura observations.
    setEventEnabled("ZONE_CHANGED", sources.location)
    setEventEnabled("ZONE_CHANGED_INDOORS", sources.location)

    -- spells / class / weapons: shared notifications for known enchant spells,
    -- class-provided raid-buff metadata, and equipped enchant state. Each input
    -- is refreshed only if requested; these do not request player aura scans.
    local spellChanges = sources.spells or sources.class or sources.weapons
    setEventEnabled("SPELLS_CHANGED", spellChanges)
    setEventEnabled("SPELL_DATA_LOAD_RESULT", spellChanges)
    setEventEnabled("PLAYER_SPECIALIZATION_CHANGED", spellChanges)

    -- instance / location / roster / auras: major transitions deliberately
    -- refresh all requested inputs in this group, even if the instance ID/type
    -- stays the same. This is separate from location-only movement above.
    local majorTransitions = sources.instance or sources.location or sources.roster or auras
    setEventEnabled("ZONE_CHANGED_NEW_AREA", majorTransitions)
    setEventEnabled("PLAYER_DIFFICULTY_CHANGED", majorTransitions)

    -- preferences has no game-event subscription; RCC's item-choice/settings
    -- code invalidates it directly when a saved preference changes.
end

local function hasDemand()
    return next(demand.categories) ~= nil
end

local function merge(source, scope)
    if not demand.sources[source] then return end

    scope = scope or true

    if pending[source] == true or scope == true then
        pending[source] = true
    else
        local values = pending[source] or {}

        for key in pairs(scope) do
            values[key] = true
        end

        pending[source] = values
    end
end

local function invalidateAll()
    for source in pairs(demand.sources) do
        merge(source)
    end
end

local function reconcileDemand()
    local categories = {}
    local consumersChanged = false

    for _, entry in pairs(consumers) do
        local requested = entry.consumer:GetCategories()

        if not Inputs.Equal(entry.categories, requested) then
            entry.categories = requested
            entry.dirty = true
        end

        consumersChanged = consumersChanged or entry.dirty

        for key in pairs(requested) do
            categories[key] = true
        end
    end

    if Inputs.Equal(demand.categories, categories) then
        return false, consumersChanged
    end

    demand = Demand.Build(categories)
    Runtime.RetainCategories(runtime, categories)

    for source in pairs(inputs) do
        if not demand.sources[source] then
            inputs[source] = nil
        end
    end

    for source in pairs(pending) do
        if not demand.sources[source] then
            pending[source] = nil
        end
    end

    updateEventSubscriptions()

    -- Opening/enabling is a fresh-read boundary. This also trims inventory and
    -- weapon snapshots to the new union, without retaining disabled deadlines.
    invalidateAll()

    return true, consumersChanged
end

local function cancelDeadline()
    if deadlineTimer then
        deadlineTimer:Cancel()
        deadlineTimer = nil
    end
end

local function getRefreshDelay(options)
    if options and options.nextFrame == true then
        return NEXT_FRAME_DELAY_SECONDS
    end

    return DEFAULT_REFRESH_DELAY_SECONDS
end

local function schedule(delaySeconds)
    if refreshing or refreshTimer or (not hasDemand() and not demandDirty) then
        return
    end

    refreshTimer = C_Timer.NewTimer(delaySeconds or DEFAULT_REFRESH_DELAY_SECONDS, function()
        refreshTimer = nil
        Controller.FlushPending()
    end)
end

-- Omit options.scope to refresh the full source; otherwise supply an item-ID
-- or unit-token set. nextFrame skips the normal delay when scheduling a new
-- batch. An already scheduled batch keeps its timing and includes this change.
function Controller.Invalidate(source, options)
    if not demand.sources[source] then return end

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
    -- Fixed topological order: class/roster -> group observations; inventory ->
    -- cooldowns; applied enchant -> saved preference -> category selection.
    local resetGroup = dirty.groupAuras == true

    -- These inputs affect selection/evaluation, not aura freshness. Major
    -- transitions request their aura reads explicitly in the event handler.
    if dirty.instance then
        storeInput("instance", Inputs.ReadInstance())
    end

    if dirty.location then
        storeInput("location", Inputs.ReadLocation())
    end

    if dirty.class then
        local class = Inputs.ReadClass()

        if not Inputs.Equal(inputs.class, class) then
            storeInput("class", class)

            -- Group observations describe the buff supplied by this class.
            resetGroup = true
        end
    end

    if dirty.inventory then
        storeInput("inventory", Inputs.ReadInventory(
            demand.itemIDs,
            inputs.inventory,
            type(dirty.inventory) == "table" and dirty.inventory or nil
        ))
        dirty.cooldowns = demand.sources.cooldowns
    end

    if dirty.spells then
        storeInput("spells", Inputs.ReadSpells())
    end

    if dirty.weapons then
        storeInput("weapons", Inputs.ReadWeapons(now, demand.weaponSlots))
        Inputs.RememberAppliedEnchants(inputs.weapons)
        dirty.preferences = demand.sources.preferences
    end

    if dirty.preferences then
        storeInput("preferences", Inputs.ReadPreferences())
    end

    local groupUnits = type(dirty.groupAuras) == "table" and dirty.groupAuras or {}

    if dirty.roster then
        local roster = Inputs.ReadRoster()

        if dirty.roster == true then
            resetGroup = true
        else
            for unit, member in pairs(roster.units) do
                if not inputs.roster or not Inputs.Equal(member, inputs.roster.units[unit]) then
                    groupUnits[unit] = true
                end
            end
        end

        storeInput("roster", roster)
    end

    if dirty.playerAuras then
        storeInput("playerAuras", RCC.HelpfulAuraScan.ScanUnit("player"))
    end

    if demand.sources.groupAuras and (resetGroup or next(groupUnits) or dirty.roster) then
        local previous = inputs.groupAuras

        if resetGroup then
            previous, groupUnits = nil, nil
        end

        storeInput("groupAuras", Inputs.ReadGroupAuras(
            inputs.roster,
            inputs.class,
            previous,
            groupUnits,
            now,
            dirty.playerAuras and inputs.playerAuras or nil
        ))
    end

    if dirty.cooldowns then
        storeInput("cooldowns", Inputs.ReadCooldowns(inputs.inventory, now))
    end
end

local function publish(snapshot, includeInactive)
    if publishing then return end

    publishing = true

    for _, entry in pairs(consumers) do
        if next(entry.categories) or entry.dirty or includeInactive then
            entry.dirty = false
            entry.consumer:ApplySnapshot(snapshot, entry.categories)
        end
    end

    publishing = false

    if demandDirty then
        schedule(NEXT_FRAME_DELAY_SECONDS)
    end
end

local function scheduleDeadline()
    cancelDeadline()

    if not hasDemand() then return end

    local deadline = Runtime.GetDeadline(runtime)

    if deadline then
        deadlineTimer = C_Timer.NewTimer(math.max(MIN_DEADLINE_DELAY_SECONDS, deadline - GetTime()), function()
            deadlineTimer = nil
            Controller.FlushPending()
        end)
    end
end

function Controller.FlushPending(forceRefresh)
    if refreshing or publishing then return false end

    if refreshTimer then
        refreshTimer:Cancel()
        refreshTimer = nil
    end

    local categoriesChanged, consumersChanged = false, false

    if demandDirty or forceRefresh or not latestSnapshot then
        demandDirty = false
        categoriesChanged, consumersChanged = reconcileDemand()
    end

    if forceRefresh or refreshRequested then
        invalidateAll()
    end

    refreshRequested = false

    local now = GetTime()
    local due, expiredSources = Runtime.GetDue(runtime, now)

    for source in pairs(expiredSources) do
        merge(source)
    end

    if not next(pending) and not next(due) and latestSnapshot and not categoriesChanged then
        if consumersChanged then
            publish(latestSnapshot)
        end

        scheduleDeadline()

        if demandDirty then
            schedule(NEXT_FRAME_DELAY_SECONDS)
        end

        return consumersChanged
    end

    -- Detach before querying/publishing: invalidations raised during this pass
    -- belong to the next batch, never to a table we're about to wipe.
    local dirty = pending
    pending = {}
    refreshing = true
    local previousRevision = sourceRevision
    readInputs(dirty, now)

    if latestSnapshot and not categoriesChanged and previousRevision == sourceRevision and not next(due) then
        if consumersChanged then
            publish(latestSnapshot)
        end

        refreshing = false
        scheduleDeadline()

        if next(pending) or demandDirty then
            schedule()
        end

        return consumersChanged
    end

    latestSnapshot = Runtime.Build(runtime, inputs, now, due, demand.categories)
    publish(latestSnapshot)
    refreshing = false
    scheduleDeadline()

    if next(pending) or demandDirty then
        schedule()
    end

    return true
end

-- Full refresh is an explicit opening/re-enabling boundary, not the default
-- event path. It reads only requested inputs, even when force is true.
function Controller.RefreshNow(force)
    -- A consumer may open itself while receiving this very snapshot. Retain
    -- the request for a trailing pass rather than recursively reading/publishing.
    if refreshing or publishing then
        demandDirty = true

        if force then
            refreshRequested = true
        end

        return false
    end

    local changed = Controller.FlushPending(force)

    if not changed and latestSnapshot then
        publish(latestSnapshot)
    end

    return changed
end

-- Visibility/settings can change without an input event, including while a
-- consumer is applying a snapshot. Preserve a trailing demand reconciliation.
function Controller.RefreshDemand()
    demandDirty = true

    if refreshing or publishing then return false end

    return Controller.FlushPending()
end

function Controller.RequestRefresh(options)
    demandDirty = true
    refreshRequested = true
    schedule(getRefreshDelay(options))
end

function Controller.PrepareOutOfCombat()
    if InCombatLockdown() then return false end

    if combatPending then
        combatPending = false
        demandDirty = true
        refreshRequested = true
    end

    return Controller.FlushPending()
end

function Controller.RegisterConsumer(key, consumer)
    consumers[key] = { consumer = consumer, categories = {}, dirty = true }

    -- Consumers register while the TOC is loading, before saved settings and
    -- later modules are ready. Surface initialization/login starts observation.
    if latestSnapshot then
        Controller.RequestRefresh({ nextFrame = true })
    end

    return true
end

function Controller.UnregisterConsumer(key)
    consumers[key] = nil
    Controller.RefreshDemand()
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

eventFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        Controller.RequestRefresh({ nextFrame = true })
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Loading screens are a full freshness boundary, including returns to
        -- the same instance. RequestRefresh reads only currently needed inputs.
        Controller.RequestRefresh({ nextFrame = true })
    elseif event == "PLAYER_REGEN_DISABLED" then
        combatPending = true
        -- Refresh public data and reapply the combat visual policy immediately.
        Controller.RefreshNow(true)
    elseif event == "PLAYER_REGEN_ENABLED" then
        Controller.PrepareOutOfCombat()
        -- Hidden temporary surfaces may still need to release actions that
        -- could not be cleared when their demand ended during combat.
        if latestSnapshot then
            publish(latestSnapshot, true)
        end
    elseif event == "UNIT_AURA"
        or event == "UNIT_AURA_BLOCKED"
        or event == "UNIT_AURA_BLOCK_LIST_CLEARED"
    then
        if demand.sources.playerAuras and F.UnitIsUnitSafe(unit, "player") then
            Controller.Invalidate("playerAuras")
        end

        local token = demand.sources.groupAuras and rosterUnit(unit)

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
        if not inputs.class or not inputs.class.raidBuff then return end

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
        -- Travel/difficulty changes can invalidate observations without changing
        -- the instance ID/type. Refresh those sources explicitly, not as a side
        -- effect of comparing instance or location values.
        Controller.Invalidate("instance")
        Controller.Invalidate("location")
        Controller.Invalidate("roster")
        Controller.Invalidate("playerAuras")
        Controller.Invalidate("groupAuras")
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
        Controller.Invalidate("location")
    elseif event == "BAG_UPDATE_DELAYED" then
        Controller.Invalidate("inventory")
    elseif event == "ITEM_COUNT_CHANGED" or event == "ITEM_DATA_LOAD_RESULT" then
        if F.IsSafeNumber(unit) and demand.itemIDs[unit] then
            Controller.Invalidate("inventory", { scope = { [unit] = true } })
        end
    elseif event == "BAG_UPDATE_COOLDOWN" then
        Controller.Invalidate("cooldowns")
    elseif event == "WEAPON_ENCHANT_CHANGED"
        or event == "WEAPON_SLOT_CHANGED"
        or event == "PLAYER_EQUIPMENT_CHANGED"
    then
        Controller.Invalidate("weapons")
    elseif event == "UNIT_INVENTORY_CHANGED" then
        if F.UnitIsUnitSafe(unit, "player") then
            Controller.Invalidate("weapons")
        end
    elseif event == "SPELLS_CHANGED"
        or event == "SPELL_DATA_LOAD_RESULT"
        or event == "PLAYER_SPECIALIZATION_CHANGED"
    then
        if event ~= "PLAYER_SPECIALIZATION_CHANGED" or F.UnitIsUnitSafe(unit, "player") then
            Controller.Invalidate("spells")
            Controller.Invalidate("class")
            Controller.Invalidate("weapons")
        end
    end
end)

-- Lifecycle and combat reconciliation.
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
