local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Repair Items
--- Reusable repair devices are preferred while ready. Consumable repair items
--- provide the fallback when the reusable device is missing or on cooldown.
--------------------------------------------------------------------------------

RCC.db.repairItemIDs = {
    49040,  -- Jeeves
    132514, -- Auto-Hammer
}

RCC.db.repairItemData = {
    [49040] = {
        reusable = true,
    },
    [132514] = {
        reusable = false,
    },
}

RCC.db.repairDefaultItemID = 132514
