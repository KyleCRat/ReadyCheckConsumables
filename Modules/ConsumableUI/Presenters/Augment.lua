local _, RCC = ...

RCC.ConsumablePresenters = RCC.ConsumablePresenters or {}
local Augment = {}
RCC.ConsumablePresenters.Augment = Augment

local ButtonState = RCC.ConsumableState

local CacheKey = RCC.ConsumableItemCacheKey

local OUT_OF_ITEMS = "No Augment Runes found in Bags"
local OUT_OF_SELECTED_ITEM = "Selected Augment Rune not found in Bags"

function Augment.Present(model)
    local augmentState = model.effect
    local isAugment = augmentState and augmentState.satisfied
    local augmentCandidate, augmentCandidates, outOfCachedAugment =
        RCC.ConsumableSelection.Unpack(model.selection)
    local augmentItemID = augmentCandidate and augmentCandidate.itemID
    local augmentItemCount = augmentCandidate and augmentCandidate.count
    local augmentItemIcon = augmentCandidate and augmentCandidate.icon
    local buttonState = ButtonState.Create()

    ButtonState.ApplyActiveAura(buttonState, augmentState)
    ButtonState.ApplyItemCooldowns(buttonState, model.selection)

    -- Item availability follows the prepared action during combat, while buff
    -- status still applies to all runes.
    buttonState.itemVisuals = {}
    buttonState.missingItemVisual = { unavailable = { text = OUT_OF_SELECTED_ITEM } }

    for _, candidate in ipairs(augmentCandidates) do
        buttonState.itemVisuals[candidate.itemID] = {}
    end

    if augmentItemID then
        buttonState.countText = RCC.Consumables.Augment.GetCountText(augmentCandidate)
        buttonState.tooltipItemID = augmentItemID
        ButtonState.SetItemQuality(buttonState, augmentCandidate)

        if augmentItemIcon then
            buttonState.icon = augmentItemIcon
        end
    else
        buttonState.countText = "0"
    end

    if augmentItemID and augmentItemCount and augmentItemCount > 0 then
        buttonState.action = model.action
    elseif outOfCachedAugment then
        buttonState.countText = "0"

        if augmentState then
            ButtonState.SetHoverUnavailable(buttonState, OUT_OF_SELECTED_ITEM)
        else
            ButtonState.SetUnavailable(buttonState, OUT_OF_SELECTED_ITEM)
        end
    else
        if not augmentState then
            ButtonState.SetUnavailable(buttonState, OUT_OF_ITEMS)
        end
    end

    buttonState.glow = augmentItemCount ~= nil
        and augmentItemCount > 0
        and not isAugment

    ButtonState.ApplyAuraScanAvailability(
        buttonState,
        model.available == true
    )

    return buttonState
end

function Augment.Choices(selection)
    local augmentCandidate, augmentCandidates, outOfCachedAugment = RCC.ConsumableSelection.Unpack(selection)
    local augmentItemID = augmentCandidate and augmentCandidate.itemID

    return ButtonState.CreateItemFlyoutChoices(
        augmentCandidates,
        augmentItemID,
        {
            getCountText = RCC.Consumables.Augment.GetCountText,
            preferenceKey = CacheKey.AUGMENT,
            includeSingleChoice = outOfCachedAugment,
        }
    )
end
