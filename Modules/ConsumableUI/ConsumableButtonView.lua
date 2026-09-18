local _, RCC = ...

RCC.ConsumableButtonView = RCC.ConsumableButtonView or {}

local View = RCC.ConsumableButtonView
local Catalog = RCC.ConsumableCatalog
local Glow = RCC.ConsumableGlow
local State = RCC.ConsumableState
local Tooltips = RCC.ConsumableTooltips
local UI = RCC.UI

local GetItemReagentQualityInfo = C_TradeSkillUI.GetItemReagentQualityInfo

local SIZE = 48
local SPACING = 2
local FONT = UI.FONT
local DETAIL_TEXT_SIZE = 16
local COUNT_TEXT_SIZE = 14
local QUALITY_ICON_SIZE = 28
local NORMAL_COLOR = { r = 1, g = 1, b = 1 }
local BAD_COLOR = { r = 1, g = 0.2, b = 0.2 }

View.SIZE = SIZE
View.SPACING = SPACING

local function getRenderCache(button)
    button.rccConsumableRenderCache = button.rccConsumableRenderCache or {
        count = {},
        detail = {},
    }

    return button.rccConsumableRenderCache
end

local function applyText(fontString, cache, text, bad, shown)
    if cache.text ~= text then
        fontString:SetText(text)
        cache.text = text
    end

    if cache.bad ~= bad then
        local color = bad and BAD_COLOR or NORMAL_COLOR

        fontString:SetTextColor(color.r, color.g, color.b)
        cache.bad = bad
    end

    if cache.shown ~= shown then
        fontString:SetShown(shown)
        cache.shown = shown
    end
end

local function applyStatusIcon(button, state)
    local cache = getRenderCache(button)
    local texture = button.statustexture
    local desaturated = state.statusTextureDesaturated == true
    local shown = state.showStatusTexture == true and not button.hideStatusTexture

    if cache.statusIcon ~= state.statusIcon then
        UI.SetStatusIcon(texture, state.statusIcon)
        cache.statusIcon = state.statusIcon
    end

    if cache.statusDesaturated ~= desaturated then
        texture:SetDesaturated(desaturated)
        cache.statusDesaturated = desaturated
    end

    if cache.statusAlpha ~= state.statusTextureAlpha then
        texture:SetAlpha(state.statusTextureAlpha)
        cache.statusAlpha = state.statusTextureAlpha
    end

    if cache.statusShown ~= shown then
        texture:SetShown(shown)
        cache.statusShown = shown
    end
end

local function setQualityOverlay(button, itemID, atlas, resolved)
    local qualityIcon = button.qualityIcon
    local cache = getRenderCache(button)

    if button.hideQualityIcon or not itemID then
        cache.qualityItemID = nil

        if qualityIcon:IsShown() then
            qualityIcon:Hide()
        end

        return
    end

    if cache.qualityItemID == itemID and cache.qualityAtlas == atlas and qualityIcon:IsShown() then
        return
    end

    if not atlas and not resolved then
        local info = GetItemReagentQualityInfo(itemID)

        atlas = info and info.iconSmall
    end

    if not atlas then
        cache.qualityItemID = nil

        if qualityIcon:IsShown() then
            qualityIcon:Hide()
        end

        return
    end

    cache.qualityItemID = itemID

    if cache.qualityAtlas ~= atlas then
        qualityIcon:SetAtlas(atlas, false)
        cache.qualityAtlas = atlas
    end

    if not qualityIcon:IsShown() then
        qualityIcon:Show()
    end
end

local function applyCooldown(button, cooldown)
    if not button.cooldown then return end

    local cache = getRenderCache(button)

    if cooldown and cooldown.start and cooldown.duration then
        if cache.cooldownStart == cooldown.start
            and cache.cooldownDuration == cooldown.duration
            and cache.cooldownShown
        then
            return
        end

        cache.cooldownStart = cooldown.start
        cache.cooldownDuration = cooldown.duration
        cache.cooldownShown = true
        button.cooldown:SetCooldown(cooldown.start, cooldown.duration)
        button.cooldown:Show()

        return
    end

    if not cache.cooldownShown and not button.cooldown:IsShown() then
        return
    end

    cache.cooldownStart = nil
    cache.cooldownDuration = nil
    cache.cooldownShown = false
    button.cooldown:Clear()
    button.cooldown:Hide()
end

local function applyIcon(button)
    local cache = getRenderCache(button)
    local icon = State.GetIcon(
        button.consumableState,
        button.defaultIcon,
        button.hoverStateActive
    )

    if icon and cache.icon ~= icon then
        button.texture:SetTexture(icon)
        cache.icon = icon
    end
end

function View.SetHoverStateActive(button, active)
    if not button then return end

    button.hoverStateActive = active == true
    applyIcon(button)
end

function View.GetUnavailableText(button)
    if not button then return end

    return State.GetUnavailableText(
        button.consumableState,
        button.hoverStateActive
    )
end

function View.ApplyVisual(button, state)
    if not button then return end

    -- Keep the latest read-only state for hover/tooltips even when every
    -- displayed value is unchanged. Only native region writes are cached.
    button.consumableState = state
    local cache = getRenderCache(button)
    local desaturated = state.desaturated == true

    applyStatusIcon(button, state)
    applyIcon(button)

    if cache.desaturated ~= desaturated then
        button.texture:SetDesaturated(desaturated)
        cache.desaturated = desaturated
    end

    applyText(
        button.count, cache.count,
        state.countText or "", state.countTextIsBad == true,
        not button.hideCountText
    )
    applyText(
        button.detailText, cache.detail,
        state.detailText or "", state.detailTextIsBad == true,
        not button.hideDurationText
    )
    setQualityOverlay(button, state.qualityItemID, state.qualityAtlas, state.qualityResolved)
    applyCooldown(button, state.cooldown)
    Glow.Set(button, state.glow == true and not InCombatLockdown())
    Tooltips.UpdateUnavailableOverlay(button)
end

function View.ApplyVisualOptions(button, options, isFlyout)
    if not button then return end

    options = options or {}
    local hideCountText = options.showStackCount == false
    local hideDurationText = options.showDuration == false
    local hideStatusTexture = isFlyout == true
        or options.showStatus == false
    local hideQualityIcon = options.showProfessionQuality == false
    local hideReminderGlow = options.showReminderGlow == false

    if button.hideCountText == hideCountText
        and button.hideDurationText == hideDurationText
        and button.hideStatusTexture == hideStatusTexture
        and button.hideQualityIcon == hideQualityIcon
        and button.hideReminderGlow == hideReminderGlow
    then
        return
    end

    button.hideCountText = hideCountText
    button.hideDurationText = hideDurationText
    button.hideStatusTexture = hideStatusTexture
    button.hideQualityIcon = hideQualityIcon
    button.hideReminderGlow = hideReminderGlow

    if button.consumableState then
        View.ApplyVisual(button, button.consumableState)
    else
        button.count:SetShown(not button.hideCountText)
        button.detailText:SetShown(not button.hideDurationText)
        button.statustexture:Hide()

        if button.hideQualityIcon then
            button.qualityIcon:Hide()
        end
    end
end

-- A released category has no observation to render. Clear stale feedback
-- without manufacturing a Missing/Unknown state for an unrequested button.
function View.Clear(button)
    button.consumableState = nil
    button.hoverStateActive = false
    button.count:SetText("")
    button.detailText:SetText("")
    button.statustexture:Hide()
    button.qualityIcon:Hide()

    if button.unavailableOverlay then
        button.unavailableOverlay:Hide()
    end

    applyCooldown(button)
    Glow.Stop(button)
    Glow.SetHovered(button, false)

    -- Cleared primary buttons and pooled flyout buttons need a full first
    -- render when reused, including regions reset directly above.
    button.rccConsumableRenderCache = nil
end

local function applyIconCrop(texture, width, height)
    if not texture or width <= 0 or height <= 0 then return end

    local left, right, top, bottom = 0, 1, 0, 1

    if width > height then
        local visibleHeight = height / width

        top = (1 - visibleHeight) / 2
        bottom = 1 - top
    elseif height > width then
        local visibleWidth = width / height

        left = (1 - visibleWidth) / 2
        right = 1 - left
    end

    texture:SetTexCoord(left, right, top, bottom)
end

local function positionDurationText(button, position)
    local detailText = button.detailText

    detailText:ClearAllPoints()
    detailText:SetJustifyH("CENTER")

    if position == "BOTTOM" then
        detailText:SetPoint("TOP", button, "BOTTOM", 0, -1)
    elseif position == "LEFT" then
        detailText:SetJustifyH("RIGHT")
        detailText:SetPoint("RIGHT", button, "LEFT", -1, 0)
    elseif position == "RIGHT" then
        detailText:SetJustifyH("LEFT")
        detailText:SetPoint("LEFT", button, "RIGHT", 1, 0)
    else
        detailText:SetPoint("BOTTOM", button, "TOP", 0, 1)
    end
end

function View.ApplyGeometry(button, geometry)
    if not button or InCombatLockdown() then return false end

    geometry = geometry or {}

    local width = math.max(1, tonumber(geometry.buttonWidth) or SIZE)
    local height = math.max(1, tonumber(geometry.buttonHeight) or SIZE)
    local textSize = math.max(
        1,
        tonumber(geometry.textSize) or DETAIL_TEXT_SIZE
    )
    local overlaySize = math.min(width, height) / 2
    local qualitySize = math.min(width, height)
        * (QUALITY_ICON_SIZE / SIZE)

    button:SetSize(width, height)
    applyIconCrop(button.texture, width, height)
    button.statustexture:SetSize(overlaySize, overlaySize)
    positionDurationText(button, geometry.durationTextPosition or "TOP")
    button.detailText:SetFont(FONT, textSize, "OUTLINE")
    button.detailText:SetWidth(width * 5)
    button.detailText:SetMaxLines(1)
    button.detailText:SetWordWrap(false)
    button.count:SetFont(FONT, textSize, "OUTLINE")
    button.qualityIcon:SetSize(qualitySize, qualitySize)

    return true
end

local function createClickOverlay(button)
    local click = CreateFrame(
        "Button",
        nil,
        button,
        "SecureActionButtonTemplate"
    )

    click:SetAllPoints()
    click:RegisterForClicks("AnyDown")
    click:Hide()

    local highlight = click:CreateTexture(nil, "HIGHLIGHT")

    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.15)
    highlight:SetBlendMode("ADD")

    button.unavailableOverlay = button:CreateTexture(nil, "ARTWORK", nil, 1)
    button.unavailableOverlay:SetAllPoints()
    button.unavailableOverlay:SetColorTexture(0.6, 0, 0, 0.4)
    button.unavailableOverlay:Hide()
    button.click = click
end

function View.Create(parent, definition, options)
    options = options or {}

    local button = CreateFrame("Frame", nil, parent)

    button.definition = definition
    button.defaultIcon = definition.defaultIcon
    button.weaponSlot = definition.weaponSlot
    button.tooltipAction = definition.tooltipAction
    button.surfaceCapabilities = options.capabilities
    button:SetSize(SIZE, SIZE)

    button.texture = button:CreateTexture()
    button.texture:SetAllPoints()

    button.statustexture = button:CreateTexture(nil, "OVERLAY", nil, 1)
    button.statustexture:SetPoint("CENTER")
    button.statustexture:SetSize(SIZE / 2, SIZE / 2)

    button.detailText = button:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    button.detailText:SetPoint("BOTTOM", button, "TOP", 0, 1)
    button.detailText:SetFont(FONT, DETAIL_TEXT_SIZE, "OUTLINE")

    button.count = button:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.count:SetFont(FONT, COUNT_TEXT_SIZE, "OUTLINE")

    button.qualityIcon = button:CreateTexture(nil, "OVERLAY")
    button.qualityIcon:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4)
    button.qualityIcon:SetSize(QUALITY_ICON_SIZE, QUALITY_ICON_SIZE)
    button.qualityIcon:Hide()

    if options.clickable then
        createClickOverlay(button)
    end

    button:EnableMouse(true)

    if definition.defaultIcon then
        button.texture:SetTexture(definition.defaultIcon)
    end

    if definition.hasCooldown then
        button.cooldown = CreateFrame(
            "Cooldown",
            nil,
            button,
            "CooldownFrameTemplate"
        )
        button.cooldown:SetAllPoints()
        button.cooldown:SetDrawEdge(true)
        button.cooldown:SetDrawSwipe(true)
    end

    return button
end

function View.CreateSet(parent, options)
    local buttons = {}
    local definitions = Catalog.GetDefinitions()

    for i = 1, #definitions do
        local definition = definitions[i]
        local clickable = options.clickable == true

        if options.isClickable then
            clickable = options.isClickable(definition) == true
        end

        buttons[definition.key] = View.Create(parent, definition, {
            clickable = clickable,
            capabilities = options.capabilities,
        })
    end

    parent.buttons = buttons

    return buttons
end


function View.GetWidth(buttonCount, buttonWidth, spacing)
    buttonWidth = buttonWidth or SIZE
    spacing = spacing or SPACING

    return buttonWidth * buttonCount
        + spacing * math.max(buttonCount - 1, 0)
end

function View.GetStackHeight(buttonCount, buttonHeight, spacing)
    buttonHeight = buttonHeight or SIZE
    spacing = spacing or SPACING

    return buttonHeight * buttonCount
        + spacing * math.max(buttonCount - 1, 0)
end
