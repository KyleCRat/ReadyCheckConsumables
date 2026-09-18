local _, RCC = ...
RCC.Consumables = RCC.Consumables or {}

local Selection = {}
RCC.ConsumableSelection = Selection

-- Pure candidate construction. Live counts/icons enter through ConsumableInputs;
-- ordering, preference and fallback rules stay with the individual category.
function Selection.Item(inventory, itemID, data, index, uses)
    local item = itemID and inventory[itemID]

    if not item then return end

    data = type(data) == "table" and data or nil

    return {
        itemID = itemID,
        count = uses and item.uses or item.count,
        icon = data and data.icon or item.icon,
        qualityAtlas = item.qualityAtlas,
        metadataLoaded = item.metadataLoaded,
        data = data,
        index = index,
    }
end

function Selection.List(inventory, itemIDs, uses)
    local candidates = {}

    for index, itemID in ipairs(itemIDs or {}) do
        local candidate = Selection.Item(inventory, itemID, nil, index, uses)

        if candidate and candidate.count > 0 then
            candidates[#candidates + 1] = candidate
        end
    end

    return candidates
end

function Selection.Map(inventory, itemData, uses)
    local candidates = {}

    for itemID, data in pairs(itemData) do
        local candidate = Selection.Item(inventory, itemID, data, nil, uses)

        if candidate and candidate.count > 0 then
            candidates[#candidates + 1] = candidate
        end
    end

    table.sort(candidates, function(a, b)
        return a.itemID > b.itemID
    end)

    return candidates
end

function Selection.CachedList(inventory, itemIDs, preferredID)
    for index, itemID in ipairs(itemIDs or {}) do
        if itemID == preferredID then
            return Selection.Item(inventory, itemID, nil, index)
        end
    end
end

function Selection.CachedMap(inventory, itemData, preferredID)
    if preferredID and itemData[preferredID] then
        return Selection.Item(inventory, preferredID, itemData[preferredID])
    end
end

function Selection.Preferred(candidates, preferredID, unavailableCandidate)
    for _, candidate in ipairs(candidates) do
        if candidate.itemID == preferredID then return candidate end
    end

    return unavailableCandidate or candidates[1]
end

function Selection.Result(candidate, candidates, preferredID)
    return {
        candidate = candidate,
        candidates = candidates,
        unavailable = candidate ~= nil and candidate.itemID == preferredID and candidate.count <= 0,
    }
end

function Selection.WithItemAction(result, options)
    local candidate = result.candidate

    if candidate and candidate.count > 0 then
        result.action = RCC.ConsumableState.CreateItemAction(candidate.itemID, options)
    end

    return result
end

function Selection.Unpack(result)
    return result.candidate, result.candidates, result.unavailable
end

function Selection.Best(candidates, isBetter)
    local selected

    for _, candidate in ipairs(candidates) do
        if not selected or isBetter(candidate, selected) then
            selected = candidate
        end
    end

    return selected
end
