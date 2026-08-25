local _, RCC = ...

RCC.ConsumableActionBarPosition =
    RCC.ConsumableActionBarPosition or {}

local Position = RCC.ConsumableActionBarPosition
local ActionBar = RCC.ConsumableActionBar
local Shared = RCC.ConsumableSettingsShared

local ELEMENT_KEY = ActionBar.ELEMENT_KEY
local DEFAULT_POSITION = {
    point = "CENTER",
    relPoint = "CENTER",
    x = 0,
    y = 0,
}

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

local movementProvider
local initialized = false
local pendingValues
local pendingApply = false

local function syncSettingsPages()
    Shared.SyncPages()
end

local function normalizeCoordinate(value, fallback)
    local number = tonumber(value)

    if not number
        or number ~= number
        or number == math.huge
        or number == -math.huge
    then
        return fallback or 0
    end

    return number
end

local function copyPosition(position)
    if type(position) ~= "table" then return end

    local point = VALID_POINTS[position.point]
        and position.point or DEFAULT_POSITION.point
    local relPoint = VALID_POINTS[position.relPoint]
        and position.relPoint or DEFAULT_POSITION.relPoint

    return {
        point = point,
        relPoint = relPoint,
        x = normalizeCoordinate(position.x, DEFAULT_POSITION.x),
        y = normalizeCoordinate(position.y, DEFAULT_POSITION.y),
    }
end

local function applyPosition(position)
    if InCombatLockdown() then
        pendingApply = true

        return false
    end

    pendingApply = false
    position = copyPosition(position) or copyPosition(DEFAULT_POSITION)

    local frame = ActionBar.frame

    frame:ClearAllPoints()
    frame:SetPoint(
        position.point,
        UIParent,
        position.relPoint,
        position.x,
        position.y
    )

    return true
end

local function getDatabase()
    return ReadyCheckConsumablesDB
end

local function registerEllesmereUI()
    if not C_AddOns.IsAddOnLoaded("EllesmereUI") then return false end

    local EUI = _G.EllesmereUI

    if not EUI
        or not EUI.MakeUnlockElement
        or not EUI.RegisterUnlockElements
    then
        return false
    end

    local element = EUI.MakeUnlockElement({
        key = ELEMENT_KEY,
        label = "Consumables Action Bar",
        group = "Ready Check Consumables",
        order = 700,
        noResize = true,
        getFrame = function()
            return ActionBar.frame
        end,
        getSize = function()
            return ActionBar.frame:GetWidth(), ActionBar.frame:GetHeight()
        end,
        isHidden = function()
            return not ActionBar.ShouldShow()
        end,
        savePos = function(_, point, relativePoint, x, y)
            local db = getDatabase()

            if not db then return end

            db.consumablesActionBarPosition = copyPosition({
                point = point,
                relPoint = relativePoint,
                x = x,
                y = y,
            })

            local unlockActive = EUI.IsUnlockModeActive
                and EUI:IsUnlockModeActive()

            if not unlockActive then
                applyPosition(db.consumablesActionBarPosition)
            end

            syncSettingsPages()
        end,
        loadPos = function()
            local db = getDatabase()

            return db and copyPosition(
                db.consumablesActionBarPosition
            )
        end,
        clearPos = function()
            local db = getDatabase()

            if db then
                db.consumablesActionBarPosition = nil
            end

            syncSettingsPages()
        end,
        applyPos = function()
            local db = getDatabase()

            applyPosition(db and db.consumablesActionBarPosition)
        end,
    })

    EUI:RegisterUnlockElements({ element }, "ReadyCheckConsumables")

    if EUI.RegisterUnlockModeListener then
        EUI:RegisterUnlockModeListener(Position, function(active)
            if not active then
                syncSettingsPages()
            end
        end)
    end

    movementProvider = "ellesmereui"

    local db = getDatabase()

    applyPosition(db and db.consumablesActionBarPosition)

    return true
end

local function getEditModePositions()
    local db = getDatabase()

    if not db then return end

    if type(db.consumablesActionBarEditModePositions) ~= "table" then
        db.consumablesActionBarEditModePositions = {}
    end

    return db.consumablesActionBarEditModePositions
end

local function getActiveEditModeLayoutName()
    local lib = LibStub("LibEditMode", true)

    return lib and lib:GetActiveLayoutName()
end

local function getCurrentStoredPosition()
    local db = getDatabase()

    if movementProvider == "editmode" then
        local positions = getEditModePositions()
        local layoutName = getActiveEditModeLayoutName()

        return positions and layoutName and positions[layoutName]
    end

    return db and db.consumablesActionBarPosition
end

local function applyEditModeLayout(layoutName)
    local positions = getEditModePositions()
    local position = positions and positions[layoutName]

    applyPosition(position)
    syncSettingsPages()
end

local function registerLibEditMode()
    local lib = LibStub("LibEditMode", true)

    if not lib then return false end

    lib:AddFrame(
        ActionBar.frame,
        function(_, layoutName, point, x, y)
            local positions = getEditModePositions()

            if not positions or not layoutName then return end

            positions[layoutName] = copyPosition({
                point = point,
                relPoint = point,
                x = x,
                y = y,
            })
            syncSettingsPages()
        end,
        {
            point = DEFAULT_POSITION.point,
            x = DEFAULT_POSITION.x,
            y = DEFAULT_POSITION.y,
        },
        "Consumables Action Bar"
    )

    movementProvider = "editmode"

    lib:RegisterCallback("layout", function(layoutName)
        applyEditModeLayout(layoutName)
    end)
    lib:RegisterCallback("create", function(layoutName, _, sourceLayoutName)
        local positions = getEditModePositions()

        if not positions or not layoutName then return end

        positions[layoutName] = copyPosition(
            sourceLayoutName and positions[sourceLayoutName]
        )
    end)
    lib:RegisterCallback("rename", function(oldLayoutName, newLayoutName)
        local positions = getEditModePositions()

        if not positions or not newLayoutName then return end

        positions[newLayoutName] = positions[oldLayoutName]
        positions[oldLayoutName] = nil
    end)
    lib:RegisterCallback("delete", function(layoutName)
        local positions = getEditModePositions()

        if positions then
            positions[layoutName] = nil
        end
    end)

    local layoutName = lib:GetActiveLayoutName()

    if layoutName then
        applyEditModeLayout(layoutName)
    else
        applyPosition(DEFAULT_POSITION)
    end

    return true
end

function Position.Initialize()
    if initialized then return movementProvider end

    initialized = true

    if registerEllesmereUI() then
        return movementProvider
    end

    registerLibEditMode()

    return movementProvider
end

function Position.GetMovementProvider()
    return movementProvider
end

function Position.GetCurrent()
    if pendingValues then
        local position = copyPosition(getCurrentStoredPosition())
            or copyPosition(DEFAULT_POSITION)

        for key, value in pairs(pendingValues) do
            position[key] = value
        end

        return copyPosition(position)
    end

    return copyPosition(getCurrentStoredPosition())
        or copyPosition(DEFAULT_POSITION)
end

function Position.SetCurrent(values)
    if type(values) ~= "table" then return false end

    if InCombatLockdown() then
        pendingValues = pendingValues or {}

        for key, value in pairs(values) do
            pendingValues[key] = value
        end

        return false
    end

    local position = Position.GetCurrent()

    pendingValues = nil

    if values.point ~= nil then
        position.point = values.point
    end

    if values.relPoint ~= nil then
        position.relPoint = values.relPoint
    end

    if values.x ~= nil then
        position.x = values.x
    end

    if values.y ~= nil then
        position.y = values.y
    end

    position = copyPosition(position)

    if movementProvider == "editmode" then
        local positions = getEditModePositions()
        local layoutName = getActiveEditModeLayoutName()

        if not positions or not layoutName then return false end

        positions[layoutName] = position
    else
        local db = getDatabase()

        if not db then return false end

        db.consumablesActionBarPosition = position
    end

    applyPosition(position)
    syncSettingsPages()

    return true
end

function Position.ResetCurrent()
    if InCombatLockdown() then return false end

    pendingValues = nil

    if movementProvider == "editmode" then
        local positions = getEditModePositions()
        local layoutName = getActiveEditModeLayoutName()

        if not positions or not layoutName then return false end

        positions[layoutName] = nil
    else
        local db = getDatabase()

        if not db then return false end

        db.consumablesActionBarPosition = nil
    end

    applyPosition(DEFAULT_POSITION)
    syncSettingsPages()

    return true
end

function Position.ApplyCurrent()
    return applyPosition(Position.GetCurrent())
end

function Position.ApplyPending()
    if InCombatLockdown() then return false end

    local values = pendingValues

    if values then
        pendingValues = nil

        return Position.SetCurrent(values)
    elseif pendingApply then
        return Position.ApplyCurrent()
    end

    return true
end
