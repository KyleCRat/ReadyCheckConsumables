local _, RCC = ...

RCC.ConsumablePresenters = RCC.ConsumablePresenters or {}
local Food = {}
RCC.ConsumablePresenters.Food = Food

local ButtonState = RCC.ConsumableState

local CacheKey = RCC.ConsumableItemCacheKey

local OUT_OF_ITEMS = "No Food found in Bags"
local OUT_OF_SELECTED_ITEM = "Selected Food not found in Bags"

function Food.Present(model)
    local displayAuraState = model.effect
    local hasFoodCoverage = model.hasCoverage
    local foodSatisfied = model.satisfied

    local foodCandidate, foodCandidates, outOfCachedFood =
        RCC.ConsumableSelection.Unpack(model.selection)
    local foodCount = foodCandidate and foodCandidate.count or 0
    local foodItemID = foodCandidate and foodCandidate.itemID
    local buttonState = ButtonState.Create({
        cooldown = model.cooldown or { clear = true },
    })

    ButtonState.ApplyActiveAura(buttonState, displayAuraState)

    if foodItemID then
        buttonState.tooltipItemID = foodItemID
        ButtonState.SetItemQuality(buttonState, foodCandidate)

        if foodCandidate.icon then
            if displayAuraState then
                if foodCount <= 0 then
                    ButtonState.SetHoverUnavailable(
                        buttonState,
                        OUT_OF_SELECTED_ITEM,
                        { icon = foodCandidate.icon }
                    )
                else
                    ButtonState.SetHoverState(
                        buttonState,
                        ButtonState.Create({ icon = foodCandidate.icon })
                    )
                end
            else
                buttonState.icon = foodCandidate.icon
            end
        end
    end

    if foodCount > 0 then
        buttonState.action = model.action
    elseif outOfCachedFood and not hasFoodCoverage then
        ButtonState.SetUnavailable(buttonState, OUT_OF_SELECTED_ITEM)
    else
        if not hasFoodCoverage then
            ButtonState.SetUnavailable(buttonState, OUT_OF_ITEMS)
        end
    end

    buttonState.countText = foodItemID and tostring(foodCount) or ""
    buttonState.glow = not foodSatisfied
        and foodCount > 0

    ButtonState.ApplyAuraScanAvailability(
        buttonState,
        model.available == true
    )

    return buttonState
end

function Food.Choices(selection)
    local foodCandidate, foodCandidates, outOfCachedFood = RCC.ConsumableSelection.Unpack(selection)
    local foodItemID = foodCandidate and foodCandidate.itemID

    return ButtonState.CreateItemFlyoutChoices(
        foodCandidates,
        foodItemID,
        {
            preferenceKey = CacheKey.FOOD,
            includeSingleChoice = outOfCachedFood,
        }
    )
end
