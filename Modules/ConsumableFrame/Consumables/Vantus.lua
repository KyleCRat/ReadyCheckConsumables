local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Vantus = RCC.Consumables.Vantus or {}

local Vantus = RCC.Consumables.Vantus

local Actions = RCC.ConsumableFrameActions
local Buttons = RCC.ConsumableFrameButtons

local GetItemCount = C_Item.GetItemCount
local GetItemIcon = C_Item.GetItemIconByID

local setButtonShownInLayout = Buttons.SetShownInLayout

local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

local function getAuraBossName(state)
    if not state or not state.auras then return end

    for i = 1, #state.auras do
        local aura = state.auras[i]

        if RCC.db.vantusBuffIDs[aura.spellID] then
            local name = aura.name or ""

            return name:gsub("^Vantus Rune: ", "")
        end
    end
end

local function getVantusForCurrentRaid()
    local instanceID = select(8, GetInstanceInfo())
    local vantusRuneIDs = RCC.db.vantusItemsByRaid[instanceID]

    if not vantusRuneIDs then
        return nil, nil, 0
    end

    for i = 1, #vantusRuneIDs do
        local count = GetItemCount(vantusRuneIDs[i], false, true)

        if count and count > 0 then
            return vantusRuneIDs, vantusRuneIDs[i], count
        end
    end

    return vantusRuneIDs, vantusRuneIDs[1], 0
end

function Vantus.Update(button, state)
    local bossName = getAuraBossName(state)
    local vantusRuneIDs, itemID, count = getVantusForCurrentRaid()

    if not vantusRuneIDs then
        setButtonShownInLayout(button, false)
        Actions.Disable(button)

        return
    end

    setButtonShownInLayout(button, true)

    if itemID then
        local iconTextureID = GetItemIcon(itemID)
        button.texture:SetTexture(iconTextureID)
    end

    if bossName then
        button.timeleft:SetText(bossName)
        button.statustexture:SetTexture(READY)
        button.hasConsumableBuff = true
        button.texture:SetDesaturated(false)

        if count > 0 then
            button.count:SetFormattedText("%d", count)
        end

        Actions.Disable(button)

        return
    end

    if itemID and count > 0 then
        button.count:SetFormattedText("%d", count)
        button.tooltipItemID = itemID
        button.usableItemID = itemID

        Actions.SetItemMacro(button, itemID)

        return
    end

    button.count:SetText("0")
    button.tooltipItemID = itemID
    button.outOfItemsText = "No Vantus Runes found in Bags"

    Actions.Disable(button)
end
