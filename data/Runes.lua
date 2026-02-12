local _, RCC = ...
RCC.db = RCC.db or {}

-------------------------------------------------------------------------------
--- Augment Rune Spell IDs
--- Maps spell ID -> tier for detecting augment rune auras.
--- Higher tier = more current expansion.
-------------------------------------------------------------------------------

RCC.db.tableRunes = {
    [224001]  = 3, -- 7.0.3: Defiled Augmentation
    [270058]  = 4, -- 8.1.0: Battle-Scarred Augmentation
    [317065]  = 4, -- 8.3.0: Battle-Scarred Augmentation
    [347901]  = 5, -- 9.0.2: Veiled Augmentation
    [367405]  = 5, -- 9.2.0: Eternal Augmentation
    [393438]  = 6, -- 10.0.0: Draconic Augmentation
    [453250]  = 6, -- 11.0.0: Crystallization
    [1234969] = 6, -- 11.2.0: Ethereal Augmentation
    [1242347] = 6, -- 11.2.0: Soulgorged Augmentation
    [1264426] = 7, -- 12.0.0: Void-Touched Augment Rune
}

-------------------------------------------------------------------------------
--- Vantus Rune Spell IDs
--- Maps spell ID -> boss number within the raid tier.
-------------------------------------------------------------------------------

RCC.db.tableVantus = {
    -- Uldir
    [269276] = 1,
    [269405] = 2,
    [269408] = 3,
    [269407] = 4,
    [269409] = 5,
    [269411] = 6,
    [269412] = 7,
    [269413] = 8,

    -- Eternal Palace
    [298622] = 1,
    [298640] = 2,
    [298642] = 3,
    [298643] = 4,
    [298644] = 5,
    [298645] = 6,
    [298646] = 7,
    [302914] = 8,

    -- Ny'alotha
    [306475] = 1,
    [306480] = 2,
    [306476] = 3,
    [306477] = 4,
    [306478] = 5,
    [306484] = 6,
    [306485] = 7,
    [306479] = 8,
    [313550] = 9,
    [313551] = 10,
    [313554] = 11,
    [313556] = 12,

    -- Castle Nathria
    [311445] = 1,
    [334132] = 2,
    [311448] = 3,
    [311446] = 4,
    [311447] = 5,
    [311449] = 6,
    [311450] = 7,
    [311451] = 8,
    [311452] = 9,
    [334131] = 10,

    -- Sanctum of Domination
    [354384] = 1,
    [354385] = 2,
    [354386] = 3,
    [354387] = 4,
    [354388] = 5,
    [354389] = 6,
    [354390] = 7,
    [354391] = 8,
    [354392] = 9,
    [354393] = 10,

    -- Vault of the Incarnates
    [384233] = 1, [384234] = 2, [384235] = 3,
    [384192] = 1, [384203] = 2, [384201] = 3, -- Eranogz
    [384214] = 1, [384215] = 2, [384216] = 3, -- The Primal Council
    [384210] = 1, [384209] = 2, [384208] = 3, -- Terros
    [384229] = 1, [384228] = 2, [384227] = 3, -- Dathea, Ascended
    [384239] = 1, [384240] = 2, [384241] = 3, -- Kurog Grimtotem
    [384220] = 1, [384221] = 2, [384222] = 3, -- Sennarth
    [384245] = 1, [384246] = 2, [384247] = 3, -- Raszageth
    [384154] = 1, [384248] = 2, [384306] = 3,
}

-------------------------------------------------------------------------------
--- Vantus Rune Buff Spell IDs (TWW + Midnight)
--- Set-style lookup for detecting active vantus rune auras.
--- The buff name contains "Vantus Rune: <Boss Name>".
-------------------------------------------------------------------------------

RCC.db.vantusBuffIDs = {
    -- 11.0.0 - Nerub-ar Palace
    [457610] = true, -- Ulgrax the Devourer
    [458701] = true, -- The Bloodbound Horror
    [458702] = true, -- Sikran
    [458703] = true, -- Rasha'nan
    [458704] = true, -- Broodtwister Ovi'nax
    [458705] = true, -- Nexus-Princess Ky'veza
    [458706] = true, -- The Silken Court
    [458707] = true, -- Queen Ansurek

    -- 11.1.0 - Liberation of Undermine
    [472541] = true, [472604] = true, -- Vexie and the Geargrinders
    [472596] = true, [472602] = true, -- Rik Reverb
    [472595] = true, [472601] = true, -- Stix Bunkjunker
    [472597] = true, [472603] = true, -- Cauldron of Carnage
    [472592] = true, [472598] = true, -- Mug'Zee, Heads of Security
    [472594] = true, [472600] = true, -- Sprocketmonger Lockenstock
    [472593] = true, [472599] = true, -- One-Armed Bandit
    [472521] = true, [472591] = true, -- Chrome King Gallywix

    -- 11.2.0 - Manaforge Omega
    [1236900] = true, -- Plexus Sentinel
    [1236901] = true, -- Loom'ithar
    [1236902] = true, -- Soulbinder Naazindhri
    [1236903] = true, -- Forgeweaver Araz
    [1236904] = true, -- The Soul Hunters
    [1236905] = true, -- Fractillus
    [1236906] = true, -- Nexus-King Salhadaar
    [1236907] = true, -- Dimensius

    -- 12.0.0 - Midnight
    -- Voidspire
    [1276687] = true, [1276688] = true, -- Imperator Averzian
    [1276691] = true, [1276698] = true, -- Vorasius
    [1276704] = true, [1276705] = true, -- Fallen-King Salhadaar
    [1276708] = true, [1276709] = true, -- Vaelgor & Ezzorak
    [1276711] = true, [1276712] = true, -- Lightblinded Vanguard
    [1276714] = true, [1276715] = true, -- Crown of the Cosmos
    -- Dreamrift
    [1276685] = true, [1276686] = true, -- Chimaerus the Undreamt God
    -- March on Quel'Danas
    [1276666] = true, [1276669] = true, -- Belo'ren, Child of Al'ar
    [1276682] = true, [1276683] = true, -- L'ura
}

-------------------------------------------------------------------------------
--- Vantus Rune Item IDs by Raid Instance
--- Keyed by WoW instance ID (GetInstanceInfo 8th return).
--- Each array is ordered highest quality first so the update
--- function can stop at the first item found in bags.
-------------------------------------------------------------------------------

RCC.db.vantusItemsByRaid = {
    -- The War Within
    [1273] = { 226036, 226035, 226034 }, -- Nerub-ar Palace
    [1296] = { 232937, 232936, 232935 }, -- Liberation of Undermine
    [1301] = { 244149, 244148, 244147 }, -- Manaforge Omega
    [2810] = { 244149, 244148, 244147 }, -- Manaforge Omega Story mode

    -- Midnight
    [2912] = { 245880, 245879 }, -- The Voidspire
    [2913] = { 245880, 245879 }, -- March on Quel'Danas
    [2939] = { 245880, 245879 }, -- The Dreamrift
}
