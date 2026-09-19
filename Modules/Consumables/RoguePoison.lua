local _, RCC = ...
local RoguePoison = {}
RCC.Consumables.RoguePoison = RoguePoison

local State = RCC.ConsumableState
local Effects = RCC.ConsumableEffects

RoguePoison.Dependencies = {
    selection = { "class.classToken", "spells", "playerSpellAuras" },
    observation = { "spells", "playerSpellAuras" },
    evaluation = { "instance.warningSeconds" },
    expiration = "playerSpellAuras",
}

function RoguePoison.GetSpellIDs(definition)
    return RCC.db.roguePoisons[definition.poisonType]
end

-- Poison casts and their self buffs use the same IDs. Keeping both declarations
-- explicit lets other spell categories use different cast and aura IDs.
RoguePoison.GetPlayerAuraSpellIDs = RoguePoison.GetSpellIDs

function RoguePoison.Observe(inputs, definition)
    local available = true

    for _, spellID in ipairs(RoguePoison.GetSpellIDs(definition)) do
        if inputs.spells[spellID].known then
            local observation = inputs.playerSpellAuras[spellID]

            if observation.aura then return observation end

            if not observation.available then
                available = false
            end
        end
    end

    return { available = available }
end

-- These are self-buff choices, not weapon-slot enchants or item preferences.
-- Keep an active known poison primary; otherwise use the first known spell in
-- data order. With two active poisons, that same order breaks the tie. Every
-- other known poison remains manually castable from the out-of-combat flyout.
function RoguePoison.Select(inputs, definition)
    local selection = { applicable = false, candidates = {} }

    if inputs.class.classToken ~= "ROGUE" then return selection end

    local observation = RoguePoison.Observe(inputs, definition)
    local activeSpellID = observation.aura and observation.aura.spellID

    for _, spellID in ipairs(RoguePoison.GetSpellIDs(definition)) do
        local spell = inputs.spells[spellID]

        if spell.known then
            local candidate = {
                spellID = spellID,
                icon = spell.icon,
                action = State.CreateSpellAction(spellID, { available = true }),
            }
            selection.candidates[#selection.candidates + 1] = candidate

            if spellID == activeSpellID then
                selection.candidate = candidate
            end
        end
    end

    selection.candidate = selection.candidate or selection.candidates[1]
    selection.applicable = selection.candidate ~= nil
    selection.action = selection.candidate and selection.candidate.action

    return selection
end

function RoguePoison.Evaluate(selection, observation, inputs, now)
    -- This first version confirms one active poison per category. It does not
    -- yet evaluate the additional slots granted by Dragon-Tempered Blades.
    return Effects.Evaluate(selection, observation, inputs.instance, now)
end
