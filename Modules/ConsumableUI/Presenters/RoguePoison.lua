local _, RCC = ...
local RoguePoison = {}
RCC.ConsumablePresenters.RoguePoison = RoguePoison

local State = RCC.ConsumableState

function RoguePoison.Present(model)
    local selected = model.selection
    local state = State.Create({ applicable = selected.applicable })

    if not selected.applicable then return state end

    State.ApplyActiveAura(state, model.effect)

    -- Keep the icon and click hint aligned with the spell that will be cast.
    state.icon = selected.candidate.icon
    state.action = model.action
    state.tooltipSpellID = selected.candidate.spellID
    state.clickHintSpellID = selected.candidate.spellID
    state.glow = not model.effect or not model.effect.satisfied

    State.ApplyAuraScanAvailability(state, model.available)

    return state
end

function RoguePoison.Choices(selection)
    if not selection.applicable then return end

    local choices = {}

    for _, candidate in ipairs(selection.candidates) do
        if candidate.spellID ~= selection.candidate.spellID then
            choices[#choices + 1] = State.Create({
                icon = candidate.icon,
                desaturated = false,
                showStatusTexture = false,
                tooltipSpellID = candidate.spellID,
                clickHintSpellID = candidate.spellID,
                action = candidate.action,
            })
        end
    end

    if #choices > 0 then return choices end
end
