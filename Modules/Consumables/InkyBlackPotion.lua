local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.InkyBlackPotion =
    RCC.Consumables.InkyBlackPotion or {}

local InkyBlackPotion = RCC.Consumables.InkyBlackPotion

local ItemCandidates = RCC.ConsumableFrameItemCandidates

function InkyBlackPotion.GetItemCandidate()
    local itemID = RCC.db.inkyBlackPotionItemID

    return {
        itemID = itemID,
        count = ItemCandidates.GetCount(
            itemID,
            ItemCandidates.BAGS_ONLY
        ),
        icon = ItemCandidates.GetIcon(itemID),
    }
end
