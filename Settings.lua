local _, RCC = ...

local CanvasControls = RCC.SettingsCanvasControls

--------------------------------------------------------------------------------
--- Defaults
--------------------------------------------------------------------------------

local DEFAULTS = {
    -- Consumables Frame
    consumables_enabled      = true,
    consumables_scale        = 1.0,
    consumables_minShow      = false,
    consumables_minShowTime  = 15,
    consumables_cauldronOpen = false,
    consumables_breakOpen    = false,
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
    icon_combatPotion        = true,
    icon_healPotion          = true,
    icon_consumableStasis    = true,
    icon_recuperate          = false,
    icon_augment             = true,
    icon_raidBuff            = true,
    icon_vantus              = true,

    -- Raid Frame
    raidFrame_enabled        = true,
    raidFrame_scale          = 1.0,
    raidFrame_minShow        = true,
    raidFrame_minShowTime    = 15,

    -- Raid Frame Feast and Cauldron Columns
    raidFrameCauldron_enabled               = true,
    raidFrameCauldron_showOutsideReadyCheck = true,

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

function RCC.GetSettingDefault(key)
    return DEFAULTS[key]
end

function RCC.SetSettingValue(key, value)
    if not ReadyCheckConsumablesDB or DEFAULTS[key] == nil then
        return false
    end

    ReadyCheckConsumablesDB[key] = value

    return true
end

local function getContextualVisibilityOverrides()
    local db = ReadyCheckConsumablesDB

    if not db or type(db.contextualVisibility) ~= "table" then
        return
    end

    return db.contextualVisibility
end

function RCC.GetContextualVisibilityOverride(surface, elementKey, reason)
    local overrides = getContextualVisibilityOverrides()
    local surfaceOverrides = overrides and overrides[surface]

    if type(surfaceOverrides) ~= "table" then
        return
    end

    local elementOverrides = surfaceOverrides[elementKey]

    if type(elementOverrides) ~= "table" then
        return
    end

    local value = elementOverrides[reason]

    if type(value) == "boolean" then
        return value
    end
end

function RCC.GetContextualVisibility(surface, elementKey, reason, defaultValue)
    local override = RCC.GetContextualVisibilityOverride(
        surface,
        elementKey,
        reason
    )

    if override ~= nil then
        return override
    end

    return defaultValue == true
end

local function removeEmptyOverrideTables(overrides, surface, elementKey)
    local surfaceOverrides = overrides[surface]

    if type(surfaceOverrides) ~= "table" then
        overrides[surface] = nil

        return
    end

    local elementOverrides = surfaceOverrides[elementKey]

    if type(elementOverrides) ~= "table" then
        surfaceOverrides[elementKey] = nil
    elseif next(elementOverrides) == nil then
        surfaceOverrides[elementKey] = nil
    end

    if next(surfaceOverrides) == nil then
        overrides[surface] = nil
    end
end

local function refreshContextualVisibility()
    if InCombatLockdown() then return end

    if RCC.consumables:IsShown() then
        RCC.consumables:Update()
    end

    RCC.raidFrame:RefreshContextualVisibility()
end

function RCC.SetContextualVisibilityOverride(surface, elementKey, reason, value)
    if not surface or not elementKey or not reason then
        return false
    end

    if value ~= nil and type(value) ~= "boolean" then
        return false
    end

    local db = ReadyCheckConsumablesDB

    if not db then
        return false
    end

    db.contextualVisibility = type(db.contextualVisibility) == "table"
        and db.contextualVisibility
        or {}

    local overrides = db.contextualVisibility

    if value == nil then
        local surfaceOverrides = overrides[surface]
        local elementOverrides = type(surfaceOverrides) == "table"
            and surfaceOverrides[elementKey]
            or nil

        if type(elementOverrides) == "table" then
            elementOverrides[reason] = nil
            removeEmptyOverrideTables(overrides, surface, elementKey)
        end
    else
        if type(overrides[surface]) ~= "table" then
            overrides[surface] = {}
        end

        if type(overrides[surface][elementKey]) ~= "table" then
            overrides[surface][elementKey] = {}
        end

        overrides[surface][elementKey][reason] = value
    end

    refreshContextualVisibility()

    return true
end

function RCC.ClearContextualVisibilityOverrides(surface)
    if not ReadyCheckConsumablesDB or not surface then
        return false
    end

    local overrides = getContextualVisibilityOverrides()

    if overrides then
        overrides[surface] = nil

        if next(overrides) == nil then
            ReadyCheckConsumablesDB.contextualVisibility = nil
        end
    end

    refreshContextualVisibility()

    return true
end

--------------------------------------------------------------------------------
--- Macro settings canvas
--------------------------------------------------------------------------------

local function createMacroButton(parent, text, key, label, characterSpecific)
    local button = CanvasControls.CreateSmallTertiaryButton(
        parent,
        text,
        86,
        22
    )

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

        Macros.CreateManagedMacro(key, characterSpecific)
    end)

    return button
end

local function getMacroMarker(key)
    return "#RCC:" .. key
end

local function getInlineMacroMarker(key)
    return "#RCCI:" .. key
end

local function getMacroShorthand(definition)
    local aliases = definition.aliases

    if not aliases then return definition.key end

    local shorthand = aliases[1]

    for aliasIndex = 2, #aliases do
        local alias = aliases[aliasIndex]

        if #alias < #shorthand then
            shorthand = alias
        end
    end

    return shorthand
end

local function getMacroKeyText(definition)
    local marker = getMacroMarker(definition.key)
    local shorthand = getMacroShorthand(definition)

    if shorthand ~= definition.key then
        return marker .. " (" .. shorthand .. ")"
    end

    return marker
end

local function getInlineMacroText(definition)
    if not definition.inlineGetAction then return "-" end

    return getInlineMacroMarker(getMacroShorthand(definition))
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
        "RCC macros keep action-bar buttons linked to your preferred "
        .. "consumables. Right-click an item in a Consumables Frame button's "
        .. "flyout to select it as your preferred consumable. RCC keeps that "
        .. "preference until you right-click another item, even when the "
        .. "selected item is temporarily missing from your bags. If you have "
        .. "not selected a preferred item, RCC uses the best available "
        .. "option.\n\n"
        .. "Managed macros are complete macros created and maintained by RCC. "
        .. "The #RCC:<key> marker identifies what each macro should use. Choose "
        .. "Shared or Character below to create one. The Healing Potion macro "
        .. "casts Recuperate out of combat and uses a potion in combat.\n\n"
        .. "Inline markers update one line inside a custom macro without "
        .. "changing the rest of it. Put an inline marker shown below on its "
        .. "own line. Macro conditions can follow the marker, for example "
        .. "#RCCI:cp [combat].",
        600
    )
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)

    local nameHeader = createMacroText(frame, GameFontNormal, "Name", 120)
    nameHeader:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -20)

    local keyHeader = createMacroText(
        frame,
        GameFontNormal,
        "Key (Shorthand)",
        190
    )
    keyHeader:SetPoint("TOPLEFT", nameHeader, "TOPLEFT", 160, 0)

    local inlineHeader = createMacroText(
        frame,
        GameFontNormal,
        "Inline",
        95
    )
    inlineHeader:SetPoint("TOPLEFT", nameHeader, "TOPLEFT", 355, 0)

    local createHeader = createMacroText(frame, GameFontNormal, "Create", 180)
    createHeader:SetPoint("TOPLEFT", nameHeader, "TOPLEFT", 455, 0)

    local rowHeight = 28
    local definitions = RCC.ConsumableMacros.GetDefinitions()

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
            nameHeader,
            "BOTTOMLEFT",
            0,
            -14 - ((i - 1) * rowHeight)
        )

        local marker = createMacroText(
            frame,
            GameFontHighlight,
            getMacroKeyText(definition),
            190
        )
        marker:SetPoint("TOPLEFT", label, "TOPLEFT", 160, 0)

        local inlineMarker = createMacroText(
            frame,
            GameFontHighlight,
            getInlineMacroText(definition),
            95
        )
        inlineMarker:SetPoint("TOPLEFT", label, "TOPLEFT", 355, 0)

        local sharedButton = createMacroButton(
            frame,
            "Shared",
            key,
            definition.label,
            false
        )
        sharedButton:SetPoint("TOPLEFT", label, "TOPLEFT", 455, -2)

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

local function openSettingsDestination(button)
    Settings.OpenToCategory(button.settingsCategoryID)
end

local function populateMainSettingsFrame(frame, destinations)
    local Controls = RCC.SettingsCanvasControls
    local positions = {
        { x = 0, y = -126 },
        { x = 300, y = -126 },
        { x = 0, y = -230 },
        { x = 300, y = -230 },
    }

    frame:SetSize(640, 560)

    local title = Controls.CreateText(
        frame,
        GameFontNormalLarge,
        "Ready Check Consumables",
        580
    )
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)

    local description = Controls.CreateText(
        frame,
        GameFontHighlight,
        "Configure RCC's personal consumable bar, raid status frame, "
            .. "chat reporting, and managed macros.",
        570
    )
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)

    local sectionTitle = Controls.CreateText(
        frame,
        GameFontNormal,
        "Settings",
        570
    )
    sectionTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -96)

    for i = 1, #destinations do
        local destination = destinations[i]
        local position = positions[i]
        local button = Controls.CreateTertiaryButton(
            frame,
            destination.label,
            270,
            34,
            openSettingsDestination
        )
        button.settingsCategoryID = destination.category:GetID()
        button:SetPoint(
            "TOPLEFT",
            frame,
            "TOPLEFT",
            position.x,
            position.y
        )

        local detail = Controls.CreateText(
            frame,
            GameFontHighlight,
            destination.description,
            270
        )
        detail:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 8, -8)
    end

    local version = C_AddOns.GetAddOnMetadata(
        "ReadyCheckConsumables",
        "Version"
    ) or "Unknown"
    local versionText = Controls.CreateText(
        frame,
        GameFontDisableSmall,
        "Version " .. version,
        570
    )
    versionText:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -360)
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

    local mainFrame = CreateFrame("Frame")
    local category, layout = Settings.RegisterCanvasLayoutCategory(
        mainFrame,
        "Ready Check Consumables"
    )
    layout:AddAnchorPoint("TOPLEFT", 35, -35)
    layout:AddAnchorPoint("BOTTOMRIGHT", -35, 35)

    ----------------------------------------------------------------------------
    --- Consumables Frame (subcategory)
    ----------------------------------------------------------------------------

    local cfFrame = RCC.ConsumableFrameSettings.CreateFrame()
    local cfCat, cfLayout = Settings.RegisterCanvasLayoutSubcategory(
        category, cfFrame, "Consumables Frame"
    )
    cfLayout:AddAnchorPoint("TOPLEFT", 35, -35)
    cfLayout:AddAnchorPoint("BOTTOMRIGHT", -35, 35)

    ----------------------------------------------------------------------------
    --- Raid Frame (subcategory — declared early for parent page buttons)
    ----------------------------------------------------------------------------

    local rfFrame = RCC.RaidFrameSettings.CreateFrame()
    local rfCat, rfLayout = Settings.RegisterCanvasLayoutSubcategory(
        category, rfFrame, "Raid Frame"
    )
    rfLayout:AddAnchorPoint("TOPLEFT", 35, -35)
    rfLayout:AddAnchorPoint("BOTTOMRIGHT", -35, 35)

    ----------------------------------------------------------------------------
    --- Chat Report (subcategory — declared early for parent page buttons)
    ----------------------------------------------------------------------------

    local crFrame = RCC.ChatReportSettings.CreateFrame()
    local crCat, crLayout = Settings.RegisterCanvasLayoutSubcategory(
        category, crFrame, "Chat Report"
    )
    crLayout:AddAnchorPoint("TOPLEFT", 35, -35)
    crLayout:AddAnchorPoint("BOTTOMRIGHT", -35, 35)

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

    populateMainSettingsFrame(mainFrame, {
        {
            label = "Consumables Frame",
            description = "Choose when the personal consumable bar opens "
                .. "and which buttons each event displays.",
            category = cfCat,
        },
        {
            label = "Raid Frame",
            description = "Configure the group consumable status grid, "
                .. "timing, and feast or cauldron tracking.",
            category = rfCat,
        },
        {
            label = "Chat Report",
            description = "Choose when RCC reports missing consumables "
                .. "and who can trigger reports.",
            category = crCat,
        },
        {
            label = "Managed Macros",
            description = "Create RCC macros that keep their selected "
                .. "consumable or spell actions up to date.",
            category = macroCat,
        },
    })

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
