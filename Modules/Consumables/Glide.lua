local _, RCC = ...

local Glide = {}
RCC.Consumables.Glide = Glide
local Selection = RCC.ConsumableSelection
local PREFERENCE_KEY = RCC.ConsumablePreferenceKey.GLIDE

Glide.Inventory = {
    list = RCC.db.glideItemIDs,
    cooldownItemIDs = RCC.db.glideItemIDs,
}

Glide.Toys = {
    list = RCC.db.glideToyItemIDs,
    cooldownItemIDs = RCC.db.glideToyItemIDs,
}

Glide.Dependencies = {
    selection = { "inventory", "toys", "cooldowns", "preferences.glide" },
}

local function higherPriority(left, right)
    local leftAvailable = Selection.IsAvailable(left)
    local rightAvailable = Selection.IsAvailable(right)

    if leftAvailable ~= rightAvailable then return leftAvailable end

    local leftReady = left.cooldown == nil
    local rightReady = right.cooldown == nil

    if leftReady ~= rightReady then return leftReady end
    if left.isToy ~= right.isToy then return left.isToy == true end

    return left.index < right.index
end

function Glide.Select(inputs)
    local preferredID =
        RCC.ConsumablePreferences.GetItemID(inputs.preferences, PREFERENCE_KEY)
    local candidates = {}
    local selection = {
        candidates = candidates,
        fallbacks = candidates,
        allCandidates = {},
    }

    for index, data in ipairs(RCC.db.glideItems) do
        local candidate

        if data.isToy then
            candidate = Selection.Toy(inputs.toys, data.itemID, data, index)
        else
            candidate =
                Selection.Item(inputs.inventory, data.itemID, data, index)
        end

        selection.allCandidates[data.itemID] = candidate

        if candidate.itemID == preferredID then
            selection.preferred = candidate
        end

        if candidate.itemID == RCC.db.glideDefaultItemID then
            selection.defaultCandidate = candidate
        end

        -- Keep collected but currently restricted toys in the flyout. Their
        -- restriction is visible and they can still be chosen as a preference.
        if candidate.owned or Selection.IsAvailable(candidate) then
            candidates[#candidates + 1] = candidate
        end
    end

    Selection.ApplyItemCooldowns(
        selection,
        inputs.cooldowns,
        RCC.db.glideCooldownItemIDs
    )
    table.sort(candidates, higherPriority)

    -- Automatic selection favors a ready toy before consuming a kit. Explicit
    -- preferences are never replaced for cooldowns, restrictions, or zero count.
    return Selection.Resolve(selection, { preferenceKey = PREFERENCE_KEY })
end
