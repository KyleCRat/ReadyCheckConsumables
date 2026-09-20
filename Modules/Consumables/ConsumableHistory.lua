local _, RCC = ...
local History = {}
RCC.ConsumableHistory = History
local Choice = RCC.ConsumableChoice
local HISTORY_LIMIT = 16
local observed = {}
local seenInputs = {}
local activeCapacity = {}

-- History belongs to this character, even when explicit preferences belong to
-- a profile. Domains opt in by returning confirmed applications. Clicking,
-- selecting a preference, and observing an unavailable scan never record use.
-- Each capacity has independent history. Domains may supply public application
-- evidence (such as expiry timestamps) to distinguish a refresh from a repeated
-- read. Selection keeps an unchanged fallback pair in a stable casting order.
function History.Observe(inputs, definition)
    local logic = definition.logic

    if not logic.GetApplications then return false end

    local Inputs = RCC.ConsumableInputs
    local previousInputs = seenInputs[definition.key]
    local currentInputs = {}
    local changedInputs = previousInputs == nil

    for _, path in ipairs(logic.Dependencies.observation) do
        local value = Inputs.GetDependency(inputs, path, definition)
        currentInputs[path] = value

        if not previousInputs or not Inputs.Equal(previousInputs[path], value) then
            changedInputs = true
        end
    end

    if not changedInputs then return false end

    seenInputs[definition.key] = currentInputs
    local applications, available, capacity, evidence = logic.GetApplications(inputs, definition)
    local key = definition.key
    capacity = capacity or 1
    observed[key] = observed[key] or {}
    local previous = observed[key][capacity]
    local current = available and {} or CopyTable(previous or {})
    local saved = RCC.characterDB:Get("consumableHistory", key, capacity) or {}
    local restoringBranch = activeCapacity[key] ~= nil
        and activeCapacity[key] ~= capacity and #saved > 0
    activeCapacity[key] = capacity
    local history
    local changed = false

    for _, choice in ipairs(applications) do
        local identity = Choice.Key(choice)
        local application = evidence and evidence[identity] or true
        current[identity] = application

        if not restoringBranch and (not previous or previous[identity] ~= application) then
            local index = Choice.Contains(history or saved, choice)

            -- Reloading must not reorder an established pair just because
            -- its effects are enumerated in data order.
            if index ~= 1 and (previous ~= nil or index == nil) then
                history = history or CopyTable(saved)

                if index then table.remove(history, index) end

                table.insert(history, 1, Choice.Copy(choice))
                changed = true
            end
        end
    end

    observed[key][capacity] = current

    if changed then
        while #history > HISTORY_LIMIT do
            table.remove(history)
        end

        RCC.characterDB:Set("consumableHistory", key, capacity, history)
    end

    return changed
end

function History.Read(previous)
    local history = CopyTable(RCC.characterDB:Get("consumableHistory") or {})

    for key, branches in pairs(history) do
        if previous and RCC.ConsumableInputs.Equal(previous[key], branches) then
            history[key] = previous[key]
        end
    end

    return history
end

function History.GetChoices(history, category, capacity)
    local branches = history and history[category]

    return branches and branches[capacity or 1] or {}
end
