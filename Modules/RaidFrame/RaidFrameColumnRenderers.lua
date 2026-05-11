local _, RCC = ...

RCC.RaidFrameColumnRenderers = RCC.RaidFrameColumnRenderers or {}

local Renderers      = RCC.RaidFrameColumnRenderers
local UI             = RCC.UI
local formatDuration = RCC.F.FormatDuration

local MISSING_ALPHA     = 0.3
local COLOR_DUR_GREEN   = { r = 0.2, g = 1,    b = 0.2 }
local COLOR_DUR_YELLOW  = { r = 1,   g = 0.82, b = 0   }
local COLOR_DUR_RED     = { r = 1,   g = 0.2,  b = 0.2 }
local COLOR_TIME_NORMAL = { r = 1,   g = 1,    b = 1   }
local COLOR_TIME_WARN   = { r = 1,   g = 0.2,  b = 0.2 }
local FONT_SIZE_TIME    = 14
local MISSING_BG        = { r = 0,   g = 0,    b = 0   }

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
        -- TODO: Add red "Aura Missing" text line if the aura is missing
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
    color = color or MISSING_BG

    bg:SetPoint("TOPLEFT",     icon, "TOPLEFT")
    bg:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(color.r, color.g, color.b, 1)
end

local function setCell(row, column, cell)
    row.cells[column.key] = cell
end

local function getCell(row, column)
    local cell = row.cells and row.cells[column.key]

    if not cell then
        error("Raid frame row has no cell for column: " .. tostring(column.key), 2)
    end

    return cell
end

local function createTimedCell(row, column, layout, options)
    options = options or {}

    local timeText = row:CreateFontString(nil, "ARTWORK")
    timeText:SetPoint("LEFT", row, "LEFT", column.timeX, 0)
    timeText:SetFont(
        options.font or UI.FONT,
        options.fontSizeTime or FONT_SIZE_TIME,
        "OUTLINE"
    )
    timeText:SetWidth(layout.timeWidth)
    timeText:SetJustifyH("RIGHT")

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", column.iconX, 0)
    icon:SetSize(layout.iconSize, layout.iconSize)
    icon:SetTexture(column.iconID)
    createIconBg(row, icon, options.missingBg)

    local overlay = createOverlay(row, icon)
    overlay.label = column.label

    setCell(row, column, {
        timeText = timeText,
        icon     = icon,
        overlay  = overlay,
    })
end

local function createIconCell(row, column, layout, options)
    options = options or {}

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", column.iconX, 0)
    icon:SetSize(layout.iconSize, layout.iconSize)
    icon:SetTexture(column.iconID)
    createIconBg(row, icon, options.missingBg)

    local overlay = createOverlay(row, icon)
    overlay.label = column.label

    setCell(row, column, {
        icon    = icon,
        overlay = overlay,
    })
end

local function createRaidBuffCell(row, column, layout, options)
    options = options or {}

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", column.iconX, 0)
    icon:SetSize(layout.iconSize, layout.iconSize)
    icon:SetTexture(column.iconID)
    createIconBg(row, icon, options.missingBg)

    local overlay = createOverlay(row, icon)
    overlay.spellID = column.spellID

    setCell(row, column, {
        icon    = icon,
        overlay = overlay,
    })
end

local function createDurabilityCell(row, column, layout, options)
    options = options or {}

    local text = row:CreateFontString(nil, "ARTWORK")

    text:SetPoint("LEFT", row, "LEFT", column.textX, 0)
    text:SetFont(
        options.font or UI.FONT,
        options.fontSizeTime or FONT_SIZE_TIME,
        "OUTLINE"
    )
    text:SetWidth(layout.durabilityWidth)
    text:SetJustifyH("CENTER")
    text:SetText("?")
    text:SetTextColor(0.5, 0.5, 0.5)

    setCell(row, column, {
        text = text,
    })
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
    local cell = getCell(row, column)
    local icon = cell.icon
    local timeText = cell.timeText
    local overlay = cell.overlay

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

local function setOilState(cell, column, label, text, r, g, b)
    cell.icon:SetTexture(column.iconID)
    cell.icon:SetDesaturated(true)
    cell.icon:SetVertexColor(1, 1, 1, MISSING_ALPHA)
    cell.timeText:SetText(text or "")

    if r and g and b then
        cell.timeText:SetTextColor(r, g, b)
    end

    cell.overlay.label = label
end

local function renderOilCell(row, member, column, context)
    local data = getColumnData(member, column)
    local oilTime = data and data.time
    local oilItemID = data and data.itemID or 0
    local cell = getCell(row, column)
    local icon = cell.icon
    local timeText = cell.timeText
    local overlay = cell.overlay

    overlay.itemID = nil
    overlay.label  = nil

    local hasOil       = oilTime and oilTime > 0
    local oilIsMissing = oilTime == 0
    local hasNoWeapon  = oilTime == -1
    local noOilInfo    = oilTime == nil

    if hasOil then
        icon:SetDesaturated(false)
        icon:SetVertexColor(1, 1, 1, 1)
        timeText:SetText(formatDuration(oilTime))
        setTimeColor(timeText, oilTime, context)

        if oilItemID > 0 then
            overlay.itemID = oilItemID
        else
            overlay.label = "Weapon Oil"
        end
    elseif oilIsMissing then
        setOilState(cell, column, column.labelMissing)
    elseif hasNoWeapon then
        setOilState(cell, column, column.labelNoWeapon)
    elseif noOilInfo then
        setOilState(cell, column, column.labelUnknown, "?", 0.5, 0.5, 0.5)
    end
end

local function renderIconAuraCell(row, member, column)
    local data = getColumnData(member, column)
    local cell = getCell(row, column)
    local icon = cell.icon
    local overlay = cell.overlay
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
    local cell = getCell(row, column)
    local icon = cell.icon
    local overlay = cell.overlay

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
    local cell = getCell(row, column)
    local text = cell.text

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
