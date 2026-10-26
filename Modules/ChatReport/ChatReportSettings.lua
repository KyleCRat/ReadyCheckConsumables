local _, RCC = ...

RCC.ChatReportSettings = RCC.ChatReportSettings or {}

local Page = RCC.ChatReportSettings
local Controls = LibStub("LibModernSettings-1.0")
local Reports = RCC.ChatReportReports

local FEATURE_DISABLED_TOOLTIP =
    "Automatic reporting is disabled. Enable it to edit."

local AUTOMATIC_SETTING_KEYS = {
    "chatReport_permission",
    "chatReport_allReady",
    "chatReport_mythicRaid",
    "chatReport_heroicRaid",
    "chatReport_normalRaid",
    "chatReport_lfr",
    "chatReport_mythicDungeon",
    "chatReport_heroicDungeon",
    "chatReport_normalDungeon",
}

local PERMISSION_CHOICES = {
    { value = "lead", label = "Raid Leader Only" },
    { value = "assist", label = "Raid Leader or Assist" },
    { value = "any", label = "Any Raid Member" },
}

local INSTANCE_SETTINGS = {
    raid = {
        {
            key = "chatReport_mythicRaid",
            label = "Mythic",
            tooltip = "Report after ready checks in Mythic raids.",
        },
        {
            key = "chatReport_heroicRaid",
            label = "Heroic",
            tooltip = "Report after ready checks in Heroic raids.",
        },
        {
            key = "chatReport_normalRaid",
            label = "Normal",
            tooltip = "Report after ready checks in Normal raids.",
        },
        {
            key = "chatReport_lfr",
            label = "Raid Finder",
            tooltip = "Report after ready checks in Raid Finder.",
        },
    },
    dungeon = {
        {
            key = "chatReport_mythicDungeon",
            label = "Mythic",
            tooltip = "Report after ready checks in Mythic dungeons.",
        },
        {
            key = "chatReport_heroicDungeon",
            label = "Heroic",
            tooltip = "Report after ready checks in Heroic dungeons.",
        },
        {
            key = "chatReport_normalDungeon",
            label = "Normal",
            tooltip = "Report after ready checks in Normal dungeons.",
        },
    },
}

local function addSettingCheckbox(frame, flow, options)
    local checkbox = flow:AddControl("checkbox", {
        label = options.label,
        tooltip = options.tooltip,

        onChanged = function(checked)
            RCC.SetSettingValue(options.key, checked)
            frame:Sync()
        end,
    })

    frame.settingControls[options.key] = checkbox

    return checkbox
end

function Page.CreateFrame(measurementFrame)
    local frame = CreateFrame("Frame")

    frame.settingControls = {}

    local layout = Controls:CreateCanvasLayout(frame, {
        measurementFrame = measurementFrame,
    })
    local root = layout:GetRootFlow()

    layout:AddHeader(
        "Chat Report",
        "Choose which readiness information to report and when to send "
            .. "automatic reports."
    )
    addSettingCheckbox(frame, root, {
        key = "chatReport_enabled",
        label = "Enabled",
        tooltip = "Enable automatic chat reports during ready checks.",
    })

    root:AddSection("Report Types")
    root:AddText({
        fontObject = GameFontHighlightSmall,
        text = "Choose what to include in automatic reports and the "
            .. "/rcc r and /rcc rc commands. Automatic reports use the "
            .. "chosen reporter's settings.",
    })

    local reportColumns = root:BeginColumns()
    local definitions = Reports.GetDefinitions()
    local splitIndex = math.ceil(#definitions / 2)

    for i, definition in ipairs(definitions) do
        local flow = i <= splitIndex and reportColumns.left
            or reportColumns.right

        addSettingCheckbox(frame, flow, {
            key = definition.settingKey,
            label = definition.label,
            tooltip = definition.tooltip,
        })
    end

    reportColumns:Finish()

    local permissionColumns = root:BeginColumns()
    local permissionFlow = permissionColumns.left

    permissionFlow:AddSection("Reporting Permission")

    local permission = permissionFlow:AddControl("dropdown", {
        label = "Who Can Report",
        tooltip = "Choose the minimum raid role allowed to send RCC's "
            .. "automatic report. This restriction does not apply outside "
            .. "raids.",
        value = RCC.GetSetting("chatReport_permission"),
        choices = PERMISSION_CHOICES,

        onChanged = function(value)
            RCC.SetSettingValue("chatReport_permission", value)
        end,
    })
    frame.settingControls.chatReport_permission = permission

    permissionColumns.right:AddSection("Ready Announcement")
    addSettingCheckbox(frame, permissionColumns.right, {
        key = "chatReport_allReady",
        label = "Everyone Ready",
        tooltip = "Announce when everyone in the active raid has answered "
            .. "Ready, without waiting for benched players",
    })

    permissionColumns:Finish()

    local instanceColumns = root:BeginColumns()
    local raidFlow = instanceColumns.left
    local dungeonFlow = instanceColumns.right

    raidFlow:AddSection("Raid Instances")
    dungeonFlow:AddSection("Dungeon Instances")

    for i = 1, #INSTANCE_SETTINGS.raid do
        addSettingCheckbox(frame, raidFlow, INSTANCE_SETTINGS.raid[i])
    end

    for i = 1, #INSTANCE_SETTINGS.dungeon do
        addSettingCheckbox(frame, dungeonFlow, INSTANCE_SETTINGS.dungeon[i])
    end

    instanceColumns:Finish()
    layout:Finalize()
    frame.layout = layout

    function frame:Sync()
        for key, control in pairs(self.settingControls) do
            control:SetValue(RCC.GetSetting(key))
        end

        local enabled = RCC.GetSetting("chatReport_enabled") == true

        -- Manual reports still use the section choices when automation is off.
        for _, key in ipairs(AUTOMATIC_SETTING_KEYS) do
            local control = self.settingControls[key]

            control:SetControlEnabled(enabled, FEATURE_DISABLED_TOOLTIP)
        end
    end

    frame:SetScript("OnShow", function(self)
        self:Sync()
    end)

    frame:Sync()

    return frame
end
