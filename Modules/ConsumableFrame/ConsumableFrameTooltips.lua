local _, RCC = ...

local Glow = RCC.ConsumableFrameGlow
local GetItemInfo = C_Item.GetItemInfo

RCC.ConsumableFrameTooltips = RCC.ConsumableFrameTooltips or {}

local Tooltips = RCC.ConsumableFrameTooltips

local function getItemLink(itemID)
    if not itemID then return end

    return select(2, GetItemInfo(itemID))
end

local function addClickHint(button)
    if not button.tooltipAction then return end

    local itemLink = getItemLink(button.clickHintItemID
                                 or button.usableItemID
                                 or button.tooltipItemID)

    if not itemLink then return end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ff00Click to " .. button.tooltipAction .. "|r "
                        .. itemLink)
    GameTooltip:Show()
end

local function addOutOfHint(button)
    if not button.outOfItemsText then return end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffff3333" .. button.outOfItemsText .. "|r")
    GameTooltip:Show()
end

local function showButtonTooltip(button, shoppingTooltip)
    local shownTooltip

    if button.tooltipItemID then
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(button.tooltipItemID)
        GameTooltip:Show()
        shownTooltip = true
    end

    if button.tooltipAuraID and shoppingTooltip and shownTooltip then
        ShoppingTooltip1:SetOwner(GameTooltip, "ANCHOR_NONE")
        ShoppingTooltip1:SetPoint("BOTTOMLEFT", GameTooltip, "TOPLEFT", 0, 4)
        ShoppingTooltip1:SetUnitBuffByAuraInstanceID("player", button.tooltipAuraID)
        ShoppingTooltip1:Show()

    elseif button.tooltipAuraID then
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
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

    if self.outOverlay and self.outOfItemsText then
        self.outOverlay:Show()
    end

    if showButtonTooltip(self, true) then
        addOutOfHint(self)

        return
    end

    if self.outOfItemsText then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(self.outOfItemsText)
        GameTooltip:Show()
    end
end

function Tooltips.InfoButtonOnLeave(self)
    Glow.SetHovered(self, false)

    if self.outOverlay then
        self.outOverlay:Hide()
    end

    ShoppingTooltip1:Hide()
    GameTooltip:Hide()
end

function Tooltips.UpdateOutOverlay(button)
    if not button.outOverlay then return end

    if button.outOfItemsText and button:IsMouseOver() then
        button.outOverlay:Show()
    else
        button.outOverlay:Hide()
    end
end
