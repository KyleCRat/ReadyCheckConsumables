local _, RCC = ...

RCC.ConsumablePresenters = RCC.ConsumablePresenters or {}
local Healthstone = {}
RCC.ConsumablePresenters.Healthstone = Healthstone

local ButtonState = RCC.ConsumableState

function Healthstone.Present(model)
    local showHealthstone = model.applicable
    local totalCount = model.selection.count

    if totalCount > 0 then
        return ButtonState.Create({
            applicable = showHealthstone,
            countText = tostring(totalCount),
            statusIcon = ButtonState.READY_ICON,
            desaturated = false,
            tooltipItemID = RCC.db.healthstoneItemID,
            clickHintItemID = RCC.db.healthstoneItemID,
            action = model.action,
        })
    end

    return ButtonState.Create({
        applicable = showHealthstone,
        countText = "0",
        tooltipItemID = RCC.db.healthstoneItemID,
        action = model.action,
    })
end
