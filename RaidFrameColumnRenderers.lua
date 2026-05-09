local _, RCC = ...

RCC.RaidFrameColumnRenderers = RCC.RaidFrameColumnRenderers or {}
local Renderers = RCC.RaidFrameColumnRenderers

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

local function createTimedCell(row, column, layout, options)
    local timeText = row:CreateFontString(nil, "ARTWORK")
    timeText:SetPoint("LEFT", row, "LEFT", column.timeX, 0)
    timeText:SetFont(options.font, options.fontSizeTime, "OUTLINE")
    timeText:SetWidth(layout.timeWidth)
    timeText:SetJustifyH("RIGHT")
    row[column.timeField] = timeText

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", column.iconX, 0)
    icon:SetSize(layout.iconSize, layout.iconSize)
    icon:SetTexture(column.iconID)
    createIconBg(row, icon, options.missingBg)
    row[column.iconField] = icon

    local overlay = createOverlay(row, icon)
    overlay.label = column.label
    row[column.overlayField] = overlay
end

local function createIconCell(row, column, layout, options)
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", column.iconX, 0)
    icon:SetSize(layout.iconSize, layout.iconSize)
    icon:SetTexture(column.iconID)
    createIconBg(row, icon, options.missingBg)
    row[column.iconField] = icon

    local overlay = createOverlay(row, icon)
    overlay.label = column.label
    row[column.overlayField] = overlay
end

local function createRaidBuffCell(row, column, layout, options)
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", column.iconX, 0)
    icon:SetSize(layout.iconSize, layout.iconSize)
    icon:SetTexture(options.raidBuffIcons[column.index])
    createIconBg(row, icon, options.missingBg)
    row.raidBuffIcons[column.index] = icon

    local overlay = createOverlay(row, icon)
    overlay.spellID = column.spellID
    row.raidBuffOverlays[column.index] = overlay
end

local function createDurabilityCell(row, column, layout, options)
    local text = row:CreateFontString(nil, "ARTWORK")

    text:SetPoint("LEFT", row, "LEFT", column.textX, 0)
    text:SetFont(options.font, options.fontSizeTime, "OUTLINE")
    text:SetWidth(layout.durabilityWidth)
    text:SetJustifyH("CENTER")
    text:SetText("?")
    text:SetTextColor(0.5, 0.5, 0.5)
    row[column.textField] = text
end

Renderers.TIMED = {
    CreateCell = createTimedCell,
}

Renderers.ICON = {
    CreateCell = createIconCell,
}

Renderers.RAID_BUFF = {
    CreateCell = createRaidBuffCell,
}

Renderers.DURABILITY = {
    CreateCell = createDurabilityCell,
}
