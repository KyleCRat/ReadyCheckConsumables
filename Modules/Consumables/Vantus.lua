local _, RCC = ...
local Vantus = {}
RCC.Consumables.Vantus = Vantus
local S = RCC.ConsumableSelection
local KEY = RCC.ConsumableItemCacheKey.VANTUS

Vantus.Inventory = { lists = RCC.db.vantusItemsByRaid }

Vantus.Dependencies = {
    selection = { "inventory", "preferences.vantus", "context.instanceID" },
    observation = { "playerAuras" }, evaluation = { "context.warningSeconds" },
    expiration = "playerAuras",
}

function Vantus.Select(inputs, preserveUnavailable, runeIDs)
    runeIDs = runeIDs or RCC.db.vantusItemsByRaid[inputs.context.instanceID]
    local preferredID = inputs.preferences[KEY]
    local candidates = S.List(inputs.inventory, runeIDs)
    local cached = preserveUnavailable and S.CachedList(inputs.inventory, runeIDs, preferredID)
    local result = S.Result(S.Preferred(candidates, preferredID, cached), candidates, preferredID)
    result.applicable = runeIDs ~= nil
    result.fallback = runeIDs and S.Item(inputs.inventory, runeIDs[1])
    return S.WithItemAction(result, { preferenceKey = KEY })
end

function Vantus.GetRuneIDsForCurrentRaid()
    return RCC.db.vantusItemsByRaid[RCC.ConsumableInputs.ReadContext().instanceID]
end

function Vantus.GetItemCandidate(runeIDs, preserveUnavailable)
    return S.Unpack(Vantus.Select(RCC.ConsumableInputs.ReadSelection("vantus"), preserveUnavailable, runeIDs))
end

function Vantus.Observe(inputs)
    return RCC.ConsumableEffects.Observe(inputs.playerAuras, RCC.db.vantusBuffIDs)
end

function Vantus.Evaluate(selection, observation, inputs, now)
    local model = RCC.ConsumableEffects.Evaluate(selection, observation, inputs.context, now)
    model.allowFlyout = selection.applicable and model.effect == nil
    if not model.allowFlyout then model.action = nil end
    -- Its label is the boss name, not a countdown or a duration warning.
    model.nextUpdateAt = model.recheckAt
    return model
end
