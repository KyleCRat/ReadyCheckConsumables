local _, RCC = ...
RCC.db = RCC.db or {}

-------------------------------------------------------------------------------
--- Augment Rune Spell IDs
--- Maps spell ID -> tier for detecting augment rune auras.
--- Higher tier = more current expansion.
-------------------------------------------------------------------------------

RCC.db.tableRunes = {
    [1264426] = 7, -- 12.0.0: Void-Touched Augment Rune
    [1242347] = 6, -- 11.2.0: Soulgorged Augmentation
    [1234969] = 6, -- 11.2.0: Ethereal Augmentation
    [453250]  = 6, -- 11.0.0: Crystallization
    [393438]  = 6, -- 10.0.0: Draconic Augmentation
    [367405]  = 5, -- 9.2.0:  Eternal Augmentation
    [347901]  = 5, -- 9.0.2:  Veiled Augmentation
    [317065]  = 4, -- 8.3.0:  Battle-Scarred Augmentation
    [270058]  = 4, -- 8.1.0:  Battle-Scarred Augmentation
    [224001]  = 3, -- 7.0.3:  Defiled Augmentation
}

-------------------------------------------------------------------------------
--- Vantus Rune Buff Spell IDs (TWW + Midnight)
--- Set-style lookup for detecting active vantus rune auras.
--- The buff name contains "Vantus Rune: <Boss Name>".
-------------------------------------------------------------------------------

RCC.db.vantusBuffIDs = {
    ----------------------------------------------------------------------------
    --- Midnight

    -- 12.0.0 - Voidspire
    [1276687] = true, [1276688] = true, -- Imperator Averzian
    [1276691] = true, [1276698] = true, -- Vorasius
    [1276704] = true, [1276705] = true, -- Fallen-King Salhadaar
    [1276708] = true, [1276709] = true, -- Vaelgor & Ezzorak
    [1276711] = true, [1276712] = true, -- Lightblinded Vanguard
    [1276714] = true, [1276715] = true, -- Crown of the Cosmos

    -- 12.0.0 - Dreamrift
    [1276685] = true, [1276686] = true, -- Chimaerus the Undreamt God

    -- 12.0.0 - March on Quel'Danas
    [1276666] = true, [1276669] = true, -- Belo'ren, Child of Al'ar
    [1276682] = true, [1276683] = true, -- L'ura

    ----------------------------------------------------------------------------
    --- The War Within

    -- 11.2.0 - Manaforge Omega
    [1236900] = true, -- Plexus Sentinel
    [1236901] = true, -- Loom'ithar
    [1236902] = true, -- Soulbinder Naazindhri
    [1236903] = true, -- Forgeweaver Araz
    [1236904] = true, -- The Soul Hunters
    [1236905] = true, -- Fractillus
    [1236906] = true, -- Nexus-King Salhadaar
    [1236907] = true, -- Dimensius

    -- 11.1.0 - Liberation of Undermine
    [472541] = true, [472604] = true, -- Vexie and the Geargrinders
    [472596] = true, [472602] = true, -- Rik Reverb
    [472595] = true, [472601] = true, -- Stix Bunkjunker
    [472597] = true, [472603] = true, -- Cauldron of Carnage
    [472592] = true, [472598] = true, -- Mug'Zee, Heads of Security
    [472594] = true, [472600] = true, -- Sprocketmonger Lockenstock
    [472593] = true, [472599] = true, -- One-Armed Bandit
    [472521] = true, [472591] = true, -- Chrome King Gallywix

    -- 11.0.0 - Nerub-ar Palace
    [457610] = true, -- Ulgrax the Devourer
    [458701] = true, -- The Bloodbound Horror
    [458702] = true, -- Sikran
    [458703] = true, -- Rasha'nan
    [458704] = true, -- Broodtwister Ovi'nax
    [458705] = true, -- Nexus-Princess Ky'veza
    [458706] = true, -- The Silken Court
    [458707] = true, -- Queen Ansurek

    ----------------------------------------------------------------------------
    --- Dragonflight

    -- 10.2.0 - Amirdrassil, the Dream's Hope
    [425905] = 1, [425934] = 2, [425943] = 3, -- Gnarlroot
    [425906] = 1, [425935] = 2, [425944] = 3, -- Igira the Cruel
    [425907] = 1, [425936] = 2, [425945] = 3, -- Volcoross
    [425908] = 1, [425937] = 2, [425946] = 3, -- Council of Dreams
    [425909] = 1, [425938] = 2, [425947] = 3, -- Larodar, Keeper of the Flame
    [425910] = 1, [425939] = 2,               -- Nymue, Weaver of the Cycle
    [425911] = 1, [425940] = 2, [425951] = 3, -- Smolderon
    [425912] = 1, [425941] = 2, [425948] = 3, -- Tindral Sageswift
    [425913] = 1, [425942] = 2, [425949] = 3, -- Fyrakk the Blazing
    [425914] = 1, [425915] = 2, [425916] = 3, -- Amirdrassil, the Dream's Hope

    -- 10.1.0 - Aberrus, the Shadowed Crucible
    [411469] = 1                             -- Kazzara, the Hellforged
    [409619] = 1, [411507] = 2, [411513] = 3, -- Kazzara, the Hellforged
    [409622] = 1, [411514] = 2, [411515] = 3, -- Shadowflame Elemental
    [409624] = 1, [411516] = 2, [411517] = 3, -- The Forgotten Experiments
    [409626] = 1, [411523] = 2, [411526] = 3, -- Zaqali Invasion
    [409627] = 1, [411527] = 2, [411528] = 3, -- Rashok
    [409638] = 1, [411530] = 2, [411532] = 3, -- The Vigilant Steward, Zskarn
    [409640] = 1, [411534] = 2, [411535] = 3, -- Magmorax
    [409618] = 1, [411536] = 2, [411537] = 3, -- Echo of Neltharion
    [409644] = 1, [411538] = 2, [411539] = 3, -- Scalecommander Sarkareth
    [409611] = 1, [410290] = 2, [410291] = 3, -- Aberrus, the Shadowed Crucible

    -- 10.0.0 - Vault of the Incarnates
    [384192] = 1, [384203] = 2, [384201] = 3, -- Eranog
    [384214] = 1, [384215] = 2, [384216] = 3, -- The Primal Council
    [384210] = 1, [384209] = 2, [384208] = 3, -- Terros
    [384229] = 1, [384228] = 2, [384227] = 3, -- Dathea, Ascended
    [384239] = 1, [384240] = 2, [384241] = 3, -- Kurog Grimtotem
    [384220] = 1, [384221] = 2, [384222] = 3, -- Sennarth
    [384233] = 1, [384234] = 2, [384235] = 3, -- Broodkeeper Diurna
    [384245] = 1, [384246] = 2, [384247] = 3, -- Raszageth
    [384154] = 1, [384248] = 2, [384306] = 3, -- Vault of the Incarnates

    ----------------------------------------------------------------------------
    --- Shadowlands

    -- 9.2.0 - Sepulcher of the First Ones

    -- 9.1.0 - Sanctum of Domination
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

    -- 9.0.0 - Castle Nathria
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

    ----------------------------------------------------------------------------
    --- Battle for Azeroth

    -- 8.3.0 - Ny'alotha, the Waking City
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

    -- 8.2.0 - The Eternal Palace
    [298622] = 1,
    [298640] = 2,
    [298642] = 3,
    [298643] = 4,
    [298644] = 5,
    [298645] = 6,
    [298646] = 7,
    [302914] = 8,

    -- 8.1.0 - Crucible of Storms
    -- 8.1.0 - Battle of Dazar'alor

    -- 8.0.0 - Uldir
    [269276] = 1,
    [269405] = 2,
    [269408] = 3,
    [269407] = 4,
    [269409] = 5,
    [269411] = 6,
    [269412] = 7,
    [269413] = 8,
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
