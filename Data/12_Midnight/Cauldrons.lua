local _, RCC = ...

local FLASK = RCC.CauldronKind.FLASK
local POTION = RCC.CauldronKind.POTION

RCC.Data.AddCauldrons({
    {
        name = "Voidlight Potion Cauldron",
        xpac = RCC.MIDNIGHT,
        kind = POTION,
        spellIDs = {
            1240267, -- R2
            1240225, -- R1
        },
        itemIDs = {
            241284, -- R2
            241285, -- R1
        },
        pickupItemIDs = {
            274764, -- R2 Fleeting Liquid Luster
            274763, -- R1 Fleeting Liquid Luster
            274765, -- R2 Fleeting Alluring Nostrum
            274766, -- R1 Fleeting Alluring Nostrum
            245916, -- R2 Fleeting Lightfused Mana Potion
            245917, -- R1 Fleeting Lightfused Mana Potion
            245918, -- R2 Fleeting Silvermoon Health Potion
            245919, -- R1 Fleeting Silvermoon Health Potion
            245898, -- R2 Fleeting Light's Potential
            245897, -- R1 Fleeting Light's Potential
            245910, -- R2 Fleeting Draught of Rampant Abandon
            245911, -- R1 Fleeting Draught of Rampant Abandon
            245902, -- R2 Fleeting Potion of Recklessness
            245903, -- R1 Fleeting Potion of Recklessness
            245901, -- R2 Fleeting Potion of Zealotry
            245900, -- R1 Fleeting Potion of Zealotry
            245904, -- R2 Fleeting Potion of Devoured Dreams
            245905, -- R1 Fleeting Potion of Devoured Dreams
        },
        target = 20,
        pickupQuantity = 5,
    },
    {
        name = "Cauldron of Sin'dorei Flasks",
        xpac = RCC.MIDNIGHT,
        kind = FLASK,
        spellIDs = {
            1240195, -- R2
            1240019, -- R1
        },
        itemIDs = {
            241318, -- R2
            241319, -- R1
        },
        pickupItemIDs = {
            245926, -- R2 Fleeting Flask of Thalassian Resistance
            245927, -- R1 Fleeting Flask of Thalassian Resistance
            245933, -- R2 Fleeting Flask of the Magisters
            245932, -- R1 Fleeting Flask of the Magisters
            245931, -- R2 Fleeting Flask of the Blood Knights
            245930, -- R1 Fleeting Flask of the Blood Knights
            245929, -- R2 Fleeting Flask of the Shattered Sun
            245928, -- R1 Fleeting Flask of the Shattered Sun
        },
        target = 2,
        pickupQuantity = 1,
    },
})
