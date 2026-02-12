local _, RCC = ...
RCC.db = RCC.db or {}

-------------------------------------------------------------------------------
--- Permanent Enchantments (12.0.0 - Midnight)
--- Stored for future use. Not currently used by the addon.
--- Item IDs only — enchant IDs not yet collected.
-------------------------------------------------------------------------------

RCC.db.enchants = {
    -- 12.0.0 - Midnight
    boots = {
        244009, -- Farstrider's Hunt
        243953, -- Lynx's Dexterity
        243983, -- Shaladrassil's Roots
    },
    chest = {
        243947, -- Mark of Nalorakk
        244003, -- Mark of the Magister
        243975, -- Mark of the Rootwarden
        243977, -- Mark of the Worldsoul
    },
    helm = {
        243979, -- Blessing of Speed
        243981, -- Empowered Blessing of Speed
        244007, -- Empowered Rune of Avoidance
        243949, -- Hex of Leeching
        244005, -- Rune of Avoidance
    },
    ring = {
        243955, -- Amani Mastery
        243957, -- Eyes of the Eagle
        243987, -- Nature's Fury
        243985, -- Nature's Wrath
        244015, -- Silvermoon's Alacrity
        244017, -- Silvermoon's Tenacity
        244011, -- Thalassian Haste
        244013, -- Thalassian Versatility
        243959, -- Zul'jins Mastery
    },
    shoulder = {
        243963, -- Akil'zon's Celerity
        243991, -- Amirdrassil's Grace
        243961, -- Flight of the Eagle
        243989, -- Nature's Grace
        244021, -- Silvermoon's Mending
        244019, -- Thalassian Recovery
    },
    weapon = {
        244029, -- Acuity of the Ren'dorei
        244031, -- Arcane Mastery
        243973, -- Berserker's Rage
        244027, -- Flames of the Sin'dorei
        243971, -- Jan'alai's Precision
        243969, -- Strength of Halazzi
        243999, -- Worldsoul Aegis
        243997, -- Worldsoul Cradle
        244001, -- Worldsoul Tenacity
    },
    tool = {
        243965, -- Amani Perception
        243967, -- Amani Resourcefulness
        243993, -- Haranir Finesse
        243995, -- Haranir Multicrafting
        244025, -- Ren'dorei Ingenuity
        244023, -- Sin'dorei Deftness
    },
    spellthread = {
        240155, -- Arcanoweave Spellthread
        240133, -- Sunfire Silk Spellthread
        240157, -- Bright Linen Spellthread
    },
    armorkit = {
        244643, -- Blood Knight's Armor Kit
        244641, -- Forest Hunter's Armor Kit
        244645, -- Thalassian Scout Armor Kit
    },
}
