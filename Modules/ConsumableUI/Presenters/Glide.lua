local _, RCC = ...

RCC.ConsumablePresenters = RCC.ConsumablePresenters or {}
local Glide = {}
RCC.ConsumablePresenters.Glide = Glide

local State = RCC.ConsumableState
local Selection = RCC.ConsumableSelection
local PREFERENCE_KEY = RCC.ConsumablePreferenceKey.GLIDE
local OUT_OF_ITEMS = "No glider kits or usable parasol toys available"
local OUT_OF_PREFERRED_ITEM = "Your preferred glide item is not in your bags"
local TOY_NOT_COLLECTED = "You haven't collected this toy"
local TOY_UNUSABLE = "This toy can't be used by this character or in this area"

local function getUnavailableText(candidate, preferred)
    if candidate.isToy then
        if not candidate.owned then return TOY_NOT_COLLECTED end
        if not candidate.usable then return TOY_UNUSABLE end
    elseif candidate.count == 0 then
        return preferred and OUT_OF_PREFERRED_ITEM or OUT_OF_ITEMS
    end
end

local function createChoice(candidate)
    local state = State.CreateItemChoice(candidate, {
        preferenceKey = PREFERENCE_KEY,
        suppressGlow = true,
    })

    state.showStatusTexture = false
    state.desaturated = not Selection.IsAvailable(candidate)

    if state.desaturated then
        state.action = nil
        state.preference = {
            key = PREFERENCE_KEY,
            capacity = 1,
            choice = candidate.choice,
        }
        State.SetUnavailable(state, getUnavailableText(candidate))
    end

    return state
end

function Glide.Present(model)
    local selection = model.selection
    local candidate = selection.candidate or selection.defaultCandidate
    local state = createChoice(candidate)
    state.action = model.action

    if not selection.candidate then state.preference = nil end

    State.SetUnavailable(
        state,
        getUnavailableText(candidate, selection.preferred ~= nil)
    )
    State.ApplyItemCooldowns(state, selection)

    -- A cooldown may change automatic selection during combat. Keep the
    -- prepared button's availability aligned with the toy/item it still uses.
    state.itemVisuals = {}

    for itemID, item in pairs(selection.allCandidates) do
        local text = getUnavailableText(
            item,
            itemID == candidate.itemID and selection.preferred ~= nil
        )

        state.itemVisuals[itemID] = {
            desaturated = not Selection.IsAvailable(item),
            unavailable = text and { text = text } or nil,
        }
    end

    return state
end

function Glide.Choices(selection)
    local primary = selection.candidate or selection.defaultCandidate
    local choices = {}

    for _, candidate in ipairs(selection.candidates) do
        if candidate.itemID ~= primary.itemID then
            choices[#choices + 1] = createChoice(candidate)
        end
    end

    if #choices > 0 then return choices end
end
