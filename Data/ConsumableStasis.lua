local _, RCC = ...

RCC.db = RCC.db or {}
RCC.Data = RCC.Data or {}

--------------------------------------------------------------------------------
--- Consumable Stasis Item IDs
--- Expansion files append their items in priority order.
--------------------------------------------------------------------------------

RCC.db.consumableStasisItemIDs = {}

function RCC.Data.AddConsumableStasisItems(itemIDs)
    if not itemIDs then return end

    for i = 1, #itemIDs do
        RCC.db.consumableStasisItemIDs[
            #RCC.db.consumableStasisItemIDs + 1
        ] = itemIDs[i]
    end
end
