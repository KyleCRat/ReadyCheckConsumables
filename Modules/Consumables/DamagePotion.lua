local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.DamagePotion = RCC.Consumables.DamagePotion or {}

local DamagePotion = RCC.Consumables.DamagePotion

local ItemCandidates = RCC.ConsumableFrameItemCandidates

-- TODO: Update logic to only show most powerful found pot?
-- This will get weird if a healer has dmg pots and mana pots
function DamagePotion.GetItemCandidate()
    return ItemCandidates.FindFirstAvailable(
        RCC.db.potionItemIDs,
        ItemCandidates.BAGS_ONLY
    )
end
