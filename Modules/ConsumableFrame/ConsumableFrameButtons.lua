local _, RCC = ...

local UI = RCC.UI
local Tooltips = RCC.ConsumableFrameTooltips
local State = RCC.ConsumableFrameButtonState

RCC.ConsumableFrameButtons = RCC.ConsumableFrameButtons or {}

local Buttons = RCC.ConsumableFrameButtons

local SIZE = 48
local SPACING = 2
local FONT = UI.FONT
local DETAIL_TEXT_FONT_SIZE = 16
local DETAIL_TEXT_MAX_WIDTH = (SIZE * 5) + (SPACING * 2)
local QUALITY_ICON_SIZE = 28
local TIME_TEXT_NORMAL_COLOR = { r = 1, g = 1, b = 1 }
local TIME_TEXT_BAD_COLOR = { r = 1, g = 0.2, b = 0.2 }
local MAIN_HAND_INVENTORY_SLOT = 16
local OFF_HAND_INVENTORY_SLOT = 17
local FLYOUT_HIDE_DELAY = 0.1

local GetItemReagentQualityInfo = C_TradeSkillUI.GetItemReagentQualityInfo

Buttons.SIZE = SIZE
Buttons.SPACING = SPACING

-- Array order defines layout order (left to right).
local BUTTON_DEFS = {
    {
        key           = "food",
        settingKey    = "icon_food",
        defaultIcon   = RCC.db.foodIconID,
        clickable     = true,
        tooltipAction = "eat",
        hasCooldown   = true,
    },
    {
        key           = "flask",
        settingKey    = "icon_flask",
        defaultIcon   = RCC.db.flaskIconID,
        clickable     = true,
        tooltipAction = "use",
    },
    {
        key           = "mainHandTempWeaponEnchant",
        weaponSlot    = MAIN_HAND_INVENTORY_SLOT,
        settingKey    = "icon_mhTempWeaponEnchant",
        defaultIcon   = RCC.db.weaponEnchantIconID,
        clickable     = true,
        tooltipAction = "apply to main hand",
    },
    {
        key             = "offHandTempWeaponEnchant",
        weaponSlot      = OFF_HAND_INVENTORY_SLOT,
        settingKey      = "icon_ohTempWeaponEnchant",
        defaultIcon     = RCC.db.weaponEnchantIconID,
        clickable       = true,
        tooltipAction   = "apply to off hand",
        hiddenByDefault = true,
    },
    {
        key           = "augment",
        settingKey    = "icon_augment",
        defaultIcon   = RCC.db.augmentIconID,
        clickable     = true,
        tooltipAction = "use",
    },
    {
        key           = "raidBuff",
        settingKey    = "icon_raidBuff",
        defaultIcon   = RCC.db.raidBuffIconID,
        clickable     = true,
        tooltipAction = "cast",
    },
    {
        key         = "hs",
        settingKey  = "icon_healthstone",
        defaultIcon = RCC.db.healthstoneIconID,
    },
    {
        key           = "dmgpot",
        settingKey    = "icon_dmgPotion",
        defaultIcon   = RCC.db.potionIconID,
        clickable     = true,
        tooltipAction = "select the preferred item for macro use",
    },
    {
        key           = "healpot",
        settingKey    = "icon_healPotion",
        defaultIcon   = RCC.db.healingPotionIconID,
        clickable     = true,
        tooltipAction = "select the preferred item for macro use",
    },
    {
        key             = "vantus",
        settingKey      = "icon_vantus",
        defaultIcon     = RCC.db.vantusIconID,
        clickable       = true,
        tooltipAction   = "use",
        hiddenByDefault = true,
    },
}

function Buttons.GetButtonCount()
    return #BUTTON_DEFS
end

function Buttons.GetWidth(buttonCount)
    return SIZE * buttonCount
           + SPACING * math.max(buttonCount - 1, 0)
end

function Buttons.GetStackHeight(buttonCount)
    return Buttons.GetWidth(buttonCount)
end

local function getRenderCache(button)
    button.consumableFrameRenderCache =
        button.consumableFrameRenderCache or {}

    return button.consumableFrameRenderCache
end

function Buttons.SetDetailTextBad(button, bad)
    local color = bad and TIME_TEXT_BAD_COLOR or TIME_TEXT_NORMAL_COLOR

    button.detailText:SetTextColor(color.r, color.g, color.b)
end

function Buttons.SetCountTextBad(button, bad)
    local color = bad and TIME_TEXT_BAD_COLOR or TIME_TEXT_NORMAL_COLOR

    button.count:SetTextColor(color.r, color.g, color.b)
end

function Buttons.SetQualityOverlay(button, itemID)
    if not button.qualityIcon then return end

    local cache = getRenderCache(button)

    if not itemID then
        if not cache.qualityItemID and not button.qualityIcon:IsShown() then
            return
        end

        cache.qualityItemID = nil
        button.qualityIcon:Hide()

        return
    end

    if cache.qualityItemID == itemID then return end

    local info = GetItemReagentQualityInfo(itemID)

    if not info or not info.iconSmall then
        cache.qualityItemID = nil
        button.qualityIcon:Hide()

        return
    end

    cache.qualityItemID = itemID
    button.qualityIcon:SetAtlas(info.iconSmall, false)
    button.qualityIcon:Show()
end

local function applyButtonIcon(button)
    local icon = State.GetIcon(
        button.consumableState,
        button.defaultIcon,
        button.hoverStateActive
    )

    if icon then
        button.texture:SetTexture(icon)
    end
end

function Buttons.SetHoverStateActive(button, active)
    button.hoverStateActive = active == true
    applyButtonIcon(button)
end

function Buttons.GetUnavailableText(button)
    if not button then return end

    return State.GetUnavailableText(
        button.consumableState,
        button.hoverStateActive
    )
end

local function applyCooldown(button, cooldown)
    if not button.cooldown then return end

    local cache = getRenderCache(button)

    if cooldown and cooldown.start and cooldown.duration then
        if cache.cooldownStart == cooldown.start
            and cache.cooldownDuration == cooldown.duration
            and cache.cooldownShown
        then
            return
        end

        cache.cooldownStart = cooldown.start
        cache.cooldownDuration = cooldown.duration
        cache.cooldownShown = true
        button.cooldown:SetCooldown(cooldown.start, cooldown.duration)
        button.cooldown:Show()

        return
    end

    if not cache.cooldownShown and not button.cooldown:IsShown() then
        return
    end

    cache.cooldownStart = nil
    cache.cooldownDuration = nil
    cache.cooldownShown = false
    button.cooldown:Clear()
    button.cooldown:Hide()
end

function Buttons.ApplyState(button, state)
    if not button or not state then return end

    button.statustexture:SetTexture(state.statusTexture)
    button.statustexture:SetShown(
        state.showStatusTexture == true and not button.hideStatusTexture
    )
    applyButtonIcon(button)
    button.texture:SetDesaturated(state.desaturated == true)
    button.count:SetText(state.countText or "")
    Buttons.SetCountTextBad(button, state.countTextIsBad == true)
    button.detailText:SetText(state.detailText or "")
    Buttons.SetDetailTextBad(button, state.detailTextIsBad == true)
    Buttons.SetQualityOverlay(button, state.qualityItemID)
    applyCooldown(button, state.cooldown)
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

local function isMouseOverFrame(frame)
    return frame and frame:IsShown() and frame:IsMouseOver()
end

local function isFlyoutInteractionActive(owner)
    return owner
           and (owner.primaryHovered
                or owner.flyoutHovered
                or isMouseOverFrame(owner)
                or isMouseOverFrame(owner.flyout))
end

local function getOrCreateFlyoutButton(owner, index)
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

    button.statustexture = button:CreateTexture(nil, "OVERLAY", nil, 1)
    button.statustexture:SetPoint("CENTER")
    button.statustexture:SetSize(SIZE / 2, SIZE / 2)
    button.statustexture:Hide()

    button.detailText = button:CreateFontString(nil, "ARTWORK",
                                                "GameFontWhite")
    button.detailText:SetPoint("BOTTOM", button, "TOP", 0, 1)
    button.detailText:SetFont(FONT, DETAIL_TEXT_FONT_SIZE, "OUTLINE")
    button.detailText:SetMaxLines(1)
    button.detailText:SetWordWrap(false)
    button.detailText:SetWidth(DETAIL_TEXT_MAX_WIDTH)

    button.count = button:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.count:SetFont(FONT, 14, "OUTLINE")

    button.qualityIcon = button:CreateTexture(nil, "OVERLAY")
    button.qualityIcon:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4)
    button.qualityIcon:SetSize(QUALITY_ICON_SIZE, QUALITY_ICON_SIZE)
    button.qualityIcon:Hide()

    button.click = CreateFrame("Button", nil, button,
                               "SecureActionButtonTemplate")
    button.click:SetAllPoints()
    button.click:Hide()
    button.click:RegisterForClicks("AnyDown")
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
        if isFlyoutInteractionActive(owner) then return end

        Buttons.HideFlyout(owner)
    end)
end

function Buttons.SetPrimaryHovered(button, hovered)
    local owner = getFlyoutOwner(button)

    if not owner then return end

    owner.primaryHovered = hovered == true
    Buttons.SetHoverStateActive(owner, hovered)

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
    local keepOpen = isFlyoutInteractionActive(button)

    flyout:SetHeight(Buttons.GetStackHeight(count))

    for i = 1, count do
        local flyoutButton = getOrCreateFlyoutButton(button, i)

        -- Deferred lookup: breaks circular dependency with ConsumableFrameRenderer.
        Renderer.Apply(flyoutButton, choices[i])

        if keepOpen then
            flyoutButton:Show()
        else
            flyoutButton:Hide()
        end
    end

    for i = count + 1, #flyout.buttons do
        flyout.buttons[i]:Hide()
    end

    if keepOpen or isFlyoutInteractionActive(button) then
        Buttons.ShowFlyout(button)
    else
        Buttons.HideFlyout(button)
    end
end

function Buttons.CreateAll(parent)
    parent.buttons = {}

    local buttons = parent.buttons
    local previous

    for i = 1, #BUTTON_DEFS do
        local def = BUTTON_DEFS[i]
        local button = CreateFrame("Frame", nil, parent)
        button.defaultIcon = def.defaultIcon
        button.weaponSlot = def.weaponSlot
        button:SetSize(SIZE, SIZE)

        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", SPACING, 0)
        else
            button:SetPoint("LEFT", 0, 0)
        end

        button.texture = button:CreateTexture()
        button.texture:SetAllPoints()

        button.statustexture = button:CreateTexture(nil, "OVERLAY", nil, 1)
        button.statustexture:SetPoint("CENTER")
        button.statustexture:SetSize(SIZE / 2, SIZE / 2)

        button.detailText = button:CreateFontString(nil, "ARTWORK",
                                                    "GameFontWhite")
        button.detailText:SetPoint("BOTTOM", button, "TOP", 0, 1)
        button.detailText:SetFont(FONT, DETAIL_TEXT_FONT_SIZE, "OUTLINE")

        button.count = button:CreateFontString(nil, "ARTWORK", "GameFontWhite")
        button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        button.count:SetFont(FONT, 14, "OUTLINE")

        button.qualityIcon = button:CreateTexture(nil, "OVERLAY")
        button.qualityIcon:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4)
        button.qualityIcon:SetSize(QUALITY_ICON_SIZE, QUALITY_ICON_SIZE)
        button.qualityIcon:Hide()

        if def.clickable then
            button.click = CreateFrame("Button", nil, button,
                                       "SecureActionButtonTemplate")
            button.click:SetAllPoints()
            button.click:Hide()
            button.click:RegisterForClicks("AnyDown")
            button.click:SetAttribute("type", "macro")

            button.click:SetScript("OnEnter", primaryClickOnEnter)
            button.click:SetScript("OnLeave", primaryClickOnLeave)

            local highlight = button.click:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(1, 1, 1, 0.15)
            highlight:SetBlendMode("ADD")

            button.unavailableOverlay =
                button:CreateTexture(nil, "ARTWORK", nil, 1)
            button.unavailableOverlay:SetAllPoints()
            button.unavailableOverlay:SetColorTexture(0.6, 0, 0, 0.4)
            button.unavailableOverlay:Hide()

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
        previous = button

        if def.hiddenByDefault then
            button:Hide()
        end
    end

    return buttons
end

function Buttons.ApplyLayout(parent, buttons)
    local previous
    local visibleCount = 0

    for _, def in ipairs(BUTTON_DEFS) do
        local button = buttons[def.key]
        local shouldShow = State.IsShownInLayout(button.consumableState)
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

function Buttons.UpdateUnavailableOverlays(buttons)
    for i = 1, #BUTTON_DEFS do
        local button = buttons[BUTTON_DEFS[i].key]

        Tooltips.UpdateUnavailableOverlay(button)
    end
end
