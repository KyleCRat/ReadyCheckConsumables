local _, RCC = ...

RCC.ConsumablePresenters = RCC.ConsumablePresenters or {}
local Recuperate = {}
RCC.ConsumablePresenters.Recuperate = Recuperate

local ButtonState = RCC.ConsumableState

function Recuperate.Present(model)
    return ButtonState.Create({
        showStatusTexture = false,
        icon = model.selection.icon,
        desaturated = false,
        tooltipSpellID = model.action.spellID,
        clickHintSpellID = model.action.spellID,
        action = model.action,
    })
end
