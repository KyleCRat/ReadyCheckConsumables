local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.HealingPotion = RCC.Consumables.HealingPotion or {}

local HealingPotion = RCC.Consumables.HealingPotion

local ItemCandidates = RCC.ConsumableFrameItemCandidates

function HealingPotion.GetItemCandidate()
    return ItemCandidates.FindFirstAvailable(
        RCC.db.healingPotionItemIDs,
        ItemCandidates.BAGS_ONLY
    )
end
