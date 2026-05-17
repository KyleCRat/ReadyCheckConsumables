local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.DamagePotion = RCC.Consumables.DamagePotion or {}

local DamagePotion = RCC.Consumables.DamagePotion

local ButtonState = RCC.ConsumableFrameButtonState
local Renderer = RCC.ConsumableFrameRenderer

local GetItemCount = C_Item.GetItemCount
local GetItemIcon = C_Item.GetItemIconByID

-- TODO: Update logic to only show most powerful found pot?
-- This will get weird if a healer has dmg pots and mana pots
function DamagePotion.Update(button)
    local inventoryItem
    local inventoryItemCount

    for i = 1, #RCC.db.potionItemIDs do
        local item = RCC.db.potionItemIDs[i]
        local count = GetItemCount(item, false, true)

        if count and count > 0 then
            inventoryItem = item
            inventoryItemCount = count

            break
        end
    end

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
