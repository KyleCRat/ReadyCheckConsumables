local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.InkyBlackPotion =
    RCC.Consumables.InkyBlackPotion or {}

local InkyBlackPotion = RCC.Consumables.InkyBlackPotion

local Auras = RCC.ConsumableFrameAuras
local ButtonState = RCC.ConsumableState

local OUT_OF_ITEMS = "No Inky Black Potions found in Bags"

local function getAuraState(state)
    local aura = Auras.FindBySpellID(
        state,
        RCC.db.inkyBlackPotionBuffIDs
    )

    return Auras.ToConsumableState(
        aura,
        { includeExpirationState = true }
    )
end

function InkyBlackPotion.ResolveState(state)
    local auraState = getAuraState(state)
    local candidate = InkyBlackPotion.GetItemCandidate()
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
        buttonState.action = ButtonState.CreateItemAction(itemID)
    elseif auraState then
        ButtonState.SetHoverUnavailable(buttonState, OUT_OF_ITEMS)
    else
        ButtonState.SetUnavailable(buttonState, OUT_OF_ITEMS)
    end

    ButtonState.ApplyAuraScanAvailability(
        buttonState,
        state and state.available == true
    )

    -- This is an optional visual effect, not a readiness state. Keep both the
    -- item and active-buff icons at full color.
    buttonState.desaturated = false

    return buttonState
end
