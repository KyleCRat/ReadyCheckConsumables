local _, RCC = ...

RCC.RaidFrameColumns = RCC.RaidFrameColumns or {}
local Columns = RCC.RaidFrameColumns

local Broadcast      = RCC.RaidFrameBroadcast
local DisplayContext = RCC.DisplayContext
local db             = RCC.db
local F              = RCC.F
local FoodAuras      = RCC.FoodAuras
local Cauldron       = RCC.RaidFrameCauldron
local Renderers      = RCC.RaidFrameColumnRenderers
local RaidBuffStatus = RCC.RaidBuffStatus
local Timing         = RCC.ConsumableTiming
local Visibility     = RCC.ContextualVisibility

local ICON_SIZE                  = 26
local NAME_WIDTH                 = 150
local RC_ICON_WIDTH              = 24
local TIME_WIDTH                 = 30
local H_PAD                      = 3
local FRAME_PAD                  = 3
local DURABILITY_WIDTH           = 42
local PROVISION_NAME_X           = H_PAD
local CAULDRON_WIDTH             = 58
local CAULDRON_COUNT_WIDTH       = 28
local NO_DURATION                = 0
local FOOD_AURA_TYPE = FoodAuras.Type
local TEMP_WEAPON_ENCHANT_STATUS = Broadcast.TempWeaponEnchantStatus
local Reason = RCC.DisplayReason

local COLUMN_TYPE = {
    TIMED      = "timed",
    ICON       = "icon",
    RAID_BUFF  = "raidBuff",
    DURABILITY = "durability",
    CAULDRON   = "cauldron",
}

local DATA_SOURCE = {
    AURA                 = "aura",
    TEMP_WEAPON_ENCHANT  = "tempWeaponEnchant",
    RAID_BUFF            = "raidBuff",
    DURABILITY           = "durability",
    CAULDRON             = "cauldron",
}

Columns.COLUMN_TYPE = COLUMN_TYPE
Columns.DATA_SOURCE = DATA_SOURCE
Columns.RULES = {
    noDuration          = NO_DURATION,
    durabilityThreshold = 50,
}

local CREATE_CELL_BY_COLUMN_TYPE = {
    [COLUMN_TYPE.TIMED]      = Renderers.TIMED.CreateCell,
    [COLUMN_TYPE.ICON]       = Renderers.ICON.CreateCell,
    [COLUMN_TYPE.RAID_BUFF]  = Renderers.RAID_BUFF.CreateCell,
    [COLUMN_TYPE.DURABILITY] = Renderers.DURABILITY.CreateCell,
    [COLUMN_TYPE.CAULDRON]   = Renderers.CAULDRON.CreateCell,
}

local RENDER_CELL_BY_DATA_SOURCE = {
    [DATA_SOURCE.AURA] = {
        [COLUMN_TYPE.TIMED] = Renderers.TIMED.RenderAuraCell,
        [COLUMN_TYPE.ICON]  = Renderers.ICON.RenderAuraCell,
    },
    [DATA_SOURCE.TEMP_WEAPON_ENCHANT] = {
        [COLUMN_TYPE.TIMED] = Renderers.TIMED.RenderTempWeaponEnchantCell,
    },
    [DATA_SOURCE.RAID_BUFF] = {
        [COLUMN_TYPE.RAID_BUFF] = Renderers.RAID_BUFF.RenderCell,
    },
    [DATA_SOURCE.DURABILITY] = {
        [COLUMN_TYPE.DURABILITY] = Renderers.DURABILITY.RenderCell,
    },
    [DATA_SOURCE.CAULDRON] = {
        [COLUMN_TYPE.CAULDRON] = Renderers.CAULDRON.RenderCell,
    },
}

local RAID_BUFF_COUNT = RaidBuffStatus.GetCount()

local READY_CHECK_VISIBILITY = {
    reasons = {
        [Reason.READY_CHECK] = true,
    },
}

local FOOD_VISIBILITY = {
    reasons = {
        [Reason.READY_CHECK] = true,
        [Reason.FEAST_DROP] = true,
    },
}

local CAULDRON_VISIBILITY = {
    reasons = {
        [Reason.READY_CHECK] = true,
        [Reason.CAULDRON_DROP] = true,
    },
    IsApplicable = function(_, _, definition)
        return Cauldron.IsActive(definition.cauldronKind)
    end,
}

--------------------------------------------------------------------------------
--- Shared helpers
--------------------------------------------------------------------------------

local function getColumnData(member, column)
    return member.columnData and member.columnData[column.key]
end

local storeAuraID = F.StoreAuraID

local function setTimedAuraData(data, aura, remaining)
    data.available = true
    data.has     = true
    data.time    = remaining
    data.iconID  = F.GetPublicAuraField(aura, "icon")
    data.spellID = F.GetPublicAuraField(aura, "spellID")
    data.source  = "aura"
    storeAuraID(data, aura)
end

local function setTimedExternalData(data, source)
    if data.has and data.source == "aura" then
        return
    end

    data.available = true
    data.has     = source ~= nil and source.has == true
    data.time    = source and source.time or 0
    data.iconID  = source and source.iconID or nil
    data.spellID = source and source.spellID or nil
    data.auraID  = nil
    data.source  = "broadcast"
end

local function setIconAuraData(data, aura)
    data.available = true
    data.has     = true
    data.iconID  = F.GetPublicAuraField(aura, "icon")
    data.spellID = F.GetPublicAuraField(aura, "spellID")
    storeAuraID(data, aura)
end

local function isTimedDataBad(data, rules)
    if not data or not data.has then
        return true
    end

    if not data.time or data.time == rules.noDuration then
        return false
    end

    return Timing.IsExpiringSoon(data.time)
end

--------------------------------------------------------------------------------
--- Food Column
--------------------------------------------------------------------------------

local function createFoodData()
    return {
        available = false,
        has     = false,
        time    = 0,
        auraID  = nil,
        iconID  = nil,
        spellID = nil,
        source  = nil,
    }
end

local function refreshFoodDisplayData(data, rules)
    -- Show Eating/Drinking while the real Well Fed state still needs refresh.
    local displayData = data.wellFed
    local isEating = false

    if data.eating.has and isTimedDataBad(data.wellFed, rules) then
        displayData = data.eating
        isEating = true
    end

    data.has      = displayData.has
    data.time     = displayData.time
    data.auraID   = displayData.auraID
    data.iconID   = displayData.iconID
    data.spellID  = displayData.spellID
    data.source   = displayData.source
    data.isEating = isEating
    data.available = displayData.available == true
end

local function collectFoodAura(data, aura, scanContext)
    local auraType = FoodAuras.GetType(aura)

    if not auraType then
        return
    end

    data.wellFed = data.wellFed or createFoodData()
    data.eating  = data.eating or createFoodData()

    if auraType == FOOD_AURA_TYPE.EATING then
        setTimedAuraData(data.eating, aura, scanContext.remaining)
    else
        setTimedAuraData(data.wellFed, aura, scanContext.remaining)
    end

    refreshFoodDisplayData(data, scanContext.rules)
end

local function isFoodBad(member, context, column)
    local data = getColumnData(member, column)

    if not data or data.available ~= true then
        return false
    end

    if data and data.wellFed then
        return isTimedDataBad(data.wellFed, context.rules)
    end

    return isTimedDataBad(data, context.rules)
end

local function syncFoodData(data, member, context)
    local playerKey = member.key
    local entry = playerKey and context.shared.foodData[playerKey]

    if not entry then
        return
    end

    data.wellFed = data.wellFed or createFoodData()
    data.eating  = data.eating or createFoodData()

    setTimedExternalData(data.wellFed, entry.wellFed)
    setTimedExternalData(data.eating, entry.eating)
    refreshFoodDisplayData(data, context.rules)
end

local foodColumn = {
    columnType        = COLUMN_TYPE.TIMED,
    dataSource        = DATA_SOURCE.AURA,
    key               = "food",
    visibility        = FOOD_VISIBILITY,
    iconID            = db.foodIconID,
    statusName        = "Food",
    inProgressTooltip =
        "This player is eating, but has not gained Well Fed yet.",
    CreateData        = createFoodData,
    CollectAura       = collectFoodAura,
    SyncData          = syncFoodData,
    IsBad             = isFoodBad,
}

--------------------------------------------------------------------------------
--- Flask Column
--------------------------------------------------------------------------------

local function createFlaskData()
    return {
        available = false,
        has     = false,
        time    = 0,
        auraID  = nil,
        iconID  = nil,
        spellID = nil,
        source  = nil,
    }
end

local function collectFlaskAura(data, aura, scanContext)
    local spellID = aura.spellID

    if not spellID or data.has or not db.flaskBuffIDs[spellID] then
        return
    end

    setTimedAuraData(data, aura, scanContext.remaining)
end

local function isFlaskBad(member, context, column)
    local data = getColumnData(member, column)

    return data and data.available == true
        and isTimedDataBad(data, context.rules)
end

local function syncFlaskData(data, member, context)
    local playerKey = member.key
    local entry = playerKey and context.shared.flaskData[playerKey]

    if not entry then
        return
    end

    setTimedExternalData(data, entry)
end

local flaskColumn = {
    columnType   = COLUMN_TYPE.TIMED,
    dataSource   = DATA_SOURCE.AURA,
    key          = "flask",
    visibility   = READY_CHECK_VISIBILITY,
    iconID       = db.flaskIconID,
    statusName   = "Flask",
    CreateData   = createFlaskData,
    CollectAura  = collectFlaskAura,
    SyncData     = syncFlaskData,
    IsBad        = isFlaskBad,
}

--------------------------------------------------------------------------------
--- Temp Weapon Enchant Column
--------------------------------------------------------------------------------

local function createTempWeaponEnchantData()
    return {
        has     = false,
        time    = nil,
        itemID  = nil,
        spellID = nil,
        iconID  = nil,
    }
end

local function syncTempWeaponEnchantData(data, member, context)
    local playerKey = member.key

    if not playerKey then
        data.has     = false
        data.time    = nil
        data.itemID  = nil
        data.spellID = nil
        data.iconID  = nil

        return
    end

    local entry = context.shared.tempWeaponEnchantData[playerKey]
    local time = entry and entry.time
    local itemID = entry and entry.itemID
    local spellID = entry and entry.spellID
    local iconID = entry and entry.iconID

    data.has     = time and time > 0 or false
    data.time    = time
    data.itemID  = itemID and itemID > 0 and itemID or nil
    data.spellID = spellID and spellID > 0 and spellID or nil
    data.iconID  = iconID and iconID > 0 and iconID or nil
end

local function isTempWeaponEnchantBad(member, context, column)
    local data = getColumnData(member, column)
    local time = data and data.time

    -- Header aggregation treats missing data and UNKNOWN as neutral because
    -- neither confirms a failure. MISSING and NO_WEAPON are confirmed bad.
    if time == nil
        or time == TEMP_WEAPON_ENCHANT_STATUS.UNKNOWN
    then
        return false
    end

    return time == TEMP_WEAPON_ENCHANT_STATUS.MISSING
        or time == TEMP_WEAPON_ENCHANT_STATUS.NO_WEAPON
        or Timing.IsExpiringSoon(time)
end

local tempWeaponEnchantColumn = {
    columnType      = COLUMN_TYPE.TIMED,
    dataSource      = DATA_SOURCE.TEMP_WEAPON_ENCHANT,
    key             = "tempWeaponEnchant",
    visibility      = READY_CHECK_VISIBILITY,
    iconID          = db.weaponEnchantIconID,
    statusName      = "Weapon Enchant",
    CreateData      = createTempWeaponEnchantData,
    SyncData        = syncTempWeaponEnchantData,
    IsBad           = isTempWeaponEnchantBad,
}

--------------------------------------------------------------------------------
--- Augment Rune Column
--------------------------------------------------------------------------------

local function createAugmentData()
    return {
        available = false,
        has     = false,
        auraID  = nil,
        iconID  = nil,
        spellID = nil,
    }
end

local function collectAugmentAura(data, aura)
    local spellID = aura.spellID

    if not spellID or data.has or not db.augmentBuffIDs[spellID] then
        return
    end

    setIconAuraData(data, aura)
end

local function isAugmentBad(member, context, column)
    local data = getColumnData(member, column)

    return data and data.available == true and not data.has
end

local augmentColumn = {
    columnType   = COLUMN_TYPE.ICON,
    dataSource   = DATA_SOURCE.AURA,
    key          = "augment",
    visibility   = READY_CHECK_VISIBILITY,
    iconID       = db.augmentIconID,
    statusName   = "Augment Rune",
    CreateData   = createAugmentData,
    CollectAura  = collectAugmentAura,
    IsBad        = isAugmentBad,
}

--------------------------------------------------------------------------------
--- Vantus Rune Column
--------------------------------------------------------------------------------

local function createVantusData()
    return {
        available = false,
        has     = false,
        auraID  = nil,
        iconID  = nil,
        spellID = nil,
    }
end

local function collectVantusAura(data, aura)
    local spellID = aura.spellID

    if not spellID or data.has or not db.vantusBuffIDs[spellID] then
        return
    end

    setIconAuraData(data, aura)
end

local function isVantusBad(member, context, column)
    local data = getColumnData(member, column)

    return data and data.available == true and not data.has
end

local vantusColumn = {
    columnType   = COLUMN_TYPE.ICON,
    dataSource   = DATA_SOURCE.AURA,
    key          = "vantus",
    visibility   = READY_CHECK_VISIBILITY,
    iconID       = db.vantusIconID,
    statusName   = "Vantus Rune",
    CreateData   = createVantusData,
    CollectAura  = collectVantusAura,
    IsBad        = isVantusBad,
}

--------------------------------------------------------------------------------
--- Raid Buff Columns
--------------------------------------------------------------------------------

local function createRaidBuffData()
    return RaidBuffStatus.CreateData()
end

local function collectRaidBuffAura(data, aura, _, column)
    RaidBuffStatus.CollectAura(data, aura, column.index)
end

local function isRaidBuffBad(member, context, column)
    local data = getColumnData(member, column)

    return RaidBuffStatus.IsMissing(data)
end

local function createRaidBuffColumn(raidBuffIndex)
    local buffInfo = RaidBuffStatus.GetInfo(raidBuffIndex)

    return {
        columnType         = COLUMN_TYPE.RAID_BUFF,
        dataSource         = DATA_SOURCE.RAID_BUFF,
        key                = "raidBuff" .. raidBuffIndex,
        index              = raidBuffIndex,
        visibility         = READY_CHECK_VISIBILITY,
        iconID             = buffInfo.iconID,
        spellID            = buffInfo.spellID,
        statusName         = buffInfo.label,
        CreateData         = createRaidBuffData,
        CollectAura        = collectRaidBuffAura,
        IsBad              = isRaidBuffBad,
    }
end

local raidBuffColumns = {
    isColumnGroup = true,
}

for raidBuffIndex = 1, RAID_BUFF_COUNT do
    raidBuffColumns[#raidBuffColumns + 1] = createRaidBuffColumn(raidBuffIndex)
end

--------------------------------------------------------------------------------
--- Durability Column
--------------------------------------------------------------------------------

local function createDurabilityData()
    return {
        has     = false,
        percent = nil,
    }
end

local function syncDurabilityData(data, member, context)
    local playerKey = member.key

    if not playerKey then
        data.has     = false
        data.percent = nil

        return
    end

    local percent = context.shared.durabilityData[playerKey]

    data.has     = percent ~= nil
    data.percent = percent
end

local function isDurabilityBad(member, context, column)
    local data = getColumnData(member, column)
    local pct = data and data.percent

    if not pct then
        return false
    end

    return pct <= context.rules.durabilityThreshold
end

local durabilityColumn = {
    columnType  = COLUMN_TYPE.DURABILITY,
    dataSource  = DATA_SOURCE.DURABILITY,
    key         = "durability",
    visibility  = READY_CHECK_VISIBILITY,
    statusName  = "Durability",
    CreateData  = createDurabilityData,
    SyncData    = syncDurabilityData,
    IsBad       = isDurabilityBad,
}

--------------------------------------------------------------------------------
--- Cauldron Columns
--------------------------------------------------------------------------------

local function isCauldronBad(member, _, column)
    if not member or not member.key then
        return true
    end

    return Cauldron.GetCount(member.key, column.cauldronKind)
        ~= Cauldron.GetTarget(column.cauldronKind)
end

local cauldronFlaskColumn = {
    columnType            = COLUMN_TYPE.CAULDRON,
    dataSource            = DATA_SOURCE.CAULDRON,
    key                   = "cauldronFlask",
    visibility            = CAULDRON_VISIBILITY,
    cauldronKind          = Cauldron.KIND_FLASK,
    iconID                = db.flaskIconID,
    statusName            = "Flasks",
    includeOfflineInTitle = true,
    IsBad                 = isCauldronBad,
}

local cauldronPotionColumn = {
    columnType            = COLUMN_TYPE.CAULDRON,
    dataSource            = DATA_SOURCE.CAULDRON,
    key                   = "cauldronPotion",
    visibility            = CAULDRON_VISIBILITY,
    cauldronKind          = Cauldron.KIND_POTION,
    iconID                = db.combatPotionIconID,
    statusName            = "Potions",
    includeOfflineInTitle = true,
    IsBad                 = isCauldronBad,
}

--------------------------------------------------------------------------------
--- Public API
--------------------------------------------------------------------------------

local function createColumnData(layout)
    local columnData = {
        auraScanAvailable = false,
        rccPresent        = false,
    }

    for columnIndex = 1, #layout.columns do
        local column = layout.columns[columnIndex]

        if column.CreateData then
            columnData[column.key] = column.CreateData(column)
        end
    end

    return columnData
end

function Columns.CreateColumnData(layout)
    return createColumnData(layout)
end

function Columns.GetDefinitions(layout)
    return layout.columns
end

function Columns.CreateCell(row, column, layout, options)
    local createCell = CREATE_CELL_BY_COLUMN_TYPE[column.columnType]

    if not createCell then
        error("Raid frame column has no cell creator: " .. tostring(column.key), 2)
    end

    createCell(row, column, layout, options)
end

function Columns.RenderCell(row, member, column, context)
    local renderers = RENDER_CELL_BY_DATA_SOURCE[column.dataSource]
    local renderCell = renderers and renderers[column.columnType]

    if not renderCell then
        error("Raid frame column has no renderer: " .. tostring(column.key), 2)
    end

    renderCell(row, member, column, context)
end

function Columns.SetCellShown(row, column, shown)
    local cell = row.cells and row.cells[column.key]

    Renderers.SetCellShown(cell, shown)
end

function Columns.PositionCell(row, column, layout)
    Renderers.PositionCell(row, column, layout)
end

function Columns.ScanUnitData(unit, now, layout, context, scanColumns)
    local columnData = createColumnData(layout)
    local rules = context.rules
    local columns = scanColumns or layout.activeColumns
    local scanContext = {
        remaining = rules.noDuration,
        rules     = rules,
    }

    local scanAvailable = F.ForEachHelpfulAura(unit, function(aura)
        scanContext.remaining = F.GetAuraRemaining(
            aura.expirationTime,
            now
        ) or rules.noDuration

        for columnIndex = 1, #columns do
            local column = columns[columnIndex]

            if column.CollectAura then
                column.CollectAura(
                    columnData[column.key],
                    aura,
                    scanContext,
                    column
                )
            end
        end
    end)

    if not scanAvailable then
        columnData = createColumnData(layout)
        columnData.auraScanAvailable = false

        return columnData
    end

    columnData.auraScanAvailable = true

    for columnIndex = 1, #columns do
        local column = columns[columnIndex]

        if column.CollectAura then
            local data = columnData[column.key]

            if data then
                data.available = true

                if data.wellFed then
                    data.wellFed.available = true
                end

                if data.eating then
                    data.eating.available = true
                end
            end
        end
    end

    return columnData
end

function Columns.SyncExternalData(member, layout, context)
    if not member then
        return
    end

    member.columnData = member.columnData or createColumnData(layout)
    member.columnData.rccPresent = member.key ~= nil
        and context.shared.presenceData[member.key] ~= nil

    for columnIndex = 1, #layout.activeColumns do
        local column = layout.activeColumns[columnIndex]

        if column.SyncData then
            local data = member.columnData[column.key]

            if not data then
                data = column.CreateData(column)
                member.columnData[column.key] = data
            end

            column.SyncData(data, member, context, column)
        end
    end
end

local function copyColumn(definition)
    local copy = {}

    for key, value in pairs(definition) do
        copy[key] = value
    end

    return copy
end

local function createColumns()
    -- This list is the raid-frame column order from left to right.
    local definitions = {
        foodColumn,
        flaskColumn,
        tempWeaponEnchantColumn,
        augmentColumn,
        vantusColumn,
        raidBuffColumns,
        durabilityColumn,
        cauldronFlaskColumn,
        cauldronPotionColumn,
    }

    local columns = {}

    for definitionIndex = 1, #definitions do
        local definition = definitions[definitionIndex]

        if definition.isColumnGroup then
            for groupIndex = 1, #definition do
                columns[#columns + 1] = copyColumn(
                    definition[groupIndex]
                )
            end
        else
            columns[#columns + 1] = copyColumn(definition)
        end
    end

    return columns
end

local function positionColumn(layout, column, startX)
    if column.columnType == COLUMN_TYPE.TIMED then
        column.timeX = startX
        column.iconX = startX + layout.timeWidth
        column.titleX = column.iconX

        return column.iconX + layout.iconSize + H_PAD
    elseif column.columnType == COLUMN_TYPE.CAULDRON then
        column.countX = startX
        column.iconX = startX + layout.cauldronCountWidth + 2
        column.titleX = column.iconX

        return startX + layout.cauldronWidth + H_PAD
    elseif column.columnType == COLUMN_TYPE.DURABILITY then
        column.textX = startX
        column.titleX = startX
            + (layout.durabilityWidth - layout.iconSize) / 2

        return startX + layout.durabilityWidth + H_PAD
    end

    column.iconX = startX
    column.titleX = startX

    return startX + layout.iconSize + H_PAD
end

function Columns.ConfigureLayout(layout, context)
    local showReadyIcon = DisplayContext.IsActive(
        context,
        Reason.READY_CHECK
    )
    local nameX = showReadyIcon
        and layout.rcIconWidth + H_PAD
        or PROVISION_NAME_X
    local nextX = nameX + layout.nameWidth + H_PAD

    wipe(layout.activeColumns)

    for columnIndex = 1, #layout.columns do
        local column = layout.columns[columnIndex]

        if Visibility.IsVisible(column, context) then
            layout.activeColumns[#layout.activeColumns + 1] = column
            nextX = positionColumn(layout, column, nextX)
        end
    end

    layout.showReadyIcon = showReadyIcon
    layout.frameWidth = nextX + layout.framePad * 2
    layout.x.readyIconCenter = layout.rcIconWidth / 2
    layout.x.name = nameX
end

function Columns.CreateLayout(context)
    local columns = createColumns()
    local columnsByKey = {}

    for i = 1, #columns do
        columnsByKey[columns[i].key] = columns[i]
    end

    local layout = {
        raidBuffCount       = RAID_BUFF_COUNT,
        frameWidth          = 0,
        framePad            = FRAME_PAD,
        iconSize            = ICON_SIZE,
        rcIconWidth         = RC_ICON_WIDTH,
        nameWidth           = NAME_WIDTH,
        timeWidth           = TIME_WIDTH,
        durabilityWidth     = DURABILITY_WIDTH,
        cauldronWidth       = CAULDRON_WIDTH,
        cauldronCountWidth  = CAULDRON_COUNT_WIDTH,
        showReadyIcon       = false,
        x                   = {},
        columns             = columns,
        columnsByKey        = columnsByKey,
        broadcastColumns    = {
            columnsByKey.food,
            columnsByKey.flask,
        },
        activeColumns       = {},
    }

    local constructionX = layout.rcIconWidth
        + H_PAD
        + layout.nameWidth
        + H_PAD

    for i = 1, #layout.columns do
        constructionX = positionColumn(
            layout,
            layout.columns[i],
            constructionX
        )
    end

    if not context then
        context = DisplayContext.Create(RCC.DisplaySurface.RAID_FRAME)
        DisplayContext.Activate(context, Reason.READY_CHECK)
    end

    Columns.ConfigureLayout(layout, context)

    return layout
end
