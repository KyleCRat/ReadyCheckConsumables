local _, RCC = ...
local RoguePoison = { choicesUseModel = true }
RCC.ConsumablePresenters.RoguePoison = RoguePoison

local State = RCC.ConsumableState

function RoguePoison.Present(model)
    local selected = model.selection
    local state = State.Create({ applicable = selected.applicable, action = model.action })

    if not selected.applicable then return state end

    if selected.capacity > 1 then
        State.ApplyEffectSummary(state, model)
    else
        State.ApplyActiveAura(state, model.effects[1])
        state.icon = selected.candidate and selected.candidate.icon
        state.tooltipSpellID = selected.candidate and selected.candidate.spellID
        state.tooltipAppliedSpellID = model.effects[1] and model.effects[1].spellID
        state.glow = not model.satisfied
        State.ApplyAuraScanAvailability(state, model.available)
    end

    return state
end

function RoguePoison.Choices(model)
    local selection = model.selection

    if not selection.applicable then return end

    local choices = {}

    for _, candidate in ipairs(selection.candidates) do
        if selection.capacity > 1 or candidate ~= selection.candidate then
            local effect = model.bySpellID[candidate.spellID]
            local observation = model.observations[candidate.spellID]
            local state = State.Create({
                icon = candidate.icon,
                desaturated = false,
                showStatusTexture = effect ~= nil or not observation.available,
                flyoutStatus = true,
                tooltipSpellID = candidate.spellID,
                action = candidate.action,
            })

            State.ApplyActiveAura(state, effect)
            State.ApplyAuraScanAvailability(state, observation.available)
            choices[#choices + 1] = state
        end
    end

    if #choices > 0 then return choices end
end
