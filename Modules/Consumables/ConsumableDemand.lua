local _, RCC = ...
local Demand = {}
RCC.ConsumableDemand = Demand

local Catalog = RCC.ConsumableCatalog
local Inputs = RCC.ConsumableInputs
local PHASES = { "selection", "observation", "evaluation" }

-- Category dependencies describe domain work; these are the prerequisites of
-- the input readers themselves. Keep this graph source-based, not a second
-- list of rules for Food, Flask, Repair, etc.
local SOURCE_REQUIREMENTS = {
    groupAuras = { "roster", "class" },
    cooldowns = { "inventory" },
}

local function addSource(sources, source)
    if sources[source] then return end

    sources[source] = true

    for _, required in ipairs(SOURCE_REQUIREMENTS[source] or {}) do
        addSource(sources, required)
    end
end

-- Requests are category-key sets, chosen before current applicability. A
-- hidden off-hand button must keep watching equipment so it can become usable
-- again. Only personal surfaces use this demand; macros/reporters read live
-- inputs independently and must never inherit personal button settings.
function Demand.Build(categories)
    local demand = {
        categories = categories,
        sources = {},
        itemIDs = {},
        cooldownItemIDs = {},
        weaponSlots = {},
        spellIDs = {},
        playerAuraSpellIDs = {},
    }

    for key in pairs(categories) do
        local definition = Catalog.GetDefinition(key)
        local dependencies = definition.logic.Dependencies

        for _, phase in ipairs(PHASES) do
            for _, path in ipairs(dependencies[phase] or {}) do
                local source = path:match("^[^.]+")

                if source == "slotPreference" or source == "categoryPreference" then
                    source = "preferences"
                elseif source == "categoryHistory" then
                    source = "history"
                elseif source == "slotWeapon" then
                    source = "weapons"
                    demand.weaponSlots[definition.weaponSlot] = true
                end

                addSource(demand.sources, source)
            end
        end

        if dependencies.expiration then
            addSource(demand.sources, dependencies.expiration)
        end

        for itemID in pairs(Inputs.GetItemIDs(key)) do
            demand.itemIDs[itemID] = true
        end

        for itemID in pairs(Inputs.GetCooldownItemIDs(key)) do
            demand.cooldownItemIDs[itemID] = true
        end

        for spellID in pairs(Inputs.GetSpellIDs(key)) do
            demand.spellIDs[spellID] = true
        end

        for spellID in pairs(Inputs.GetPlayerAuraSpellIDs(key)) do
            demand.playerAuraSpellIDs[spellID] = true
        end
    end

    return demand
end
