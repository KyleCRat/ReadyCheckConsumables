local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Food = RCC.Consumables.Food or {}

local Food = RCC.Consumables.Food

local Actions = RCC.ConsumableFrameActions
local Auras = RCC.ConsumableFrameAuras
local F = RCC.F
local Glow = RCC.ConsumableFrameGlow

local GetItemCount = C_Item.GetItemCount
local GetItemInfoInstant = C_Item.GetItemInfoInstant

local setButtonGlow = Glow.Set

local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

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

local function applyAuraState(button, state)
    if not state or not state.active then return end

    button.statustexture:SetTexture(READY)
    button.hasConsumableBuff = true
    button.texture:SetDesaturated(false)

    if state.remaining then
        button.timeleft:SetText(F.FormatDuration(state.remaining))
    end

    if state.icon then
        button.texture:SetTexture(state.icon)
    end

    if state.auraInstanceID then
        button.tooltipAuraID = state.auraInstanceID
    end
end

local function updateEatingCooldown(button, state)
    if state
        and state.remaining
        and Auras.IsPositiveDuration(state.duration)
    then
        local cooldownStart = state.expiry - state.duration
        button.cooldown:SetCooldown(cooldownStart, state.duration)
        button.cooldown:Show()

        return
    end

    button.cooldown:Clear()
end

function Food.Update(button, state)
    local foodState, eatingState = getFoodAuraState(state)
    local isFood = foodState and foodState.satisfied
    local foodCount = 0
    local foodItemID

    applyAuraState(button, foodState)
    updateEatingCooldown(button, eatingState)

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
        button.tooltipItemID = foodItemID
        button.usableItemID = foodItemID

        if not isFood then
            local texture = select(5, GetItemInfoInstant(foodItemID))

            if texture then
                button.texture:SetTexture(texture)
            end
        end

        Actions.SetItemMacro(button, foodItemID)
    else
        Actions.Disable(button)

        if not isFood then
            button.outOfItemsText = "No Food found in Bags"
        end
    end

    button.count:SetFormattedText("%s", foodCount > 0 and foodCount or "")

    if not isFood and foodCount > 0 then
        setButtonGlow(button, true)
    else
        setButtonGlow(button, false)
    end
end
