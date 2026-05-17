local _, RCC = ...

RCC.ConsumableFrameAuras = RCC.ConsumableFrameAuras or {}

local Auras = RCC.ConsumableFrameAuras
local F = RCC.F

function Auras.GetRemaining(expiry, now)
    return F.GetAuraRemaining(expiry, now)
end

function Auras.IsPositiveDuration(duration)
    return type(duration) == "number"
           and not issecretvalue(duration)
           and duration > 0
end

function Auras.FindBySpellID(state, spellIDs)
    if not state or not state.auras or not spellIDs then return end

    for i = 1, #state.auras do
        local aura = state.auras[i]

        if spellIDs[aura.spellID] then
            return aura
        end
    end
end

function Auras.FindBySpellOrIconID(state, spellIDs, iconIDs)
    if not state or not state.auras then return end

    for i = 1, #state.auras do
        local aura = state.auras[i]

        if (spellIDs and spellIDs[aura.spellID])
            or (iconIDs and iconIDs[aura.icon])
        then
            return aura
        end
    end
end

function Auras.ToConsumableState(aura, options)
    if not aura then return end

    options = options or {}

    local auraState = {
        active = true,
        duration = aura.duration,
        expiry = aura.expiry,
        icon = aura.icon,
        name = aura.name,
        remaining = aura.remaining,
    }

    if options.includeAuraInstanceID ~= false then
        auraState.auraInstanceID = aura.auraInstanceID
    end

    if options.expireWarnSeconds then
        local expiringSoon = aura.remaining
            and aura.remaining <= options.expireWarnSeconds

        auraState.satisfied = not expiringSoon
        auraState.timeIsBad = expiringSoon == true
    elseif options.satisfied ~= nil then
        auraState.satisfied = options.satisfied == true
    end

    return auraState
end

function Auras.ScanPlayer(now)
    local state = {
        auras = {},
    }

    for i = 1, 60 do
        local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")

        if not auraData then
            break
        end

        if not issecretvalue(auraData.spellId) then
            local sid = auraData.spellId
            local expiry = auraData.expirationTime
            local remaining = Auras.GetRemaining(expiry, now)
            local aura = {
                duration = auraData.duration,
                expiry = expiry,
                icon = auraData.icon,
                name = auraData.name,
                remaining = remaining,
                spellID = sid,
            }

            if auraData.auraInstanceID
                and not issecretvalue(auraData.auraInstanceID)
            then
                aura.auraInstanceID = auraData.auraInstanceID
            end

            state.auras[#state.auras + 1] = aura
        end
    end

    return state
end
