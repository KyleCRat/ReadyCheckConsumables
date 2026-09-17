local _, RCC = ...

RCC.ConsumablePresenters = RCC.ConsumablePresenters or {}
local HealingPotion = {}
RCC.ConsumablePresenters.HealingPotion = HealingPotion

local ButtonState = RCC.ConsumableState

local CacheKey = RCC.ConsumableItemCacheKey

function HealingPotion.Present(model)
    local inventoryItemCandidate, inventoryItemCandidates, outOfCachedPotion =
        RCC.ConsumableSelection.Unpack(model.selection)
    local inventoryItem = inventoryItemCandidate
        and inventoryItemCandidate.itemID
    local inventoryItemCount = inventoryItemCandidate
        and inventoryItemCandidate.count or 0
    local buttonState = ButtonState.Create({
        countText = inventoryItem and tostring(inventoryItemCount) or "0",
        suppressGlow = true,
    })

    if inventoryItem and inventoryItemCount > 0 then
        buttonState.statusIcon = ButtonState.READY_ICON
        buttonState.desaturated = false
        buttonState.action = model.action
    end

    if inventoryItem then
        buttonState.tooltipItemID = inventoryItem
        ButtonState.SetItemQuality(buttonState, inventoryItemCandidate)

        if inventoryItemCandidate.icon then
            buttonState.icon = inventoryItemCandidate.icon
        end
    end
    return buttonState
end

function HealingPotion.Choices(selection)
    local inventoryItemCandidate, inventoryItemCandidates, outOfCachedPotion = RCC.ConsumableSelection.Unpack(selection)
    local inventoryItem = inventoryItemCandidate and inventoryItemCandidate.itemID
    return ButtonState.CreateItemFlyoutChoices(
        inventoryItemCandidates,
        inventoryItem,
        {
            preferenceKey = CacheKey.HEALING_POTION,
            selectionOnly = true,
            includeSingleChoice = outOfCachedPotion,
            suppressGlow = true,
        }
    )
end
