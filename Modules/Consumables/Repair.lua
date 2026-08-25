local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Repair = RCC.Consumables.Repair or {}

local Repair = RCC.Consumables.Repair

local F = RCC.F
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local GetItemCooldown = C_Item.GetItemCooldown

local Priority = {
    READY_REUSABLE = 4,
    READY_CONSUMABLE = 3,
    COOLDOWN_REUSABLE = 2,
    COOLDOWN_CONSUMABLE = 1,
}

local function getActiveCooldown(itemID, now)
    local start, duration = GetItemCooldown(itemID)

    if not F.IsSafeNumber(start)
        or not F.IsSafeNumber(duration)
        or duration <= 0
        or start + duration <= now
    then
        return
    end

    return {
        start = start,
        duration = duration,
    }
end

local function addRepairData(candidate, now)
    local data = candidate
        and RCC.db.repairItemData[candidate.itemID]

    if not data then return candidate end

    candidate.reusable = data.reusable == true
    candidate.cooldown = getActiveCooldown(candidate.itemID, now)
    candidate.ready = candidate.cooldown == nil

    return candidate
end

local function getPriority(candidate)
    if candidate.ready then
        if candidate.reusable then
            return Priority.READY_REUSABLE
        end

        return Priority.READY_CONSUMABLE
    elseif candidate.reusable then
        return Priority.COOLDOWN_REUSABLE
    end

    return Priority.COOLDOWN_CONSUMABLE
end

function Repair.CollectItemsInBags(now)
    now = F.IsSafeNumber(now) and now or GetTime()

    local candidates = ItemCandidates.CollectAvailableFromList(
        RCC.db.repairItemIDs,
        ItemCandidates.BAGS_ONLY
    )

    for i = 1, #candidates do
        addRepairData(candidates[i], now)
    end

    return candidates
end

function Repair.GetCooldownSignature(now)
    -- BAG_UPDATE_COOLDOWN is noisy. The controller compares this compact
    -- signature so the full consumable pipeline only refreshes on a repair
    -- item's cooldown start, completion, or candidate change.
    local candidates = Repair.CollectItemsInBags(now)
    local fields = {}

    for i = 1, #candidates do
        local candidate = candidates[i]
        local cooldown = candidate.cooldown

        fields[#fields + 1] = tostring(candidate.itemID)

        if cooldown then
            fields[#fields + 1] = tostring(cooldown.start)
            fields[#fields + 1] = tostring(cooldown.duration)
        else
            fields[#fields + 1] = "ready"
        end
    end

    return table.concat(fields, ":")
end

function Repair.GetItemCandidate(now)
    local candidates = Repair.CollectItemsInBags(now)
    local selected = ItemCandidates.SelectBest(
        candidates,
        function(candidate, currentSelection)
            return getPriority(candidate) > getPriority(currentSelection)
        end
    )

    return selected, candidates
end

function Repair.GetDefaultItemID()
    return RCC.db.repairDefaultItemID
end
