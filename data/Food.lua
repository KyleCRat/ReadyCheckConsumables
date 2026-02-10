local _, RCC = ...
RCC.db = RCC.db or {}

-------------------------------------------------------------------------------
--- Food Buff IDs
--- Not currently used — food is detected by icon ID (136000) instead.
--- Kept here for potential future use with spell-based food detection.
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
-- --Haste          Mastery         Crit            Versa           Int             Str             Agi             Stam            Stam            Special
-- [308488]=30, [308506]=30, [308434]=30, [308514]=30, [327708]=20, [327706]=20, [327709]=20, [308525]=30, [327707]=30, [308637]=30,
-- [308474]=18, [308504]=18, [308430]=18, [308509]=18, [327704]=18, [327701]=18, [327705]=18, [327702]=18, [308525]=18,
--                              --[341449]=20,

-- --Haste          Mastery         Crit            Versa           Int             Str             Agi             Stam            Stam            Special
-- [382145]=70, [382150]=70, [382146]=70, [382149]=70, [396092]=90,                    [382246]=70,    [382247]=90,
-- --HasteCrit     HasteVers       VersMastery     StamStr         StamAgi         StamInt         HasteMastery    CritVers        CritMastery
-- [382152]=90, [382153]=90, [382157]=90, [382230]=70, [382231]=70, [382232]=70, [382154]=90, [382155]=90, [382156]=90,
--                                                  [382234]=90,    [382235]=90,    [382236]=90,
-- }

-- RCC.db.foodBuffIDsIsBest = {
-- --Haste          Mastery         Crit            Versa           Int             Str             Agi             Stam            Stam            Special
-- [382145]=70, [382150]=70, [382146]=70, [382149]=70, [396092]=90,                    [382246]=70,    [382247]=90,
-- --HasteCrit     HasteVers       VersMastery     StamStr         StamAgi         StamInt         HasteMastery    CritVers        CritMastery
-- [382152]=90, [382153]=90, [382157]=90, [382230]=70, [382231]=70, [382232]=70, [382154]=90, [382155]=90, [382156]=90,
--                                                  [382234]=90,    [382235]=90,    [382236]=90,
-- }

RCC.db.foodBuffIDs = {}
