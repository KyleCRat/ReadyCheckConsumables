local _, RCC = ...

RCC.RaidFrameSettings = RCC.RaidFrameSettings or {}

local Page = RCC.RaidFrameSettings
local Controls = LibStub("LibModernSettings-1.0")

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

local function setControlState(control, enabled, disabledTooltip)
    control:SetControlEnabled(enabled, disabledTooltip)
end

local function addSettingCheckbox(frame, flow, options, placement)
    local checkbox = flow:AddControl("checkbox", {
        label = options.label,
        tooltip = options.tooltip,
        onChanged = function(checked)
            RCC.SetSettingValue(options.key, checked)

            if options.onChanged then
                options.onChanged(checked)
            end

            frame:Sync()
        end,
    }, placement)
    frame.settingControls[options.key] = checkbox

    return checkbox
end

local function addSettingSlider(frame, flow, options, placement)
    local controlOptions = {}

    for key, value in pairs(options) do
        controlOptions[key] = value
    end

    controlOptions.value = RCC.GetSetting(options.key)
    controlOptions.onChanged = function(value)
        RCC.SetSettingValue(controlOptions.key, value)

        if controlOptions.afterChanged then
            controlOptions.afterChanged(value)
        end
    end

    local slider = flow:AddControl("slider", controlOptions, placement)

    frame.settingControls[options.key] = slider

    return slider
end

function Page.CreateFrame(measurementFrame)
    local frame = CreateFrame("Frame")

    frame.settingControls = {}

    local layout = Controls:CreateCanvasLayout(frame, {
        measurementFrame = measurementFrame,
    })
    local root = layout:GetRootFlow()

    layout:AddHeader(
        "Raid Frame",
        "Configure the group consumable status frame shown during "
            .. "ready checks and provision events."
    )
    addSettingCheckbox(frame, root, {
        key = "raidFrame_enabled",
        label = "Enabled",
        tooltip = "Enable the group consumable status frame.",
        onChanged = function()
            RCC.raidFrame:RefreshContextualVisibility()
        end,
    })

    local columns = root:BeginColumns()
    local left = columns.left
    local right = columns.right

    left:AddSection("Display")

    addSettingSlider(frame, left, {
        key = "raidFrame_scale",
        label = "Scale",
        tooltip = "Scale the Raid Frame.",
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
        afterChanged = function()
            RCC.raidFrame:SyncScaleControl()
        end,
    })

    left:AddSection("Ready Check")

    addSettingCheckbox(frame, left, {
        key = "raidFrame_minShow",
        label = "Keep Open After Finished",
        tooltip = "Keep the Raid Frame open briefly after a ready check "
            .. "finishes.",
    })

    addSettingSlider(frame, left, {
        key = "raidFrame_minShowTime",
        label = "Keep Open Duration",
        tooltip = "How long the Raid Frame remains open after a ready "
            .. "check finishes.",
        minValue = 1,
        maxValue = 40,
        step = 1,
        inputFormatter = function(value)
            return string.format("%d", value)
        end,
        suffix = "s",
    }, {
        indent = 1,
    })

    right:AddSection("Feasts & Cauldrons")

    addSettingCheckbox(frame, right, {
        key = "raidFrameCauldron_enabled",
        label = "Track Feasts and Cauldrons",
        tooltip = "Track feast drops and flask or potion pickups from "
            .. "cauldrons.",
        onChanged = function()
            RCC.RaidFrameCauldron.Refresh()
        end,
    })

    addSettingCheckbox(frame, right, {
        key = "raidFrameCauldron_showOutsideReadyCheck",
        label = "Show Outside Ready Checks",
        tooltip = "Show the relevant food and cauldron columns when a "
            .. "feast or cauldron is detected outside ready checks.",
        onChanged = function()
            RCC.RaidFrameCauldron.Refresh()
        end,
    }, {
        indent = 1,
    })

    columns:Finish()
    layout:Finalize()
    frame.layout = layout

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
