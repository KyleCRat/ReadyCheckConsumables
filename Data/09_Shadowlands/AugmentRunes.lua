local _, RCC = ...

local XPAC = RCC.SHADOWLANDS

RCC.Data.AddAugmentBuffs({
    [367405] = { xpac = XPAC, unlimited = false }, -- 9.2.0: Eternal Augmentation
    [347901] = { xpac = XPAC, unlimited = false }, -- 9.0.2: Veiled Augmentation
})

RCC.Data.AddAugmentItems({
    [190384] = { xpac = XPAC, priority = 1, unlimited = false }, -- 9.2.0: Eternal Augment Rune
    [181468] = { xpac = XPAC, priority = 0, unlimited = false }, -- 9.0.1: Veiled Augment Rune
})
