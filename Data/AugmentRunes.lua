local _, RCC = ...

RCC.db = RCC.db or {}

--------------------------------------------------------------------------------
--- Augment Rune Spell IDs
--- Maps spell ID -> data for detecting augment rune auras.
--- Higher xpac = more current expansion.
--------------------------------------------------------------------------------

RCC.db.augmentBuffIDs = {}
RCC.db.currentAugmentXpac = 0

--------------------------------------------------------------------------------
--- Augment Rune Item IDs
--- Maps item ID -> { xpac, priority, unlimited } for bag scanning.
--- Higher xpac wins. Within same xpac, higher priority wins.
--- Unlimited runes are not consumed on use.
--------------------------------------------------------------------------------

-- TODO: Review selector logic, but I'm pretty sure these are correct.
--
-- Select highest xpac, highest priority, unless unlimited is favored in settings
-- then select highest xpac highest priority unlimited over higher xpac unlimited.

RCC.db.augmentItemIDs = {}

RCC.Data = RCC.Data or {}

local function updateCurrentAugmentXpac(data)
    local xpac = data and data.xpac

    if xpac and xpac > RCC.db.currentAugmentXpac then
        RCC.db.currentAugmentXpac = xpac
    end
end

function RCC.Data.AddAugmentBuffs(buffIDs)
    if not buffIDs then return end

    for spellID, data in pairs(buffIDs) do
        RCC.db.augmentBuffIDs[spellID] = data
        updateCurrentAugmentXpac(data)
    end
end

function RCC.Data.AddAugmentItems(itemIDs)
    if not itemIDs then return end

    for itemID, data in pairs(itemIDs) do
        RCC.db.augmentItemIDs[itemID] = data
    end
end
