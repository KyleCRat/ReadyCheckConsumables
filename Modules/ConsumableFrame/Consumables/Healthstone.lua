local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Healthstone = RCC.Consumables.Healthstone or {}

local Healthstone = RCC.Consumables.Healthstone

local ButtonState = RCC.ConsumableFrameButtonState

local GetItemCount = C_Item.GetItemCount

function Healthstone.Update(button)
    local totalCount = 0

    for itemID in pairs(RCC.db.healthstoneItemIDs) do
        local count = GetItemCount(itemID, false, true)

        if count and count > 0 then
            totalCount = totalCount + count
        end
    end

    if totalCount > 0 then
        ButtonState.Apply(button, ButtonState.Create({
            countText = tostring(totalCount),
            statusTexture = ButtonState.READY_TEXTURE,
            desaturated = false,
            tooltipItemID = RCC.db.healthstone_item_id,
        }))
    else
        ButtonState.Apply(button, ButtonState.Create({
            countText = "0",
        }))
    end
end
