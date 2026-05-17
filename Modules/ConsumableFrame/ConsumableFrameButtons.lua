local _, RCC = ...

local UI = RCC.UI
local Glow = RCC.ConsumableFrameGlow
local Tooltips = RCC.ConsumableFrameTooltips

RCC.ConsumableFrameButtons = RCC.ConsumableFrameButtons or {}

local Buttons = RCC.ConsumableFrameButtons

local SIZE = 48
local SPACING = 2
local FONT = UI.FONT
local TIME_TEXT_NORMAL_COLOR = { r = 1, g = 1, b = 1 }
local TIME_TEXT_BAD_COLOR = { r = 1, g = 0.2, b = 0.2 }
local MAIN_HAND_INVENTORY_SLOT = 16
local OFF_HAND_INVENTORY_SLOT = 17
local FLYOUT_HIDE_DELAY = 0.05

Buttons.SIZE = SIZE
Buttons.SPACING = SPACING

local BUTTON_DEFS = {
    {
        key = "food",
        settingKey = "icon_food",
        defaultIcon = RCC.db.food_icon_id,
        clickable = true,
        tooltipAction = "eat",
        hasCooldown = true,
        expireWarnSeconds = 60 * 10,
        layoutOrder = 1,
    },
    {
        key = "flask",
        settingKey = "icon_flask",
        defaultIcon = RCC.db.flask_icon_id,
        clickable = true,
        tooltipAction = "use",
        expireWarnSeconds = 60 * 10,
        layoutOrder = 2,
    },
    {
        key = "mainHandTempWeaponEnchant",
        weaponSlot = MAIN_HAND_INVENTORY_SLOT,
        settingKey = "icon_mhOil",
        defaultIcon = RCC.db.weapon_enchant_icon_id,
        clickable = true,
        tooltipAction = "apply to main hand",
        expireWarnSeconds = 60 * 10,
        layoutOrder = 3,
    },
    {
        key = "augment",
        settingKey = "icon_augment",
        defaultIcon = RCC.db.augment_icon_id,
        clickable = true,
        tooltipAction = "use",
        expireWarnSeconds = 60 * 10,
        layoutOrder = 5,
    },
    {
        key = "hs",
        settingKey = "icon_healthstone",
        defaultIcon = RCC.db.healthstone_icon_id,
        layoutOrder = 6,
    },
    {
        key = "offHandTempWeaponEnchant",
        weaponSlot = OFF_HAND_INVENTORY_SLOT,
        settingKey = "icon_ohOil",
        defaultIcon = RCC.db.weapon_enchant_icon_id,
        clickable = true,
        tooltipAction = "apply to off hand",
        expireWarnSeconds = 60 * 10,
        hiddenByDefault = true,
        layoutOrder = 4,
    },
    {
        key = "dmgpot",
        settingKey = "icon_dmgPotion",
        defaultIcon = RCC.db.potion_icon_id,
        layoutOrder = 7,
    },
    {
        key = "healpot",
        settingKey = "icon_healPotion",
        defaultIcon = RCC.db.healing_potion_icon_id,
        layoutOrder = 8,
    },
    {
        key = "vantus",
        settingKey = "icon_vantus",
        defaultIcon = RCC.db.vantus_icon_id,
        clickable = true,
        tooltipAction = "use",
        hiddenByDefault = true,
        layoutOrder = 9,
    },
}

local BUTTON_LAYOUT_ORDER = {}

for i = 1, #BUTTON_DEFS do
    local def = BUTTON_DEFS[i]
    def.index = i
    BUTTON_LAYOUT_ORDER[#BUTTON_LAYOUT_ORDER + 1] = def
end

table.sort(BUTTON_LAYOUT_ORDER, function(a, b)
    return a.layoutOrder < b.layoutOrder
end)

function Buttons.GetWidth(buttonCount)
    return SIZE * buttonCount
           + SPACING * math.max(buttonCount - 1, 0)
end

function Buttons.GetStackHeight(buttonCount)
    return Buttons.GetWidth(buttonCount)
end

function Buttons.SetShownInLayout(button, shown)
    button.showInLayout = shown == true
end

function Buttons.SetDetailTextBad(button, bad)
    local color = bad and TIME_TEXT_BAD_COLOR or TIME_TEXT_NORMAL_COLOR

    button.detailText:SetTextColor(color.r, color.g, color.b)
end

function Buttons.ResetState(button, notReadyTexture)
    button.consumableState = nil
    button.statustexture:SetTexture(notReadyTexture)
    button.statustexture:SetShown(not button.hideStatusTexture)
    button.hasConsumableBuff = false
    button.detailText:SetText("")
    Buttons.SetDetailTextBad(button, false)
    button.count:SetText("")
    button.texture:SetTexture(button.defaultIcon)
    button.texture:SetDesaturated(true)
    if button.cooldown then
        button.cooldown:Clear()
        button.cooldown:Hide()
    end
    Glow.Stop(button)
    button.tooltipAuraID = nil
    button.tooltipItemID = nil
    button.tooltipSpellID = nil
    button.usableItemID = nil
    button.clickHintItemID = nil
    button.clickHintSpellID = nil
    button.outOfItemsText = nil
    button.clickEnabled = false
    Buttons.SetShownInLayout(button, true)
end

local function primaryFrameOnEnter(self)
    Buttons.SetPrimaryHovered(self, true)
    Tooltips.InfoButtonOnEnter(self)
end

local function primaryFrameOnLeave(self)
    Buttons.SetPrimaryHovered(self, false)
    Tooltips.InfoButtonOnLeave(self)
end

local function primaryClickOnEnter(self)
    Buttons.SetPrimaryHovered(self:GetParent(), true)
    Tooltips.ClickButtonOnEnter(self)
end

local function primaryClickOnLeave(self)
    Buttons.SetPrimaryHovered(self:GetParent(), false)
    Tooltips.ClickButtonOnLeave(self)
end

local function flyoutFrameOnEnter(self)
    Buttons.SetFlyoutHovered(self, true)
    Tooltips.InfoButtonOnEnter(self)
end

local function flyoutFrameOnLeave(self)
    Buttons.SetFlyoutHovered(self, false)
    Tooltips.InfoButtonOnLeave(self)
end

local function flyoutClickOnEnter(self)
    Buttons.SetFlyoutHovered(self:GetParent(), true)
    Tooltips.ClickButtonOnEnter(self)
end

local function flyoutClickOnLeave(self)
    Buttons.SetFlyoutHovered(self:GetParent(), false)
    Tooltips.ClickButtonOnLeave(self)
end

local function getFlyoutOwner(button)
    return button and (button.flyoutOwner or button)
end

local function getFlyoutButton(owner, index)
    local flyout = owner.flyout
    local button = flyout.buttons[index]

    if button then return button end

    button = CreateFrame("Frame", nil, flyout)
    button:SetSize(SIZE, SIZE)
    button.flyoutOwner = owner
    button.defaultIcon = owner.defaultIcon
    button.tooltipAction = owner.tooltipAction
    button.hideStatusTexture = true

    if index == 1 then
        button:SetPoint("BOTTOM", flyout, "BOTTOM", 0, 0)
    else
        button:SetPoint("BOTTOM", flyout.buttons[index - 1], "TOP",
                        0, SPACING)
    end

    button.texture = button:CreateTexture()
    button.texture:SetAllPoints()

    button.statustexture = button:CreateTexture(nil, "OVERLAY")
    button.statustexture:SetPoint("CENTER")
    button.statustexture:SetSize(SIZE / 2, SIZE / 2)
    button.statustexture:Hide()

    button.detailText = button:CreateFontString(nil, "ARTWORK",
                                                "GameFontWhite")
    button.detailText:SetPoint("BOTTOM", button, "TOP", 0, 1)
    button.detailText:SetFont(FONT, 12, "OUTLINE")

    button.count = button:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.count:SetFont(FONT, 14, "OUTLINE")

    button.click = CreateFrame("Button", nil, button,
                               "SecureActionButtonTemplate")
    button.click:SetAllPoints()
    button.click:Hide()
    button.click:RegisterForClicks("AnyUp", "AnyDown")
    button.click:SetAttribute("type", "macro")
    button.click:SetScript("OnEnter", flyoutClickOnEnter)
    button.click:SetScript("OnLeave", flyoutClickOnLeave)

    local highlight = button.click:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.15)
    highlight:SetBlendMode("ADD")

    button:EnableMouse(true)
    button:SetScript("OnEnter", flyoutFrameOnEnter)
    button:SetScript("OnLeave", flyoutFrameOnLeave)
    button:Hide()

    flyout.buttons[index] = button

    return button
end

local function ensureFlyout(owner)
    if owner.flyout then return owner.flyout end

    local flyout = CreateFrame("Frame", nil, owner)
    flyout.owner = owner
    flyout.buttons = {}
    flyout:SetPoint("BOTTOM", owner, "TOP", 0, SPACING)
    flyout:SetSize(SIZE, SIZE)
    flyout:SetFrameLevel(owner:GetFrameLevel() + 20)
    flyout:EnableMouse(true)
    flyout:SetScript("OnEnter", function(self)
        Buttons.SetFlyoutHovered(self.owner, true)
    end)
    flyout:SetScript("OnLeave", function(self)
        Buttons.SetFlyoutHovered(self.owner, false)
    end)
    flyout:Hide()

    owner.flyout = flyout

    return flyout
end

function Buttons.HideFlyout(button)
    local owner = getFlyoutOwner(button)

    if not owner or InCombatLockdown() then return end
    if not owner.flyout then return end

    owner.flyoutOpen = false
    owner.flyout:Hide()

    for i = 1, #(owner.flyout.buttons) do
        owner.flyout.buttons[i]:Hide()
    end
end

function Buttons.ShowFlyout(button)
    local owner = getFlyoutOwner(button)

    if not owner or InCombatLockdown() then return end
    if not owner.flyout or not owner.flyoutChoiceCount
        or owner.flyoutChoiceCount == 0
    then
        return
    end

    owner.flyoutOpen = true
    owner.flyout:Show()

    for i = 1, owner.flyoutChoiceCount do
        owner.flyout.buttons[i]:Show()
    end
end

function Buttons.ScheduleFlyoutHide(button)
    local owner = getFlyoutOwner(button)

    if not owner then return end

    owner.flyoutHideToken = (owner.flyoutHideToken or 0) + 1

    local token = owner.flyoutHideToken

    C_Timer.After(FLYOUT_HIDE_DELAY, function()
        if owner.flyoutHideToken ~= token then return end
        if owner.primaryHovered or owner.flyoutHovered then return end

        Buttons.HideFlyout(owner)
    end)
end

function Buttons.SetPrimaryHovered(button, hovered)
    local owner = getFlyoutOwner(button)

    if not owner then return end

    owner.primaryHovered = hovered == true

    if hovered then
        Buttons.ShowFlyout(owner)
    else
        Buttons.ScheduleFlyoutHide(owner)
    end
end

function Buttons.SetFlyoutHovered(button, hovered)
    local owner = getFlyoutOwner(button)

    if not owner then return end

    owner.flyoutHovered = hovered == true

    if hovered then
        Buttons.ShowFlyout(owner)
    else
        Buttons.ScheduleFlyoutHide(owner)
    end
end

function Buttons.SetFlyoutChoices(button, choices)
    if not button or button.flyoutOwner then return end
    if InCombatLockdown() then return end

    local count = choices and #choices or 0

    button.flyoutChoiceCount = count

    if count == 0 then
        Buttons.HideFlyout(button)

        return
    end

    local flyout = ensureFlyout(button)
    local Renderer = RCC.ConsumableFrameRenderer

    flyout:SetHeight(Buttons.GetStackHeight(count))

    for i = 1, count do
        local flyoutButton = getFlyoutButton(button, i)

        Renderer.Apply(flyoutButton, choices[i])
        flyoutButton:Hide()
    end

    for i = count + 1, #flyout.buttons do
        flyout.buttons[i]:Hide()
    end

    if button.primaryHovered or button.flyoutHovered then
        Buttons.ShowFlyout(button)
    else
        Buttons.HideFlyout(button)
    end
end

function Buttons.CreateAll(parent)
    parent.buttons = parent.buttons or {}

    local buttons = parent.buttons

    for i = 1, #BUTTON_DEFS do
        local def = BUTTON_DEFS[i]
        local button = CreateFrame("Frame", nil, parent)
        buttons[i] = button
        button.defaultIcon = def.defaultIcon
        button.expireWarnSeconds = def.expireWarnSeconds
        button.weaponSlot = def.weaponSlot
        button:SetSize(SIZE, SIZE)

        if i == 1 then
            button:SetPoint("LEFT", 0, 0)
        else
            button:SetPoint("LEFT", buttons[i - 1], "RIGHT", SPACING, 0)
        end

        button.texture = button:CreateTexture()
        button.texture:SetAllPoints()

        button.statustexture = button:CreateTexture(nil, "OVERLAY")
        button.statustexture:SetPoint("CENTER")
        button.statustexture:SetSize(SIZE / 2, SIZE / 2)

        button.detailText = button:CreateFontString(nil, "ARTWORK",
                                                    "GameFontWhite")
        button.detailText:SetPoint("BOTTOM", button, "TOP", 0, 1)
        button.detailText:SetFont(FONT, 12, "OUTLINE")

        button.count = button:CreateFontString(nil, "ARTWORK", "GameFontWhite")
        button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        button.count:SetFont(FONT, 14, "OUTLINE")

        if def.clickable then
            button.click = CreateFrame("Button", nil, button,
                                       "SecureActionButtonTemplate")
            button.click:SetAllPoints()
            button.click:Hide()
            button.click:RegisterForClicks("AnyUp", "AnyDown")
            button.click:SetAttribute("type", "macro")

            button.click:SetScript("OnEnter", primaryClickOnEnter)
            button.click:SetScript("OnLeave", primaryClickOnLeave)

            local highlight = button.click:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(1, 1, 1, 0.15)
            highlight:SetBlendMode("ADD")

            button.outOverlay = button:CreateTexture(nil, "ARTWORK", nil, 1)
            button.outOverlay:SetAllPoints()
            button.outOverlay:SetColorTexture(0.6, 0, 0, 0.4)
            button.outOverlay:Hide()

            button.tooltipAction = def.tooltipAction
        end

        button:EnableMouse(true)
        button:SetScript("OnEnter", primaryFrameOnEnter)
        button:SetScript("OnLeave", primaryFrameOnLeave)

        if def.defaultIcon then
            button.texture:SetTexture(def.defaultIcon)
        end

        if def.hasCooldown then
            button.cooldown = CreateFrame("Cooldown", nil, button,
                                          "CooldownFrameTemplate")
            button.cooldown:SetAllPoints()
            button.cooldown:SetDrawEdge(true)
            button.cooldown:SetDrawSwipe(true)
        end

        buttons[def.key] = button

        if def.hiddenByDefault then
            button:Hide()
        end
    end

    return buttons
end

function Buttons.ApplyLayout(parent, buttons)
    local previous
    local visibleCount = 0

    for _, def in ipairs(BUTTON_LAYOUT_ORDER) do
        local button = buttons[def.index]
        local shouldShow = button.showInLayout
            and RCC.GetSetting(def.settingKey)

        button:ClearAllPoints()

        if shouldShow then
            if previous then
                button:SetPoint("LEFT", previous, "RIGHT", SPACING, 0)
            else
                button:SetPoint("LEFT", 0, 0)
            end

            button:Show()
            previous = button
            visibleCount = visibleCount + 1
        else
            Buttons.HideFlyout(button)
            button:Hide()
        end
    end

    parent:SetWidth(Buttons.GetWidth(visibleCount))
end

function Buttons.UpdateOutOverlays(buttons)
    for i = 1, #buttons do
        Tooltips.UpdateOutOverlay(buttons[i])
    end
end
