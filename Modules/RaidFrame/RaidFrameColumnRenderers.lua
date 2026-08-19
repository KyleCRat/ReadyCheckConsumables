local _, RCC = ...

RCC.RaidFrameColumnRenderers = RCC.RaidFrameColumnRenderers or {}

local Renderers      = RCC.RaidFrameColumnRenderers
local Broadcast      = RCC.RaidFrameBroadcast
local F              = RCC.F
local ReadyCheck     = RCC.RaidFrameReadyCheck
local UI             = RCC.UI
local Timing         = RCC.ConsumableTiming
local formatDuration = F.FormatDuration
local GetItemIcon    = C_Item.GetItemIconByID

-- Row visual-state contract:
--   PRESENT     - confirmed and acceptable; full-color detected icon.
--   EXPIRING    - confirmed but below its duration threshold; full-color icon
--                 with a red duration.
--   MISSING     - confirmed absent; 30% desaturated configured icon.
--   IN_PROGRESS - an action is underway but has not produced the required
--                 result yet; full-color action icon and still counts as bad.
--   NO_WEAPON   - no enchantable main-hand weapon; desaturated configured icon
--                 with a title-bar red X overlay, and counts as bad.
--   UNKNOWN     - RCC responded but could not inspect the status; faded
--                 configured icon with a faded grey X overlay, and neutral for
--                 header aggregation.
--   NO_RESPONSE - no compatible status was received; the same faded icon and
--                 grey X overlay, and neutral for header aggregation. It is
--                 never blank.
-- Durability and cauldron cells retain their approved numeric presentations,
-- but use the same UNKNOWN/NO_RESPONSE distinction where it applies.
local ROW_STATE = {
    PRESENT     = "present",
    EXPIRING    = "expiring",
    MISSING     = "missing",
    IN_PROGRESS = "inProgress",
    NO_WEAPON   = "noWeapon",
    UNKNOWN     = "unknown",
    NO_RESPONSE = "noResponse",
}

local MISSING_ALPHA            = 0.3
local UNAVAILABLE_ICON_ALPHA   = 0.25
local UNAVAILABLE_MARKER_ALPHA = 0.8
local NOT_READY_TEXTURE        = ReadyCheck.TITLE_TEXTURES.notReady
local COLOR_DUR_GREEN          = { r = 0.2, g = 1,    b = 0.2 }
local COLOR_DUR_YELLOW         = { r = 1,   g = 0.82, b = 0   }
local COLOR_DUR_RED            = { r = 1,   g = 0.2,  b = 0.2 }
local COLOR_TIME_NORMAL = { r = 1,   g = 1,    b = 1   }
local COLOR_TIME_WARN   = { r = 1,   g = 0.2,  b = 0.2 }
local COLOR_NEUTRAL     = { r = 0.6, g = 0.6,  b = 0.6 }
local COLOR_UNDER       = { r = 1,   g = 0.82, b = 0   }
local COLOR_EXACT       = { r = 0.2, g = 1,    b = 0.2 }
local COLOR_OVER        = { r = 1,   g = 0.2,  b = 0.2 }
local FONT_SIZE_TIME    = 14
local MISSING_BG        = { r = 0,   g = 0,    b = 0   }
local TEMP_WEAPON_ENCHANT_STATUS = Broadcast.TempWeaponEnchantStatus

local function hasUsableAuraID(auraID)
    return auraID
        and type(auraID) == "number"
        and not issecretvalue(auraID)
end

local function hasUsableNumericID(id)
    return F.IsSafeNumber(id) and id > 0
end

local function getMissingTooltip(column)
    return column.statusName .. ": Missing"
end

local function getUnknownTooltip(column)
    return "Unable to check " .. column.statusName
        .. " for this player. They have Ready Check Consumables, but the "
        .. "information was unavailable."
end

local function getNoResponseTooltip(column)
    return "No " .. column.statusName
        .. " information was received from this player. They may not have "
        .. "Ready Check Consumables installed."
end

local function onOverlayEnter(self)
    local unit    = self.unit
    local auraID  = self.auraID
    local spellID = self.spellID
    local itemID  = self.itemID
    local label   = self.label
    local currentAuraID = F.GetCurrentPublicAuraInstanceID(unit, auraID)

    if currentAuraID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetUnitBuffByAuraInstanceID(unit, currentAuraID)
        GameTooltip:Show()

        return
    end

    if hasUsableNumericID(itemID) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(itemID)
        GameTooltip:Show()

        return
    end

    if hasUsableNumericID(spellID) then
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
    overlay:EnableMouse(false)
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

    return bg
end

local function createStateOverlay(row, icon)
    local stateOverlay = row:CreateTexture(nil, "OVERLAY")

    stateOverlay:SetAllPoints(icon)
    stateOverlay:SetTexture(NOT_READY_TEXTURE)
    stateOverlay:Hide()

    return stateOverlay
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

local function createIconRegions(row, column, layout, options, hasStateOverlay)
    options = options or {}

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT", column.iconX, 0)
    icon:SetSize(layout.iconSize, layout.iconSize)
    icon:SetTexture(column.iconID)

    local cell = {
        icon    = icon,
        bg      = createIconBg(row, icon, options.missingBg),
        overlay = createOverlay(row, icon),
    }

    if hasStateOverlay then
        cell.stateOverlay = createStateOverlay(row, icon)
        cell.stateOverlayActive = false
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

    local cell = createIconRegions(row, column, layout, options, true)
    cell.timeText = timeText

    setCell(row, column, cell)
end

local function createIconCell(row, column, layout, options)
    setCell(
        row,
        column,
        createIconRegions(row, column, layout, options, true)
    )
end

local function createCauldronCell(row, column, layout, options)
    options = options or {}

    local countText = row:CreateFontString(nil, "ARTWORK")

    countText:SetPoint("LEFT", row, "LEFT", column.countX, 0)
    countText:SetFont(
        options.font or UI.FONT,
        options.fontSizeTime or FONT_SIZE_TIME,
        "OUTLINE"
    )
    countText:SetWidth(layout.cauldronCountWidth)
    countText:SetJustifyH("RIGHT")

    local cell = createIconRegions(row, column, layout, options)
    cell.countText = countText

    setCell(row, column, cell)
end

local function createTextOverlay(row, text, width, height)
    local overlay = CreateFrame("Frame", nil, row)

    overlay:SetPoint("CENTER", text, "CENTER")
    overlay:SetSize(width, height)
    overlay:EnableMouse(false)
    overlay:SetScript("OnEnter", onOverlayEnter)
    overlay:SetScript("OnLeave", onOverlayLeave)
    overlay.unit    = nil
    overlay.auraID  = nil
    overlay.spellID = nil
    overlay.itemID  = nil
    overlay.label   = nil

    return overlay
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
        overlay = createTextOverlay(
            row,
            text,
            layout.durabilityWidth,
            options.rowHeight or layout.iconSize
        ),
    })
end

local function setTimeColor(timeText, time)
    if Timing.IsExpiringSoon(time) then
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

local function setTextColor(fontString, color)
    fontString:SetTextColor(color.r, color.g, color.b)
end

local function getCountColor(count, target)
    if count < target then
        return COLOR_UNDER
    elseif count > target then
        return COLOR_OVER
    end

    return COLOR_EXACT
end

-- These helpers own the complete reusable-region reset so a previous row or
-- visibility change cannot leak into the next render.
local function resetOverlay(overlay)
    overlay.unit    = nil
    overlay.auraID  = nil
    overlay.spellID = nil
    overlay.itemID  = nil
    overlay.label   = nil
    overlay:EnableMouse(false)
end

local function resetIconCell(cell)
    resetOverlay(cell.overlay)
    cell.bg:SetAlpha(1)

    if cell.timeText then
        cell.timeText:SetText("")
    end

    if cell.stateOverlay then
        cell.stateOverlayActive = false
        cell.stateOverlay:SetTexture(NOT_READY_TEXTURE)
        cell.stateOverlay:SetDesaturated(false)
        cell.stateOverlay:SetVertexColor(1, 1, 1, 1)
        cell.stateOverlay:Hide()
    end
end

local function setIconAppearance(cell, texture, desaturated, alpha)
    cell.icon:SetTexture(texture)
    cell.icon:SetDesaturated(desaturated)
    cell.icon:SetVertexColor(1, 1, 1, alpha)
end

local function showStateOverlay(cell, desaturated, alpha)
    if not cell.stateOverlay then
        return
    end

    cell.stateOverlayActive = true
    cell.stateOverlay:SetTexture(NOT_READY_TEXTURE)
    cell.stateOverlay:SetDesaturated(desaturated)
    cell.stateOverlay:SetVertexColor(1, 1, 1, alpha)
    cell.stateOverlay:Show()
end

local function setIconCellMissing(cell, column)
    setIconAppearance(cell, column.iconID, true, MISSING_ALPHA)
    cell.bg:SetAlpha(1)
    cell.overlay.label = getMissingTooltip(column)
    cell.overlay:EnableMouse(true)
end

local function setIconCellPresent(cell, column, iconID)
    setIconAppearance(cell, iconID or column.iconID, false, 1)
    cell.bg:SetAlpha(1)
    cell.overlay:EnableMouse(true)
end

local function setIconCellInProgress(cell, column, iconID)
    setIconCellPresent(cell, column, iconID)
    cell.overlay.label = column.inProgressTooltip
        or (column.statusName .. " is in progress.")
end

local function setIconCellNoWeapon(cell, column)
    setIconAppearance(cell, column.iconID, true, MISSING_ALPHA)
    cell.bg:SetAlpha(1)
    showStateOverlay(cell, false, 1)
    cell.overlay.label = "No enchantable main-hand weapon equipped."
    cell.overlay:EnableMouse(true)
end

local function setIconCellUnavailable(cell, column, tooltip)
    setIconAppearance(cell, column.iconID, true, UNAVAILABLE_ICON_ALPHA)
    cell.bg:SetAlpha(UNAVAILABLE_ICON_ALPHA)
    showStateOverlay(cell, true, UNAVAILABLE_MARKER_ALPHA)
    cell.overlay.label = tooltip
    cell.overlay:EnableMouse(true)
end

local function applyIconRowState(cell, column, state, iconID)
    resetIconCell(cell)

    if state == ROW_STATE.PRESENT or state == ROW_STATE.EXPIRING then
        setIconCellPresent(cell, column, iconID)
    elseif state == ROW_STATE.MISSING then
        setIconCellMissing(cell, column)
    elseif state == ROW_STATE.IN_PROGRESS then
        setIconCellInProgress(cell, column, iconID)
    elseif state == ROW_STATE.NO_WEAPON then
        setIconCellNoWeapon(cell, column)
    elseif state == ROW_STATE.UNKNOWN then
        setIconCellUnavailable(cell, column, getUnknownTooltip(column))
    elseif state == ROW_STATE.NO_RESPONSE then
        setIconCellUnavailable(cell, column, getNoResponseTooltip(column))
    else
        error("Unknown raid-frame row state: " .. tostring(state), 2)
    end
end

local function getUnavailableState(member)
    local rccPresent = member.columnData
        and member.columnData.rccPresent == true

    if rccPresent then
        return ROW_STATE.UNKNOWN
    end

    return ROW_STATE.NO_RESPONSE
end

local function getAuraRowState(member, data, context)
    if not data or data.available ~= true then
        return getUnavailableState(member)
    end

    if not data.has then
        return ROW_STATE.MISSING
    end

    if data.isEating then
        return ROW_STATE.IN_PROGRESS
    end

    if context
        and data.time
        and data.time ~= context.rules.noDuration
        and Timing.IsExpiringSoon(data.time)
    then
        return ROW_STATE.EXPIRING
    end

    return ROW_STATE.PRESENT
end

local function setPresentAuraTooltip(cell, member, column, data)
    local overlay = cell.overlay

    overlay.unit = member.unit
    overlay.auraID  = data.auraID
    overlay.spellID = data.spellID or column.spellID

    if not hasUsableAuraID(overlay.auraID)
        and not hasUsableNumericID(overlay.spellID)
    then
        overlay.label = column.statusName
    end
end

local function renderAuraIconState(cell, member, column, data, context)
    local state = getAuraRowState(member, data, context)

    applyIconRowState(cell, column, state, data and data.iconID)

    if state == ROW_STATE.PRESENT or state == ROW_STATE.EXPIRING then
        setPresentAuraTooltip(cell, member, column, data)
    end

    return state
end

local function renderTimedAuraCell(row, member, column, context)
    local data = getColumnData(member, column)
    local cell = getCell(row, column)

    local state = renderAuraIconState(cell, member, column, data, context)

    if (state == ROW_STATE.PRESENT
            or state == ROW_STATE.EXPIRING
            or state == ROW_STATE.IN_PROGRESS)
        and data.time
        and data.time ~= context.rules.noDuration
    then
        cell.timeText:SetText(formatDuration(data.time))
        setTimeColor(cell.timeText, data.time)
    end
end

local function getTempWeaponEnchantRowState(member, remaining)
    if remaining == nil then
        return getUnavailableState(member)
    elseif remaining > 0 then
        if Timing.IsExpiringSoon(remaining) then
            return ROW_STATE.EXPIRING
        end

        return ROW_STATE.PRESENT
    elseif remaining == TEMP_WEAPON_ENCHANT_STATUS.MISSING then
        return ROW_STATE.MISSING
    elseif remaining == TEMP_WEAPON_ENCHANT_STATUS.NO_WEAPON then
        return ROW_STATE.NO_WEAPON
    end

    return ROW_STATE.UNKNOWN
end

local function renderTempWeaponEnchantCell(row, member, column, context)
    local data = getColumnData(member, column)
    local remaining = data and data.time
    local itemID = data and data.itemID or 0
    local spellID = data and data.spellID or 0
    local cell = getCell(row, column)
    local overlay = cell.overlay
    local state = getTempWeaponEnchantRowState(member, remaining)

    applyIconRowState(cell, column, state, data and data.iconID)

    if state == ROW_STATE.PRESENT or state == ROW_STATE.EXPIRING then
        cell.timeText:SetText(formatDuration(remaining))
        setTimeColor(cell.timeText, remaining)

        if itemID > 0 then
            overlay.itemID = itemID
        elseif spellID > 0 then
            overlay.spellID = spellID
        else
            overlay.label = column.statusName
        end
    end
end

local function renderIconAuraCell(row, member, column, context)
    local data = getColumnData(member, column)
    local cell = getCell(row, column)

    renderAuraIconState(cell, member, column, data, context)
end

local function renderDurabilityCell(row, member, column)
    local data = getColumnData(member, column)
    local durPct = data and data.percent
    local cell = getCell(row, column)
    local text = cell.text
    local overlay = cell.overlay

    resetOverlay(overlay)

    if durPct ~= nil then
        text:SetText(durPct .. "%")

        local color
        if durPct <= 20 then
            color = COLOR_DUR_RED
        elseif durPct <= 50 then
            color = COLOR_DUR_YELLOW
        else
            color = COLOR_DUR_GREEN
        end
        setTextColor(text, color)
    else
        local state = getUnavailableState(member)

        text:SetText(state == ROW_STATE.UNKNOWN and "?" or "-")
        setTextColor(text, COLOR_NEUTRAL)
        overlay.label = state == ROW_STATE.UNKNOWN
            and getUnknownTooltip(column)
            or getNoResponseTooltip(column)
        overlay:EnableMouse(true)
    end
end

local function renderCauldronCell(row, member, column)
    local Cauldron = RCC.RaidFrameCauldron
    local kind = column.cauldronKind
    local cell = getCell(row, column)
    local count = Cauldron.GetCount(member.key, kind)
    local target = Cauldron.GetTarget(kind)
    local itemID = Cauldron.GetLastItemID(member.key, kind)
    local icon = itemID and GetItemIcon(itemID) or column.iconID

    resetOverlay(cell.overlay)
    cell.bg:SetAlpha(1)
    cell.countText:SetText(tostring(count))
    setTextColor(cell.countText, getCountColor(count, target))

    cell.icon:SetTexture(icon or column.iconID)
    cell.icon:SetDesaturated(count == 0)
    cell.icon:SetVertexColor(1, 1, 1, count > 0 and 1 or MISSING_ALPHA)

    cell.overlay.unit    = nil
    cell.overlay.auraID  = nil
    cell.overlay.spellID = nil
    cell.overlay.itemID  = itemID
    cell.overlay.label   = column.statusName
    cell.overlay:EnableMouse(true)
end

local function setRegionShown(region, shown)
    if not region or not region.Show then
        return
    end

    if shown then
        region:Show()
    else
        region:Hide()
    end
end

function Renderers.SetCellShown(cell, shown)
    if not cell then
        return
    end

    setRegionShown(cell.icon, shown)
    setRegionShown(cell.bg, shown)
    setRegionShown(cell.overlay, shown)
    setRegionShown(cell.timeText, shown)
    setRegionShown(cell.countText, shown)
    setRegionShown(cell.text, shown)

    if cell.stateOverlay then
        setRegionShown(
            cell.stateOverlay,
            shown and cell.stateOverlayActive == true
        )
    end
end

local function positionIconCell(row, cell, column)
    cell.icon:ClearAllPoints()
    cell.icon:SetPoint("LEFT", row, "LEFT", column.iconX, 0)
end

function Renderers.PositionCell(row, column)
    local cell = getCell(row, column)

    if cell.timeText then
        cell.timeText:ClearAllPoints()
        cell.timeText:SetPoint("LEFT", row, "LEFT", column.timeX, 0)
    end

    if cell.countText then
        cell.countText:ClearAllPoints()
        cell.countText:SetPoint("LEFT", row, "LEFT", column.countX, 0)
    end

    if cell.icon then
        positionIconCell(row, cell, column)
    end

    if cell.text then
        cell.text:ClearAllPoints()
        cell.text:SetPoint("LEFT", row, "LEFT", column.textX, 0)
    end
end

Renderers.TIMED = {
    CreateCell                  = createTimedCell,
    RenderAuraCell              = renderTimedAuraCell,
    RenderTempWeaponEnchantCell = renderTempWeaponEnchantCell,
}

Renderers.ICON = {
    CreateCell     = createIconCell,
    RenderAuraCell = renderIconAuraCell,
}

Renderers.RAID_BUFF = {
    CreateCell = createIconCell,
    RenderCell = renderIconAuraCell,
}

Renderers.DURABILITY = {
    CreateCell = createDurabilityCell,
    RenderCell = renderDurabilityCell,
}

Renderers.CAULDRON = {
    CreateCell = createCauldronCell,
    RenderCell = renderCauldronCell,
}
