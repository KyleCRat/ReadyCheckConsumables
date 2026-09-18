local _, RCC = ...

local FLEETING = RCC.ConsumableVariant.FLEETING

RCC.Data.AddHealingPotionItems({
    -- 11.2.0 - Fleeting
    { itemID = 244849, family = "invigorating", variant = FLEETING },

    -- 11.2.0 - Full duration
    { itemID = 244835, family = "invigorating", q = 3 },
    { itemID = 244838, family = "invigorating", q = 2 },
    { itemID = 244839, family = "invigorating", q = 1 },

    -- 11.0.0 - Fleeting
    { itemID = 212948, family = "cavedwellersDelight", q = 3, variant = FLEETING },
    { itemID = 212949, family = "cavedwellersDelight", q = 2, variant = FLEETING },
    { itemID = 212950, family = "cavedwellersDelight", q = 1, variant = FLEETING },
    { itemID = 212942, family = "algariHealing", q = 3, variant = FLEETING },
    { itemID = 212943, family = "algariHealing", q = 2, variant = FLEETING },
    { itemID = 212944, family = "algariHealing", q = 1, variant = FLEETING },

    -- 11.0.0 - Full duration
    { itemID = 212242, family = "cavedwellersDelight", q = 3 },
    { itemID = 212243, family = "cavedwellersDelight", q = 2 },
    { itemID = 212244, family = "cavedwellersDelight", q = 1 },
    { itemID = 211878, family = "algariHealing", q = 3 },
    { itemID = 211879, family = "algariHealing", q = 2 },
    { itemID = 211880, family = "algariHealing", q = 1 },
})
