local _, RCC = ...

local UI = RCC.UI
local Tooltips = RCC.ConsumableFrameTooltips

RCC.ConsumableFrameButtons = RCC.ConsumableFrameButtons or {}

local Buttons = RCC.ConsumableFrameButtons

local SIZE = 48
local SPACING = 2
local FONT = UI.FONT

Buttons.SIZE = SIZE
Buttons.SPACING = SPACING

local BUTTON_DEFS = {
    {
        key = "food",
        settingKey = "icon_food",
        defaultIcon = RCC.db.food_icon_id,
        clickable = true,
        tooltipAction = "eat",
        hasCooldown = true,
        layoutOrder = 1,
    },
    {
        key = "flask",
        settingKey = "icon_flask",
        defaultIcon = RCC.db.flask_icon_id,
        clickable = true,
        tooltipAction = "use",
        layoutOrder = 2,
    },
    {
        key = "oil",
        settingKey = "icon_mhOil",
        defaultIcon = RCC.db.weapon_enchant_icon_id,
        clickable = true,
        tooltipAction = "apply",
        targetSlot = 16,
        layoutOrder = 3,
    },
    {
        key = "augment",
        settingKey = "icon_augment",
        defaultIcon = RCC.db.augment_icon_id,
        clickable = true,
        tooltipAction = "use",
        layoutOrder = 5,
    },
    {
        key = "hs",
        settingKey = "icon_healthstone",
        defaultIcon = RCC.db.healthstone_icon_id,
        layoutOrder = 6,
    },
    {
        key = "oiloh",
        settingKey = "icon_ohOil",
        defaultIcon = RCC.db.weapon_enchant_icon_id,
        clickable = true,
        tooltipAction = "apply",
        targetSlot = 17,
        hiddenByDefault = true,
        layoutOrder = 4,
    },
    {
        key = "dmgpot",
        settingKey = "icon_dmgPotion",
        defaultIcon = RCC.db.potion_icon_id,
        layoutOrder = 7,
    },
    {
        key = "healpot",
        settingKey = "icon_healPotion",
        defaultIcon = RCC.db.healing_potion_icon_id,
        layoutOrder = 8,
    },
    {
        key = "vantus",
        settingKey = "icon_vantus",
        defaultIcon = RCC.db.vantus_icon_id,
        clickable = true,
        tooltipAction = "use",
        hiddenByDefault = true,
        layoutOrder = 9,
    },
}

local BUTTON_LAYOUT_ORDER = {}

for i = 1, #BUTTON_DEFS do
    local def = BUTTON_DEFS[i]
    def.index = i
    BUTTON_LAYOUT_ORDER[#BUTTON_LAYOUT_ORDER + 1] = def
end

table.sort(BUTTON_LAYOUT_ORDER, function(a, b)
    return a.layoutOrder < b.layoutOrder
end)

function Buttons.GetWidth(buttonCount)
    return SIZE * buttonCount
           + SPACING * math.max(buttonCount - 1, 0)
end

function Buttons.SetShownInLayout(button, shown)
    button.showInLayout = shown == true
end

function Buttons.ResetState(button, notReadyTexture)
    button.statustexture:SetTexture(notReadyTexture)
    button.hasConsumableBuff = false
    button.timeleft:SetText("")
    button.count:SetText("")
    button.texture:SetDesaturated(true)
    button.tooltipAuraID = nil
    button.tooltipItemID = nil
    button.usableItemID = nil
    button.appliedItemID = nil
    button.clickHintItemID = nil
    button.outOfItemsText = nil
    button.clickEnabled = false
    Buttons.SetShownInLayout(button, true)
end

function Buttons.CreateAll(parent)
    parent.buttons = parent.buttons or {}

    local buttons = parent.buttons

    for i = 1, #BUTTON_DEFS do
        local def = BUTTON_DEFS[i]
        local button = CreateFrame("Frame", nil, parent)
        buttons[i] = button
        button:SetSize(SIZE, SIZE)

        if i == 1 then
            button:SetPoint("LEFT", 0, 0)
        else
            button:SetPoint("LEFT", buttons[i - 1], "RIGHT", SPACING, 0)
        end

        button.texture = button:CreateTexture()
        button.texture:SetAllPoints()

        button.statustexture = button:CreateTexture(nil, "OVERLAY")
        button.statustexture:SetPoint("CENTER")
        button.statustexture:SetSize(SIZE / 2, SIZE / 2)

        button.timeleft = button:CreateFontString(nil, "ARTWORK",
                                                  "GameFontWhite")
        button.timeleft:SetPoint("BOTTOM", button, "TOP", 0, 1)
        button.timeleft:SetFont(FONT, 12, "OUTLINE")

        button.count = button:CreateFontString(nil, "ARTWORK", "GameFontWhite")
        button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        button.count:SetFont(FONT, 14, "OUTLINE")

        if def.clickable then
            button.click = CreateFrame("Button", nil, button,
                                       "SecureActionButtonTemplate")
            button.click:SetAllPoints()
            button.click:Hide()
            button.click:RegisterForClicks("AnyUp", "AnyDown")

            if def.targetSlot then
                button.click:SetAttribute("type", "item")
                button.click:SetAttribute("target-slot",
                                          tostring(def.targetSlot))
            else
                button.click:SetAttribute("type", "macro")
            end

            button.click:SetScript("OnEnter", Tooltips.ClickButtonOnEnter)
            button.click:SetScript("OnLeave", Tooltips.ClickButtonOnLeave)

            local highlight = button.click:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(1, 1, 1, 0.15)
            highlight:SetBlendMode("ADD")

            button.outOverlay = button:CreateTexture(nil, "ARTWORK", nil, 1)
            button.outOverlay:SetAllPoints()
            button.outOverlay:SetColorTexture(0.6, 0, 0, 0.4)
            button.outOverlay:Hide()

            button.tooltipAction = def.tooltipAction
        end

        button:EnableMouse(true)
        button:SetScript("OnEnter", Tooltips.InfoButtonOnEnter)
        button:SetScript("OnLeave", Tooltips.InfoButtonOnLeave)

        if def.defaultIcon then
            button.texture:SetTexture(def.defaultIcon)
        end

        if def.hasCooldown then
            button.cooldown = CreateFrame("Cooldown", nil, button,
                                          "CooldownFrameTemplate")
            button.cooldown:SetAllPoints()
            button.cooldown:SetDrawEdge(true)
            button.cooldown:SetDrawSwipe(true)
        end

        buttons[def.key] = button

        if def.hiddenByDefault then
            button:Hide()
        end
    end

    return buttons
end

function Buttons.ApplyLayout(parent, buttons)
    local previous
    local visibleCount = 0

    for _, def in ipairs(BUTTON_LAYOUT_ORDER) do
        local button = buttons[def.index]
        local shouldShow = button.showInLayout
            and RCC.GetSetting(def.settingKey)

        button:ClearAllPoints()

        if shouldShow then
            if previous then
                button:SetPoint("LEFT", previous, "RIGHT", SPACING, 0)
            else
                button:SetPoint("LEFT", 0, 0)
            end

            button:Show()
            previous = button
            visibleCount = visibleCount + 1
        else
            button:Hide()
        end
    end

    parent:SetWidth(Buttons.GetWidth(visibleCount))
end

function Buttons.UpdateOutOverlays(buttons)
    for i = 1, #buttons do
        Tooltips.UpdateOutOverlay(buttons[i])
    end
end
