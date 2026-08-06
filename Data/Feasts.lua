local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Feast Item and Placement Spell IDs
--- "Hearty" variants are the same food but persist through death.
--- Expansion files append their item and spell rows so the rest of the addon
--- can keep reading one combined feast registry.
--------------------------------------------------------------------------------

RCC.db.feastItemIDs = {}
RCC.db.feastSpellIDs = {}

RCC.Data = RCC.Data or {}

function RCC.Data.AddFeastItems(itemIDs)
    if not itemIDs then return end

    for i = 1, #itemIDs do
        RCC.db.feastItemIDs[#RCC.db.feastItemIDs + 1] = itemIDs[i]
    end
end

function RCC.Data.AddFeastSpells(spellIDs)
    if not spellIDs then return end

    for i = 1, #spellIDs do
        RCC.db.feastSpellIDs[spellIDs[i]] = true
    end
end
