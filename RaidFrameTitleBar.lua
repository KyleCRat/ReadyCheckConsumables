local _, RCC = ...

RCC.RaidFrameTitleBar = RCC.RaidFrameTitleBar or {}
local TitleBar = RCC.RaidFrameTitleBar

local COLOR_TITLE_BG     = { r = 0, g = 0,      b = 0,       a = 0.2 }
local COLOR_PROGRESS_BAR = { r = 0, g = 209/255, b = 255/255, a = 0.6 }

function TitleBar.Create(parent, layout, options)
    local titleBar = CreateFrame("Frame", nil, parent)

    titleBar:SetPoint("TOPLEFT",  parent, "TOPLEFT",
        layout.framePad, -layout.framePad)
    titleBar:SetPoint("TOPRIGHT", parent, "TOPRIGHT",
        -layout.framePad, -layout.framePad)
    titleBar:SetHeight(options.titleHeight)

    titleBar.bg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBar.bg:SetAllPoints(titleBar)
    titleBar.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    titleBar.bg:SetVertexColor(
        COLOR_TITLE_BG.r, COLOR_TITLE_BG.g, COLOR_TITLE_BG.b, COLOR_TITLE_BG.a
    )

    titleBar.progress = titleBar:CreateTexture(nil, "BORDER")
    titleBar.progress:SetPoint("TOPLEFT", titleBar, "TOPLEFT")
    titleBar.progress:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT")
    titleBar.progress:SetTexture("Interface\\Buttons\\WHITE8x8")
    titleBar.progress:SetVertexColor(
        COLOR_PROGRESS_BAR.r, COLOR_PROGRESS_BAR.g,
        COLOR_PROGRESS_BAR.b, COLOR_PROGRESS_BAR.a
    )
    titleBar.progress:SetWidth(1)
    titleBar.progress:Hide()

    titleBar.countText = titleBar:CreateFontString(nil, "ARTWORK")
    titleBar.countText:SetPoint("LEFT", titleBar, "LEFT", 2, 0)
    titleBar.countText:SetFont(options.font, options.fontSizeName, "OUTLINE")
    titleBar.countText:SetTextColor(1, 1, 1)
    titleBar.countText:SetText("")

    titleBar.timerText = titleBar:CreateFontString(nil, "ARTWORK")
    titleBar.timerText:SetPoint("LEFT", titleBar.countText, "RIGHT", 6, 0)
    titleBar.timerText:SetFont(options.font, options.fontSizeName, "OUTLINE")
    titleBar.timerText:SetTextColor(1, 1, 1)
    titleBar.timerText:SetText("")

    titleBar.colIcons = {}

    for i = 1, #layout.titleX do
        local icon = titleBar:CreateTexture(nil, "ARTWORK")

        icon:SetSize(layout.iconSize, layout.iconSize)
        icon:SetPoint("LEFT", titleBar, "LEFT", layout.titleX[i], 0)
        icon:SetTexture(options.pendingTexture)
        titleBar.colIcons[i] = icon
    end

    return titleBar
end
