local _, RCC = ...
RCC.db = RCC.db or {}

-------------------------------------------------------------------------------
--- Raid Buff Spell IDs
-------------------------------------------------------------------------------

local battle_shout                = 6673
local battle_shout_scroll         = 264761
local power_word_fortitude        = 21562
local power_word_fortitude_scroll = 264764
local arcane_intellect            = 1459
local arcane_intellect_scroll     = 264760
local mark_of_the_wild            = 1126
local skyfury                     = 462854
local blessing_of_the_bronze      = 381748

-------------------------------------------------------------------------------
--- Raid Buff Definitions
--- Each entry: { label, provider_class, primary_spell, scroll_spell,
---               [optional alternate_spells table] }
-------------------------------------------------------------------------------

RCC.db.raidBuffDefs = {
    {
        ATTACK_POWER_TOOLTIP or "AP", "WARRIOR",
        battle_shout, battle_shout_scroll,
    },
    {
        SPELL_STAT3_NAME or "Stamina", "PRIEST",
        power_word_fortitude, power_word_fortitude_scroll,
    },
    {
        SPELL_STAT4_NAME or "Int", "MAGE",
        arcane_intellect, arcane_intellect_scroll,
    },
    {
        STAT_VERSATILITY or "Vers", "DRUID",
        mark_of_the_wild,
    },
    {
        STAT_MASTERY or "Mastery", "SHAMAN",
        skyfury,
    },
    {
        TUTORIAL_TITLE2 or "Movement", "EVOKER",
        blessing_of_the_bronze, nil,
        {
            [381758] = true, -- Heroic Leap
            [381732] = true, -- Death's Advance
            [381741] = true, -- Fel Rush
            [381746] = true, -- Tiger Dash / Dash
            [381748] = true, -- Hover
            [381750] = true, -- Shimmer / Blink
            [381749] = true, -- Aspect of the Cheetah
            [381751] = true, -- Chi Torpedo / Roll
            [381752] = true, -- Divine Steed
            [381753] = true, -- Leap of Faith
            [381754] = true, -- Sprint
            [381756] = true, -- Spiritwalker's Grace / Spirit Walk / Gust of Wind
            [381757] = true, -- Demonic Circle: Teleport
        },
    },
}
