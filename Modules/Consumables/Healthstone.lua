local _, RCC = ...
local Healthstone = {}
RCC.Consumables.Healthstone = Healthstone
local S = RCC.ConsumableSelection

Healthstone.Inventory = { map = RCC.db.healthstoneItemIDs }

Healthstone.Dependencies = {
    selection = { "inventory" },
    evaluation = { "roster.hasWarlock" }
}

function Healthstone.Select(inputs)
    local candidates = S.Map(inputs.inventory, RCC.db.healthstoneItemIDs, true)
    local result = S.Result(candidates[1], candidates)
    result.count = 0

    for _, candidate in ipairs(candidates) do
        result.count = result.count + candidate.count
    end

    result.action = RCC.ConsumableState.CreateItemAction(RCC.db.healthstoneItemID, { available = result.count > 0 })

    return result
end

function Healthstone.GetItemCandidate()
    return Healthstone.Select(RCC.ConsumableInputs.ReadSelection("hs")).candidate
end

function Healthstone.Evaluate(selection, _, inputs)
    return {
        selection = selection,
        action = selection.action,
        applicable = inputs.roster.hasWarlock
    }
end
