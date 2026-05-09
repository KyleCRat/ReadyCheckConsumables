local _, RCC = ...

RCC.RaidFrameRows = RCC.RaidFrameRows or {}
local Rows = RCC.RaidFrameRows

local function onOverlayEnter(self)
    local unit    = self.unit
    local auraID  = self.auraID
    local spellID = self.spellID
    local itemID  = self.itemID
    local label   = self.label

    if auraID and unit
        and type(auraID) == "number"
        and not issecretvalue(auraID)
    then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetUnitBuffByAuraInstanceID(unit, auraID)
        GameTooltip:Show()

        return
    end

    if itemID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(itemID)
        GameTooltip:Show()

        return
    end

    if spellID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(spellID)
        GameTooltip:Show()

        return
    end

    if label then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(label)
        GameTooltip:Show()

        return
    end
end

local function onOverlayLeave()
    GameTooltip:Hide()
end

local function createOverlay(row, icon)
    local overlay = CreateFrame("Frame", nil, row)

    overlay:SetPoint("TOPLEFT", icon, "TOPLEFT")
    overlay:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
    overlay:EnableMouse(true)
    overlay:SetScript("OnEnter", onOverlayEnter)
    overlay:SetScript("OnLeave", onOverlayLeave)
    overlay.unit    = nil
    overlay.auraID  = nil
    overlay.spellID = nil
    overlay.itemID  = nil
    overlay.label   = nil

    return overlay
end

local function createIconBg(row, icon, color)
    local bg = row:CreateTexture(nil, "BACKGROUND")

    bg:SetPoint("TOPLEFT",     icon, "TOPLEFT")
    bg:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(color.r, color.g, color.b, 1)
end

local function createTimedColumn(row, column, options)
    local timeText = row:CreateFontString(nil, "ARTWORK")
    timeText:SetPoint("LEFT", row, "LEFT", column.timeX, 0)
    timeText:SetFont(options.font, options.fontSizeTime, "OUTLINE")
    timeText:SetWidth(options.timeWidth)
    timeText:SetJustifyH("RIGHT")
    row[column.timeField] = timeText

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", column.iconX, 0)
    icon:SetSize(options.iconSize, options.iconSize)
    icon:SetTexture(column.iconID)
    createIconBg(row, icon, options.missingBg)
    row[column.iconField] = icon

    local overlay = createOverlay(row, icon)
    overlay.label = column.label
    row[column.overlayField] = overlay
end

local function createIconColumn(row, column, options)
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", column.iconX, 0)
    icon:SetSize(options.iconSize, options.iconSize)
    icon:SetTexture(column.iconID)
    createIconBg(row, icon, options.missingBg)
    row[column.iconField] = icon

    local overlay = createOverlay(row, icon)
    overlay.label = column.label
    row[column.overlayField] = overlay
end

local function createRaidBuffColumn(row, column, options)
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", column.iconX, 0)
    icon:SetSize(options.iconSize, options.iconSize)
    icon:SetTexture(options.raidBuffIcons[column.index])
    createIconBg(row, icon, options.missingBg)
    row.raidBuffIcons[column.index] = icon

    local overlay = createOverlay(row, icon)
    overlay.spellID = column.spellID
    row.raidBuffOverlays[column.index] = overlay
end

local function createRow(parent, rows, index, layout, options)
    local row = CreateFrame("Frame", nil, parent)
    local x = layout.x

    row:SetSize(options.frameWidth - options.framePad * 2, options.rowHeight)
    row:Hide()

    row.rcIcon = row:CreateTexture(nil, "ARTWORK")
    row.rcIcon:SetPoint("CENTER", row, "LEFT", x.readyIconCenter, 0)
    row.rcIcon:SetSize(options.rcIconWidth, options.rcIconWidth)
    row.rcIcon:SetTexture(options.rcPendingTexture)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints(row)
    row.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    row.bg:SetVertexColor(1, 1, 1, 0.25)

    row.nameText = row:CreateFontString(nil, "ARTWORK")
    row.nameText:SetPoint("LEFT", row, "LEFT", x.name, 0)
    row.nameText:SetFont(options.font, options.fontSizeName, "OUTLINE")
    row.nameText:SetWidth(options.nameWidth)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWordWrap(false)

    for i = 1, #layout.timedColumns do
        createTimedColumn(row, layout.timedColumns[i], options)
    end

    for i = 1, #layout.iconColumns do
        createIconColumn(row, layout.iconColumns[i], options)
    end

    row.raidBuffIcons    = {}
    row.raidBuffOverlays = {}

    for k = 1, #layout.raidBuffColumns do
        createRaidBuffColumn(row, layout.raidBuffColumns[k], options)
    end

    row.durabilityText = row:CreateFontString(nil, "ARTWORK")
    row.durabilityText:SetPoint("LEFT", row, "LEFT", x.durability, 0)
    row.durabilityText:SetFont(options.font, options.fontSizeTime, "OUTLINE")
    row.durabilityText:SetWidth(options.durabilityWidth)
    row.durabilityText:SetJustifyH("CENTER")
    row.durabilityText:SetText("?")
    row.durabilityText:SetTextColor(0.5, 0.5, 0.5)

    if index == 1 then
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", options.framePad,
            -(options.framePad + options.titleHeight + options.framePad
                + options.vPad))
    else
        row:SetPoint("TOPLEFT", rows[index - 1], "BOTTOMLEFT", 0, -options.vPad)
    end

    return row
end

function Rows.Create(parent, layout, options)
    local rows = {}

    for i = 1, options.maxRows do
        rows[i] = createRow(parent, rows, i, layout, options)
    end

    return rows
end
