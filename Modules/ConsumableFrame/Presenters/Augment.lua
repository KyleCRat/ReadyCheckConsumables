local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Augment = RCC.Consumables.Augment or {}

local Augment = RCC.Consumables.Augment

local Auras = RCC.ConsumableFrameAuras
local ButtonState = RCC.ConsumableFrameButtonState
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType
local CacheKey = RCC.ConsumableItemCacheKey

local OUT_OF_ITEMS = "No Augment Runes found in Bags"
local OUT_OF_SELECTED_ITEM = "Selected Augment Rune not found in Bags"

local function getAuraState(state)
    local aura = Auras.FindBySpellID(state, RCC.db.augmentBuffIDs)

    return Auras.ToConsumableState(
        aura,
        { includeExpirationState = true }
    )
end

function Augment.Update(button, state)
    local augmentState = getAuraState(state)
    local isAugment = augmentState and augmentState.satisfied
    local augmentCandidate, augmentCandidates, outOfCachedAugment =
        Augment.GetItemCandidate(true)
    local augmentItemID = augmentCandidate and augmentCandidate.itemID
    local augmentItemCount = augmentCandidate and augmentCandidate.count
    local augmentItemIcon = augmentCandidate and augmentCandidate.icon
    local buttonState = ButtonState.Create()

    ButtonState.ApplyActiveAura(buttonState, augmentState)

    if augmentItemID then
        buttonState.countText = Augment.GetCountText(augmentCandidate)
        buttonState.tooltipItemID = augmentItemID
        buttonState.qualityItemID = augmentItemID

        if augmentItemIcon then
            buttonState.icon = augmentItemIcon
        end
    else
        buttonState.countText = "0"
    end

    if augmentItemID and augmentItemCount and augmentItemCount > 0 then
        buttonState.action = {
            type = ActionType.ITEM_MACRO,
            itemID = augmentItemID,
            cacheKey = CacheKey.AUGMENT,
        }
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
    buttonState.flyoutChoices = ButtonState.CreateItemFlyoutChoices(
        augmentCandidates,
        augmentItemID,
        ActionType.ITEM_MACRO,
        {
            getCountText = Augment.GetCountText,
            cacheKey = CacheKey.AUGMENT,
            includeSingleChoice = outOfCachedAugment,
        }
    )

    Renderer.Apply(button, buttonState)
end
