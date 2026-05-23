local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Gem Item IDs
--- Stored for future use. Not currently used by the addon.
--- Organized by gem color, then stat prefix.
--- Base gems are uncommon, Flawless gems are rare.
--- Expansion files append their rows so the rest of the addon can keep reading
--- one combined gem table.
--------------------------------------------------------------------------------

RCC.db.gemItemIDs = {}

RCC.Data = RCC.Data or {}

function RCC.Data.AddGemItems(gemItems)
    if not gemItems then return end

    for gemKey, stats in pairs(gemItems) do
        RCC.db.gemItemIDs[gemKey] = stats
    end
end
