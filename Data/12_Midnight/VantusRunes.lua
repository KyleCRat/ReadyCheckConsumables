local _, RCC = ...

RCC.Data.AddVantusBuffs({
    -- 12.0.0 - Voidspire
    [1276687] = true, [1276688] = true, -- Imperator Averzian
    [1276691] = true, [1276698] = true, -- Vorasius
    [1276704] = true, [1276705] = true, -- Fallen-King Salhadaar
    [1276708] = true, [1276709] = true, -- Vaelgor & Ezzorak
    [1276711] = true, [1276712] = true, -- Lightblinded Vanguard
    [1276714] = true, [1276715] = true, -- Crown of the Cosmos

    -- 12.0.0 - Dreamrift
    [1276685] = true, [1276686] = true, -- Chimaerus the Undreamt God

    -- 12.0.0 - Sporefall
    [1300174] = true, [1300173] = true, -- Rotmire

    -- 12.0.0 - March on Quel'Danas
    [1276666] = true, [1276669] = true, -- Belo'ren, Child of Al'ar
    [1276682] = true, [1276683] = true, -- L'ura
})

RCC.Data.AddVantusItemsByRaid({
    [1592] = { 245880, 245879 }, -- Sporefall
    [2912] = { 245880, 245879 }, -- The Voidspire
    [2913] = { 245880, 245879 }, -- March on Quel'Danas
    [2939] = { 245880, 245879 }, -- The Dreamrift
})
