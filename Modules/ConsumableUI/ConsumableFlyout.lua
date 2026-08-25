local _, RCC = ...

RCC.ConsumableFlyout = RCC.ConsumableFlyout or {}

local Flyout = RCC.ConsumableFlyout
local Binder = RCC.ConsumableActionBinder
local Catalog = RCC.ConsumableCatalog
local State = RCC.ConsumableState
local Tooltips = RCC.ConsumableTooltips
local View = RCC.ConsumableButtonView

local FLYOUT_HIDE_DELAY = 0.1
local FLYOUT_SPACING = 2

local SECURE_FLYOUT_SHOW = [[
    local manager = self:GetFrameRef("rccFlyoutManager")
    local active = manager
        and manager:GetAttribute("rcc-flyout-active")

    if self:GetAttribute("rcc-flyout-enabled") and not active then
        local flyout = self:GetFrameRef("rccFlyout")

        if flyout then
            if manager then
                manager:SetAttribute("rcc-flyout-active", true)
            end

            self:SetAttribute("rcc-flyout-open", true)
            flyout:Show()
        end
    end
]]

local SECURE_FLYOUT_HIDE = [[
    local flyout = self:GetFrameRef("rccFlyout")

    if self:GetAttribute("rcc-flyout-open") then
        local manager = self:GetFrameRef("rccFlyoutManager")

        self:SetAttribute("rcc-flyout-open", nil)

        if manager then
            manager:SetAttribute("rcc-flyout-active", nil)
        end

        if flyout then
            flyout:Hide()
        end
    end
]]

local function getOwner(button)
    return button and (button.flyoutOwner or button)
end

local function isMouseOverFrame(frame)
    return frame and frame:IsShown() and frame:IsMouseOver()
end

local function isInteractionActive(owner)
    return owner
        and (owner.primaryHovered
            or owner.flyoutHovered
            or isMouseOverFrame(owner)
            or isMouseOverFrame(owner.flyout))
end

local function isClaimedByAnother(owner)
    local manager = owner and owner.consumableFlyoutManager

    return manager
        and manager:GetAttribute("rcc-flyout-active") == true
        and owner:GetAttribute("rcc-flyout-open") ~= true
end

function Flyout.CreateManager(parent, enabled)
    if not enabled then return end

    return CreateFrame(
        "Frame",
        nil,
        parent,
        "SecureHandlerBaseTemplate"
    )
end

function Flyout.Hide(button)
    local owner = getOwner(button)

    if not owner or InCombatLockdown() or not owner.flyout then
        return false
    end

    local ownsFlyout = owner:GetAttribute("rcc-flyout-open") == true

    owner.flyoutOpen = false
    owner.flyout:Hide()

    if ownsFlyout then
        owner:SetAttribute("rcc-flyout-open", nil)

        if owner.consumableFlyoutManager then
            owner.consumableFlyoutManager:SetAttribute(
                "rcc-flyout-active",
                nil
            )
        end
    end

    return true
end

function Flyout.Show(button)
    local owner = getOwner(button)

    if not owner or InCombatLockdown() then return false end
    if not owner.flyout or (owner.flyoutChoiceCount or 0) == 0 then
        return false
    end
    if isClaimedByAnother(owner) then return false end

    owner.flyoutOpen = true
    owner.flyout:Show()

    if owner.consumableFlyoutManager then
        owner.consumableFlyoutManager:SetAttribute(
            "rcc-flyout-active",
            true
        )
        owner:SetAttribute("rcc-flyout-open", true)
    end

    return true
end

function Flyout.ScheduleHide(button)
    local owner = getOwner(button)

    if not owner then return end

    owner.flyoutHideToken = (owner.flyoutHideToken or 0) + 1

    local token = owner.flyoutHideToken

    C_Timer.After(FLYOUT_HIDE_DELAY, function()
        if owner.flyoutHideToken ~= token then return end
        if isInteractionActive(owner) then return end

        Flyout.Hide(owner)
    end)
end

function Flyout.SetPrimaryHovered(button, hovered)
    local owner = getOwner(button)

    if not owner then return false end

    local wasHovered = owner.primaryHovered == true

    if hovered and isClaimedByAnother(owner) then
        owner.primaryHovered = false
        View.SetHoverStateActive(owner, false)

        return false
    end

    owner.primaryHovered = hovered == true
    View.SetHoverStateActive(owner, hovered)

    if hovered then
        Flyout.Show(owner)
    else
        Flyout.ScheduleHide(owner)
    end

    return hovered == true or wasHovered
end

function Flyout.SetFlyoutHovered(button, hovered)
    local owner = getOwner(button)

    if not owner then return end

    owner.flyoutHovered = hovered == true

    if hovered then
        Flyout.Show(owner)
    else
        Flyout.ScheduleHide(owner)
    end
end

local function primaryFrameOnEnter(self)
    if not Flyout.SetPrimaryHovered(self, true) then return end

    Tooltips.InfoButtonOnEnter(self)
end

local function primaryFrameOnLeave(self)
    if not Flyout.SetPrimaryHovered(self, false) then return end

    Tooltips.InfoButtonOnLeave(self)
end

local function primaryClickOnEnter(self)
    if not Flyout.SetPrimaryHovered(self:GetParent(), true) then return end

    Tooltips.ClickButtonOnEnter(self)
end

local function primaryClickOnLeave(self)
    if not Flyout.SetPrimaryHovered(self:GetParent(), false) then return end

    Tooltips.ClickButtonOnLeave(self)
end

local function flyoutFrameOnEnter(self)
    Flyout.SetFlyoutHovered(self, true)
    Tooltips.InfoButtonOnEnter(self)
end

local function flyoutFrameOnLeave(self)
    Flyout.SetFlyoutHovered(self, false)
    Tooltips.InfoButtonOnLeave(self)
end

local function flyoutClickOnEnter(self)
    Flyout.SetFlyoutHovered(self:GetParent(), true)
    Tooltips.ClickButtonOnEnter(self)
end

local function flyoutClickOnLeave(self)
    Flyout.SetFlyoutHovered(self:GetParent(), false)
    Tooltips.ClickButtonOnLeave(self)
end

function Flyout.AttachPrimary(button, manager)
    if not button then return end

    button.consumableFlyoutManager = manager

    if manager then
        button:SetFrameRef("rccFlyoutManager", manager)
        button:HookScript("OnEnter", primaryFrameOnEnter)
        button:HookScript("OnLeave", primaryFrameOnLeave)
    else
        button:SetScript("OnEnter", primaryFrameOnEnter)
        button:SetScript("OnLeave", primaryFrameOnLeave)
    end

    if button.click then
        button.click:SetScript("OnEnter", primaryClickOnEnter)
        button.click:SetScript("OnLeave", primaryClickOnLeave)
    end
end

local function createFlyoutButton(owner, index)
    local button = View.Create(owner.flyout, owner.definition, {
        clickable = true,
        capabilities = owner.surfaceCapabilities,
    })

    button.flyoutOwner = owner
    button.hideStatusTexture = true

    if owner.combatFlyouts then
        button:SetPropagateMouseMotion(true)
        button.click:SetPropagateMouseMotion(true)
    end

    button:SetScript("OnEnter", flyoutFrameOnEnter)
    button:SetScript("OnLeave", flyoutFrameOnLeave)
    button.click:SetScript("OnEnter", flyoutClickOnEnter)
    button.click:SetScript("OnLeave", flyoutClickOnLeave)
    button:Show()

    owner.flyout.buttons[index] = button

    return button
end

local function ensureFlyout(owner)
    if owner.flyout then return owner.flyout end

    local flyout = CreateFrame(
        "Frame",
        nil,
        owner,
        "SecureHandlerEnterLeaveTemplate"
    )

    flyout.owner = owner
    flyout.buttons = {}
    flyout:SetPoint("BOTTOM", owner, "TOP", 0, 0)
    flyout:SetSize(View.SIZE, View.SIZE + FLYOUT_SPACING)
    flyout:SetFrameLevel(owner:GetFrameLevel() + 20)
    flyout:EnableMouse(true)
    flyout:HookScript("OnEnter", function(self)
        Flyout.SetFlyoutHovered(self.owner, true)
    end)
    flyout:HookScript("OnLeave", function(self)
        Flyout.SetFlyoutHovered(self.owner, false)
    end)
    flyout:Hide()

    if owner.combatFlyouts then
        flyout:SetPropagateMouseMotion(true)
    end

    owner.flyout = flyout

    if owner.combatFlyouts then
        owner:SetFrameRef("rccFlyout", flyout)
        owner:SetAttribute("_onenter", SECURE_FLYOUT_SHOW)
        owner:SetAttribute("_onleave", SECURE_FLYOUT_HIDE)
        owner:SetAttribute(
            "rcc-flyout-enabled",
            (owner.flyoutChoiceCount or 0) > 0
        )
    end

    return flyout
end

function Flyout.ApplyGeometry(owner, geometry)
    if not owner or InCombatLockdown() or not owner.flyout then
        return false
    end

    local flyout = owner.flyout
    local width = math.max(1, tonumber(geometry.buttonWidth) or View.SIZE)
    local height = math.max(1, tonumber(geometry.buttonHeight) or View.SIZE)
    local direction = geometry.flyoutDirection or "UP"
    local count = math.max(owner.flyoutChoiceCount or 0, 1)
    local stackLength

    if direction == "LEFT" or direction == "RIGHT" then
        stackLength = View.GetWidth(count, width, FLYOUT_SPACING)
    else
        stackLength = View.GetStackHeight(count, height, FLYOUT_SPACING)
    end

    stackLength = stackLength + FLYOUT_SPACING
    flyout:ClearAllPoints()

    if direction == "DOWN" then
        flyout:SetPoint("TOP", owner, "BOTTOM", 0, 0)
        flyout:SetSize(width, stackLength)
    elseif direction == "LEFT" then
        flyout:SetPoint("RIGHT", owner, "LEFT", 0, 0)
        flyout:SetSize(stackLength, height)
    elseif direction == "RIGHT" then
        flyout:SetPoint("LEFT", owner, "RIGHT", 0, 0)
        flyout:SetSize(stackLength, height)
    else
        flyout:SetPoint("BOTTOM", owner, "TOP", 0, 0)
        flyout:SetSize(width, stackLength)
    end

    for i = 1, #flyout.buttons do
        local button = flyout.buttons[i]
        local previous = flyout.buttons[i - 1]

        button:ClearAllPoints()

        if direction == "DOWN" then
            button:SetPoint(
                "TOP",
                previous or flyout,
                previous and "BOTTOM" or "TOP",
                0,
                -FLYOUT_SPACING
            )
        elseif direction == "LEFT" then
            button:SetPoint(
                "RIGHT",
                previous or flyout,
                previous and "LEFT" or "RIGHT",
                -FLYOUT_SPACING,
                0
            )
        elseif direction == "RIGHT" then
            button:SetPoint(
                "LEFT",
                previous or flyout,
                previous and "RIGHT" or "LEFT",
                FLYOUT_SPACING,
                0
            )
        else
            button:SetPoint(
                "BOTTOM",
                previous or flyout,
                previous and "TOP" or "BOTTOM",
                0,
                FLYOUT_SPACING
            )
        end

        View.ApplyGeometry(button, geometry)
    end

    return true
end

function Flyout.ApplyVisualOptions(owner, options)
    local buttons = owner and owner.flyout and owner.flyout.buttons

    if not buttons then return end

    for i = 1, #buttons do
        View.ApplyVisualOptions(buttons[i], options, true)
    end
end

function Flyout.SetChoices(owner, choices, geometry, visualOptions)
    if not owner or owner.flyoutOwner or InCombatLockdown() then
        return false
    end

    local count = choices and #choices or 0

    owner.flyoutChoiceCount = count

    if owner.combatFlyouts then
        owner:SetAttribute("rcc-flyout-enabled", count > 0)
    end

    if count == 0 then
        Flyout.Hide(owner)

        return true
    end

    local flyout = ensureFlyout(owner)

    for i = 1, count do
        local button = flyout.buttons[i] or createFlyoutButton(owner, i)
        local choice = State.Normalize(choices[i])

        View.ApplyVisualOptions(button, visualOptions, true)
        View.ApplyVisual(button, choice)
        Binder.Bind(button, choice.action, owner.surfaceCapabilities)
        button:Show()
    end

    for i = count + 1, #flyout.buttons do
        Binder.Disable(flyout.buttons[i])
        flyout.buttons[i]:Hide()
    end

    Flyout.ApplyGeometry(owner, geometry or {})

    if isInteractionActive(owner) then
        Flyout.Show(owner)
    else
        Flyout.Hide(owner)
    end

    return true
end

function Flyout.HideAll(buttons)
    if not buttons or InCombatLockdown() then return false end

    local definitions = Catalog.GetDefinitions()

    for i = 1, #definitions do
        Flyout.Hide(buttons[definitions[i].key])
    end

    return true
end

