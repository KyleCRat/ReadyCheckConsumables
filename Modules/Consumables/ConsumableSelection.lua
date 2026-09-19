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

local function higherItemIDFirst(a, b)
    return a.itemID > b.itemID
end

-- Sort once using the category's priority, or the default item-ID order.
function Selection.Map(inventory, itemData, options)
    options = options or {}
    local candidates = {}

    for itemID, data in pairs(itemData) do
        local candidate = Selection.Item(inventory, itemID, data, nil, options.countUses)

        if candidate and candidate.count > 0 then
            candidates[#candidates + 1] = candidate
        end
    end

    table.sort(candidates, options.compare or higherItemIDFirst)

    return candidates
end

function Selection.FindListItem(inventory, itemIDs, itemID)
    if not itemID then return end

    for index, registeredItemID in ipairs(itemIDs or {}) do
        if registeredItemID == itemID then
            return Selection.Item(inventory, itemID, nil, index)
        end
    end
end

function Selection.FindMapItem(inventory, itemData, itemID)
    if itemID and itemData[itemID] then
        return Selection.Item(inventory, itemID, itemData[itemID])
    end
end

-- Attach public cooldowns before publishing a new selection. Keep a map for
-- prepared combat items that may no longer be carried, as well as the timing
-- on each current flyout candidate. This never changes priority or readiness;
-- categories such as Repair can apply their own readiness rules afterward.
function Selection.ApplyItemCooldowns(selection, cooldowns, itemIDs)
    local itemCooldowns = {}

    for _, itemID in ipairs(itemIDs) do
        itemCooldowns[itemID] = cooldowns[itemID]
    end

    selection.itemCooldowns = itemCooldowns

    for _, candidate in ipairs(selection.candidates) do
        candidate.cooldown = itemCooldowns[candidate.itemID]
    end

    if selection.preferred then
        selection.preferred.cooldown = itemCooldowns[selection.preferred.itemID]
    end

    if selection.defaultCandidate then
        selection.defaultCandidate.cooldown = itemCooldowns[selection.defaultCandidate.itemID]
    end
end

-- Selection never writes preferences. Categories supply three independent
-- choices: the exact preferred item (even at zero count), available overrides
-- in priority order, and ordered fallbacks. Candidates are the full flyout
-- list, which can include items ineligible for automatic fallback.
--
-- Buttons show an override, otherwise the preference, otherwise the first
-- fallback. An unavailable preference must not silently bind another item.
-- Macros skip unavailable choices and take their primary/backup from the same
-- ordering. A spell override replaces item use, not the saved item preference.
-- An exclusiveOverrides result limits automatic item use to its override list;
-- the saved preference and full manual flyout candidates remain intact.
function Selection.Resolve(selection, actionOptions)
    if selection.overrideAction then
        selection.action = selection.overrideAction

        return selection
    end

    local override = selection.overrides and selection.overrides[1]
    local fallback = selection.fallbacks and selection.fallbacks[1]
    local candidate = override or selection.preferred or fallback

    selection.candidate = candidate
    selection.unavailable = candidate ~= nil and candidate.count <= 0

    if candidate and candidate.count > 0 then
        selection.action = RCC.ConsumableState.CreateItemAction(candidate.itemID, actionOptions)
    end

    return selection
end

function Selection.GetAvailableCandidates(selection)
    local candidates = {}
    local included = {}

    local function add(candidate)
        if not candidate or candidate.count <= 0 or candidate.ready == false then return end
        if included[candidate.itemID] then return end

        included[candidate.itemID] = true
        candidates[#candidates + 1] = candidate
    end

    for _, candidate in ipairs(selection.overrides or {}) do
        add(candidate)
    end

    if selection.exclusiveOverrides then return candidates end

    add(selection.preferred)

    for _, candidate in ipairs(selection.fallbacks or {}) do
        add(candidate)
    end

    return candidates
end

-- Item data defines family membership and ordering. Only fleeting items from
-- the preferred family override an exact preference. Other families may be
-- macro fallbacks, subject to the category's own compatibility rules.
function Selection.FamilyCandidates(inventory, options)
    local candidates = Selection.List(inventory, options.itemIDs)
    local preferred = Selection.FindMapItem(inventory, options.itemData, options.preferredID)
    local selection = {
        candidates = candidates,
        preferred = preferred,
        overrides = {},
        fallbacks = {},
    }
    local otherFamilies = {}

    for _, candidate in ipairs(candidates) do
        candidate.data = options.itemData[candidate.itemID]

        if not preferred then
            selection.fallbacks[#selection.fallbacks + 1] = candidate
        elseif candidate.data.family == preferred.data.family then
            if candidate.data.variant == RCC.ConsumableVariant.FLEETING then
                selection.overrides[#selection.overrides + 1] = candidate
            end

            selection.fallbacks[#selection.fallbacks + 1] = candidate
        elseif not options.canFallbackToFamily
            or options.canFallbackToFamily(preferred.data, candidate.data)
        then
            otherFamilies[#otherFamilies + 1] = candidate
        end
    end

    for _, candidate in ipairs(otherFamilies) do
        selection.fallbacks[#selection.fallbacks + 1] = candidate
    end

    return selection
end

function Selection.Unpack(result)
    return result.candidate, result.candidates, result.unavailable
end
