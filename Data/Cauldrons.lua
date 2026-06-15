local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Cauldron Data
--- Expansion files append their rows so the rest of the addon can keep reading
--- one combined cauldron registry.
--------------------------------------------------------------------------------

RCC.CauldronKind = RCC.CauldronKind or {
    FLASK  = "flask",
    POTION = "potion",
}

RCC.db.cauldronItemIDs = {}
RCC.db.cauldronItemData = {}
RCC.db.cauldrons = {}
RCC.db.cauldronKindData = {}
RCC.db.cauldronSpellData = {}
RCC.db.cauldronPickupItemData = {}

RCC.Data = RCC.Data or {}

local function addIndexedItems(itemIDs, orderedIDs, itemData, cauldron)
    if not itemIDs then return end

    for itemIndex = 1, #itemIDs do
        local itemID = itemIDs[itemIndex]

        if orderedIDs then
            orderedIDs[#orderedIDs + 1] = itemID
        end

        itemData[itemID] = cauldron
    end
end

local function addIndexedSpellIDs(cauldron)
    if cauldron.spellID then
        RCC.db.cauldronSpellData[cauldron.spellID] = cauldron
    end

    local spellIDs = cauldron.spellIDs

    if not spellIDs then return end

    for spellIndex = 1, #spellIDs do
        RCC.db.cauldronSpellData[spellIDs[spellIndex]] = cauldron
    end
end

local function addIndexedKind(cauldron)
    if cauldron.kind and not RCC.db.cauldronKindData[cauldron.kind] then
        RCC.db.cauldronKindData[cauldron.kind] = cauldron
    end
end

function RCC.Data.AddCauldrons(cauldrons)
    if not cauldrons then return end

    for cauldronIndex = 1, #cauldrons do
        local cauldron = cauldrons[cauldronIndex]
        local registryIndex = #RCC.db.cauldrons + 1

        cauldron.index = registryIndex
        RCC.db.cauldrons[registryIndex] = cauldron

        addIndexedKind(cauldron)
        addIndexedSpellIDs(cauldron)
        addIndexedItems(
            cauldron.itemIDs,
            RCC.db.cauldronItemIDs,
            RCC.db.cauldronItemData,
            cauldron
        )
        addIndexedItems(
            cauldron.pickupItemIDs,
            nil,
            RCC.db.cauldronPickupItemData,
            cauldron
        )
    end
end
