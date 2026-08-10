local _, RCC = ...

RCC.ChatReportSettings = RCC.ChatReportSettings or {}

local Page = RCC.ChatReportSettings
local Controls = LibStub("LibModernSettings-1.0")
local Layout = RCC.SettingsLayout

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
    {
        key = "chatReport_mythicRaid",
        label = "Mythic",
        tooltip = "Report after ready checks in Mythic raids.",
        x = 0,
        y = -264,
    },
    {
        key = "chatReport_heroicRaid",
        label = "Heroic",
        tooltip = "Report after ready checks in Heroic raids.",
        x = 0,
        y = -300,
    },
    {
        key = "chatReport_normalRaid",
        label = "Normal",
        tooltip = "Report after ready checks in Normal raids.",
        x = 0,
        y = -336,
    },
    {
        key = "chatReport_lfr",
        label = "Raid Finder",
        tooltip = "Report after ready checks in Raid Finder.",
        x = 0,
        y = -372,
    },
    {
        key = "chatReport_mythicDungeon",
        label = "Mythic",
        tooltip = "Report after ready checks in Mythic dungeons.",
        rightColumn = true,
        y = -264,
    },
    {
        key = "chatReport_heroicDungeon",
        label = "Heroic",
        tooltip = "Report after ready checks in Heroic dungeons.",
        rightColumn = true,
        y = -300,
    },
    {
        key = "chatReport_normalDungeon",
        label = "Normal",
        tooltip = "Report after ready checks in Normal dungeons.",
        rightColumn = true,
        y = -336,
    },
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

local function addSettingCheckbox(frame, parent, options)
    local checkbox = Controls:CreateCheckbox(parent, {
        label = options.label,
        width = options.width or Layout.COLUMN_WIDTH,
        tooltip = options.tooltip,
        onChanged = function(checked)
            RCC.SetSettingValue(options.key, checked)
            frame:Sync()
        end,
    })

    checkbox:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        options.rightColumn and Layout.RIGHT_COLUMN_X or options.x,
        options.y
    )
    frame.settingControls[options.key] = checkbox

    return checkbox
end

function Page.CreateFrame()
    local frame = CreateFrame("Frame")

    frame:SetSize(Layout.CANVAS_WIDTH, Layout.CANVAS_HEIGHT)
    frame.settingControls = {}

    local content = Layout.CreateContentFrame(frame)

    local title = Controls:CreateText(content, {
        fontObject = GameFontNormalLarge,
        text = "Chat Report",
        width = Layout.CONTENT_WIDTH,
    })
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -8)

    local description = Controls:CreateText(content, {
        fontObject = GameFontHighlight,
        text = "Configure automatic reports for players who are missing "
            .. "required consumables after a ready check.",
        width = Layout.CONTENT_WIDTH,
    })
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)

    addSettingCheckbox(frame, content, {
        key = "chatReport_enabled",
        label = "Enabled",
        tooltip = "Enable automatic missing-consumable chat reports.",
        x = 0,
        y = -76,
    })

    createSectionHeader(content, "Reporting Permission", 0, -124)

    local permission = Controls:CreateDropdown(content, {
        label = "Who Can Report",
        tooltip = "Choose the minimum raid role allowed to send RCC's "
            .. "automatic report. This restriction does not apply outside "
            .. "raids.",
        width = Layout.COLUMN_WIDTH,
        value = RCC.GetSetting("chatReport_permission"),
        choices = PERMISSION_CHOICES,
        onChanged = function(value)
            RCC.SetSettingValue("chatReport_permission", value)
        end,
    })
    permission:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -150)
    frame.settingControls.chatReport_permission = permission

    createSectionHeader(content, "Raid Instances", 0, -238)
    createSectionHeader(
        content,
        "Dungeon Instances",
        Layout.RIGHT_COLUMN_X,
        -238
    )

    for i = 1, #INSTANCE_SETTINGS do
        local options = INSTANCE_SETTINGS[i]

        addSettingCheckbox(frame, content, options)
    end

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
