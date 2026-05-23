local _, RCC = ...

local XPAC = RCC.LEGION

RCC.Data.AddAugmentBuffs({
    [224001] = { xpac = XPAC, unlimited = false }, -- 7.0.3: Defiled Augmentation
})

RCC.Data.AddAugmentItems({
    [153023] = { xpac = XPAC, priority = 1, unlimited = false }, -- 7.3.0: Lightforged Augment Rune
    [140587] = { xpac = XPAC, priority = 0, unlimited = false }, -- 7.0.3: Defiled Augment Rune
})
