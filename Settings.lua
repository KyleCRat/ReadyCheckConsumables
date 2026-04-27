local _, RCC = ...

-------------------------------------------------------------------------------
--- Defaults
-------------------------------------------------------------------------------

local DEFAULTS = {
    -- Chat Report
    chatReport_enabled       = true,
    chatReport_permission    = "assist",
    chatReport_mythicRaid    = true,
    chatReport_heroicRaid    = true,
    chatReport_normalRaid    = false,
    chatReport_lfr           = false,
    chatReport_mythicDungeon = false,
    chatReport_heroicDungeon = false,
    chatReport_normalDungeon = false,

    -- Scale
    consumables_scale        = 1.0,
    raidFrame_scale          = 1.0,

    -- Consumables Frame
    consumables_enabled      = true,
    consumables_minShow      = false,
    consumables_minShowTime  = 15,
    icon_food                = true,
    icon_flask               = true,
    icon_mhOil               = true,
    icon_ohOil               = true,
    icon_healthstone         = true,
    icon_dmgPotion           = true,
    icon_healPotion          = true,
    icon_rune                = true,
    icon_vantus              = true,

    -- Raid Frame
    raidFrame_enabled        = true,
}

-------------------------------------------------------------------------------
--- Public accessor
-------------------------------------------------------------------------------

function RCC.GetSetting(key)
    local db = ReadyCheckConsumablesDB

    if not db then
        return DEFAULTS[key]
    end

    local val = db[key]

    if val == nil then
        return DEFAULTS[key]
    end

    return val
end

-------------------------------------------------------------------------------
--- Panel registration (ADDON_LOADED)
-------------------------------------------------------------------------------

local function registerPanel()
    local db = ReadyCheckConsumablesDB

    for key, default in pairs(DEFAULTS) do
        if db[key] == nil then
            db[key] = default
        end
    end

    local category, layout = Settings.RegisterVerticalLayoutCategory(
        "Ready Check Consumables"
    )

    ---------------------------------------------------------------------------
    --- Enable / Disable
    ---------------------------------------------------------------------------

    local cfEnabled = Settings.RegisterAddOnSetting(
        category, "consumables_enabled", "consumables_enabled",
        db, "boolean", "Enable Consumables Frame", db.consumables_enabled
    )
    Settings.CreateCheckbox(category, cfEnabled,
        "Show the consumable icon bar during ready checks.")

    local rfEnabled = Settings.RegisterAddOnSetting(
        category, "raidFrame_enabled", "raidFrame_enabled",
        db, "boolean", "Enable Raid Status Frame", db.raidFrame_enabled
    )
    Settings.CreateCheckbox(category, rfEnabled,
        "Show the per-member consumable status frame during ready checks.")

    local crEnabled = Settings.RegisterAddOnSetting(
        category, "chatReport_enabled", "chatReport_enabled",
        db, "boolean", "Enable Chat Report", db.chatReport_enabled
    )
    Settings.CreateCheckbox(category, crEnabled,
        "Automatically report missing consumables to chat on ready check.")

    ---------------------------------------------------------------------------
    --- Scale
    ---------------------------------------------------------------------------

    layout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Scale")
    )

    local scaleOptions = Settings.CreateSliderOptions(0.5, 2.0, 0.1)
    scaleOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
        function(value) return string.format("%.1f", value) end)

    local cfScale = Settings.RegisterAddOnSetting(
        category, "consumables_scale", "consumables_scale",
        db, "number", "Consumables Frame Scale", db.consumables_scale
    )
    Settings.CreateSlider(category, cfScale, scaleOptions,
        "Scale of the consumable icon bar.")

    local rfScale = Settings.RegisterAddOnSetting(
        category, "raidFrame_scale", "raidFrame_scale",
        db, "number", "Raid Status Frame Scale", db.raidFrame_scale
    )
    Settings.CreateSlider(category, rfScale, scaleOptions,
        "Scale of the raid status frame.")

    Settings.SetOnValueChangedCallback("consumables_scale", function()
        RCC.consumables:SetScale(db.consumables_scale)
    end)

    Settings.SetOnValueChangedCallback("raidFrame_scale", function()
        RCC.raidFrame:SetScale(db.raidFrame_scale)
    end)

    ---------------------------------------------------------------------------
    --- Report to Chat
    ---------------------------------------------------------------------------

    layout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Report to Chat")
    )

    local function getPermOptions()
        local c = Settings.CreateControlTextContainer()
        c:Add("lead", "Raid Leader")
        c:Add("assist", "Raid Assist")
        c:Add("any", "Any")

        return c:GetData()
    end

    local crPerm = Settings.RegisterAddOnSetting(
        category, "chatReport_permission", "chatReport_permission",
        db, "string", "Require Role to Report", db.chatReport_permission
    )
    Settings.CreateDropdown(category, crPerm, getPermOptions,
        "Which raid role is allowed to trigger chat reports.")

    layout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Only Report to Chat in:")
    )

    local instanceKeys = {
        { "chatReport_mythicRaid",    "Mythic Raid"    },
        { "chatReport_heroicRaid",    "Heroic Raid"    },
        { "chatReport_normalRaid",    "Normal Raid"    },
        { "chatReport_lfr",           "LFR"            },
        { "chatReport_mythicDungeon", "Mythic Dungeon" },
        { "chatReport_heroicDungeon", "Heroic Dungeon" },
        { "chatReport_normalDungeon", "Normal Dungeon" },
    }

    for _, pair in ipairs(instanceKeys) do
        local key, label = pair[1], pair[2]
        local s = Settings.RegisterAddOnSetting(
            category, key, key, db, "boolean", label, db[key]
        )
        Settings.CreateCheckbox(category, s, "Report in " .. label .. ".")
    end

    ---------------------------------------------------------------------------
    --- Consumables Frame
    ---------------------------------------------------------------------------

    layout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Consumables Frame")
    )

    local cfMinShow = Settings.RegisterAddOnSetting(
        category, "consumables_minShow", "consumables_minShow",
        db, "boolean", "Keep Open After Response", db.consumables_minShow
    )
    Settings.CreateCheckbox(category, cfMinShow,
        "Keep the consumables frame open for a minimum duration after you respond to a ready check.")

    local minShowOptions = Settings.CreateSliderOptions(1, 40, 1)
    minShowOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
        function(value) return string.format("%ds", value) end)

    local cfMinShowTime = Settings.RegisterAddOnSetting(
        category, "consumables_minShowTime", "consumables_minShowTime",
        db, "number", "Keep Open Duration", db.consumables_minShowTime
    )
    Settings.CreateSlider(category, cfMinShowTime, minShowOptions,
        "How long the consumables frame stays open after a ready check (1–40 seconds).")

    ---------------------------------------------------------------------------
    --- Consumables Frame — Icons
    ---------------------------------------------------------------------------

    layout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Consumables Frame Icons")
    )

    local iconKeys = {
        { "icon_food",        "Food"           },
        { "icon_flask",       "Flask"          },
        { "icon_mhOil",       "Mainhand Oil"   },
        { "icon_ohOil",       "Offhand Oil"    },
        { "icon_healthstone", "Healthstone"    },
        { "icon_dmgPotion",   "Damage Potion"  },
        { "icon_healPotion",  "Healing Potion" },
        { "icon_rune",        "Augment Rune"   },
        { "icon_vantus",      "Vantus Rune"    },
    }

    for _, pair in ipairs(iconKeys) do
        local key, label = pair[1], pair[2]
        local s = Settings.RegisterAddOnSetting(
            category, key, key, db, "boolean", label, db[key]
        )
        Settings.CreateCheckbox(category, s, "Show " .. label .. " icon.")
    end

    Settings.RegisterAddOnCategory(category)
    RCC.settingsCategory = category
end

-------------------------------------------------------------------------------
--- Event wiring
-------------------------------------------------------------------------------

local settingsFrame = CreateFrame("Frame")
settingsFrame:RegisterEvent("ADDON_LOADED")
settingsFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "ReadyCheckConsumables" then
        return
    end

    self:UnregisterEvent("ADDON_LOADED")
    ReadyCheckConsumablesDB = ReadyCheckConsumablesDB or {}
    registerPanel()
end)
