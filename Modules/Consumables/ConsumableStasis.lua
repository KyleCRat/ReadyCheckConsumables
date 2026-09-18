local _, RCC = ...
local ConsumableStasis = {}
RCC.Consumables.ConsumableStasis = ConsumableStasis
local S = RCC.ConsumableSelection

ConsumableStasis.Inventory = { list = RCC.db.consumableStasisItemIDs }

ConsumableStasis.Dependencies = { selection = { "inventory" } }

function ConsumableStasis.Select(inputs)
    local candidates = S.List(inputs.inventory, RCC.db.consumableStasisItemIDs)

    return S.Resolve({
        candidates = candidates,
        fallbacks = candidates,
        defaultCandidate = S.Item(inputs.inventory, RCC.db.consumableStasisItemIDs[1]),
    })
end
