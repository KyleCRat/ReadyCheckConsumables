local _, RCC = ...

RCC.ConsumableFrameSettings = RCC.ConsumableFrameSettings or {}

local Page = RCC.ConsumableFrameSettings
local Buttons = RCC.ConsumableFrameButtons
local Controls = LibStub("LibModernSettings-1.0")
local Layout = RCC.SettingsLayout
local Visibility = RCC.ContextualVisibility
local Reason = RCC.DisplayReason
local Surface = RCC.DisplaySurface.CONSUMABLE_FRAME

local CONTENT_HEIGHT = 1040
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

local function createSectionHeader(parent, text, x, y)
    local header = Controls:CreateText(parent, {
        fontObject = GameFontNormal,
        text = text,
        width = Layout.COLUMN_WIDTH,
    })

    header:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    return header
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

local function createGeneralSettings(frame, content)
    addSettingCheckbox(frame, content, {
        key = "consumables_enabled",
        label = "Enabled",
        tooltip = "Enable the personal Consumables Frame.",
        x = 0,
        y = -76,
        onChanged = function(enabled)
            if not enabled and not InCombatLockdown() then
                RCC.consumables:Hide()
            end
        end,
    })

    createSectionHeader(content, "Display", 0, -118)
    createSectionHeader(
        content,
        "Automatic Open Events",
        Layout.RIGHT_COLUMN_X,
        -118
    )

    addSettingSlider(frame, content, {
        key = "consumables_scale",
        label = "Scale",
        tooltip = "Scale the personal Consumables Frame.",
        width = Layout.COLUMN_WIDTH,
        minValue = 0.5,
        maxValue = 2.0,
        step = 0.1,
        inputFormatter = function(value)
            return string.format("%.1f", value)
        end,
        x = 0,
        y = -144,
        afterChanged = function(value)
            RCC.consumables:SetScale(value)
        end,
    })

    addSettingCheckbox(frame, content, {
        key = "consumables_minShow",
        label = "Keep Open After Ready Response",
        tooltip = "Keep the frame open briefly after you answer a ready check.",
        x = 0,
        y = -202,
    })

    addSettingSlider(frame, content, {
        key = "consumables_minShowTime",
        label = "Ready Check Duration",
        tooltip = "How long the frame remains open after your ready-check response.",
        width = Layout.COLUMN_WIDTH,
        minValue = 1,
        maxValue = 40,
        step = 1,
        inputFormatter = function(value)
            return string.format("%d", value)
        end,
        suffix = "s",
        x = 0,
        y = -240,
    })

    createSectionHeader(content, "Augment Runes", 0, -299)

    addSettingCheckbox(frame, content, {
        key = "consumables_preferUnlimitedAugment",
        label = "Prefer Unlimited Augment Runes",
        tooltip = "Use unlimited augment runes before consumable runes from newer expansions.",
        x = 0,
        y = -321,
        onChanged = refreshConsumableFrame,
    })

    addSettingCheckbox(frame, content, {
        key = "consumables_cauldronOpen",
        label = "Open After Cauldron Pickup",
        tooltip = "Open after collecting a known flask or potion from a cauldron.",
        x = Layout.RIGHT_COLUMN_X,
        y = -144,
    })

    addSettingCheckbox(frame, content, {
        key = "consumables_breakOpen",
        label = "Open on Break Timer",
        tooltip = "Open when BigWigs or DBM starts a break timer.",
        x = Layout.RIGHT_COLUMN_X,
        y = -180,
    })

    addSettingCheckbox(frame, content, {
        key = "consumables_instanceOpen",
        label = "Open When Entering an Instance",
        tooltip = "Open when entering one of the selected instance types.",
        x = Layout.RIGHT_COLUMN_X,
        y = -216,
    })

    local instanceTypes = {
        {
            key = "consumables_instanceOpenParty",
            label = "Dungeons",
            tooltip = "Open when entering a dungeon instance.",
            x = Layout.RIGHT_COLUMN_X + Layout.INDENT,
            y = -252,
        },
        {
            key = "consumables_instanceOpenRaid",
            label = "Raids",
            tooltip = "Open when entering a raid instance.",
            x = Layout.RIGHT_COLUMN_X + Layout.INDENT
                + Layout.NESTED_COLUMN_WIDTH
                + Layout.NESTED_GAP,
            y = -252,
        },
        {
            key = "consumables_instanceOpenScenario",
            label = "Scenarios",
            tooltip = "Open when entering a scenario instance.",
            x = Layout.RIGHT_COLUMN_X + Layout.INDENT,
            y = -288,
        },
        {
            key = "consumables_instanceOpenPvp",
            label = "Battlegrounds",
            tooltip = "Open when entering a battleground instance.",
            x = Layout.RIGHT_COLUMN_X + Layout.INDENT
                + Layout.NESTED_COLUMN_WIDTH
                + Layout.NESTED_GAP,
            y = -288,
        },
        {
            key = "consumables_instanceOpenArena",
            label = "Arenas",
            tooltip = "Open when entering an arena instance.",
            x = Layout.RIGHT_COLUMN_X + Layout.INDENT,
            y = -324,
        },
    }

    for i = 1, #instanceTypes do
        local option = instanceTypes[i]

        option.width = Layout.NESTED_COLUMN_WIDTH
        addSettingCheckbox(frame, content, option)
        frame.instanceTypeControls[#frame.instanceTypeControls + 1] =
            frame.settingControls[option.key]
    end

    addSettingCheckbox(frame, content, {
        key = "consumables_instanceHide",
        label = "Auto-Hide After Instance Entry",
        tooltip = "Hide the frame automatically after its instance-entry delay.",
        x = Layout.RIGHT_COLUMN_X,
        y = -360,
    })

    addSettingSlider(frame, content, {
        key = "consumables_instanceHideTime",
        label = "Instance Auto-Hide Delay",
        tooltip = "How long the frame remains open after entering an instance.",
        width = Layout.INDENTED_COLUMN_WIDTH,
        minValue = 5,
        maxValue = 120,
        step = 5,
        inputFormatter = function(value)
            return string.format("%d", value)
        end,
        suffix = "s",
        x = Layout.RIGHT_COLUMN_X + Layout.INDENT,
        y = -396,
    })
end

local function createMatrixHeader(content, text, x, y, width)
    local header = Controls:CreateText(content, {
        fontObject = GameFontNormalSmall,
        text = text,
        width = width,
    })

    header:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
    header:SetJustifyH("CENTER")
    header:SetJustifyV("MIDDLE")

    return header
end

local function createVisibilityMatrix(frame, content)
    local matrixTop = -464
    local matrixTitle = createSectionHeader(
        content,
        "Buttons by Open Event",
        0,
        matrixTop
    )
    matrixTitle:SetWidth(220)

    local resetButton = Controls:CreateButton(content, {
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
    resetButton:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, matrixTop + 5)
    frame.resetMatrixButton = resetButton

    local description = Controls:CreateText(content, {
        fontObject = GameFontHighlightSmall,
        text = "Enabled is the global switch for a button. Event columns "
            .. "choose which enabled buttons each type of frame opening "
            .. "displays.",
        width = Layout.CONTENT_WIDTH,
    })
    description:SetPoint("TOPLEFT", content, "TOPLEFT", 0, matrixTop - 32)

    local headerY = matrixTop - 66
    local matrixPadding = Layout.TABLE_PADDING
    local matrixLeft = matrixPadding
    local labelWidth = 160
    local enabledX = matrixLeft + labelWidth
    local enabledWidth = 67
    local eventStartX = enabledX + enabledWidth
    local eventWidth = (
        Layout.CONTENT_WIDTH - matrixPadding - eventStartX
    ) / #OPEN_EVENTS

    createMatrixHeader(
        content,
        "Button",
        matrixLeft,
        headerY,
        labelWidth
    ):SetJustifyH("LEFT")
    createMatrixHeader(
        content,
        "Enabled",
        enabledX,
        headerY,
        enabledWidth
    )

    for eventIndex = 1, #OPEN_EVENTS do
        local event = OPEN_EVENTS[eventIndex]
        local x = eventStartX + ((eventIndex - 1) * eventWidth)

        createMatrixHeader(content, event.label, x, headerY, eventWidth)
    end

    local definitions = Buttons.GetDefinitions()
    local firstRowY = headerY - 42

    for definitionIndex = 1, #definitions do
        local definition = definitions[definitionIndex]
        local rowY = firstRowY - ((definitionIndex - 1) * MATRIX_ROW_HEIGHT)

        if definitionIndex % 2 == 0 then
            local stripe = content:CreateTexture(nil, "BACKGROUND")

            stripe:SetColorTexture(1, 1, 1, 0.035)
            stripe:SetPoint("TOPLEFT", content, "TOPLEFT", 0, rowY)
            stripe:SetSize(Layout.CONTENT_WIDTH, MATRIX_ROW_HEIGHT)
        end

        local rowLabel = Controls:CreateText(content, {
            fontObject = GameFontHighlight,
            text = definition.label,
            width = labelWidth,
        })
        rowLabel:SetPoint(
            "LEFT",
            content,
            "TOPLEFT",
            matrixLeft,
            rowY - (MATRIX_ROW_HEIGHT / 2)
        )
        rowLabel:SetJustifyV("MIDDLE")
        frame.matrixRowLabels[#frame.matrixRowLabels + 1] = rowLabel

        if definition.settingsTooltip then
            local tooltipRegion = CreateFrame("Frame", nil, content)

            tooltipRegion:SetPoint(
                "TOPLEFT",
                content,
                "TOPLEFT",
                matrixLeft,
                rowY
            )
            tooltipRegion:SetSize(labelWidth, MATRIX_ROW_HEIGHT)
            tooltipRegion:EnableMouse(true)
            Controls:SetTooltip(tooltipRegion, definition.settingsTooltip)
        end

        local enabledTooltip = "Enable " .. definition.label
            .. " for the Consumables Frame."

        if definition.settingsTooltip then
            enabledTooltip = definition.settingsTooltip .. "\n\n"
                .. enabledTooltip
        end

        local enabledCheckbox = Controls:CreateCheckbox(content, {
            tooltip = enabledTooltip,
            onChanged = function(checked)
                RCC.SetSettingValue(definition.settingKey, checked)
                refreshConsumableFrame()
                frame:Sync()
            end,
        })
        enabledCheckbox:SetPoint(
            "TOPLEFT",
            content,
            "TOPLEFT",
            enabledX
                + ((eventStartX - enabledX - enabledCheckbox:GetWidth()) / 2),
            rowY - 1
        )
        frame.settingControls[definition.settingKey] = enabledCheckbox

        for eventIndex = 1, #OPEN_EVENTS do
            local event = OPEN_EVENTS[eventIndex]
            local x = eventStartX + ((eventIndex - 1) * eventWidth)
            local enabledTooltip = string.format(
                event.tooltip,
                definition.label
            )
            local checkbox = Controls:CreateCheckbox(content, {
                tooltip = enabledTooltip,
                onChanged = function(checked)
                    Page.SetMatrixValue(
                        definition,
                        event.reason,
                        checked
                    )
                    frame:Sync()
                end,
            })

            checkbox:SetPoint(
                "TOPLEFT",
                content,
                "TOPLEFT",
                x + ((eventWidth - checkbox:GetWidth()) / 2),
                rowY - 1
            )
            frame.matrixControls[#frame.matrixControls + 1] = {
                control = checkbox,
                definition = definition,
                reason = event.reason,
                disabledTooltip = definition.label .. " is disabled.",
            }
        end
    end
end

function Page.CreateFrame()
    local frame = CreateFrame("Frame")

    frame:SetSize(Layout.CANVAS_WIDTH, Layout.CANVAS_HEIGHT)
    frame.settingControls = {}
    frame.instanceTypeControls = {}
    frame.matrixControls = {}
    frame.matrixRowLabels = {}

    local scrollBox, content = Layout.CreateScrollBox(
        frame,
        CONTENT_HEIGHT
    )

    frame.scrollBox = scrollBox

    local title = Controls:CreateText(content, {
        fontObject = GameFontNormalLarge,
        text = "Consumables Frame",
        width = Layout.CONTENT_WIDTH,
    })
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -8)

    local description = Controls:CreateText(content, {
        fontObject = GameFontHighlight,
        text = "Choose when the personal consumable bar opens and which "
            .. "buttons appear for each open event. Open-event options start "
            .. "the frame; the matrix controls its contents.",
        width = Layout.CONTENT_WIDTH,
    })
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)

    createGeneralSettings(frame, content)
    createVisibilityMatrix(frame, content)

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
