local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.HealingPotion = RCC.Consumables.HealingPotion or {}

local HealingPotion = RCC.Consumables.HealingPotion

local ButtonState = RCC.ConsumableFrameButtonState

local GetItemCount = C_Item.GetItemCount
local GetItemIcon = C_Item.GetItemIconByID

function HealingPotion.Update(button)
    local inventoryItem
    local inventoryItemCount

    for i = 1, #RCC.db.healingPotionItemIDs do
        local item = RCC.db.healingPotionItemIDs[i]
        local count = GetItemCount(item, false, true)

        if count and count > 0 then
            inventoryItem = item
            inventoryItemCount = count

            break
        end
    end

    if inventoryItem and inventoryItemCount > 0 then
        ButtonState.Apply(button, ButtonState.Create({
            countText = tostring(inventoryItemCount),
            statusTexture = ButtonState.READY_TEXTURE,
            icon = GetItemIcon(inventoryItem),
            desaturated = false,
            tooltipItemID = inventoryItem,
        }))
    else
        ButtonState.Apply(button, ButtonState.Create({
            countText = "0",
        }))
    end
end
