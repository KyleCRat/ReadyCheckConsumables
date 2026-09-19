local _, RCC = ...

RCC.ConsumablePresenters = RCC.ConsumablePresenters or {}
local Flask = {}
RCC.ConsumablePresenters.Flask = Flask

local ButtonState = RCC.ConsumableState

local PreferenceKey = RCC.ConsumablePreferenceKey

local OUT_OF_ITEMS = "No Flasks found in Bags"
local OUT_OF_SELECTED_ITEM = "Selected Flask not found in Bags"

function Flask.Present(model)
    local flaskState = model.effect
    local isFlask = flaskState and flaskState.satisfied
    local flaskCandidate, flaskCandidates, outOfCachedFlask =
        RCC.ConsumableSelection.Unpack(model.selection)
    local flaskCount = flaskCandidate and flaskCandidate.count or 0
    local flaskItemID = flaskCandidate and flaskCandidate.itemID
    local buttonState = ButtonState.Create()

    ButtonState.ApplyActiveAura(buttonState, flaskState)

    if flaskItemID then
        buttonState.tooltipItemID = flaskItemID
        ButtonState.SetItemQuality(buttonState, flaskCandidate)

        if flaskCandidate.icon then
            buttonState.icon = flaskCandidate.icon
        end
    end

    if flaskCount > 0 then
        buttonState.action = model.action
    elseif outOfCachedFlask then
        if flaskState then
            ButtonState.SetHoverUnavailable(buttonState, OUT_OF_SELECTED_ITEM)
        else
            ButtonState.SetUnavailable(buttonState, OUT_OF_SELECTED_ITEM)
        end
    else
        if not flaskState then
            ButtonState.SetUnavailable(buttonState, OUT_OF_ITEMS)
        end
    end

    buttonState.countText = flaskItemID and tostring(flaskCount) or ""
    buttonState.glow = not isFlask
        and flaskCount > 0

    ButtonState.ApplyAuraScanAvailability(
        buttonState,
        model.available == true
    )

    return buttonState
end

function Flask.Choices(selection)
    local flaskCandidate, flaskCandidates, outOfCachedFlask = RCC.ConsumableSelection.Unpack(selection)
    local flaskItemID = flaskCandidate and flaskCandidate.itemID

    return ButtonState.CreateItemFlyoutChoices(
        flaskCandidates,
        flaskItemID,
        {
            preferenceKey = PreferenceKey.FLASK,
            includeSingleChoice = outOfCachedFlask,
        }
    )
end
