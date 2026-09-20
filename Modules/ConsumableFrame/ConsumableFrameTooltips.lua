local _, RCC = ...

local Glow = RCC.ConsumableFrameGlow
local State = RCC.ConsumableState
local Preferences = RCC.ConsumablePreferences
local F = RCC.F
local GetItemInfo = C_Item.GetItemInfo
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellLink = C_Spell.GetSpellLink

RCC.ConsumableFrameTooltips = RCC.ConsumableFrameTooltips or {}
RCC.ConsumableTooltips = RCC.ConsumableFrameTooltips

local Tooltips = RCC.ConsumableFrameTooltips

local function getItemLink(itemID)
    if not itemID then return end

    return select(2, GetItemInfo(itemID))
end

local function getSpellDisplay(spellID)
    if not spellID then return end

    local spellLink = GetSpellLink and GetSpellLink(spellID)

    if spellLink then
        return spellLink
    end

    local spellInfo = GetSpellInfo(spellID)

    return spellInfo and spellInfo.name
end

local function getUnavailableText(button)
    return State.GetUnavailableText(
        button and button.consumableState,
        button and button.hoverStateActive
    )
end

local function getAuraScanUnavailableText(button)
    return State.GetAuraScanUnavailableText(
        button and button.consumableState
    )
end

local function setGameTooltipOwner(button)
    GameTooltip:SetOwner(button, "ANCHOR_NONE")
    GameTooltip:SetPoint("BOTTOMLEFT", button, "TOPRIGHT", 2, 2)
end

local function addAppliedEffectHint(button)
    local state = button.consumableState

    if not state then return end

    local text = getItemLink(state.tooltipAppliedItemID)
        or getSpellDisplay(state.tooltipAppliedSpellID)

    if not text then return end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Currently applied: " .. text, 1, 1, 1, true)
    GameTooltip:Show()
end

local function addClickHint(button)
    if not button.tooltipAction then return end

    local state = button.consumableState

    if not state then return end
    if state.summaryCapacity then return end

    local action = state.action

    if not action then
        return
    end

    local capabilities = button.surfaceCapabilities or {}

    if action.selectionOnly
        and capabilities.allowSelectionItemUse ~= true
    then
        return
    end

    local targetText = getItemLink(State.GetClickHintItemID(state))
        or getSpellDisplay(State.GetClickHintSpellID(state))

    if not targetText then return end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ff00Left click to "
                        .. button.tooltipAction .. "|r " .. targetText)
    GameTooltip:Show()

    return true
end

local function addRightClickPreferenceHint(button, hasHint)
    local state = button.consumableState
    local preference = state and state.preference

    if not preference then return end

    local choice = preference.choice
    local targetText

    if choice.kind == "item" then
        targetText = getItemLink(choice.id)
    else
        targetText = getSpellDisplay(choice.id)
    end

    if not targetText then return end

    if not hasHint then
        GameTooltip:AddLine(" ")
    end

    if Preferences.IsPreferred(preference.key, preference.capacity, choice) then
        GameTooltip:AddLine("|cff00ff00Preferred:|r " .. targetText)
        GameTooltip:AddLine("|cff00ff00Right click to clear preference|r")
    else
        GameTooltip:AddLine("|cff00ff00Right click to prefer|r " .. targetText)
    end

    GameTooltip:Show()
end

local function addClickHints(button)
    local hasHint = addClickHint(button)

    addRightClickPreferenceHint(button, hasHint)
end

local function addUnavailableHint(button)
    local unavailableText = getUnavailableText(button)

    if not unavailableText then return end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffff3333" .. unavailableText .. "|r")
    GameTooltip:Show()
end

local function addAuraScanUnavailableHint(button)
    local text = getAuraScanUnavailableText(button)

    if not text then return end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(text, 0.65, 0.65, 0.65, true)
    GameTooltip:Show()
end

local function showStatusMessageTooltip(button, auraText, unavailableText)
    if not auraText and not unavailableText then return end

    setGameTooltipOwner(button)
    GameTooltip:ClearLines()

    if auraText then
        GameTooltip:AddLine("Status Unknown")
        GameTooltip:AddLine(auraText, 0.65, 0.65, 0.65, true)
    end

    if unavailableText then
        if auraText then
            GameTooltip:AddLine(" ")
        end

        GameTooltip:AddLine(unavailableText, 1, 0.2, 0.2, true)
    end

    GameTooltip:Show()

    return true
end

local function showButtonTooltip(button, shoppingTooltip)
    local state = button.consumableState
    local shownTooltip

    if not state then return end

    if state.summaryCapacity then
        setGameTooltipOwner(button)
        GameTooltip:ClearLines()
        GameTooltip:AddLine(state.summaryLabel)
        local effects = state.summaryEffects or {}

        if #effects > 0 then
            GameTooltip:AddLine("Active", 1, 1, 1)
        end

        for _, effect in ipairs(effects) do
            local name = getSpellDisplay(effect.spellID) or effect.name or "Name unavailable"
            local duration = effect.remaining and F.FormatDuration(effect.remaining) or ""
            GameTooltip:AddDoubleLine(name, duration, 1, 1, 1, 1, 1, 1)
        end

        local unfilled = state.summaryCapacity - #effects

        if unfilled > 0 then
            GameTooltip:AddLine("Missing: " .. unfilled, 1, 0.2, 0.2)
        end

        GameTooltip:AddLine(" ")
        local action = state.action
        local spellIDs = action and (action.spellIDs or { action.spellID }) or {}

        if #spellIDs == 0 then
            local hint = InCombatLockdown() and "Choose an option after combat"
                or "Choose an option from the menu"

            GameTooltip:AddLine(hint, 0.7, 0.7, 0.7, true)
        else
            GameTooltip:AddLine("Left click to " .. button.tooltipAction, 0.2, 1, 0.2)

            for index, spellID in ipairs(spellIDs) do
                local name = getSpellDisplay(spellID) or "Name unavailable"

                if #spellIDs > 1 then
                    name = index .. ". " .. name
                end

                GameTooltip:AddLine(name, 1, 1, 1, true)
            end

            if #spellIDs > 1 then
                GameTooltip:AddLine("Click once for each, in the order shown", 0.2, 1, 0.2, true)
            end
        end

        GameTooltip:Show()

        return true
    end

    if state.tooltipItemID then
        setGameTooltipOwner(button)
        GameTooltip:SetItemByID(state.tooltipItemID)
        GameTooltip:Show()
        shownTooltip = true
    end

    if state.tooltipSpellID then
        setGameTooltipOwner(button)
        GameTooltip:SetSpellByID(state.tooltipSpellID)
        GameTooltip:Show()
        shownTooltip = true
    end

    if state.tooltipAuraID and shoppingTooltip and shownTooltip then
        local auraInstanceID = F.GetCurrentPublicAuraInstanceID(
            "player",
            state.tooltipAuraID
        )

        if auraInstanceID then
            ShoppingTooltip1:SetOwner(GameTooltip, "ANCHOR_NONE")
            ShoppingTooltip1:SetPoint(
                "BOTTOMLEFT",
                GameTooltip,
                "TOPLEFT",
                0,
                4
            )
            ShoppingTooltip1:SetUnitBuffByAuraInstanceID(
                "player",
                auraInstanceID
            )
            ShoppingTooltip1:Show()
        end
    elseif state.tooltipAuraID then
        local auraInstanceID = F.GetCurrentPublicAuraInstanceID(
            "player",
            state.tooltipAuraID
        )

        if auraInstanceID then
            setGameTooltipOwner(button)
            GameTooltip:SetUnitBuffByAuraInstanceID("player", auraInstanceID)
            GameTooltip:Show()
            shownTooltip = true
        end
    end

    return shownTooltip
end

local function showClickButtonTooltip(button)
    if showButtonTooltip(button, true) then
        addAppliedEffectHint(button)
        addAuraScanUnavailableHint(button)
        addUnavailableHint(button)
        addClickHints(button)

        return true
    end

    return showStatusMessageTooltip(
        button,
        getAuraScanUnavailableText(button)
    )
end

local function showInfoButtonTooltip(button)
    local unavailableText = getUnavailableText(button)
    local auraScanUnavailableText = getAuraScanUnavailableText(button)

    if showButtonTooltip(button, true) then
        addAppliedEffectHint(button)

        if button.clickEnabled then
            addClickHints(button)
        end

        addAuraScanUnavailableHint(button)
        addUnavailableHint(button)

        return true
    end

    return showStatusMessageTooltip(
        button,
        auraScanUnavailableText,
        unavailableText
    )
end

function Tooltips.ClickButtonOnEnter(self)
    local button = self:GetParent()

    Glow.SetHovered(button, true)
    showClickButtonTooltip(button)
end

function Tooltips.ClickButtonOnLeave(self)
    Glow.SetHovered(self:GetParent(), false)
    ShoppingTooltip1:Hide()
    GameTooltip:Hide()
end

function Tooltips.InfoButtonOnEnter(self)
    Glow.SetHovered(self, true)
    Tooltips.UpdateUnavailableOverlay(self)
    showInfoButtonTooltip(self)
end

function Tooltips.InfoButtonOnLeave(self)
    Glow.SetHovered(self, false)

    Tooltips.UpdateUnavailableOverlay(self)

    ShoppingTooltip1:Hide()
    GameTooltip:Hide()
end

-- Preference clicks and item rebinding can change an open tooltip without
-- another mouse-enter event. Rebuild only its contents, not hover behavior.
function Tooltips.Refresh(button)
    if not GameTooltip:IsShown() or not GameTooltip:IsOwned(button) then return end

    ShoppingTooltip1:Hide()

    if not button:IsVisible() or not button.consumableState then
        GameTooltip:Hide()

        return
    end

    GameTooltip:ClearLines()

    local shown

    if button.clickEnabled then
        shown = showClickButtonTooltip(button)
    else
        shown = showInfoButtonTooltip(button)
    end

    if not shown then
        GameTooltip:Hide()
    end
end

function Tooltips.UpdateUnavailableOverlay(button)
    if not button.unavailableOverlay then return end

    local shown = getUnavailableText(button) ~= nil

    if button.unavailableOverlay:IsShown() ~= shown then
        button.unavailableOverlay:SetShown(shown)
    end
end
