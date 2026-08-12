local _, RCC = ...

local Glow = RCC.ConsumableFrameGlow
local State = RCC.ConsumableFrameButtonState
local F = RCC.F
local ActionType = RCC.ConsumableActionType
local GetItemInfo = C_Item.GetItemInfo
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellLink = C_Spell.GetSpellLink

RCC.ConsumableFrameTooltips = RCC.ConsumableFrameTooltips or {}

local Tooltips = RCC.ConsumableFrameTooltips

local function getItemLink(itemID)
    if not itemID then return end

    return select(2, GetItemInfo(itemID))
end

local function getSpellDisplay(spellID)
    if not spellID then return end

    local spellLink = GetSpellLink and GetSpellLink(spellID)

    if spellLink then
        return spellLink
    end

    local spellInfo = GetSpellInfo(spellID)

    return spellInfo and spellInfo.name
end

local function getUnavailableText(button)
    -- Deferred lookup: breaks circular dependency with ConsumableFrameButtons.
    local Buttons = RCC.ConsumableFrameButtons

    return Buttons.GetUnavailableText(button)
end

local function getAuraScanUnavailableText(button)
    return State.GetAuraScanUnavailableText(
        button and button.consumableState
    )
end

local function setGameTooltipOwner(button)
    -- Deferred lookup: breaks circular dependency with ConsumableFrameButtons.
    local Buttons = RCC.ConsumableFrameButtons
    local spacing = Buttons.SPACING

    GameTooltip:SetOwner(button, "ANCHOR_NONE")
    GameTooltip:SetPoint("BOTTOMLEFT", button, "TOPRIGHT", spacing, spacing)
end

local function addClickHint(button)
    if not button.tooltipAction then return end

    local state = button.consumableState

    if not state then return end

    local action = state.action

    if not action
        or action.type == ActionType.ITEM_CACHE_SELECT
    then
        return
    end

    local targetText = getItemLink(State.GetClickHintItemID(state))
        or getSpellDisplay(State.GetClickHintSpellID(state))

    if not targetText then return end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ff00Left click to "
                        .. button.tooltipAction .. "|r " .. targetText)
    GameTooltip:Show()

    return true
end

local function addRightClickPreferenceHint(button, hasHint)
    local state = button.consumableState
    local action = state and state.action
    local itemID = State.GetClickHintItemID(state)

    if not action or not action.cacheKey or not itemID then return end

    local targetText = getItemLink(itemID)

    if not targetText then return end

    if not hasHint then
        GameTooltip:AddLine(" ")
    end

    GameTooltip:AddLine("|cff00ff00Right click to prefer|r " .. targetText)
    GameTooltip:Show()
end

local function addClickHints(button)
    local hasHint = addClickHint(button)

    addRightClickPreferenceHint(button, hasHint)
end

local function addUnavailableHint(button)
    local unavailableText = getUnavailableText(button)

    if not unavailableText then return end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffff3333" .. unavailableText .. "|r")
    GameTooltip:Show()
end

local function addAuraScanUnavailableHint(button)
    local text = getAuraScanUnavailableText(button)

    if not text then return end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(text, 0.65, 0.65, 0.65, true)
    GameTooltip:Show()
end

local function showStatusMessageTooltip(button, auraText, unavailableText)
    if not auraText and not unavailableText then return end

    setGameTooltipOwner(button)
    GameTooltip:ClearLines()

    if auraText then
        GameTooltip:AddLine("Status Unknown")
        GameTooltip:AddLine(auraText, 0.65, 0.65, 0.65, true)
    end

    if unavailableText then
        if auraText then
            GameTooltip:AddLine(" ")
        end

        GameTooltip:AddLine(unavailableText, 1, 0.2, 0.2, true)
    end

    GameTooltip:Show()
end

local function showButtonTooltip(button, shoppingTooltip)
    local state = button.consumableState
    local shownTooltip

    if not state then return end

    if state.tooltipItemID then
        setGameTooltipOwner(button)
        GameTooltip:SetItemByID(state.tooltipItemID)
        GameTooltip:Show()
        shownTooltip = true
    end

    if state.tooltipSpellID then
        setGameTooltipOwner(button)
        GameTooltip:SetSpellByID(state.tooltipSpellID)
        GameTooltip:Show()
        shownTooltip = true
    end

    if state.tooltipAuraID and shoppingTooltip and shownTooltip then
        local auraInstanceID = F.GetCurrentPublicAuraInstanceID(
            "player",
            state.tooltipAuraID
        )

        if auraInstanceID then
            ShoppingTooltip1:SetOwner(GameTooltip, "ANCHOR_NONE")
            ShoppingTooltip1:SetPoint(
                "BOTTOMLEFT",
                GameTooltip,
                "TOPLEFT",
                0,
                4
            )
            ShoppingTooltip1:SetUnitBuffByAuraInstanceID(
                "player",
                auraInstanceID
            )
            ShoppingTooltip1:Show()
        end
    elseif state.tooltipAuraID then
        local auraInstanceID = F.GetCurrentPublicAuraInstanceID(
            "player",
            state.tooltipAuraID
        )

        if auraInstanceID then
            setGameTooltipOwner(button)
            GameTooltip:SetUnitBuffByAuraInstanceID("player", auraInstanceID)
            GameTooltip:Show()
            shownTooltip = true
        end
    end

    return shownTooltip
end

function Tooltips.ClickButtonOnEnter(self)
    local button = self:GetParent()
    Glow.SetHovered(button, true)

    if showButtonTooltip(button, true) then
        addAuraScanUnavailableHint(button)
        addClickHints(button)

        return
    end

    showStatusMessageTooltip(
        button,
        getAuraScanUnavailableText(button)
    )
end

function Tooltips.ClickButtonOnLeave(self)
    Glow.SetHovered(self:GetParent(), false)
    ShoppingTooltip1:Hide()
    GameTooltip:Hide()
end

function Tooltips.InfoButtonOnEnter(self)
    Glow.SetHovered(self, true)

    local unavailableText = getUnavailableText(self)
    local auraScanUnavailableText = getAuraScanUnavailableText(self)

    if self.unavailableOverlay and unavailableText then
        self.unavailableOverlay:Show()
    end

    if showButtonTooltip(self, true) then
        if self.clickEnabled then
            addClickHints(self)
        end

        addAuraScanUnavailableHint(self)
        addUnavailableHint(self)

        return
    end

    showStatusMessageTooltip(
        self,
        auraScanUnavailableText,
        unavailableText
    )
end

function Tooltips.InfoButtonOnLeave(self)
    Glow.SetHovered(self, false)

    Tooltips.UpdateUnavailableOverlay(self)

    ShoppingTooltip1:Hide()
    GameTooltip:Hide()
end

function Tooltips.UpdateUnavailableOverlay(button)
    if not button.unavailableOverlay then return end

    if getUnavailableText(button) then
        button.unavailableOverlay:Show()
    else
        button.unavailableOverlay:Hide()
    end
end
