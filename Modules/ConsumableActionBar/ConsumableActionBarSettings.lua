local _, RCC = ...

RCC.ConsumableActionBarSettings =
    RCC.ConsumableActionBarSettings or {}

local Page = RCC.ConsumableActionBarSettings
local ActionBar = RCC.ConsumableActionBar
local Catalog = RCC.ConsumableCatalog
local Controls = LibStub("LibModernSettings-1.0")
local Position = RCC.ConsumableActionBarPosition
local Shared = RCC.ConsumableSettingsShared

local FEATURE_DISABLED_TOOLTIP =
    "The Consumables Action Bar is disabled. Enable it to edit."

local ACTION_BAR_SETTING_KEYS = {
    "consumablesActionBar_enabled",
    "consumablesActionBar_iconsPerRow",
    "consumablesActionBar_buttonWidth",
    "consumablesActionBar_buttonHeight",
    "consumablesActionBar_gapX",
    "consumablesActionBar_gapY",
    "consumablesActionBar_flyoutDirection",
    "consumablesActionBar_durationTextPosition",
    "consumablesActionBar_textSize",
    "consumablesActionBar_showStackCount",
    "consumablesActionBar_showDuration",
    "consumablesActionBar_showStatus",
    "consumablesActionBar_showProfessionQuality",
}

local POSITION_LIMIT = 4000
local ANCHOR_CHOICES = {
    { value = "TOPLEFT", label = "Top Left" },
    { value = "TOP", label = "Top" },
    { value = "TOPRIGHT", label = "Top Right" },
    { value = "LEFT", label = "Left" },
    { value = "CENTER", label = "Center" },
    { value = "RIGHT", label = "Right" },
    { value = "BOTTOMLEFT", label = "Bottom Left" },
    { value = "BOTTOM", label = "Bottom" },
    { value = "BOTTOMRIGHT", label = "Bottom Right" },
}

local FLYOUT_DIRECTION_CHOICES = {
    { value = "UP", label = "Up" },
    { value = "DOWN", label = "Down" },
    { value = "LEFT", label = "Left" },
    { value = "RIGHT", label = "Right" },
}

local DURATION_TEXT_POSITION_CHOICES = {
    { value = "TOP", label = "Top" },
    { value = "BOTTOM", label = "Bottom" },
    { value = "LEFT", label = "Left" },
    { value = "RIGHT", label = "Right" },
}

local definitions = Catalog.GetDefinitions()

for i = 1, #definitions do
    ACTION_BAR_SETTING_KEYS[#ACTION_BAR_SETTING_KEYS + 1] =
        definitions[i].actionBarSettingKey
end

local function refreshLayout()
    ActionBar.RequestLayout()
end

local function refreshVisualOptions()
    ActionBar.RequestVisualOptions()
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
    local slider = flow:AddControl("slider", {
        label = options.label,
        tooltip = options.tooltip,
        value = RCC.GetSetting(options.key),
        minValue = options.minValue,
        maxValue = options.maxValue,
        step = options.step,
        inputFormatter = options.inputFormatter,
        onChanged = function(value)
            RCC.SetSettingValue(options.key, value)
            options.onChanged()
        end,
    }, placement)

    frame.settingControls[options.key] = slider

    return slider
end

local function addSettingDropdown(frame, flow, options, placement)
    local dropdown = flow:AddControl("dropdown", {
        label = options.label,
        tooltip = options.tooltip,
        value = RCC.GetSetting(options.key),
        choices = options.choices,
        onChanged = function(value)
            RCC.SetSettingValue(options.key, value)
            options.onChanged()
        end,
    }, placement)

    frame.settingControls[options.key] = dropdown

    return dropdown
end

local function addPositionSlider(frame, flow, options, placement)
    local position = Position.GetCurrent()
    local slider = flow:AddControl("slider", {
        label = options.label,
        tooltip = options.tooltip,
        value = position[options.field],
        minValue = -POSITION_LIMIT,
        maxValue = POSITION_LIMIT,
        step = 1,
        inputFormatter = function(value)
            return string.format("%d", value)
        end,
        onChanged = function(value)
            Position.SetCurrent({
                [options.field] = value,
            })
        end,
    }, placement)

    frame.positionControls[options.field] = slider

    return slider
end

local function addPositionDropdown(frame, flow, options, placement)
    local position = Position.GetCurrent()
    local dropdown = flow:AddControl("dropdown", {
        label = options.label,
        tooltip = options.tooltip,
        value = position[options.field],
        choices = ANCHOR_CHOICES,
        onChanged = function(value)
            Position.SetCurrent({
                [options.field] = value,
            })
        end,
    }, placement)

    frame.positionControls[options.field] = dropdown

    return dropdown
end

local function createGeneralSettings(frame, layout)
    local root = layout:GetRootFlow()

    local columns = root:BeginColumns()
    local featureFlow = columns.left
    local layoutFlow = columns.right

    featureFlow:AddSection("Action Bar")
    layoutFlow:AddSection("Wrapping")

    addSettingCheckbox(frame, featureFlow, {
        key = "consumablesActionBar_enabled",
        label = "Enabled",
        tooltip = "Show the permanent Consumables Action Bar.",
        onChanged = ActionBar.RequestVisibility,
    })

    addSettingSlider(frame, layoutFlow, {
        key = "consumablesActionBar_iconsPerRow",
        label = "Icons Per Row",
        tooltip = "Wrap enabled action-bar buttons after this many icons.",
        minValue = 1,
        maxValue = Catalog.GetCount(),
        step = 1,
        inputFormatter = function(value)
            return string.format("%d", value)
        end,
        onChanged = refreshLayout,
    })

    columns:Finish({
        marginBottom = 12,
    })

    root:AddSection("Button Appearance")

    columns = root:BeginColumns()

    addSettingSlider(frame, columns.left, {
        key = "consumablesActionBar_buttonWidth",
        label = "Button Width",
        tooltip = "Set the width of each action-bar button.",
        minValue = ActionBar.Limits.buttonWidth.min,
        maxValue = ActionBar.Limits.buttonWidth.max,
        step = 1,
        inputFormatter = function(value)
            return string.format("%d", value)
        end,
        onChanged = refreshLayout,
    })

    addSettingSlider(frame, columns.left, {
        key = "consumablesActionBar_buttonHeight",
        label = "Button Height",
        tooltip = "Set the height of each action-bar button.",
        minValue = ActionBar.Limits.buttonHeight.min,
        maxValue = ActionBar.Limits.buttonHeight.max,
        step = 1,
        inputFormatter = function(value)
            return string.format("%d", value)
        end,
        onChanged = refreshLayout,
    })

    addSettingSlider(frame, columns.right, {
        key = "consumablesActionBar_gapX",
        label = "Horizontal Gap",
        tooltip = "Set the horizontal space between action-bar buttons.",
        minValue = ActionBar.Limits.gapX.min,
        maxValue = ActionBar.Limits.gapX.max,
        step = 1,
        inputFormatter = function(value)
            return string.format("%d", value)
        end,
        onChanged = refreshLayout,
    })

    addSettingSlider(frame, columns.right, {
        key = "consumablesActionBar_gapY",
        label = "Vertical Gap",
        tooltip = "Set the vertical space between action-bar rows, including "
            .. "room for duration text.",
        minValue = ActionBar.Limits.gapY.min,
        maxValue = ActionBar.Limits.gapY.max,
        step = 1,
        inputFormatter = function(value)
            return string.format("%d", value)
        end,
        onChanged = refreshLayout,
    })

    addSettingSlider(frame, columns.left, {
        key = "consumablesActionBar_textSize",
        label = "Text Size",
        tooltip = "Set the size of duration and count text.",
        minValue = ActionBar.Limits.textSize.min,
        maxValue = ActionBar.Limits.textSize.max,
        step = 1,
        inputFormatter = function(value)
            return string.format("%d", value)
        end,
        onChanged = refreshLayout,
    })

    addSettingDropdown(frame, columns.right, {
        key = "consumablesActionBar_flyoutDirection",
        label = "Flyout Direction",
        tooltip = "Choose the direction flyout choices open.",
        choices = FLYOUT_DIRECTION_CHOICES,
        onChanged = refreshLayout,
    })

    addSettingDropdown(frame, columns.right, {
        key = "consumablesActionBar_durationTextPosition",
        label = "Duration Text Side",
        tooltip = "Choose which side of each icon shows duration text.",
        choices = DURATION_TEXT_POSITION_CHOICES,
        onChanged = refreshLayout,
    })

    columns:Finish({
        marginBottom = 12,
    })

    root:AddSection("Button Information")

    columns = root:BeginColumns()

    addSettingCheckbox(frame, columns.left, {
        key = "consumablesActionBar_showStackCount",
        label = "Show Stack Count",
        tooltip = "Show the available item count on applicable buttons.",
        onChanged = refreshVisualOptions,
    })

    addSettingCheckbox(frame, columns.left, {
        key = "consumablesActionBar_showDuration",
        label = "Show Duration",
        tooltip = "Show remaining consumable duration beside each button.",
        onChanged = refreshVisualOptions,
    })

    addSettingCheckbox(frame, columns.right, {
        key = "consumablesActionBar_showStatus",
        label = "Show Status Check / X",
        tooltip = "Show ready and missing status icons over each button.",
        onChanged = refreshVisualOptions,
    })

    addSettingCheckbox(frame, columns.right, {
        key = "consumablesActionBar_showProfessionQuality",
        label = "Show Profession Quality",
        tooltip = "Show profession quality marks on applicable consumables.",
        onChanged = refreshVisualOptions,
    })

    columns:Finish({
        marginBottom = 12,
    })

    root:AddSection("Position")

    columns = root:BeginColumns()

    addPositionDropdown(frame, columns.left, {
        field = "point",
        label = "Anchor From",
        tooltip = "Choose the anchor point on the action bar.",
    })

    addPositionDropdown(frame, columns.right, {
        field = "relPoint",
        label = "Anchor To",
        tooltip = "Choose the anchor point on the game UI.",
    })

    columns:Finish()

    columns = root:BeginColumns()

    addPositionSlider(frame, columns.left, {
        field = "x",
        label = "X Position",
        tooltip = "Set the horizontal offset from the selected anchors.",
    })

    addPositionSlider(frame, columns.right, {
        field = "y",
        label = "Y Position",
        tooltip = "Set the vertical offset from the selected anchors.",
    })

    columns:Finish({
        marginBottom = 12,
    })
end

local function addButtonCheckbox(frame, flow, definition)
    local settingKey = definition.actionBarSettingKey
    local checkbox = flow:AddControl("checkbox", {
        label = definition.label,
        tooltip = "Show " .. definition.label
            .. " on the Consumables Action Bar.",
        onChanged = function(checked)
            RCC.SetSettingValue(settingKey, checked)
            refreshLayout()
            frame:Sync()
        end,
    })

    frame.buttonControls[#frame.buttonControls + 1] = {
        control = checkbox,
        settingKey = settingKey,
    }
end

local function createButtonSettings(frame, layout)
    local flow = layout:GetRootFlow()

    flow:AddSection("Buttons")
    flow:AddText({
        fontObject = GameFontHighlightSmall,
        text = "Enabled buttons keep fixed slots. A button that is not "
            .. "currently applicable or available remains visible in its "
            .. "disabled state.",
    }, {
        marginBottom = 8,
    })

    local columns = flow:BeginColumns()
    local splitIndex = math.ceil(#definitions / 2)

    for i = 1, #definitions do
        local column = i <= splitIndex and columns.left or columns.right

        addButtonCheckbox(frame, column, definitions[i])
    end

    columns:Finish({
        marginBottom = 12,
    })
end

function Page.CreateFrame(measurementFrame)
    local frame = CreateFrame("Frame")

    frame.settingControls = {}
    frame.positionControls = {}
    frame.buttonControls = {}

    local layout = Controls:CreateCanvasLayout(frame, {
        measurementFrame = measurementFrame,
        scrollable = true,
    })

    layout:AddHeader(
        "Consumables Action Bar",
        "Keep selected consumable actions visible at all times. Position the "
            .. "bar here, with EllesmereUI Unlock Mode when available, or "
            .. "with Blizzard Edit Mode otherwise. Prepared flyout choices "
            .. "remain usable in combat."
    )

    createGeneralSettings(frame, layout)
    createButtonSettings(frame, layout)
    layout:Finalize()
    frame.layout = layout
    frame.scrollBox = layout:GetScrollBox()

    function frame:Sync()
        local enabled = RCC.GetSetting(
            "consumablesActionBar_enabled"
        ) == true

        for key, control in pairs(self.settingControls) do
            control:SetValue(RCC.GetSetting(key))

            if key ~= "consumablesActionBar_enabled" then
                control:SetControlEnabled(
                    enabled,
                    FEATURE_DISABLED_TOOLTIP
                )
            end
        end

        local position = Position.GetCurrent()

        for field, control in pairs(self.positionControls) do
            control:SetValue(position[field])
            control:SetControlEnabled(
                enabled,
                FEATURE_DISABLED_TOOLTIP
            )
        end

        for i = 1, #self.buttonControls do
            local entry = self.buttonControls[i]

            entry.control:SetValue(RCC.GetSetting(entry.settingKey))
            entry.control:SetControlEnabled(
                enabled,
                FEATURE_DISABLED_TOOLTIP
            )
        end
    end

    function frame:OnRefresh()
        self:Sync()
    end

    function frame:OnDefault()
        for i = 1, #ACTION_BAR_SETTING_KEYS do
            local key = ACTION_BAR_SETTING_KEYS[i]

            RCC.SetSettingValue(key, RCC.GetSettingDefault(key))
        end

        Position.ResetCurrent()
        ActionBar.RequestApplySettings()
        Shared.SyncPages()
    end

    Shared.RegisterPage(frame)
    frame:Sync()

    return frame
end
