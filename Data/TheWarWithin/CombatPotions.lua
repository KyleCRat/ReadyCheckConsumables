local _, RCC = ...

local DAMAGE   = RCC.CombatPotionType.DAMAGE
local UTILITY  = RCC.CombatPotionType.UTILITY
local FLEETING = RCC.CombatPotionVariant.FLEETING

RCC.Data.AddCombatPotionItems({
    {-- Tempered Potion
        type = DAMAGE,
        xpac = RCC.THE_WAR_WITHIN,
        items = {
            { itemID = 212969, variant = FLEETING },
            { itemID = 212970, variant = FLEETING },
            { itemID = 212971, variant = FLEETING },
            { itemID = 212263 },
            { itemID = 212264 },
            { itemID = 212265 },
        },
    },
    {-- Potion of Unwavering Focus
        type = DAMAGE,
        xpac = RCC.THE_WAR_WITHIN,
        items = {
            { itemID = 212963, variant = FLEETING },
            { itemID = 212964, variant = FLEETING },
            { itemID = 212965, variant = FLEETING },
            { itemID = 212257 },
            { itemID = 212258 },
            { itemID = 212259 },
        },
    },
    {-- Frontline Potion
        type = UTILITY,
        xpac = RCC.THE_WAR_WITHIN,
        items = {
            { itemID = 212966, variant = FLEETING },
            { itemID = 212967, variant = FLEETING },
            { itemID = 212968, variant = FLEETING },
            { itemID = 212260 },
            { itemID = 212261 },
            { itemID = 212262 },
        },
    },
})
