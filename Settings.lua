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
    consumables_instanceOpen = false,
    consumables_instanceOpenParty = true,
    consumables_instanceOpenRaid = true,
    consumables_instanceOpenScenario = true,
    consumables_instanceOpenPvp = true,
    consumables_instanceOpenArena = true,
    consumables_instanceHide = true,
    consumables_instanceHideTime = 15,
    consumables_preferUnlimitedAugment = true,
    -- consumables_instanceOnlyIfMissing = false,
    icon_food                = true,
    icon_flask               = true,
    icon_mhTempWeaponEnchant = true,
    icon_ohTempWeaponEnchant = true,
    icon_healthstone         = true,
    icon_dmgPotion           = true,
    icon_healPotion          = true,
    icon_recuperate          = false,
    icon_augment             = true,
    icon_raidBuff            = true,
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
--- Macro settings canvas
--------------------------------------------------------------------------------

local function createMacroButton(parent, text, key, label, characterSpecific)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(86, 22)
    button:SetText(text)

    local macroTab = characterSpecific
        and "Character Specific Macro tab"
        or "Shared Macro tab"
    button.tooltipText = "Create " .. label .. " macro in the " .. macroTab .. "."

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.tooltipText, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", function()
        local Macros = RCC.ConsumableMacros

        if Macros and Macros.CreateManagedMacro then
            Macros.CreateManagedMacro(key, characterSpecific)
        end
    end)

    return button
end

local function getMacroMarker(key)
    return "#RCC:" .. key
end

local function createMacroText(parent, fontObject, text, width)
    local fontString = parent:CreateFontString(nil, "ARTWORK")

    if fontObject then
        fontString:SetFontObject(fontObject)
    end

    fontString:SetJustifyH("LEFT")
    fontString:SetJustifyV("TOP")
    fontString:SetWidth(width)
    fontString:SetText(text)

    return fontString
end

local function createMacrosSettingsFrame()
    local frame = CreateFrame("Frame")
    frame:SetSize(640, 560)

    local title = createMacroText(
        frame,
        GameFontNormalLarge,
        "Managed Macros",
        600
    )
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)

    local body = createMacroText(
        frame,
        GameFontHighlight,
        "Managed macros are ordinary WoW macros containing a marker like "
        .. "#RCC:dmgpot. RCC keeps the marker, adds an automated comment, "
        .. "and rewrites the generated /use or /cast lines when bags, "
        .. "cached selections, equipment, spells, zone, or macros change.\n\n"
        .. "Food, flask, augment, Vantus, and weapon enchant macros follow "
        .. "the same cached selection used by the consumable frame. The "
        .. "cache changes when you choose or use a cached consumable from "
        .. "RCC's consumable buttons. If a cached item is out of bags, RCC "
        .. "still writes that item ID into the macro so the action bar shows "
        .. "it as unavailable. Potions and healthstones use the current "
        .. "available item list.",
        600
    )
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)

    local keyHeader = createMacroText(frame, GameFontNormal, "Name", 120)
    keyHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -176)

    local markerHeader = createMacroText(frame, GameFontNormal, "Key", 120)
    markerHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 180, -176)

    local sharedHeader = createMacroText(frame, GameFontNormal, "Create", 190)
    sharedHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 360, -176)

    local rowTop = -204
    local rowHeight = 28
    local definitions = RCC.ConsumableMacros
        and RCC.ConsumableMacros.GetDefinitions
        and RCC.ConsumableMacros.GetDefinitions()
        or {}

    for i = 1, #definitions do
        local definition = definitions[i]
        local key = definition.key
        local label = createMacroText(
            frame,
            GameFontHighlight,
            definition.label,
            170
        )
        label:SetPoint(
            "TOPLEFT",
            frame,
            "TOPLEFT",
            0,
            rowTop - ((i - 1) * rowHeight)
        )

        local marker = createMacroText(
            frame,
            GameFontHighlight,
            getMacroMarker(key),
            150
        )
        marker:SetPoint("TOPLEFT", label, "TOPLEFT", 180, 0)

        local sharedButton = createMacroButton(
            frame,
            "Shared",
            key,
            definition.label,
            false
        )
        sharedButton:SetPoint("TOPLEFT", label, "TOPLEFT", 360, -2)

        local characterButton = createMacroButton(
            frame,
            "Character",
            key,
            definition.label,
            true
        )
        characterButton:SetPoint("LEFT", sharedButton, "RIGHT", 8, 0)
    end

    return frame
end

--------------------------------------------------------------------------------
--- Panel registration (ADDON_LOADED)
--------------------------------------------------------------------------------

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
    --- Macros (subcategory - canvas)
    ----------------------------------------------------------------------------

    local macroFrame = createMacrosSettingsFrame()
    local macroCat, macroLayout = Settings.RegisterCanvasLayoutSubcategory(
        category, macroFrame, "Macros"
    )
    macroLayout:AddAnchorPoint("TOPLEFT", 35, -35)
    macroLayout:AddAnchorPoint("BOTTOMRIGHT", -35, 35)

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

    local macroButton = CreateSettingsButtonInitializer(
        "", "Macros",
        function() Settings.OpenToCategory(macroCat:GetID()) end,
        "Create and manage RCC marker macros.",
        false
    )
    layout:AddInitializer(macroButton)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(
        "Version: " .. (C_AddOns.GetAddOnMetadata("ReadyCheckConsumables", "Version") or "Unknown")
    ))

    local cfEnabled = Settings.RegisterAddOnSetting(
        cfCat, "consumables_enabled", "consumables_enabled",
        db, "boolean", "Enabled", DEFAULTS.consumables_enabled
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
        db, "number", "Scale", DEFAULTS.consumables_scale
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
        db, "boolean", "Keep Open After Response", DEFAULTS.consumables_minShow
    )
    Settings.CreateCheckbox(cfCat, cfMinShow,
        "Keep the consumables frame open for a minimum duration after you respond to a ready check.")

    local minShowOptions = Settings.CreateSliderOptions(1, 40, 1)
    minShowOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
        function(value) return string.format("%ds", value) end)

    local cfMinShowTime = Settings.RegisterAddOnSetting(
        cfCat, "consumables_minShowTime", "consumables_minShowTime",
        db, "number", "Keep Open Duration", DEFAULTS.consumables_minShowTime
    )
    Settings.CreateSlider(cfCat, cfMinShowTime, minShowOptions,
        "How long the consumables frame stays open after a ready check (1-40 seconds).")

    cfLayout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Open When Entering Instance")
    )

    local cfInstanceOpen = Settings.RegisterAddOnSetting(
        cfCat, "consumables_instanceOpen", "consumables_instanceOpen",
        db, "boolean", "Open When Entering Instance",
        DEFAULTS.consumables_instanceOpen
    )
    Settings.CreateCheckbox(cfCat, cfInstanceOpen,
        "Show the consumables frame when you enter instanced content.")

    local instanceTypeSettings = {
        {
            "consumables_instanceOpenParty",
            "Dungeons",
            "Open when entering dungeon instances.",
        },
        {
            "consumables_instanceOpenRaid",
            "Raids",
            "Open when entering raid instances.",
        },
        {
            "consumables_instanceOpenScenario",
            "Scenarios",
            "Open when entering scenario instances.",
        },
        {
            "consumables_instanceOpenPvp",
            "Battlegrounds",
            "Open when entering battleground instances.",
        },
        {
            "consumables_instanceOpenArena",
            "Arenas",
            "Open when entering arena instances.",
        },
    }

    for _, option in ipairs(instanceTypeSettings) do
        local key, label, tooltip = option[1], option[2], option[3]
        local setting = Settings.RegisterAddOnSetting(
            cfCat, key, key, db, "boolean", label, DEFAULTS[key]
        )
        Settings.CreateCheckbox(cfCat, setting, tooltip)
    end

    -- Future option:
    -- local cfInstanceOnlyIfMissing = Settings.RegisterAddOnSetting(
    --     cfCat, "consumables_instanceOnlyIfMissing",
    --     "consumables_instanceOnlyIfMissing",
    --     db, "boolean", "Only Open When Consumables Are Complete",
    --     db.consumables_instanceOnlyIfMissing
    -- )
    -- Settings.CreateCheckbox(cfCat, cfInstanceOnlyIfMissing,
    --     "Only show on instance entry when all tracked buffs have 30 minutes or more remaining and all required items are in your inventory.")

    local cfInstanceHide = Settings.RegisterAddOnSetting(
        cfCat, "consumables_instanceHide", "consumables_instanceHide",
        db, "boolean", "Auto-Hide After Delay", DEFAULTS.consumables_instanceHide
    )
    Settings.CreateCheckbox(cfCat, cfInstanceHide,
        "Hide the consumables frame automatically after the auto-hide delay.")

    local instanceHideOptions = Settings.CreateSliderOptions(5, 120, 5)
    instanceHideOptions:SetLabelFormatter(
        MinimalSliderWithSteppersMixin.Label.Right,
        function(value) return string.format("%ds", value) end
    )

    local cfInstanceHideTime = Settings.RegisterAddOnSetting(
        cfCat, "consumables_instanceHideTime", "consumables_instanceHideTime",
        db, "number", "Auto-Hide Delay Duration", DEFAULTS.consumables_instanceHideTime
    )
    Settings.CreateSlider(cfCat, cfInstanceHideTime, instanceHideOptions,
        "How long the consumables frame stays open when Auto-Hide After Delay is enabled (5-120 seconds).")

    cfLayout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Augment Runes")
    )

    local cfPreferUnlimitedAugment = Settings.RegisterAddOnSetting(
        cfCat, "consumables_preferUnlimitedAugment",
        "consumables_preferUnlimitedAugment",
        db, "boolean", "Prefer Unlimited Augment Runes",
        DEFAULTS.consumables_preferUnlimitedAugment
    )
    Settings.CreateCheckbox(cfCat, cfPreferUnlimitedAugment,
        "Use unlimited augment runes before higher-expansion consumable augment runes.")

    Settings.SetOnValueChangedCallback(
        "consumables_preferUnlimitedAugment",
        function()
            if RCC.consumables and RCC.consumables:IsShown()
                and not InCombatLockdown()
            then
                RCC.consumables:Update()
            end
        end
    )

    cfLayout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Icons")
    )

    local iconKeys = {
        { "icon_food",        "Food"           },
        { "icon_flask",       "Flask"          },
        { "icon_mhTempWeaponEnchant", "MH Weapon Enchant" },
        { "icon_ohTempWeaponEnchant", "OH Weapon Enchant" },
        { "icon_healthstone", "Healthstone"    },
        { "icon_dmgPotion",   "Damage Potion"  },
        { "icon_healPotion",  "Healing Potion" },
        { "icon_recuperate",  "Recuperate"     },
        { "icon_augment",     "Augment Rune"   },
        { "icon_raidBuff",    "Raid Buff"      },
        { "icon_vantus",      "Vantus Rune"    },
    }

    for _, pair in ipairs(iconKeys) do
        local key, label = pair[1], pair[2]
        local s = Settings.RegisterAddOnSetting(
            cfCat, key, key, db, "boolean", label, DEFAULTS[key]
        )
        Settings.CreateCheckbox(cfCat, s, "Show " .. label .. " icon.")
        Settings.SetOnValueChangedCallback(key, function()
            if RCC.consumables and RCC.consumables:IsShown()
                and not InCombatLockdown()
            then
                RCC.consumables:Update()
            end
        end)
    end

    ----------------------------------------------------------------------------
    --- Raid Frame (settings)
    ----------------------------------------------------------------------------

    local rfEnabled = Settings.RegisterAddOnSetting(
        rfCat, "raidFrame_enabled", "raidFrame_enabled",
        db, "boolean", "Enabled", DEFAULTS.raidFrame_enabled
    )
    Settings.CreateCheckbox(rfCat, rfEnabled,
        "Show the per-member consumable status frame during ready checks.")

    rfLayout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Display")
    )

    local rfScaleOptions = Settings.CreateSliderOptions(0.5, 1.5, 0.05)
    rfScaleOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
        function(value) return string.format("%d%%", floor(value * 100 + 0.5)) end)

    local rfScale = Settings.RegisterAddOnSetting(
        rfCat, "raidFrame_scale", "raidFrame_scale",
        db, "number", "Scale", DEFAULTS.raidFrame_scale
    )
    Settings.CreateSlider(rfCat, rfScale, rfScaleOptions,
        "Scale of the raid status frame.")

    Settings.SetOnValueChangedCallback("raidFrame_scale", function()
        if RCC.raidFrame.SyncScaleControl then
            RCC.raidFrame:SyncScaleControl()
        else
            RCC.raidFrame:SetScale(db.raidFrame_scale)
        end
    end)

    rfLayout:AddInitializer(
        CreateSettingsListSectionHeaderInitializer("Visibility")
    )

    local rfMinShow = Settings.RegisterAddOnSetting(
        rfCat, "raidFrame_minShow", "raidFrame_minShow",
        db, "boolean", "Keep Open After Finished", DEFAULTS.raidFrame_minShow
    )
    Settings.CreateCheckbox(rfCat, rfMinShow,
        "Keep the raid status frame open for a minimum duration after the ready check finishes.")

    local rfMinShowOptions = Settings.CreateSliderOptions(1, 40, 1)
    rfMinShowOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
        function(value) return string.format("%ds", value) end)

    local rfMinShowTime = Settings.RegisterAddOnSetting(
        rfCat, "raidFrame_minShowTime", "raidFrame_minShowTime",
        db, "number", "Keep Open Duration", DEFAULTS.raidFrame_minShowTime
    )
    Settings.CreateSlider(rfCat, rfMinShowTime, rfMinShowOptions,
        "How long the raid status frame stays open after a ready check (1-40 seconds).")

    ----------------------------------------------------------------------------
    --- Chat Report (settings)
    ----------------------------------------------------------------------------

    local crEnabled = Settings.RegisterAddOnSetting(
        crCat, "chatReport_enabled", "chatReport_enabled",
        db, "boolean", "Enabled", DEFAULTS.chatReport_enabled
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
        db, "string", "Require Role to Report", DEFAULTS.chatReport_permission
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
            crCat, key, key, db, "boolean", label, DEFAULTS[key]
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
    ReadyCheckConsumablesDB.consumableItemCache =
        ReadyCheckConsumablesDB.consumableItemCache or {}
    registerPanel()
end)
