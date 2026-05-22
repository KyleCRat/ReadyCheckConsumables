local _, RCC = ...

RCC.ConsumableFrameRenderer = RCC.ConsumableFrameRenderer or {}

local Renderer = RCC.ConsumableFrameRenderer

local Actions = RCC.ConsumableFrameActions
local Buttons = RCC.ConsumableFrameButtons
local ButtonState = RCC.ConsumableFrameButtonState
local Glow = RCC.ConsumableFrameGlow

function Renderer.Apply(button, state)
    if not button then return end

    local viewState = ButtonState.Normalize(state)

    button.consumableState = viewState

    Buttons.ApplyState(button, viewState)
    Actions.Apply(button, viewState.action)
    Glow.Set(button, viewState.glow == true)
    Buttons.SetFlyoutChoices(button, viewState.flyoutChoices)
end
