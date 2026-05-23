local _, RCC = ...

local DAMAGE   = RCC.CombatPotionType.DAMAGE
local UTILITY  = RCC.CombatPotionType.UTILITY
local FLEETING = RCC.CombatPotionVariant.FLEETING

RCC.Data.AddCombatPotionItems({
    {-- Tempered Potion
        type = DAMAGE,
        xpac = RCC.THE_WAR_WITHIN,
        items = {
            { itemID = 212969, q = 3, variant = FLEETING },
            { itemID = 212970, q = 2, variant = FLEETING },
            { itemID = 212971, q = 1, variant = FLEETING },
            { itemID = 212263, q = 3 },
            { itemID = 212264, q = 2 },
            { itemID = 212265, q = 1 },
        },
    },
    {-- Potion of Unwavering Focus
        type = DAMAGE,
        xpac = RCC.THE_WAR_WITHIN,
        items = {
            { itemID = 212963, q = 3, variant = FLEETING },
            { itemID = 212964, q = 2, variant = FLEETING },
            { itemID = 212965, q = 1, variant = FLEETING },
            { itemID = 212257, q = 3 },
            { itemID = 212258, q = 2 },
            { itemID = 212259, q = 1 },
        },
    },
    {-- Frontline Potion
        type = UTILITY,
        xpac = RCC.THE_WAR_WITHIN,
        items = {
            { itemID = 212966, q = 3, variant = FLEETING },
            { itemID = 212967, q = 2, variant = FLEETING },
            { itemID = 212968, q = 1, variant = FLEETING },
            { itemID = 212260, q = 3 },
            { itemID = 212261, q = 2 },
            { itemID = 212262, q = 1 },
        },
    },
})
