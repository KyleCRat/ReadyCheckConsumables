local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Class-provided Raid Buff Spell IDs
--------------------------------------------------------------------------------

local battle_shout                = 6673
local power_word_fortitude        = 21562
local arcane_intellect            = 1459
local mark_of_the_wild            = 1126
local skyfury                     = 462854
local blessing_of_the_bronze      = 381748

--------------------------------------------------------------------------------
--- Class-provided Raid Buff Definitions
--- Always loaded, including class-specific variants of the same ability.
--- Secrecy is still checked through Blizzard's API, not assumed from this list.
--- Each entry:
--- {
---     label = display text,
---     providerClass = class token expected in UnitClass/GetRaidRosterInfo,
---     spellID = primary buff spell,
---     equivalentSpellIDs = optional map of class-specific aura spell IDs,
--- }
--------------------------------------------------------------------------------

RCC.db.raidBuffDefs = {
    {
        label = ATTACK_POWER_TOOLTIP or "AP",
        providerClass = "WARRIOR",
        spellID = battle_shout,
    },
    {
        label = SPELL_STAT3_NAME or "Stamina",
        providerClass = "PRIEST",
        spellID = power_word_fortitude,
    },
    {
        label = SPELL_STAT4_NAME or "Int",
        providerClass = "MAGE",
        spellID = arcane_intellect,
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

--------------------------------------------------------------------------------
--- Item-provided Raid Buff Alternatives
--- Maps a primary class buff spell ID to an ordered list of accepted item aura
--- spell IDs. These are applied aura IDs, not inventory item or use-spell IDs.
--- The TOC loads only the current expansion's RaidBuffs.lua after this file.
--- Older expansion files remain in the repository without joining this list.
--------------------------------------------------------------------------------

RCC.db.raidBuffItemAuras = {}

RCC.Data = RCC.Data or {}

function RCC.Data.AddRaidBuffItemAuras(alternatives)
    for classSpellID, spellIDs in pairs(alternatives) do
        local itemAuras = RCC.db.raidBuffItemAuras[classSpellID]

        if not itemAuras then
            itemAuras = {}
            RCC.db.raidBuffItemAuras[classSpellID] = itemAuras
        end

        for _, spellID in ipairs(spellIDs) do
            itemAuras[#itemAuras + 1] = spellID
        end
    end
end
