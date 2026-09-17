local _, RCC = ...

RCC.ConsumablePresenters = RCC.ConsumablePresenters or {}
local ConsumableStasis = {}
RCC.ConsumablePresenters.ConsumableStasis = ConsumableStasis

local ButtonState = RCC.ConsumableState

function ConsumableStasis.Present(model)
    local candidate = model.selection.candidate
    local itemID = candidate and candidate.itemID
        or model.selection.fallback.itemID
    local count = candidate and candidate.count or 0
    local state = ButtonState.Create({
        showStatusTexture = false,
        countText = tostring(count),
        tooltipItemID = itemID,
        clickHintItemID = itemID,
        icon = (candidate or model.selection.fallback).icon,
    })

    if candidate then
        state.desaturated = false
        state.action = model.action
    end

    return state
end
