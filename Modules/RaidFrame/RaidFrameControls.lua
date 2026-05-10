local _, RCC = ...

RCC.RaidFrameControls = RCC.RaidFrameControls or {}
local Controls = RCC.RaidFrameControls

local UI = RCC.UI

local floor = floor

local SCALE_MIN          = 50
local SCALE_MAX          = 150
local SCALE_STEP         = 5
local SCALE_BUTTON_WIDTH = 86

local function savePosition(self)
    self:StopMovingOrSizing()

    if not ReadyCheckConsumablesDB then
        return
    end

    local point, _, relPoint, x, y = self:GetPoint(1)
    ReadyCheckConsumablesDB.raidFramePos = {
        point    = point,
        relPoint = relPoint,
        x        = x,
        y        = y,
    }
end

function Controls.Create(frame)
    local controls = {
        frame = frame,
        positionRestored = false,
    }

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", savePosition)

    frame.scaleButton = UI.CreateControlButton(frame, SCALE_BUTTON_WIDTH, 20, "")
    frame.scaleButton:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 1, -3)

    controls.scalePopup = UI.CreatePopupSlider(frame.scaleButton, {
        minValue = SCALE_MIN,
        maxValue = SCALE_MAX,
        step = SCALE_STEP,
        label = "Scale",

        formatValue = function(value)
            return value .. "%"
        end,

        onValueChanged = function(value)
            frame.scaleButton.text:SetText("Scale: " .. value .. "%")
            frame:SetScale(value / 100)

            if ReadyCheckConsumablesDB then
                ReadyCheckConsumablesDB.raidFrame_scale = value / 100
            end
        end,
    })

    frame.close = UI.CreateControlButton(
        frame, 0, 20, CLOSE or "x", "SecureHandlerClickTemplate"
    )
    frame.close:SetPoint("TOPLEFT", frame.scaleButton, "TOPRIGHT", 3, 0)
    frame.close:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -1, -3)

    frame.close:SetFrameRef("CLLRaidFrame", frame)
    frame.close:SetAttribute("_onclick", [[
    self:GetFrameRef("CLLRaidFrame"):Hide()
]])

    function controls:SyncScale()
        local scale = ReadyCheckConsumablesDB
            and ReadyCheckConsumablesDB.raidFrame_scale
            or 1

        self.scalePopup:SetValue(floor(scale * 100 + 0.5))
    end

    function controls:RestorePosition()
        if self.positionRestored then
            return
        end

        self.positionRestored = true

        if not ReadyCheckConsumablesDB then
            return
        end

        local pos = ReadyCheckConsumablesDB.raidFramePos

        if not pos then
            return
        end

        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    end

    function frame:SyncScaleControl()
        controls:SyncScale()
    end

    controls:SyncScale()

    return controls
end
