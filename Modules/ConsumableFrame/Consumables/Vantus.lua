local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Vantus = RCC.Consumables.Vantus or {}

local Vantus = RCC.Consumables.Vantus

local Auras = RCC.ConsumableFrameAuras
local Actions = RCC.ConsumableFrameActions
local ButtonState = RCC.ConsumableFrameButtonState
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local GetItemIcon = C_Item.GetItemIconByID

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
        return vantusRuneIDs, candidate.itemID, candidate.count
    end

    return vantusRuneIDs, vantusRuneIDs[1], 0
end

function Vantus.Update(button, state)
    local bossName = getAuraBossName(state)
    local vantusRuneIDs, itemID, count = getVantusForCurrentRaid()
    local buttonState = ButtonState.Create()

    if not vantusRuneIDs then
        buttonState.showInLayout = false

        Renderer.Apply(button, buttonState)

        return
    end

    buttonState.showInLayout = true

    if itemID then
        buttonState.icon = GetItemIcon(itemID)
    end

    if bossName then
        buttonState.timeText = bossName
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
        buttonState.action = Actions.CreateItemMacro(itemID)

        Renderer.Apply(button, buttonState)

        return
    end

    buttonState.countText = "0"
    buttonState.tooltipItemID = itemID
    buttonState.outOfItemsText = "No Vantus Runes found in Bags"

    Renderer.Apply(button, buttonState)
end
