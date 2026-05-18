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

local function getVantusRuneIDsForCurrentRaid()
    local instanceID = select(8, GetInstanceInfo())

    return RCC.db.vantusItemsByRaid[instanceID]
end

local function getVantusCandidate(vantusRuneIDs)
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

    return candidate, candidates, outOfCachedItem
end

local function getFallbackVantusIcon(vantusRuneIDs)
    local itemID = vantusRuneIDs[1]

    return itemID, ItemCandidates.GetIcon(itemID)
end

function Vantus.Update(button, state)
    local vantusRuneIDs = getVantusRuneIDsForCurrentRaid()

    if not vantusRuneIDs then
        Renderer.Apply(button, ButtonState.Create({ showInLayout = false }))

        return
    end

    local bossName = getAuraBossName(state)
    local candidate, candidates, outOfCachedItem =
        getVantusCandidate(vantusRuneIDs)

    local itemID = candidate and candidate.itemID
    local count = candidate and candidate.count or 0
    local icon = candidate and candidate.icon

    if not itemID then
        itemID, icon = getFallbackVantusIcon(vantusRuneIDs)
    end

    local buttonState = ButtonState.Create()
    buttonState.showInLayout = true
    buttonState.icon = icon
    buttonState.tooltipItemID = itemID

    if bossName then
        buttonState.detailText = bossName
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
        buttonState.usableItemID = itemID
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
