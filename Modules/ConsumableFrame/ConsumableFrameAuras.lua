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
    local state = {}
    local foodState
    local eatingState

    for i = 1, 60 do
        local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")

        if not auraData then
            break
        end

        if not issecretvalue(auraData.spellId) then
            local sid = auraData.spellId
            local expiry = auraData.expirationTime
            local remaining = Auras.GetRemaining(expiry, now)

            if RCC.db.foodBuffIDs[sid] or RCC.db.foodIconIDs[auraData.icon] then
                if RCC.db.eatingIconIDs[auraData.icon] then
                    eatingState = {
                        active = true,
                        duration = auraData.duration,
                        expiry = expiry,
                        icon = auraData.icon,
                        remaining = remaining,
                    }
                else
                    foodState = {
                        active = true,
                        expiry = expiry,
                        icon = auraData.icon,
                        remaining = remaining,
                    }

                    if auraData.auraInstanceID
                        and not issecretvalue(auraData.auraInstanceID)
                    then
                        foodState.auraInstanceID = auraData.auraInstanceID
                    end
                end

            elseif RCC.db.flaskBuffIDs[sid] then
                state.flask = {
                    active = true,
                    icon = auraData.icon,
                    remaining = remaining,
                    satisfied = not (remaining and remaining <= 600),
                }

            elseif RCC.db.augmentBuffIDs[sid] then
                state.augment = {
                    active = true,
                    icon = auraData.icon,
                    remaining = remaining,
                    satisfied = true,
                }

            elseif RCC.db.vantusBuffIDs[sid] then
                local name = auraData.name or ""
                state.vantus = {
                    bossName = name:gsub("^Vantus Rune: ", ""),
                }
            end
        end
    end

    if foodState then
        foodState.satisfied = true
        state.food = foodState
    elseif eatingState then
        state.eating = eatingState
        state.food = {
            active = true,
            expiry = eatingState.expiry,
            icon = eatingState.icon,
            remaining = eatingState.remaining,
            satisfied = true,
        }
    end

    return state
end
