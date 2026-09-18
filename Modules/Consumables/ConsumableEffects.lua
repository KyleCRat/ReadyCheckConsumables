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
        active = true, icon = aura.icon, name = aura.name,
        auraInstanceID = aura.auraInstanceID,
        duration = aura.duration, expiry = expiry, remaining = remaining,
        timeIsBad = bad, satisfied = not bad,
    }
end

function Effects.AddDeadline(model, expiry, instance, now)
    if not expiry or expiry <= now then return end
    local remaining = expiry - now
    -- Duration labels have minute precision; native cooldown widgets animate
    -- their own sweep. Also wake exactly at warning and expiration boundaries.
    local nextUpdate = now + (remaining % 60) + 0.01
    if nextUpdate > expiry then nextUpdate = expiry end
    local warning = expiry - instance.warningSeconds
    if warning > now then nextUpdate = math.min(nextUpdate, warning) end
    model.nextUpdateAt = math.min(model.nextUpdateAt or nextUpdate, nextUpdate)
    model.recheckAt = math.min(model.recheckAt or expiry, expiry)
end

function Effects.Evaluate(selection, observation, instance, now)
    local effect = Effects.Aura(observation.aura, instance, now)
    local model = { selection = selection, action = selection.action, effect = effect, available = observation.available }
    if effect then Effects.AddDeadline(model, effect.expiry, instance, now) end
    return model
end
