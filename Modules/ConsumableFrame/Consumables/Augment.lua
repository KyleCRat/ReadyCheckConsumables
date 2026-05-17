local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Augment = RCC.Consumables.Augment or {}

local Augment = RCC.Consumables.Augment

local Auras = RCC.ConsumableFrameAuras
local ButtonState = RCC.ConsumableFrameButtonState
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local GetItemIcon = C_Item.GetItemIconByID

local function getAuraState(state)
    local aura = Auras.FindBySpellID(state, RCC.db.augmentBuffIDs)

    return Auras.ToConsumableState(aura, {
        satisfied = true,
    })
end

local function findItemInBags()
    local preferUnlimited =
        RCC.GetSetting("consumables_preferUnlimitedAugment")
    local candidates = ItemCandidates.CollectAvailableFromMap(
        RCC.db.augmentItemIDs,
        ItemCandidates.BAGS_ONLY
    )

    local best = ItemCandidates.SelectBest(candidates, function(candidate, best)
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
    end)

    if best then
        return best.itemID, best.count, best.data
    end
end

function Augment.Update(button, state)
    local augmentState = getAuraState(state)
    local isAugment = augmentState and augmentState.satisfied
    local augmentItemID, augmentItemCount, augmentItemData = findItemInBags()
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
            local icon = GetItemIcon(augmentItemID)

            if icon then
                buttonState.icon = icon
            end
        end

        buttonState.action = ButtonState.ItemMacroAction(augmentItemID)
    else
        buttonState.countText = "0"
        buttonState.action = ButtonState.DisableAction()

        if not isAugment then
            buttonState.outOfItemsText = "No Augment Runes found in Bags"
        end
    end

    buttonState.glow = augmentItemID ~= nil and not isAugment

    Renderer.Apply(button, buttonState)
end
