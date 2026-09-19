local _, RCC = ...

-- Each ID is both the cast spell and the buff on the rogue, not the debuff
-- applied to an enemy. Order selects the default when no poison is active.
RCC.db.roguePoisons = {
    lethal = {
        2823,   -- Deadly Poison
        381664, -- Amplifying Poison
        315584, -- Instant Poison
        8679,   -- Wound Poison
    },
    nonLethal = {
        5761,   -- Numbing Poison
        381637, -- Atrophic Poison
        3408,   -- Crippling Poison
    },
}

-- Used only until the known spell's icon metadata is available.
RCC.db.roguePoisonFallbackIconID = 134400 -- INV_Misc_QuestionMark

RCC.db.roguePoisonCapacity = {
    default = 1,
    talentSpellID = 381801, -- Dragon-Tempered Blades
    talented = 2,
}
