local _, RCC = ...

-- 8.0.1 - Battle for Azeroth
-- Historical item alternatives, retained for reference and not loaded by the
-- current TOC. Keys are primary class buff spell IDs; values are applied auras.
RCC.Data.AddRaidBuffItemAuras({
    [6673] = { 264761 }, -- Battle Shout: War-Scroll of Battle Shout
    [21562] = { 264764 }, -- Power Word: Fortitude: War-Scroll of Fortitude
    [1459] = { 264760 }, -- Arcane Intellect: War-Scroll of Intellect
})
