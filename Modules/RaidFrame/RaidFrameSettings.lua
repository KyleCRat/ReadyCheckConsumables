local _, RCC = ...

RCC.RaidFrameSettings = RCC.RaidFrameSettings or {}

local Page = RCC.RaidFrameSettings
local Controls = LibStub("LibModernSettings-1.0")
local Layout = RCC.SettingsLayout

local FEATURE_DISABLED_TOOLTIP =
    "The Raid Frame is disabled. Enable it to edit."
local KEEP_OPEN_DISABLED_TOOLTIP =
    "Keep Open After Finished is disabled."
local PROVISION_TRACKING_DISABLED_TOOLTIP =
    "Feast and cauldron tracking is disabled."

local SETTING_KEYS = {
    "raidFrame_enabled",
    "raidFrame_scale",
    "raidFrame_minShow",
    "raidFrame_minShowTime",
    "raidFrameCauldron_enabled",
    "raidFrameCauldron_showOutsideReadyCheck",
}

local function createSectionHeader(parent, text, x, y)
    local header = Controls:CreateText(parent, {
        fontObject = GameFontNormal,
        text = text,
        width = Layout.COLUMN_WIDTH,
    })

    header:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    return header
end

local function setControlState(control, enabled, disabledTooltip)
    control:SetControlEnabled(enabled, disabledTooltip)
end

local function addSettingCheckbox(frame, parent, options)
    local checkbox = Controls:CreateCheckbox(parent, {
        label = options.label,
        width = options.width or Layout.COLUMN_WIDTH,
        tooltip = options.tooltip,
        onChanged = function(checked)
            RCC.SetSettingValue(options.key, checked)

            if options.onChanged then
                options.onChanged(checked)
            end

            frame:Sync()
        end,
    })

    checkbox:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        options.x,
        options.y
    )
    frame.settingControls[options.key] = checkbox

    return checkbox
end

local function addSettingSlider(frame, parent, options)
    options.value = RCC.GetSetting(options.key)
    options.onChanged = function(value)
        RCC.SetSettingValue(options.key, value)

        if options.afterChanged then
            options.afterChanged(value)
        end
    end

    local slider = Controls:CreateSlider(parent, options)

    slider:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        options.x,
        options.y
    )
    frame.settingControls[options.key] = slider

    return slider
end

function Page.CreateFrame()
    local frame = CreateFrame("Frame")

    frame:SetSize(Layout.CANVAS_WIDTH, Layout.CANVAS_HEIGHT)
    frame.settingControls = {}

    local content = Layout.CreateContentFrame(frame)

    local title = Controls:CreateText(content, {
        fontObject = GameFontNormalLarge,
        text = "Raid Frame",
        width = Layout.CONTENT_WIDTH,
    })
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -8)

    local description = Controls:CreateText(content, {
        fontObject = GameFontHighlight,
        text = "Configure the group consumable status frame shown during "
            .. "ready checks and provision events.",
        width = Layout.CONTENT_WIDTH,
    })
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)

    addSettingCheckbox(frame, content, {
        key = "raidFrame_enabled",
        label = "Enabled",
        tooltip = "Enable the group consumable status frame.",
        x = 0,
        y = -76,
        onChanged = function()
            RCC.raidFrame:RefreshContextualVisibility()
        end,
    })

    createSectionHeader(content, "Display", 0, -124)

    addSettingSlider(frame, content, {
        key = "raidFrame_scale",
        label = "Scale",
        tooltip = "Scale the Raid Frame.",
        width = Layout.COLUMN_WIDTH,
        minValue = 0.5,
        maxValue = 1.5,
        step = 0.05,
        inputFormatter = function(value)
            return string.format("%d", math.floor(value * 100 + 0.5))
        end,
        inputParser = function(text)
            local numericText = text:match("^%s*([+-]?%d*%.?%d+)")

            return numericText and tonumber(numericText) / 100 or nil
        end,
        suffix = "%",
        x = 0,
        y = -150,
        afterChanged = function()
            RCC.raidFrame:SyncScaleControl()
        end,
    })

    createSectionHeader(content, "Ready Check", 0, -230)

    addSettingCheckbox(frame, content, {
        key = "raidFrame_minShow",
        label = "Keep Open After Finished",
        tooltip = "Keep the Raid Frame open briefly after a ready check "
            .. "finishes.",
        x = 0,
        y = -256,
    })

    addSettingSlider(frame, content, {
        key = "raidFrame_minShowTime",
        label = "Keep Open Duration",
        tooltip = "How long the Raid Frame remains open after a ready "
            .. "check finishes.",
        width = Layout.INDENTED_COLUMN_WIDTH,
        minValue = 1,
        maxValue = 40,
        step = 1,
        inputFormatter = function(value)
            return string.format("%d", value)
        end,
        suffix = "s",
        x = Layout.INDENT,
        y = -294,
    })

    createSectionHeader(
        content,
        "Feasts & Cauldrons",
        Layout.RIGHT_COLUMN_X,
        -124
    )

    addSettingCheckbox(frame, content, {
        key = "raidFrameCauldron_enabled",
        label = "Track Feasts and Cauldrons",
        tooltip = "Track feast drops and flask or potion pickups from "
            .. "cauldrons.",
        x = Layout.RIGHT_COLUMN_X,
        y = -150,
        onChanged = function()
            RCC.RaidFrameCauldron.Refresh()
        end,
    })

    addSettingCheckbox(frame, content, {
        key = "raidFrameCauldron_showOutsideReadyCheck",
        label = "Show Outside Ready Checks",
        tooltip = "Show the relevant food and cauldron columns when a "
            .. "feast or cauldron is detected outside ready checks.",
        width = Layout.INDENTED_COLUMN_WIDTH,
        x = Layout.RIGHT_COLUMN_X + Layout.INDENT,
        y = -188,
        onChanged = function()
            RCC.RaidFrameCauldron.Refresh()
        end,
    })

    function frame:Sync()
        for i = 1, #SETTING_KEYS do
            local key = SETTING_KEYS[i]
            local control = self.settingControls[key]

            control:SetValue(RCC.GetSetting(key))
        end

        local enabled = RCC.GetSetting("raidFrame_enabled") == true
        local keepOpen = RCC.GetSetting("raidFrame_minShow") == true
        local trackProvisions =
            RCC.GetSetting("raidFrameCauldron_enabled") == true

        setControlState(
            self.settingControls.raidFrame_scale,
            enabled,
            FEATURE_DISABLED_TOOLTIP
        )
        setControlState(
            self.settingControls.raidFrame_minShow,
            enabled,
            FEATURE_DISABLED_TOOLTIP
        )
        setControlState(
            self.settingControls.raidFrame_minShowTime,
            enabled and keepOpen,
            not enabled
                and FEATURE_DISABLED_TOOLTIP
                or KEEP_OPEN_DISABLED_TOOLTIP
        )
        setControlState(
            self.settingControls.raidFrameCauldron_enabled,
            enabled,
            FEATURE_DISABLED_TOOLTIP
        )
        setControlState(
            self.settingControls.raidFrameCauldron_showOutsideReadyCheck,
            enabled and trackProvisions,
            not enabled
                and FEATURE_DISABLED_TOOLTIP
                or PROVISION_TRACKING_DISABLED_TOOLTIP
        )
    end

    frame:SetScript("OnShow", function(self)
        self:Sync()
    end)
    frame:Sync()

    return frame
end
