local _, RCC = ...

RCC.ConsumableFrameButtonState = RCC.ConsumableFrameButtonState or {}

local State = RCC.ConsumableFrameButtonState

local F = RCC.F

State.READY_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Ready"
State.NOT_READY_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-NotReady"

State.DEFAULTS = {
    showInLayout = true,
    statusTexture = State.NOT_READY_TEXTURE,
    showStatusTexture = true,
    desaturated = true,
    countText = "",
    countTextIsBad = false,
    detailText = "",
    detailTextIsBad = false,
    hasConsumableBuff = false,
    glow = false,
}

-- Consumable modules return partial input state. The renderer normalizes that
-- input before applying it, so omitted fields use State.DEFAULTS.
function State.Create(fields)
    local state = {}

    if fields then
        for key, value in pairs(fields) do
            state[key] = value
        end
    end

    return state
end

function State.Normalize(state)
    local normalized = {}

    for key, value in pairs(State.DEFAULTS) do
        normalized[key] = value
    end

    if state then
        for key, value in pairs(state) do
            normalized[key] = value
        end
    end

    return normalized
end

function State.SetUnavailable(state, text)
    if not state or not text then return end

    state.unavailable = {
        text = text,
    }
end

function State.SetHoverState(state, hoverState)
    if not state or not hoverState then return end

    state.hoverState = hoverState
end

function State.SetHoverUnavailable(state, text, fields)
    if not state or not text then return end

    local hoverState = State.Create(fields)

    State.SetUnavailable(hoverState, text)
    State.SetHoverState(state, hoverState)
end

function State.GetUnavailableText(state, hoverActive)
    if not state then return end

    if hoverActive and state.hoverState then
        local unavailable = state.hoverState.unavailable
        local hoverText = unavailable and unavailable.text

        if hoverText then
            return hoverText
        end
    end

    return state.unavailable and state.unavailable.text
end

function State.GetClickHintItemID(state)
    if not state then return end

    if state.clickHintItemID then
        return state.clickHintItemID
    end

    return state.action and state.action.itemID
end

function State.GetClickHintSpellID(state)
    if not state then return end

    return state.clickHintSpellID or (state.action and state.action.spellID)
end

function State.IsShownInLayout(state)
    local showInLayout = state and state.showInLayout

    if showInLayout == nil then
        showInLayout = State.DEFAULTS.showInLayout
    end

    return showInLayout == true
end

function State.HasConsumableBuff(state)
    local hasConsumableBuff = state and state.hasConsumableBuff

    if hasConsumableBuff == nil then
        hasConsumableBuff = State.DEFAULTS.hasConsumableBuff
    end

    return hasConsumableBuff == true
end

function State.GetIcon(state, defaultIcon, hoverActive)
    local icon = state and state.icon

    if hoverActive
        and state
        and state.hoverState
        and state.hoverState.icon
    then
        icon = state.hoverState.icon
    end

    return icon or defaultIcon
end

function State.CreateItemChoice(candidate, actionType, options)
    if not candidate or not candidate.itemID then return end

    options = options or {}

    local action = {
        type = actionType,
        itemID = candidate.itemID,
        targetSlot = options.targetSlot,
        available = options.available,
        cacheKey = options.cacheKey,
    }

    return State.Create({
        icon = candidate.icon,
        desaturated = false,
        countText = options.countText or tostring(candidate.count or 0),
        tooltipItemID = candidate.itemID,
        qualityItemID = candidate.itemID,
        clickHintItemID = candidate.itemID,
        action = action,
    })
end

function State.CreateItemFlyoutChoices(candidates, selectedItemID, actionType,
                                       options)
    if not candidates then return end

    options = options or {}

    if not options.includeSingleChoice and #candidates <= 1 then
        return
    end

    local choices = {}

    for i = 1, #candidates do
        local candidate = candidates[i]

        if candidate.itemID ~= selectedItemID then
            local choiceOptions = {
                targetSlot = options.targetSlot,
                available = options.available,
                cacheKey = options.cacheKey,
            }

            if options.getCountText then
                choiceOptions.countText = options.getCountText(candidate)
            else
                choiceOptions.countText = options.countText
            end

            local choice = State.CreateItemChoice(
                candidate,
                actionType,
                choiceOptions
            )

            if choice then
                choices[#choices + 1] = choice
            end
        end
    end

    if #choices > 0 then
        return choices
    end
end

function State.ApplyActiveAura(state, auraState)
    if not state or not auraState or not auraState.active then return end

    state.statusTexture = State.READY_TEXTURE
    state.hasConsumableBuff = true
    state.desaturated = false

    if auraState.icon then
        state.icon = auraState.icon
    end

    if auraState.remaining then
        state.detailText = F.FormatDuration(auraState.remaining)
    end

    if auraState.timeIsBad ~= nil then
        state.detailTextIsBad = auraState.timeIsBad
    end

    if auraState.auraInstanceID then
        state.tooltipAuraID = auraState.auraInstanceID
    end
end
