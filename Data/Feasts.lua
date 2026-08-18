local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Feast Reference Data
--- Item IDs remain available for future item-based features. Only confirmed
--- placement spell IDs are valid feast-drop detection signals.
--------------------------------------------------------------------------------

RCC.db.feastItemIDs = {}
RCC.db.feastPlacementSpellIDs = {}

RCC.Data = RCC.Data or {}

function RCC.Data.AddFeastItems(itemIDs)
    if not itemIDs then return end

    for i = 1, #itemIDs do
        RCC.db.feastItemIDs[#RCC.db.feastItemIDs + 1] = itemIDs[i]
    end
end

function RCC.Data.AddFeastPlacementSpells(spellIDs)
    if not spellIDs then return end

    for i = 1, #spellIDs do
        RCC.db.feastPlacementSpellIDs[spellIDs[i]] = true
    end
end
