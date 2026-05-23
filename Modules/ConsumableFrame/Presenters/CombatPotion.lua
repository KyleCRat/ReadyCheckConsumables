local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.CombatPotion = RCC.Consumables.CombatPotion or {}

local CombatPotion = RCC.Consumables.CombatPotion

local ButtonState = RCC.ConsumableFrameButtonState
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType
local CacheKey = RCC.ConsumableItemCacheKey

function CombatPotion.Update(button)
    local inventoryItemCandidate, inventoryItemCandidates, outOfCachedPotion =
        CombatPotion.GetItemCandidate(true)
    local inventoryItem = inventoryItemCandidate
        and inventoryItemCandidate.itemID
    local inventoryItemCount = inventoryItemCandidate
        and inventoryItemCandidate.count or 0
    local buttonState = ButtonState.Create({
        countText = inventoryItem and tostring(inventoryItemCount) or "0",
        suppressGlow = true,
    })

    if inventoryItem and inventoryItemCount > 0 then
        buttonState.statusTexture = ButtonState.READY_TEXTURE
        buttonState.desaturated = false
        buttonState.action = {
            type = ActionType.ITEM_CACHE_SELECT,
            itemID = inventoryItem,
            cacheKey = CacheKey.COMBAT_POTION,
        }
    end

    if inventoryItem then
        buttonState.tooltipItemID = inventoryItem
        buttonState.qualityItemID = inventoryItem

        if inventoryItemCandidate.icon then
            buttonState.icon = inventoryItemCandidate.icon
        end
    end

    buttonState.flyoutChoices = ButtonState.CreateItemFlyoutChoices(
        inventoryItemCandidates,
        inventoryItem,
        ActionType.ITEM_CACHE_SELECT,
        {
            cacheKey = CacheKey.COMBAT_POTION,
            includeSingleChoice = outOfCachedPotion,
            suppressGlow = true,
        }
    )

    Renderer.Apply(button, buttonState)
end
