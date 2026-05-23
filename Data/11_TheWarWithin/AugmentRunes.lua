local _, RCC = ...

local XPAC = RCC.THE_WAR_WITHIN

RCC.Data.AddAugmentBuffs({
    [1242347] = { xpac = XPAC, unlimited = false }, -- 11.2.0: Soulgorged Augmentation
    [1234969] = { xpac = XPAC, unlimited = true  }, -- 11.2.0: Ethereal Augmentation
    [453250]  = { xpac = XPAC, unlimited = false }, -- 11.0.0: Crystallization
})

RCC.Data.AddAugmentItems({
    [243191] = { xpac = XPAC, priority = 2, unlimited = true  }, -- 11.2.0: Ethereal Augment Rune
    [246492] = { xpac = XPAC, priority = 1, unlimited = false }, -- 11.2.0: Soulgorged Augment Rune
    [224572] = { xpac = XPAC, priority = 0, unlimited = false }, -- 11.0.0: Crystallized Augment Rune
})
