local _, RCC = ...

local Flask = {}
RCC.Consumables.Flask = Flask
local Selection = RCC.ConsumableSelection
local PREFERENCE_KEY = RCC.ConsumableItemCacheKey.FLASK

Flask.Inventory = { list = RCC.db.flaskItemIDs }

Flask.Dependencies = {
    selection = { "inventory", "preferences.flask" },
    observation = { "playerAuras" },
    evaluation = { "instance.warningSeconds" },
    expiration = "playerAuras",
}

function Flask.Select(inputs)
    local choices = Selection.FamilyCandidates(inputs.inventory, {
        itemIDs = RCC.db.flaskItemIDs,
        itemData = RCC.db.flaskItemData,
        preferredID = inputs.preferences[PREFERENCE_KEY],
    })

    return Selection.Resolve(choices, { preferenceKey = PREFERENCE_KEY })
end

function Flask.Observe(inputs)
    return RCC.ConsumableEffects.Observe(inputs.playerAuras, RCC.db.flaskBuffIDs)
end

function Flask.Evaluate(selection, observation, inputs, now)
    return RCC.ConsumableEffects.Evaluate(selection, observation, inputs.instance, now)
end
