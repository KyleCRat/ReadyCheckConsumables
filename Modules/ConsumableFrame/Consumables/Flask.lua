local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Flask = RCC.Consumables.Flask or {}

local Flask = RCC.Consumables.Flask

local Auras = RCC.ConsumableFrameAuras
local ButtonState = RCC.ConsumableFrameButtonState
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType

local function getFlaskAuraState(state, expireWarnSeconds)
    local aura = Auras.FindBySpellID(state, RCC.db.flaskBuffIDs)

    return Auras.ToConsumableState(aura, {
        expireWarnSeconds = expireWarnSeconds,
    })
end

function Flask.Update(button, state)
    local flaskState = getFlaskAuraState(state, button.expireWarnSeconds)
    local isFlask = flaskState and flaskState.satisfied
    local flaskCandidates = ItemCandidates.CollectAvailableFromList(
        RCC.db.flaskItemIDs,
        ItemCandidates.BAGS_ONLY
    )
    local flaskCandidate = flaskCandidates[1]
    local flaskCount = flaskCandidate and flaskCandidate.count or 0
    local flaskItemID = flaskCandidate and flaskCandidate.itemID
    local buttonState = ButtonState.Create()

    ButtonState.ApplyActiveAura(buttonState, flaskState)

    if flaskCount > 0 then
        buttonState.tooltipItemID = flaskItemID
        buttonState.usableItemID = flaskItemID

        if not isFlask then
            if flaskCandidate.icon then
                buttonState.icon = flaskCandidate.icon
            end
        end

        buttonState.action = {
            type = ActionType.ITEM_MACRO,
            itemID = flaskItemID,
        }
    else
        if not isFlask then
            buttonState.outOfItemsText = "No Flasks found in Bags"
        end
    end

    buttonState.countText = flaskCount > 0 and tostring(flaskCount) or ""
    buttonState.glow = not isFlask and flaskCount > 0
    buttonState.flyoutChoices = ButtonState.CreateItemFlyoutChoices(
        flaskCandidates,
        flaskItemID,
        ActionType.ITEM_MACRO
    )

    Renderer.Apply(button, buttonState)
end
