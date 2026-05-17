local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Vantus = RCC.Consumables.Vantus or {}

local Vantus = RCC.Consumables.Vantus

local Auras = RCC.ConsumableFrameAuras
local ButtonState = RCC.ConsumableFrameButtonState
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType

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

    local candidate = ItemCandidates.FindFirstAvailable(
        vantusRuneIDs,
        ItemCandidates.BAGS_ONLY
    )

    if candidate then
        return vantusRuneIDs, candidate.itemID, candidate.count, candidate.icon
    end

    local itemID = vantusRuneIDs[1]

    return vantusRuneIDs, itemID, 0, ItemCandidates.GetIcon(itemID)
end

function Vantus.Update(button, state)
    local bossName = getAuraBossName(state)
    local vantusRuneIDs, itemID, count, icon = getVantusForCurrentRaid()
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
        buttonState.detailText = bossName
        buttonState.statusTexture = ButtonState.READY_TEXTURE
        buttonState.hasConsumableBuff = true
        buttonState.desaturated = false

        if count > 0 then
            buttonState.countText = tostring(count)
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
        }

        Renderer.Apply(button, buttonState)

        return
    end

    buttonState.countText = "0"
    buttonState.tooltipItemID = itemID
    buttonState.outOfItemsText = "No Vantus Runes found in Bags"

    Renderer.Apply(button, buttonState)
end
