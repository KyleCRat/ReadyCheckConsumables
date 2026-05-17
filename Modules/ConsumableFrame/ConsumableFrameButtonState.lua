local _, RCC = ...

RCC.ConsumableFrameButtonState = RCC.ConsumableFrameButtonState or {}

local State = RCC.ConsumableFrameButtonState

local F = RCC.F

State.READY_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Ready"
State.NOT_READY_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-NotReady"

-- Buttons are reset before module updates, so omitted fields keep the reset
-- defaults for the current update pass.
function State.Create(fields)
    local state = {}

    if fields then
        for key, value in pairs(fields) do
            state[key] = value
        end
    end

    return state
end

function State.CreateItemChoice(candidate, actionType, options)
    if not candidate or not candidate.itemID then return end

    options = options or {}

    local action = {
        type = actionType,
        itemID = candidate.itemID,
        targetSlot = options.targetSlot,
        available = options.available,
    }

    return State.Create({
        icon = candidate.icon,
        desaturated = false,
        countText = options.countText or tostring(candidate.count or 0),
        tooltipItemID = candidate.itemID,
        usableItemID = candidate.itemID,
        clickHintItemID = candidate.itemID,
        action = action,
    })
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
