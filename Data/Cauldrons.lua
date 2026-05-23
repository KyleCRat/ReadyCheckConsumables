local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Cauldron Item IDs
--- Stored for future use. Not currently tracked by the addon.
--- Expansion files append their item rows so the rest of the addon can keep
--- reading one combined cauldron table.
--------------------------------------------------------------------------------

RCC.db.cauldronItemIDs = {}

RCC.Data = RCC.Data or {}

function RCC.Data.AddCauldronItems(itemIDs)
    if not itemIDs then return end

    for i = 1, #itemIDs do
        RCC.db.cauldronItemIDs[#RCC.db.cauldronItemIDs + 1] = itemIDs[i]
    end
end
