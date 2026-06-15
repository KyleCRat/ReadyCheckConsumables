local _, RCC = ...

RCC.RaidFrameRows = RCC.RaidFrameRows or {}
local Rows = RCC.RaidFrameRows

local Columns = RCC.RaidFrameColumns
local UI = RCC.UI
local F = RCC.F
local ReadyCheck = RCC.RaidFrameReadyCheck

local ROW_HEIGHT           = 30
local V_PAD                = 0
local MAX_ROWS             = 40
local DEFAULT_VISIBLE_ROWS = 5
local FONT_SIZE_NAME       = 16

local COLOR_NAME_NORMAL  = { r = 1,   g = 1,   b = 1   }
local COLOR_NAME_OFFLINE = { r = 0.5, g = 0.5, b = 0.5 }
local COLOR_NAME_DEAD    = { r = 0.8, g = 0.2, b = 0.2 }

local RC_TEXTURE_OFFLINE = "Interface\\CharacterFrame\\Disconnect-Icon"
local RC_ATLAS_DEAD      = "Navigation-Tombstone-Icon"

local function getFrameHeight(rows, layout, activeCount)
    return layout.framePad * 2
        + rows.titleHeight + layout.framePad
        + activeCount * rows.rowHeight
        + (activeCount > 1 and (activeCount - 1) * rows.vPad or 0)
end

local function createRow(parent, titleBar, rows, index, layout, options)
    local row = CreateFrame("Frame", nil, parent)
    local x = layout.x

    row:SetSize(layout.frameWidth - layout.framePad * 2, options.rowHeight)
    row:Hide()

    row.rcIcon = row:CreateTexture(nil, "ARTWORK")
    row.rcIcon:SetPoint("CENTER", row, "LEFT", x.readyIconCenter, 0)
    row.rcIcon:SetSize(layout.rcIconWidth, layout.rcIconWidth)
    row.rcIcon:SetTexture(ReadyCheck.TEXTURES[ReadyCheck.PENDING])

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints(row)
    row.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    row.bg:SetVertexColor(1, 1, 1, 0.25)

    row.nameText = row:CreateFontString(nil, "ARTWORK")
    row.nameText:SetPoint("LEFT", row, "LEFT", x.name, 0)
    row.nameText:SetFont(options.font, options.fontSizeName, "OUTLINE")
    row.nameText:SetWidth(layout.nameWidth)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWordWrap(false)

    row.cells = {}

    for columnIndex = 1, #layout.columns do
        local column = layout.columns[columnIndex]

        Columns.CreateCell(row, column, layout, options)
    end

    if index == 1 then
        row:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0,
            -(layout.framePad + options.vPad))
    else
        row:SetPoint("TOPLEFT", rows[index - 1], "BOTTOMLEFT", 0, -options.vPad)
    end

    return row
end

function Rows.Create(parent, titleBar, layout, options)
    options = options or {}

    local rows = {
        maxRows     = options.maxRows or MAX_ROWS,
        rowHeight   = options.rowHeight or ROW_HEIGHT,
        titleHeight = titleBar:GetHeight(),
        vPad        = options.vPad or V_PAD,
    }

    local rowOptions = {
        rowHeight        = rows.rowHeight,
        vPad             = rows.vPad,
        font             = options.font or UI.FONT,
        fontSizeName     = options.fontSizeName or FONT_SIZE_NAME,
        fontSizeTime     = options.fontSizeTime,
        missingBg        = options.missingBg,
    }

    rows.initialFrameHeight = getFrameHeight(rows, layout, DEFAULT_VISIBLE_ROWS)

    for i = 1, rows.maxRows do
        rows[i] = createRow(parent, titleBar, rows, i, layout, rowOptions)
    end

    return rows
end

local function applyRcIcon(row, unit, member, layout, context)
    if not layout.showReadyIcon then
        row.rcIcon:Hide()

        return
    end

    row.rcIcon:Show()

    local status = context.state.rcStatus[unit] or ReadyCheck.PENDING

    if status == ReadyCheck.NOT_READY and not member.online then
        row.rcIcon:SetSize(layout.rcIconWidth, layout.rcIconWidth)
        row.rcIcon:SetTexture(RC_TEXTURE_OFFLINE)
    elseif status == ReadyCheck.PENDING and member.isDead then
        row.rcIcon:SetSize(
            layout.rcIconWidth * 26 / 33, layout.rcIconWidth
        )
        row.rcIcon:SetAtlas(RC_ATLAS_DEAD)
    else
        row.rcIcon:SetSize(layout.rcIconWidth, layout.rcIconWidth)
        row.rcIcon:SetTexture(ReadyCheck.TEXTURES[status])
    end
end

local function applyClassBackground(row, member)
    local color = RAID_CLASS_COLORS[member.class]

    if color then
        row.bg:SetVertexColor(color.r, color.g, color.b, 0.25)
    else
        row.bg:SetVertexColor(0.5, 0.5, 0.5, 0.25)
    end
end

local function applyName(row, member, layout)
    row.nameText:ClearAllPoints()
    row.nameText:SetPoint("LEFT", row, "LEFT", layout.x.name, 0)

    if not member.online then
        row.nameText:SetTextColor(COLOR_NAME_OFFLINE.r, COLOR_NAME_OFFLINE.g, COLOR_NAME_OFFLINE.b)
    elseif member.isDead then
        row.nameText:SetTextColor(COLOR_NAME_DEAD.r, COLOR_NAME_DEAD.g, COLOR_NAME_DEAD.b)
    else
        row.nameText:SetTextColor(COLOR_NAME_NORMAL.r, COLOR_NAME_NORMAL.g, COLOR_NAME_NORMAL.b)
    end

    row.nameText:SetText(F.shortName(member.name))
end

function Rows.ApplyData(row, member, layout, context)
    if not member then
        row:Hide()

        return
    end

    local unit = member.unit

    row:SetWidth(layout.frameWidth - layout.framePad * 2)
    applyRcIcon(row, unit, member, layout, context)
    applyClassBackground(row, member)
    applyName(row, member, layout)

    for columnIndex = 1, #layout.columns do
        local column = layout.columns[columnIndex]

        Columns.SetCellShown(row, column, false)
    end

    for columnIndex = 1, #layout.activeColumns do
        local column = layout.activeColumns[columnIndex]

        Columns.SetCellShown(row, column, true)
        Columns.PositionCell(row, column, layout)
        Columns.RenderCell(row, member, column, context)
    end

    row:Show()
end

function Rows.RefreshRow(row, member, layout, context)
    if not row then
        return
    end

    Columns.SyncExternalData(member, layout, context)
    Rows.ApplyData(row, member, layout, context)
end

function Rows.RefreshAll(rows, state, layout, context)
    local activeCount = state.activeCount

    for i = 1, activeCount do
        rows[i]:SetWidth(layout.frameWidth - layout.framePad * 2)
        Rows.RefreshRow(rows[i], state.members[i], layout, context)
    end

    for i = activeCount + 1, rows.maxRows do
        rows[i]:Hide()
    end

    return getFrameHeight(rows, layout, activeCount)
end
