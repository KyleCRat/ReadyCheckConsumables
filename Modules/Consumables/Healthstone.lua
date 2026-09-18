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
    local candidates = S.Map(inputs.inventory, RCC.db.healthstoneItemIDs, {
        countUses = true,
        compare = function(a, b)
            return a.data.priority > b.data.priority
        end,
    })

    -- Healthstones are automatic, never preferred: Demonic takes priority.
    return S.Resolve({ candidates = candidates, fallbacks = candidates })
end

function Healthstone.Evaluate(selection, _, inputs)
    return {
        selection = selection,
        action = selection.action,
        applicable = inputs.roster.hasWarlock
    }
end
