local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.DamagePotion = RCC.Consumables.DamagePotion or {}

local DamagePotion = RCC.Consumables.DamagePotion

local ButtonState = RCC.ConsumableFrameButtonState
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local GetItemIcon = C_Item.GetItemIconByID

-- TODO: Update logic to only show most powerful found pot?
-- This will get weird if a healer has dmg pots and mana pots
function DamagePotion.Update(button)
    local inventoryItemCandidate = ItemCandidates.FindFirstAvailable(
        RCC.db.potionItemIDs,
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
            icon = GetItemIcon(inventoryItem),
            desaturated = false,
            tooltipItemID = inventoryItem,
        }))
    else
        Renderer.Apply(button, ButtonState.Create({
            countText = "0",
        }))
    end
end
