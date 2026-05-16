local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.DamagePotion = RCC.Consumables.DamagePotion or {}

local DamagePotion = RCC.Consumables.DamagePotion

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
        button.count:SetFormattedText("%d", inventoryItemCount)
        button.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        button.texture:SetTexture(GetItemIcon(inventoryItem))
        button.texture:SetDesaturated(false)
        button.tooltipItemID = inventoryItem
    else
        button.count:SetText("0")
    end
end
