local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Augment = RCC.Consumables.Augment or {}

local Augment = RCC.Consumables.Augment

local Auras = RCC.ConsumableFrameAuras
local ButtonState = RCC.ConsumableFrameButtonState
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType

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

local function buildFlyoutChoices(candidates, selectedItemID)
    if not candidates or #candidates <= 1 then return end

    local choices = {}

    for i = 1, #candidates do
        local candidate = candidates[i]

        if candidate.itemID ~= selectedItemID then
            choices[#choices + 1] = ButtonState.CreateItemChoice(
                candidate,
                ActionType.ITEM_MACRO,
                { countText = getCountText(candidate) }
            )
        end
    end

    if #choices > 0 then
        return choices
    end
end

local function getAuraState(state, expireWarnSeconds)
    local aura = Auras.FindBySpellID(state, RCC.db.augmentBuffIDs)

    return Auras.ToConsumableState(aura, {
        expireWarnSeconds = expireWarnSeconds,
    })
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
    local augmentState = getAuraState(state, button.expireWarnSeconds)
    local isAugment = augmentState and augmentState.satisfied
    local augmentCandidates = collectItemsInBags()
    local augmentCandidate = augmentCandidates[1]
    local augmentItemID = augmentCandidate and augmentCandidate.itemID
    local augmentItemCount = augmentCandidate and augmentCandidate.count
    local augmentItemData = augmentCandidate and augmentCandidate.data
    local augmentItemIcon = augmentCandidate and augmentCandidate.icon
    local buttonState = ButtonState.Create()

    ButtonState.ApplyActiveAura(buttonState, augmentState)

    if augmentItemID and augmentItemCount and augmentItemCount > 0 then
        if augmentItemData and augmentItemData.unlimited then
            buttonState.countText = ""
        else
            buttonState.countText = tostring(augmentItemCount)
        end

        buttonState.tooltipItemID = augmentItemID
        buttonState.usableItemID = augmentItemID

        if not isAugment then
            if augmentItemIcon then
                buttonState.icon = augmentItemIcon
            end
        end

        buttonState.action = {
            type = ActionType.ITEM_MACRO,
            itemID = augmentItemID,
        }
    else
        buttonState.countText = "0"

        if not isAugment then
            buttonState.outOfItemsText = "No Augment Runes found in Bags"
        end
    end

    buttonState.glow = augmentItemID ~= nil and not isAugment
    buttonState.flyoutChoices = buildFlyoutChoices(
        augmentCandidates,
        augmentItemID
    )

    Renderer.Apply(button, buttonState)
end
