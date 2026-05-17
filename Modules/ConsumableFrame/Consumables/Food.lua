local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Food = RCC.Consumables.Food or {}

local Food = RCC.Consumables.Food

local Auras = RCC.ConsumableFrameAuras
local Actions = RCC.ConsumableFrameActions
local ButtonState = RCC.ConsumableFrameButtonState
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local GetItemInfoInstant = C_Item.GetItemInfoInstant

local function getFoodAuraStates(state, expireWarnSeconds)
    local foodAuraState
    local eatingAuraState

    if not state or not state.auras then
        return nil, nil
    end

    for i = 1, #state.auras do
        local aura = state.auras[i]

        if RCC.db.foodBuffIDs[aura.spellID]
            or RCC.db.foodIconIDs[aura.icon]
        then
            if RCC.db.eatingIconIDs[aura.icon] then
                eatingAuraState = Auras.ToConsumableState(aura, {
                    includeAuraInstanceID = false,
                })
            else
                foodAuraState = Auras.ToConsumableState(aura, {
                    expireWarnSeconds = expireWarnSeconds,
                })
            end
        end
    end

    return foodAuraState, eatingAuraState
end

local function getEatingCooldown(state)
    if state
        and state.remaining
        and Auras.IsPositiveDuration(state.duration)
    then
        local cooldownStart = state.expiry - state.duration

        return {
            start = cooldownStart,
            duration = state.duration,
        }
    end

    return { clear = true }
end

function Food.Update(button, state)
    local foodAuraState, eatingAuraState = getFoodAuraStates(
        state,
        button.expireWarnSeconds
    )
    local displayAuraState = foodAuraState or eatingAuraState
    local foodSatisfied = eatingAuraState ~= nil

    if foodAuraState then
        foodSatisfied = foodAuraState.satisfied == true
    end

    local foodCandidate = ItemCandidates.FindFirstAvailable(
        RCC.db.foodItemIDs,
        ItemCandidates.BAGS_ONLY
    )
    local foodCount = foodCandidate and foodCandidate.count or 0
    local foodItemID = foodCandidate and foodCandidate.itemID
    local buttonState = ButtonState.Create({
        cooldown = getEatingCooldown(eatingAuraState),
    })

    ButtonState.ApplyActiveAura(buttonState, displayAuraState)

    if foodCount > 0 then
        buttonState.tooltipItemID = foodItemID
        buttonState.usableItemID = foodItemID

        if not foodSatisfied then
            local texture = select(5, GetItemInfoInstant(foodItemID))

            if texture then
                buttonState.icon = texture
            end
        end

        buttonState.action = Actions.CreateItemMacro(foodItemID)
    else
        if not foodSatisfied then
            buttonState.outOfItemsText = "No Food found in Bags"
        end
    end

    buttonState.countText = foodCount > 0 and tostring(foodCount) or ""
    buttonState.glow = not foodSatisfied and foodCount > 0

    Renderer.Apply(button, buttonState)
end
