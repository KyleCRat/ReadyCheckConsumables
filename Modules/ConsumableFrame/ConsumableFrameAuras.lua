local _, RCC = ...

RCC.ConsumableFrameAuras = RCC.ConsumableFrameAuras or {}

local Auras = RCC.ConsumableFrameAuras

function Auras.GetRemaining(expiry, now)
    if type(expiry) ~= "number" or issecretvalue(expiry) then return end
    if expiry <= 0 then return end

    return expiry - now
end

function Auras.IsPositiveDuration(duration)
    return type(duration) == "number"
           and not issecretvalue(duration)
           and duration > 0
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
