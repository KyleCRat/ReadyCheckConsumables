local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Flask = RCC.Consumables.Flask or {}

local Flask = RCC.Consumables.Flask

local Auras = RCC.ConsumableFrameAuras
local ButtonState = RCC.ConsumableFrameButtonState
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType
local CacheKey = RCC.ConsumableItemCacheKey

local OUT_OF_ITEMS = "No Flasks found in Bags"
local OUT_OF_SELECTED_ITEM = "Selected Flask not found in Bags"

local function getFlaskAuraState(state)
    local aura = Auras.FindBySpellID(state, RCC.db.flaskBuffIDs)

    return Auras.ToConsumableState(
        aura,
        { includeExpirationState = true }
    )
end

function Flask.Update(button, state)
    local flaskState = getFlaskAuraState(state)
    local isFlask = flaskState and flaskState.satisfied
    local flaskCandidate, flaskCandidates, outOfCachedFlask =
        Flask.GetItemCandidate(true)
    local flaskCount = flaskCandidate and flaskCandidate.count or 0
    local flaskItemID = flaskCandidate and flaskCandidate.itemID
    local buttonState = ButtonState.Create()

    ButtonState.ApplyActiveAura(buttonState, flaskState)

    if flaskItemID then
        buttonState.tooltipItemID = flaskItemID
        buttonState.qualityItemID = flaskItemID

        if flaskCandidate.icon then
            buttonState.icon = flaskCandidate.icon
        end
    end

    if flaskCount > 0 then
        buttonState.action = {
            type = ActionType.ITEM_MACRO,
            itemID = flaskItemID,
            cacheKey = CacheKey.FLASK,
        }
    elseif outOfCachedFlask then
        if flaskState then
            ButtonState.SetHoverUnavailable(buttonState, OUT_OF_SELECTED_ITEM)
        else
            ButtonState.SetUnavailable(buttonState, OUT_OF_SELECTED_ITEM)
        end
    else
        if not flaskState then
            ButtonState.SetUnavailable(buttonState, OUT_OF_ITEMS)
        end
    end

    buttonState.countText = flaskItemID and tostring(flaskCount) or ""
    buttonState.glow = not isFlask and flaskCount > 0
    buttonState.flyoutChoices = ButtonState.CreateItemFlyoutChoices(
        flaskCandidates,
        flaskItemID,
        ActionType.ITEM_MACRO,
        {
            cacheKey = CacheKey.FLASK,
            includeSingleChoice = outOfCachedFlask,
        }
    )

    Renderer.Apply(button, buttonState)
end
