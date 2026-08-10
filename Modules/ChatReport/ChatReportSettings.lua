local _, RCC = ...

RCC.ChatReportSettings = RCC.ChatReportSettings or {}

local Page = RCC.ChatReportSettings
local Controls = LibStub("LibModernSettings-1.0")

local FEATURE_DISABLED_TOOLTIP =
    "Chat Report is disabled. Enable it to edit."

local SETTING_KEYS = {
    "chatReport_enabled",
    "chatReport_permission",
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
        "Configure automatic reports for players who are missing "
            .. "required consumables after a ready check."
    )
    addSettingCheckbox(frame, root, {
        key = "chatReport_enabled",
        label = "Enabled",
        tooltip = "Enable automatic missing-consumable chat reports.",
    })

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
        for i = 1, #SETTING_KEYS do
            local key = SETTING_KEYS[i]
            local control = self.settingControls[key]

            control:SetValue(RCC.GetSetting(key))
        end

        local enabled = RCC.GetSetting("chatReport_enabled") == true

        for i = 2, #SETTING_KEYS do
            local control = self.settingControls[SETTING_KEYS[i]]

            control:SetControlEnabled(enabled, FEATURE_DISABLED_TOOLTIP)
        end
    end

    frame:SetScript("OnShow", function(self)
        self:Sync()
    end)
    frame:Sync()

    return frame
end
