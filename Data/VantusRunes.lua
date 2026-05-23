local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Vantus Rune Buff Spell IDs
--- Maps spell ID -> truthy marker for detecting active vantus rune auras.
--- The buff name contains "Vantus Rune: <Boss Name>".
--------------------------------------------------------------------------------

RCC.db.vantusBuffIDs = {}

--------------------------------------------------------------------------------
--- Vantus Rune Item IDs by Raid Instance
--- Keyed by WoW instance ID (GetInstanceInfo 8th return).
--- Each array is ordered highest quality first so the update function can stop
--- at the first item found in bags.
--------------------------------------------------------------------------------

RCC.db.vantusItemsByRaid = {}

RCC.Data = RCC.Data or {}

function RCC.Data.AddVantusBuffs(buffIDs)
    if not buffIDs then return end

    for spellID, value in pairs(buffIDs) do
        RCC.db.vantusBuffIDs[spellID] = value
    end
end

function RCC.Data.AddVantusItemsByRaid(itemsByRaid)
    if not itemsByRaid then return end

    for instanceID, itemIDs in pairs(itemsByRaid) do
        RCC.db.vantusItemsByRaid[instanceID] = itemIDs
    end
end
