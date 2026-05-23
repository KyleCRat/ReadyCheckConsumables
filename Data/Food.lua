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
--- Icon IDs used as a fallback to classify food/drink auras when the spell ID
--- is not in foodBuffIDs.
--------------------------------------------------------------------------------

RCC.db.foodAuraIconTypes = {
    [136000] = FOOD_AURA_TYPE.WELL_FED, -- Spell_misc_food,  Well Fed Food Buff
    [132805] = FOOD_AURA_TYPE.EATING,   -- Inv_drink_18,     Drinking
    [133950] = FOOD_AURA_TYPE.EATING,   -- Inv_misc_food_08, Eating
}

function FoodAuras.GetType(aura, spellID)
    if spellID and RCC.db.foodBuffIDs[spellID] then
        return FOOD_AURA_TYPE.WELL_FED
    end

    local iconID = aura and aura.icon

    if iconID then
        return RCC.db.foodAuraIconTypes[iconID]
    end
end

--------------------------------------------------------------------------------
--- Food Buff Spell IDs
--- Maps spell ID -> true for detecting Well Fed auras on players.
--- Also detected by icon ID (foodAuraIconTypes) as a fallback.
--------------------------------------------------------------------------------

RCC.db.foodBuffIDs = {
    -- 8.0.1 - Battle for Azeroth
    [257413] = true, -- Haste 5
    [257415] = true, -- Haste 7
    [297034] = true, -- Haste 9
    [257418] = true, -- Mastery 5
    [257420] = true, -- Mastery 7
    [297035] = true, -- Mastery 9
    [257408] = true, -- Crit 5
    [257410] = true, -- Crit 7
    [297039] = true, -- Crit 9
    [185736] = true, -- Versatility 3
    [257422] = true, -- Versatility 5
    [257424] = true, -- Versatility 7
    [297037] = true, -- Versatility 9
    [259449] = true, -- Intellect 7
    [259455] = true, -- Intellect 10
    [290468] = true, -- Intellect 8
    [297117] = true, -- Intellect 10
    [259452] = true, -- Strength 7
    [259456] = true, -- Strength 10
    [290469] = true, -- Strength 8
    [297118] = true, -- Strength 10
    [259448] = true, -- Agility 7
    [259454] = true, -- Agility 10
    [290467] = true, -- Agility 8
    [297116] = true, -- Agility 10
    [259453] = true, -- Stamina 11
    [259457] = true, -- Stamina 15
    [288074] = true, -- Stamina 11
    [288075] = true, -- Stamina 15
    [297119] = true, -- Stamina 16
    [297040] = true, -- Stamina 19
    [285719] = true, -- Rebirth Well Fed 5
    [285720] = true, -- Rebirth Well Fed 8
    [285721] = true, -- Rebirth Well Fed 8
    [286171] = true, -- Melee atk speed reduction 10

    -- 10.0.0 - Dragonflight
    [308488] = true, -- Haste 30
    [308506] = true, -- Mastery 30
    [308434] = true, -- Crit 30
    [308514] = true, -- Versatility 30
    [327708] = true, -- Intellect 20
    [327706] = true, -- Strength 20
    [327709] = true, -- Agility 20
    [308525] = true, -- Stamina 30
    [327707] = true, -- Stamina 30
    [308637] = true, -- Special 30
    [308474] = true, -- Haste 18
    [308504] = true, -- Mastery 18
    [308430] = true, -- Crit 18
    [308509] = true, -- Versatility 18
    [327704] = true, -- Intellect 18
    [327701] = true, -- Strength 18
    [327705] = true, -- Agility 18
    [327702] = true, -- Stamina 18
    [382145] = true, -- Haste 70
    [382150] = true, -- Mastery 70
    [382146] = true, -- Crit 70
    [382149] = true, -- Versatility 70
    [396092] = true, -- Intellect 90
    [382246] = true, -- Stamina 70
    [382247] = true, -- Stamina 90
    [382152] = true, -- Haste/Crit 90
    [382153] = true, -- Haste/Versatility 90
    [382157] = true, -- Versatility/Mastery 90
    [382230] = true, -- Stamina/Strength 70
    [382231] = true, -- Stamina/Agility 70
    [382232] = true, -- Stamina/Intellect 70
    [382154] = true, -- Haste/Mastery 90
    [382155] = true, -- Crit/Versatility 90
    [382156] = true, -- Crit/Mastery 90
    [382234] = true, -- Stamina/Strength 90
    [382235] = true, -- Stamina/Agility 90
    [382236] = true, -- Stamina/Intellect 90
}
