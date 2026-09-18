local _, RCC = ...

RCC.ConsumablePresenters = RCC.ConsumablePresenters or {}
local Vantus = {}
RCC.ConsumablePresenters.Vantus = Vantus

local ButtonState = RCC.ConsumableState
local F = RCC.F

local CacheKey = RCC.ConsumableItemCacheKey

local OUT_OF_ITEMS = "No Vantus Runes found in Bags"
local OUT_OF_SELECTED_ITEM = "Selected Vantus Rune not found in Bags"

local function getAuraBossName(aura)
    local name = F.GetPublicAuraField(aura, "name")

    if not name then return end

    local bossName = name:gsub("^Vantus Rune: ", "")

    return bossName
end

function Vantus.Present(model)
    local selection = model.selection

    if not selection.applicable then
        return ButtonState.Create({ applicable = false })
    end

    local vantusAura = model.effect
    local bossName = getAuraBossName(vantusAura)
    local candidate, candidates, outOfCachedItem =
        RCC.ConsumableSelection.Unpack(selection)

    local itemID = candidate and candidate.itemID
    local count = candidate and candidate.count or 0
    local icon = candidate and candidate.icon

    if not itemID then
        itemID, icon = selection.fallback.itemID, selection.fallback.icon
    end

    local buttonState = ButtonState.Create()
    buttonState.icon = icon
    buttonState.tooltipItemID = itemID

    if vantusAura then
        if bossName then
            buttonState.detailText = bossName
        end

        buttonState.statusIcon = ButtonState.READY_ICON
        buttonState.hasConsumableBuff = true
        buttonState.desaturated = false
        buttonState.glow = false

        if count > 0 or outOfCachedItem then
            buttonState.countText = tostring(count)
        end

        if outOfCachedItem then
            ButtonState.SetHoverUnavailable(
                buttonState,
                OUT_OF_SELECTED_ITEM
            )
        end
    elseif count > 0 then
        buttonState.countText = tostring(count)
        ButtonState.SetItemQuality(buttonState, candidate)
        buttonState.glow = true
        buttonState.action = model.action
    else
        buttonState.countText = "0"
        buttonState.glow = false
        ButtonState.SetUnavailable(
            buttonState,
            outOfCachedItem and OUT_OF_SELECTED_ITEM or OUT_OF_ITEMS
        )
    end

    ButtonState.ApplyAuraScanAvailability(
        buttonState,
        model.available == true
    )

    return buttonState
end

function Vantus.Choices(selection)
    local candidate = selection.candidate or selection.fallback

    return ButtonState.CreateItemFlyoutChoices(selection.candidates, candidate and candidate.itemID, {
        preferenceKey = CacheKey.VANTUS,
        includeSingleChoice = selection.unavailable,
    })
end
