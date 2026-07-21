local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Vantus = RCC.Consumables.Vantus or {}

local Vantus = RCC.Consumables.Vantus

local Auras = RCC.ConsumableFrameAuras
local ButtonState = RCC.ConsumableFrameButtonState
local F = RCC.F
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType
local CacheKey = RCC.ConsumableItemCacheKey

local OUT_OF_ITEMS = "No Vantus Runes found in Bags"
local OUT_OF_SELECTED_ITEM = "Selected Vantus Rune not found in Bags"

local function getAuraBossName(aura)
    local name = F.GetPublicAuraField(aura, "name")

    if not name then return end

    local bossName = name:gsub("^Vantus Rune: ", "")

    return bossName
end

function Vantus.Update(button, state)
    local vantusRuneIDs = Vantus.GetRuneIDsForCurrentRaid()

    if not vantusRuneIDs then
        Renderer.Apply(button, ButtonState.Create({ showInLayout = false }))

        return
    end

    local vantusAura = Auras.FindBySpellID(state, RCC.db.vantusBuffIDs)
    local bossName = getAuraBossName(vantusAura)
    local candidate, candidates, outOfCachedItem =
        Vantus.GetItemCandidate(vantusRuneIDs, true)

    local itemID = candidate and candidate.itemID
    local count = candidate and candidate.count or 0
    local icon = candidate and candidate.icon

    if not itemID then
        itemID, icon = Vantus.GetFallbackItem(vantusRuneIDs)
    end

    local buttonState = ButtonState.Create()
    buttonState.showInLayout = true
    buttonState.icon = icon
    buttonState.tooltipItemID = itemID

    if vantusAura then
        if bossName then
            buttonState.detailText = bossName
        end

        buttonState.statusTexture = ButtonState.READY_TEXTURE
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
        buttonState.qualityItemID = itemID
        buttonState.glow = true
        buttonState.action = {
            type = ActionType.ITEM_MACRO,
            itemID = itemID,
            cacheKey = CacheKey.VANTUS,
        }
        buttonState.flyoutChoices = ButtonState.CreateItemFlyoutChoices(
            candidates,
            itemID,
            ActionType.ITEM_MACRO,
            { cacheKey = CacheKey.VANTUS }
        )
    else
        buttonState.countText = "0"
        buttonState.glow = false
        ButtonState.SetUnavailable(
            buttonState,
            outOfCachedItem and OUT_OF_SELECTED_ITEM or OUT_OF_ITEMS
        )
        buttonState.flyoutChoices = ButtonState.CreateItemFlyoutChoices(
            candidates,
            itemID,
            ActionType.ITEM_MACRO,
            {
                cacheKey = CacheKey.VANTUS,
                includeSingleChoice = outOfCachedItem,
            }
        )
    end

    Renderer.Apply(button, buttonState)
end
