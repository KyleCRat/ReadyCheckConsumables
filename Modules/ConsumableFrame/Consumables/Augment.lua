local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Augment = RCC.Consumables.Augment or {}

local Augment = RCC.Consumables.Augment

local Actions = RCC.ConsumableFrameActions
local F = RCC.F
local Glow = RCC.ConsumableFrameGlow

local GetItemCount = C_Item.GetItemCount
local GetItemIcon = C_Item.GetItemIconByID

local setButtonGlow = Glow.Set

local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

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

local function applyAuraState(button, state)
    if not state or not state.active then return end

    button.statustexture:SetTexture(READY)
    button.hasConsumableBuff = true
    button.texture:SetDesaturated(false)
    button.texture:SetTexture(state.icon)

    if state.remaining then
        button.timeleft:SetText(F.FormatDuration(state.remaining))
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

    applyAuraState(button, augmentState)

    if augmentItemID and augmentItemCount and augmentItemCount > 0 then
        if augmentItemData and augmentItemData.unlimited then
            button.count:SetText("")
        else
            button.count:SetFormattedText("%d", augmentItemCount)
        end

        button.tooltipItemID = augmentItemID
        button.usableItemID = augmentItemID

        if not isAugment then
            local icon = GetItemIcon(augmentItemID)

            if icon then
                button.texture:SetTexture(icon)
            end
        end

        Actions.SetItemMacro(button, augmentItemID)
    else
        button.count:SetText("0")

        Actions.Disable(button)

        if not isAugment then
            button.outOfItemsText = "No Augment Runes found in Bags"
        end
    end

    if augmentItemID and not isAugment then
        setButtonGlow(button, true)
    else
        setButtonGlow(button, false)
    end
end
