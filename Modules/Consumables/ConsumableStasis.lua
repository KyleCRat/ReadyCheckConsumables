local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.ConsumableStasis =
    RCC.Consumables.ConsumableStasis or {}

local ConsumableStasis = RCC.Consumables.ConsumableStasis

local ItemCandidates = RCC.ConsumableFrameItemCandidates

function ConsumableStasis.GetItemCandidate()
    return ItemCandidates.FindFirstAvailable(
        RCC.db.consumableStasisItemIDs,
        ItemCandidates.BAGS_ONLY
    )
end

function ConsumableStasis.GetDefaultItemID()
    return RCC.db.consumableStasisItemIDs[1]
end
