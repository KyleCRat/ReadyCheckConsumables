local _, RCC = ...

local CanvasControls = LibStub("LibModernSettings-1.0")

--------------------------------------------------------------------------------
--- Shared settings layout
--------------------------------------------------------------------------------

local SettingsLayout = {
    CANVAS_WIDTH = 716,
    CANVAS_HEIGHT = 633,
    CONTENT_INSET = 8,
    SCROLLBAR_GAP = 8,
    SCROLLBAR_WIDTH = 17,
    COLUMN_GAP = 15,
    INDENT = 16,
    NESTED_GAP = 8,
    TABLE_PADDING = 8,
}

local function calculateSettingsLayout()
    SettingsLayout.CONTENT_WIDTH = SettingsLayout.CANVAS_WIDTH
        - SettingsLayout.CONTENT_INSET
        - SettingsLayout.SCROLLBAR_GAP
        - SettingsLayout.SCROLLBAR_WIDTH
    SettingsLayout.COLUMN_WIDTH =
        (SettingsLayout.CONTENT_WIDTH - SettingsLayout.COLUMN_GAP) / 2
    SettingsLayout.RIGHT_COLUMN_X = SettingsLayout.COLUMN_WIDTH
        + SettingsLayout.COLUMN_GAP
    SettingsLayout.INDENTED_COLUMN_WIDTH = SettingsLayout.COLUMN_WIDTH
        - SettingsLayout.INDENT
    SettingsLayout.NESTED_COLUMN_WIDTH =
        (SettingsLayout.INDENTED_COLUMN_WIDTH - SettingsLayout.NESTED_GAP) / 2
end

function SettingsLayout.ConfigureForCanvas(canvas)
    -- Blizzard's Settings canvas is fixed-size. Measure it once while the
    -- categories are registered; pages do not switch or collapse columns.
    if canvas then
        local width = canvas:GetWidth()
        local height = canvas:GetHeight()

        if width and width > 0 then
            SettingsLayout.CANVAS_WIDTH = width
        end
        if height and height > 0 then
            SettingsLayout.CANVAS_HEIGHT = height
        end
    end

    calculateSettingsLayout()
end

calculateSettingsLayout()

function SettingsLayout.CreateContentFrame(parent, height)
    local content = CreateFrame("Frame", nil, parent)

    content:SetSize(
        SettingsLayout.CONTENT_WIDTH,
        height or SettingsLayout.CANVAS_HEIGHT
    )
    content:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        SettingsLayout.CONTENT_INSET,
        0
    )

    return content
end

function SettingsLayout.CreateScrollBox(
    parent,
    contentHeight,
    topInset,
    bottomInset
)
    topInset = topInset or 0
    bottomInset = bottomInset or 0

    local scrollBox = CreateFrame("Frame", nil, parent, "WowScrollBox")

    scrollBox:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        SettingsLayout.CONTENT_INSET,
        -topInset
    )
    scrollBox:SetPoint(
        "BOTTOMRIGHT",
        parent,
        "BOTTOMRIGHT",
        -(SettingsLayout.SCROLLBAR_GAP + SettingsLayout.SCROLLBAR_WIDTH),
        bottomInset
    )

    local scrollBar = CreateFrame(
        "EventFrame",
        nil,
        parent,
        "MinimalScrollBar"
    )

    scrollBar:SetWidth(SettingsLayout.SCROLLBAR_WIDTH)
    scrollBar:SetPoint(
        "TOPLEFT",
        scrollBox,
        "TOPRIGHT",
        SettingsLayout.SCROLLBAR_GAP,
        0
    )
    scrollBar:SetPoint(
        "BOTTOMLEFT",
        scrollBox,
        "BOTTOMRIGHT",
        SettingsLayout.SCROLLBAR_GAP,
        0
    )

    local content = CreateFrame("Frame", nil, scrollBox)

    content.scrollable = true
    content:SetSize(SettingsLayout.CONTENT_WIDTH, contentHeight)

    local view = CreateScrollBoxLinearView()

    view:SetPanExtent(40)
    ScrollUtil.InitScrollBoxWithScrollBar(scrollBox, scrollBar, view)

    return scrollBox, content, scrollBar
end

RCC.SettingsLayout = SettingsLayout

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

local function createMacrosSettingsFrame()
    local frame = CreateFrame("Frame")
    frame:SetSize(SettingsLayout.CANVAS_WIDTH, SettingsLayout.CANVAS_HEIGHT)

    local content = SettingsLayout.CreateContentFrame(frame)

    local title = CanvasControls:CreateText(content, {
        fontObject = GameFontNormalLarge,
        text = "Managed Macros",
        width = SettingsLayout.CONTENT_WIDTH,
    })
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -8)

    local body = CanvasControls:CreateText(content, {
        fontObject = GameFontHighlight,
        text = "RCC macros keep action-bar buttons linked to your preferred "
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
        width = SettingsLayout.CONTENT_WIDTH,
    })
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)

    local nameHeader = CanvasControls:CreateText(content, {
        fontObject = GameFontNormal,
        text = "Name",
        width = 150,
    })
    nameHeader:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -20)

    local keyHeader = CanvasControls:CreateText(content, {
        fontObject = GameFontNormal,
        text = "Key (Shorthand)",
        width = 190,
    })
    keyHeader:SetPoint("TOPLEFT", nameHeader, "TOPLEFT", 150, 0)

    local inlineHeader = CanvasControls:CreateText(content, {
        fontObject = GameFontNormal,
        text = "Inline",
        width = 85,
    })
    inlineHeader:SetPoint("TOPLEFT", nameHeader, "TOPLEFT", 340, 0)

    local createHeader = CanvasControls:CreateText(content, {
        fontObject = GameFontNormal,
        text = "Create",
        width = 202,
    })
    createHeader:SetPoint("TOPLEFT", nameHeader, "TOPLEFT", 425, 0)

    local rowHeight = 28
    local definitions = RCC.ConsumableMacros.GetDefinitions()

    for i = 1, #definitions do
        local definition = definitions[i]
        local key = definition.key
        local label = CanvasControls:CreateText(content, {
            fontObject = GameFontHighlight,
            text = definition.label,
            width = 150,
        })
        label:SetPoint(
            "TOPLEFT",
            nameHeader,
            "BOTTOMLEFT",
            0,
            -14 - ((i - 1) * rowHeight)
        )

        local marker = CanvasControls:CreateText(content, {
            fontObject = GameFontHighlight,
            text = getMacroKeyText(definition),
            width = 190,
        })
        marker:SetPoint("TOPLEFT", label, "TOPLEFT", 150, 0)

        local inlineMarker = CanvasControls:CreateText(content, {
            fontObject = GameFontHighlight,
            text = getInlineMacroText(definition),
            width = 85,
        })
        inlineMarker:SetPoint("TOPLEFT", label, "TOPLEFT", 340, 0)

        local sharedButton = createMacroButton(
            content,
            "Shared",
            key,
            definition.label,
            false
        )
        sharedButton:SetPoint("TOPLEFT", label, "TOPLEFT", 425, -2)

        local characterButton = createMacroButton(
            content,
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
    local positions = {
        { x = 0, y = -126 },
        { x = SettingsLayout.RIGHT_COLUMN_X, y = -126 },
        { x = 0, y = -230 },
        { x = SettingsLayout.RIGHT_COLUMN_X, y = -230 },
    }

    frame:SetSize(SettingsLayout.CANVAS_WIDTH, SettingsLayout.CANVAS_HEIGHT)

    local content = SettingsLayout.CreateContentFrame(frame)

    local title = CanvasControls:CreateText(content, {
        fontObject = GameFontNormalLarge,
        text = "Ready Check Consumables",
        width = SettingsLayout.CONTENT_WIDTH,
    })
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -8)

    local description = CanvasControls:CreateText(content, {
        fontObject = GameFontHighlight,
        text = "Configure RCC's personal consumable bar, raid status frame, "
            .. "chat reporting, and managed macros.",
        width = SettingsLayout.CONTENT_WIDTH,
    })
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)

    local sectionTitle = CanvasControls:CreateText(content, {
        fontObject = GameFontNormal,
        text = "Settings",
        width = SettingsLayout.CONTENT_WIDTH,
    })
    sectionTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -96)

    for i = 1, #destinations do
        local destination = destinations[i]
        local position = positions[i]
        local button = CanvasControls:CreateButton(content, {
            text = destination.label,
            width = SettingsLayout.COLUMN_WIDTH,
            height = 34,
            onClick = openSettingsDestination,
        })
        button.settingsCategoryID = destination.category:GetID()
        button:SetPoint(
            "TOPLEFT",
            content,
            "TOPLEFT",
            position.x,
            position.y
        )

        local detail = CanvasControls:CreateText(content, {
            fontObject = GameFontHighlight,
            text = destination.description,
            width = SettingsLayout.INDENTED_COLUMN_WIDTH,
        })
        detail:SetPoint(
            "TOPLEFT",
            button,
            "BOTTOMLEFT",
            SettingsLayout.INDENT,
            -8
        )
    end

    local version = C_AddOns.GetAddOnMetadata(
        "ReadyCheckConsumables",
        "Version"
    ) or "Unknown"
    local versionText = CanvasControls:CreateText(content, {
        fontObject = GameFontDisableSmall,
        text = "Version " .. version,
        width = SettingsLayout.CONTENT_WIDTH,
    })
    versionText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -360)
end

--------------------------------------------------------------------------------
--- Panel registration (ADDON_LOADED)
--------------------------------------------------------------------------------

local function registerPanel()
    local db = ReadyCheckConsumablesDB

    SettingsLayout.ConfigureForCanvas(
        SettingsPanel and SettingsPanel:GetSettingsCanvas()
    )

    for key, default in pairs(DEFAULTS) do
        if db[key] == nil then
            db[key] = default
        end
    end

    local mainFrame = CreateFrame("Frame")
    local category = Settings.RegisterCanvasLayoutCategory(
        mainFrame,
        "Ready Check Consumables"
    )

    ----------------------------------------------------------------------------
    --- Consumables Frame (subcategory)
    ----------------------------------------------------------------------------

    local cfFrame = RCC.ConsumableFrameSettings.CreateFrame()
    local cfCat = Settings.RegisterCanvasLayoutSubcategory(
        category, cfFrame, "Consumables Frame"
    )

    ----------------------------------------------------------------------------
    --- Raid Frame (subcategory — declared early for parent page buttons)
    ----------------------------------------------------------------------------

    local rfFrame = RCC.RaidFrameSettings.CreateFrame()
    local rfCat = Settings.RegisterCanvasLayoutSubcategory(
        category, rfFrame, "Raid Frame"
    )

    ----------------------------------------------------------------------------
    --- Chat Report (subcategory — declared early for parent page buttons)
    ----------------------------------------------------------------------------

    local crFrame = RCC.ChatReportSettings.CreateFrame()
    local crCat = Settings.RegisterCanvasLayoutSubcategory(
        category, crFrame, "Chat Report"
    )

    ----------------------------------------------------------------------------
    --- Macros (subcategory - canvas)
    ----------------------------------------------------------------------------

    local macroFrame = createMacrosSettingsFrame()
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
