local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Food = RCC.Consumables.Food or {}

local Food = RCC.Consumables.Food

local Auras = RCC.ConsumableFrameAuras
local ButtonState = RCC.ConsumableFrameButtonState
local FoodAuras = RCC.FoodAuras
local ItemCache = RCC.ConsumableFrameItemCache
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType
local CacheKey = RCC.ConsumableItemCacheKey
local FOOD_AURA_TYPE = FoodAuras.Type

local OUT_OF_ITEMS = "No Food found in Bags"
local OUT_OF_SELECTED_ITEM = "Selected Food not found in Bags"

local function getDisplayAuraState(foodAuraState, eatingAuraState)
    if eatingAuraState
        and (not foodAuraState or foodAuraState.timeIsBad)
    then
        return eatingAuraState
    end

    return foodAuraState
end

local function getFoodAuraStates(state)
    local foodAuraState
    local eatingAuraState

    if not state or not state.auras then
        return nil, nil
    end

    for i = 1, #state.auras do
        local aura = state.auras[i]
        local auraType = FoodAuras.GetType(aura, aura.spellID)

        if auraType == FOOD_AURA_TYPE.EATING then
            eatingAuraState = Auras.ToConsumableState(aura, {
                includeAuraInstanceID = false,
            })
        elseif auraType == FOOD_AURA_TYPE.WELL_FED then
            foodAuraState = Auras.ToConsumableState(
                aura,
                { includeExpirationState = true }
            )
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
    local foodAuraState, eatingAuraState = getFoodAuraStates(state)
    local displayAuraState = getDisplayAuraState(
        foodAuraState,
        eatingAuraState
    )
    local hasFoodCoverage = foodAuraState ~= nil or eatingAuraState ~= nil
    local foodSatisfied = eatingAuraState ~= nil
        or (foodAuraState and foodAuraState.satisfied == true)

    local foodCandidates = ItemCandidates.CollectAvailableFromList(
        RCC.db.foodItemIDs,
        ItemCandidates.BAGS_ONLY
    )
    local cachedFoodCandidate = ItemCandidates.CreateFromList(
        RCC.db.foodItemIDs,
        ItemCache.Get(CacheKey.FOOD),
        ItemCandidates.BAGS_ONLY
    )
    local foodCandidate = ItemCache.SelectCandidate(
        CacheKey.FOOD,
        foodCandidates,
        cachedFoodCandidate
    )
    local outOfCachedFood = ItemCache.IsUnavailableCachedCandidate(
        CacheKey.FOOD,
        foodCandidate
    )
    local foodCount = foodCandidate and foodCandidate.count or 0
    local foodItemID = foodCandidate and foodCandidate.itemID
    local buttonState = ButtonState.Create({
        cooldown = getEatingCooldown(eatingAuraState),
    })

    ButtonState.ApplyActiveAura(buttonState, displayAuraState)

    if foodItemID then
        buttonState.tooltipItemID = foodItemID
        buttonState.qualityItemID = foodItemID

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
        buttonState.action = {
            type = ActionType.ITEM_MACRO,
            itemID = foodItemID,
            cacheKey = CacheKey.FOOD,
        }
    elseif outOfCachedFood and not hasFoodCoverage then
        ButtonState.SetUnavailable(buttonState, OUT_OF_SELECTED_ITEM)
    else
        if not hasFoodCoverage then
            ButtonState.SetUnavailable(buttonState, OUT_OF_ITEMS)
        end
    end

    buttonState.countText = foodItemID and tostring(foodCount) or ""
    buttonState.glow = not foodSatisfied and foodCount > 0
    buttonState.flyoutChoices = ButtonState.CreateItemFlyoutChoices(
        foodCandidates,
        foodItemID,
        ActionType.ITEM_MACRO,
        {
            cacheKey = CacheKey.FOOD,
            includeSingleChoice = outOfCachedFood,
        }
    )

    Renderer.Apply(button, buttonState)
end
