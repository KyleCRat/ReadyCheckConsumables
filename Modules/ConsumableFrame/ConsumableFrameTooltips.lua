local _, RCC = ...

local Glow = RCC.ConsumableFrameGlow
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
    local Buttons = RCC.ConsumableFrameButtons

    return Buttons and Buttons.GetUnavailableText(button)
end

local function setGameTooltipOwner(button)
    local Buttons = RCC.ConsumableFrameButtons
    local spacing = Buttons and Buttons.SPACING or 0

    GameTooltip:SetOwner(button, "ANCHOR_NONE")
    GameTooltip:SetPoint("BOTTOMLEFT", button, "TOPRIGHT", spacing, spacing)
end

local function addClickHint(button)
    if not button.tooltipAction then return end

    local targetText = getItemLink(button.clickHintItemID
                                   or button.usableItemID
                                   or button.tooltipItemID)
        or getSpellDisplay(button.clickHintSpellID
                           or button.tooltipSpellID)

    if not targetText then return end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ff00Click to " .. button.tooltipAction .. "|r "
                        .. targetText)
    GameTooltip:Show()
end

local function addUnavailableHint(button)
    local unavailableText = getUnavailableText(button)

    if not unavailableText then return end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffff3333" .. unavailableText .. "|r")
    GameTooltip:Show()
end

local function showButtonTooltip(button, shoppingTooltip)
    local shownTooltip

    if button.tooltipItemID then
        setGameTooltipOwner(button)
        GameTooltip:SetItemByID(button.tooltipItemID)
        GameTooltip:Show()
        shownTooltip = true
    end

    if button.tooltipSpellID then
        setGameTooltipOwner(button)
        GameTooltip:SetSpellByID(button.tooltipSpellID)
        GameTooltip:Show()
        shownTooltip = true
    end

    if button.tooltipAuraID and shoppingTooltip and shownTooltip then
        ShoppingTooltip1:SetOwner(GameTooltip, "ANCHOR_NONE")
        ShoppingTooltip1:SetPoint("BOTTOMLEFT", GameTooltip, "TOPLEFT", 0, 4)
        ShoppingTooltip1:SetUnitBuffByAuraInstanceID("player", button.tooltipAuraID)
        ShoppingTooltip1:Show()

    elseif button.tooltipAuraID then
        setGameTooltipOwner(button)
        GameTooltip:SetUnitBuffByAuraInstanceID("player", button.tooltipAuraID)
        GameTooltip:Show()
        shownTooltip = true
    end

    return shownTooltip
end

function Tooltips.ClickButtonOnEnter(self)
    local button = self:GetParent()
    Glow.SetHovered(button, true)

    if showButtonTooltip(button, true) then
        addClickHint(button)
    end
end

function Tooltips.ClickButtonOnLeave(self)
    Glow.SetHovered(self:GetParent(), false)
    ShoppingTooltip1:Hide()
    GameTooltip:Hide()
end

function Tooltips.InfoButtonOnEnter(self)
    Glow.SetHovered(self, true)

    local unavailableText = getUnavailableText(self)

    if self.unavailableOverlay and unavailableText then
        self.unavailableOverlay:Show()
    end

    if showButtonTooltip(self, true) then
        addUnavailableHint(self)

        return
    end

    if unavailableText then
        setGameTooltipOwner(self)
        GameTooltip:ClearLines()
        GameTooltip:AddLine(unavailableText)
        GameTooltip:Show()
    end
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
