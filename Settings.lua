local _, RCC = ...

--------------------------------------------------------------------------------
--- Defaults
--------------------------------------------------------------------------------

local DEFAULTS = {
    -- Consumables Frame
    consumables_enabled      = true,
    consumables_scale        = 1.0,
    consumables_minShow      = false,
    consumables_minShowTime  = 15,
    icon_food                = true,
    icon_flask               = true,
    icon_mhOil               = true,
    icon_ohOil               = true,
    icon_healthstone         = true,
    icon_dmgPotion           = true,
    icon_healPotion          = true,
    icon_augment             = true,
    icon_vantus              = true,

    -- Raid Frame
    raidFrame_enabled        = true,
    raidFrame_scale          = 1.0,
    raidFrame_minShow        = true,
    raidFrame_minShowTime    = 15,

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
}

--------------------------------------------------------------------------------
--- Public accessor
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
--- Panel registration (ADDON_LOADED)
--------------------------------------------------------------------------------

local function registerPanel()
    local db = ReadyCheckConsumablesDB

    -- Migrate renamed keys
    if db.icon_rune ~= nil then
        db.icon_augment = db.icon_rune
        db.icon_rune = nil
    end

    for key, default in pairs(DEFAULTS) do
        if db[key] == nil then
            db[key] = default
        end
    end

    local category, layout = Settings.RegisterVerticalLayoutCategory(
        "Ready Check Consumables"
    )

    ----------------------------------------------------------------------------
    --- Consumables Frame (subcategory)
    ----------------------------------------------------------------------------

    local cfCat, cfLayout = Settings.RegisterVerticalLayoutSubcategory(
        category, "Consumables Frame"
    )

    ----------------------------------------------------------------------------
    --- Raid Frame (subcategory — declared early for parent page buttons)
    ----------------------------------------------------------------------------

    local rfCat, rfLayout = Settings.RegisterVerticalLayoutSubcategory(
        category, "Raid Frame"
    )

    ----------------------------------------------------------------------------
    --- Chat Report (subcategory — declared early for parent page buttons)
    ----------------------------------------------------------------------------

    local crCat, crLayout = Settings.RegisterVerticalLayoutSubcategory(
        category, "Chat Report"
    )

    ----------------------------------------------------------------------------
    --- Parent page
    ----------------------------------------------------------------------------

    local cfButton = CreateSettingsButtonInitializer(
        "", "Consumables Frame",
        function() Settings.OpenToCategory(cfCat:GetID()) end,
        "Personal consumable icon bar shown during ready checks.",
        false
    )
    layout:AddInitializer(cfButton)

    local rfButton = CreateSettingsButtonInitializer(
        "", "Raid Frame",
        function() Settings.OpenToCategory(rfCat:GetID()) end,
        "Per-member consumable status grid shown during ready checks.",
        false
    )
    layout:AddInitializer(rfButton)

    local crButton = CreateSettingsButtonInitializer(
        "", "Chat Report",
        function() Settings.OpenToCategory(crCat:GetID()) end,
        "Automatic missing consumable reports sent to chat.",
        false
    )
    layout:AddInitializer(crButton)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(
        "Version: " .. (C_AddOns.GetAddOnMetadata("ReadyCheckConsumables", "Version") or "Unknown")
    ))

    local cfEnabled = Settings.RegisterAddOnSetting(
        cfCat, "consumables_enabled", "consumables_enabled",
        db, "boolean", "Enabled", db.consumables_enabled
    )
    Settings.CreateCheckbox(cfCat, cfEnabled,
        "Show the consumable icon bar during ready checks.")

    cfLayout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Display")
    )

    local scaleOptions = Settings.CreateSliderOptions(0.5, 2.0, 0.1)
    scaleOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
        function(value) return string.format("%.1f", value) end)

    local cfScale = Settings.RegisterAddOnSetting(
        cfCat, "consumables_scale", "consumables_scale",
        db, "number", "Scale", db.consumables_scale
    )
    Settings.CreateSlider(cfCat, cfScale, scaleOptions,
        "Scale of the consumable icon bar.")

    Settings.SetOnValueChangedCallback("consumables_scale", function()
        RCC.consumables:SetScale(db.consumables_scale)
    end)

    cfLayout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Visibility")
    )

    local cfMinShow = Settings.RegisterAddOnSetting(
        cfCat, "consumables_minShow", "consumables_minShow",
        db, "boolean", "Keep Open After Response", db.consumables_minShow
    )
    Settings.CreateCheckbox(cfCat, cfMinShow,
        "Keep the consumables frame open for a minimum duration after you respond to a ready check.")

    local minShowOptions = Settings.CreateSliderOptions(1, 40, 1)
    minShowOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
        function(value) return string.format("%ds", value) end)

    local cfMinShowTime = Settings.RegisterAddOnSetting(
        cfCat, "consumables_minShowTime", "consumables_minShowTime",
        db, "number", "Keep Open Duration", db.consumables_minShowTime
    )
    Settings.CreateSlider(cfCat, cfMinShowTime, minShowOptions,
        "How long the consumables frame stays open after a ready check (1-40 seconds).")

    cfLayout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Icons")
    )

    local iconKeys = {
        { "icon_food",        "Food"           },
        { "icon_flask",       "Flask"          },
        { "icon_mhOil",       "Mainhand Oil"   },
        { "icon_ohOil",       "Offhand Oil"    },
        { "icon_healthstone", "Healthstone"    },
        { "icon_dmgPotion",   "Damage Potion"  },
        { "icon_healPotion",  "Healing Potion" },
        { "icon_augment",     "Augment Rune"   },
        { "icon_vantus",      "Vantus Rune"    },
    }

    for _, pair in ipairs(iconKeys) do
        local key, label = pair[1], pair[2]
        local s = Settings.RegisterAddOnSetting(
            cfCat, key, key, db, "boolean", label, db[key]
        )
        Settings.CreateCheckbox(cfCat, s, "Show " .. label .. " icon.")
    end

    ----------------------------------------------------------------------------
    --- Raid Frame (settings)
    ----------------------------------------------------------------------------

    local rfEnabled = Settings.RegisterAddOnSetting(
        rfCat, "raidFrame_enabled", "raidFrame_enabled",
        db, "boolean", "Enabled", db.raidFrame_enabled
    )
    Settings.CreateCheckbox(rfCat, rfEnabled,
        "Show the per-member consumable status frame during ready checks.")

    rfLayout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Display")
    )

    local rfScaleOptions = Settings.CreateSliderOptions(0.5, 2.0, 0.1)
    rfScaleOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
        function(value) return string.format("%.1f", value) end)

    local rfScale = Settings.RegisterAddOnSetting(
        rfCat, "raidFrame_scale", "raidFrame_scale",
        db, "number", "Scale", db.raidFrame_scale
    )
    Settings.CreateSlider(rfCat, rfScale, rfScaleOptions,
        "Scale of the raid status frame.")

    Settings.SetOnValueChangedCallback("raidFrame_scale", function()
        RCC.raidFrame:SetScale(db.raidFrame_scale)
    end)

    rfLayout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Visibility")
    )

    local rfMinShow = Settings.RegisterAddOnSetting(
        rfCat, "raidFrame_minShow", "raidFrame_minShow",
        db, "boolean", "Keep Open After Finished", db.raidFrame_minShow
    )
    Settings.CreateCheckbox(rfCat, rfMinShow,
        "Keep the raid status frame open for a minimum duration after the ready check finishes.")

    local rfMinShowOptions = Settings.CreateSliderOptions(1, 40, 1)
    rfMinShowOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
        function(value) return string.format("%ds", value) end)

    local rfMinShowTime = Settings.RegisterAddOnSetting(
        rfCat, "raidFrame_minShowTime", "raidFrame_minShowTime",
        db, "number", "Keep Open Duration", db.raidFrame_minShowTime
    )
    Settings.CreateSlider(rfCat, rfMinShowTime, rfMinShowOptions,
        "How long the raid status frame stays open after a ready check (1-40 seconds).")

    ----------------------------------------------------------------------------
    --- Chat Report (settings)
    ----------------------------------------------------------------------------

    local crEnabled = Settings.RegisterAddOnSetting(
        crCat, "chatReport_enabled", "chatReport_enabled",
        db, "boolean", "Enabled", db.chatReport_enabled
    )
    Settings.CreateCheckbox(crCat, crEnabled,
        "Automatically report missing consumables to chat on ready check.")

    local function getPermOptions()
        local c = Settings.CreateControlTextContainer()
        c:Add("lead", "Raid Leader")
        c:Add("assist", "Raid Assist")
        c:Add("any", "Any")

        return c:GetData()
    end

    local crPerm = Settings.RegisterAddOnSetting(
        crCat, "chatReport_permission", "chatReport_permission",
        db, "string", "Require Role to Report", db.chatReport_permission
    )
    Settings.CreateDropdown(crCat, crPerm, getPermOptions,
        "Which raid role is allowed to trigger chat reports.")

    crLayout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Instance Types")
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
            crCat, key, key, db, "boolean", label, db[key]
        )
        Settings.CreateCheckbox(crCat, s, "Report in " .. label .. ".")
    end

    Settings.RegisterAddOnCategory(category)
    RCC.settingsCategory = category
end

--------------------------------------------------------------------------------
--- Event wiring
--------------------------------------------------------------------------------

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
