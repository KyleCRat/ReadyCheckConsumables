local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Augment = RCC.Consumables.Augment or {}

local Augment = RCC.Consumables.Augment

local Auras = RCC.ConsumableFrameAuras
local ButtonState = RCC.ConsumableFrameButtonState
local ItemCache = RCC.ConsumableFrameItemCache
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType
local CacheKey = RCC.ConsumableItemCacheKey

local OUT_OF_ITEMS = "No Augment Runes found in Bags"
local OUT_OF_SELECTED_ITEM = "Selected Augment Rune not found in Bags"

local function isBetterAugmentCandidate(candidate, best, preferUnlimited)
    local data = candidate.data or {}
    local bestData = best.data or {}
    local unlimited = data.unlimited == true
    local bestUnlimited = bestData.unlimited == true

    if preferUnlimited and unlimited ~= bestUnlimited then
        return unlimited
    end

    local xpac = data.xpac or 0
    local priority = data.priority or 0
    local bestXpac = bestData.xpac or 0
    local bestPriority = bestData.priority or 0

    return xpac > bestXpac
        or (xpac == bestXpac and priority > bestPriority)
        or (xpac == bestXpac and priority == bestPriority
            and candidate.itemID > (best.itemID or 0))
end

local function sortAugmentCandidates(candidates, preferUnlimited)
    table.sort(candidates, function(a, b)
        return isBetterAugmentCandidate(a, b, preferUnlimited)
    end)
end

local function getCountText(candidate)
    local data = candidate and candidate.data

    if data and data.unlimited then
        return ""
    end

    return tostring(candidate and candidate.count or 0)
end

local function getAuraState(state)
    local aura = Auras.FindBySpellID(state, RCC.db.augmentBuffIDs)

    return Auras.ToConsumableState(
        aura,
        { includeExpirationState = true }
    )
end

local function collectItemsInBags()
    local preferUnlimited =
        RCC.GetSetting("consumables_preferUnlimitedAugment")
    local candidates = ItemCandidates.CollectAvailableFromMap(
        RCC.db.augmentItemIDs,
        ItemCandidates.BAGS_ONLY
    )

    sortAugmentCandidates(candidates, preferUnlimited)

    return candidates
end

function Augment.Update(button, state)
    local augmentState = getAuraState(state)
    local isAugment = augmentState and augmentState.satisfied
    local augmentCandidates = collectItemsInBags()
    local cachedAugmentCandidate = ItemCandidates.CreateFromMap(
        RCC.db.augmentItemIDs,
        ItemCache.Get(CacheKey.AUGMENT),
        ItemCandidates.BAGS_ONLY
    )
    local augmentCandidate = ItemCache.SelectCandidate(
        CacheKey.AUGMENT,
        augmentCandidates,
        cachedAugmentCandidate
    )
    local outOfCachedAugment = ItemCache.IsUnavailableCachedCandidate(
        CacheKey.AUGMENT,
        augmentCandidate
    )
    local augmentItemID = augmentCandidate and augmentCandidate.itemID
    local augmentItemCount = augmentCandidate and augmentCandidate.count
    local augmentItemData = augmentCandidate and augmentCandidate.data
    local augmentItemIcon = augmentCandidate and augmentCandidate.icon
    local buttonState = ButtonState.Create()

    ButtonState.ApplyActiveAura(buttonState, augmentState)

    if augmentItemID then
        if augmentItemData and augmentItemData.unlimited then
            buttonState.countText = ""
        else
            buttonState.countText = tostring(augmentItemCount or 0)
        end

        buttonState.tooltipItemID = augmentItemID
        buttonState.usableItemID = augmentItemID

        if augmentItemIcon then
            buttonState.icon = augmentItemIcon
        end
    else
        buttonState.countText = "0"
    end

    if augmentItemID and augmentItemCount and augmentItemCount > 0 then
        buttonState.action = {
            type = ActionType.ITEM_MACRO,
            itemID = augmentItemID,
            cacheKey = CacheKey.AUGMENT,
        }
    elseif outOfCachedAugment then
        buttonState.countText = "0"

        if augmentState then
            ButtonState.SetHoverUnavailable(buttonState, OUT_OF_SELECTED_ITEM)
        else
            ButtonState.SetUnavailable(buttonState, OUT_OF_SELECTED_ITEM)
        end
    else
        if not augmentState then
            ButtonState.SetUnavailable(buttonState, OUT_OF_ITEMS)
        end
    end

    buttonState.glow = augmentItemCount ~= nil
                       and augmentItemCount > 0
                       and not isAugment
    buttonState.flyoutChoices = ButtonState.CreateItemFlyoutChoices(
        augmentCandidates,
        augmentItemID,
        ActionType.ITEM_MACRO,
        {
            getCountText = getCountText,
            cacheKey = CacheKey.AUGMENT,
            includeSingleChoice = outOfCachedAugment,
        }
    )

    Renderer.Apply(button, buttonState)
end
