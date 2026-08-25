local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.ConsumableStasis =
    RCC.Consumables.ConsumableStasis or {}

local ConsumableStasis = RCC.Consumables.ConsumableStasis

local ButtonState = RCC.ConsumableState
local ItemCandidates = RCC.ConsumableFrameItemCandidates

function ConsumableStasis.ResolveState()
    local candidate = ConsumableStasis.GetItemCandidate()
    local itemID = candidate and candidate.itemID
        or ConsumableStasis.GetDefaultItemID()
    local count = candidate and candidate.count or 0
    local state = ButtonState.Create({
        showStatusTexture = false,
        countText = tostring(count),
        tooltipItemID = itemID,
        clickHintItemID = itemID,
        icon = ItemCandidates.GetIcon(itemID),
    })

    if candidate then
        state.desaturated = false
        state.action = ButtonState.CreateItemAction(candidate.itemID)
    end

    return state
end
