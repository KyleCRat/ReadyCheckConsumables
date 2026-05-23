local _, RCC = ...

local XPAC = RCC.BATTLE_FOR_AZEROTH

RCC.Data.AddAugmentBuffs({
    [317065] = { xpac = XPAC, unlimited = false }, -- 8.3.0: Battle-Scarred Augmentation
    [270058] = { xpac = XPAC, unlimited = false }, -- 8.1.0: Battle-Scarred Augmentation
})

RCC.Data.AddAugmentItems({
    [174906] = { xpac = XPAC, priority = 1, unlimited = false }, -- 8.3.0: Lightning-Forged Augment Rune
    [160053] = { xpac = XPAC, priority = 0, unlimited = false }, -- 8.0.1: Battle-Scarred Augment Rune
})
