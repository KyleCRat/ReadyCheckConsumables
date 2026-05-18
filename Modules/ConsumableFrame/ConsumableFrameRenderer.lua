local _, RCC = ...

RCC.ConsumableFrameRenderer = RCC.ConsumableFrameRenderer or {}

local Renderer = RCC.ConsumableFrameRenderer

local Actions = RCC.ConsumableFrameActions
local Buttons = RCC.ConsumableFrameButtons
local ButtonState = RCC.ConsumableFrameButtonState
local Glow = RCC.ConsumableFrameGlow

local function applyCooldown(button, cooldown)
    if not button.cooldown or not cooldown then return end

    if cooldown.start and cooldown.duration then
        button.cooldown:SetCooldown(cooldown.start, cooldown.duration)
        button.cooldown:Show()
    elseif cooldown.clear then
        button.cooldown:Clear()
    end
end

function Renderer.Apply(button, state)
    if not button or not state then return end

    Buttons.ResetState(button, ButtonState.NOT_READY_TEXTURE)
    button.consumableState = state

    if state.showInLayout ~= nil then
        Buttons.SetShownInLayout(button, state.showInLayout)
    end

    if state.statusTexture then
        button.statustexture:SetTexture(state.statusTexture)
    end

    if state.icon then
        Buttons.SetIcon(button, state.icon)
    end

    if state.hoverState then
        Buttons.SetHoverState(button, state.hoverState)
    end

    if state.desaturated ~= nil then
        button.texture:SetDesaturated(state.desaturated == true)
    end

    if state.countText ~= nil then
        button.count:SetText(state.countText)
    end

    if state.detailText ~= nil then
        button.detailText:SetText(state.detailText)
    end

    if state.detailTextIsBad ~= nil then
        Buttons.SetDetailTextBad(button, state.detailTextIsBad)
    end

    if state.hasConsumableBuff ~= nil then
        button.hasConsumableBuff = state.hasConsumableBuff == true
    end

    if state.tooltipAuraID ~= nil then
        button.tooltipAuraID = state.tooltipAuraID
    end

    if state.tooltipItemID ~= nil then
        button.tooltipItemID = state.tooltipItemID
    end

    if state.tooltipSpellID ~= nil then
        button.tooltipSpellID = state.tooltipSpellID
    end

    if state.usableItemID ~= nil then
        button.usableItemID = state.usableItemID
    end

    if state.clickHintItemID ~= nil then
        button.clickHintItemID = state.clickHintItemID
    end

    if state.clickHintSpellID ~= nil then
        button.clickHintSpellID = state.clickHintSpellID
    end

    if state.unavailable ~= nil then
        Buttons.SetUnavailable(button, state.unavailable)
    end

    applyCooldown(button, state.cooldown)

    Actions.Apply(button, state.action)

    Glow.Set(button, state.glow == true)

    Buttons.SetFlyoutChoices(button, state.flyoutChoices)
end
