local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.ConsumableStasis =
    RCC.Consumables.ConsumableStasis or {}

local ConsumableStasis = RCC.Consumables.ConsumableStasis

local ButtonState = RCC.ConsumableFrameButtonState
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType

function ConsumableStasis.Update(button, showInLayout)
    local candidate = ConsumableStasis.GetItemCandidate()
    local itemID = candidate and candidate.itemID
        or ConsumableStasis.GetDefaultItemID()
    local count = candidate and candidate.count or 0
    local state = ButtonState.Create({
        showInLayout = showInLayout,
        showStatusTexture = false,
        countText = tostring(count),
        tooltipItemID = itemID,
        clickHintItemID = itemID,
        icon = ItemCandidates.GetIcon(itemID),
    })

    if candidate then
        state.desaturated = false
        state.action = {
            type = ActionType.ITEM_MACRO,
            itemID = candidate.itemID,
        }
    end

    Renderer.Apply(button, state)
end
