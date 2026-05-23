local _, RCC = ...

local XPAC = RCC.DRAGONFLIGHT

RCC.Data.AddAugmentBuffs({
    [393438] = { xpac = XPAC, unlimited = false }, -- 10.0.0: Draconic Augmentation
})

RCC.Data.AddAugmentItems({
    [211495] = { xpac = XPAC, priority = 1, unlimited = true  }, -- 10.2.0: Dreambound Augment Rune
    [201325] = { xpac = XPAC, priority = 0, unlimited = false }, -- 10.0.0: Draconic Augment Rune
})
