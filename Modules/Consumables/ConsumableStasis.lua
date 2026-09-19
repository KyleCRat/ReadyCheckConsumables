local _, RCC = ...
local ConsumableStasis = {}
RCC.Consumables.ConsumableStasis = ConsumableStasis
local S = RCC.ConsumableSelection

ConsumableStasis.Inventory = {
    list = RCC.db.consumableStasisItemIDs,
    cooldownItemIDs = RCC.db.consumableStasisItemIDs,
}

ConsumableStasis.Dependencies = { selection = { "inventory", "cooldowns" } }

function ConsumableStasis.Select(inputs)
    local candidates = S.List(inputs.inventory, RCC.db.consumableStasisItemIDs)

    local selection = {
        candidates = candidates,
        fallbacks = candidates,
        defaultCandidate = S.Item(inputs.inventory, RCC.db.consumableStasisItemIDs[1]),
    }

    S.ApplyItemCooldowns(selection, inputs.cooldowns, ConsumableStasis.Inventory.cooldownItemIDs)

    return S.Resolve(selection)
end
