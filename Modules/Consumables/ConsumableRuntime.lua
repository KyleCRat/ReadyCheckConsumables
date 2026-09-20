local _, RCC = ...
local Runtime = {}
RCC.ConsumableRuntime = Runtime

local Inputs = RCC.ConsumableInputs
local State = RCC.ConsumableState
local Catalog = RCC.ConsumableCatalog

local EMPTY = {}

local function dependenciesChanged(seen, dependencies, inputs, definition)
    local changed = seen == nil
    local current = {}

    for _, path in ipairs(dependencies or EMPTY) do
        local value = Inputs.GetDependency(inputs, path, definition)
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
-- Select/Observe receive the catalog definition so shared logic can select
-- their weapon slot, poison type, or other category-specific data explicitly.
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
        local logic = definition.logic
        local presenter = definition.presenter
        local deps = logic.Dependencies
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
            local selected = logic.Select and logic.Select(inputs, definition) or EMPTY

            if selected.capacity and not Catalog.SupportsCapacity(definition, selected.capacity) then
                error("RCC: unsupported selection capacity " .. tostring(selected.capacity) .. " for " .. key)
            end

            if not Inputs.Equal(selected, selection) then
                selection = selected
            end
        end

        if observationDirty then
            local observed = logic.Observe and logic.Observe(inputs, definition) or EMPTY

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
            local model = logic.Evaluate and logic.Evaluate(selection, observation, inputs, now)
                or { selection = selection, action = selection.action }
            local choices = cache.choices

            if not previous or selection ~= cache.selection or presenter.choicesUseModel then
                local choiceInput = presenter.choicesUseModel and model or selection
                choices = presenter.Choices and presenter.Choices(choiceInput) or nil

                for _, choice in ipairs(choices or EMPTY) do
                    State.Normalize(choice)
                end
            end

            local state = presenter.Present(model)
            local candidate = selection.candidate

            if not state.action and not state.summaryCapacity and candidate and selection.preferenceKey
                and RCC.ConsumablePreferences.CanPrefer(candidate.choice)
            then
                state.preference = {
                    key = selection.preferenceKey,
                    capacity = selection.capacity or 1,
                    choice = candidate.choice,
                }
            end

            State.Normalize(state)

            if model.allowFlyout ~= false then
                state.flyoutChoices = choices
            end

            local oldState = cache.state
            local visualChanged = not Inputs.Equal(oldState, state)
            local interactionChanged = not oldState
                or not State.SameInteractions(oldState, state)
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
