local _, RCC = ...

RCC.ConsumableFlyout = RCC.ConsumableFlyout or {}

local Flyout = RCC.ConsumableFlyout
local Binder = RCC.ConsumableActionBinder
local Catalog = RCC.ConsumableCatalog
local Tooltips = RCC.ConsumableTooltips
local View = RCC.ConsumableButtonView

local FLYOUT_HIDE_DELAY = 0.1
local FLYOUT_SPACING = 2

-- Flyouts are preparation UI, never combat controls. Only this secure close
-- runs in combat; primary buttons retain their preselected secure actions.
local SECURE_FLYOUT_COMBAT = [[
    if newstate == "combat" then
        local flyout = self:GetFrameRef("rccActiveFlyout")

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
        and manager.activeOwner
        and manager.activeOwner ~= owner
end

local function releaseOwner(owner)
    owner.flyoutHovered = false

    local manager = owner.consumableFlyoutManager

    if manager and manager.activeOwner == owner then
        manager.activeOwner = nil
    end
end

-- Temporary surfaces already hide in combat. A combat-usable surface needs
-- shared hover ownership and a secure close, never a secure hover-open path.
function Flyout.CreateManager(parent, combatUsable)
    if not combatUsable then return end

    local manager = CreateFrame(
        "Frame",
        nil,
        parent,
        "SecureHandlerStateTemplate"
    )

    manager:SetAttribute("_onstate-combat", SECURE_FLYOUT_COMBAT)
    RegisterStateDriver(manager, "combat", "[combat] combat; nocombat")

    return manager
end

function Flyout.Hide(button)
    local owner = getOwner(button)

    if not owner or InCombatLockdown() or not owner.flyout then
        return false
    end

    owner.flyout:Hide()
    releaseOwner(owner)

    return true
end

function Flyout.Show(button)
    local owner = getOwner(button)

    if not owner or InCombatLockdown() then return false end
    if not owner.flyout or (owner.flyoutChoiceCount or 0) == 0 then
        return false
    end
    if isClaimedByAnother(owner) then return false end

    local manager = owner.consumableFlyoutManager

    if manager and manager.activeOwner ~= owner then
        manager:SetFrameRef("rccActiveFlyout", owner.flyout)
        manager.activeOwner = owner
    end

    owner.flyout:Show()

    return true
end

function Flyout.ScheduleHide(button)
    local owner = getOwner(button)

    if not owner or InCombatLockdown() then return end

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
        local activeOwner = owner.consumableFlyoutManager.activeOwner

        -- An open flyout consumes hover over any primary beneath it. Outside
        -- that flyout, entering another primary transfers ownership immediately:
        -- the old owner's hide delay must not discard the new OnEnter event.
        if InCombatLockdown() or isMouseOverFrame(activeOwner.flyout) then
            owner.primaryHovered = false
            View.SetHoverStateActive(owner, false)

            return false
        end

        Flyout.Hide(activeOwner)
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
    button:SetScript("OnEnter", primaryFrameOnEnter)
    button:SetScript("OnLeave", primaryFrameOnLeave)

    if button.click then
        button.click:SetScript("OnEnter", primaryClickOnEnter)
        button.click:SetScript("OnLeave", primaryClickOnLeave)
    end
end

local function createFlyoutButton(owner, index)
    local button = View.Create(owner.flyout, owner.definition, {
        clickable = true,
        isFlyout = true,
        capabilities = owner.surfaceCapabilities,
    })

    button.flyoutOwner = owner
    View.ApplyGeometry(button, owner.flyoutGeometry)
    View.ApplyVisualOptions(button, owner.flyoutVisualOptions, true)

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
        "SecureFrameTemplate"
    )

    flyout.owner = owner
    flyout.buttons = {}
    flyout:SetPoint("BOTTOM", owner, "TOP", 0, 0)
    flyout:SetSize(View.SIZE, View.SIZE + FLYOUT_SPACING)
    flyout:SetFrameLevel(owner:GetFrameLevel() + 20)
    flyout:EnableMouse(true)
    flyout:SetScript("OnEnter", function(self)
        Flyout.SetFlyoutHovered(self.owner, true)
    end)
    flyout:SetScript("OnLeave", function(self)
        Flyout.SetFlyoutHovered(self.owner, false)
    end)
    flyout:SetScript("OnHide", function(self)
        -- A secure combat close or a hidden parent also releases hover
        -- ownership, without mutating protected attributes from this hook.
        releaseOwner(self.owner)
    end)
    flyout:Hide()

    owner.flyout = flyout

    return flyout
end

local function layoutFlyout(owner)
    local flyout = owner.flyout
    local geometry = owner.flyoutGeometry
    local width = math.max(1, tonumber(geometry.buttonWidth) or View.SIZE)
    local height = math.max(1, tonumber(geometry.buttonHeight) or View.SIZE)
    local direction = geometry.flyoutDirection or "UP"
    local count = owner.flyoutChoiceCount
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

    for i = 1, count do
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
    end
end

-- The surface owns configuration changes. Keep its current configuration for
-- future pooled buttons; ordinary snapshots update choices, not configuration.
function Flyout.ApplyGeometry(owner, geometry)
    if not owner or InCombatLockdown() then return false end

    local previous = owner.flyoutGeometry
    owner.flyoutGeometry = geometry

    if not owner.flyout then return true end

    local sizeChanged = not previous
        or previous.buttonWidth ~= geometry.buttonWidth
        or previous.buttonHeight ~= geometry.buttonHeight
    local layoutChanged = sizeChanged
        or previous.flyoutDirection ~= geometry.flyoutDirection
    local buttonGeometryChanged = sizeChanged
        or previous.textSize ~= geometry.textSize
        or previous.durationTextPosition ~= geometry.durationTextPosition

    if buttonGeometryChanged then
        local buttons = owner.flyout.buttons

        for i = 1, #buttons do
            View.ApplyGeometry(buttons[i], geometry)
        end
    end

    if layoutChanged and (owner.flyoutChoiceCount or 0) > 0 then
        layoutFlyout(owner)
    end

    return true
end

function Flyout.ApplyVisualOptions(owner, options)
    if not owner then return end

    owner.flyoutVisualOptions = options
    local buttons = owner.flyout and owner.flyout.buttons

    if not buttons then return end

    for i = 1, #buttons do
        View.ApplyVisualOptions(buttons[i], options, true)
    end
end

-- Choices arrive normalized and read-only from the runtime. Update them only
-- out of combat; configuration is separate and only count changes reflow.
function Flyout.SetChoices(owner, choices)
    if not owner or owner.flyoutOwner or InCombatLockdown() then
        return false
    end

    local count = choices and #choices or 0
    local previousCount = owner.flyoutChoiceCount or 0

    owner.flyoutChoiceCount = count

    for i = count + 1, previousCount do
        local button = owner.flyout.buttons[i]

        Binder.Disable(button)
        View.Clear(button)
        button:Hide()
    end

    if count == 0 then
        Flyout.Hide(owner)

        return true
    end

    local flyout = ensureFlyout(owner)

    for i = 1, count do
        local button = flyout.buttons[i] or createFlyoutButton(owner, i)
        local choice = choices[i]

        View.ApplyVisual(button, choice)
        Binder.Bind(button, choice.action, owner.surfaceCapabilities, choice.preference)
        button:Show()
    end

    if count ~= previousCount then
        layoutFlyout(owner)
    end

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

-- Existing choices only: no creation, secure binding, layout, show/hide, or
-- hover transitions when a checkmark or duration changes.
function Flyout.ApplyChoiceVisuals(owner, choices)
    if InCombatLockdown() or not owner.flyout then return end

    for index, choice in ipairs(choices or {}) do
        local button = owner.flyout.buttons[index]

        if button then
            View.ApplyVisual(button, choice)
            RCC.ConsumableTooltips.Refresh(button)
        end
    end
end
