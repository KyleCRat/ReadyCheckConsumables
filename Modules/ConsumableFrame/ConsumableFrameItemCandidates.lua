local _, RCC = ...

RCC.ConsumableFrameItemCandidates = RCC.ConsumableFrameItemCandidates or {}

local Candidates = RCC.ConsumableFrameItemCandidates

local GetItemCount = C_Item.GetItemCount

Candidates.BAGS_ONLY = { includeBank = false, includeUses = false }
Candidates.BAGS_WITH_USES = { includeBank = false, includeUses = true }

local function getOption(options, key, defaultValue)
    if options and options[key] ~= nil then
        return options[key]
    end

    return defaultValue
end

function Candidates.GetCount(itemID, options)
    if not itemID then return 0 end

    local includeBank = getOption(options, "includeBank", false)
    local includeUses = getOption(options, "includeUses", false)

    return GetItemCount(itemID, includeBank, includeUses) or 0
end

function Candidates.CollectAvailableFromList(itemIDs, options)
    local candidates = {}

    if not itemIDs then return candidates end

    for index = 1, #itemIDs do
        local itemID = itemIDs[index]
        local count = Candidates.GetCount(itemID, options)

        if count > 0 then
            candidates[#candidates + 1] = {
                itemID = itemID,
                count = count,
                index = index,
            }
        end
    end

    return candidates
end

function Candidates.CollectAvailableFromMap(itemDataByID, options)
    local candidates = {}

    if not itemDataByID then return candidates end

    for itemID, data in pairs(itemDataByID) do
        local count = Candidates.GetCount(itemID, options)

        if count > 0 then
            candidates[#candidates + 1] = {
                itemID = itemID,
                count = count,
                data = data,
            }
        end
    end

    return candidates
end

function Candidates.FindFirstAvailable(itemIDs, options)
    if not itemIDs then return end

    for index = 1, #itemIDs do
        local itemID = itemIDs[index]
        local count = Candidates.GetCount(itemID, options)

        if count > 0 then
            return {
                itemID = itemID,
                count = count,
                index = index,
            }
        end
    end
end

function Candidates.SelectBest(candidates, isBetter)
    local best

    if not candidates or not isBetter then return best end

    for index = 1, #candidates do
        local candidate = candidates[index]

        if not best or isBetter(candidate, best) then
            best = candidate
        end
    end

    return best
end

function Candidates.SumCounts(itemIDsByKey, options)
    local totalCount = 0

    if not itemIDsByKey then return totalCount end

    for itemID in pairs(itemIDsByKey) do
        totalCount = totalCount + Candidates.GetCount(itemID, options)
    end

    return totalCount
end
