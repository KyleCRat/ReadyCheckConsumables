local _, RCC = ...

RCC.ConsumablePresenters = RCC.ConsumablePresenters or {}
local Healthstone = {}
RCC.ConsumablePresenters.Healthstone = Healthstone

local ButtonState = RCC.ConsumableState

function Healthstone.Present(model)
    local showHealthstone = model.applicable
    local candidate = model.selection.candidate
    local count = candidate and candidate.count or 0
    local itemID = candidate and candidate.itemID or RCC.db.healthstoneItemID
    local icon = candidate and candidate.icon

    if count > 0 then
        return ButtonState.Create({
            applicable = showHealthstone,
            countText = tostring(count),
            icon = icon,
            statusIcon = ButtonState.READY_ICON,
            desaturated = false,
            tooltipItemID = itemID,
            clickHintItemID = itemID,
            action = model.action,
        })
    end

    return ButtonState.Create({
        applicable = showHealthstone,
        countText = "0",
        tooltipItemID = itemID,
        action = model.action,
    })
end
