local _, RCC = ...

RCC.ConsumableFrameAuras = RCC.ConsumableFrameAuras or {}

local Auras = RCC.ConsumableFrameAuras
local F = RCC.F
local Timing = RCC.ConsumableTiming

function Auras.IsPositiveDuration(duration)
    return F.IsSafeNumber(duration) and duration > 0
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

    if options.includeExpirationState then
        local expiringSoon = Timing.IsExpiringSoon(aura.remaining)

        auraState.satisfied = not expiringSoon
        auraState.timeIsBad = expiringSoon
    end

    return auraState
end

function Auras.ScanPlayer(now)
    local state = {
        auras = {},
    }

    F.ForEachHelpfulAura("player", function(auraData, spellID)
        local expiry = F.GetPublicAuraField(auraData, "expirationTime")
        local remaining = F.GetAuraRemaining(expiry, now)
        local aura = {
            auraInstanceID = F.GetPublicAuraField(
                auraData,
                "auraInstanceID"
            ),
            duration = F.GetPublicAuraField(auraData, "duration"),
            expiry = expiry,
            icon = F.GetPublicAuraField(auraData, "icon"),
            name = F.GetPublicAuraField(auraData, "name"),
            remaining = remaining,
            spellID = spellID,
        }

        state.auras[#state.auras + 1] = aura
    end)

    return state
end
