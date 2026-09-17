local _, RCC = ...
local RaidBuff = {}
RCC.Consumables.RaidBuff = RaidBuff

RaidBuff.Dependencies = {
    observation = { "groupAuras" }, evaluation = { "context.raidBuff", "context.warningSeconds" },
    expiration = "groupAuras",
}

function RaidBuff.GetPlayerRaidBuffInfo()
    return RCC.ConsumableInputs.ReadContext().raidBuff
end

function RaidBuff.Observe(inputs)
    local observation = { available = true, missing = 0 }
    for _, status in pairs(inputs.groupAuras) do
        if not status.available then
            observation.available = false
        elseif not status.has then
            observation.missing = observation.missing + 1
        elseif status.expirationTime then
            observation.expirationTime = math.min(observation.expirationTime or status.expirationTime, status.expirationTime)
        end
    end
    return observation
end

function RaidBuff.Evaluate(_, observation, inputs, now)
    local remaining = observation.expirationTime and observation.expirationTime - now
    local info = inputs.context.raidBuff
    local model = {
        info = info, available = observation.available,
        missing = observation.missing, remaining = remaining and math.max(0, remaining),
        expiringSoon = remaining ~= nil and remaining <= inputs.context.warningSeconds,
    }
    if info and info.spellID then
        model.action = RCC.ConsumableState.CreateSpellAction(info.spellID, { available = true })
    end
    RCC.ConsumableEffects.AddDeadline(model, observation.expirationTime, inputs.context, now)
    return model
end
