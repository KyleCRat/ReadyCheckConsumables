local _, RCC = ...

RCC.ConsumablePresenters = RCC.ConsumablePresenters or {}
local InkyBlackPotion = {}
RCC.ConsumablePresenters.InkyBlackPotion = InkyBlackPotion

local ButtonState = RCC.ConsumableState

local OUT_OF_ITEMS = "No Inky Black Potions found in Bags"

function InkyBlackPotion.Present(model)
    local auraState = model.effect
    local candidate = model.selection.candidate
    local itemID = candidate.itemID
    local count = candidate.count or 0
    local buttonState = ButtonState.Create({
        countText = tostring(count),
        tooltipItemID = itemID,
        clickHintItemID = itemID,
        icon = candidate.icon,
        showStatusTexture = false,
        suppressGlow = true,
    })

    ButtonState.ApplyActiveAura(buttonState, auraState)

    if count > 0 then
        buttonState.action = model.action
    elseif auraState then
        ButtonState.SetHoverUnavailable(buttonState, OUT_OF_ITEMS)
    else
        ButtonState.SetUnavailable(buttonState, OUT_OF_ITEMS)
    end

    ButtonState.ApplyAuraScanAvailability(
        buttonState,
        model.available == true
    )

    -- This is an optional visual effect, not a readiness state. Keep both the
    -- item and active-buff icons at full color.
    buttonState.desaturated = false

    return buttonState
end
