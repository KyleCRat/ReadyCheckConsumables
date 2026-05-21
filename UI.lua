local _, RCC = ...

RCC.UI = RCC.UI or {}
local UI = RCC.UI

local floor = floor

UI.FONT = "Interface\\AddOns\\ReadyCheckConsumables\\Media\\Fonts\\PTSansNarrow-Bold.ttf"

local CONTROL_BG        = { r = 0.1, g = 0.1, b = 0.1, a = 0.9 }
local CONTROL_HIGHLIGHT = { r = 0.3, g = 0.3, b = 0.3, a = 0.5 }
local POPUP_TRACK       = { r = 0.5, g = 0.5, b = 0.5, a = 1 }

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
    options.font = options.font or UI.FONT
    options.bgColor = options.bgColor or
        { r = CONTROL_BG.r, g = CONTROL_BG.g, b = CONTROL_BG.b, a = 0.95 }
    options.trackColor = options.trackColor or
        { r = POPUP_TRACK.r, g = POPUP_TRACK.g, b = POPUP_TRACK.b, a = POPUP_TRACK.a }

    return LibStub("LibPopupSlider-1.0"):Create(button, options)
end
