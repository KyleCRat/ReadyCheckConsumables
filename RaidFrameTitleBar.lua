local _, RCC = ...

RCC.RaidFrameTitleBar = RCC.RaidFrameTitleBar or {}
local TitleBar = RCC.RaidFrameTitleBar

local ceil    = ceil
local GetTime = GetTime

local COLOR_TITLE_BG     = { r = 0, g = 0,      b = 0,       a = 0.2 }
local COLOR_PROGRESS_BAR = { r = 0, g = 209/255, b = 255/255, a = 0.6 }
local COLOR_NOT_READY    = { r = 1,   g = 0.2,  b = 0.2 }
local COLOR_AFK          = { r = 1,   g = 0.82, b = 0   }
local COLOR_READY        = { r = 0.2, g = 1,    b = 0.2 }

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

    for columnIndex = 1, #layout.columns do
        local column = layout.columns[columnIndex]
        local icon = titleBar:CreateTexture(nil, "ARTWORK")

        icon:SetSize(layout.iconSize, layout.iconSize)
        icon:SetPoint("LEFT", titleBar, "LEFT", column.titleX, 0)
        icon:SetTexture(options.pendingTexture)
        titleBar.colIcons[columnIndex] = icon
    end

    function titleBar:RefreshColumns(columnStates, readyTexture, notReadyTexture)
        local numCols = #self.colIcons

        for columnIndex = 1, numCols do
            self.colIcons[columnIndex]:SetTexture(
                columnStates[columnIndex] and notReadyTexture or readyTexture
            )
        end
    end

    function titleBar:SetReadyCount(readyCount, activeCount)
        self.countText:SetTextColor(1, 1, 1)
        self.countText:SetText(readyCount .. "/" .. activeCount)
    end

    function titleBar:ShowFinishedSummary(notReadyCount, afkCount)
        if notReadyCount > 0 then
            local c = COLOR_NOT_READY
            local s = notReadyCount == 1 and "Player" or "Players"

            self.countText:SetTextColor(c.r, c.g, c.b)
            self.countText:SetText(notReadyCount .. " " .. s .. " not Ready")
        elseif afkCount > 0 then
            local c = COLOR_AFK
            local verb = afkCount == 1 and "Player is" or "Players are"

            self.countText:SetTextColor(c.r, c.g, c.b)
            self.countText:SetText(afkCount .. " " .. verb .. " AFK")
        else
            local c = COLOR_READY

            self.countText:SetTextColor(c.r, c.g, c.b)
            self.countText:SetText("Everyone is Ready!")
        end
    end

    function titleBar:StopProgress()
        self.progress:Hide()
        self:SetScript("OnUpdate", nil)

        if self.progressTextTimer then
            self.progressTextTimer:Cancel()
            self.progressTextTimer = nil
        end

        self.timerText:SetText("")
    end

    function titleBar:StartProgress(duration, barWidth)
        self:StopProgress()

        local endTime = GetTime() + duration

        self.progress:SetWidth(barWidth)
        self.progress:Show()
        self.timerText:SetText(ceil(duration) .. "s")

        self:SetScript("OnUpdate", function()
            local remaining = endTime - GetTime()

            if remaining <= 0 then
                self:StopProgress()

                return
            end

            self.progress:SetWidth(math.max(1, barWidth * remaining / duration))
        end)

        self.progressTextTimer = C_Timer.NewTicker(1, function(ticker)
            local remaining = endTime - GetTime()

            if remaining <= 0 then
                ticker:Cancel()

                return
            end

            self.timerText:SetText(ceil(remaining) .. "s")
        end)
    end

    return titleBar
end
