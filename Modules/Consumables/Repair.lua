local _, RCC = ...
local Repair = {}
RCC.Consumables.Repair = Repair
local S = RCC.ConsumableSelection

Repair.Inventory = { list = RCC.db.repairItemIDs }

Repair.Dependencies = {
    selection = { "inventory", "cooldowns" },
    expiration = "cooldowns"
}

function Repair.Evaluate(selection, observation, inputs, now)
    local model = { selection = selection, action = selection.action }

    for _, candidate in ipairs(selection.candidates) do
        local cooldown = candidate.cooldown
        local expires = cooldown and cooldown.start + cooldown.duration

        if expires and expires > now then
            model.recheckAt = math.min(model.recheckAt or expires, expires)
            model.nextUpdateAt = model.recheckAt
        end
    end

    return model
end

local function priority(candidate)
    -- Prefer a ready reusable device over a consumable, but never choose a
    -- cooling-down reusable over a ready consumable.
    if candidate.ready then return candidate.reusable and 4 or 3 end

    return candidate.reusable and 2 or 1
end

function Repair.Select(inputs)
    local candidates = S.List(inputs.inventory, RCC.db.repairItemIDs)

    for _, candidate in ipairs(candidates) do
        candidate.reusable = RCC.db.repairItemData[candidate.itemID].reusable == true
        candidate.cooldown = inputs.cooldowns[candidate.itemID]
        candidate.ready = candidate.cooldown == nil
    end

    table.sort(candidates, function(a, b)
        local aPriority, bPriority = priority(a), priority(b)

        if aPriority ~= bPriority then return aPriority > bPriority end

        return a.index < b.index
    end)

    local selected = candidates[1]

    return S.Resolve({
        candidates = candidates,
        fallbacks = candidates,
        defaultCandidate = S.Item(inputs.inventory, RCC.db.repairDefaultItemID),
    }, { available = selected and selected.ready })
end
