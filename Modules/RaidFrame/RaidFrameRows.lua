local _, RCC = ...

RCC.RaidFrameRows = RCC.RaidFrameRows or {}
local Rows = RCC.RaidFrameRows

local Columns = RCC.RaidFrameColumns
local F = RCC.F

local COLOR_NAME_NORMAL  = { r = 1,   g = 1,   b = 1   }
local COLOR_NAME_OFFLINE = { r = 0.5, g = 0.5, b = 0.5 }
local COLOR_NAME_DEAD    = { r = 0.8, g = 0.2, b = 0.2 }

local RC_TEXTURE_OFFLINE = "Interface\\CharacterFrame\\Disconnect-Icon"
local RC_ATLAS_DEAD      = "Navigation-Tombstone-Icon"

local function createRow(parent, rows, index, layout, options)
    local row = CreateFrame("Frame", nil, parent)
    local x = layout.x

    row:SetSize(layout.frameWidth - layout.framePad * 2, options.rowHeight)
    row:Hide()

    row.rcIcon = row:CreateTexture(nil, "ARTWORK")
    row.rcIcon:SetPoint("CENTER", row, "LEFT", x.readyIconCenter, 0)
    row.rcIcon:SetSize(layout.rcIconWidth, layout.rcIconWidth)
    row.rcIcon:SetTexture(options.rcPendingTexture)

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

        if not column.CreateCell then
            error("Raid frame column has no cell creator: " .. tostring(column.key), 2)
        end

        column.CreateCell(row, column, layout, options)
    end

    if index == 1 then
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", layout.framePad,
            -(layout.framePad + options.titleHeight + layout.framePad
                + options.vPad))
    else
        row:SetPoint("TOPLEFT", rows[index - 1], "BOTTOMLEFT", 0, -options.vPad)
    end

    return row
end

function Rows.Create(parent, layout, options)
    local rows = {
        maxRows     = options.maxRows,
        rowHeight   = options.rowHeight,
        titleHeight = options.titleHeight,
        vPad        = options.vPad,
    }

    for i = 1, options.maxRows do
        rows[i] = createRow(parent, rows, i, layout, options)
    end

    return rows
end

local function applyRcIcon(row, unit, member, layout, context)
    local readyCheck = context.readyCheck
    local status = context.state.rcStatus[unit] or readyCheck.pending

    if status == readyCheck.notReady and not member.online then
        row.rcIcon:SetSize(layout.rcIconWidth, layout.rcIconWidth)
        row.rcIcon:SetTexture(RC_TEXTURE_OFFLINE)
    elseif status == readyCheck.pending and member.isDead then
        row.rcIcon:SetSize(
            layout.rcIconWidth * 26 / 33, layout.rcIconWidth
        )
        row.rcIcon:SetAtlas(RC_ATLAS_DEAD)
    else
        row.rcIcon:SetSize(layout.rcIconWidth, layout.rcIconWidth)
        row.rcIcon:SetTexture(readyCheck.textures[status])
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

local function applyName(row, member)
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

    applyRcIcon(row, unit, member, layout, context)
    applyClassBackground(row, member)
    applyName(row, member)

    for columnIndex = 1, #layout.columns do
        local column = layout.columns[columnIndex]

        if not column.RenderCell then
            error("Raid frame column has no renderer: " .. tostring(column.key), 2)
        end

        column.RenderCell(row, member, column, context)
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
        Rows.RefreshRow(rows[i], state.members[i], layout, context)
    end

    for i = activeCount + 1, rows.maxRows do
        rows[i]:Hide()
    end

    return layout.framePad * 2
        + rows.titleHeight + layout.framePad
        + activeCount * rows.rowHeight
        + (activeCount > 1 and (activeCount - 1) * rows.vPad or 0)
end
