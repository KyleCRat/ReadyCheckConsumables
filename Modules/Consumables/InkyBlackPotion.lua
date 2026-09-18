local _, RCC = ...
local InkyBlackPotion = {}
RCC.Consumables.InkyBlackPotion = InkyBlackPotion
local S = RCC.ConsumableSelection

InkyBlackPotion.Inventory = { itemID = RCC.db.inkyBlackPotionItemID }

InkyBlackPotion.Dependencies = {
    selection = { "inventory" },
    observation = { "playerAuras" },
    evaluation = { "instance.warningSeconds" },
    expiration = "playerAuras",
}

function InkyBlackPotion.Select(inputs)
    local candidate = S.Item(inputs.inventory, RCC.db.inkyBlackPotionItemID)

    return S.Resolve({ candidates = {}, fallbacks = { candidate } })
end

function InkyBlackPotion.Observe(inputs)
    return RCC.ConsumableEffects.Observe(inputs.playerAuras, RCC.db.inkyBlackPotionBuffIDs)
end

function InkyBlackPotion.Evaluate(selection, observation, inputs, now)
    return RCC.ConsumableEffects.Evaluate(selection, observation, inputs.instance, now)
end
