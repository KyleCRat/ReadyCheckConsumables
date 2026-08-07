local _, RCC = ...

RCC.SettingsCanvasControls = RCC.SettingsCanvasControls or {}

local Controls = RCC.SettingsCanvasControls
local CHECKBOX_SIZE = 34
local CHECKBOX_LABEL_GAP = 2
local CHECKBOX_CHECKMARK_ATLAS = "common-icon-checkmark-yellow"
local CHECKBOX_CHECKMARK_SCALE = 1.25
local CHECKBOX_CHECKMARK_OFFSET_X = 2
local CHECKBOX_CHECKMARK_OFFSET_Y = 2

local TERTIARY_BUTTON_ATLASES = {
    regular = {
        normal = "common-button-tertiary-normal",
        hover = "common-button-tertiary-hover",
        pressed = "common-button-tertiary-pressed",
        disabled = "common-button-tertiary-disabled",
    },
    small = {
        normal = "common-button-tertiary-normal-small",
        hover = "common-button-tertiary-hover-small",
        pressed = "common-button-tertiary-pressed-small",
        disabled = "common-button-tertiary-disabled-small",
    },
    square = {
        normal = "common-button-tertiary-square-normal",
        hover = "common-button-tertiary-square-hover",
        pressed = "common-button-tertiary-square-pressed",
        disabled = "common-button-tertiary-square-disabled",
    },
}

local function createButtonState(button, layer, atlas)
    local texture = button:CreateTexture(nil, layer)

    texture:SetAllPoints(button)
    texture:SetAtlas(atlas, false)

    return texture
end

function Controls.CreateText(parent, fontObject, text, width)
    local fontString = parent:CreateFontString(nil, "ARTWORK")

    if fontObject then
        fontString:SetFontObject(fontObject)
    end

    fontString:SetJustifyH("LEFT")
    fontString:SetJustifyV("TOP")

    if width then
        fontString:SetWidth(width)
    end

    fontString:SetText(text or "")

    return fontString
end

function Controls.SetTooltip(frame, text)
    frame.tooltipText = text

    frame:SetScript("OnEnter", function(self)
        if not self.tooltipText then return end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.tooltipText, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function Controls.CreateCheckbox(parent, label, width, tooltip, onChanged)
    local checkbox = CreateFrame("CheckButton", nil, parent)
    local atlases = TERTIARY_BUTTON_ATLASES.square

    checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
    checkbox:SetNormalTexture(
        createButtonState(checkbox, "BACKGROUND", atlases.normal)
    )
    checkbox:SetPushedTexture(
        createButtonState(checkbox, "BACKGROUND", atlases.pressed)
    )
    checkbox:SetHighlightTexture(
        createButtonState(checkbox, "HIGHLIGHT", atlases.hover)
    )
    checkbox:SetDisabledTexture(
        createButtonState(checkbox, "BACKGROUND", atlases.disabled)
    )

    local checkedTexture = checkbox:CreateTexture(nil, "ARTWORK")

    checkedTexture:SetPoint(
        "CENTER",
        checkbox,
        "CENTER",
        CHECKBOX_CHECKMARK_OFFSET_X,
        CHECKBOX_CHECKMARK_OFFSET_Y
    )
    checkedTexture:SetAtlas(CHECKBOX_CHECKMARK_ATLAS, true)
    checkedTexture:SetScale(CHECKBOX_CHECKMARK_SCALE)
    checkbox:SetCheckedTexture(checkedTexture)

    local disabledCheckedTexture = checkbox:CreateTexture(nil, "ARTWORK")

    disabledCheckedTexture:SetPoint(
        "CENTER",
        checkbox,
        "CENTER",
        CHECKBOX_CHECKMARK_OFFSET_X,
        CHECKBOX_CHECKMARK_OFFSET_Y
    )
    disabledCheckedTexture:SetAtlas(CHECKBOX_CHECKMARK_ATLAS, true)
    disabledCheckedTexture:SetScale(CHECKBOX_CHECKMARK_SCALE)
    disabledCheckedTexture:SetDesaturated(true)
    disabledCheckedTexture:SetVertexColor(
        GRAY_FONT_COLOR.r,
        GRAY_FONT_COLOR.g,
        GRAY_FONT_COLOR.b
    )
    checkbox:SetDisabledCheckedTexture(disabledCheckedTexture)
    checkbox:SetMotionScriptsWhileDisabled(true)

    if label then
        local text = Controls.CreateText(
            parent,
            GameFontHighlight,
            label,
            math.max(
                (width or 220) - CHECKBOX_SIZE - CHECKBOX_LABEL_GAP,
                1
            )
        )

        text:SetPoint(
            "LEFT",
            checkbox,
            "RIGHT",
            CHECKBOX_LABEL_GAP,
            0
        )
        text:SetJustifyV("MIDDLE")
        checkbox.label = text

        if width and width > CHECKBOX_SIZE then
            checkbox:SetHitRectInsets(0, CHECKBOX_SIZE - width, 0, 0)
        end
    end

    Controls.SetTooltip(checkbox, tooltip)
    checkbox.enabledTooltipText = tooltip
    checkbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked() == true

        PlaySound(
            checked
                and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
                or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
        )

        onChanged(checked)
    end)

    function checkbox:SetControlEnabled(enabled)
        self:SetEnabled(enabled)

        if self.label then
            self.label:SetTextColor(
                enabled and HIGHLIGHT_FONT_COLOR.r or GRAY_FONT_COLOR.r,
                enabled and HIGHLIGHT_FONT_COLOR.g or GRAY_FONT_COLOR.g,
                enabled and HIGHLIGHT_FONT_COLOR.b or GRAY_FONT_COLOR.b
            )
        end
    end

    return checkbox
end

function Controls.CreateSlider(parent, options)
    local control = CreateFrame("Frame", nil, parent)
    local controlWidth = options.width or 270
    local inputAtlas = "common-button-tertiary-depressed-normal"
    local inputAtlasInfo = C_Texture.GetAtlasInfo(inputAtlas)
    local inputWidth = options.inputWidth or 60
    local inputHeight = options.inputHeight or inputAtlasInfo.height
    local inputGap = options.inputGap or 0
    local sliderWidth = controlWidth - inputWidth - inputGap - 2

    control:SetSize(controlWidth, 60)

    local label = Controls.CreateText(
        control,
        GameFontHighlight,
        options.label,
        controlWidth - 10
    )
    label:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)

    local slider = CreateFrame(
        "Frame",
        nil,
        control,
        "MinimalSliderWithSteppersTemplate"
    )
    slider:SetWidth(sliderWidth)
    slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, 2)

    local valueBox = CreateFrame(
        "EditBox",
        nil,
        control,
        "InputBoxScriptTemplate"
    )
    valueBox:SetSize(inputWidth, inputHeight)
    valueBox:SetPoint("LEFT", slider, "RIGHT", inputGap, 0)
    valueBox:SetAutoFocus(false)
    valueBox:SetFontObject(GameFontHighlight)
    valueBox:SetMaxLetters(options.maxLetters or 5)
    valueBox:SetJustifyH("CENTER")
    valueBox:SetJustifyV("MIDDLE")
    valueBox:SetTextInsets(4, 4, 0, 0)

    local valueBoxBackground = valueBox:CreateTexture(nil, "BACKGROUND")

    valueBoxBackground:SetAllPoints(valueBox)
    valueBoxBackground:SetAtlas(inputAtlas, false)

    local steps = (options.maxValue - options.minValue) / options.step

    slider:Init(
        options.value,
        options.minValue,
        options.maxValue,
        steps,
        nil
    )

    local function normalizeValue(value)
        local clamped = math.max(
            options.minValue,
            math.min(options.maxValue, value)
        )
        local stepIndex = math.floor(
            ((clamped - options.minValue) / options.step) + 0.5
        )

        return options.minValue + (stepIndex * options.step)
    end

    local function formatInputValue(value)
        local text

        if options.inputFormatter then
            text = options.inputFormatter(value)
        else
            text = tostring(value)
        end

        return text .. (options.suffix or "")
    end

    local function syncValueBox(value)
        valueBox:SetText(formatInputValue(value))
        valueBox:SetCursorPosition(0)
    end

    local function getInputValue()
        local numericText = valueBox:GetText():match(
            "^%s*([+-]?%d*%.?%d+)"
        )

        return numericText and tonumber(numericText) or nil
    end

    control.callbackHandles = EventUtil.CreateCallbackHandleContainer()
    control.callbackHandles:RegisterCallback(
        slider,
        MinimalSliderWithSteppersMixin.Event.OnValueChanged,
        function(_, value)
            control.currentValue = value
            syncValueBox(value)

            if not control.syncing then
                options.onChanged(value)
            end
        end
    )

    local function finalizeInput()
        local value = getInputValue()

        if not value then
            syncValueBox(control.currentValue)
            return
        end

        local normalized = normalizeValue(value)

        slider:SetValue(normalized)
        control.currentValue = normalized
        syncValueBox(normalized)
    end

    valueBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    valueBox:SetScript("OnEscapePressed", EditBox_ClearFocus)
    valueBox:SetScript("OnEditFocusGained", EditBox_HighlightText)
    valueBox:SetScript("OnEditFocusLost", function(self)
        EditBox_ClearHighlight(self)
        finalizeInput()
    end)
    if options.tooltip then
        control.enabledTooltipText = options.tooltip
        control.tooltipText = options.tooltip
        control:EnableMouse(true)

        local function showTooltip(owner)
            if not control.tooltipText then return end

            GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
            GameTooltip:AddLine(options.label, 1, 1, 1)
            GameTooltip:AddLine(
                control.tooltipText,
                nil,
                nil,
                nil,
                true
            )
            GameTooltip:Show()
        end

        local function hideTooltip()
            GameTooltip:Hide()
        end

        slider.Slider:HookScript("OnEnter", showTooltip)
        slider.Slider:HookScript("OnLeave", hideTooltip)
        valueBox:HookScript("OnEnter", showTooltip)
        valueBox:HookScript("OnLeave", hideTooltip)
        control:HookScript("OnEnter", showTooltip)
        control:HookScript("OnLeave", hideTooltip)
    end

    function control:SetValue(value)
        local normalized = normalizeValue(value)

        self.currentValue = normalized
        self.syncing = true
        slider:SetValue(normalized)
        syncValueBox(normalized)
        self.syncing = false
    end

    function control:SetControlEnabled(enabled)
        slider:SetEnabled(enabled)
        valueBox:SetEnabled(enabled)
        valueBox:SetTextColor(
            enabled and HIGHLIGHT_FONT_COLOR.r or GRAY_FONT_COLOR.r,
            enabled and HIGHLIGHT_FONT_COLOR.g or GRAY_FONT_COLOR.g,
            enabled and HIGHLIGHT_FONT_COLOR.b or GRAY_FONT_COLOR.b
        )
        label:SetTextColor(
            enabled and HIGHLIGHT_FONT_COLOR.r or GRAY_FONT_COLOR.r,
            enabled and HIGHLIGHT_FONT_COLOR.g or GRAY_FONT_COLOR.g,
            enabled and HIGHLIGHT_FONT_COLOR.b or GRAY_FONT_COLOR.b
        )
    end

    control.label = label
    control.slider = slider
    control.valueBox = valueBox

    control:SetValue(options.value)

    return control
end

local function createTertiaryButton(parent, text, width, height, onClick,
                                    atlases, fonts)
    local button = CreateFrame("Button", nil, parent)

    button:SetSize(width or 100, height or 22)
    button:SetMotionScriptsWhileDisabled(true)
    button:SetNormalFontObject(fonts.normal)
    button:SetHighlightFontObject(fonts.highlight)
    button:SetDisabledFontObject(fonts.disabled)
    button:SetNormalTexture(createButtonState(
        button,
        "BACKGROUND",
        atlases.normal
    ))
    button:SetHighlightTexture(createButtonState(
        button,
        "HIGHLIGHT",
        atlases.hover
    ))
    button:SetPushedTexture(createButtonState(
        button,
        "BACKGROUND",
        atlases.pressed
    ))
    button:SetDisabledTexture(createButtonState(
        button,
        "BACKGROUND",
        atlases.disabled
    ))
    button:SetText(text)

    if onClick then
        button:SetScript("OnClick", onClick)
    end

    return button
end

function Controls.CreateTertiaryButton(parent, text, width, height, onClick)
    return createTertiaryButton(
        parent,
        text,
        width,
        height,
        onClick,
        TERTIARY_BUTTON_ATLASES.regular,
        {
            normal = GameFontNormal,
            highlight = GameFontHighlight,
            disabled = GameFontDisable,
        }
    )
end

function Controls.CreateSmallTertiaryButton(parent, text, width, height,
                                             onClick)
    return createTertiaryButton(
        parent,
        text,
        width,
        height,
        onClick,
        TERTIARY_BUTTON_ATLASES.small,
        {
            normal = GameFontNormalSmall,
            highlight = GameFontHighlightSmall,
            disabled = GameFontDisableSmall,
        }
    )
end
