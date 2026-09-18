local _, RCC = ...
local Runtime = {}
RCC.ConsumableRuntime = Runtime

local Inputs = RCC.ConsumableInputs
local State = RCC.ConsumableState
local Catalog = RCC.ConsumableCatalog

local EMPTY = {}

local function dependencyValue(inputs, path, definition)
    if path == "slotPreference" then
        return inputs.preferences[RCC.Consumables.WeaponEnchant.GetCacheKey(definition.weaponSlot)]
    elseif path == "slotWeapon" then
        return inputs.weapons[definition.weaponSlot]
    end

    local value = inputs

    for key in path:gmatch("[^.]+") do
        value = value[key]
    end

    return value
end

local function dependenciesChanged(seen, dependencies, inputs, definition)
    local changed = seen == nil
    local current = {}

    for _, path in ipairs(dependencies or EMPTY) do
        local value = dependencyValue(inputs, path, definition)
        current[path] = value

        if not seen or seen[path] ~= value then
            changed = true
        end
    end

    return changed, current
end

-- A category implements only the phases it needs: Select, Observe, Evaluate.
-- Select and Observe cache independently. Evaluate combines their immutable
-- results with their additional inputs and the current time. Presenters have
-- no authority to query or save data.
-- Records/snapshots are read-only to consumers. Revisions are per facet and
-- monotonically increasing, so opening a surface cannot miss a previous delta.
function Runtime.Create()
    return { categories = {}, revision = 0 }
end

function Runtime.RetainCategories(runtime, categories)
    for key in pairs(runtime.categories) do
        if not categories[key] then
            runtime.categories[key] = nil
        end
    end
end

-- Snapshots are complete for the requested categories only. Absent categories
-- were not requested, not observed as missing. Dropped caches lose their
-- deadlines; reactivation starts fresh without resetting the revision counter.
function Runtime.Build(runtime, inputs, now, due, categories)
    local snapshot = {
        generatedAt = now,
        states = {},
        revisions = {},
        changed = {}
    }

    for key in pairs(categories) do
        local definition = Catalog.GetDefinition(key)
        local domain = RCC.Consumables[definition.domain]
        local presenter = RCC.ConsumablePresenters[definition.domain]
        local deps = domain.Dependencies
        local previous = runtime.categories[key]
        local cache = previous or {}

        local selectionDirty, seenSelection = dependenciesChanged(
            cache.seenSelection, deps.selection, inputs, definition
        )
        local observationDirty, seenObservation = dependenciesChanged(
            cache.seenObservation, deps.observation, inputs, definition
        )
        local evaluationDirty, seenEvaluation = dependenciesChanged(
            cache.seenEvaluation, deps.evaluation, inputs, definition
        )

        local selection = cache.selection
        local observation = cache.observation

        if selectionDirty then
            local selected = domain.Select and domain.Select(inputs, true, definition.weaponSlot) or EMPTY

            if not Inputs.Equal(selected, selection) then
                selection = selected
            end
        end

        if observationDirty then
            local observed = domain.Observe and domain.Observe(inputs, definition.weaponSlot) or EMPTY

            if not Inputs.Equal(observed, observation) then
                observation = observed
            end
        end

        if not previous
            or selection ~= cache.selection
            or observation ~= cache.observation
            or evaluationDirty
            or (due and due[key])
        then
            local choices = cache.choices

            if not previous or selection ~= cache.selection then
                choices = presenter.Choices and presenter.Choices(selection) or nil

                for _, choice in ipairs(choices or EMPTY) do
                    State.Normalize(choice)
                end
            end

            local model = domain.Evaluate and domain.Evaluate(selection, observation, inputs, now)
                or { selection = selection, action = selection.action }
            local state = State.Normalize(presenter.Present(model))

            if model.allowFlyout ~= false then
                state.flyoutChoices = choices
            end

            local oldState = cache.state
            local visualChanged = not Inputs.Equal(oldState, state)
            local interactionChanged = not oldState
                or not Inputs.Equal(oldState.action, state.action)
                or not Inputs.Equal(oldState.flyoutChoices, state.flyoutChoices)
            local applicabilityChanged = not oldState or oldState.applicable ~= state.applicable
            local revisions = cache.revisions or {}

            if visualChanged or interactionChanged or applicabilityChanged then
                runtime.revision = runtime.revision + 1
                revisions = {
                    visual = visualChanged and runtime.revision or revisions.visual,
                    interaction = interactionChanged and runtime.revision or revisions.interaction,
                    applicability = applicabilityChanged and runtime.revision or revisions.applicability,
                }
                snapshot.changed[key] = {
                    visual = visualChanged,
                    interaction = interactionChanged,
                    applicability = applicabilityChanged,
                }
            end

            cache = {
                selection = selection,
                observation = observation,
                choices = choices,
                state = visualChanged and state or oldState,
                revisions = revisions,
                nextUpdateAt = model.nextUpdateAt,
                recheckAt = model.recheckAt,
                recheckSource = deps.expiration,
            }
        end

        cache.seenSelection, cache.seenObservation, cache.seenEvaluation =
            seenSelection, seenObservation, seenEvaluation
        runtime.categories[key] = cache
        snapshot.states[key] = cache.state
        snapshot.revisions[key] = cache.revisions
    end

    return snapshot
end

function Runtime.GetDeadline(runtime)
    local deadline

    for _, cache in pairs(runtime.categories) do
        if cache.nextUpdateAt then
            deadline = math.min(deadline or cache.nextUpdateAt, cache.nextUpdateAt)
        end
    end

    return deadline
end

function Runtime.GetDue(runtime, now)
    local due, sources = {}, {}

    for key, cache in pairs(runtime.categories) do
        if cache.nextUpdateAt and cache.nextUpdateAt <= now + 0.01 then
            due[key] = true
        end

        if cache.recheckAt and cache.recheckAt <= now + 0.01 and cache.recheckSource then
            sources[cache.recheckSource] = true
        end
    end

    return due, sources
end
