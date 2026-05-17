local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Flask = RCC.Consumables.Flask or {}

local Flask = RCC.Consumables.Flask

local Auras = RCC.ConsumableFrameAuras
local Actions = RCC.ConsumableFrameActions
local ButtonState = RCC.ConsumableFrameButtonState
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local GetItemInfoInstant = C_Item.GetItemInfoInstant

local function getFlaskAuraState(state, expireWarnSeconds)
    local aura = Auras.FindBySpellID(state, RCC.db.flaskBuffIDs)

    return Auras.ToConsumableState(aura, {
        expireWarnSeconds = expireWarnSeconds,
    })
end

function Flask.Update(button, state)
    local flaskState = getFlaskAuraState(state, button.expireWarnSeconds)
    local isFlask = flaskState and flaskState.satisfied
    local flaskCandidate = ItemCandidates.FindFirstAvailable(
        RCC.db.flaskItemIDs,
        ItemCandidates.BAGS_ONLY
    )
    local flaskCount = flaskCandidate and flaskCandidate.count or 0
    local flaskItemID = flaskCandidate and flaskCandidate.itemID
    local buttonState = ButtonState.Create()

    ButtonState.ApplyActiveAura(buttonState, flaskState)

    if flaskCount > 0 then
        buttonState.tooltipItemID = flaskItemID
        buttonState.usableItemID = flaskItemID

        if not isFlask then
            local texture = select(5, GetItemInfoInstant(flaskItemID))

            if texture then
                buttonState.icon = texture
            end
        end

        buttonState.action = Actions.CreateItemMacro(flaskItemID)
    else
        buttonState.action = Actions.CreateDisabled()

        if not isFlask then
            buttonState.outOfItemsText = "No Flasks found in Bags"
        end
    end

    buttonState.countText = flaskCount > 0 and tostring(flaskCount) or ""
    buttonState.glow = not isFlask and flaskCount > 0

    Renderer.Apply(button, buttonState)
end
