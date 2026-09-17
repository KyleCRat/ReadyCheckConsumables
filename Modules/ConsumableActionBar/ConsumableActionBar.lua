local _, RCC = ...

RCC.ConsumableActionBar = RCC.ConsumableActionBar or {}

local ActionBar = RCC.ConsumableActionBar
local Binder = RCC.ConsumableActionBinder
local Catalog = RCC.ConsumableCatalog
local State = RCC.ConsumableState
local StateController = RCC.ConsumableStateController
local Surface = RCC.ConsumableSurface
local View = RCC.ConsumableButtonView

local FRAME_NAME = "RCCConsumablesActionBar"
local ELEMENT_KEY = "RCC_ConsumablesActionBar"

local VALID_FLYOUT_DIRECTIONS = {
    UP = true,
    DOWN = true,
    LEFT = true,
    RIGHT = true,
}

local VALID_DURATION_TEXT_POSITIONS = {
    TOP = true,
    BOTTOM = true,
    LEFT = true,
    RIGHT = true,
}

ActionBar.Limits = {
    buttonWidth = { min = 24, max = 128, default = 48 },
    buttonHeight = { min = 24, max = 128, default = 48 },
    gapX = { min = 0, max = 32, default = 2 },
    gapY = { min = 0, max = 32, default = 20 },
    textSize = { min = 8, max = 32, default = 16 },
}

local frame = CreateFrame("Frame", FRAME_NAME, UIParent)

frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetSize(View.SIZE, View.SIZE)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:SetFrameStrata("HIGH")
frame:SetToplevel(true)
frame:SetDontSavePosition(true)
frame:SetUserPlaced(false)
frame:Hide()

frame.surface = Surface.Create(frame, {
    capabilities = Binder.Capabilities.ACTION_BAR,
    clickable = true,
})

RCC.consumablesActionBar = frame
ActionBar.frame = frame
ActionBar.ELEMENT_KEY = ELEMENT_KEY

local pending = {
    layout = false,
    visual = false,
    visibility = false,
}

local function getPositiveSetting(key, fallback, minimum)
    local value = tonumber(RCC.GetSetting(key)) or fallback

    if value < minimum then
        return minimum
    end

    return value
end

local function getIconsPerRow()
    local value = tonumber(
        RCC.GetSetting("consumablesActionBar_iconsPerRow")
    ) or 10

    return math.max(1, math.floor(value + 0.5))
end

local function getFlyoutDirection()
    local direction = RCC.GetSetting(
        "consumablesActionBar_flyoutDirection"
    )

    if VALID_FLYOUT_DIRECTIONS[direction] then
        return direction
    end

    return "UP"
end

local function getDurationTextPosition()
    local position = RCC.GetSetting(
        "consumablesActionBar_durationTextPosition"
    )

    if VALID_DURATION_TEXT_POSITIONS[position] then
        return position
    end

    return "TOP"
end

function ActionBar.GetGeometry()
    local limits = ActionBar.Limits

    return {
        buttonWidth = getPositiveSetting(
            "consumablesActionBar_buttonWidth",
            limits.buttonWidth.default,
            1
        ),
        buttonHeight = getPositiveSetting(
            "consumablesActionBar_buttonHeight",
            limits.buttonHeight.default,
            1
        ),
        gapX = getPositiveSetting(
            "consumablesActionBar_gapX",
            limits.gapX.default,
            0
        ),
        gapY = getPositiveSetting(
            "consumablesActionBar_gapY",
            limits.gapY.default,
            0
        ),
        flyoutDirection = getFlyoutDirection(),
        durationTextPosition = getDurationTextPosition(),
        textSize = getPositiveSetting(
            "consumablesActionBar_textSize",
            limits.textSize.default,
            1
        ),
    }
end

function ActionBar.GetVisualOptions()
    return {
        -- The permanent bar uses hover feedback, not persistent reminders.
        showReminderGlow = false,
        showStackCount = RCC.GetSetting(
            "consumablesActionBar_showStackCount"
        ) == true,
        showDuration = RCC.GetSetting(
            "consumablesActionBar_showDuration"
        ) == true,
        showStatus = RCC.GetSetting(
            "consumablesActionBar_showStatus"
        ) == true,
        showProfessionQuality = RCC.GetSetting(
            "consumablesActionBar_showProfessionQuality"
        ) == true,
    }
end

-- Enabled buttons retain their slots when supplies are unavailable. The
-- off-hand enchant definition opts out when the slot cannot be enchanted;
-- use its resolved applicability, not item availability or enchant status.
local function shouldShowButton(definition)
    if not frame.surface.categories[definition.key] then
        return false
    end

    if definition.actionBarHideWhenInapplicable then
        local snapshot = frame.surface.latestSnapshot
        local state = snapshot and snapshot.states[definition.key]

        return State.IsApplicable(state)
    end

    return true
end

function ActionBar.GetEnabledCount()
    local definitions = Catalog.GetDefinitions()
    local count = 0

    for i = 1, #definitions do
        if RCC.GetSetting(definitions[i].actionBarSettingKey) == true then
            count = count + 1
        end
    end

    return count
end

function ActionBar.IsEnabled()
    return RCC.GetSetting("consumablesActionBar_enabled") == true
end

function ActionBar.ShouldShow()
    if not ActionBar.IsEnabled() then return false end

    local definitions = Catalog.GetDefinitions()

    for i = 1, #definitions do
        if shouldShowButton(definitions[i]) then
            return true
        end
    end

    return false
end

local function notifyMovementProviderOfResize()
    local EUI = _G.EllesmereUI

    if EUI and EUI.NotifyElementResized then
        EUI.NotifyElementResized(ELEMENT_KEY)
    end
end

function ActionBar.ApplyVisualOptions()
    if InCombatLockdown() then
        pending.visual = true

        return false
    end

    pending.visual = false

    return Surface.ApplyVisualOptions(
        frame.surface,
        ActionBar.GetVisualOptions()
    )
end

function ActionBar.ApplyLayout()
    if InCombatLockdown() then
        pending.layout = true

        return false
    end

    pending.layout = false
    pending.visual = false

    StateController.RefreshDemand()

    local definitions = Catalog.GetDefinitions()
    local geometry = ActionBar.GetGeometry()
    local iconsPerRow = getIconsPerRow()
    local visibleCount = 0

    Surface.HideFlyouts(frame.surface)
    Surface.ApplyGeometry(frame.surface, geometry)
    Surface.ApplyVisualOptions(
        frame.surface,
        ActionBar.GetVisualOptions()
    )

    for i = 1, #definitions do
        local definition = definitions[i]
        local button = frame.surface.buttons[definition.key]

        button:ClearAllPoints()

        if shouldShowButton(definition) then
            local column = visibleCount % iconsPerRow
            local row = math.floor(visibleCount / iconsPerRow)

            button:SetPoint(
                "TOPLEFT",
                frame,
                "TOPLEFT",
                column * (geometry.buttonWidth + geometry.gapX),
                -row * (geometry.buttonHeight + geometry.gapY)
            )
            button:Show()
            visibleCount = visibleCount + 1
        else
            button:Hide()
        end
    end

    local columns = math.max(1, math.min(visibleCount, iconsPerRow))
    local rows = visibleCount > 0
        and math.ceil(visibleCount / iconsPerRow)
        or 1

    frame:SetSize(
        View.GetWidth(columns, geometry.buttonWidth, geometry.gapX),
        View.GetStackHeight(rows, geometry.buttonHeight, geometry.gapY)
    )

    notifyMovementProviderOfResize()

    return visibleCount > 0
end

function ActionBar.ApplyVisibility()
    if InCombatLockdown() then
        pending.visibility = true

        return false
    end

    pending.visibility = false

    -- Reconcile enablement before showing/hiding. New categories get live
    -- inputs and prepared actions; an off-hand-only hidden bar stays requested.
    StateController.RefreshDemand()

    if ActionBar.ShouldShow() then
        frame:Show()
    else
        Surface.HideFlyouts(frame.surface)
        frame:Hide()
    end

    return true
end

function ActionBar.ApplyAll()
    if InCombatLockdown() then
        pending.layout = true
        pending.visual = true
        pending.visibility = true

        return false
    end

    ActionBar.ApplyLayout()
    RCC.ConsumableActionBarPosition.ApplyCurrent()
    ActionBar.ApplyVisibility()

    return true
end

function ActionBar.RequestLayout()
    if InCombatLockdown() then
        pending.layout = true
        pending.visibility = true

        return false
    end

    ActionBar.ApplyLayout()

    return ActionBar.ApplyVisibility()
end

function ActionBar.RequestVisualOptions()
    return ActionBar.ApplyVisualOptions()
end

function ActionBar.RequestVisibility()
    return ActionBar.ApplyVisibility()
end

function ActionBar.RequestApplySettings()
    return ActionBar.ApplyAll()
end

function ActionBar.ApplyPending()
    if InCombatLockdown() then return false end

    if pending.layout then
        ActionBar.ApplyLayout()
    elseif pending.visual then
        ActionBar.ApplyVisualOptions()
    end

    RCC.ConsumableActionBarPosition.ApplyPending()

    if pending.visibility then
        ActionBar.ApplyVisibility()
    end

    Surface.ReconcileSecure(frame.surface)

    return true
end

StateController.RegisterConsumer("consumablesActionBar", {
    GetCategories = function()
        -- Protected buttons cannot adopt settings/layout changes in combat.
        -- Keep their prepared categories live until out-of-combat reconciliation.
        if InCombatLockdown() then return frame.surface.categories end

        local categories = {}
        if not ActionBar.IsEnabled() then return categories end

        for _, definition in ipairs(Catalog.GetDefinitions()) do
            if RCC.GetSetting(definition.actionBarSettingKey) == true then
                categories[definition.key] = true
            end
        end
        return categories
    end,
    ApplySnapshot = function(_, snapshot, categories)
        Surface.ApplySnapshot(frame.surface, snapshot, categories)

        local definitions = Catalog.GetDefinitions()

        for i = 1, #definitions do
            local definition = definitions[i]
            local button = frame.surface.buttons[definition.key]

            if button:IsShown() ~= shouldShowButton(definition) then
                -- Reflow only when visibility changes. RequestLayout keeps
                -- protected layout changes deferred until combat ends.
                ActionBar.RequestLayout()

                break
            end
        end
    end,
})

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_ENABLED" then
        ActionBar.ApplyPending()

        return
    end

    local addonName = ...

    if addonName ~= "ReadyCheckConsumables" then return end

    self:UnregisterEvent("ADDON_LOADED")

    RCC.ConsumableActionBarPosition.Initialize()
    ActionBar.ApplyAll()
end)
