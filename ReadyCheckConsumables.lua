local ADDON_NAME, RCC = ...

RCC.db = RCC.db or {}
local L = {}  -- localization table placeholder
local F = RCC.F

_G.RCC = RCC

local GetTime = GetTime
local IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
local GetSpellInfo = C_Spell.GetSpellInfo
local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
local GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
local GetItemCount = C_Item and C_Item.GetItemCount or GetItemCount
local SendChatMessage = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
local IsEncounterInProgress = C_InstanceEncounter and C_InstanceEncounter.IsEncounterInProgress or IsEncounterInProgress

-------------------------------------------------------------------------------
--- Food
---
--- Not needed, as we just check for the food icon. 136000
-------------------------------------------------------------------------------

-- RCC.db.foodBuffIDs_headers = { 0, 5, 10, 14 }
-- RCC.db.foodBuffIDs = {
--     -- Well Fed buff ID's
--     -- [ID]=BUFF_AMOUNT

--     -- Haste
--     [257413]=5, -- 8.0.1
--     [257415]=7, -- 8.0.1
--     [297034]=9, -- 8.0.1
--     -- Mastery
--     [257418]=5, -- 8.0.1
--     [257420]=7, -- 8.0.1
--     [297035]=9, -- 8.0.1
--     -- Crit
--     [257408]=5, -- 8.0.1
--     [257410]=7, -- 8.0.1
--     [297039]=9, -- 8.0.1
--     -- Versatility
--     [185736]=3, -- 6.2.0
--     [257422]=5, -- 8.0.1
--     [257424]=7, -- 8.0.1
--     [297037]=9, -- 8.2.0
--     -- Intellect
--     [259449]=7,  -- 8.0.1
--     [259455]=10, -- 8.0.1
--     [290468]=8,  -- 8.1.0
--     [297117]=10, -- 8.2.0
--     -- Strength
--     [259452]=7,  -- 8.0.1
--     [259456]=10, -- 8.0.1
--     [290469]=8,  -- 8.1.0
--     [297118]=10, -- 8.2.0
--     -- Agility
--     [259448]=7,  -- 8.0.1
--     [259454]=10, -- 8.0.1
--     [290467]=8,  -- 8.1.0
--     [297116]=10, -- 8.2.0
--     -- Stamina
--     [259453]=11, -- 8.0.1
--     [259457]=15, -- 8.0.1
--     [288074]=11, -- 8.1.0
--     [288075]=15, -- 8.1.0
--     [297119]=16, -- 8.2.0
--     [297040]=19, -- 8.2.0
--     -- Special
--     [285719]=5, -- 8.1.0: Rebirth Well Fed
--     [285720]=8, -- 8.1.0: Rebirth Well Fed
--     [285721]=8, -- 8.1.0: Rebirth Well Fed
--     [286171]=10, -- 8.1.0: Melee atk speed reduction
-- }

-- RCC.db.StaminaFood = {
--     -- 8.0.0 - Battle for Azeroth
--     [201638]=true, -- Strength: 10
--     [288074]=true, -- Stamina:  11
--     [259457]=true, -- Stamina:  15
--     [288075]=true, -- Stamina:  15
--     [297119]=true, -- Stamina:  16
--     [297040]=true, -- Stamina:  19
-- }

-- RCC.db.foodBuffIDs_headers = {0,70,90}
-- RCC.db.foodBuffIDs = {
-- -- 10.0.0 Dragonflight
-- --Haste		    Mastery	    	Crit	    	Versa	    	Int	        	Str 	    	Agi	        	Stam	    	Stam		    Special
-- [308488]=30,	[308506]=30,	[308434]=30,	[308514]=30,	[327708]=20,	[327706]=20,	[327709]=20,	[308525]=30,	[327707]=30,	[308637]=30,
-- [308474]=18,	[308504]=18,	[308430]=18,	[308509]=18,	[327704]=18,	[327701]=18,	[327705]=18,	[327702]=18,	[308525]=18,
-- 								--[341449]=20,

-- --Haste	    	Mastery	    	Crit	    	Versa   		Int	        	Str     		Agi	        	Stam	    	Stam	    	Special
-- [382145]=70,	[382150]=70,	[382146]=70,	[382149]=70,	[396092]=90,					[382246]=70,    [382247]=90,
-- --HasteCrit 	HasteVers   	VersMastery 	StamStr	    	StamAgi	    	StamInt	    	HasteMastery	CritVers    	CritMastery
-- [382152]=90,	[382153]=90,	[382157]=90,	[382230]=70,	[382231]=70,	[382232]=70,	[382154]=90,	[382155]=90,	[382156]=90,
-- 						                        [382234]=90,	[382235]=90,	[382236]=90,
-- }

-- RCC.db.foodBuffIDsIsBest = {
-- --Haste	    	Mastery	    	Crit	    	Versa	    	Int	        	Str 	    	Agi	        	Stam    		Stam	    	Special
-- [382145]=70,	[382150]=70,	[382146]=70,	[382149]=70,	[396092]=90,					[382246]=70,    [382247]=90,
-- --HasteCrit	    HasteVers   	VersMastery	    StamStr	    	StamAgi	    	StamInt	    	HasteMastery	CritVers    	CritMastery
-- [382152]=90,	[382153]=90,	[382157]=90,	[382230]=70,	[382231]=70,	[382232]=70,	[382154]=90,	[382155]=90,	[382156]=90,
-- 						                        [382234]=90,    [382235]=90,	[382236]=90,
-- }

RCC.db.foodBuffIDs_headers = {}
RCC.db.foodBuffIDs = {}

-------------------------------------------------------------------------------
--- Flasks
-------------------------------------------------------------------------------

RCC.db.flaskBuffIDs_headers = { 0, 15, 22, 26, 70 }
RCC.db.flaskBuffIDs = {
    -- Stamina
    [251838]=15, -- 8.0.1: Flask of the Vast Horizon
    [298839]=22, -- 8.2.0: Greater Flask of the Vast Horizon
    -- Intellect
    [251837]=15, -- 8.0.1: Flask of Endless Fathoms
    [298837]=22, -- 8.2.0: Greater Flask of Endless Fathoms
    -- Agility
    [251836]=15, -- 8.0.1: Flask of the Currents
    [298836]=22, -- 8.2.0: Greater Flask of the Currents
    -- Strength
    [251839]=15, -- 8.0.1: Flask of the Undertow
    [298841]=22, -- 8.2.0: Greater Flask of the Undertow

    [307187]=26, -- 9.0.1: Spectral Stamina Flask
    [307185]=18, -- 9.0.1: Spectral Flask of Power
    [307166]=70, -- Eternal Flask

    [371339]=70, -- 10.0.0: Phial of Elemental Chaos
    [374000]=70, -- 10.0.0: Iced Phial of Corrupting Rage
    [371354]=70, -- 10.0.0: Phial of the Eye in the Storm
    [371204]=70, -- 10.0.0: Phial of Still Air
    [370662]=70, -- 10.0.0: Phial of Icy Preservation
    [373257]=70, -- 10.0.0: Phial of Glacial Fury
    [371386]=70, -- 10.0.0: Phial of Charged Isolation
    [370652]=70, -- 10.0.0: Phial of Static Empowerment
    [371172]=70, -- 10.0.0: Phial of Tepid Versatility
    [371186]=70, -- 10.0.0: Charged Phial of Alacrity

    [432021]=70, -- 11.0.0: Flask of Alchemical Chaos
    [432473]=70, -- 11.0.0: Flask of Saving Graces
    [431971]=70, -- 11.0.0: Flask of Tempered Aggression
    [431972]=70, -- 11.0.0: Flask of Tempered Swiftness
    [431974]=70, -- 11.0.0: Flask of Tempered Mastery
    [431973]=70, -- 11.0.0: Flask of Tempered Versatility
}

-- Item IDS for TWW Flasks
-- Spell IDS from flaskBuffIDs
--  [432021]=70, [432473]=70, [431971]=70, [431972]=70, [431974]=70, [431973]=70,
-- TODO: REFACTOR TO WORK WITH MIDNIGHT
-- Indicate Fleeting by making it negative (-xyz) NEVERMIND OUT OF DATE
RCC.db.flaskItemIDs = {
    212741, 212740, 212739, -- 11.0.0: Fleeting Flask of Alchemical Chaos
    212747, 212746, 212745, -- 11.0.0: Fleeting Flask of Saving Graces
    212728, 212727, 212725, -- 11.0.0: Fleeting Flask of Tempered Aggression
    212731, 212730, 212729, -- 11.0.0: Fleeting Flask of Tempered Swiftness
    212738, 212736, 212735, -- 11.0.0: Fleeting Flask of Tempered Mastery
    212734, 212733, 212732, -- 11.0.0: Fleeting Flask of Tempered Versatility
    212283, 212282, 212281, -- 11.0.0: Flask of Alchemical Chaos
    212301, 212300, 212299, -- 11.0.0: Flask of Saving Graces
    212271, 212270, 212269, -- 11.0.0: Flask of Tempered Aggression
    212274, 212273, 212272, -- 11.0.0: Flask of Tempered Swiftness
    212280, 212279, 212278, -- 11.0.0: Flask of Tempered Mastery
    212277, 212276, 212275, -- 11.0.0: Flask of Tempered Versatility
}

-------------------------------------------------------------------------------
--- Potions
-------------------------------------------------------------------------------

RCC.db.tablePotion = {
    [188024]=true, --Run haste
    [250871]=true, --Mana
    [252753]=true, --Mana channel
    [250872]=true, --Mana+hp

    [279152]=true, --Agi
    [279151]=true, --Int
    [279154]=true, --Stamina
    [279153]=true, --Str
    [251231]=true, --Armor

    [298152]=true, --Int
    [298146]=true, --Agi
    [298153]=true, --Stamina
    [298154]=true, --Str
    [298155]=true, --Armor

    [298225]=true, --Potion of Empowered Proximity
    [298317]=true, --Potion of Focused Resolve
    [300714]=true, --Potion of Unbridled Fury
    [300741]=true, --Potion of Wild Mending


    [251316]=true, --Potion of Bursting Blood
    [269853]=true, --Potion of Rising Death

    [250873]=true, --Invis
    [250878]=true, --Run haste
    [251143]=true, --Fall

    [307159]=true, --Agi
    [307162]=true, --Int
    [307163]=true, --Stam
    [307164]=true, --Str
    [307160]=true, --Armor

    [307161]=true, --Mana sleep
    [307194]=true, --Mana+hp
    [307193]=true, --Mana

    [307497]=true, --Potion of Deathly Fixation
    [307494]=true, --Potion of Empowered Exorcisms
    [307496]=true, --Potion of Divine Awakening
    [307495]=true, --Potion of Phantom Fire
    [322302]=true, --Potion of Sacrificial Anima
    [344314]=true, --Run
    [307199]=true, --Potion of Soul Purity
    [342890]=true, --Potion of Unhindered Passing
    [307196]=true, --Potion of Shadow Sight
    [307195]=true, --Invis

    -- 10.0.0 Dragonflight
    [370607]=true,
    [371028]=true,
    [371024]=true,
    [371033]=true,
    [371134]=true,
    [371152]=true,
    [371039]=true,
    [371167]=true,

    -- 11.0.0 - The War Within
    [431932]=true, -- Tempered Potion
    [431419]=true, -- Cavedweller's Delight
    [431416]=true, -- Algari Healing Potion
    [431424]=true, -- Treading Lightly
    [431418]=true, -- Algari Mana Potion
    [460074]=true, -- Grotesque Vial
    [431914]=true, -- Potion of Unwavering Focus
    [431422]=true, -- Slumbering Soul Serum
    [431941]=true, -- Potion of the Reborn Cheetah
    [431432]=true, -- Draught of Shocking Revelations
    [431925]=true, -- Frontline Potion
    [453040]=true, -- Potion Bomb of Speed
    [453162]=true, -- Potion Bomb of Recovery
    [453205]=true, -- Potion Bomb of Power

    -- 11.2.0
    [1247091]=true, -- Shrouded in Shadows
}

-------------------------------------------------------------------------------
--- Healing Items
-------------------------------------------------------------------------------

RCC.db.hsSpells = {
    [6262] = true, -- Healthstone
    [105708] = true, -- 5.0.4: Healing Potion
    [156438] = true, -- 6.0.1: Healing Tonic
    [188016] = true, -- 7.0.1: Ancient Healing Potion
    --[188018] = true, -- 7.0.1: Ancient Rejuvenation Potion
    [250870] = true, -- 8.0.1: Coastal Healing Potion
    [301308] = true, -- 8.0.1: Abyssal Healing Potion
    [307192] = true, -- 9.0.1: Spiritual Healing Potion
    [370511] = true, -- 10.0.0: Refreshing Healing Potion
    [431419] = true, -- 11.0.0: Cavedweller's Delight
    [431416] = true, -- 11.0.0: Algari Healing Potion
    [1238009]=true, -- 11.2.0: Invigorating Healing Potion
}

-------------------------------------------------------------------------------
--- Raid Buffs
-------------------------------------------------------------------------------

local                battle_shout = 6673   -- Battle Shout
local         battle_shout_scroll = 264761 -- War-Scroll of Battle Shout
local        power_word_fortitude = 21562  -- Power Word: Fortitude
local power_word_fortitude_scroll = 264764 -- War-Scroll of Fortitude
local            arcane_intellect = 1459   -- Arcane Intellect
local     arcane_intellect_scroll = 264760 -- War-Scroll of Intellect
local            mark_of_the_wild = 1126   -- Mark of the Wild
local                     skyfury = 462854 -- Skyfury
local      blessing_of_the_bronze = 381748 -- Blessing of the Bronze

RCC.db.raidBuffs = {
    { ATTACK_POWER_TOOLTIP or "AP",       "WARRIOR", battle_shout, battle_shout_scroll },
    { SPELL_STAT3_NAME     or "Stamina",  "PRIEST",  power_word_fortitude, power_word_fortitude_scroll },
    { SPELL_STAT4_NAME     or "Int",      "MAGE",    arcane_intellect,  arcane_intellect_scroll },
    { STAT_VERSATILITY     or "Vers",     "DRUID",   mark_of_the_wild },
    { STAT_MASTERY         or "Mastery",  "SHAMAN",  skyfury },
    { TUTORIAL_TITLE2      or "Movement", "EVOKER",  blessing_of_the_bronze, nil,
        {
            [381758]=true, -- Blessing of the Bronze: Heroic Leap
            [381732]=true, -- Blessing of the Bronze: Death's Advance
            [381741]=true, -- Blessing of the Bronze: Fel Rush
            [381746]=true, -- Blessing of the Bronze: Tiger Dash / Dash
            [381748]=true, -- Blessing of the Bronze: Hover
            [381750]=true, -- Blessing of the Bronze: Shimmer / Blink
            [381749]=true, -- Blessing of the Bronze: Aspect of the Cheetah
            [381751]=true, -- Blessing of the Bronze: Chi Torpedo / Roll
            [381752]=true, -- Blessing of the Bronze: Divine Steed
            [381753]=true, -- Blessing of the Bronze: Leap of Faith
            [381754]=true, -- Blessing of the Bronze: Sprint
            [381756]=true, -- Blessing of the Bronze: Spiritwalker's Grace, Spirit Walk, and Gust of Wind
            [381757]=true, -- Blessing of the Bronze: Demonic Circle: Teleport
        }
    },
}

RCC.db.tableInt = {
    [arcane_intellect]=true,
    [arcane_intellect_scroll]=7,
}
RCC.db.tableStamina = {
    [power_word_fortitude]=true,
    [power_word_fortitude_scroll]=7,
}
RCC.db.tableAP = {
    [battle_shout]=true,
    [battle_shout_scroll]=7,
}
RCC.db.tableVers = {
    [mark_of_the_wild]=true,
}
RCC.db.tableMastery = {
    [skyfury]=true,
}
RCC.db.tableMove = {
    [381758]=true, -- Blessing of the Bronze: Heroic Leap
    [381732]=true, -- Blessing of the Bronze: Death's Advance
    [381741]=true, -- Blessing of the Bronze: Fel Rush
    [381746]=true, -- Blessing of the Bronze: Tiger Dash / Dash
    [381748]=true, -- Blessing of the Bronze: Hover
    [381750]=true, -- Blessing of the Bronze: Shimmer / Blink
    [381749]=true, -- Blessing of the Bronze: Aspect of the Cheetah
    [381751]=true, -- Blessing of the Bronze: Chi Torpedo / Roll
    [381752]=true, -- Blessing of the Bronze: Divine Steed
    [381753]=true, -- Blessing of the Bronze: Leap of Faith
    [381754]=true, -- Blessing of the Bronze: Sprint
    [381756]=true, -- Blessing of the Bronze: Spiritwalker's Grace, Spirit Walk, and Gust of Wind
    [381757]=true, -- Blessing of the Bronze: Demonic Circle: Teleport
}

-------------------------------------------------------------------------------
--- Vantus Runes
---
--- TODO: No idea how this works for manaforge, need to test in a raid
-------------------------------------------------------------------------------

RCC.db.tableVantus = {
    --uldir
    [269276] = 1,
    [269405] = 2,
    [269408] = 3,
    [269407] = 4,
    [269409] = 5,
    [269411] = 6,
    [269412] = 7,
    [269413] = 8,

    --ep
    [298622] = 1,
    [298640] = 2,
    [298642] = 3,
    [298643] = 4,
    [298644] = 5,
    [298645] = 6,
    [298646] = 7,
    [302914] = 8,

    --Nyl
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

    --CN
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

    --SoD
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

    [384233] = 1, [384234] = 2, [384235] = 3, -- Vantus Rune: Vault of the Incarnates
    [384229] = 1, [384228] = 2, [384227] = 3, -- Vantus Rune: Dathea, Ascended
    [384192] = 1, [384203] = 2, [384201] = 3, -- Vantus Rune: Eranog
    [384239] = 1, [384240] = 2, [384241] = 3, -- Vantus Rune: Kurog Grimtotem
    [384245] = 1, [384246] = 2, [384247] = 3, -- Vantus Rune: Raszageth
    [384220] = 1, [384221] = 2, [384222] = 3, -- Vantus Rune: Sennarth, The Cold Breath
    [384210] = 1, [384209] = 2, [384208] = 3, -- Vantus Rune: Terros
    [384214] = 1, [384215] = 2, [384216] = 3, -- Vantus Rune: The Primal Council
    [384154] = 1, [384248] = 2, [384306] = 3, -- Vantus Rune: Vault of the Incarnates
}

-------------------------------------------------------------------------------
--- Augment Runes
-------------------------------------------------------------------------------

RCC.db.tableRunes = {
    [224001]=3,  -- 7.0.3: Defiled Augmentation
    [270058]=4,  -- 8.1.0: Battle-Scarred Augmentation
    [317065]=4,  -- 8.3.0: Battle-Scarred Augmentation
    [347901]=5,  -- 9.0.2: Veiled Augmentation
    [367405]=5,  -- 9.2.0: Eternal Augmentation
    [393438]=6,  -- 10.0.0: Draconic Augmentation
    [453250]=6,  -- 11.0.0: Crystallization
    [1234969]=6, -- 11.2.0: Ethereal Augmentation
    [1242347]=6  -- 11.2.0: Soulgorged Augmentation
}

-------------------------------------------------------------------------------
--- Weapon Buffs / Oils
-------------------------------------------------------------------------------

local wenchants = {
    [6190] = { ench=6190, item=171286, icon=463544  }, -- 9.0.1: Embalmer's Oil
    [6188] = { ench=6188, item=171285, icon=463543  }, -- 9.0.1: Shadowcore Oil
    [6200] = { ench=6200, item=171437, icon=3528422 }, -- 9.0.1: Shaded Sharpening Stone
    [6198] = { ench=6198, item=171436, icon=3528424 }, -- 9.0.1: Porous Sharpening Stone
    [6201] = { ench=6201, item=171439, icon=3528423 }, -- 9.0.1: Shaded Weightstone
    [6199] = { ench=6199, item=171438, icon=3528425 }, -- 9.0.1: Porous Weightstone

    [6381] = { ench=6381, item=191940, icon=4622275, q=3 }, -- 10.0.0: Primal Whetstone
    [6380] = { ench=6380, item=191939, icon=4622275, q=2 }, -- 10.0.0: Primal Whetstone
    [6379] = { ench=6379, item=191933, icon=4622275, q=1 }, -- 10.0.0: Primal Whetstone
    [6698] = { ench=6698, item=191945, icon=4622279, q=3 }, -- 10.0.0: Primal Weightstone
    [6697] = { ench=6697, item=191944, icon=4622279, q=2 }, -- 10.0.0: Primal Weightstone
    [6696] = { ench=6696, item=191943, icon=4622279, q=1 }, -- 10.0.0: Primal Weightstone
    [6384] = { ench=6384, item=191950, icon=4622274, q=3 }, -- 10.0.0: Primal Razorstone
    [6383] = { ench=6383, item=191949, icon=4622274, q=2 }, -- 10.0.0: Primal Razorstone
    [6382] = { ench=6382, item=191948, icon=4622274, q=1 }, -- 10.0.0: Primal Razorstone
    [6514] = { ench=6514, item=194823, icon=134421,  q=3 }, -- 10.0.0: Buzzing Rune
    [6513] = { ench=6513, item=194822, icon=134421,  q=2 }, -- 10.0.0: Buzzing Rune
    [6512] = { ench=6512, item=194821, icon=134421,  q=1 }, -- 10.0.0: Buzzing Rune
    [6695] = { ench=6695, item=194826, icon=134422,  q=3 }, -- 10.0.0: Chirping Rune
    [6694] = { ench=6694, item=194825, icon=134422,  q=2 }, -- 10.0.0: Chirping Rune
    [6515] = { ench=6515, item=194824, icon=134422,  q=1 }, -- 10.0.0: Chirping Rune
    [6518] = { ench=6518, item=194820, icon=134418,  q=3 }, -- 10.0.0: Howling Rune
    [6517] = { ench=6517, item=194819, icon=134418,  q=2 }, -- 10.0.0: Howling Rune
    [6516] = { ench=6516, item=194817, icon=134418,  q=1 }, -- 10.0.0: Howling Rune
    [6534] = { ench=6534, item=198165, icon=135644,  q=3 }, -- 10.0.0: Endless Stack of Needles
    [6533] = { ench=6533, item=198164, icon=135644,  q=2 }, -- 10.0.0: Endless Stack of Needles
    [6532] = { ench=6532, item=198163, icon=135644,  q=1 }, -- 10.0.0: Endless Stack of Needles
    [6531] = { ench=6531, item=198162, icon=249174,  q=3 }, -- 10.0.0: Completely Safe Rockets
    [6530] = { ench=6530, item=198161, icon=249174,  q=2 }, -- 10.0.0: Completely Safe Rockets
    [6529] = { ench=6529, item=198160, icon=249174,  q=1 }, -- 10.0.0: Completely Safe Rockets
    [6522] = { ench=6522, item=198312, icon=4548897, q=3 }, -- 10.0.0: Gyroscopic Kaleidoscope
    [6521] = { ench=6521, item=198311, icon=4548897, q=2 }, -- 10.0.0: Gyroscopic Kaleidoscope
    [6520] = { ench=6520, item=198310, icon=4548897, q=1 }, -- 10.0.0: Gyroscopic Kaleidoscope
    [6528] = { ench=6528, item=198318, icon=4548899, q=3 }, -- 10.0.0: High Intensity Thermal Scanner
    [6527] = { ench=6527, item=198317, icon=4548899, q=2 }, -- 10.0.0: High Intensity Thermal Scanner
    [6526] = { ench=6526, item=198316, icon=4548899, q=1 }, -- 10.0.0: High Intensity Thermal Scanner
    [6525] = { ench=6525, item=198315, icon=4548898, q=3 }, -- 10.0.0: Projectile Propulsion Pinion
    [6524] = { ench=6524, item=198314, icon=4548898, q=2 }, -- 10.0.0: Projectile Propulsion Pinion
    [6523] = { ench=6523, item=198313, icon=4548898, q=1 }, -- 10.0.0: Projectile Propulsion Pinion
    [7537] = { ench=7537, item=222890, icon=4549251, q=3 }, -- 11.0.0: Weavercloth Spellthread
    [7536] = { ench=7536, item=222889, icon=4549251, q=2 }, -- 11.0.0: Weavercloth Spellthread
    [7535] = { ench=7535, item=222888, icon=4549251, q=1 }, -- 11.0.0: Weavercloth Spellthread
    [7545] = { ench=7545, item=222504, icon=3622195, q=3 }, -- 11.0.0: Ironclaw Whetstone
    [7544] = { ench=7544, item=222503, icon=3622195, q=2 }, -- 11.0.0: Ironclaw Whetstone
    [7543] = { ench=7543, item=222502, icon=3622195, q=1 }, -- 11.0.0: Ironclaw Whetstone
    [7551] = { ench=7551, item=222510, icon=3622199, q=3 }, -- 11.0.0: Ironclaw Weightstone
    [7550] = { ench=7550, item=222509, icon=3622199, q=2 }, -- 11.0.0: Ironclaw Weightstone
    [7549] = { ench=7549, item=222508, icon=3622199, q=1 }, -- 11.0.0: Ironclaw Weightstone
    [7534] = { ench=7534, item=222893, icon=4549251, q=3 }, -- 11.0.0: Sunset Spellthread
    [7533] = { ench=7533, item=222892, icon=4549251, q=2 }, -- 11.0.0: Sunset Spellthread
    [7532] = { ench=7532, item=222891, icon=4549251, q=1 }, -- 11.0.0: Sunset Spellthread
    [7531] = { ench=7531, item=222896, icon=4549251, q=3 }, -- 11.0.0: Daybreak Spellthread
    [7530] = { ench=7530, item=222895, icon=4549251, q=2 }, -- 11.0.0: Daybreak Spellthread
    [7529] = { ench=7529, item=222894, icon=4549251, q=1 }, -- 11.0.0: Daybreak Spellthread
    [6839] = { ench=6839, item=204973, icon=134422,  q=3 }, -- 11.0.0: Hissing Rune
    [6837] = { ench=6837, item=204972, icon=134422,  q=2 }, -- 11.0.0: Hissing Rune
    [6838] = { ench=6838, item=204971, icon=134422,  q=1 }, -- 11.0.0: Hissing Rune
    [6493] = { ench=6493, item=193567, icon=4559209, q=3 }, -- 11.0.0: Reinforced Armor Kit
    [6492] = { ench=6492, item=193563, icon=4559209, q=2 }, -- 11.0.0: Reinforced Armor Kit
    [6491] = { ench=6491, item=193559, icon=4559209, q=1 }, -- 11.0.0: Reinforced Armor Kit
    [6490] = { ench=6490, item=193565, icon=4559217, q=3 }, -- 11.0.0: Fierce Armor Kit
    [6489] = { ench=6489, item=193561, icon=4559217, q=2 }, -- 11.0.0: Fierce Armor Kit
    [6488] = { ench=6488, item=193557, icon=4559217, q=1 }, -- 11.0.0: Fierce Armor Kit
    [6496] = { ench=6496, item=193564, icon=4559216, q=3 }, -- 11.0.0: Frosted Armor Kit
    [6495] = { ench=6495, item=193560, icon=4559216, q=2 }, -- 11.0.0: Frosted Armor Kit
    [6494] = { ench=6494, item=193556, icon=4559216, q=1 }, -- 11.0.0: Frosted Armor Kit
    [6538] = { ench=6538, item=194010, icon=4549251, q=3 }, -- 11.0.0: Vibrant Spellthread
    [6537] = { ench=6537, item=194009, icon=4549251, q=2 }, -- 11.0.0: Vibrant Spellthread
    [6536] = { ench=6536, item=194008, icon=4549251, q=1 }, -- 11.0.0: Vibrant Spellthread
    [6541] = { ench=6541, item=194013, icon=4549250, q=3 }, -- 11.0.0: Frozen Spellthread
    [6540] = { ench=6540, item=194012, icon=4549250, q=2 }, -- 11.0.0: Frozen Spellthread
    [6539] = { ench=6539, item=194011, icon=4549250, q=1 }, -- 11.0.0: Frozen Spellthread
    [6544] = { ench=6544, item=194016, icon=4549249, q=3 }, -- 11.0.0: Temporal Spellthread
    [6543] = { ench=6543, item=194015, icon=4549249, q=2 }, -- 11.0.0: Temporal Spellthread
    [6542] = { ench=6542, item=194014, icon=4549249, q=1 }, -- 11.0.0: Temporal Spellthread
    [7601] = { ench=7601, item=219911, icon=5975854, q=3 }, -- 11.0.0: Stormbound Armor Kit
    [7600] = { ench=7600, item=219910, icon=5975854, q=2 }, -- 11.0.0: Stormbound Armor Kit
    [7599] = { ench=7599, item=219909, icon=5975854, q=1 }, -- 11.0.0: Stormbound Armor Kit
    [7598] = { ench=7598, item=219914, icon=5975933, q=3 }, -- 11.0.0: Dual Layered Armor Kit
    [7597] = { ench=7597, item=219913, icon=5975933, q=2 }, -- 11.0.0: Dual Layered Armor Kit
    [7596] = { ench=7596, item=219912, icon=5975933, q=1 }, -- 11.0.0: Dual Layered Armor Kit
    [7595] = { ench=7595, item=219908, icon=5975753, q=3 }, -- 11.0.0: Defender's Armor Kit
    [7594] = { ench=7594, item=219907, icon=5975753, q=2 }, -- 11.0.0: Defender's Armor Kit
    [7593] = { ench=7593, item=219906, icon=5975753, q=1 }, -- 11.0.0: Defender's Armor Kit
    [6830] = { ench=6830, item=204702, icon=5088845, q=3 }, -- 11.0.0: Lambent Armor Kit
    [6829] = { ench=6829, item=204701, icon=5088845, q=2 }, -- 11.0.0: Lambent Armor Kit
    [6828] = { ench=6828, item=204700, icon=5088845, q=1 }, -- 11.0.0: Lambent Armor Kit
    [7498] = { ench=7498, item=224113, icon=609897,  q=3 }, -- 11.0.0: Oil of Deep Toxins
    [7497] = { ench=7497, item=224112, icon=609897,  q=2 }, -- 11.0.0: Oil of Deep Toxins
    [7496] = { ench=7496, item=224111, icon=609897,  q=1 }, -- 11.0.0: Oil of Deep Toxins
    [7495] = { ench=7495, item=224107, icon=609892,  q=3 }, -- 11.0.0: Algari Mana Oil
    [7494] = { ench=7494, item=224106, icon=609892,  q=2 }, -- 11.0.0: Algari Mana Oil
    [7493] = { ench=7493, item=224105, icon=609892,  q=1 }, -- 11.0.0: Algari Mana Oil
    [6904] = { ench=6904, item=205039, icon=4559225, q=3 }, -- 10.1.0: Shadowed Belt Clasp
    [6905] = { ench=6905, item=205044, icon=4559225, q=2 }, -- 10.1.0: Shadowed Belt Clasp
    [6906] = { ench=6906, item=205043, icon=4559225, q=1 }, -- 10.1.0: Shadowed Belt Clasp
    [7502] = { ench=7502, item=224110, icon=609896,  q=3 }, -- 11.0.0: Oil of Beledar's Grace
    [7501] = { ench=7501, item=224109, icon=609896,  q=2 }, -- 11.0.0: Oil of Beledar's Grace
    [7500] = { ench=7500, item=224108, icon=609896,  q=1 }, -- 11.0.0: Oil of Beledar's Grace

    [7052] = { ench=7052, item=210494, icon=1045108 }, -- Incandescent Essence

    [5401] = { ench=5401, item=-33757, icon=462329, iconoh=135814 }, -- Windfury Weapon
    [5400] = { ench=5400, item=-318038, icon=135814 },               -- Flametongue Weapon
}

--- END ITEM DEFINITIONS


-------------------------------------------------------------------------------
--- Settings
-------------------------------------------------------------------------------
local IS_SL = false
local IS_DF = false
local IS_TWW = true

local SHADOWLANDS    = 9
local DRAGONFLIGHT   = 10
local THE_WAR_WITHIN = 11
local MIDNIGHT       = 12

local CURRENT_XPAC = THE_WAR_WITHIN

-- Allow icon overrides per expansion. Goes from oldest to newest expansion
-- overriding older xpac items and icons with newer ones.
RCC.settings = {
    -- [XPAC_ID] = {
    --      rune            = { item_id = xyz, icon_id = xyz },
    --      unlimited_rune  = { item_id = xyz, icon_id = xyz },
    --      food            = { icon_id = xyz },
    --      weapon_enchants = { icon_id = xyz },
    --      flask           = { icon_id = xyz },
    --      armor_kit       = { icon_id = xyz }
    -- },
    [SHADOWLANDS] = {
        rune           = { item_id = 181468, icon_id = 134078, },
        unlimited_rune = { item_id = 190384, icon_id = 4224736, },
        armor_kit      = { item_id = 3528447 }
    },
    [DRAGONFLIGHT] = {},
    [THE_WAR_WITHIN] = {
        rune           = { item_id = 224572, icon_id = 4549102, },
        unlimited_rune = { item_id = 243191, icon_id = 3566863, },
        flask          = { icon_id = 3566840 }
    },
    [MIDNIGHT] = {
        flask = { icon_id = 7548902 },
    },
}

-- Sort the ordered IDs of xpansions for looping later
RCC.ordered_xpac_ids = {}
for xpac_id in pairs(RCC.settings) do
    table.insert(RCC.ordered_xpac_ids, xpac_id)
end
table.sort(RCC.ordered_xpac_ids)

-------------------------------------------------------------------------------
--- Set the ID's and Icon ID's for items to show
-------------------------------------------------------------------------------

local rune_item_id, rune_item_count, rune_icon_id
local unlimited_rune_item_id, unlimited_rune_item_count, unlimited_rune_icon_id
local weapon_enchant_icon_id = 463543
local food_icon_id = 136000
local flask_icon_id = 3528447
local armor_kit_icon_id = 3566840

local class_icon_id = 136051 -- Lightning Shield, this works diff

local healthstone_item_id = 5512
local healthstone_icon_id = 538745


-- Loop through expansions and take the latest version of each
for _, xpac_id in ipairs(RCC.ordered_xpac_ids) do
    if RCC.settings[xpac_id] then
        local xs = RCC.settings[xpac_id]

        -- Runes
        if xs.rune then
            rune_item_id = xs.rune.item_id
            rune_icon_id = xs.rune.icon_id
        end

        -- Unlimited Runes
        if xs.unlimited_rune then
            unlimited_rune_item_id = xs.unlimited_rune.item_id
            unlimited_rune_icon_id = xs.unlimited_rune.icon_id
        end

        -- Food
        if xs.food and xs.food.icon_id then
            food_icon_id = xs.food.icon_id
        end

        -- Weapon Enchants
        if xs.weapon_enchants and xs.weapon_enchants.icon_id then
            weapon_enchant_icon_id = xs.weapon_enchants.icon_id
        end

        -- Armor Kits
        if xs.armor_kit and xs.armor_kit.icon_id then
            armor_kit_icon_id = xs.armor_kit.icon_id
        end

        -- Flasks
        if xs.flask and xs.flask.icon_id then
            flask_icon_id = xs.flask.icon_id
        end
    end
end

-------------------------------------------------------------------------------
--- Construct the button frame
-------------------------------------------------------------------------------

-- Size of the icons in the frame
local consumables_size = 48

RCC.consumables = CreateFrame("Frame", "RCConsumables", ReadyCheckListenerFrame)
RCC.consumables:SetPoint("BOTTOM", ReadyCheckListenerFrame, "TOP", 0, 5)
RCC.consumables:SetSize(consumables_size * 5, consumables_size)
RCC.consumables:Hide()
RCC.consumables.buttons = {}

RCC.consumables.rlpointer = CreateFrame("Frame", nil, UIParent)
RCC.consumables.rlpointer:SetSize(1, 1)
RCC.consumables.rlpointer:SetPoint("CENTER")
RCC.consumables.rlpointer:Hide()

local function ButtonOnEnter(self)
    self:GetParent():SetAlpha(.7)
end

local function ButtonOnLeave(self)
    self:GetParent():SetAlpha(1)
end

RCC.consumables.state = CreateFrame('Frame', nil, nil, 'SecureHandlerStateTemplate')
RCC.consumables.state:SetAttribute('_onstate-combat', [=[
    for i=2,8 do
        if i ~= 6 then
            if self:GetFrameRef("Button"..i) then
                if newstate == 'hide' then
                    self:GetFrameRef("Button"..i):Hide()
                elseif newstate == 'show' then
                    if self:GetFrameRef("Button"..i).IsON then
                        self:GetFrameRef("Button"..i):Show()
                    end
                end
            end
        end
    end
]=])

RegisterStateDriver(RCC.consumables.state, 'combat', '[combat] hide; [nocombat] show')

local i_food = 1
local i_flask = 2
local i_kit = 3
local i_mh_oil = 4
local i_rune = 5
local i_hs = 6
local i_of_oil = 7
local i_class = 8

local FONT = "Interface\\AddOns\\ReadyCheckConsumables\\media\\fonts\\PTSansNarrow-Bold.ttf"

for i = 1, 8 do
    local button = CreateFrame("Frame", nil, RCC.consumables)
    RCC.consumables.buttons[i] = button
    button:SetSize(consumables_size,consumables_size)

    if i == 1 then
        button:SetPoint("LEFT", 0, 0)
        else
        button:SetPoint("LEFT", RCC.consumables.buttons[i-1], "RIGHT", 0, 0)
    end

    button.texture = button:CreateTexture()
    button.texture:SetAllPoints()

    button.statustexture = button:CreateTexture(nil, "OVERLAY")
    button.statustexture:SetPoint("CENTER")
    button.statustexture:SetSize(consumables_size / 2, consumables_size / 2)

    button.timeleft = button:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    button.timeleft:SetPoint("BOTTOM", button, "TOP", 0, 1)
    button.timeleft:SetFont(FONT, 12, "OUTLINE")

    button.count = button:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.count:SetFont(FONT, 14, "OUTLINE")

    if i == i_flask or i == i_kit or i == i_mh_oil or i == i_rune or i == i_of_oil or i == i_class then
        button.click = CreateFrame("Button", nil, button, "SecureActionButtonTemplate")
        button.click:SetAllPoints()
        button.click:Hide()
        button.click:RegisterForClicks("AnyUp", "AnyDown")
        if i == i_mh_oil or i == i_of_oil then
            button.click:SetAttribute("type", "item")
            button.click:SetAttribute("target-slot", i == i_mh_oil and "16" or "17")
        else
            button.click:SetAttribute("type", "macro")
        end

        button.click:SetScript("OnEnter", ButtonOnEnter)
        button.click:SetScript("OnLeave", ButtonOnLeave)

        RCC.consumables.state:SetFrameRef("Button"..i, button.click)
    end

    if i == i_food then
        -- FOOD (spell-misc-food)
        button.texture:SetTexture(food_icon_id)
        RCC.consumables.buttons.food = button
    elseif i == i_flask then
        -- Flask (Inv_alchemy_90_flask_green)
        button.texture:SetTexture(flask_icon_id)
        RCC.consumables.buttons.flask = button
    elseif i == i_kit then
        -- Armour Kit (Inv_leatherworking_armorpatch_heavy)
        button.texture:SetTexture(armor_kit_icon_id)
        RCC.consumables.buttons.kit = button
    elseif i == i_mh_oil then
        -- Weapon Oil
        button.texture:SetTexture(weapon_enchant_icon_id)
        RCC.consumables.buttons.oil = button
    elseif i == i_rune then
        -- Augment Rune
        button.texture:SetTexture(rune_texture)
        RCC.consumables.buttons.rune = button
    elseif i == i_hs then
        -- Healthstone
        button.texture:SetTexture(healthstone_icon_id)
        RCC.consumables.buttons.hs = button
    elseif i == i_of_oil then
        -- Offhand Oil
        button.texture:SetTexture(weapon_enchant_icon_id)
        RCC.consumables.buttons.oiloh = button
        button:Hide()
    elseif i == i_class then
        -- Class (Lightning Shield)
        button.texture:SetTexture(class_icon_id)
        RCC.consumables.buttons.class = button
        button:Hide()
    end
end

-------------------------------------------------------------------------------
--- Update Function
-------------------------------------------------------------------------------
local isElvUIFix
local lastWeaponEnchantItem
local wenchants_items = {}

for k, v in pairs(wenchants) do
    wenchants_items[v.item] = v
end

function RCC.consumables:Update()
    local totalButtons = 6

    -- Secret Checking
    if C_Secrets and C_Secrets.ShouldAurasBeSecret() then
        return
    elseif canaccessvalue then
        local accessData = C_UnitAuras.GetAuraDataByIndex("player", 1, "HELPFUL")

        if accessData and not canaccessvalue(accessData.icon) then
            return
        end
    end

    -- Check if UI fix is needed
    if (IsAddOnLoaded("ElvUI") or IsAddOnLoaded("ShestakUI")) and not isElvUIFix then
        self:SetParent(ReadyCheckFrame)
        self:ClearAllPoints()
        self:SetPoint("BOTTOM",ReadyCheckFrame,"TOP",0,5)
        isElvUIFix = true
    end

    -- Check for Warlock to know if we should show healthstones
    local isWarlockInRaid

    for _, name, _, class in F.IterateRoster, F.GetRaidDiffMaxGroup() do
        if class == "WARLOCK" then
            isWarlockInRaid = true
            break
        end
    end

    if not InCombatLockdown() then
        if isWarlockInRaid then
            self.buttons.hs:Show()
        else
            self.buttons.hs:Hide()
            totalButtons = totalButtons - 1
        end

        if IS_DF or IS_TWW then
            self.buttons.kit:Hide()
            totalButtons = totalButtons - 1

            self.buttons.oil:ClearAllPoints()
            self.buttons.oil:SetPoint("LEFT", self.buttons.flask, "RIGHT", 0,0)
        end
    end

    for i=1,#self.buttons do
        self.buttons[i].statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        self.buttons[i].timeleft:SetText("")
        self.buttons[i].count:SetText("")
        self.buttons[i].texture:SetDesaturated(true)
    end

    local LCG = LibStub("LibCustomGlow-1.0", true)

    local now = GetTime()

    local isFood, isRune, isFlask
    local isShamanBuff

    for i=1,60 do
        local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not auraData then
            break
        elseif RCC.db.foodBuffIDs[auraData.spellId] or auraData.icon == food_icon_id then
            self.buttons.food.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
            self.buttons.food.texture:SetDesaturated(false)
            self.buttons.food.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES, ceil((auraData.expirationTime-now)/60))
            isFood = true
        elseif RCC.db.flaskBuffIDs[auraData.spellId] then
            self.buttons.flask.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
            self.buttons.flask.texture:SetDesaturated(false)
            self.buttons.flask.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES, ceil((auraData.expirationTime-now)/60))
            self.buttons.flask.texture:SetTexture(auraData.icon)
            isFlask = true
            if auraData.expirationTime - now <= 600 then
                -- if falsk is expiring in less than 5 minutes show it as false
                isFlask = false
            end
        elseif RCC.db.tableRunes[auraData.spellId] then
            self.buttons.rune.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
            self.buttons.rune.texture:SetDesaturated(false)
            self.buttons.rune.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES, ceil((auraData.expirationTime-now)/60))
            isRune = true
        elseif auraData.spellId == 192106 then
            isShamanBuff = format(GARRISON_DURATION_MINUTES,ceil((auraData.expirationTime-now)/60))

            if auraData.expirationTime - now <= 600 then
                isShamanBuff = false
            end
        end
    end

    ---------------------------------------------------------------------------
    --- Start Health Stone Handling
    local hsCount = GetItemCount(healthstone_item_id, false, true) -- Healthstone
    local hsLockCount = GetItemCount(224464, false, true) -- Demonic Healthstone

    if hsCount and hsCount > 0 then
        self.buttons.hs.count:SetFormattedText("%d",hsCount)
        self.buttons.hs.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        self.buttons.hs.texture:SetDesaturated(false)

        if self.buttons.hs.texture.isRed then
            self.buttons.hs.texture:SetTexture(healthstone_icon_id)
            self.buttons.hs.texture.isRed = false
        end
    elseif hsLockCount and hsLockCount > 0 then
        self.buttons.hs.count:SetFormattedText("%d",hsLockCount)
        self.buttons.hs.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        self.buttons.hs.texture:SetDesaturated(false)

        if not self.buttons.hs.texture.isRed then
            self.buttons.hs.texture:SetTexture(538744)
            self.buttons.hs.texture.isRed = true
        end
    else
        self.buttons.hs.count:SetText("0")
    end
    --- END Health Stone Handling

    ---------------------------------------------------------------------------
    --- Start Flask Handling
    local flask_count = 0
    local flask_item_id

    for flask_index = 1, #RCC.db.flaskItemIDs do
        local fid = RCC.db.flaskItemIDs[flask_index]

        local count = GetItemCount(fid, false, false)

        if count and count > 0 then
            flask_item_id = fid
            flask_count = count

            break
        end
    end

    if not isFlask and (flask_count and flask_count > 0) then
        if not InCombatLockdown() then
            local itemID = flask_item_id
            local itemName = GetItemInfo(itemID)

            if itemName then
                self.buttons.flask.click:SetAttribute("macrotext1", format("/stopmacro [combat]\n/use %s", itemName))
                self.buttons.flask.click:Show()
                self.buttons.flask.click.IsON = true

                local texture = select(5, C_Item.GetItemInfoInstant(itemID))
                if texture then
                    self.buttons.flask.texture:SetTexture(texture)
                end
            else
                self.buttons.flask.click:Hide()
                self.buttons.flask.click.IsON = false
            end
        end
    else
        if not InCombatLockdown() then
            self.buttons.flask.click:Hide()
            self.buttons.flask.click.IsON = false
        end
    end

    -- Show stacks on flask
    self.buttons.flask.count:SetFormattedText("%s", flask_count > 0 and flask_count or "")

    if LCG then
        if not isFlask and (flask_count and flask_count > 0) then
            LCG.PixelGlow_Start(self.buttons.flask)
        else
            LCG.PixelGlow_Stop(self.buttons.flask)
        end
    end
    --- End Flask Handling

    ---------------------------------------------------------------------------
    --- Start Armor Kits Handling
    -- Only existed in shadowlands so far so only work if we are in shadowlands
    --
    -- KitCheck not implemented, if kits exist in the future need to re-work
    --
    --
    -- if CURRENT_XPAC == SHADOWLANDS then
    --     local kitCount = GetItemCount(172347, false, true)
    --     local kitNow, kitMax, kitTimeLeft = RCC:KitCheck()

    --     if kitNow > 0 then
    --         self.buttons.kit.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    --         self.buttons.kit.texture:SetDesaturated(false)
    --         if kitTimeLeft then
    --             self.buttons.kit.timeleft:SetText(kitTimeLeft)
    --         end
    --     end

    --     if kitCount and kitCount > 0 then
    --         if not InCombatLockdown() then
    --             local itemName = GetItemInfo(172347)
    --             if itemName then
    --                 self.buttons.kit.click:SetAttribute("macrotext1", format("/stopmacro [combat]\n/use %s\n/use 5", itemName))
    --                 self.buttons.kit.click:Show()
    --                 self.buttons.kit.click.IsON = true
    --                 else
    --                 self.buttons.kit.click:Hide()
    --                 self.buttons.kit.click.IsON = false
    --             end
    --         end
    --     else
    --         if not InCombatLockdown() then
    --             self.buttons.kit.click:Hide()
    --             self.buttons.kit.click.IsON = false
    --         end
    --     end

    --     self.buttons.kit.count:SetFormattedText("%d",kitCount)

    --     if LCG then
    --         if kitCount and kitCount > 0 and kitNow == 0 then
    --             LCG.PixelGlow_Start(self.buttons.kit)
    --         else
    --             LCG.PixelGlow_Stop(self.buttons.kit)
    --         end
    --     end
    -- end
    --- END Armor Kit Handling

    ---------------------------------------------------------------------------
    --- Start Weapon Enchant Handling
    lastWeaponEnchantItem = lastWeaponEnchantItem

    local offhandCanBeEnchanted
    local offhandItemID = GetInventoryItemID("player", 17)

    if offhandItemID then
        local _, _, _, _, _, itemClassID, itemSubClassID = GetItemInfoInstant(offhandItemID)
        if itemClassID == 2 then
            offhandCanBeEnchanted = true
        end
    end

    if not InCombatLockdown() then
        if offhandCanBeEnchanted then
            self.buttons.oiloh:Show()
            totalButtons = totalButtons + 1
            self.buttons.oiloh:ClearAllPoints()
            self.buttons.oiloh:SetPoint("LEFT",self.buttons.oil,"RIGHT",0,0)
            self.buttons.rune:ClearAllPoints()
            self.buttons.rune:SetPoint("LEFT",self.buttons.oiloh,"RIGHT",0,0)
        else
            self.buttons.oiloh:Hide()
            self.buttons.rune:ClearAllPoints()
            self.buttons.rune:SetPoint("LEFT",self.buttons.oil,"RIGHT",0,0)
        end
    end


    local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID = GetWeaponEnchantInfo()

    if hasMainHandEnchant then
        self.buttons.oil.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        self.buttons.oil.texture:SetDesaturated(false)
        self.buttons.oil.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,ceil((mainHandExpiration or 0)/1000/60))

        if wenchants[mainHandEnchantID or 0] then
            lastWeaponEnchantItem = wenchants[mainHandEnchantID].item
        end
    end

    if offhandCanBeEnchanted and hasOffHandEnchant then
        self.buttons.oiloh.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        self.buttons.oiloh.texture:SetDesaturated(false)
        self.buttons.oiloh.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,ceil((offHandExpiration or 0)/1000/60))
    end

    local wenchData

    if lastWeaponEnchantItem and wenchants_items[lastWeaponEnchantItem] then
        wenchData = wenchants_items[lastWeaponEnchantItem]
        self.buttons.oil.texture:SetTexture(wenchData.icon)
        self.buttons.oiloh.texture:SetTexture(wenchData.iconoh or wenchData.icon)
    end

    local oilItemID = lastWeaponEnchantItem

    if oilItemID then
        local oilCount = GetItemCount(oilItemID,false,true)
        self.buttons.oil.count:SetText(oilCount)
        self.buttons.oiloh.count:SetText(oilCount)

        if type(oilItemID) == 'number' and oilItemID < 0 then   --for spell enchants
            if not InCombatLockdown() then
                local spellInfo = GetSpellInfo(-oilItemID)
                local spellName = spellInfo and spellInfo.name
                self.buttons.oil.click:SetAttribute("spell", spellName)
                self.buttons.oil.click:Show()
                self.buttons.oil.click.IsON = true
                self.buttons.oil.click:SetAttribute("type", "spell")
                local spellInfo = GetSpellInfo(oilItemID == -33757 and 318038 or -oilItemID)
                local spellName = spellInfo and spellInfo.name
                self.buttons.oiloh.click:SetAttribute("spell", spellName)
                self.buttons.oiloh.click:Show()
                self.buttons.oiloh.click.IsON = true
                self.buttons.oiloh.click:SetAttribute("type", "spell")
            end

            self.buttons.oil.count:SetText("")
            self.buttons.oiloh.count:SetText("")
        elseif oilCount and oilCount > 0 then
            if not InCombatLockdown() then
                local itemName = GetItemInfo(oilItemID)

                if itemName then
                    self.buttons.oil.click:SetAttribute("item", itemName)
                    self.buttons.oil.click:Show()
                    self.buttons.oil.click.IsON = true
                    if
                        mainHandExpiration and
                        (oilItemID == 171285 or oilItemID == 171286) and
                        offhandItemID and not offhandCanBeEnchanted
                    then
                        self.buttons.oil.click:SetAttribute("type", "cancelaura")
                    else
                        self.buttons.oil.click:SetAttribute("type", "item")
                    end
                    self.buttons.oiloh.click:SetAttribute("item", itemName)
                    self.buttons.oiloh.click:Show()
                    self.buttons.oiloh.click.IsON = true
                else
                    self.buttons.oil.click:Hide()
                    self.buttons.oil.click.IsON = false
                    self.buttons.oiloh.click:Hide()
                    self.buttons.oiloh.click.IsON = false
                end
            end
        else
            if not InCombatLockdown() then
                self.buttons.oil.click:Hide()
                self.buttons.oil.click.IsON = false
                self.buttons.oiloh.click:Hide()
                self.buttons.oiloh.click.IsON = false
            end
        end

        if LCG then
            if oilCount and oilCount > 0 and (not hasMainHandEnchant or (mainHandExpiration and mainHandExpiration <= 300000)) then
                LCG.PixelGlow_Start(self.buttons.oil)
                else
                LCG.PixelGlow_Stop(self.buttons.oil)
            end

            if oilCount and oilCount > 0 and (not hasOffHandEnchant or (offHandExpiration and offHandExpiration <= 300000)) then
                LCG.PixelGlow_Start(self.buttons.oiloh)
                else
                LCG.PixelGlow_Stop(self.buttons.oiloh)
            end
        end
    else
        if LCG then
            LCG.PixelGlow_Stop(self.buttons.oil)
            LCG.PixelGlow_Stop(self.buttons.oiloh)
        end
    end
    -- END Weapon Enchant Handling

    ---------------------------------------------------------------------------
    --- Start Rune Handling
    rune_item_count = GetItemCount(rune_item_id, false, true)
    unlimited_rune_item_count = GetItemCount(unlimited_rune_item_id, false, true)

    if unlimited_rune_item_count and unlimited_rune_item_count > 0 then --no rune yet
        self.buttons.rune.count:SetText("")

        if not InCombatLockdown() then
            self.buttons.rune.texture:SetTexture(unlimited_rune_icon_id)
            local itemName = GetItemInfo(unlimited_rune_item_id)

            if itemName then
                self.buttons.rune.click:SetAttribute("macrotext1", format("/stopmacro [combat]\n/use %s", itemName))
                self.buttons.rune.click:Show()
                self.buttons.rune.click.IsON = true
                else
                self.buttons.rune.click:Hide()
                self.buttons.rune.click.IsON = false
            end
        end
    elseif rune_item_count and rune_item_count > 0 then
        self.buttons.rune.count:SetFormattedText("%d", rune_item_count)

        if not InCombatLockdown() then
            self.buttons.rune.texture:SetTexture(rune_icon_id)
            local itemName = GetItemInfo(rune_item_id)

            if itemName then
                self.buttons.rune.click:SetAttribute("macrotext1", format("/stopmacro [combat]\n/use %s", itemName))
                self.buttons.rune.click:Show()
                self.buttons.rune.click.IsON = true
            else
                self.buttons.rune.click:Hide()
                self.buttons.rune.click.IsON = false
            end
        end
    else
        self.buttons.rune.count:SetText("0")

        if not InCombatLockdown() then
            self.buttons.rune.click:Hide()
            self.buttons.rune.click.IsON = false
        end
    end

    if LCG then
        if ((rune_item_count and rune_item_count > 0) or (unlimited_rune_item_count and unlimited_rune_item_count > 0)) and not isRune then
            LCG.PixelGlow_Start(self.buttons.rune)
        else
            LCG.PixelGlow_Stop(self.buttons.rune)
        end
    end
    --- End Rune Handling


    -- Check if player is an enhancement shaman
    local isClassShamanEnh

    if select(2, UnitClass("player")) == "SHAMAN" and GetSpecialization() == 2 then
        isClassShamanEnh = true
    end

    if isClassShamanEnh then
        if isShamanBuff then
            self.buttons.class.texture:SetDesaturated(false)
            self.buttons.class.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
            self.buttons.class.timeleft:SetText(isShamanBuff)
        else
            self.buttons.class.texture:SetDesaturated(true)
        end

        if not InCombatLockdown() then
            local spellInfo = GetSpellInfo(192106).name
            local spellName = spellInfo and spellInfo.name
            self.buttons.class.click:SetAttribute("type", "spell")
            self.buttons.class.click:SetAttribute("spell", spellName)
            self.buttons.class.click:Show()
            self.buttons.class.click.IsON = true
        end
    end

    if not InCombatLockdown() then
        if isClassShamanEnh then
            self.buttons.class.texture:SetTexture(class_icon_id)
            self.buttons.class:Show()
            totalButtons = totalButtons + 1
            self.buttons.class:ClearAllPoints()

            if isWarlockInRaid then
                self.buttons.class:SetPoint("LEFT",self.buttons.hs,"RIGHT",0,0)
            else
                self.buttons.class:SetPoint("LEFT",self.buttons.rune,"RIGHT",0,0)
            end
        else
            self.buttons.class:Hide()
            self.buttons.class.click:Hide()
            self.buttons.class.click.IsON = false
        end
    end

    -- Finalize width of the frame
    if not InCombatLockdown() then
        self:SetWidth(consumables_size * totalButtons)
    end
end -- END Update() Function

function RCC.consumables:Repos(isRL)
    if InCombatLockdown() then
        return
    end

    if isRL then
        self:SetParent(self.rlpointer)
        self:ClearAllPoints()
        self:SetPoint("CENTER",self.rlpointer,"CENTER",0,0)

        self.rlpointer:Show()
        -- self.close:Show()

        self.isRLpos = true
    elseif self.isRLpos then
        local parent

        if isElvUIFix then
            parent = ReadyCheckFrame
        else
            parent = ReadyCheckListenerFrame
        end

        self:SetParent(parent)
        self:ClearAllPoints()
        self:SetPoint("BOTTOM",parent,"TOP",0,5)

        self.isRLpos = false
    end
end

function RCC.consumables:OnHide()
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("UNIT_INVENTORY_CHANGED")

    if self.cancelDelay then
        self.cancelDelay:Cancel()
        self.cancelDelay = nil
    end
end

RCC.consumables:SetScript("OnEvent", function(self, event, unit, time_to_hide)
    if event == "READY_CHECK" then
        self:Update()

        self:RegisterEvent("UNIT_AURA")
        self:RegisterEvent("UNIT_INVENTORY_CHANGED")


        if self.cancelDelay then
            self.cancelDelay:Cancel()
        end

        self.cancelDelay = C_Timer.NewTimer(time_to_hide or 40, function()
            self:UnregisterEvent("UNIT_AURA")
            self:UnregisterEvent("UNIT_INVENTORY_CHANGED")

            if self.isRLpos then
                self.rlpointer:Hide()
            end
        end)

        if unit and UnitIsUnit(unit, "player") then
            self:Repos(true)
        else
            self:Repos()
        end
    elseif event == "READY_CHECK_FINISHED" then
        RCC.consumables:OnHide()

        if self.isRLpos and not InCombatLockdown() then
            self.rlpointer:Hide()
        end
    elseif event == "UNIT_AURA" then
        if unit == "player" then
            self:Update()
        end
    elseif event == "UNIT_INVENTORY_CHANGED" then
        if unit == "player" then
            C_Timer.After(.2, function()
                self:Update()
            end)
        end
    end
end)

RCC.consumables:SetScript("OnHide", function(self)
    RCC.consumables:OnHide()
end)

RCC.consumables.Test = function(isRL)
    RCC.consumables:SetParent(UIParent)
    RCC.consumables:ClearAllPoints()
    RCC.consumables:SetPoint("CENTER")
    RCC.consumables:GetScript("OnEvent")( RCC.consumables, "READY_CHECK", isRL and UnitName 'player' or "" )
end

RCC.consumables.TestHide = function(isRL)
    RCC.consumables:GetScript("OnEvent")( RCC.consumables, "READY_CHECK_FINISHED", isRL and UnitName 'player' or "" )
end

RCC.consumables:RegisterEvent("READY_CHECK")
RCC.consumables:RegisterEvent("READY_CHECK_FINISHED")
RCC.consumables:Show()

-- /run RCC.consumables.Test(true)
-- /run RCC.consumables.TestHide(true)
