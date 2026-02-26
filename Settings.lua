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

    -- Consumables Frame
    consumables_enabled      = true,
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
    --- Chat Report
    ---------------------------------------------------------------------------

    layout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Report to Chat")
    )

    local crEnabled = Settings.RegisterAddOnSetting(
        category, "chatReport_enabled", "chatReport_enabled",
        db, "boolean", "Enable Chat Report", db.chatReport_enabled
    )
    Settings.CreateCheckbox(category, crEnabled,
        "Automatically report missing consumables to chat on ready check.")

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

    ---------------------------------------------------------------------------
    --- Chat Report — Instance Types
    ---------------------------------------------------------------------------

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

    local cfEnabled = Settings.RegisterAddOnSetting(
        category, "consumables_enabled", "consumables_enabled",
        db, "boolean", "Enable Consumables Frame", db.consumables_enabled
    )
    Settings.CreateCheckbox(category, cfEnabled,
        "Show the consumable icon bar during ready checks.")

    ---------------------------------------------------------------------------
    --- Consumables Frame — Icons
    ---------------------------------------------------------------------------

    layout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Enable / Disable Icons for Consumables Frame")
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

    ---------------------------------------------------------------------------
    --- Raid Frame
    ---------------------------------------------------------------------------

    layout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Raid Status Frame")
    )

    local rfEnabled = Settings.RegisterAddOnSetting(
        category, "raidFrame_enabled", "raidFrame_enabled",
        db, "boolean", "Enable Raid Status Frame", db.raidFrame_enabled
    )
    Settings.CreateCheckbox(category, rfEnabled,
        "Show the per-member consumable status frame during ready checks.")

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
