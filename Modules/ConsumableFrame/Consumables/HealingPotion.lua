local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.HealingPotion = RCC.Consumables.HealingPotion or {}

local HealingPotion = RCC.Consumables.HealingPotion

local ButtonState = RCC.ConsumableFrameButtonState
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

function HealingPotion.Update(button)
    local inventoryItemCandidate = ItemCandidates.FindFirstAvailable(
        RCC.db.healingPotionItemIDs,
        ItemCandidates.BAGS_ONLY
    )
    local inventoryItem = inventoryItemCandidate
        and inventoryItemCandidate.itemID
    local inventoryItemCount = inventoryItemCandidate
        and inventoryItemCandidate.count

    if inventoryItem and inventoryItemCount > 0 then
        Renderer.Apply(button, ButtonState.Create({
            countText = tostring(inventoryItemCount),
            statusTexture = ButtonState.READY_TEXTURE,
            icon = inventoryItemCandidate.icon,
            desaturated = false,
            tooltipItemID = inventoryItem,
            qualityItemID = inventoryItem,
        }))
    else
        Renderer.Apply(button, ButtonState.Create({
            countText = "0",
        }))
    end
end
