local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.HealingPotion = RCC.Consumables.HealingPotion or {}

local HealingPotion = RCC.Consumables.HealingPotion

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
        button.count:SetFormattedText("%d", inventoryItemCount)
        button.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        button.texture:SetTexture(GetItemIcon(inventoryItem))
        button.texture:SetDesaturated(false)
        button.tooltipItemID = inventoryItem
    else
        button.count:SetText("0")
    end
end
