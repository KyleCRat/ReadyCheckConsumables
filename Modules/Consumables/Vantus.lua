local _, RCC = ...
local Vantus = {}
RCC.Consumables.Vantus = Vantus
local S = RCC.ConsumableSelection
local KEY = RCC.ConsumableItemCacheKey.VANTUS

Vantus.Inventory = { lists = RCC.db.vantusItemsByRaid }

Vantus.Dependencies = {
    selection = { "inventory", "preferences.vantus", "instance.instanceID" },
    observation = { "playerAuras" },
    evaluation = { "instance.warningSeconds" },
    expiration = "playerAuras",
}

function Vantus.Select(inputs)
    local runeIDs = RCC.db.vantusItemsByRaid[inputs.instance.instanceID]
    local preferredID = inputs.preferences[KEY]
    local candidates = S.List(inputs.inventory, runeIDs)
    local preferred = S.FindListItem(inputs.inventory, runeIDs, preferredID)

    return S.Resolve({
        preferred = preferred,
        fallbacks = candidates,
        candidates = candidates,
        applicable = runeIDs ~= nil,
        defaultCandidate = runeIDs and S.Item(inputs.inventory, runeIDs[1]),
    }, { preferenceKey = KEY })
end

function Vantus.Observe(inputs)
    return RCC.ConsumableEffects.Observe(inputs.playerAuras, RCC.db.vantusBuffIDs)
end

function Vantus.Evaluate(selection, observation, inputs, now)
    local model = RCC.ConsumableEffects.Evaluate(selection, observation, inputs.instance, now)
    model.allowFlyout = selection.applicable and model.effect == nil

    if not model.allowFlyout then
        model.action = nil
    end

    -- Its label is the boss name, not a countdown or a duration warning.
    model.nextUpdateAt = model.recheckAt

    return model
end
