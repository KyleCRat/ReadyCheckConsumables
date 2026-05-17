local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Food = RCC.Consumables.Food or {}

local Food = RCC.Consumables.Food

local Auras = RCC.ConsumableFrameAuras
local ButtonState = RCC.ConsumableFrameButtonState
local F = RCC.F
local Renderer = RCC.ConsumableFrameRenderer

local GetItemCount = C_Item.GetItemCount
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
                eatingState = {
                    active = true,
                    duration = aura.duration,
                    expiry = aura.expiry,
                    icon = aura.icon,
                    remaining = aura.remaining,
                }
            else
                foodState = {
                    active = true,
                    auraInstanceID = aura.auraInstanceID,
                    expiry = aura.expiry,
                    icon = aura.icon,
                    remaining = aura.remaining,
                    satisfied = true,
                }
            end
        end
    end

    if foodState then
        return foodState, nil
    end

    if eatingState then
        return {
            active = true,
            expiry = eatingState.expiry,
            icon = eatingState.icon,
            remaining = eatingState.remaining,
            satisfied = true,
        }, eatingState
    end

    return nil, nil
end

local function applyAuraState(stateTable, state)
    if not state or not state.active then return end

    stateTable.statusTexture = ButtonState.READY_TEXTURE
    stateTable.hasConsumableBuff = true
    stateTable.desaturated = false

    if state.remaining then
        stateTable.timeText = F.FormatDuration(state.remaining)
    end

    if state.icon then
        stateTable.icon = state.icon
    end

    if state.auraInstanceID then
        stateTable.tooltipAuraID = state.auraInstanceID
    end
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
    local foodCount = 0
    local foodItemID
    local buttonState = ButtonState.Create({
        cooldown = getEatingCooldown(eatingState),
    })

    applyAuraState(buttonState, foodState)

    for foodIndex = 1, #RCC.db.foodItemIDs do
        local itemID = RCC.db.foodItemIDs[foodIndex]
        local count = GetItemCount(itemID, false, false)

        if count and count > 0 then
            foodItemID = itemID
            foodCount = count

            break
        end
    end

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
