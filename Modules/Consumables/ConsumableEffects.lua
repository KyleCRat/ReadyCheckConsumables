local _, RCC = ...
local Effects = {}
RCC.ConsumableEffects = Effects

-- Status derivation is pure. A readable match survives an incomplete scan;
-- absence is only confirmed by a complete scan. Cached remaining time is never
-- decremented in place: it is derived from the public expiration timestamp.
function Effects.Observe(scan, spellIDs)
    for _, aura in ipairs(scan.auras) do
        if spellIDs[aura.spellID] then
            return { available = scan.available, aura = aura }
        end
    end

    return { available = scan.available }
end

function Effects.Aura(aura, instance, now)
    if not aura then return end

    local expiry = aura.expirationTime
    local remaining = expiry and expiry > 0 and expiry - now or nil

    if remaining and remaining <= 0 then return end

    local bad = remaining ~= nil and remaining <= instance.warningSeconds

    return {
        active = true,
        icon = aura.icon,
        name = aura.name,
        auraInstanceID = aura.auraInstanceID,
        duration = aura.duration,
        expiry = expiry,
        remaining = remaining,
        timeIsBad = bad,
        satisfied = not bad,
    }
end

function Effects.AddDeadline(model, expiry, instance, now)
    if not expiry or expiry <= now then return end

    local remaining = expiry - now

    -- Duration labels have minute precision; native cooldown widgets animate
    -- their own sweep. Also wake exactly at warning and expiration boundaries.
    local nextUpdate = now + (remaining % 60) + 0.01

    if nextUpdate > expiry then
        nextUpdate = expiry
    end

    local warning = expiry - instance.warningSeconds

    if warning > now then
        nextUpdate = math.min(nextUpdate, warning)
    end

    model.nextUpdateAt = math.min(model.nextUpdateAt or nextUpdate, nextUpdate)
    model.recheckAt = math.min(model.recheckAt or expiry, expiry)
end

function Effects.Evaluate(selection, observation, instance, now)
    local effect = Effects.Aura(observation.aura, instance, now)
    local model = {
        selection = selection,
        action = selection.action,
        effect = effect,
        available = observation.available
    }

    if effect then
        Effects.AddDeadline(model, effect.expiry, instance, now)
    end

    return model
end

-- Preserve every readable effect. An absent alternative is unknown only when
-- that particular targeted lookup was unavailable.
function Effects.ObserveSpells(inputs, spellIDs)
    local observation = { available = true, auras = {}, bySpellID = {} }

    for _, spellID in ipairs(spellIDs) do
        if inputs.spells[spellID].known then
            local result = inputs.playerSpellAuras[spellID]
            observation.bySpellID[spellID] = result

            if result.aura then
                observation.auras[#observation.auras + 1] = result.aura
            elseif not result.available then
                observation.available = false
            end
        end
    end

    return observation
end

function Effects.EvaluateMany(selection, observation, instance, now)
    local model = {
        selection = selection,
        action = selection.action,
        available = observation.available,
        effects = {},
        bySpellID = {},
        observations = observation.bySpellID,
        satisfied = true,
        timeIsBad = false,
    }

    -- Data order is stable, independent of preferences, history, duration
    -- sorting, and which member of a pair was refreshed most recently.
    for _, aura in ipairs(observation.auras) do
        local effect = Effects.Aura(aura, instance, now)

        if effect then
            effect.spellID = aura.spellID
            model.effects[#model.effects + 1] = effect
            model.bySpellID[aura.spellID] = effect
            model.satisfied = model.satisfied and effect.satisfied
            model.timeIsBad = model.timeIsBad or effect.timeIsBad
            Effects.AddDeadline(model, effect.expiry, instance, now)

            if effect.remaining then
                model.remaining = math.min(model.remaining or effect.remaining, effect.remaining)
            end
        end
    end

    model.complete = #model.effects >= (selection.capacity or 1)
    model.satisfied = model.satisfied and model.complete

    return model
end
