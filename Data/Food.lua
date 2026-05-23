local _, RCC = ...

RCC.db = RCC.db or {}
RCC.FoodAuras = RCC.FoodAuras or {}

local FoodAuras = RCC.FoodAuras

FoodAuras.Type = FoodAuras.Type or {
    WELL_FED = "wellFed",
    EATING   = "eating",
}

local FOOD_AURA_TYPE = FoodAuras.Type

--------------------------------------------------------------------------------
--- Food and Drink Item IDs
--- Food IDs are used by the consumable frame; drink IDs are stored for future
--- use.
--- Expansion files append their item rows so the rest of the addon can keep
--- reading one combined set of food and drink tables.
--------------------------------------------------------------------------------

RCC.db.foodItemIDs = {}
RCC.db.drinkItemIDs = {}

RCC.Data = RCC.Data or {}

local function appendItemIDs(target, itemIDs)
    if not itemIDs then return end

    for i = 1, #itemIDs do
        target[#target + 1] = itemIDs[i]
    end
end

function RCC.Data.AddFoodItems(itemIDs)
    appendItemIDs(RCC.db.foodItemIDs, itemIDs)
end

function RCC.Data.AddDrinkItems(itemIDs)
    appendItemIDs(RCC.db.drinkItemIDs, itemIDs)
end

--------------------------------------------------------------------------------
--- Food Aura Icon Types
--- Icon IDs used to classify food/drink auras.
--------------------------------------------------------------------------------

RCC.db.foodAuraIconTypes = {
    [136000] = FOOD_AURA_TYPE.WELL_FED, -- Spell_misc_food,  Well Fed Food Buff
    [132805] = FOOD_AURA_TYPE.EATING,   -- Inv_drink_18,     Drinking
    [133950] = FOOD_AURA_TYPE.EATING,   -- Inv_misc_food_08, Eating
}

function FoodAuras.GetType(aura)
    local iconID = aura and aura.icon

    if iconID then
        return RCC.db.foodAuraIconTypes[iconID]
    end
end
