local _, RCC = ...

RCC.ReadyCheckMover = {}

local Mover = RCC.ReadyCheckMover
local popup = ReadyCheckFrame
local dialog = ReadyCheckListenerFrame

local VALID_POINTS = {
    TOPLEFT = true,
    TOP = true,
    TOPRIGHT = true,
    LEFT = true,
    CENTER = true,
    RIGHT = true,
    BOTTOMLEFT = true,
    BOTTOM = true,
    BOTTOMRIGHT = true,
}

local initialized = false
local enabled = false
local moving = false
local discardDrag = false
local pendingApply = false
local originalState

local function isCoordinate(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function restorePosition()
    local position = RCC.settingsDB:Get("readyCheckPosition")

    if type(position) ~= "table"
        or not VALID_POINTS[position.point]
        or not VALID_POINTS[position.relPoint]
        or not isCoordinate(position.x)
        or not isCoordinate(position.y)
    then
        -- Without an RCC position, leave Blizzard's or another mover's current
        -- placement alone. Re-enabling must not restore an old session anchor.
        return
    end

    popup:ClearAllPoints()
    popup:SetPoint(position.point, UIParent, position.relPoint, position.x, position.y)
end

local function stopMoving()
    if not moving then return end

    -- Another addon or an anchored secure control can protect the popup.
    -- Cancel an interrupted drag after combat instead of mutating it in lockdown
    -- or saving wherever the cursor happens to be when combat ends.
    if InCombatLockdown() and popup:IsProtected() then
        discardDrag = true
        pendingApply = true

        return
    end

    popup:StopMovingOrSizing()
    moving = false

    if not discardDrag then
        local point, _, relPoint, x, y = popup:GetPoint(1)

        RCC.settingsDB:Set("readyCheckPosition", {
            point = point,
            relPoint = relPoint,
            x = x,
            y = y,
        })
    end

    discardDrag = false

    if not InCombatLockdown() then
        popup:SetUserPlaced(false)
    end
end

local function startMoving()
    if not enabled or InCombatLockdown() then return end

    discardDrag = false
    popup:SetMovable(true)
    popup:StartMoving()
    moving = true
end

local function onDialogShown()
    if not enabled then return end

    if InCombatLockdown() then
        pendingApply = true

        return
    end

    restorePosition()
end

local function initialize()
    -- Only the existing visible child receives drag input. Blizzard leaves the
    -- outer ReadyCheckFrame shown for the initiator while hiding this child;
    -- enabling mouse input on that outer frame would leave an invisible hitbox.
    -- Hook scripts without replacing Blizzard's show behavior or button clicks.
    dialog:RegisterForDrag("LeftButton")
    dialog:HookScript("OnDragStart", startMoving)
    dialog:HookScript("OnDragStop", stopMoving)
    dialog:HookScript("OnHide", stopMoving)
    dialog:HookScript("OnShow", onDialogShown)
    initialized = true
end

function Mover.DiscardPending()
    -- The active DB object is rebound during a profile change. A drag that
    -- started in the old profile must never save into the new profile.
    discardDrag = true
end

function Mover.ApplySettings()
    if InCombatLockdown() then
        pendingApply = true

        return
    end

    pendingApply = false
    local allowDragging = RCC.GetSetting("readyCheckMover_enabled")

    if not allowDragging then
        -- Forget only this profile's RCC position. Do not let an interrupted
        -- drag immediately save it again while releasing our input handling.
        discardDrag = true
        RCC.settingsDB:ResetPath("readyCheckPosition")
    end

    stopMoving()

    if allowDragging then
        if not initialized then
            initialize()
        end

        if not enabled then
            originalState = {
                mouseClickEnabled = dialog:IsMouseClickEnabled(),
                mouseMotionEnabled = dialog:IsMouseMotionEnabled(),
                dontSavePosition = popup:GetDontSavePosition(),
                userPlaced = popup:IsUserPlaced(),
            }

            popup:SetMovable(true)
            popup:SetClampedToScreen(true)
            popup:SetDontSavePosition(true)
            popup:SetUserPlaced(false)
            dialog:EnableMouse(true)
            enabled = true
        end

        restorePosition()
    elseif enabled then
        -- RCC's handlers stop here; the popup's movement capabilities are
        -- shared with other movers. Restoring an old movable=false snapshot
        -- would prevent their still-installed hooks from moving the frame.
        enabled = false
        dialog:SetMouseClickEnabled(originalState.mouseClickEnabled)
        dialog:SetMouseMotionEnabled(originalState.mouseMotionEnabled)
        popup:SetUserPlaced(originalState.userPlaced)
        popup:SetDontSavePosition(originalState.dontSavePosition)
    end
end

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        stopMoving()
    elseif pendingApply then
        Mover.ApplySettings()
    end
end)
