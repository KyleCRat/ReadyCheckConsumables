local _, RCC = ...
local Choice = {}
RCC.ConsumableChoice = Choice

-- Saved choices are identities, not actions or observations. An item and a
-- spell with the same numeric ID are different choices.
function Choice.IsValid(choice)
    return type(choice) == "table"
        and (choice.kind == "item" or choice.kind == "spell")
        and type(choice.id) == "number"
        and choice.id > 0
        and choice.id % 1 == 0
end

function Choice.Item(itemID)
    return { kind = "item", id = itemID }
end

function Choice.Spell(spellID)
    return { kind = "spell", id = spellID }
end

function Choice.Key(choice)
    return choice.kind .. ":" .. choice.id
end

function Choice.Equal(left, right)
    return left ~= nil and right ~= nil
        and left.kind == right.kind and left.id == right.id
end

function Choice.Copy(choice)
    return { kind = choice.kind, id = choice.id }
end

function Choice.Contains(choices, choice)
    for index, saved in ipairs(choices or {}) do
        if Choice.Equal(saved, choice) then return index end
    end
end

function Choice.ValidateBranches(branches, options)
    if type(branches) ~= "table" then return false end

    for category, capacities in pairs(branches) do
        if type(category) ~= "string" or type(capacities) ~= "table" then return false end

        for capacity, choices in pairs(capacities) do
            if type(capacity) ~= "number" or capacity < 1 or capacity % 1 ~= 0
                or type(choices) ~= "table"
            then
                return false
            end

            local count = 0
            local seen = {}

            for index, choice in pairs(choices) do
                if type(index) ~= "number" or index < 1 or index % 1 ~= 0
                    or not Choice.IsValid(choice) or seen[Choice.Key(choice)]
                then
                    return false
                end

                count = count + 1
                seen[Choice.Key(choice)] = true
            end

            for index = 1, count do
                if choices[index] == nil then return false end
            end

            if options and options.limitToCapacity and count > capacity then
                return false
            end
        end
    end

    return true
end
