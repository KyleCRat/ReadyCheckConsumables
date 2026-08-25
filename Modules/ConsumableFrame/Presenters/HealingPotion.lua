local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.HealingPotion = RCC.Consumables.HealingPotion or {}

local HealingPotion = RCC.Consumables.HealingPotion

local ButtonState = RCC.ConsumableState

local CacheKey = RCC.ConsumableItemCacheKey

function HealingPotion.ResolveState()
    local inventoryItemCandidate, inventoryItemCandidates, outOfCachedPotion =
        HealingPotion.GetItemCandidate(true)
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
        buttonState.action = ButtonState.CreateItemAction(inventoryItem, {
            preferenceKey = CacheKey.HEALING_POTION,
            selectionOnly = true,
        })
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
        {
            preferenceKey = CacheKey.HEALING_POTION,
            selectionOnly = true,
            includeSingleChoice = outOfCachedPotion,
            suppressGlow = true,
        }
    )

    return buttonState
end
