local _, RCC = ...
local Repair = {}
RCC.Consumables.Repair = Repair
local S = RCC.ConsumableSelection

Repair.Inventory = {
    list = RCC.db.repairItemIDs,
    cooldownItemIDs = RCC.db.repairItemIDs,
}

Repair.Dependencies = {
    selection = { "inventory", "cooldowns" },
}

local function priority(candidate)
    -- Prefer a ready reusable device over a consumable, but never choose a
    -- cooling-down reusable over a ready consumable.
    if candidate.ready then return candidate.reusable and 4 or 3 end

    return candidate.reusable and 2 or 1
end

function Repair.Select(inputs)
    local candidates = S.List(inputs.inventory, RCC.db.repairItemIDs)
    local selection = {
        candidates = candidates,
        fallbacks = candidates,
        defaultCandidate = S.Item(inputs.inventory, RCC.db.repairDefaultItemID),
    }

    S.ApplyItemCooldowns(selection, inputs.cooldowns, Repair.Inventory.cooldownItemIDs)

    for _, candidate in ipairs(candidates) do
        candidate.reusable = RCC.db.repairItemData[candidate.itemID].reusable == true
        candidate.ready = candidate.cooldown == nil
    end

    table.sort(candidates, function(a, b)
        local aPriority, bPriority = priority(a), priority(b)

        if aPriority ~= bPriority then return aPriority > bPriority end

        return a.index < b.index
    end)

    local selected = candidates[1]

    return S.Resolve(selection, { available = selected and selected.ready })
end
