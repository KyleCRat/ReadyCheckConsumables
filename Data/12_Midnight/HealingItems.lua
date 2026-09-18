local _, RCC = ...

local FLEETING = RCC.ConsumableVariant.FLEETING

RCC.Data.AddHealingPotionItems({
    -- 12.1
    { itemID = 271884, family = "concentratedSilvermoon", q = 2 },
    { itemID = 271883, family = "concentratedSilvermoon", q = 1 },

    -- Fleeting cauldron output
    { itemID = 245918, family = "silvermoon", q = 2, variant = FLEETING },
    { itemID = 245919, family = "silvermoon", q = 1, variant = FLEETING },

    -- 12.0
    { itemID = 241304, family = "silvermoon", q = 2 },
    { itemID = 241305, family = "silvermoon", q = 1 },
    { itemID = 241298, family = "amaniExtract", q = 2 },
    { itemID = 241299, family = "amaniExtract", q = 1 },
    { itemID = 241306, family = "refreshingSerum", q = 2 },
    { itemID = 241307, family = "refreshingSerum", q = 1 },
})
