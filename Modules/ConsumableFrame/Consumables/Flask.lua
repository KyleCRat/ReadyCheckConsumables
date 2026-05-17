local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Flask = RCC.Consumables.Flask or {}

local Flask = RCC.Consumables.Flask

local ButtonState = RCC.ConsumableFrameButtonState
local F = RCC.F
local Renderer = RCC.ConsumableFrameRenderer

local GetItemCount = C_Item.GetItemCount
local GetItemInfoInstant = C_Item.GetItemInfoInstant

local function getFlaskAuraState(state)
    if not state or not state.auras then return end

    for i = 1, #state.auras do
        local aura = state.auras[i]

        if RCC.db.flaskBuffIDs[aura.spellID] then
            return {
                active = true,
                icon = aura.icon,
                remaining = aura.remaining,
                satisfied = not (aura.remaining and aura.remaining <= 600),
            }
        end
    end
end

local function applyAuraState(stateTable, state)
    if not state or not state.active then return end

    stateTable.statusTexture = ButtonState.READY_TEXTURE
    stateTable.hasConsumableBuff = true
    stateTable.desaturated = false

    if state.icon then
        stateTable.icon = state.icon
    end

    if state.remaining then
        stateTable.timeText = F.FormatDuration(state.remaining)
        stateTable.timeIsBad = not state.satisfied
    end
end

function Flask.Update(button, state)
    local flaskState = getFlaskAuraState(state)
    local isFlask = flaskState and flaskState.satisfied
    local flaskCount = 0
    local flaskItemID
    local buttonState = ButtonState.Create()

    applyAuraState(buttonState, flaskState)

    for flaskIndex = 1, #RCC.db.flaskItemIDs do
        local itemID = RCC.db.flaskItemIDs[flaskIndex]
        local count = GetItemCount(itemID, false, false)

        if count and count > 0 then
            flaskItemID = itemID
            flaskCount = count

            break
        end
    end

    if flaskCount > 0 then
        buttonState.tooltipItemID = flaskItemID
        buttonState.usableItemID = flaskItemID

        if not isFlask then
            local texture = select(5, GetItemInfoInstant(flaskItemID))

            if texture then
                buttonState.icon = texture
            end
        end

        buttonState.action = {
            type = ButtonState.ACTION_ITEM_MACRO,
            itemID = flaskItemID,
        }
    else
        buttonState.action = {
            type = ButtonState.ACTION_DISABLE,
        }

        if not isFlask then
            buttonState.outOfItemsText = "No Flasks found in Bags"
        end
    end

    buttonState.countText = flaskCount > 0 and tostring(flaskCount) or ""
    buttonState.glow = not isFlask and flaskCount > 0

    Renderer.Apply(button, buttonState)
end
