local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Food = RCC.Consumables.Food or {}

local Food = RCC.Consumables.Food

local Auras = RCC.ConsumableFrameAuras
local ButtonState = RCC.ConsumableFrameButtonState
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local GetItemInfoInstant = C_Item.GetItemInfoInstant

local function getFoodAuraState(state)
    local foodState
    local eatingState

    if not state or not state.auras then
        return nil, nil
    end

    for i = 1, #state.auras do
        local aura = state.auras[i]

        if RCC.db.foodBuffIDs[aura.spellID]
            or RCC.db.foodIconIDs[aura.icon]
        then
            if RCC.db.eatingIconIDs[aura.icon] then
                eatingState = Auras.ToConsumableState(aura, {
                    includeAuraInstanceID = false,
                })
            else
                foodState = Auras.ToConsumableState(aura, {
                    satisfied = true,
                })
            end
        end
    end

    if foodState then
        return foodState, nil
    end

    if eatingState then
        eatingState.satisfied = true

        return eatingState, eatingState
    end

    return nil, nil
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
    local foodState, eatingState = getFoodAuraState(state)
    local isFood = foodState and foodState.satisfied
    local foodCandidate = ItemCandidates.FindFirstAvailable(
        RCC.db.foodItemIDs,
        ItemCandidates.BAGS_ONLY
    )
    local foodCount = foodCandidate and foodCandidate.count or 0
    local foodItemID = foodCandidate and foodCandidate.itemID
    local buttonState = ButtonState.Create({
        cooldown = getEatingCooldown(eatingState),
    })

    ButtonState.ApplyActiveAura(buttonState, foodState)

    if foodCount > 0 then
        buttonState.tooltipItemID = foodItemID
        buttonState.usableItemID = foodItemID

        if not isFood then
            local texture = select(5, GetItemInfoInstant(foodItemID))

            if texture then
                buttonState.icon = texture
            end
        end

        buttonState.action = {
            type = ButtonState.ACTION_ITEM_MACRO,
            itemID = foodItemID,
        }
    else
        buttonState.action = {
            type = ButtonState.ACTION_DISABLE,
        }

        if not isFood then
            buttonState.outOfItemsText = "No Food found in Bags"
        end
    end

    buttonState.countText = foodCount > 0 and tostring(foodCount) or ""
    buttonState.glow = not isFood and foodCount > 0

    Renderer.Apply(button, buttonState)
end
