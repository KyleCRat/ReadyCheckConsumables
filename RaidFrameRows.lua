local _, RCC = ...

RCC.RaidFrameRows = RCC.RaidFrameRows or {}
local Rows = RCC.RaidFrameRows

local F  = RCC.F
local db = RCC.db

local ceil   = ceil
local format = format

local MISSING_ALPHA      = 0.3
local COLOR_DUR_GREEN    = { r = 0.2, g = 1,   b = 0.2 }
local COLOR_DUR_YELLOW   = { r = 1,   g = 0.82, b = 0  }
local COLOR_DUR_RED      = { r = 1,   g = 0.2, b = 0.2 }
local COLOR_TIME_NORMAL  = { r = 1,   g = 1,   b = 1   }
local COLOR_TIME_WARN    = { r = 1,   g = 0.2, b = 0.2 }
local COLOR_NAME_NORMAL  = { r = 1,   g = 1,   b = 1   }
local COLOR_NAME_OFFLINE = { r = 0.5, g = 0.5, b = 0.5 }
local COLOR_NAME_DEAD    = { r = 0.8, g = 0.2, b = 0.2 }

local RC_TEXTURE_OFFLINE = "Interface\\CharacterFrame\\Disconnect-Icon"
local RC_ATLAS_DEAD      = "Navigation-Tombstone-Icon"

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

local function createTimedColumn(row, column, layout, options)
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

local function createIconColumn(row, column, layout, options)
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

local function createRaidBuffColumn(row, column, layout, options)
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

    for i = 1, #layout.timedColumns do
        createTimedColumn(row, layout.timedColumns[i], layout, options)
    end

    for i = 1, #layout.iconColumns do
        createIconColumn(row, layout.iconColumns[i], layout, options)
    end

    row.raidBuffIcons    = {}
    row.raidBuffOverlays = {}

    for k = 1, #layout.raidBuffColumns do
        createRaidBuffColumn(row, layout.raidBuffColumns[k], layout, options)
    end

    row.durabilityText = row:CreateFontString(nil, "ARTWORK")
    row.durabilityText:SetPoint("LEFT", row, "LEFT", x.durability, 0)
    row.durabilityText:SetFont(options.font, options.fontSizeTime, "OUTLINE")
    row.durabilityText:SetWidth(layout.durabilityWidth)
    row.durabilityText:SetJustifyH("CENTER")
    row.durabilityText:SetText("?")
    row.durabilityText:SetTextColor(0.5, 0.5, 0.5)

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
    local rows = {}

    for i = 1, options.maxRows do
        rows[i] = createRow(parent, rows, i, layout, options)
    end

    return rows
end

local function formatDuration(seconds)
    local mins = ceil(seconds / 60)

    if mins >= 60 then
        return format("%dh", ceil(seconds / 3600))
    end

    return format("%dm", mins > 0 and mins or 0)
end

local function applyTimedBuff(icon, timeText, overlay, unit, hasBuff, time,
    auraIconID, fallbackIcon, auraID, context)
    if hasBuff then
        icon:SetDesaturated(false)
        icon:SetVertexColor(1, 1, 1, 1)
        icon:SetTexture(auraIconID or fallbackIcon)

        if time == context.noDuration then
            timeText:SetText("")
        else
            timeText:SetText(formatDuration(time))

            if time < context.expireWarnSeconds then
                timeText:SetTextColor(COLOR_TIME_WARN.r, COLOR_TIME_WARN.g, COLOR_TIME_WARN.b)
            else
                timeText:SetTextColor(COLOR_TIME_NORMAL.r, COLOR_TIME_NORMAL.g, COLOR_TIME_NORMAL.b)
            end
        end
    else
        icon:SetTexture(fallbackIcon)
        icon:SetDesaturated(true)
        icon:SetVertexColor(1, 1, 1, MISSING_ALPHA)
        timeText:SetText("")
    end

    overlay.unit   = unit
    overlay.auraID = auraID
end

local function applySimpleBuff(icon, overlay, unit, hasBuff, auraIconID, fallbackIcon, auraID)
    icon:SetTexture(auraIconID or fallbackIcon)
    icon:SetDesaturated(not hasBuff)
    icon:SetVertexColor(1, 1, 1, hasBuff and 1 or MISSING_ALPHA)
    overlay.unit   = unit
    overlay.auraID = auraID
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

local function setOilMissing(row, label)
    row.oilIcon:SetTexture(db.weapon_enchant_icon_id)
    row.oilIcon:SetDesaturated(true)
    row.oilIcon:SetVertexColor(1, 1, 1, MISSING_ALPHA)
    row.oilTime:SetText("")
    row.oilOverlay.label = label
end

local function applyOil(row, playerKey, context)
    local oil = context.oilData[playerKey]
    local oilTime = oil and oil.time
    local oilItemID = oil and oil.item or 0

    row.oilOverlay.itemID = nil
    row.oilOverlay.label  = nil

    if oilTime and oilTime > 0 then
        row.oilIcon:SetDesaturated(false)
        row.oilIcon:SetVertexColor(1, 1, 1, 1)
        row.oilTime:SetText(formatDuration(oilTime))

        if oilTime < context.expireWarnSeconds then
            row.oilTime:SetTextColor(COLOR_TIME_WARN.r, COLOR_TIME_WARN.g, COLOR_TIME_WARN.b)
        else
            row.oilTime:SetTextColor(COLOR_TIME_NORMAL.r, COLOR_TIME_NORMAL.g, COLOR_TIME_NORMAL.b)
        end

        if oilItemID > 0 then
            row.oilOverlay.itemID = oilItemID
        else
            row.oilOverlay.label = "Weapon Oil"
        end
    elseif oilTime == 0 then
        setOilMissing(row, "Weapon Oil: Missing")
    elseif oilTime == -1 then
        setOilMissing(row, "Weapon Oil: N/A")
    else
        setOilMissing(row, "Weapon Oil: Unknown")
        row.oilTime:SetText("?")
        row.oilTime:SetTextColor(0.5, 0.5, 0.5)
    end
end

local function applyRaidBuffs(row, unit, auras)
    for k = 1, #db.raidBuffDefs do
        local auraID = auras.raidBuff[k]
        local has = auraID and auraID ~= false

        row.raidBuffIcons[k]:SetDesaturated(not has)
        row.raidBuffIcons[k]:SetVertexColor(1, 1, 1, has and 1 or MISSING_ALPHA)
        row.raidBuffOverlays[k].unit = unit

        if has and not issecretvalue(auraID) then
            row.raidBuffOverlays[k].auraID = auraID
        else
            row.raidBuffOverlays[k].auraID = nil
        end
    end
end

local function applyDurability(row, playerKey, context)
    local durPct = context.durabilityData[playerKey]

    if durPct then
        row.durabilityText:SetText(durPct .. "%")

        local c
        if durPct <= 20 then
            c = COLOR_DUR_RED
        elseif durPct <= 50 then
            c = COLOR_DUR_YELLOW
        else
            c = COLOR_DUR_GREEN
        end

        row.durabilityText:SetTextColor(c.r, c.g, c.b)
    else
        row.durabilityText:SetText("?")
        row.durabilityText:SetTextColor(0.5, 0.5, 0.5)
    end
end

function Rows.ApplyData(row, member, layout, context)
    if not member then
        row:Hide()

        return
    end

    local unit      = member.unit
    local auras     = member.auras
    local playerKey = member.key or F.fullName(member.name)

    applyRcIcon(row, unit, member, layout, context)
    applyClassBackground(row, member)
    applyName(row, member)

    applyTimedBuff(row.foodIcon, row.foodTime, row.foodOverlay,
        unit, auras.hasFood, auras.foodTime, auras.foodIconID,
        db.food_icon_id, auras.foodAuraID, context)

    applyTimedBuff(row.flaskIcon, row.flaskTime, row.flaskOverlay,
        unit, auras.hasFlask, auras.flaskTime, auras.flaskIconID,
        db.flask_icon_id, auras.flaskAuraID, context)

    applyOil(row, playerKey, context)

    applySimpleBuff(row.augmentIcon, row.augmentOverlay,
        unit, auras.hasAugment, auras.augmentIconID,
        db.augment_icon_id, auras.augmentAuraID)

    applySimpleBuff(row.vantusIcon, row.vantusOverlay,
        unit, auras.hasVantus, auras.vantusIconID,
        db.vantus_icon_id, auras.vantusAuraID)

    applyRaidBuffs(row, unit, auras)
    applyDurability(row, playerKey, context)

    row:Show()
end
