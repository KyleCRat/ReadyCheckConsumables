local _, RCC = ...

local MANA     = RCC.CombatPotionType.MANA
local DAMAGE   = RCC.CombatPotionType.DAMAGE
local UTILITY  = RCC.CombatPotionType.UTILITY
local FLEETING = RCC.CombatPotionVariant.FLEETING

RCC.Data.AddCombatPotionItems({
    {-- Lightfused Mana Potion
        type = MANA,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245917, q = 2, variant = FLEETING },
            { itemID = 245916, q = 1, variant = FLEETING },
            { itemID = 241300, q = 2 },
            { itemID = 241301, q = 1 },
        },
    },
    {-- Light's Potential
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245897, q = 2, variant = FLEETING },
            { itemID = 245898, q = 1, variant = FLEETING },
            { itemID = 241308, q = 2 },
            { itemID = 241309, q = 1 },
        },
    },
    {-- Draught of Rampant Abandon
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245910, q = 2, variant = FLEETING },
            { itemID = 245911, q = 1, variant = FLEETING },
            { itemID = 241292, q = 2 },
            { itemID = 241293, q = 1 },
        },
    },
    {-- Potion of Recklessness
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245902, q = 2, variant = FLEETING },
            { itemID = 245903, q = 1, variant = FLEETING },
            { itemID = 241288, q = 2 },
            { itemID = 241289, q = 1 },
        },
    },
    {-- Potion of Zealotry
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245900, q = 2, variant = FLEETING },
            { itemID = 245901, q = 1, variant = FLEETING },
            { itemID = 241296, q = 2 },
            { itemID = 241297, q = 1 },
        },
    },
    {-- Light's Preservation
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 241286, q = 2 },
            { itemID = 241287, q = 1 },
        },
    },
    {-- Potion of Devoured Dreams
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245904, q = 2, variant = FLEETING },
            { itemID = 245905, q = 1, variant = FLEETING },
            { itemID = 241294, q = 2 },
            { itemID = 241295, q = 1 },
        },
    },
    {-- Void-Shrouded Tincture (Invisibility)
        type = UTILITY,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 241302, q = 2 },
            { itemID = 241303, q = 1 },
        },
    },
    {-- Enlightenment Tonic (Slow Fall)
        type = UTILITY,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 241338, q = 2 },
            { itemID = 241339, q = 1 },
        },
    },
})
