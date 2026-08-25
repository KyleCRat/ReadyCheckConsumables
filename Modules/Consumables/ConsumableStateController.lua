local _, RCC = ...

RCC.ConsumableStateController = RCC.ConsumableStateController or {}

local Controller = RCC.ConsumableStateController
local Auras = RCC.ConsumableFrameAuras
local State = RCC.ConsumableState
local Consumables = RCC.Consumables

local REFRESH_DELAY = 0.2

local consumers = {}
local refreshTimer
local latestSnapshot

local function hasActiveConsumer()
    for _, consumer in pairs(consumers) do
        if not consumer.IsActive or consumer:IsActive() then
            return true
        end
    end

    return false
end

local function resolveStates(now)
    local auraState = Auras.ScanPlayer(now)
    local weaponStates = Consumables.WeaponEnchant.ResolveStates()

    return {
        food = Consumables.Food.ResolveState(auraState),
        flask = Consumables.Flask.ResolveState(auraState),
        consumableStasis = Consumables.ConsumableStasis.ResolveState(),
        mainHandTempWeaponEnchant =
            weaponStates.mainHandTempWeaponEnchant,
        offHandTempWeaponEnchant =
            weaponStates.offHandTempWeaponEnchant,
        augment = Consumables.Augment.ResolveState(auraState),
        raidBuff = Consumables.RaidBuff.ResolveState(),
        hs = Consumables.Healthstone.ResolveState(),
        combatpot = Consumables.CombatPotion.ResolveState(),
        healpot = Consumables.HealingPotion.ResolveState(),
        recuperate = Consumables.Recuperate.ResolveState(),
        vantus = Consumables.Vantus.ResolveState(auraState),
    }
end

local function buildSnapshot(now)
    local resolved = resolveStates(now)
    local normalized = {}

    for key, state in pairs(resolved) do
        normalized[key] = State.Normalize(state)
    end

    return {
        generatedAt = now,
        states = normalized,
    }
end

local function applySnapshot(snapshot)
    for _, consumer in pairs(consumers) do
        if (not consumer.IsActive or consumer:IsActive())
            and consumer.ApplySnapshot
        then
            consumer:ApplySnapshot(snapshot)
        end
    end
end

function Controller.RegisterConsumer(key, consumer)
    if not key or type(consumer) ~= "table" then
        return false
    end

    consumers[key] = consumer

    if latestSnapshot
        and (not consumer.IsActive or consumer:IsActive())
        and consumer.ApplySnapshot
    then
        consumer:ApplySnapshot(latestSnapshot)
    end

    return true
end

function Controller.UnregisterConsumer(key)
    consumers[key] = nil
end

function Controller.GetLatestSnapshot()
    return latestSnapshot
end

function Controller.RefreshNow(force)
    if refreshTimer then
        refreshTimer:Cancel()
        refreshTimer = nil
    end

    if not force and not hasActiveConsumer() then
        return false
    end

    latestSnapshot = buildSnapshot(GetTime())
    applySnapshot(latestSnapshot)

    return true
end

function Controller.RequestRefresh(delay, force)
    if refreshTimer then return false end
    if not force and not hasActiveConsumer() then return false end

    refreshTimer = C_Timer.NewTimer(delay or REFRESH_DELAY, function()
        refreshTimer = nil
        Controller.RefreshNow(force)
    end)

    return true
end

local eventFrame = CreateFrame("Frame")

local function requestUnitRefresh(unit)
    if RCC.F.UnitIsUnitSafe(unit, "player") then
        Controller.RequestRefresh()
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        Controller.RequestRefresh(0, true)

        return
    elseif event == "UNIT_AURA"
        or event == "UNIT_INVENTORY_CHANGED"
        or event == "PLAYER_SPECIALIZATION_CHANGED"
    then
        requestUnitRefresh(...)

        return
    elseif event == "PLAYER_REGEN_DISABLED"
        or event == "PLAYER_REGEN_ENABLED"
    then
        Controller.RequestRefresh(0)

        return
    end

    Controller.RequestRefresh()
end)

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("SPELLS_CHANGED")

