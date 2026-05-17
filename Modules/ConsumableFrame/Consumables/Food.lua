local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Food = RCC.Consumables.Food or {}

local Food = RCC.Consumables.Food

local Auras = RCC.ConsumableFrameAuras
local ButtonState = RCC.ConsumableFrameButtonState
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType

local function buildFlyoutChoices(candidates, selectedItemID)
    if not candidates or #candidates <= 1 then return end

    local choices = {}

    for i = 1, #candidates do
        local candidate = candidates[i]

        if candidate.itemID ~= selectedItemID then
            choices[#choices + 1] = ButtonState.CreateItemChoice(
                candidate,
                ActionType.ITEM_MACRO
            )
        end
    end

    if #choices > 0 then
        return choices
    end
end

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

    local foodCandidates = ItemCandidates.CollectAvailableFromList(
        RCC.db.foodItemIDs,
        ItemCandidates.BAGS_ONLY
    )
    local foodCandidate = foodCandidates[1]
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
            if foodCandidate.icon then
                buttonState.icon = foodCandidate.icon
            end
        end

        buttonState.action = {
            type = ActionType.ITEM_MACRO,
            itemID = foodItemID,
        }
    else
        if not foodSatisfied then
            buttonState.outOfItemsText = "No Food found in Bags"
        end
    end

    buttonState.countText = foodCount > 0 and tostring(foodCount) or ""
    buttonState.glow = not foodSatisfied and foodCount > 0
    buttonState.flyoutChoices = buildFlyoutChoices(
        foodCandidates,
        foodItemID
    )

    Renderer.Apply(button, buttonState)
end
