local _, RCC = ...

local UI = RCC.UI
local Binder = RCC.ConsumableActionBinder
local Catalog = RCC.ConsumableCatalog
local Surface = RCC.ConsumableSurface
local View = RCC.ConsumableButtonView

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded

local CONTROL_BORDER_OVERHANG = 1

local function getGeometry()
    local widthPercent = RCC.GetSetting(
        "consumables_iconWidthPercent"
    )

    return {
        buttonWidth = View.SIZE * (widthPercent / 100),
        buttonHeight = View.SIZE,
        gapX = View.SPACING,
    }
end

local initialGeometry = getGeometry()

RCC.consumables = CreateFrame("Frame", "RCConsumables", UIParent)
RCC.consumables:SetPoint("BOTTOM", ReadyCheckListenerFrame, "TOP", 0, 5)
RCC.consumables:SetSize(
    View.GetWidth(
        Catalog.GetCount(),
        initialGeometry.buttonWidth,
        initialGeometry.gapX
    ),
    initialGeometry.buttonHeight
)
RCC.consumables:Hide()

RCC.consumables.anchor = CreateFrame("Frame", nil, UIParent)
RCC.consumables.anchor:SetSize(1, 1)
RCC.consumables.anchor:SetPoint("CENTER")
RCC.consumables.anchor:Hide()

RCC.consumables:SetMovable(true)
RCC.consumables:SetClampedToScreen(true)
RCC.consumables:SetFrameStrata("HIGH")
RCC.consumables:SetToplevel(true)

RCC.consumables.drag = UI.CreateControlFrame(RCC.consumables, 20, 20)
RCC.consumables.drag:SetPoint("TOPLEFT", RCC.consumables, "BOTTOMLEFT",
                              CONTROL_BORDER_OVERHANG,
                              -(View.SPACING + CONTROL_BORDER_OVERHANG))
RCC.consumables.drag:EnableMouse(true)
RCC.consumables.drag:RegisterForDrag("LeftButton")
RCC.consumables.drag:Hide()

RCC.consumables.drag.icon = RCC.consumables.drag:CreateTexture(nil, "OVERLAY")
RCC.consumables.drag.icon:SetSize(12, 12)
RCC.consumables.drag.icon:SetPoint("CENTER")
RCC.consumables.drag.icon:SetTexture("Interface\\CURSOR\\UI-Cursor-Move")

RCC.consumables.drag:SetScript("OnDragStart", function(self)
    RCC.consumables:StartMoving()
end)

RCC.consumables.drag:SetScript("OnDragStop", function(self)
    RCC.consumables:StopMovingOrSizing()
end)

RCC.consumables.close = UI.CreateControlButton(
    RCC.consumables, 0, 20, CLOSE or "x", "SecureHandlerClickTemplate"
)
RCC.consumables.close:SetPoint("TOPLEFT", RCC.consumables.drag, "TOPRIGHT",
                               View.SPACING + CONTROL_BORDER_OVERHANG * 2,
                               0)
RCC.consumables.close:SetPoint("TOPRIGHT", RCC.consumables, "BOTTOMRIGHT",
                               -CONTROL_BORDER_OVERHANG,
                               -(View.SPACING + CONTROL_BORDER_OVERHANG))
RCC.consumables.close:Hide()

RCC.consumables.close:SetFrameRef("consumables", RCC.consumables)
RCC.consumables.close:SetFrameRef("anchor", RCC.consumables.anchor)
RCC.consumables.close:SetAttribute("_onclick", [[
    self:GetFrameRef("consumables"):Hide()
    self:GetFrameRef("anchor"):Hide()
]])

RCC.consumables.surface = Surface.Create(RCC.consumables, {
    capabilities = Binder.Capabilities.TEMPORARY,
    geometry = initialGeometry,
    isClickable = function(definition)
        return definition.temporaryClickable == true
    end,
})

function RCC.consumables:ApplyLayout()
    if InCombatLockdown() then return false end

    local geometry = getGeometry()

    Surface.HideFlyouts(self.surface)
    Surface.ApplyGeometry(self.surface, geometry)

    if self:IsShown() then
        Surface.ApplyTemporaryLayout(self.surface, self.displayContext)
    else
        self:SetSize(
            View.GetWidth(
                Catalog.GetCount(),
                geometry.buttonWidth,
                geometry.gapX
            ),
            geometry.buttonHeight
        )
    end

    return true
end

function RCC.consumables:UpdateReadyCheckAnchor()
    if self.readyCheckAnchorFixed then return end

    local needsFix = IsAddOnLoaded("ElvUI") or
                     IsAddOnLoaded("ShestakUI")

    if not needsFix then return end

    self:ClearAllPoints()
    self:SetPoint("BOTTOM", ReadyCheckFrame, "TOP", 0, 5)

    self.readyCheckAnchorFixed = true
end

function RCC.consumables:Repos(isInitiator)
    if InCombatLockdown() then return end

    if isInitiator then
        self:ClearAllPoints()
        self:SetPoint("CENTER", self.anchor, "CENTER", 0, 0)

        self.anchor:Show()
        self.drag:Show()
        self.close:Show()
    else
        local anchor = self.readyCheckAnchorFixed
            and ReadyCheckFrame
            or ReadyCheckListenerFrame

        self.anchor:Hide()
        self.drag:Hide()
        self.close:Hide()

        self:ClearAllPoints()
        self:SetPoint("BOTTOM", anchor, "TOP", 0, 5)
    end
end
