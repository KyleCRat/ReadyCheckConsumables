local _, RCC = ...

local XPAC = RCC.WARLORDS_OF_DRAENOR

RCC.Data.AddAugmentItems({
    [128482] = { xpac = XPAC, priority = 1, unlimited = false }, -- 6.2.0: Empowered Augment Rune
    [128475] = { xpac = XPAC, priority = 1, unlimited = false }, -- 6.2.0: Empowered Augment Rune
    [118630] = { xpac = XPAC, priority = 0, unlimited = false }, -- 6.0.1: Hyper Augment Rune
    [118631] = { xpac = XPAC, priority = 0, unlimited = false }, -- 6.0.1: Stout Augment Rune
    [118632] = { xpac = XPAC, priority = 0, unlimited = false }, -- 6.0.1: Focus Augment Rune
})
