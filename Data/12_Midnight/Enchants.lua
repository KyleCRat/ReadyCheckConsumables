local _, RCC = ...

-- Group keys are readable equipment/enchant groups. Detection code can map
-- these groups to one or more inventory slot IDs later.
-- Row keys should be enchant IDs from the item link's enchantID field.
-- Midnight enchant IDs and icons still need to be collected, so those values
-- are marked with unique FIXME strings for now.

RCC.Data.AddEnchantItems({
    boots = {
        ["FIXME_ENCHANT_ID_FARSTRIDERS_HUNT_R2"] = { item = 244009, icon = "FIXME_ICON", q = 2 }, -- Farstrider's Hunt
        ["FIXME_ENCHANT_ID_FARSTRIDERS_HUNT_R1"] = { item = 244008, icon = "FIXME_ICON", q = 1 }, -- Farstrider's Hunt
        ["FIXME_ENCHANT_ID_LYNXS_DEXTERITY_R2"] = { item = 243953, icon = "FIXME_ICON", q = 2 }, -- Lynx's Dexterity
        ["FIXME_ENCHANT_ID_SHALADRASSILS_ROOTS_R2"] = { item = 243983, icon = "FIXME_ICON", q = 2 }, -- Shaladrassil's Roots
    },
    chest = {
        ["FIXME_ENCHANT_ID_MARK_OF_NALORAKK_R2"] = { item = 243947, icon = "FIXME_ICON", q = 2 }, -- Mark of Nalorakk
        ["FIXME_ENCHANT_ID_MARK_OF_THE_MAGISTER_R2"] = { item = 244003, icon = "FIXME_ICON", q = 2 }, -- Mark of the Magister
        ["FIXME_ENCHANT_ID_MARK_OF_THE_ROOTWARDEN_R2"] = { item = 243975, icon = "FIXME_ICON", q = 2 }, -- Mark of the Rootwarden
        ["FIXME_ENCHANT_ID_MARK_OF_THE_WORLDSOUL_R2"] = { item = 243977, icon = "FIXME_ICON", q = 2 }, -- Mark of the Worldsoul
    },
    helm = {
        ["FIXME_ENCHANT_ID_BLESSING_OF_SPEED_R2"] = { item = 243979, icon = "FIXME_ICON", q = 2 }, -- Blessing of Speed
        ["FIXME_ENCHANT_ID_EMPOWERED_BLESSING_OF_SPEED_R2"] = { item = 243981, icon = "FIXME_ICON", q = 2 }, -- Empowered Blessing of Speed
        ["FIXME_ENCHANT_ID_EMPOWERED_RUNE_OF_AVOIDANCE_R2"] = { item = 244007, icon = "FIXME_ICON", q = 2 }, -- Empowered Rune of Avoidance
        ["FIXME_ENCHANT_ID_HEX_OF_LEECHING_R2"] = { item = 243949, icon = "FIXME_ICON", q = 2 }, -- Hex of Leeching
        ["FIXME_ENCHANT_ID_RUNE_OF_AVOIDANCE_R2"] = { item = 244005, icon = "FIXME_ICON", q = 2 }, -- Rune of Avoidance
    },
    ring = {
        ["FIXME_ENCHANT_ID_AMANI_MASTERY_R2"] = { item = 243955, icon = "FIXME_ICON", q = 2 }, -- Amani Mastery
        ["FIXME_ENCHANT_ID_EYES_OF_THE_EAGLE_R2"] = { item = 243957, icon = "FIXME_ICON", q = 2 }, -- Eyes of the Eagle
        ["FIXME_ENCHANT_ID_NATURES_FURY_R2"] = { item = 243987, icon = "FIXME_ICON", q = 2 }, -- Nature's Fury
        ["FIXME_ENCHANT_ID_NATURES_WRATH_R2"] = { item = 243985, icon = "FIXME_ICON", q = 2 }, -- Nature's Wrath
        ["FIXME_ENCHANT_ID_SILVERMOONS_ALACRITY_R2"] = { item = 244015, icon = "FIXME_ICON", q = 2 }, -- Silvermoon's Alacrity
        ["FIXME_ENCHANT_ID_SILVERMOONS_TENACITY_R2"] = { item = 244017, icon = "FIXME_ICON", q = 2 }, -- Silvermoon's Tenacity
        ["FIXME_ENCHANT_ID_THALASSIAN_HASTE_R2"] = { item = 244011, icon = "FIXME_ICON", q = 2 }, -- Thalassian Haste
        ["FIXME_ENCHANT_ID_THALASSIAN_VERSATILITY_R2"] = { item = 244013, icon = "FIXME_ICON", q = 2 }, -- Thalassian Versatility
        ["FIXME_ENCHANT_ID_ZULJINS_MASTERY_R2"] = { item = 243959, icon = "FIXME_ICON", q = 2 }, -- Zul'jins Mastery
    },
    shoulder = {
        ["FIXME_ENCHANT_ID_AKILZONS_CELERITY_R2"] = { item = 243963, icon = "FIXME_ICON", q = 2 }, -- Akil'zon's Celerity
        ["FIXME_ENCHANT_ID_AMIRDRASSILS_GRACE_R2"] = { item = 243991, icon = "FIXME_ICON", q = 2 }, -- Amirdrassil's Grace
        ["FIXME_ENCHANT_ID_FLIGHT_OF_THE_EAGLE_R2"] = { item = 243961, icon = "FIXME_ICON", q = 2 }, -- Flight of the Eagle
        ["FIXME_ENCHANT_ID_NATURES_GRACE_R2"] = { item = 243989, icon = "FIXME_ICON", q = 2 }, -- Nature's Grace
        ["FIXME_ENCHANT_ID_SILVERMOONS_MENDING_R2"] = { item = 244021, icon = "FIXME_ICON", q = 2 }, -- Silvermoon's Mending
        ["FIXME_ENCHANT_ID_THALASSIAN_RECOVERY_R2"] = { item = 244019, icon = "FIXME_ICON", q = 2 }, -- Thalassian Recovery
    },
    weapon = {
        ["FIXME_ENCHANT_ID_ACUITY_OF_THE_RENDOREI_R2"] = { item = 244029, icon = "FIXME_ICON", q = 2 }, -- Acuity of the Ren'dorei
        ["FIXME_ENCHANT_ID_ARCANE_MASTERY_R2"] = { item = 244031, icon = "FIXME_ICON", q = 2 }, -- Arcane Mastery
        ["FIXME_ENCHANT_ID_BERSERKERS_RAGE_R2"] = { item = 243973, icon = "FIXME_ICON", q = 2 }, -- Berserker's Rage
        ["FIXME_ENCHANT_ID_FLAMES_OF_THE_SINDOREI_R2"] = { item = 244027, icon = "FIXME_ICON", q = 2 }, -- Flames of the Sin'dorei
        ["FIXME_ENCHANT_ID_JANALAIS_PRECISION_R2"] = { item = 243971, icon = "FIXME_ICON", q = 2 }, -- Jan'alai's Precision
        ["FIXME_ENCHANT_ID_STRENGTH_OF_HALAZZI_R2"] = { item = 243969, icon = "FIXME_ICON", q = 2 }, -- Strength of Halazzi
        ["FIXME_ENCHANT_ID_WORLDSOUL_AEGIS_R2"] = { item = 243999, icon = "FIXME_ICON", q = 2 }, -- Worldsoul Aegis
        ["FIXME_ENCHANT_ID_WORLDSOUL_CRADLE_R2"] = { item = 243997, icon = "FIXME_ICON", q = 2 }, -- Worldsoul Cradle
        ["FIXME_ENCHANT_ID_WORLDSOUL_TENACITY_R2"] = { item = 244001, icon = "FIXME_ICON", q = 2 }, -- Worldsoul Tenacity
    },
    tool = {
        ["FIXME_ENCHANT_ID_AMANI_PERCEPTION_R2"] = { item = 243965, icon = "FIXME_ICON", q = 2 }, -- Amani Perception
        ["FIXME_ENCHANT_ID_AMANI_RESOURCEFULNESS_R2"] = { item = 243967, icon = "FIXME_ICON", q = 2 }, -- Amani Resourcefulness
        ["FIXME_ENCHANT_ID_HARANIR_FINESSE_R2"] = { item = 243993, icon = "FIXME_ICON", q = 2 }, -- Haranir Finesse
        ["FIXME_ENCHANT_ID_HARANIR_MULTICRAFTING_R2"] = { item = 243995, icon = "FIXME_ICON", q = 2 }, -- Haranir Multicrafting
        ["FIXME_ENCHANT_ID_RENDOREI_INGENUITY_R2"] = { item = 244025, icon = "FIXME_ICON", q = 2 }, -- Ren'dorei Ingenuity
        ["FIXME_ENCHANT_ID_SINDOREI_DEFTNESS_R2"] = { item = 244023, icon = "FIXME_ICON", q = 2 }, -- Sin'dorei Deftness
    },
    legs = {
        ["FIXME_ENCHANT_ID_ARCANOWEAVE_SPELLTHREAD_R2"] = { item = 240155, icon = "FIXME_ICON", q = 2 }, -- Arcanoweave Spellthread
        ["FIXME_ENCHANT_ID_SUNFIRE_SILK_SPELLTHREAD_R2"] = { item = 240133, icon = "FIXME_ICON", q = 2 }, -- Sunfire Silk Spellthread
        ["FIXME_ENCHANT_ID_BRIGHT_LINEN_SPELLTHREAD_R2"] = { item = 240157, icon = "FIXME_ICON", q = 2 }, -- Bright Linen Spellthread
        ["FIXME_ENCHANT_ID_BLOOD_KNIGHTS_ARMOR_KIT_R2"] = { item = 244643, icon = "FIXME_ICON", q = 2 }, -- Blood Knight's Armor Kit
        ["FIXME_ENCHANT_ID_FOREST_HUNTERS_ARMOR_KIT_R2"] = { item = 244641, icon = "FIXME_ICON", q = 2 }, -- Forest Hunter's Armor Kit
        ["FIXME_ENCHANT_ID_THALASSIAN_SCOUT_ARMOR_KIT_R2"] = { item = 244645, icon = "FIXME_ICON", q = 2 }, -- Thalassian Scout Armor Kit
    },
})
