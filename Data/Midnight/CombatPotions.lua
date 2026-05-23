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
            { itemID = 245917, variant = FLEETING, q = 2 },
            { itemID = 245916, variant = FLEETING, q = 1 },
            { itemID = 241300, q = 2 },
            { itemID = 241301, q = 1 },
        },
    },
    {-- Light's Potential
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245897, variant = FLEETING },
            { itemID = 245898, variant = FLEETING },
            { itemID = 241308 },
            { itemID = 241309 },
        },
    },
    {-- Draught of Rampant Abandon
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245910, variant = FLEETING },
            { itemID = 245911, variant = FLEETING },
            { itemID = 241292 },
            { itemID = 241293 },
        },
    },
    {-- Potion of Recklessness
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245902, variant = FLEETING },
            { itemID = 245903, variant = FLEETING },
            { itemID = 241288 },
            { itemID = 241289 },
        },
    },
    {-- Potion of Zealotry
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245900, variant = FLEETING },
            { itemID = 245901, variant = FLEETING },
            { itemID = 241296 },
            { itemID = 241297 },
        },
    },
    {-- Light's Preservation
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 241286 },
            { itemID = 241287 },
        },
    },
    {-- Potion of Devoured Dreams
        type = DAMAGE,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245904, variant = FLEETING },
            { itemID = 245905, variant = FLEETING },
            { itemID = 241294 },
            { itemID = 241295 },
        },
    },
    {-- Void-Shrouded Tincture (Invisibility)
        type = UTILITY,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 241302 },
            { itemID = 241303 },
        },
    },
    {-- Enlightenment Tonic (Slow Fall)
        type = UTILITY,
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 241338 },
            { itemID = 241339 },
        },
    },
})
