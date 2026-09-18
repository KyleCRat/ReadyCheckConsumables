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
    return S.WithItemAction(S.Result(S.Item(inputs.inventory, RCC.db.inkyBlackPotionItemID), {}))
end

function InkyBlackPotion.GetItemCandidate()
    return InkyBlackPotion.Select(RCC.ConsumableInputs.ReadSelection("inkyBlackPotion")).candidate
end

function InkyBlackPotion.Observe(inputs)
    return RCC.ConsumableEffects.Observe(inputs.playerAuras, RCC.db.inkyBlackPotionBuffIDs)
end

function InkyBlackPotion.Evaluate(selection, observation, inputs, now)
    return RCC.ConsumableEffects.Evaluate(selection, observation, inputs.instance, now)
end
