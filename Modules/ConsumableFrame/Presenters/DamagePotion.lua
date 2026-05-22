local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.DamagePotion = RCC.Consumables.DamagePotion or {}

local DamagePotion = RCC.Consumables.DamagePotion

local ButtonState = RCC.ConsumableFrameButtonState
local Renderer = RCC.ConsumableFrameRenderer

function DamagePotion.Update(button)
    local inventoryItemCandidate = DamagePotion.GetItemCandidate()
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
