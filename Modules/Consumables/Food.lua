local _, RCC = ...
local Food = {}
RCC.Consumables.Food = Food
local S = RCC.ConsumableSelection
local KEY = RCC.ConsumableItemCacheKey.FOOD

Food.Inventory = { list = RCC.db.foodItemIDs }

Food.Dependencies = {
    selection = { "inventory", "preferences.food" },
    observation = { "playerAuras" },
    evaluation = { "instance.warningSeconds" },
    expiration = "playerAuras",
}

function Food.Select(inputs, preserveUnavailable)
    local candidates = S.List(inputs.inventory, RCC.db.foodItemIDs)
    local preferredID = inputs.preferences[KEY]
    local cached = preserveUnavailable and S.CachedList(inputs.inventory, RCC.db.foodItemIDs, preferredID)

    return S.WithItemAction(S.Result(S.Preferred(candidates, preferredID, cached), candidates, preferredID), {
        preferenceKey = KEY,
    })
end

function Food.GetItemCandidate(preserveUnavailable)
    return S.Unpack(Food.Select(RCC.ConsumableInputs.ReadSelection("food"), preserveUnavailable))
end

function Food.Observe(inputs)
    local observation = { available = inputs.playerAuras.available }

    for _, aura in ipairs(inputs.playerAuras.auras) do
        local kind = RCC.FoodAuras.GetType(aura)

        if kind == RCC.FoodAuras.Type.EATING then
            observation.eating = aura
        end

        if kind == RCC.FoodAuras.Type.WELL_FED then
            observation.food = aura
        end
    end

    return observation
end

function Food.Evaluate(selection, observation, inputs, now)
    local E = RCC.ConsumableEffects
    local food = E.Aura(observation.food, inputs.instance, now)
    local eating = E.Aura(observation.eating, inputs.instance, now)
    local model = {
        selection = selection,
        action = selection.action,
        available = observation.available,
        effect = eating and (not food or food.timeIsBad) and eating or food,
        satisfied = eating ~= nil or (food and food.satisfied) or false,
        hasCoverage = food ~= nil or eating ~= nil,
    }

    if eating then
        -- Eating suppresses reminders while in progress, not a short Well Fed buff.
        eating.timeIsBad = nil
        eating.auraInstanceID = nil

        if eating.duration and eating.duration > 0 and eating.remaining then
            model.cooldown = { start = eating.expiry - eating.duration, duration = eating.duration }
        end
    end

    if food then
        E.AddDeadline(model, food.expiry, inputs.instance, now)
    end

    if eating then
        E.AddDeadline(model, eating.expiry, inputs.instance, now)
    end

    return model
end
