local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Feast Item IDs
--- Stored for future use. Not currently used by the addon.
--- "Hearty" variants are the same food but persist through death.
--- Expansion files append their item rows so the rest of the addon can keep
--- reading one combined feast table.
--------------------------------------------------------------------------------

RCC.db.feastItemIDs = {}

RCC.Data = RCC.Data or {}

function RCC.Data.AddFeastItems(itemIDs)
    if not itemIDs then return end

    for i = 1, #itemIDs do
        RCC.db.feastItemIDs[#RCC.db.feastItemIDs + 1] = itemIDs[i]
    end
end
