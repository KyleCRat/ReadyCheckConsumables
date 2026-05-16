local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Flask = RCC.Consumables.Flask or {}

local Flask = RCC.Consumables.Flask

local Actions = RCC.ConsumableFrameActions
local F = RCC.F
local Glow = RCC.ConsumableFrameGlow

local GetItemCount = C_Item.GetItemCount
local GetItemInfoInstant = C_Item.GetItemInfoInstant

local setButtonGlow = Glow.Set

local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

local function getFlaskAuraState(state)
    if not state or not state.auras then return end

    for i = 1, #state.auras do
        local aura = state.auras[i]

        if RCC.db.flaskBuffIDs[aura.spellID] then
            return {
                active = true,
                icon = aura.icon,
                remaining = aura.remaining,
                satisfied = not (aura.remaining and aura.remaining <= 600),
            }
        end
    end
end

local function applyAuraState(button, state)
    if not state or not state.active then return end

    button.statustexture:SetTexture(READY)
    button.hasConsumableBuff = true
    button.texture:SetDesaturated(false)

    if state.icon then
        button.texture:SetTexture(state.icon)
    end

    if state.remaining then
        button.timeleft:SetText(F.FormatDuration(state.remaining))
    end
end

function Flask.Update(button, state)
    local flaskState = getFlaskAuraState(state)
    local isFlask = flaskState and flaskState.satisfied
    local flaskCount = 0
    local flaskItemID

    applyAuraState(button, flaskState)

    for flaskIndex = 1, #RCC.db.flaskItemIDs do
        local itemID = RCC.db.flaskItemIDs[flaskIndex]
        local count = GetItemCount(itemID, false, false)

        if count and count > 0 then
            flaskItemID = itemID
            flaskCount = count

            break
        end
    end

    if flaskCount > 0 then
        button.tooltipItemID = flaskItemID
        button.usableItemID = flaskItemID

        if not isFlask then
            local texture = select(5, GetItemInfoInstant(flaskItemID))

            if texture then
                button.texture:SetTexture(texture)
            end
        end

        Actions.SetItemMacro(button, flaskItemID)
    else
        Actions.Disable(button)

        if not isFlask then
            button.outOfItemsText = "No Flasks found in Bags"
        end
    end

    button.count:SetFormattedText("%s", flaskCount > 0 and flaskCount or "")

    if not isFlask and flaskCount > 0 then
        setButtonGlow(button, true)
    else
        setButtonGlow(button, false)
    end
end
