local _, RCC = ...

RCC.ConsumableFrameSettings = RCC.ConsumableFrameSettings or {}

local Page = RCC.ConsumableFrameSettings
local Buttons = RCC.ConsumableFrameButtons
local Controls = LibStub("LibModernSettings-1.0")
local Visibility = RCC.ContextualVisibility
local Reason = RCC.DisplayReason
local Surface = RCC.DisplaySurface.CONSUMABLE_FRAME

local MATRIX_ROW_HEIGHT = 36
local FEATURE_DISABLED_TOOLTIP =
    "The Consumables Frame is disabled. Enable it to edit."
local KEEP_OPEN_DISABLED_TOOLTIP =
    "Keep Open After Ready Response is disabled."
local INSTANCE_OPEN_DISABLED_TOOLTIP =
    "Open When Entering an Instance is disabled."
local INSTANCE_HIDE_DISABLED_TOOLTIP =
    "Auto-Hide After Instance Entry is disabled."

local OPEN_EVENTS = {
    {
        reason = Reason.READY_CHECK,
        label = "Ready\nCheck",
        tooltip = "Show %s when a ready check opens the frame.",
    },
    {
        reason = Reason.INSTANCE_ENTRY,
        label = "Instance\nEntry",
        tooltip = "Show %s when entering an enabled instance type.",
    },
    {
        reason = Reason.CAULDRON_PICKUP,
        label = "Cauldron\nPickup",
        tooltip = "Show %s after collecting a consumable from a cauldron.",
    },
    {
        reason = Reason.BREAK_TIMER,
        label = "Break\nTimer",
        tooltip = "Show %s when BigWigs or DBM starts a break timer.",
    },
}

local CONSUMABLE_SETTING_KEYS = {
    "consumables_enabled",
    "consumables_scale",
    "consumables_minShow",
    "consumables_minShowTime",
    "consumables_cauldronOpen",
    "consumables_breakOpen",
    "consumables_instanceOpen",
    "consumables_instanceOpenParty",
    "consumables_instanceOpenRaid",
    "consumables_instanceOpenScenario",
    "consumables_instanceOpenPvp",
    "consumables_instanceOpenArena",
    "consumables_instanceHide",
    "consumables_instanceHideTime",
    "consumables_preferUnlimitedAugment",
    "icon_food",
    "icon_flask",
    "icon_mhTempWeaponEnchant",
    "icon_ohTempWeaponEnchant",
    "icon_healthstone",
    "icon_combatPotion",
    "icon_healPotion",
    "icon_consumableStasis",
    "icon_recuperate",
    "icon_augment",
    "icon_raidBuff",
    "icon_vantus",
}

function Page.GetOpenEvents()
    return OPEN_EVENTS
end

function Page.GetMatrixValue(definition, reason)
    local defaultValue = Visibility.GetReasonDefault(definition, reason)

    return RCC.GetContextualVisibility(
        Surface,
        definition.key,
        reason,
        defaultValue
    )
end

function Page.SetMatrixValue(definition, reason, value)
    local defaultValue = Visibility.GetReasonDefault(definition, reason)
    local enabled = value == true
    local override = enabled == defaultValue and nil or enabled

    return RCC.SetContextualVisibilityOverride(
        Surface,
        definition.key,
        reason,
        override
    )
end

local function refreshConsumableFrame()
    if InCombatLockdown() or not RCC.consumables:IsShown() then
        return
    end

    RCC.consumables:Update()
end

local function refreshAugmentRuneSelection()
    refreshConsumableFrame()
    RCC.ConsumableMacros.ScheduleUpdate()
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

local function createGeneralSettings(frame, layout)
    local root = layout:GetRootFlow()

    addSettingCheckbox(frame, root, {
        key = "consumables_enabled",
        label = "Enabled",
        tooltip = "Enable the personal Consumables Frame.",
        onChanged = function(enabled)
            if not enabled and not InCombatLockdown() then
                RCC.consumables:Hide()
            end
        end,
    })

    local columns = root:BeginColumns()
    local displayFlow = columns.left
    local eventsFlow = columns.right

    displayFlow:AddSection("Display")
    eventsFlow:AddSection("Automatic Open Events")

    addSettingSlider(frame, displayFlow, {
        key = "consumables_scale",
        label = "Scale",
        tooltip = "Scale the personal Consumables Frame.",
        minValue = 0.5,
        maxValue = 2.0,
        step = 0.1,
        inputFormatter = function(value)
            return string.format("%.1f", value)
        end,
        afterChanged = function(value)
            RCC.consumables:SetScale(value)
        end,
    })

    addSettingCheckbox(frame, displayFlow, {
        key = "consumables_minShow",
        label = "Keep Open After Ready Response",
        tooltip = "Keep the frame open briefly after you answer a ready check.",
    })

    addSettingSlider(frame, displayFlow, {
        key = "consumables_minShowTime",
        label = "Ready Check Duration",
        tooltip = "How long the frame remains open after your ready-check response.",
        minValue = 1,
        maxValue = 40,
        step = 1,
        inputFormatter = function(value)
            return string.format("%d", value)
        end,
        suffix = "s",
    })

    displayFlow:AddSection("Augment Runes")

    addSettingCheckbox(frame, displayFlow, {
        key = "consumables_preferUnlimitedAugment",
        label = "Prefer Unlimited Augment Runes",
        tooltip = "Use unlimited augment runes before consumable runes from newer expansions.",
        onChanged = refreshAugmentRuneSelection,
    })

    addSettingCheckbox(frame, eventsFlow, {
        key = "consumables_cauldronOpen",
        label = "Open After Cauldron Pickup",
        tooltip = "Open after collecting a known flask or potion from a cauldron.",
    })

    addSettingCheckbox(frame, eventsFlow, {
        key = "consumables_breakOpen",
        label = "Open on Break Timer",
        tooltip = "Open when BigWigs or DBM starts a break timer.",
    })

    addSettingCheckbox(frame, eventsFlow, {
        key = "consumables_instanceOpen",
        label = "Open When Entering an Instance",
        tooltip = "Open when entering one of the selected instance types.",
    })

    local instanceTypes = {
        left = {
            {
                key = "consumables_instanceOpenParty",
                label = "Dungeons",
                tooltip = "Open when entering a dungeon instance.",
            },
            {
                key = "consumables_instanceOpenScenario",
                label = "Scenarios",
                tooltip = "Open when entering a scenario instance.",
            },
            {
                key = "consumables_instanceOpenArena",
                label = "Arenas",
                tooltip = "Open when entering an arena instance.",
            },
        },
        right = {
            {
                key = "consumables_instanceOpenRaid",
                label = "Raids",
                tooltip = "Open when entering a raid instance.",
            },
            {
                key = "consumables_instanceOpenPvp",
                label = "Battlegrounds",
                tooltip = "Open when entering a battleground instance.",
            },
        },
    }

    local instanceColumns = eventsFlow:BeginColumns({
        indent = 1,
        columnGap = layout:GetStyleValue("nestedColumnGap"),
    })

    for i = 1, #instanceTypes.left do
        local option = instanceTypes.left[i]
        local control = addSettingCheckbox(
            frame,
            instanceColumns.left,
            option
        )

        frame.instanceTypeControls[#frame.instanceTypeControls + 1] = control
    end

    for i = 1, #instanceTypes.right do
        local option = instanceTypes.right[i]
        local control = addSettingCheckbox(
            frame,
            instanceColumns.right,
            option
        )

        frame.instanceTypeControls[#frame.instanceTypeControls + 1] = control
    end

    instanceColumns:Finish()

    addSettingCheckbox(frame, eventsFlow, {
        key = "consumables_instanceHide",
        label = "Auto-Hide After Instance Entry",
        tooltip = "Hide the frame automatically after its instance-entry delay.",
    })

    addSettingSlider(frame, eventsFlow, {
        key = "consumables_instanceHideTime",
        label = "Instance Auto-Hide Delay",
        tooltip = "How long the frame remains open after entering an instance.",
        minValue = 5,
        maxValue = 120,
        step = 5,
        inputFormatter = function(value)
            return string.format("%d", value)
        end,
        suffix = "s",
    }, {
        indent = 1,
    })

    columns:Finish()
end

local function createVisibilityMatrix(frame, layout)
    local content = layout:GetContent()
    local flow = layout:GetRootFlow()
    local heading = flow:AddCustom(30, {
        marginTop = 14,
        marginBottom = 2,
    })
    local matrixTitle = Controls:CreateText(heading, {
        fontObject = GameFontNormal,
        text = "Buttons by Open Event",
        width = 220,
        height = 30,
        justifyV = "MIDDLE",
    })

    matrixTitle:SetPoint("LEFT", heading, "LEFT", 0, 0)

    local resetButton = Controls:CreateButton(heading, {
        text = "Reset Matrix",
        width = 112,
        height = 30,
        tooltip = "Restore every button and open-event combination to its "
            .. "addon default.",
        onClick = function()
            RCC.ClearContextualVisibilityOverrides(Surface)
            frame:Sync()
        end,
    })
    resetButton:SetPoint("RIGHT", heading, "RIGHT", 0, 0)
    frame.resetMatrixButton = resetButton

    flow:AddText({
        fontObject = GameFontHighlightSmall,
        text = "Enabled is the global switch for a button. Event columns "
            .. "choose which enabled buttons each type of frame opening "
            .. "displays.",
    }, {
        marginBottom = 8,
    })

    local columns = {
        { key = "button", width = 160, justifyH = "LEFT" },
        { key = "enabled", width = 67 },
    }

    for eventIndex = 1, #OPEN_EVENTS do
        columns[#columns + 1] = {
            key = "event" .. eventIndex,
            weight = 1,
        }
    end

    local matrix = Controls:CreateSettingsTable(content, {
        width = flow:GetWidth(),
        padding = layout:GetStyleValue("tablePadding"),
        headerHeight = 42,
        rowHeight = MATRIX_ROW_HEIGHT,
        columns = columns,
    })

    matrix:AddHeaderText("button", "Button")
    matrix:AddHeaderText("enabled", "Enabled")

    for eventIndex = 1, #OPEN_EVENTS do
        matrix:AddHeaderText(
            "event" .. eventIndex,
            OPEN_EVENTS[eventIndex].label
        )
    end

    local definitions = Buttons.GetDefinitions()

    for definitionIndex = 1, #definitions do
        local definition = definitions[definitionIndex]
        local row = matrix:AddRow()
        local rowLabel = row:AddText("button", definition.label)

        frame.matrixRowLabels[#frame.matrixRowLabels + 1] = rowLabel

        if definition.settingsTooltip then
            Controls:SetTooltip(
                row:GetCell("button"),
                definition.settingsTooltip
            )
        end

        local enabledTooltip = "Enable " .. definition.label
            .. " for the Consumables Frame."

        if definition.settingsTooltip then
            enabledTooltip = definition.settingsTooltip .. "\n\n"
                .. enabledTooltip
        end

        local enabledCheckbox = row:AddControl("enabled", "checkbox", {
            tooltip = enabledTooltip,
            onChanged = function(checked)
                RCC.SetSettingValue(definition.settingKey, checked)
                refreshConsumableFrame()
                frame:Sync()
            end,
        })
        frame.settingControls[definition.settingKey] = enabledCheckbox

        for eventIndex = 1, #OPEN_EVENTS do
            local event = OPEN_EVENTS[eventIndex]
            local enabledTooltip = string.format(
                event.tooltip,
                definition.label
            )
            local checkbox = row:AddControl(
                "event" .. eventIndex,
                "checkbox",
                {
                    tooltip = enabledTooltip,
                    onChanged = function(checked)
                        Page.SetMatrixValue(
                            definition,
                            event.reason,
                            checked
                        )
                        frame:Sync()
                    end,
                }
            )
            frame.matrixControls[#frame.matrixControls + 1] = {
                control = checkbox,
                definition = definition,
                reason = event.reason,
                disabledTooltip = definition.label .. " is disabled.",
            }
        end
    end

    flow:AddFrame(matrix:GetFrame(), {
        marginBottom = 12,
    })
    frame.visibilityMatrix = matrix
end

function Page.CreateFrame(measurementFrame)
    local frame = CreateFrame("Frame")

    frame.settingControls = {}
    frame.instanceTypeControls = {}
    frame.matrixControls = {}
    frame.matrixRowLabels = {}

    local layout = Controls:CreateCanvasLayout(frame, {
        measurementFrame = measurementFrame,
        scrollable = true,
    })

    layout:AddHeader(
        "Consumables Frame",
        "Choose when the personal consumable bar opens and which "
            .. "buttons appear for each open event. Open-event options start "
            .. "the frame; the matrix controls its contents."
    )

    createGeneralSettings(frame, layout)
    createVisibilityMatrix(frame, layout)
    layout:Finalize()
    frame.layout = layout
    frame.scrollBox = layout:GetScrollBox()

    function frame:Sync()
        local pageEnabled = RCC.GetSetting("consumables_enabled") == true

        for key, control in pairs(self.settingControls) do
            control:SetValue(RCC.GetSetting(key))

            if key ~= "consumables_enabled" then
                control:SetControlEnabled(
                    pageEnabled,
                    FEATURE_DISABLED_TOOLTIP
                )
            end
        end

        local minShowEnabled = RCC.GetSetting("consumables_minShow") == true
        local instanceOpen = RCC.GetSetting("consumables_instanceOpen") == true
        local instanceHide = RCC.GetSetting("consumables_instanceHide") == true

        self.settingControls.consumables_minShowTime:SetControlEnabled(
            pageEnabled and minShowEnabled,
            not pageEnabled
                and FEATURE_DISABLED_TOOLTIP
                or KEEP_OPEN_DISABLED_TOOLTIP
        )

        for i = 1, #self.instanceTypeControls do
            self.instanceTypeControls[i]:SetControlEnabled(
                pageEnabled and instanceOpen,
                not pageEnabled
                    and FEATURE_DISABLED_TOOLTIP
                    or INSTANCE_OPEN_DISABLED_TOOLTIP
            )
        end

        self.settingControls.consumables_instanceHide:SetControlEnabled(
            pageEnabled and instanceOpen,
            not pageEnabled
                and FEATURE_DISABLED_TOOLTIP
                or INSTANCE_OPEN_DISABLED_TOOLTIP
        )
        self.settingControls.consumables_instanceHideTime:SetControlEnabled(
            pageEnabled and instanceOpen and instanceHide,
            not pageEnabled
                and FEATURE_DISABLED_TOOLTIP
                or not instanceOpen
                    and INSTANCE_OPEN_DISABLED_TOOLTIP
                    or INSTANCE_HIDE_DISABLED_TOOLTIP
        )

        self.resetMatrixButton:SetControlEnabled(
            pageEnabled,
            FEATURE_DISABLED_TOOLTIP
        )

        for i = 1, #self.matrixRowLabels do
            local rowLabel = self.matrixRowLabels[i]
            local color = pageEnabled
                and HIGHLIGHT_FONT_COLOR
                or GRAY_FONT_COLOR

            rowLabel:SetTextColor(color.r, color.g, color.b)
        end

        for i = 1, #self.matrixControls do
            local entry = self.matrixControls[i]
            local globallyEnabled = RCC.GetSetting(
                entry.definition.settingKey
            ) == true

            entry.control:SetValue(Page.GetMatrixValue(
                entry.definition,
                entry.reason
            ))
            entry.control:SetControlEnabled(
                pageEnabled and globallyEnabled,
                not pageEnabled
                    and FEATURE_DISABLED_TOOLTIP
                    or entry.disabledTooltip
            )
        end
    end

    function frame:OnRefresh()
        self:Sync()
    end

    function frame:OnDefault()
        for i = 1, #CONSUMABLE_SETTING_KEYS do
            local key = CONSUMABLE_SETTING_KEYS[i]

            RCC.SetSettingValue(key, RCC.GetSettingDefault(key))
        end

        RCC.ClearContextualVisibilityOverrides(Surface)
        RCC.consumables:SetScale(RCC.GetSetting("consumables_scale"))
        refreshConsumableFrame()
        self:Sync()
    end

    frame:Sync()

    return frame
end
