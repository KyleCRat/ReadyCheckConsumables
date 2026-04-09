local _, RCC = ...

local F  = RCC.F
local db = RCC.db

local GetTime            = GetTime
local ceil               = ceil
local floor              = floor
local format             = format
local strsplit           = strsplit
local UnitName           = UnitName
local GetItemInfoInstant = C_Item.GetItemInfoInstant

-------------------------------------------------------------------------------
--- Constants
-------------------------------------------------------------------------------

local ROW_HEIGHT           = 30
local TITLE_HEIGHT         = 28
local ICON_SIZE            = 26
local NAME_WIDTH           = 150
local RC_ICON_WIDTH        = 24
local TIME_WIDTH           = 30
local H_PAD                = 3
local V_PAD                = 0
local FRAME_PAD            = 3
local MAX_ROWS             = 40
local MISSING_ALPHA        = 0.3
local EXPIRE_WARN_SECONDS  = 600  -- 10 minutes
local DURABILITY_WIDTH     = 42
local DURABILITY_THRESHOLD = 50
local COLOR_DUR_GREEN      = { r = 0.2, g = 1,   b = 0.2 }
local COLOR_DUR_YELLOW     = { r = 1,   g = 0.82, b = 0  }
local COLOR_DUR_RED        = { r = 1,   g = 0.2, b = 0.2 }
local MISSING_BG           = { r = 0,   g = 0,   b = 0   }
local COLOR_TIME_NORMAL    = { r = 1,   g = 1,   b = 1   }
local COLOR_TIME_WARN      = { r = 1,   g = 0.2, b = 0.2 }
local COLOR_NAME_NORMAL    = { r = 1,   g = 1,   b = 1   }
local COLOR_NAME_OFFLINE   = { r = 0.5, g = 0.5, b = 0.5 }
local COLOR_NAME_DEAD      = { r = 0.8, g = 0.2, b = 0.2 }
local FONT_SIZE_NAME       = 16
local FONT_SIZE_TIME       = 14
local COLOR_TITLE_BG       = { r = 0, g = 0, b = 0, a = 0.2 }
local COLOR_PROGRESS_BAR   = { r = 0, g = 209/255, b = 255/255, a = 0.6 }

local FONT = "Interface\\AddOns\\"
    .. "ReadyCheckConsumables\\media\\fonts\\PTSansNarrow-Bold.ttf"

local RC_PENDING = 0
local RC_READY   = 1
local RC_NOT     = 2

local RC_TEXTURES = {
    [RC_PENDING] = "Interface\\RaidFrame\\ReadyCheck-Waiting",
    [RC_READY]   = "Interface\\RaidFrame\\ReadyCheck-Ready",
    [RC_NOT]     = "Interface\\RaidFrame\\ReadyCheck-NotReady",
}

local RC_TEXTURE_OFFLINE = "Interface\\CharacterFrame\\Disconnect-Icon"
local RC_ATLAS_DEAD      = "Navigation-Tombstone-Icon"

local COLOR_SUMMARY_NOT_READY = { r = 1,   g = 0.2, b = 0.2 }
local COLOR_SUMMARY_AFK       = { r = 1,   g = 0.82, b = 0  }
local COLOR_SUMMARY_READY     = { r = 0.2, g = 1,   b = 0.2 }

local FRAME_WIDTH = FRAME_PAD
    + RC_ICON_WIDTH + H_PAD
    + NAME_WIDTH + H_PAD
    + TIME_WIDTH + ICON_SIZE + H_PAD  -- food
    + TIME_WIDTH + ICON_SIZE + H_PAD  -- flask
    + TIME_WIDTH + ICON_SIZE + H_PAD  -- oil
    + (ICON_SIZE + H_PAD) * 8         -- rune + vantus + 6 raid buffs
    + DURABILITY_WIDTH + H_PAD        -- durability
    + FRAME_PAD

-- X offsets of each icon column within a row (and title bar), relative to row left edge.
-- These mirror the layout computed in createRow so title icons align with data icons.
local COL_X_FOOD  = RC_ICON_WIDTH + H_PAD + NAME_WIDTH + H_PAD + TIME_WIDTH
local COL_X_FLASK = COL_X_FOOD  + ICON_SIZE + H_PAD + TIME_WIDTH
local COL_X_OIL   = COL_X_FLASK + ICON_SIZE + H_PAD + TIME_WIDTH
local COL_X_RUNE  = COL_X_OIL   + ICON_SIZE + H_PAD
local COL_X_VANTUS = COL_X_RUNE + ICON_SIZE + H_PAD
local COL_X_RAIDBUFF = {}  -- [1..N]
for k = 1, 8 do
    COL_X_RAIDBUFF[k] = COL_X_VANTUS + k * (ICON_SIZE + H_PAD)
end

local COL_X_DURABILITY = COL_X_RAIDBUFF[#db.raidBuffDefs] + ICON_SIZE + H_PAD

-------------------------------------------------------------------------------
--- Raid buff default icons (spell texture IDs)
--- Looked up via C_Spell.GetSpellInfo at load time
-------------------------------------------------------------------------------

local RAID_BUFF_ICONS = {}
local FALLBACK_SPELL_ICON = 134400  -- INV_Misc_QuestionMark

local function resolveRaidBuffIcons()
    for k = 1, #db.raidBuffDefs do
        local spellID = db.raidBuffDefs[k][3]
        local info = C_Spell.GetSpellInfo(spellID)

        RAID_BUFF_ICONS[k] = info and info.iconID or FALLBACK_SPELL_ICON
    end
end

resolveRaidBuffIcons()

-------------------------------------------------------------------------------
--- Durability sharing via addon messages
--- Each RCC user broadcasts their lowest-slot durability percentage on
--- READY_CHECK. Results are stored by short name and displayed in the
--- raid frame. Players without RCC show "?".
-------------------------------------------------------------------------------

local ADDON_PREFIX = "RCC"
local durabilityData = {}  -- [shortName] = percent (0-100)
local oilData        = {}  -- [shortName] = seconds (-1=N/A, 0=missing, >0=remaining)

local MRT_PREFIXES = {
    "EXRTADD", "MRTADDA", "MRTADDB", "MRTADDC", "MRTADDD",
    "MRTADDE", "MRTADDF", "MRTADDG", "MRTADDH", "MRTADDI",
}

local isMrtPrefix = {}

for _, p in ipairs(MRT_PREFIXES) do
    C_ChatInfo.RegisterAddonMessagePrefix(p)
    isMrtPrefix[p] = true
end

local function getPlayerMinDurability()
    local minPct = 100

    for slot = 1, 18 do
        local cur, mx = GetInventoryItemDurability(slot)

        if cur and mx and mx > 0 then
            local pct = cur / mx * 100

            if pct < minPct then
                minPct = pct
            end
        end
    end

    return floor(minPct)
end

local function broadcastDurability()
    local pct = getPlayerMinDurability()
    local playerName = UnitName("player")
    durabilityData[playerName] = pct

    local chatType = F.chatType()

    if chatType ~= "SAY" then
        C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "DUR\t" .. pct, chatType)
    end
end

local function getPlayerOilStatus()
    local mainHandItemID = GetInventoryItemID("player", 16)

    if not mainHandItemID then
        return -1, 0
    end

    local hasMainHandEnchant, mainHandExpiration, _,
          mainHandEnchantID, hasOffHandEnchant, offHandExpiration,
          _, offHandEnchantID = GetWeaponEnchantInfo()

    if not hasMainHandEnchant then
        return 0, 0
    end

    local lowestTime = (mainHandExpiration or 0) / 1000
    local enchData = db.weaponEnchants[mainHandEnchantID or 0]
    local itemID = enchData and enchData.item or 0

    local offhandItemID = GetInventoryItemID("player", 17)

    if offhandItemID then
        local itemClassID = select(6, GetItemInfoInstant(offhandItemID))

        if itemClassID == 2 then
            if not hasOffHandEnchant then
                return 0, 0
            end

            local ohTime = (offHandExpiration or 0) / 1000

            if ohTime < lowestTime then
                lowestTime = ohTime
                local ohData = db.weaponEnchants[offHandEnchantID or 0]
                itemID = ohData and ohData.item or 0
            end
        end
    end

    return floor(lowestTime), itemID
end

local function broadcastOilStatus()
    local oilTime, itemID = getPlayerOilStatus()
    local playerName = UnitName("player")
    oilData[playerName] = { time = oilTime, item = itemID }

    local chatType = F.chatType()

    if chatType ~= "SAY" then
        C_ChatInfo.SendAddonMessage(
            ADDON_PREFIX,
            "OIL\t" .. oilTime .. "\t" .. (itemID or 0),
            chatType
        )
    end
end

-------------------------------------------------------------------------------
--- Frame creation
-------------------------------------------------------------------------------
---

local frame = CreateFrame("Frame", "RCRaidFrame", UIParent, "BackdropTemplate")
RCC.raidFrame = frame

frame:SetSize(FRAME_WIDTH, ROW_HEIGHT * 5 + FRAME_PAD * 2)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:SetFrameStrata("HIGH")
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:Hide()

frame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
frame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
frame:SetBackdropBorderColor(0, 0, 0, 1)

frame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

--- Close button
-- TODO: Extract into function and reduce duplication with the ConsumablesFrame.lua:37
frame.close = CreateFrame("Button", nil, frame,
                                    "SecureHandlerClickTemplate")
frame.close:SetSize(0, 20)
frame.close:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 1, -3)
frame.close:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -1, -3)

frame.close.bg = frame.close:CreateTexture(nil, "BACKGROUND")
frame.close.bg:SetAllPoints()
frame.close.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

frame.close.border = frame.close:CreateTexture(nil, "BORDER")
frame.close.border:SetPoint("TOPLEFT", -1, 1)
frame.close.border:SetPoint("BOTTOMRIGHT", 1, -1)
frame.close.border:SetColorTexture(0, 0, 0, 1)

frame.close.highlight = frame.close:CreateTexture(nil, "ARTWORK")
frame.close.highlight:SetAllPoints(frame.close.bg)
frame.close.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
frame.close.highlight:SetBlendMode("ADD")
frame.close.highlight:Hide()

frame.close.text = frame.close:CreateFontString(nil, "OVERLAY")
frame.close.text:SetPoint("CENTER")
frame.close.text:SetFont(FONT, 12, "OUTLINE")
frame.close.text:SetText(CLOSE or "x")
frame.close.text:SetTextColor(1, 1, 1)

frame.close:SetScript("OnEnter", function(self)
    self.highlight:Show()
end)

frame.close:SetScript("OnLeave", function(self)
    self.highlight:Hide()
end)

frame.close:SetFrameRef("CLLRaidFrame", frame)
frame.close:SetAttribute("_onclick", [[
    self:GetFrameRef("CLLRaidFrame"):Hide()
]])


local function savePosition(self)
    self:StopMovingOrSizing()

    if not ReadyCheckConsumablesDB then
        return
    end

    local point, _, relPoint, x, y = self:GetPoint(1)
    ReadyCheckConsumablesDB.raidFramePos = {
        point    = point,
        relPoint = relPoint,
        x        = x,
        y        = y,
    }
end

frame:SetScript("OnDragStop", savePosition)

local positionRestored = false

local function restorePosition()
    if positionRestored then
        return
    end

    positionRestored = true

    if not ReadyCheckConsumablesDB then
        return
    end

    local pos = ReadyCheckConsumablesDB.raidFramePos

    if not pos then
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
end

-------------------------------------------------------------------------------
--- Title bar
--- Progress bar bg that drains left-to-right over the RC duration.
--- Left side: "X/N" ready count + "Xs" countdown.
--- Right side: per-column CHECK/X summary icons aligned with data rows.
-------------------------------------------------------------------------------

local titleBar = CreateFrame("Frame", nil, frame)
titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  FRAME_PAD, -FRAME_PAD)
titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -FRAME_PAD, -FRAME_PAD)
titleBar:SetHeight(TITLE_HEIGHT)

-- Plain black background
titleBar.bg = titleBar:CreateTexture(nil, "BACKGROUND")
titleBar.bg:SetAllPoints(titleBar)
titleBar.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
titleBar.bg:SetVertexColor(COLOR_TITLE_BG.r, COLOR_TITLE_BG.g, COLOR_TITLE_BG.b, COLOR_TITLE_BG.a)

-- Progress bar (fills left-to-right, drawn over the bg)
titleBar.progress = titleBar:CreateTexture(nil, "BORDER")
titleBar.progress:SetPoint("TOPLEFT",  titleBar, "TOPLEFT")
titleBar.progress:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT")
titleBar.progress:SetTexture("Interface\\Buttons\\WHITE8x8")
titleBar.progress:SetVertexColor(COLOR_PROGRESS_BAR.r, COLOR_PROGRESS_BAR.g, COLOR_PROGRESS_BAR.b, COLOR_PROGRESS_BAR.a)
titleBar.progress:SetWidth(1)
titleBar.progress:Hide()

-- "X/N" ready count label
titleBar.countText = titleBar:CreateFontString(nil, "ARTWORK")
titleBar.countText:SetPoint("LEFT", titleBar, "LEFT", 2, 0)
titleBar.countText:SetFont(FONT, FONT_SIZE_NAME, "OUTLINE")
titleBar.countText:SetTextColor(1, 1, 1)
titleBar.countText:SetText("")

-- Countdown timer label (e.g. "15s")
titleBar.timerText = titleBar:CreateFontString(nil, "ARTWORK")
titleBar.timerText:SetPoint("LEFT", titleBar.countText, "RIGHT", 6, 0)
titleBar.timerText:SetFont(FONT, FONT_SIZE_NAME, "OUTLINE")
titleBar.timerText:SetTextColor(1, 1, 1)
titleBar.timerText:SetText("")

-- Per-column summary icons (CHECK or X), one per buff column
-- Indices: 1=food, 2=flask, 3=oil, 4=rune, 5=vantus, 6..11=raid buffs, 12=durability
local TITLE_COL_X = {
    COL_X_FOOD,
    COL_X_FLASK,
    COL_X_OIL,
    COL_X_RUNE,
    COL_X_VANTUS,
}
for k = 1, 6 do
    TITLE_COL_X[5 + k] = COL_X_RAIDBUFF[k]
end

TITLE_COL_X[#TITLE_COL_X + 1] = COL_X_DURABILITY + (DURABILITY_WIDTH - ICON_SIZE) / 2

titleBar.colIcons = {}
for i = 1, #TITLE_COL_X do
    local icon = titleBar:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", titleBar, "LEFT", TITLE_COL_X[i], 0)
    icon:SetTexture(RC_TEXTURES[RC_PENDING])
    titleBar.colIcons[i] = icon
end

-------------------------------------------------------------------------------
--- Tooltip overlay helper
-------------------------------------------------------------------------------

local function onOverlayEnter(self)
    local unit    = self.unit
    local auraID  = self.auraID
    local spellID = self.spellID
    local itemID  = self.itemID
    local label   = self.label

    if auraID and unit then
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

-------------------------------------------------------------------------------
--- Icon background helper
--- Places a dark red BACKGROUND texture behind an icon texture.
--- Call after the icon texture is positioned so the bg matches its location.
-------------------------------------------------------------------------------

local function createIconBg(row, icon)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT",     icon, "TOPLEFT")
    bg:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(MISSING_BG.r, MISSING_BG.g, MISSING_BG.b, 1)
end

-------------------------------------------------------------------------------
--- Row creation (pre-allocate 40 rows)
-------------------------------------------------------------------------------

frame.rows = {}

local function createRow(index)
    local row = CreateFrame("Frame", nil, frame)
    row:SetSize(FRAME_WIDTH - FRAME_PAD * 2, ROW_HEIGHT)
    row:Hide()

    local x = 0

    -- Ready check icon
    row.rcIcon = row:CreateTexture(nil, "ARTWORK")
    row.rcIcon:SetPoint("CENTER", row, "LEFT", x + RC_ICON_WIDTH / 2, 0)
    row.rcIcon:SetSize(RC_ICON_WIDTH, RC_ICON_WIDTH)
    row.rcIcon:SetTexture(RC_TEXTURES[RC_PENDING])
    x = x + RC_ICON_WIDTH + H_PAD

    -- Row background (class color)
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints(row)
    row.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    row.bg:SetVertexColor(1, 1, 1, 0.25)

    -- Player name
    row.nameText = row:CreateFontString(nil, "ARTWORK")
    row.nameText:SetPoint("LEFT", row, "LEFT", x, 0)
    row.nameText:SetFont(FONT, FONT_SIZE_NAME, "OUTLINE")
    row.nameText:SetWidth(NAME_WIDTH)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWordWrap(false)
    x = x + NAME_WIDTH + H_PAD

    -- Food time + icon
    row.foodTime = row:CreateFontString(nil, "ARTWORK")
    row.foodTime:SetPoint("LEFT", row, "LEFT", x, 0)
    row.foodTime:SetFont(FONT, FONT_SIZE_TIME, "OUTLINE")
    row.foodTime:SetWidth(TIME_WIDTH)
    row.foodTime:SetJustifyH("RIGHT")
    x = x + TIME_WIDTH

    row.foodIcon = row:CreateTexture(nil, "ARTWORK")
    row.foodIcon:SetPoint("LEFT", row, "LEFT", x, 0)
    row.foodIcon:SetSize(ICON_SIZE, ICON_SIZE)
    row.foodIcon:SetTexture(db.food_icon_id)
    createIconBg(row, row.foodIcon)
    row.foodOverlay = createOverlay(row, row.foodIcon)
    row.foodOverlay.label = "Food: Missing"
    x = x + ICON_SIZE + H_PAD

    -- Flask time + icon
    row.flaskTime = row:CreateFontString(nil, "ARTWORK")
    row.flaskTime:SetPoint("LEFT", row, "LEFT", x, 0)
    row.flaskTime:SetFont(FONT, FONT_SIZE_TIME, "OUTLINE")
    row.flaskTime:SetWidth(TIME_WIDTH)
    row.flaskTime:SetJustifyH("RIGHT")
    x = x + TIME_WIDTH

    row.flaskIcon = row:CreateTexture(nil, "ARTWORK")
    row.flaskIcon:SetPoint("LEFT", row, "LEFT", x, 0)
    row.flaskIcon:SetSize(ICON_SIZE, ICON_SIZE)
    row.flaskIcon:SetTexture(db.flask_icon_id)
    createIconBg(row, row.flaskIcon)
    row.flaskOverlay = createOverlay(row, row.flaskIcon)
    row.flaskOverlay.label = "Flask: Missing"
    x = x + ICON_SIZE + H_PAD

    -- Oil time + icon
    row.oilTime = row:CreateFontString(nil, "ARTWORK")
    row.oilTime:SetPoint("LEFT", row, "LEFT", x, 0)
    row.oilTime:SetFont(FONT, FONT_SIZE_TIME, "OUTLINE")
    row.oilTime:SetWidth(TIME_WIDTH)
    row.oilTime:SetJustifyH("RIGHT")
    x = x + TIME_WIDTH

    row.oilIcon = row:CreateTexture(nil, "ARTWORK")
    row.oilIcon:SetPoint("LEFT", row, "LEFT", x, 0)
    row.oilIcon:SetSize(ICON_SIZE, ICON_SIZE)
    row.oilIcon:SetTexture(db.weapon_enchant_icon_id)
    createIconBg(row, row.oilIcon)
    row.oilOverlay = createOverlay(row, row.oilIcon)
    row.oilOverlay.label = "Weapon Oil: Unknown"
    x = x + ICON_SIZE + H_PAD

    -- Augment Rune icon
    row.runeIcon = row:CreateTexture(nil, "ARTWORK")
    row.runeIcon:SetPoint("LEFT", row, "LEFT", x, 0)
    row.runeIcon:SetSize(ICON_SIZE, ICON_SIZE)
    row.runeIcon:SetTexture(db.rune_icon_id)
    createIconBg(row, row.runeIcon)
    row.runeOverlay = createOverlay(row, row.runeIcon)
    row.runeOverlay.label = "Augment Rune: Missing"
    x = x + ICON_SIZE + H_PAD

    -- Vantus Rune icon
    row.vantusIcon = row:CreateTexture(nil, "ARTWORK")
    row.vantusIcon:SetPoint("LEFT", row, "LEFT", x, 0)
    row.vantusIcon:SetSize(ICON_SIZE, ICON_SIZE)
    row.vantusIcon:SetTexture(db.vantus_icon_id)
    createIconBg(row, row.vantusIcon)
    row.vantusOverlay = createOverlay(row, row.vantusIcon)
    row.vantusOverlay.label = "Vantus Rune: Missing"
    x = x + ICON_SIZE + H_PAD

    -- 6 Raid buff icons
    row.raidBuffIcons    = {}
    row.raidBuffOverlays = {}

    for k = 1, #db.raidBuffDefs do
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("LEFT", row, "LEFT", x, 0)
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetTexture(RAID_BUFF_ICONS[k])
        createIconBg(row, icon)
        row.raidBuffIcons[k] = icon

        local overlay = createOverlay(row, icon)
        overlay.spellID = db.raidBuffDefs[k][3]
        row.raidBuffOverlays[k] = overlay
        x = x + ICON_SIZE + H_PAD
    end

    -- Durability percentage
    row.durabilityText = row:CreateFontString(nil, "ARTWORK")
    row.durabilityText:SetPoint("LEFT", row, "LEFT", x, 0)
    row.durabilityText:SetFont(FONT, FONT_SIZE_TIME, "OUTLINE")
    row.durabilityText:SetWidth(DURABILITY_WIDTH)
    row.durabilityText:SetJustifyH("CENTER")
    row.durabilityText:SetText("?")
    row.durabilityText:SetTextColor(0.5, 0.5, 0.5)

    -- Anchor row in frame (row 1 sits below the title bar)
    if index == 1 then
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PAD, -(FRAME_PAD + TITLE_HEIGHT + FRAME_PAD + V_PAD))
    else
        row:SetPoint("TOPLEFT", frame.rows[index - 1], "BOTTOMLEFT", 0, -V_PAD)
    end

    return row
end

for i = 1, MAX_ROWS do
    frame.rows[i] = createRow(i)
end

-------------------------------------------------------------------------------
--- Member data storage
-------------------------------------------------------------------------------

local memberData  = {}  -- [i] = { name, unit, class, online, isDead, auras }
local unitToIndex = {}  -- [unit] = i
local rcStatus    = {}  -- [unit] = RC_PENDING | RC_READY | RC_NOT
local activeCount = 0

-------------------------------------------------------------------------------
--- Aura scanning
-------------------------------------------------------------------------------

local function scanMemberAuras(unit, now)
    local result = {
        hasFood  = false, foodTime  = 0, foodAuraID  = nil, foodIconID  = nil,
        hasFlask = false, flaskTime = 0, flaskAuraID = nil, flaskIconID = nil,
        hasRune  = false, runeAuraID  = nil, runeIconID  = nil,
        hasVantus = false, vantusAuraID = nil, vantusIconID = nil,
        raidBuff = {},
    }

    local buffsList = db.raidBuffDefs

    for k = 1, #buffsList do
        result.raidBuff[k] = false
    end

    for i = 1, 60 do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")

        if not aura then
            break
        end

        if not issecretvalue(aura.spellId) then
            local sid = aura.spellId
            local icon = aura.icon
            local expiry = aura.expirationTime

            if db.foodBuffIDs[sid] or db.foodIconIDs[icon] then
                if not result.hasFood or icon == db.foodWellFedIconID then
                    result.hasFood    = true
                    result.foodTime   = expiry - now
                    result.foodAuraID = aura.auraInstanceID
                    result.foodIconID = icon
                end
            end

            if not result.hasFlask and db.flaskBuffIDs[sid] then
                result.hasFlask    = true
                result.flaskTime   = expiry - now
                result.flaskAuraID = aura.auraInstanceID
                result.flaskIconID = icon
            end

            if not result.hasRune and db.runeBuffIDs[sid] then
                result.hasRune    = true
                result.runeAuraID = aura.auraInstanceID
                result.runeIconID = icon
            end

            if not result.hasVantus and db.vantusBuffIDs[sid] then
                result.hasVantus    = true
                result.vantusAuraID = aura.auraInstanceID
                result.vantusIconID = icon
            end

            for k = 1, #buffsList do
                if not result.raidBuff[k] then
                    local b = buffsList[k]

                    if sid == b[3]
                        or (b[4] and sid == b[4])
                        or (b[5] and b[5][sid])
                    then
                        result.raidBuff[k] = aura.auraInstanceID or true
                    end
                end
            end
        end
    end

    return result
end

-------------------------------------------------------------------------------
--- Roster scanning
-------------------------------------------------------------------------------

local function scanAllMembers()
    local maxGroup = F.GetRaidDiffMaxGroup()
    local now = GetTime()
    local count = 0

    wipe(memberData)
    wipe(unitToIndex)

    for j = 1, 40 do
        local name, unit, subgroup, class = F.GetRosterInfo(j)

        if not name then
            if not IsInRaid() then
                break
            end
        elseif subgroup <= maxGroup then
            count = count + 1
            local online = UnitIsConnected(unit)
            local isDead = UnitIsDeadOrGhost(unit)
            memberData[count] = {
                name   = name,
                unit   = unit,
                class  = class,
                online = online,
                isDead = isDead,
                auras  = scanMemberAuras(unit, now),
            }

            unitToIndex[unit] = count

            if not rcStatus[unit] then
                rcStatus[unit] = RC_PENDING
            end
        end
    end

    activeCount = count
end

-------------------------------------------------------------------------------
--- Test data generation
-------------------------------------------------------------------------------

local ALL_CLASSES = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK",
    "DRUID", "DEMONHUNTER", "EVOKER",
}

local TEST_NAMES = {
    "Thunderclap", "Lightforge", "Windrunner", "Shadowstep", "Faithweaver",
    "Frostmourne", "Tidecaller", "Frostbolt", "Felblood", "Mistwalker",
    "Moonfire", "Havocblade", "Scalewing",
}

local function randomBool()
    return math.random() > 0.35
end

local function generateTestAuras()
    local numBuffs = #db.raidBuffDefs
    local raidBuff = {}

    for k = 1, numBuffs do
        raidBuff[k] = randomBool() and true or false
    end

    local hasFood  = randomBool()
    local hasFlask = randomBool()
    local hasRune  = randomBool()
    local hasVantus = randomBool()

    return {
        hasFood     = hasFood,
        foodTime    = hasFood and math.random(60, 3600) or 0,
        foodAuraID  = nil,
        foodIconID  = hasFood and db.food_icon_id or nil,
        hasFlask    = hasFlask,
        flaskTime   = hasFlask and math.random(60, 3600) or 0,
        flaskAuraID = nil,
        flaskIconID = hasFlask and db.flask_icon_id or nil,
        hasRune     = hasRune,
        runeAuraID  = nil,
        runeIconID  = hasRune and db.rune_icon_id or nil,
        hasVantus   = hasVantus,
        vantusAuraID = nil,
        vantusIconID = hasVantus and db.vantus_icon_id or nil,
        raidBuff    = raidBuff,
    }
end

local function generateTestData()
    wipe(memberData)
    wipe(unitToIndex)
    wipe(rcStatus)
    wipe(durabilityData)
    wipe(oilData)

    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")

    memberData[1] = {
        name   = playerName,
        unit   = "player",
        class  = playerClass,
        online = true,
        isDead = false,
        auras  = scanMemberAuras("player", GetTime()),
    }
    unitToIndex["player"] = 1
    rcStatus["player"] = RC_READY

    local count = 1

    for i = 1, #ALL_CLASSES do
        if ALL_CLASSES[i] ~= playerClass then
            count = count + 1
            local fakeUnit = "raid" .. count
            local name = TEST_NAMES[i]

            memberData[count] = {
                name   = name,
                unit   = fakeUnit,
                class  = ALL_CLASSES[i],
                online = math.random() > 0.1,
                isDead = math.random() > 0.9,
                auras  = generateTestAuras(),
            }

            unitToIndex[fakeUnit] = count
            rcStatus[fakeUnit] = RC_PENDING

            local shortName = F.shortName(name)
            durabilityData[shortName] = math.random(10, 100)

            local oilRoll = math.random()
            if oilRoll < 0.5 then
                oilData[shortName] = { time = math.random(60, 3600), item = 0 }
            elseif oilRoll < 0.7 then
                oilData[shortName] = { time = 0, item = 0 }
            elseif oilRoll < 0.85 then
                oilData[shortName] = { time = -1, item = 0 }
            end
        end
    end

    activeCount = count
end

-------------------------------------------------------------------------------
--- Formatting helpers
-------------------------------------------------------------------------------

local function formatDuration(seconds)
    local mins = ceil(seconds / 60)

    if mins >= 60 then
        return format("%dh", ceil(seconds / 3600))
    end

    return format("%dm", mins > 0 and mins or 0)
end

-------------------------------------------------------------------------------
--- Row rendering
-------------------------------------------------------------------------------

local function applyRowData(row, member)
    if not member then
        row:Hide()

        return
    end

    local unit  = member.unit
    local auras = member.auras

    -- Ready check icon
    local status = rcStatus[unit] or RC_PENDING

    if status == RC_NOT and not member.online then
        row.rcIcon:SetSize(RC_ICON_WIDTH, RC_ICON_WIDTH)
        row.rcIcon:SetTexture(RC_TEXTURE_OFFLINE)
    elseif status == RC_PENDING and member.isDead then
        row.rcIcon:SetSize(RC_ICON_WIDTH * 26 / 33, RC_ICON_WIDTH)
        row.rcIcon:SetAtlas(RC_ATLAS_DEAD)
    else
        row.rcIcon:SetSize(RC_ICON_WIDTH, RC_ICON_WIDTH)
        row.rcIcon:SetTexture(RC_TEXTURES[status])
    end

    -- Row background (class color)
    local color = RAID_CLASS_COLORS[member.class]

    if color then
        row.bg:SetVertexColor(color.r, color.g, color.b, 0.25)
    else
        row.bg:SetVertexColor(0.5, 0.5, 0.5, 0.25)
    end

    -- Player name (white)
    local shortName = F.shortName(member.name)

    if not member.online then
        row.nameText:SetTextColor(COLOR_NAME_OFFLINE.r, COLOR_NAME_OFFLINE.g, COLOR_NAME_OFFLINE.b)
    elseif member.isDead then
        row.nameText:SetTextColor(COLOR_NAME_DEAD.r, COLOR_NAME_DEAD.g, COLOR_NAME_DEAD.b)
    else
        row.nameText:SetTextColor(COLOR_NAME_NORMAL.r, COLOR_NAME_NORMAL.g, COLOR_NAME_NORMAL.b)
    end

    row.nameText:SetText(shortName)

    -- Food
    if auras.hasFood then
        row.foodIcon:SetDesaturated(false)
        row.foodIcon:SetVertexColor(1, 1, 1, 1)
        row.foodIcon:SetTexture(auras.foodIconID or db.food_icon_id)
        row.foodTime:SetText(formatDuration(auras.foodTime))

        if auras.foodTime < EXPIRE_WARN_SECONDS then
            row.foodTime:SetTextColor(COLOR_TIME_WARN.r, COLOR_TIME_WARN.g, COLOR_TIME_WARN.b)
        else
            row.foodTime:SetTextColor(COLOR_TIME_NORMAL.r, COLOR_TIME_NORMAL.g, COLOR_TIME_NORMAL.b)
        end
    else
        row.foodIcon:SetTexture(db.food_icon_id)
        row.foodIcon:SetDesaturated(true)
        row.foodIcon:SetVertexColor(1, 1, 1, MISSING_ALPHA)
        row.foodTime:SetText("")
    end

    row.foodOverlay.unit   = unit
    row.foodOverlay.auraID = auras.foodAuraID

    -- Flask
    if auras.hasFlask then
        row.flaskIcon:SetDesaturated(false)
        row.flaskIcon:SetVertexColor(1, 1, 1, 1)
        row.flaskIcon:SetTexture(auras.flaskIconID or db.flask_icon_id)
        row.flaskTime:SetText(formatDuration(auras.flaskTime))

        if auras.flaskTime < EXPIRE_WARN_SECONDS then
            row.flaskTime:SetTextColor(COLOR_TIME_WARN.r, COLOR_TIME_WARN.g, COLOR_TIME_WARN.b)
        else
            row.flaskTime:SetTextColor(COLOR_TIME_NORMAL.r, COLOR_TIME_NORMAL.g, COLOR_TIME_NORMAL.b)
        end
    else
        row.flaskIcon:SetTexture(db.flask_icon_id)
        row.flaskIcon:SetDesaturated(true)
        row.flaskIcon:SetVertexColor(1, 1, 1, MISSING_ALPHA)
        row.flaskTime:SetText("")
    end

    row.flaskOverlay.unit   = unit
    row.flaskOverlay.auraID = auras.flaskAuraID

    -- Weapon Oil
    local shortName = F.shortName(member.name)
    local oil = oilData[shortName]
    local oilTime = oil and oil.time
    local oilItemID = oil and oil.item or 0

    row.oilOverlay.itemID = nil
    row.oilOverlay.label  = nil

    if oilTime and oilTime > 0 then
        row.oilIcon:SetDesaturated(false)
        row.oilIcon:SetVertexColor(1, 1, 1, 1)
        row.oilTime:SetText(formatDuration(oilTime))

        if oilTime < EXPIRE_WARN_SECONDS then
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
        row.oilIcon:SetTexture(db.weapon_enchant_icon_id)
        row.oilIcon:SetDesaturated(true)
        row.oilIcon:SetVertexColor(1, 1, 1, MISSING_ALPHA)
        row.oilTime:SetText("")
        row.oilOverlay.label = "Weapon Oil: Missing"
    elseif oilTime == -1 then
        row.oilIcon:SetTexture(db.weapon_enchant_icon_id)
        row.oilIcon:SetDesaturated(true)
        row.oilIcon:SetVertexColor(1, 1, 1, MISSING_ALPHA)
        row.oilTime:SetText("")
        row.oilOverlay.label = "Weapon Oil: N/A"
    else
        row.oilIcon:SetTexture(db.weapon_enchant_icon_id)
        row.oilIcon:SetDesaturated(true)
        row.oilIcon:SetVertexColor(1, 1, 1, MISSING_ALPHA)
        row.oilTime:SetText("?")
        row.oilTime:SetTextColor(0.5, 0.5, 0.5)
        row.oilOverlay.label = "Weapon Oil: Unknown"
    end

    -- Augment Rune
    row.runeIcon:SetTexture(auras.runeIconID or db.rune_icon_id)
    row.runeIcon:SetDesaturated(not auras.hasRune)
    row.runeIcon:SetVertexColor(1, 1, 1, auras.hasRune and 1 or MISSING_ALPHA)
    row.runeOverlay.unit   = unit
    row.runeOverlay.auraID = auras.runeAuraID

    -- Vantus Rune
    row.vantusIcon:SetTexture(auras.vantusIconID or db.vantus_icon_id)
    row.vantusIcon:SetDesaturated(not auras.hasVantus)
    row.vantusIcon:SetVertexColor(1, 1, 1, auras.hasVantus and 1 or MISSING_ALPHA)
    row.vantusOverlay.unit   = unit
    row.vantusOverlay.auraID = auras.vantusAuraID

    -- Raid buffs
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

    -- Durability
    local durPct = durabilityData[shortName]

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

    row:Show()
end

-------------------------------------------------------------------------------
--- Title bar helpers
-------------------------------------------------------------------------------

-- Returns true if the column buff is considered "bad" for a member.
-- bad = missing, or (food/flask) present but expiring soon.
local DURABILITY_COL_INDEX = 5 + #db.raidBuffDefs + 1

local function isBad(member, colIndex)
    local a = member.auras

    if colIndex == 1 then
        return not a.hasFood or a.foodTime < EXPIRE_WARN_SECONDS
    end

    if colIndex == 2 then
        return not a.hasFlask or a.flaskTime < EXPIRE_WARN_SECONDS
    end

    if colIndex == 3 then
        local oil = oilData[F.shortName(member.name)]
        local oilTime = oil and oil.time

        if oilTime == nil or oilTime == -1 then
            return false
        end

        return oilTime == 0 or oilTime < EXPIRE_WARN_SECONDS
    end

    if colIndex == 4 then
        return not a.hasRune
    end

    if colIndex == 5 then
        return not a.hasVantus
    end

    if colIndex == DURABILITY_COL_INDEX then
        local pct = durabilityData[F.shortName(member.name)]

        if not pct then
            return false
        end

        return pct < DURABILITY_THRESHOLD
    end

    local raidIdx = colIndex - 5
    return not a.raidBuff[raidIdx] or a.raidBuff[raidIdx] == false
end

local function refreshTitleBar()
    local numCols = #titleBar.colIcons

    for i = 1, numCols do
        local anyBad = false

        for j = 1, activeCount do
            local member = memberData[j]

            if member and member.online and isBad(member, i) then
                anyBad = true
                break
            end
        end

        titleBar.colIcons[i]:SetTexture(anyBad and RC_TEXTURES[RC_NOT] or RC_TEXTURES[RC_READY])
    end
end

local function updateTitleCount()
    local readyCount = 0

    for unit in pairs(unitToIndex) do
        local status = rcStatus[unit]

        if status == RC_READY or status == RC_NOT then
            readyCount = readyCount + 1
        end
    end

    titleBar.countText:SetTextColor(1, 1, 1)
    titleBar.countText:SetText(readyCount .. "/" .. activeCount)

    return readyCount
end

local function showFinishedSummary()
    local notReadyCount = 0
    local afkCount      = 0

    for i = 1, activeCount do
        local member = memberData[i]

        if not member then break end

        local status = rcStatus[member.unit]

        if status == RC_PENDING then
            afkCount = afkCount + 1
        elseif status == RC_NOT then
            notReadyCount = notReadyCount + 1
        end
    end

    if notReadyCount > 0 then
        local c = COLOR_SUMMARY_NOT_READY
        titleBar.countText:SetTextColor(c.r, c.g, c.b)
        local s = notReadyCount == 1 and "Player" or "Players"
        titleBar.countText:SetText(notReadyCount .. " " .. s .. " not Ready")
    elseif afkCount > 0 then
        local c = COLOR_SUMMARY_AFK
        titleBar.countText:SetTextColor(c.r, c.g, c.b)
        local verb = afkCount == 1 and "Player is" or "Players are"
        titleBar.countText:SetText(afkCount .. " " .. verb .. " AFK")
    else
        local c = COLOR_SUMMARY_READY
        titleBar.countText:SetTextColor(c.r, c.g, c.b)
        titleBar.countText:SetText("Everyone is Ready!")
    end
end

local function refreshRow(index)
    local row = frame.rows[index]

    if not row then
        return
    end

    applyRowData(row, memberData[index])
    refreshTitleBar()
end

local function refreshAllRows()
    for i = 1, activeCount do
        applyRowData(frame.rows[i], memberData[i])
    end

    for i = activeCount + 1, MAX_ROWS do
        frame.rows[i]:Hide()
    end

    local height = FRAME_PAD * 2
        + TITLE_HEIGHT + FRAME_PAD
        + activeCount * ROW_HEIGHT
        + (activeCount > 1 and (activeCount - 1) * V_PAD or 0)

    frame:SetHeight(height)
    refreshTitleBar()
end

-------------------------------------------------------------------------------
--- Ready check lifecycle
-------------------------------------------------------------------------------

local MIN_SHOW_TIME = 15

local hideTimer
local progressTextTimer
local showStartTime = 0

local function cancelHideTimer()
    if hideTimer then
        hideTimer:Cancel()
        hideTimer = nil
    end
end

local function stopProgressBar()
    titleBar.progress:Hide()
    titleBar:SetScript("OnUpdate", nil)

    if progressTextTimer then
        progressTextTimer:Cancel()
        progressTextTimer = nil
    end

    titleBar.timerText:SetText("")
end

local function startProgressBar(duration)
    local barWidth = FRAME_WIDTH - FRAME_PAD * 2
    local endTime = GetTime() + duration

    titleBar.progress:SetWidth(barWidth)
    titleBar.progress:Show()
    titleBar.timerText:SetText(ceil(duration) .. "s")

    titleBar:SetScript("OnUpdate", function()
        local remaining = endTime - GetTime()

        if remaining <= 0 then
            stopProgressBar()

            return
        end

        titleBar.progress:SetWidth(math.max(1, barWidth * remaining / duration))
    end)

    progressTextTimer = C_Timer.NewTicker(1, function(ticker)
        local remaining = endTime - GetTime()

        if remaining <= 0 then
            ticker:Cancel()

            return
        end

        titleBar.timerText:SetText(ceil(remaining) .. "s")
    end)
end

function frame:OnReadyCheck(initiatorUnit, timeToHide)
    if not RCC.GetSetting("raidFrame_enabled") then
        return
    end

    cancelHideTimer()
    wipe(rcStatus)
    wipe(durabilityData)
    wipe(oilData)
    broadcastDurability()
    broadcastOilStatus()

    self.manualShow = (timeToHide == 0)
    showStartTime = GetTime()

    scanAllMembers()

    -- The initiator never receives READY_CHECK_CONFIRM for themselves;
    -- auto-mark them as ready so their row shows a check immediately.
    if initiatorUnit then
        for unit in pairs(unitToIndex) do
            if UnitIsUnit(unit, initiatorUnit) then
                rcStatus[unit] = RC_READY
                break
            end
        end
    end

    refreshAllRows()
    updateTitleCount()

    if not self.manualShow then
        startProgressBar(timeToHide or 30)
    else
        stopProgressBar()
        titleBar.timerText:SetText("")
    end

    restorePosition()
    self:SetScale(RCC.GetSetting("raidFrame_scale"))
    self:Show()
end

local TEST_DURATION = 15

function frame:OnTestReadyCheck()
    cancelHideTimer()

    self.manualShow = false
    showStartTime = GetTime()

    generateTestData()
    broadcastDurability()
    broadcastOilStatus()

    refreshAllRows()
    updateTitleCount()
    startProgressBar(TEST_DURATION)

    restorePosition()
    self:SetScale(RCC.GetSetting("raidFrame_scale"))
    self:Show()

    for unit in pairs(unitToIndex) do
        if unit ~= "player" then
            local roll = math.random()

            if roll > 0.25 then
                local delay = math.random(1, TEST_DURATION)
                local ready = roll > 0.5

                C_Timer.After(delay, function()
                    if not self:IsShown() then
                        return
                    end

                    self:OnReadyCheckConfirm(unit, ready)
                end)
            end
        end
    end
end

function frame:OnReadyCheckConfirm(unit, ready)
    local index = unitToIndex[unit]

    if not index then
        return
    end

    rcStatus[unit] = ready and RC_READY or RC_NOT

    local row = self.rows[index]

    if row then
        local member = memberData[index]
        local newStatus = rcStatus[unit]

        row.rcIcon:SetSize(RC_ICON_WIDTH, RC_ICON_WIDTH)

        if newStatus == RC_NOT and member and not member.online then
            row.rcIcon:SetTexture(RC_TEXTURE_OFFLINE)
        else
            row.rcIcon:SetTexture(RC_TEXTURES[newStatus])
        end
    end

    local responded = updateTitleCount()

    if responded >= activeCount then
        stopProgressBar()
        showFinishedSummary()
    end
end

function frame:OnReadyCheckFinished()
    stopProgressBar()
    showFinishedSummary()

    if self.manualShow then
        return
    end

    cancelHideTimer()

    local elapsed = GetTime() - showStartTime
    local delay = max(MIN_SHOW_TIME - elapsed, 0)

    hideTimer = C_Timer.NewTimer(delay, function()
        if not InCombatLockdown() then
            frame:Hide()
        end
    end)
end

function frame:OnCombat()
    cancelHideTimer()
    self:Hide()
end

function frame:OnUnitAura(unit)
    local index = unitToIndex[unit]

    if not index then
        return
    end

    local member = memberData[index]

    if not member then
        return
    end

    member.online = UnitIsConnected(unit)
    member.isDead  = UnitIsDeadOrGhost(unit)
    member.auras   = scanMemberAuras(unit, GetTime())
    refreshRow(index)
end

function frame:OnHide()
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("READY_CHECK_CONFIRM")
    self:UnregisterEvent("UPDATE_INVENTORY_DURABILITY")
    self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
    cancelHideTimer()
    stopProgressBar()
    self.manualShow = false
end

-------------------------------------------------------------------------------
--- Event wiring
-------------------------------------------------------------------------------

frame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
    if event == "READY_CHECK" then
        if InCombatLockdown() then
            return
        end

        local initiatorUnit, duration = arg1, arg2
        self:OnReadyCheck(initiatorUnit, duration)
        self:RegisterEvent("UNIT_AURA")
        self:RegisterEvent("READY_CHECK_CONFIRM")
        self:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
        self:RegisterEvent("UNIT_INVENTORY_CHANGED")

        return
    end

    if event == "READY_CHECK_CONFIRM" then
        local unit, isReady = arg1, arg2
        self:OnReadyCheckConfirm(unit, isReady)

        return
    end

    if event == "READY_CHECK_FINISHED" then
        self:OnReadyCheckFinished()

        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        self:OnCombat()

        return
    end

    if event == "UPDATE_INVENTORY_DURABILITY" then
        broadcastDurability()
        refreshAllRows()

        return
    end

    if event == "UNIT_INVENTORY_CHANGED" then
        if arg1 == "player" then
            broadcastOilStatus()
            refreshAllRows()
        end

        return
    end

    if event == "UNIT_AURA" then
        local unit = arg1
        self:OnUnitAura(unit)

        return
    end

    if event == "CHAT_MSG_ADDON" then
        if arg1 == ADDON_PREFIX then
            local msgType, val1, val2 = strsplit("\t", arg2)

            if msgType == "DUR" then
                local pct = tonumber(val1)

                if pct and arg4 then
                    durabilityData[F.shortName(arg4)] = pct

                    if self:IsShown() then
                        refreshAllRows()
                    end
                end

            elseif msgType == "OIL" then
                local oilTime = tonumber(val1)
                local itemID = tonumber(val2) or 0

                if oilTime and arg4 then
                    oilData[F.shortName(arg4)] = {
                        time = oilTime,
                        item = itemID,
                    }

                    if self:IsShown() then
                        refreshAllRows()
                    end
                end
            end

        elseif isMrtPrefix[arg1] then
            local module, msgType, _, durStr = strsplit("\t", arg2)

            if module == "raidcheck" and msgType == "DUR" and durStr then
                local pct = tonumber(durStr)

                if pct and arg4 then
                    durabilityData[F.shortName(arg4)] = floor(pct)

                    if self:IsShown() then
                        refreshAllRows()
                    end
                end
            end
        end

        return
    end

    if event == "ADDON_LOADED" then
        local addonName = arg1

        if addonName == "ReadyCheckConsumables" then
            ReadyCheckConsumablesDB = ReadyCheckConsumablesDB or {}
            self:UnregisterEvent("ADDON_LOADED")
        end

        return
    end
end)

frame:SetScript("OnHide", function(self)
    self:OnHide()
end)

frame:RegisterEvent("READY_CHECK")
frame:RegisterEvent("READY_CHECK_FINISHED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("ADDON_LOADED")
