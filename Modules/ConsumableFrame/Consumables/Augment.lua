local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Augment = RCC.Consumables.Augment or {}

local Augment = RCC.Consumables.Augment

local ButtonState = RCC.ConsumableFrameButtonState
local F = RCC.F
local Renderer = RCC.ConsumableFrameRenderer

local GetItemCount = C_Item.GetItemCount
local GetItemIcon = C_Item.GetItemIconByID

local function getAuraState(state)
    if not state or not state.auras then return end

    for i = 1, #state.auras do
        local aura = state.auras[i]

        if RCC.db.augmentBuffIDs[aura.spellID] then
            return {
                active = true,
                icon = aura.icon,
                remaining = aura.remaining,
                satisfied = true,
            }
        end
    end
end

local function applyAuraState(stateTable, state)
    if not state or not state.active then return end

    stateTable.statusTexture = ButtonState.READY_TEXTURE
    stateTable.hasConsumableBuff = true
    stateTable.desaturated = false
    stateTable.icon = state.icon

    if state.remaining then
        stateTable.timeText = F.FormatDuration(state.remaining)
    end
end

local function findItemInBags()
    local bestItemID
    local bestCount
    local bestData
    local bestXpac = -1
    local bestPriority = -1
    local preferUnlimited =
        RCC.GetSetting("consumables_preferUnlimitedAugment")

    for itemID, data in pairs(RCC.db.augmentItemIDs) do
        local count = GetItemCount(itemID, false, true)

        if count and count > 0 then
            local xpac = data.xpac or 0
            local priority = data.priority or 0
            local unlimited = data.unlimited == true
            local bestUnlimited = bestData
                and bestData.unlimited == true
                or false

            if preferUnlimited and unlimited ~= bestUnlimited
                and unlimited
            then
                bestItemID = itemID
                bestCount = count
                bestData = data
                bestXpac = xpac
                bestPriority = priority
            elseif not (preferUnlimited and unlimited ~= bestUnlimited)
                and (xpac > bestXpac
                    or (xpac == bestXpac and priority > bestPriority)
                    or (xpac == bestXpac and priority == bestPriority
                        and itemID > (bestItemID or 0)))
            then
                bestItemID = itemID
                bestCount = count
                bestData = data
                bestXpac = xpac
                bestPriority = priority
            end
        end
    end

    return bestItemID, bestCount, bestData
end

function Augment.Update(button, state)
    local augmentState = getAuraState(state)
    local isAugment = augmentState and augmentState.satisfied
    local augmentItemID, augmentItemCount, augmentItemData = findItemInBags()
    local buttonState = ButtonState.Create()

    applyAuraState(buttonState, augmentState)

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

        buttonState.action = {
            type = ButtonState.ACTION_ITEM_MACRO,
            itemID = augmentItemID,
        }
    else
        buttonState.countText = "0"
        buttonState.action = {
            type = ButtonState.ACTION_DISABLE,
        }

        if not isAugment then
            buttonState.outOfItemsText = "No Augment Runes found in Bags"
        end
    end

    buttonState.glow = augmentItemID ~= nil and not isAugment

    Renderer.Apply(button, buttonState)
end
