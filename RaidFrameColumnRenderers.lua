local _, RCC = ...

RCC.RaidFrameColumnRenderers = RCC.RaidFrameColumnRenderers or {}
local Renderers = RCC.RaidFrameColumnRenderers

local ceil   = ceil
local format = format

local MISSING_ALPHA     = 0.3
local COLOR_DUR_GREEN   = { r = 0.2, g = 1,    b = 0.2 }
local COLOR_DUR_YELLOW  = { r = 1,   g = 0.82, b = 0   }
local COLOR_DUR_RED     = { r = 1,   g = 0.2,  b = 0.2 }
local COLOR_TIME_NORMAL = { r = 1,   g = 1,    b = 1   }
local COLOR_TIME_WARN   = { r = 1,   g = 0.2,  b = 0.2 }

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

local function formatDuration(seconds)
    local mins = ceil(seconds / 60)

    if mins >= 60 then
        return format("%dh", ceil(seconds / 3600))
    end

    return format("%dm", mins > 0 and mins or 0)
end

local function setTimeColor(timeText, time, context)
    if time < context.rules.expireWarnSeconds then
        timeText:SetTextColor(COLOR_TIME_WARN.r, COLOR_TIME_WARN.g, COLOR_TIME_WARN.b)
    else
        timeText:SetTextColor(
            COLOR_TIME_NORMAL.r,
            COLOR_TIME_NORMAL.g,
            COLOR_TIME_NORMAL.b
        )
    end
end

local function getColumnData(member, column)
    return member.columnData and member.columnData[column.key]
end

local function renderTimedAuraCell(row, member, column, context)
    local data = getColumnData(member, column)
    local icon = row[column.iconField]
    local timeText = row[column.timeField]
    local overlay = row[column.overlayField]

    if data and data.has then
        icon:SetDesaturated(false)
        icon:SetVertexColor(1, 1, 1, 1)
        icon:SetTexture(data.iconID or column.iconID)

        if not data.time or data.time == context.rules.noDuration then
            timeText:SetText("")
        else
            timeText:SetText(formatDuration(data.time))
            setTimeColor(timeText, data.time, context)
        end
    else
        icon:SetTexture(column.iconID)
        icon:SetDesaturated(true)
        icon:SetVertexColor(1, 1, 1, MISSING_ALPHA)
        timeText:SetText("")
    end

    overlay.unit   = member.unit
    overlay.auraID = data and data.auraID or nil
end

local function setOilMissing(row, column, label)
    row[column.iconField]:SetTexture(column.iconID)
    row[column.iconField]:SetDesaturated(true)
    row[column.iconField]:SetVertexColor(1, 1, 1, MISSING_ALPHA)
    row[column.timeField]:SetText("")
    row[column.overlayField].label = label
end

local function renderOilCell(row, member, column, context)
    local data = getColumnData(member, column)
    local oilTime = data and data.time
    local oilItemID = data and data.itemID or 0
    local icon = row[column.iconField]
    local timeText = row[column.timeField]
    local overlay = row[column.overlayField]

    overlay.itemID = nil
    overlay.label  = nil

    if oilTime and oilTime > 0 then
        icon:SetDesaturated(false)
        icon:SetVertexColor(1, 1, 1, 1)
        timeText:SetText(formatDuration(oilTime))
        setTimeColor(timeText, oilTime, context)

        if oilItemID > 0 then
            overlay.itemID = oilItemID
        else
            overlay.label = "Weapon Oil"
        end
    elseif oilTime == 0 then
        setOilMissing(row, column, "Weapon Oil: Missing")
    elseif oilTime == -1 then
        setOilMissing(row, column, "Weapon Oil: N/A")
    else
        setOilMissing(row, column, column.label)
        timeText:SetText("?")
        timeText:SetTextColor(0.5, 0.5, 0.5)
    end
end

local function renderIconAuraCell(row, member, column)
    local data = getColumnData(member, column)
    local icon = row[column.iconField]
    local overlay = row[column.overlayField]
    local hasAura = data and data.has

    icon:SetTexture((data and data.iconID) or column.iconID)
    icon:SetDesaturated(not hasAura)
    icon:SetVertexColor(1, 1, 1, hasAura and 1 or MISSING_ALPHA)
    overlay.unit   = member.unit
    overlay.auraID = data and data.auraID or nil
end

local function renderRaidBuffCell(row, member, column)
    local data = getColumnData(member, column)
    local auraID = data and data.auraID
    local hasAura = data and data.has
    local icon = row.raidBuffIcons[column.index]
    local overlay = row.raidBuffOverlays[column.index]

    icon:SetDesaturated(not hasAura)
    icon:SetVertexColor(1, 1, 1, hasAura and 1 or MISSING_ALPHA)
    overlay.unit = member.unit

    if hasAura
        and type(auraID) == "number"
        and not issecretvalue(auraID)
    then
        overlay.auraID = auraID
    else
        overlay.auraID = nil
    end
end

local function renderDurabilityCell(row, member, column, context)
    local data = getColumnData(member, column)
    local durPct = data and data.percent
    local text = row[column.textField]

    if durPct then
        text:SetText(durPct .. "%")

        local color
        if durPct <= 20 then
            color = COLOR_DUR_RED
        elseif durPct <= 50 then
            color = COLOR_DUR_YELLOW
        else
            color = COLOR_DUR_GREEN
        end

        text:SetTextColor(color.r, color.g, color.b)
    else
        text:SetText("?")
        text:SetTextColor(0.5, 0.5, 0.5)
    end
end

Renderers.TIMED = {
    CreateCell     = createTimedCell,
    RenderAuraCell = renderTimedAuraCell,
    RenderOilCell  = renderOilCell,
}

Renderers.ICON = {
    CreateCell     = createIconCell,
    RenderAuraCell = renderIconAuraCell,
}

Renderers.RAID_BUFF = {
    CreateCell = createRaidBuffCell,
    RenderCell = renderRaidBuffCell,
}

Renderers.DURABILITY = {
    CreateCell = createDurabilityCell,
    RenderCell = renderDurabilityCell,
}
