local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Recuperate = RCC.Consumables.Recuperate or {}

local Recuperate = RCC.Consumables.Recuperate

local ButtonState = RCC.ConsumableFrameButtonState
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType

local RECUPERATE_SPELL_ID = 1231411
local RECUPERATE_ICON = 136074

function Recuperate.Update(button)
    Renderer.Apply(button, ButtonState.Create({
        showStatusTexture = false,
        icon = RECUPERATE_ICON,
        desaturated = false,
        tooltipSpellID = RECUPERATE_SPELL_ID,
        clickHintSpellID = RECUPERATE_SPELL_ID,
        action = {
            type = ActionType.SPELL,
            spellID = RECUPERATE_SPELL_ID,
            available = true,
        },
    }))
end
