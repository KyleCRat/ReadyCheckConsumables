local _, RCC = ...

local CanvasControls = LibStub("LibModernSettings-1.0")

RCC.ConsumableFrameLimits = {
    iconWidthPercent = {
        min = 50,
        max = 100,
        step = 1,
        default = 100,
    },
}

local ICON_WIDTH_LIMITS = RCC.ConsumableFrameLimits.iconWidthPercent

--------------------------------------------------------------------------------
--- Defaults
--------------------------------------------------------------------------------

local DEFAULTS = {
    -- Consumables Frame
    consumables_enabled      = true,
    consumables_scale        = 1.0,
    consumables_iconWidthPercent = ICON_WIDTH_LIMITS.default,
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
    icon_inkyBlackPotion     = false,
    icon_repair              = false,
    icon_augment             = true,
    icon_raidBuff            = true,
    icon_vantus              = true,

    -- Consumables Action Bar
    consumablesActionBar_enabled = false,
    consumablesActionBar_iconsPerRow = 10,
    consumablesActionBar_buttonWidth = 48,
    consumablesActionBar_buttonHeight = 48,
    consumablesActionBar_gapX = 2,
    consumablesActionBar_gapY = 20,
    consumablesActionBar_flyoutDirection = "UP",
    consumablesActionBar_durationTextPosition = "TOP",
    consumablesActionBar_textSize = 16,
    consumablesActionBar_showStackCount = true,
    consumablesActionBar_showDuration = true,
    consumablesActionBar_showStatus = true,
    consumablesActionBar_showProfessionQuality = true,
    consumablesActionBar_icon_food = true,
    consumablesActionBar_icon_flask = true,
    consumablesActionBar_icon_consumableStasis = true,
    consumablesActionBar_icon_mainHandTempWeaponEnchant = true,
    consumablesActionBar_icon_offHandTempWeaponEnchant = true,
    consumablesActionBar_icon_augment = true,
    consumablesActionBar_icon_raidBuff = true,
    consumablesActionBar_icon_hs = true,
    consumablesActionBar_icon_combatpot = true,
    consumablesActionBar_icon_healpot = true,
    consumablesActionBar_icon_recuperate = false,
    consumablesActionBar_icon_inkyBlackPotion = false,
    consumablesActionBar_icon_repair = false,
    consumablesActionBar_icon_vantus = false,

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

local function normalizeConsumablesIconWidthPercent(value)
    value = tonumber(value)

    if not value or value ~= value then
        return ICON_WIDTH_LIMITS.default
    end

    if value <= ICON_WIDTH_LIMITS.min then
        return ICON_WIDTH_LIMITS.min
    end

    if value >= ICON_WIDTH_LIMITS.max then
        return ICON_WIDTH_LIMITS.max
    end

    local stepIndex = math.floor(
        ((value - ICON_WIDTH_LIMITS.min) / ICON_WIDTH_LIMITS.step) + 0.5
    )

    return ICON_WIDTH_LIMITS.min + (stepIndex * ICON_WIDTH_LIMITS.step)
end

local SETTING_NORMALIZERS = {
    consumables_iconWidthPercent =
        normalizeConsumablesIconWidthPercent,
}

local function normalizeSettingValue(key, value)
    local normalizer = SETTING_NORMALIZERS[key]

    return normalizer and normalizer(value) or value
end

--------------------------------------------------------------------------------
--- Public accessor
--------------------------------------------------------------------------------

function RCC.GetSetting(key)
    local db = ReadyCheckConsumablesDB

    if not db then
        return normalizeSettingValue(key, DEFAULTS[key])
    end

    local val = db[key]

    if val == nil then
        return normalizeSettingValue(key, DEFAULTS[key])
    end

    return normalizeSettingValue(key, val)
end

function RCC.GetSettingDefault(key)
    return DEFAULTS[key]
end

function RCC.SetSettingValue(key, value)
    if not ReadyCheckConsumablesDB or DEFAULTS[key] == nil then
        return false
    end

    ReadyCheckConsumablesDB[key] = normalizeSettingValue(key, value)

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
    local macroTab = characterSpecific
        and "Character Specific Macro tab"
        or "Shared Macro tab"

    return CanvasControls:CreateButton(parent, {
        text = text,
        width = 86,
        height = 22,
        variant = "small",
        tooltip = "Create " .. label .. " macro in the " .. macroTab .. ".",
        onClick = function()
            RCC.ConsumableMacros.CreateManagedMacro(key, characterSpecific)
        end,
    })
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

local function createMacrosSettingsFrame(measurementFrame)
    local frame = CreateFrame("Frame")
    local layout = CanvasControls:CreateCanvasLayout(frame, {
        measurementFrame = measurementFrame,
    })
    local content = layout:GetContent()
    local flow = layout:GetRootFlow()
    local bodyText = "RCC macros keep action-bar buttons linked to your preferred "
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
        .. "#RCCI:cp [combat]."

    layout:AddHeader("Managed Macros", bodyText, {
        marginBottom = 18,
    })

    local macroTable = CanvasControls:CreateSettingsTable(content, {
        width = flow:GetWidth(),
        padding = layout:GetStyleValue("tablePadding"),
        headerHeight = 28,
        rowHeight = 32,
        columns = {
            { key = "name", width = 150, justifyH = "LEFT" },
            { key = "key", width = 190, justifyH = "LEFT" },
            { key = "inline", width = 85, justifyH = "LEFT" },
            { key = "create", weight = 1 },
        },
    })

    macroTable:AddHeaderText("name", "Name", {
        fontObject = GameFontNormal,
    })
    macroTable:AddHeaderText("key", "Key (Shorthand)", {
        fontObject = GameFontNormal,
    })
    macroTable:AddHeaderText("inline", "Inline", {
        fontObject = GameFontNormal,
    })
    macroTable:AddHeaderText("create", "Create", {
        fontObject = GameFontNormal,
    })

    local definitions = RCC.ConsumableMacros.GetDefinitions()

    for i = 1, #definitions do
        local definition = definitions[i]
        local key = definition.key
        local row = macroTable:AddRow()

        row:AddText("name", definition.label)
        row:AddText("key", getMacroKeyText(definition))
        row:AddText("inline", getInlineMacroText(definition))

        local createCell = row:GetCell("create")
        local buttonWidth = 86
        local buttonGap = 8
        local buttonsWidth = (buttonWidth * 2) + buttonGap
        local buttonOffset = (createCell:GetWidth() - buttonsWidth) / 2

        local sharedButton = createMacroButton(
            createCell,
            "Shared",
            key,
            definition.label,
            false
        )
        sharedButton:SetPoint("LEFT", createCell, "LEFT", buttonOffset, 0)

        local characterButton = createMacroButton(
            createCell,
            "Character",
            key,
            definition.label,
            true
        )
        characterButton:SetPoint("LEFT", sharedButton, "RIGHT", 8, 0)
    end

    flow:AddFrame(macroTable:GetFrame(), {
        marginBottom = 12,
    })
    layout:Finalize()
    frame.layout = layout

    return frame
end

local function openSettingsDestination(button)
    RCC.OpenSettings(button.settingsCategoryID)
end

local function populateMainSettingsFrame(
    frame,
    destinations,
    measurementFrame
)
    local layout = CanvasControls:CreateCanvasLayout(frame, {
        measurementFrame = measurementFrame,
    })
    local root = layout:GetRootFlow()

    layout:AddHeader(
        "Ready Check Consumables",
        "Configure RCC's personal consumable bar, raid status frame, "
            .. "chat reporting, and managed macros."
    )
    root:AddSection("Settings")

    for firstIndex = 1, #destinations, 2 do
        local columns = root:BeginColumns()

        for columnIndex = 1, 2 do
            local destination = destinations[firstIndex + columnIndex - 1]

            if destination then
                local column = columns[columnIndex]
                local button = column:AddControl("button", {
                    text = destination.label,
                    height = 34,
                    onClick = openSettingsDestination,
                }, {
                    marginBottom = 8,
                })

                button.settingsCategoryID = destination.category:GetID()
                column:AddText({
                    fontObject = GameFontHighlight,
                    text = destination.description,
                }, {
                    indent = 1,
                    marginBottom = 18,
                })
            end
        end

        columns:Finish()
    end

    local version = C_AddOns.GetAddOnMetadata(
        "ReadyCheckConsumables",
        "Version"
    ) or "Unknown"
    root:AddText({
        fontObject = GameFontDisableSmall,
        text = "Version " .. version,
    }, {
        marginTop = 20,
        marginBottom = 0,
    })
    layout:Finalize()
    frame.layout = layout
end

--------------------------------------------------------------------------------
--- Panel registration (ADDON_LOADED)
--------------------------------------------------------------------------------

local function registerPanel()
    local db = ReadyCheckConsumablesDB
    local measurementFrame = SettingsPanel:GetSettingsCanvas()

    for key, default in pairs(DEFAULTS) do
        if db[key] == nil then
            db[key] = default
        end
    end

    for key, normalizer in pairs(SETTING_NORMALIZERS) do
        db[key] = normalizer(db[key])
    end

    local mainFrame = CreateFrame("Frame")
    local category = Settings.RegisterCanvasLayoutCategory(
        mainFrame,
        "Ready Check Consumables"
    )

    ----------------------------------------------------------------------------
    --- Consumables Frame (subcategory)
    ----------------------------------------------------------------------------

    local cfFrame = RCC.ConsumableFrameSettings.CreateFrame(measurementFrame)
    local cfCat = Settings.RegisterCanvasLayoutSubcategory(
        category, cfFrame, "Consumables Frame"
    )

    ----------------------------------------------------------------------------
    --- Consumables Action Bar (subcategory)
    ----------------------------------------------------------------------------

    local actionBarFrame = RCC.ConsumableActionBarSettings.CreateFrame(
        measurementFrame
    )
    local actionBarCat = Settings.RegisterCanvasLayoutSubcategory(
        category,
        actionBarFrame,
        "Consumables Action Bar"
    )

    ----------------------------------------------------------------------------
    --- Raid Frame (subcategory — declared early for parent page buttons)
    ----------------------------------------------------------------------------

    local rfFrame = RCC.RaidFrameSettings.CreateFrame(measurementFrame)
    local rfCat = Settings.RegisterCanvasLayoutSubcategory(
        category, rfFrame, "Raid Frame"
    )

    ----------------------------------------------------------------------------
    --- Chat Report (subcategory — declared early for parent page buttons)
    ----------------------------------------------------------------------------

    local crFrame = RCC.ChatReportSettings.CreateFrame(measurementFrame)
    local crCat = Settings.RegisterCanvasLayoutSubcategory(
        category, crFrame, "Chat Report"
    )

    ----------------------------------------------------------------------------
    --- Macros (subcategory - canvas)
    ----------------------------------------------------------------------------

    local macroFrame = createMacrosSettingsFrame(measurementFrame)
    local macroCat = Settings.RegisterCanvasLayoutSubcategory(
        category, macroFrame, "Macros"
    )

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
            label = "Consumables Action Bar",
            description = "Configure the permanent clickable consumable "
                .. "bar, its geometry, position, and button slots.",
            category = actionBarCat,
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
    }, measurementFrame)

    Settings.RegisterAddOnCategory(category)
    RCC.settingsCategory = category
end

--------------------------------------------------------------------------------
--- Event wiring
--------------------------------------------------------------------------------

local settingsFrame = CreateFrame("Frame")
local pendingSettingsCategoryID

local function openSettingsCategory(categoryID)
    pendingSettingsCategoryID = nil
    settingsFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    Settings.OpenToCategory(categoryID)
end

function RCC.OpenSettings(categoryID)
    categoryID = categoryID or RCC.settingsCategory:GetID()

    if InCombatLockdown() then
        pendingSettingsCategoryID = categoryID
        settingsFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        print(
            "|" .. RCC.color .. "ffReadyCheckConsumables|r: "
                .. "Can't open settings in combat. They will open when "
                .. "combat ends."
        )

        return false
    end

    openSettingsCategory(categoryID)

    return true
end

settingsFrame:RegisterEvent("ADDON_LOADED")
settingsFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_ENABLED" then
        if InCombatLockdown() then
            return
        end

        local categoryID = pendingSettingsCategoryID

        if categoryID then
            openSettingsCategory(categoryID)
        else
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        end

        return
    end

    local addonName = ...

    if addonName ~= "ReadyCheckConsumables" then return end

    self:UnregisterEvent("ADDON_LOADED")
    ReadyCheckConsumablesDB = ReadyCheckConsumablesDB or {}
    ReadyCheckConsumablesDB.consumableItemCache =
        ReadyCheckConsumablesDB.consumableItemCache or {}
    registerPanel()
end)
