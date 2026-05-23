local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Permanent Enchantments
--- Stored for future use. Not currently used by the addon.
--- Maps enchant group name -> enchant ID -> { item, icon, q }.
--- Group names keep the data readable. Detection code can map groups to one or
--- more inventory slot IDs later.
--- Expansion files append rows so the rest of the addon can keep reading one
--- combined enchant table.
--------------------------------------------------------------------------------

RCC.db.enchantIDs = {}

RCC.Data = RCC.Data or {}

function RCC.Data.AddEnchantItems(groupEnchantData)
    if not groupEnchantData then return end

    for groupName, enchantDataByID in pairs(groupEnchantData) do
        RCC.db.enchantIDs[groupName] = RCC.db.enchantIDs[groupName] or {}

        for enchantID, enchantData in pairs(enchantDataByID) do
            RCC.db.enchantIDs[groupName][enchantID] = enchantData
        end
    end
end
