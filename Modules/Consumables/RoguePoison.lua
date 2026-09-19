local _, RCC = ...
local RoguePoison = {}
RCC.Consumables.RoguePoison = RoguePoison

local State = RCC.ConsumableState
local Selection = RCC.ConsumableSelection
local Choice = RCC.ConsumableChoice
local Preferences = RCC.ConsumablePreferences
local History = RCC.ConsumableHistory
local Effects = RCC.ConsumableEffects

RoguePoison.Dependencies = {
    selection = { "class.classToken", "spells", "categoryPreference", "categoryHistory" },
    observation = { "spells", "playerSpellAuras" },
    evaluation = { "instance.warningSeconds" },
    expiration = "playerSpellAuras",
}

function RoguePoison.GetPlayerAuraSpellIDs(definition)
    return RCC.db.roguePoisons[definition.poisonType]
end

function RoguePoison.GetSpellIDs(definition)
    local ids = { RCC.db.roguePoisonCapacity.talentSpellID }

    for _, spellID in ipairs(RoguePoison.GetPlayerAuraSpellIDs(definition)) do
        ids[#ids + 1] = spellID
    end

    return ids
end

function RoguePoison.GetCapacity(inputs)
    local rule = RCC.db.roguePoisonCapacity

    return inputs.spells[rule.talentSpellID].known and rule.talented or rule.default
end

function RoguePoison.Observe(inputs, definition)
    return Effects.ObserveSpells(inputs, RoguePoison.GetPlayerAuraSpellIDs(definition))
end

function RoguePoison.GetApplications(inputs, definition)
    local observation = RoguePoison.Observe(inputs, definition)
    local applications = {}
    local evidence = {}

    for _, aura in ipairs(observation.auras) do
        local choice = Choice.Spell(aura.spellID)

        applications[#applications + 1] = choice
        evidence[Choice.Key(choice)] = aura.expirationTime or aura.auraInstanceID or true
    end

    return applications, observation.available, RoguePoison.GetCapacity(inputs), evidence
end

local function dataOrder(left, right)
    return left.index < right.index
end

function RoguePoison.Select(inputs, definition)
    local selection = {
        applicable = false,
        candidates = {},
        preferences = {},
        fallbacks = {},
        capacity = RoguePoison.GetCapacity(inputs),
        preferenceKey = definition.key,
        label = definition.label,
    }

    if inputs.class.classToken ~= "ROGUE" then return selection end

    local byIdentity = {}

    for index, spellID in ipairs(RoguePoison.GetPlayerAuraSpellIDs(definition)) do
        local spell = inputs.spells[spellID]

        if spell.known then
            local candidate = {
                choice = Choice.Spell(spellID),
                spellID = spellID,
                index = index,
                name = spell.name,
                icon = spell.icon,
                action = State.CreateSpellAction(spellID, {
                    available = true,
                    preferenceKey = definition.key,
                    preferenceCapacity = selection.capacity,
                }),
            }
            selection.candidates[#selection.candidates + 1] = candidate
            byIdentity[Choice.Key(candidate.choice)] = candidate
        end
    end

    local function appendKnown(target, choices)
        for _, choice in ipairs(choices) do
            local candidate = byIdentity[Choice.Key(choice)]

            if candidate then target[#target + 1] = candidate end
        end
    end

    appendKnown(selection.preferences, Preferences.GetChoices(
        inputs.preferences, definition.key, selection.capacity
    ))
    appendKnown(selection.fallbacks, History.GetChoices(
        inputs.history, definition.key, selection.capacity
    ))

    -- Do not invent a second spell when there is no remembered pair. An
    -- explicit preference already supplies the first slot when one is set.
    if #selection.preferences == 0 and #selection.fallbacks == 0 then
        selection.fallbacks[1] = selection.candidates[1]
    end

    selection.selected = Selection.ResolveChoices(
        nil, selection.preferences, selection.fallbacks, selection.capacity, dataOrder
    )
    selection.candidate = selection.selected[1]
    selection.applicable = #selection.candidates > 0
    selection.action = State.CreateSpellSequenceAction(selection.selected, selection.capacity)

    return selection
end

function RoguePoison.Evaluate(selection, observation, inputs, now)
    return Effects.EvaluateMany(selection, observation, inputs.instance, now)
end
