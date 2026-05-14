local _, RCC = ...

RCC.UI = RCC.UI or {}
local UI = RCC.UI

local floor = floor

UI.FONT = "Interface\\AddOns\\ReadyCheckConsumables\\media\\fonts\\PTSansNarrow-Bold.ttf"

local CONTROL_BG        = { r = 0.1, g = 0.1, b = 0.1, a = 0.9 }
local CONTROL_HIGHLIGHT = { r = 0.3, g = 0.3, b = 0.3, a = 0.5 }
local POPUP_TRACK       = { r = 0.5, g = 0.5, b = 0.5, a = 0.8 }

local function clamp(value, minValue, maxValue)
    return max(minValue, min(maxValue, value))
end

function UI.ApplyControlStyle(control, text, fontSize)
    control.bg = control:CreateTexture(nil, "BACKGROUND")
    control.bg:SetAllPoints()
    control.bg:SetColorTexture(CONTROL_BG.r, CONTROL_BG.g,
        CONTROL_BG.b, CONTROL_BG.a)

    control.border = control:CreateTexture(nil, "BORDER")
    control.border:SetPoint("TOPLEFT", -1, 1)
    control.border:SetPoint("BOTTOMRIGHT", 1, -1)
    control.border:SetColorTexture(0, 0, 0, 1)

    control.highlight = control:CreateTexture(nil, "ARTWORK")
    control.highlight:SetAllPoints(control.bg)
    control.highlight:SetColorTexture(CONTROL_HIGHLIGHT.r,
        CONTROL_HIGHLIGHT.g, CONTROL_HIGHLIGHT.b, CONTROL_HIGHLIGHT.a)
    control.highlight:SetBlendMode("ADD")
    control.highlight:Hide()

    if text then
        control.text = control:CreateFontString(nil, "OVERLAY")
        control.text:SetPoint("CENTER")
        control.text:SetFont(UI.FONT, fontSize or 12, "OUTLINE")
        control.text:SetText(text)
        control.text:SetTextColor(1, 1, 1)
    end

    control:SetScript("OnEnter", function(self)
        self.highlight:Show()
    end)

    control:SetScript("OnLeave", function(self)
        self.highlight:Hide()
    end)
end

function UI.CreateControlFrame(parent, width, height)
    local control = CreateFrame("Frame", nil, parent)

    control:SetSize(width, height)
    UI.ApplyControlStyle(control)

    return control
end

function UI.CreateControlButton(parent, width, height, text, template)
    local control = CreateFrame("Button", nil, parent, template)

    control:SetSize(width, height)
    UI.ApplyControlStyle(control, text or "")

    return control
end

function UI.CreatePopupSlider(button, options)
    local minValue    = options.minValue or 0
    local maxValue    = options.maxValue or 100
    local step        = options.step or 1
    local sliderH     = options.sliderHeight or 180
    local sensitivity = options.sensitivity or 1
    local popupW      = options.popupWidth or 44
    local padY        = options.paddingY or 20
    local labelGap    = options.labelGap or 4
    local popupH      = sliderH + padY * 2
    local formatValue = options.formatValue or tostring

    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetSize(popupW, popupH)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    popup:SetBackdropColor(CONTROL_BG.r, CONTROL_BG.g, CONTROL_BG.b, 0.95)
    popup:SetBackdropBorderColor(0, 0, 0, 1)
    popup:Hide()

    popup.track = popup:CreateTexture(nil, "BACKGROUND")
    popup.track:SetSize(2, sliderH)
    popup.track:SetPoint("CENTER")
    popup.track:SetColorTexture(POPUP_TRACK.r, POPUP_TRACK.g,
        POPUP_TRACK.b, POPUP_TRACK.a)

    popup.slider = CreateFrame("Slider", nil, popup, "MinimalSliderTemplate")
    popup.slider:SetOrientation("VERTICAL")
    popup.slider:SetSize(20, sliderH)
    popup.slider:SetPoint("CENTER")
    popup.slider:SetMinMaxValues(minValue, maxValue)
    popup.slider:SetValueStep(step)
    popup.slider:SetObeyStepOnDrag(true)
    popup.slider:EnableMouse(false)

    popup.label = popup:CreateFontString(nil, "OVERLAY")
    popup.label:SetPoint("BOTTOM", popup.slider, "TOP", 0, labelGap)
    popup.label:SetFont(UI.FONT, 11, "OUTLINE")
    popup.label:SetText(options.label or "")
    popup.label:SetTextColor(1, 1, 1)

    popup.value = popup:CreateFontString(nil, "OVERLAY")
    popup.value:SetPoint("TOP", popup.slider, "BOTTOM", 0, -labelGap)
    popup.value:SetFont(UI.FONT, 11, "OUTLINE")
    popup.value:SetTextColor(1, 1, 1)

    local function toSlider(value)
        return maxValue + minValue - value
    end

    local function fromSlider(value)
        return maxValue + minValue - value
    end

    local function snap(value)
        return floor(value / step + 0.5) * step
    end

    local currentValue

    local function setValue(value)
        value = clamp(snap(value), minValue, maxValue)

        if currentValue == value then
            return false
        end

        currentValue = value
        popup.value:SetText(formatValue(value))
        popup.slider:SetValue(toSlider(value))

        if options.onValueChanged then
            options.onValueChanged(value)
        end

        return true
    end

    local dragStartY
    local dragStartValue

    local function finishDrag()
        if not dragStartY then
            return
        end

        dragStartY = nil
        dragStartValue = nil
        popup:SetScript("OnUpdate", nil)
        popup:Hide()
    end

    button:SetScript("OnMouseDown", function(self, mouseButton)
        if mouseButton ~= "LeftButton" then
            return
        end

        local mouseX, mouseY = GetCursorPosition()
        local uiScale = UIParent:GetEffectiveScale()
        dragStartY = mouseY / uiScale
        dragStartValue = currentValue or fromSlider(popup.slider:GetValue())

        popup:ClearAllPoints()
        popup:SetPoint("TOP", UIParent, "BOTTOMLEFT",
            mouseX / uiScale, dragStartY + popupH / 2)
        popup:Show()

        popup:SetScript("OnUpdate", function()
            if not IsMouseButtonDown("LeftButton") then
                finishDrag()

                return
            end

            local _, cursorY = GetCursorPosition()
            cursorY = cursorY / UIParent:GetEffectiveScale()

            local delta = cursorY - dragStartY
            local pixelsPerUnit = sliderH * sensitivity
                / (maxValue - minValue)

            setValue(dragStartValue + delta / pixelsPerUnit)
        end)
    end)

    button:HookScript("OnHide", finishDrag)

    popup.slider:SetScript("OnValueChanged", function(self, value)
        setValue(fromSlider(value))
    end)

    popup.SetValue = function(self, value)
        setValue(value)
    end

    popup.GetValue = function()
        return currentValue
    end

    return popup
end
