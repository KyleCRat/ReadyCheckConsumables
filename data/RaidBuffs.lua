local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Raid Buff Spell IDs
--------------------------------------------------------------------------------

local battle_shout                = 6673
local battle_shout_scroll         = 264761
local power_word_fortitude        = 21562
local power_word_fortitude_scroll = 264764
local arcane_intellect            = 1459
local arcane_intellect_scroll     = 264760
local mark_of_the_wild            = 1126
local skyfury                     = 462854
local blessing_of_the_bronze      = 381748

--------------------------------------------------------------------------------
--- Raid Buff Definitions
--- Each entry:
--- {
---     label = display text,
---     providerClass = class token expected in UnitClass/GetRaidRosterInfo,
---     spellID = primary buff spell,
---     altSpellID = optional scroll/equivalent spell,
---     equivalentSpellIDs = optional map of equivalent aura spell IDs,
--- }
--------------------------------------------------------------------------------

RCC.db.raidBuffDefs = {
    {
        label = ATTACK_POWER_TOOLTIP or "AP",
        providerClass = "WARRIOR",
        spellID = battle_shout,
        altSpellID = battle_shout_scroll,
    },
    {
        label = SPELL_STAT3_NAME or "Stamina",
        providerClass = "PRIEST",
        spellID = power_word_fortitude,
        altSpellID = power_word_fortitude_scroll,
    },
    {
        label = SPELL_STAT4_NAME or "Int",
        providerClass = "MAGE",
        spellID = arcane_intellect,
        altSpellID = arcane_intellect_scroll,
    },
    {
        label = STAT_VERSATILITY or "Vers",
        providerClass = "DRUID",
        spellID = mark_of_the_wild,
    },
    {
        label = STAT_MASTERY or "Mastery",
        providerClass = "SHAMAN",
        spellID = skyfury,
    },
    {
        label = TUTORIAL_TITLE2 or "Movement",
        providerClass = "EVOKER",
        spellID = blessing_of_the_bronze,
        equivalentSpellIDs = {
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
