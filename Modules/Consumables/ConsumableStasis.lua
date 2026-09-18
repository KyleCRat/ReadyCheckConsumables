local _, RCC = ...
local ConsumableStasis = {}
RCC.Consumables.ConsumableStasis = ConsumableStasis
local S = RCC.ConsumableSelection

ConsumableStasis.Inventory = { list = RCC.db.consumableStasisItemIDs }

ConsumableStasis.Dependencies = { selection = { "inventory" } }

function ConsumableStasis.Select(inputs)
    local candidates = S.List(inputs.inventory, RCC.db.consumableStasisItemIDs)
    local result = S.Result(candidates[1], candidates)
    result.fallback = S.Item(inputs.inventory, RCC.db.consumableStasisItemIDs[1])

    return S.WithItemAction(result)
end

function ConsumableStasis.GetItemCandidate()
    return ConsumableStasis.Select(RCC.ConsumableInputs.ReadSelection("consumableStasis")).candidate
end

function ConsumableStasis.GetDefaultItemID()
    return RCC.db.consumableStasisItemIDs[1]
end
