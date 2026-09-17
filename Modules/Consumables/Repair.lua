local _, RCC = ...
local Repair = {}
RCC.Consumables.Repair = Repair
local S = RCC.ConsumableSelection

Repair.Inventory = { list = RCC.db.repairItemIDs }

Repair.Dependencies = { selection = { "inventory", "cooldowns" }, expiration = "cooldowns" }

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
    local selected = S.Best(candidates, function(a, b) return priority(a) > priority(b) end)
    local result = S.Result(selected, candidates)
    result.fallback = S.Item(inputs.inventory, RCC.db.repairDefaultItemID)
    return S.WithItemAction(result, { available = selected and selected.ready })
end

function Repair.GetItemCandidate()
    return S.Unpack(Repair.Select(RCC.ConsumableInputs.ReadSelection("repair")))
end

function Repair.GetDefaultItemID()
    return RCC.db.repairDefaultItemID
end
