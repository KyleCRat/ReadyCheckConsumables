-- LibPopupSlider-1.0 - a vertical drag-to-adjust slider popup
-- Attach to any button: click-and-drag opens a vertical slider at the cursor.
-- The popup positions itself so the thumb aligns with the cursor on open.
--
-- Usage:
--   local LibPopupSlider = LibStub("LibPopupSlider-1.0")
--   local popup = LibPopupSlider:Create(button, {
--       minValue       = 50,
--       maxValue       = 150,
--       step           = 5,
--       label          = "Scale",
--       formatValue    = function(v) return v .. "%" end,
--       onValueChanged = function(v) ... end,
--       -- Optional overrides:
--       sliderHeight   = 180,
--       sensitivity    = 1,
--       popupWidth     = 44,
--       paddingY       = 20,
--       labelGap       = 4,
--       font           = "Fonts\\FRIZQT__.TTF",
--       bgColor        = { r=0.1, g=0.1, b=0.1, a=0.95 },
--       trackColor     = { r=0.5, g=0.5, b=0.5, a=1 },
--   })
--
--   popup:SetValue(100)
--   popup:GetValue()

local MAJOR_VERSION = "LibPopupSlider-1.0"
local MINOR_VERSION = 1

if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

local floor = floor

-- -----------------------------------------------------------------------------
--- Helpers
-- -----------------------------------------------------------------------------

local function clamp(value, lo, hi)
    return max(lo, min(hi, value))
end

-- -----------------------------------------------------------------------------
--- Create
-- -----------------------------------------------------------------------------

function lib:Create(button, options)
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
    local font        = options.font or "Fonts\\FRIZQT__.TTF"

    local bgColor    = options.bgColor
        or { r = 0.1, g = 0.1, b = 0.1, a = 0.95 }
    local trackColor = options.trackColor
        or { r = 0.5, g = 0.5, b = 0.5, a = 1 }

    -- -----------------------------------------------------------------
    --- Popup frame
    -- -----------------------------------------------------------------

    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetSize(popupW, popupH)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    popup:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    popup:SetBackdropBorderColor(0, 0, 0, 1)
    popup:Hide()

    -- -----------------------------------------------------------------
    --- Track and slider
    -- -----------------------------------------------------------------

    local diamondSize  = 8
    local thumbH       = 20
    local diamondInset = thumbH / 2

    popup.track = popup:CreateTexture(nil, "ARTWORK")
    popup.track:SetSize(2, sliderH - diamondInset * 2)
    popup.track:SetPoint("CENTER")
    popup.track:SetColorTexture(trackColor.r, trackColor.g,
        trackColor.b, trackColor.a)

    popup.slider = CreateFrame("Slider", nil, popup)
    popup.slider:SetOrientation("VERTICAL")
    popup.slider:SetSize(20, sliderH)
    popup.slider:SetPoint("CENTER")
    popup.slider:SetMinMaxValues(minValue, maxValue)
    popup.slider:SetValueStep(step)
    popup.slider:SetObeyStepOnDrag(true)
    popup.slider:EnableMouse(false)

    local thumb = popup.slider:CreateTexture(nil, "ARTWORK")
    thumb:SetAtlas("Minimal_SliderBar_Button")
    thumb:SetSize(thumbH, thumbH)
    popup.slider:SetThumbTexture(thumb)

    -- -----------------------------------------------------------------
    --- Diamond markers (top, center, bottom)
    -- -----------------------------------------------------------------

    local function createDiamond(anchor, relPoint)
        local d = popup:CreateTexture(nil, "OVERLAY")
        d:SetSize(diamondSize, diamondSize)
        d:SetPoint("CENTER", anchor, relPoint)
        d:SetColorTexture(trackColor.r, trackColor.g,
            trackColor.b, trackColor.a)
        d:SetRotation(math.rad(45))

        return d
    end

    popup.diamondTop = createDiamond(popup.slider, "TOP")
    popup.diamondTop:ClearAllPoints()
    popup.diamondTop:SetPoint("CENTER", popup.slider, "TOP", 0, -diamondInset)

    popup.diamondCenter = createDiamond(popup.slider, "CENTER")

    popup.diamondBottom = createDiamond(popup.slider, "BOTTOM")
    popup.diamondBottom:ClearAllPoints()
    popup.diamondBottom:SetPoint("CENTER", popup.slider, "BOTTOM",
        0, diamondInset)

    -- -----------------------------------------------------------------
    --- Labels
    -- -----------------------------------------------------------------

    popup.label = popup:CreateFontString(nil, "OVERLAY")
    popup.label:SetPoint("BOTTOM", popup.slider, "TOP", 0, labelGap)
    popup.label:SetFont(font, 11, "OUTLINE")
    popup.label:SetText(options.label or "")
    popup.label:SetTextColor(1, 1, 1)

    popup.value = popup:CreateFontString(nil, "OVERLAY")
    popup.value:SetPoint("TOP", popup.slider, "BOTTOM", 0, -labelGap)
    popup.value:SetFont(font, 11, "OUTLINE")
    popup.value:SetTextColor(1, 1, 1)

    -- -----------------------------------------------------------------
    --- Value management
    -- -----------------------------------------------------------------

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

    -- -----------------------------------------------------------------
    --- Drag logic
    -- -----------------------------------------------------------------

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
        dragStartValue = currentValue
            or fromSlider(popup.slider:GetValue())

        local thumbFraction = (maxValue - dragStartValue)
            / (maxValue - minValue)
        local thumbOffset = padY + thumbH / 2
            + thumbFraction * (sliderH - thumbH)

        local popupX = mouseX / uiScale
        local popupY = dragStartY + thumbOffset
        local screenW = UIParent:GetWidth()
        local screenH = UIParent:GetHeight()

        popupX = clamp(popupX, popupW / 2, screenW - popupW / 2)
        popupY = clamp(popupY, popupH, screenH)

        popup:ClearAllPoints()
        popup:SetPoint("TOP", UIParent, "BOTTOMLEFT", popupX, popupY)
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

            local rawValue = dragStartValue + delta / pixelsPerUnit

            setValue(rawValue)

            if rawValue > maxValue or rawValue < minValue then
                dragStartY = cursorY
                dragStartValue = currentValue
            end
        end)
    end)

    button:HookScript("OnHide", finishDrag)

    popup.slider:SetScript("OnValueChanged", function(self, value)
        setValue(fromSlider(value))
    end)

    -- -----------------------------------------------------------------
    --- Public API
    -- -----------------------------------------------------------------

    popup.SetValue = function(self, value)
        setValue(value)
    end

    popup.GetValue = function()
        return currentValue
    end

    return popup
end
