local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Vantus = RCC.Consumables.Vantus or {}

local Vantus = RCC.Consumables.Vantus

local Auras = RCC.ConsumableFrameAuras
local ButtonState = RCC.ConsumableFrameButtonState
local ItemCache = RCC.ConsumableFrameItemCache
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType
local CacheKey = RCC.ConsumableItemCacheKey

local OUT_OF_ITEMS = "No Vantus Runes found in Bags"
local OUT_OF_SELECTED_ITEM = "Selected Vantus Rune not found in Bags"

local function getAuraBossName(state)
    local aura = Auras.FindBySpellID(state, RCC.db.vantusBuffIDs)

    if not aura then return end

    local name = aura.name or ""

    return name:gsub("^Vantus Rune: ", "")
end

local function getVantusForCurrentRaid()
    local instanceID = select(8, GetInstanceInfo())
    local vantusRuneIDs = RCC.db.vantusItemsByRaid[instanceID]

    if not vantusRuneIDs then
        return nil, nil, 0
    end

    local candidates = ItemCandidates.CollectAvailableFromList(
        vantusRuneIDs,
        ItemCandidates.BAGS_ONLY
    )
    local cachedCandidate = ItemCandidates.CreateFromList(
        vantusRuneIDs,
        ItemCache.Get(CacheKey.VANTUS),
        ItemCandidates.BAGS_ONLY
    )
    local candidate = ItemCache.SelectCandidate(
        CacheKey.VANTUS,
        candidates,
        cachedCandidate
    )
    local outOfCachedItem = ItemCache.IsUnavailableCachedCandidate(
        CacheKey.VANTUS,
        candidate
    )

    if candidate then
        return vantusRuneIDs, candidate.itemID, candidate.count,
            candidate.icon, candidates, outOfCachedItem
    end

    local itemID = vantusRuneIDs[1]

    return vantusRuneIDs, itemID, 0, ItemCandidates.GetIcon(itemID),
        candidates, false
end

function Vantus.Update(button, state)
    local bossName = getAuraBossName(state)
    local vantusRuneIDs, itemID, count, icon, candidates, outOfCachedItem =
        getVantusForCurrentRaid()
    local buttonState = ButtonState.Create()

    if not vantusRuneIDs then
        buttonState.showInLayout = false

        Renderer.Apply(button, buttonState)

        return
    end

    buttonState.showInLayout = true

    if itemID then
        buttonState.icon = icon
    end

    if bossName then
        buttonState.tooltipItemID = itemID
        buttonState.detailText = bossName
        buttonState.statusTexture = ButtonState.READY_TEXTURE
        buttonState.hasConsumableBuff = true
        buttonState.desaturated = false

        if count > 0 or outOfCachedItem then
            buttonState.countText = tostring(count)
        end

        if outOfCachedItem then
            ButtonState.SetHoverUnavailable(buttonState, OUT_OF_SELECTED_ITEM)
        end

        Renderer.Apply(button, buttonState)

        return
    end

    if itemID and count > 0 then
        buttonState.countText = tostring(count)
        buttonState.tooltipItemID = itemID
        buttonState.usableItemID = itemID
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

        Renderer.Apply(button, buttonState)

        return
    end

    buttonState.countText = "0"
    buttonState.tooltipItemID = itemID
    ButtonState.SetUnavailable(
        buttonState,
        outOfCachedItem and OUT_OF_SELECTED_ITEM or OUT_OF_ITEMS
    )
    buttonState.glow = false
    buttonState.flyoutChoices = ButtonState.CreateItemFlyoutChoices(
        candidates,
        itemID,
        ActionType.ITEM_MACRO,
        {
            cacheKey = CacheKey.VANTUS,
            includeSingleChoice = outOfCachedItem,
        }
    )

    Renderer.Apply(button, buttonState)
end
