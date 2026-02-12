local _, RCC = ...
RCC.db = RCC.db or {}

-------------------------------------------------------------------------------
--- Weapon Enchant / Oil Lookup
--- Maps enchant ID -> { ench, item, icon, [q], [iconoh] }
--- Used by the consumable frame to detect and display weapon buffs.
-------------------------------------------------------------------------------

RCC.db.wenchants = {
    -- Shaman Enchants (negative item = spell-based, not item-based)
    [5401] = { ench=5401, item=-33757,  icon=462329, iconoh=135814 }, -- Windfury Weapon
    [5400] = { ench=5400, item=-318038, icon=135814 },                -- Flametongue Weapon

    ----------------------------------------------------------------------------
    -- 12.0.0 - Midnight: Weightstone
    [7908] = { ench=7908, item=237369, icon=7548939 }, -- Refulgent Weightstone

    -- 12.0.0 - Midnight: Whetstone
    [7905] = { ench=7905, item=237371, icon=7548942 }, -- Refulgent Whetstone

    -- 12.0.0 - Midnight: Oils
    [8052] = { ench=8052, item=243734, icon=7548987 }, -- Thalassian Phoenix Oil
    [8054] = { ench=8054, item=243736, icon=7548985 }, -- Oil of Dawn
    [8056] = { ench=8056, item=243738, icon=7548986 }, -- Smuggler's Enchanted Edge

    ----------------------------------------------------------------------------
    -- 11.0.0 - The War Within: Spellthreads
    [7537] = { ench=7537, item=222890, icon=4549251, q=3 }, -- Weavercloth Spellthread
    [7536] = { ench=7536, item=222889, icon=4549251, q=2 }, -- Weavercloth Spellthread
    [7535] = { ench=7535, item=222888, icon=4549251, q=1 }, -- Weavercloth Spellthread
    [7534] = { ench=7534, item=222893, icon=4549251, q=3 }, -- Sunset Spellthread
    [7533] = { ench=7533, item=222892, icon=4549251, q=2 }, -- Sunset Spellthread
    [7532] = { ench=7532, item=222891, icon=4549251, q=1 }, -- Sunset Spellthread
    [7531] = { ench=7531, item=222896, icon=4549251, q=3 }, -- Daybreak Spellthread
    [7530] = { ench=7530, item=222895, icon=4549251, q=2 }, -- Daybreak Spellthread
    [7529] = { ench=7529, item=222894, icon=4549251, q=1 }, -- Daybreak Spellthread

    -- 11.0.0 - The War Within: Whetstones & Weightstones
    [7545] = { ench=7545, item=222504, icon=3622195, q=3 }, -- Ironclaw Whetstone
    [7544] = { ench=7544, item=222503, icon=3622195, q=2 }, -- Ironclaw Whetstone
    [7543] = { ench=7543, item=222502, icon=3622195, q=1 }, -- Ironclaw Whetstone
    [7551] = { ench=7551, item=222510, icon=3622199, q=3 }, -- Ironclaw Weightstone
    [7550] = { ench=7550, item=222509, icon=3622199, q=2 }, -- Ironclaw Weightstone
    [7549] = { ench=7549, item=222508, icon=3622199, q=1 }, -- Ironclaw Weightstone

    -- 11.0.0 - The War Within: Oils
    [7498] = { ench=7498, item=224113, icon=609897, q=3 }, -- Oil of Deep Toxins
    [7497] = { ench=7497, item=224112, icon=609897, q=2 }, -- Oil of Deep Toxins
    [7496] = { ench=7496, item=224111, icon=609897, q=1 }, -- Oil of Deep Toxins
    [7495] = { ench=7495, item=224107, icon=609892, q=3 }, -- Algari Mana Oil
    [7494] = { ench=7494, item=224106, icon=609892, q=2 }, -- Algari Mana Oil
    [7493] = { ench=7493, item=224105, icon=609892, q=1 }, -- Algari Mana Oil
    [7502] = { ench=7502, item=224110, icon=609896, q=3 }, -- Oil of Beledar's Grace
    [7501] = { ench=7501, item=224109, icon=609896, q=2 }, -- Oil of Beledar's Grace
    [7500] = { ench=7500, item=224108, icon=609896, q=1 }, -- Oil of Beledar's Grace

    -- 11.0.0 - The War Within: Armor Kits
    [7601] = { ench=7601, item=219911, icon=5975854, q=3 }, -- Stormbound Armor Kit
    [7600] = { ench=7600, item=219910, icon=5975854, q=2 }, -- Stormbound Armor Kit
    [7599] = { ench=7599, item=219909, icon=5975854, q=1 }, -- Stormbound Armor Kit
    [7598] = { ench=7598, item=219914, icon=5975933, q=3 }, -- Dual Layered Armor Kit
    [7597] = { ench=7597, item=219913, icon=5975933, q=2 }, -- Dual Layered Armor Kit
    [7596] = { ench=7596, item=219912, icon=5975933, q=1 }, -- Dual Layered Armor Kit
    [7595] = { ench=7595, item=219908, icon=5975753, q=3 }, -- Defender's Armor Kit
    [7594] = { ench=7594, item=219907, icon=5975753, q=2 }, -- Defender's Armor Kit
    [7593] = { ench=7593, item=219906, icon=5975753, q=1 }, -- Defender's Armor Kit
    [6830] = { ench=6830, item=204702, icon=5088845, q=3 }, -- Lambent Armor Kit
    [6829] = { ench=6829, item=204701, icon=5088845, q=2 }, -- Lambent Armor Kit
    [6828] = { ench=6828, item=204700, icon=5088845, q=1 }, -- Lambent Armor Kit

    ----------------------------------------------------------------------------
    -- 10.0.0 - Dragonflight: Whetstones & Weightstones
    [6381] = { ench=6381, item=191940, icon=4622275, q=3 }, -- Primal Whetstone
    [6380] = { ench=6380, item=191939, icon=4622275, q=2 }, -- Primal Whetstone
    [6379] = { ench=6379, item=191933, icon=4622275, q=1 }, -- Primal Whetstone
    [6698] = { ench=6698, item=191945, icon=4622279, q=3 }, -- Primal Weightstone
    [6697] = { ench=6697, item=191944, icon=4622279, q=2 }, -- Primal Weightstone
    [6696] = { ench=6696, item=191943, icon=4622279, q=1 }, -- Primal Weightstone
    [6384] = { ench=6384, item=191950, icon=4622274, q=3 }, -- Primal Razorstone
    [6383] = { ench=6383, item=191949, icon=4622274, q=2 }, -- Primal Razorstone
    [6382] = { ench=6382, item=191948, icon=4622274, q=1 }, -- Primal Razorstone

    -- 10.0.0 - Dragonflight: Runes
    [6514] = { ench=6514, item=194823, icon=134421, q=3 }, -- Buzzing Rune
    [6513] = { ench=6513, item=194822, icon=134421, q=2 }, -- Buzzing Rune
    [6512] = { ench=6512, item=194821, icon=134421, q=1 }, -- Buzzing Rune
    [6695] = { ench=6695, item=194826, icon=134422, q=3 }, -- Chirping Rune
    [6694] = { ench=6694, item=194825, icon=134422, q=2 }, -- Chirping Rune
    [6515] = { ench=6515, item=194824, icon=134422, q=1 }, -- Chirping Rune
    [6518] = { ench=6518, item=194820, icon=134418, q=3 }, -- Howling Rune
    [6517] = { ench=6517, item=194819, icon=134418, q=2 }, -- Howling Rune
    [6516] = { ench=6516, item=194817, icon=134418, q=1 }, -- Howling Rune

    -- 10.0.0 - Dragonflight: Engineering
    [6534] = { ench=6534, item=198165, icon=135644,  q=3 }, -- Endless Stack of Needles
    [6533] = { ench=6533, item=198164, icon=135644,  q=2 }, -- Endless Stack of Needles
    [6532] = { ench=6532, item=198163, icon=135644,  q=1 }, -- Endless Stack of Needles
    [6531] = { ench=6531, item=198162, icon=249174,  q=3 }, -- Completely Safe Rockets
    [6530] = { ench=6530, item=198161, icon=249174,  q=2 }, -- Completely Safe Rockets
    [6529] = { ench=6529, item=198160, icon=249174,  q=1 }, -- Completely Safe Rockets
    [6522] = { ench=6522, item=198312, icon=4548897, q=3 }, -- Gyroscopic Kaleidoscope
    [6521] = { ench=6521, item=198311, icon=4548897, q=2 }, -- Gyroscopic Kaleidoscope
    [6520] = { ench=6520, item=198310, icon=4548897, q=1 }, -- Gyroscopic Kaleidoscope
    [6528] = { ench=6528, item=198318, icon=4548899, q=3 }, -- High Intensity Thermal Scanner
    [6527] = { ench=6527, item=198317, icon=4548899, q=2 }, -- High Intensity Thermal Scanner
    [6526] = { ench=6526, item=198316, icon=4548899, q=1 }, -- High Intensity Thermal Scanner
    [6525] = { ench=6525, item=198315, icon=4548898, q=3 }, -- Projectile Propulsion Pinion
    [6524] = { ench=6524, item=198314, icon=4548898, q=2 }, -- Projectile Propulsion Pinion
    [6523] = { ench=6523, item=198313, icon=4548898, q=1 }, -- Projectile Propulsion Pinion

    -- 10.0.0 - Dragonflight: Spellthreads
    [6538] = { ench=6538, item=194010, icon=4549251, q=3 }, -- Vibrant Spellthread
    [6537] = { ench=6537, item=194009, icon=4549251, q=2 }, -- Vibrant Spellthread
    [6536] = { ench=6536, item=194008, icon=4549251, q=1 }, -- Vibrant Spellthread
    [6541] = { ench=6541, item=194013, icon=4549250, q=3 }, -- Frozen Spellthread
    [6540] = { ench=6540, item=194012, icon=4549250, q=2 }, -- Frozen Spellthread
    [6539] = { ench=6539, item=194011, icon=4549250, q=1 }, -- Frozen Spellthread
    [6544] = { ench=6544, item=194016, icon=4549249, q=3 }, -- Temporal Spellthread
    [6543] = { ench=6543, item=194015, icon=4549249, q=2 }, -- Temporal Spellthread
    [6542] = { ench=6542, item=194014, icon=4549249, q=1 }, -- Temporal Spellthread

    -- 10.0.0 - Dragonflight: Armor Kits
    [6493] = { ench=6493, item=193567, icon=4559209, q=3 }, -- Reinforced Armor Kit
    [6492] = { ench=6492, item=193563, icon=4559209, q=2 }, -- Reinforced Armor Kit
    [6491] = { ench=6491, item=193559, icon=4559209, q=1 }, -- Reinforced Armor Kit
    [6490] = { ench=6490, item=193565, icon=4559217, q=3 }, -- Fierce Armor Kit
    [6489] = { ench=6489, item=193561, icon=4559217, q=2 }, -- Fierce Armor Kit
    [6488] = { ench=6488, item=193557, icon=4559217, q=1 }, -- Fierce Armor Kit
    [6496] = { ench=6496, item=193564, icon=4559216, q=3 }, -- Frosted Armor Kit
    [6495] = { ench=6495, item=193560, icon=4559216, q=2 }, -- Frosted Armor Kit
    [6494] = { ench=6494, item=193556, icon=4559216, q=1 }, -- Frosted Armor Kit

    -- 10.1.0 - Dragonflight: Belt Clasp
    [6904] = { ench=6904, item=205039, icon=4559225, q=3 }, -- Shadowed Belt Clasp
    [6905] = { ench=6905, item=205044, icon=4559225, q=2 }, -- Shadowed Belt Clasp
    [6906] = { ench=6906, item=205043, icon=4559225, q=1 }, -- Shadowed Belt Clasp

    -- 10.1.0 - Dragonflight: Hissing Rune
    [6839] = { ench=6839, item=204973, icon=134422, q=3 }, -- Hissing Rune
    [6837] = { ench=6837, item=204972, icon=134422, q=2 }, -- Hissing Rune
    [6838] = { ench=6838, item=204971, icon=134422, q=1 }, -- Hissing Rune

    -- 10.2.0 - Dragonflight
    [7052] = { ench=7052, item=210494, icon=1045108 }, -- Incandescent Essence

    ----------------------------------------------------------------------------
    -- 9.0.1 - Shadowlands
    [6190] = { ench=6190, item=171286, icon=463544  }, -- Embalmer's Oil
    [6188] = { ench=6188, item=171285, icon=463543  }, -- Shadowcore Oil
    [6200] = { ench=6200, item=171437, icon=3528422 }, -- Shaded Sharpening Stone
    [6198] = { ench=6198, item=171436, icon=3528424 }, -- Porous Sharpening Stone
    [6201] = { ench=6201, item=171439, icon=3528423 }, -- Shaded Weightstone
    [6199] = { ench=6199, item=171438, icon=3528425 }, -- Porous Weightstone
}

-------------------------------------------------------------------------------
--- Reverse Lookup: item ID -> enchant data
--- Built at load time from RCC.db.wenchants.
-------------------------------------------------------------------------------

RCC.db.wenchants_items = {}
for _, v in pairs(RCC.db.wenchants) do
    RCC.db.wenchants_items[v.item] = v
end
