local _, RCC = ...

RCC.RaidBuffStatus = RCC.RaidBuffStatus or {}

local Status = RCC.RaidBuffStatus
local F = RCC.F
local AuraScan = RCC.HelpfulAuraScan

local GetSpellInfo = C_Spell.GetSpellInfo

local FALLBACK_SPELL_ICON = 134400 -- INV_Misc_QuestionMark
local auraQueries = {}

-- Build the accepted-ID sets once from the same definitions used by full scans.
-- Class spells come first, followed by the loaded expansion's item alternatives.
-- Matching, targeted queries, and secrecy checks all use these same sets.
for index, def in ipairs(RCC.db.raidBuffDefs) do
    local spellIDs = {}
    local seen = {}

    local function addSpellID(spellID)
        if spellID and not seen[spellID] then
            seen[spellID] = true
            spellIDs[#spellIDs + 1] = spellID
        end
    end

    addSpellID(def.spellID)

    local equivalents = {}

    for spellID, enabled in pairs(def.equivalentSpellIDs or {}) do
        if enabled then
            equivalents[#equivalents + 1] = spellID
        end
    end

    table.sort(equivalents)

    for _, spellID in ipairs(equivalents) do
        addSpellID(spellID)
    end

    for _, spellID in ipairs(RCC.db.raidBuffItemAuras[def.spellID] or {}) do
        addSpellID(spellID)
    end

    auraQueries[index] = {
        spellIDs = spellIDs,
        spellIDSet = seen,
    }
end

local function getDefinition(index)
    local defs = RCC.db.raidBuffDefs

    return defs and defs[index]
end

local function getAuraSpellID(aura)
    if not aura then return end

    return aura.spellID
end

function Status.GetCount()
    local defs = RCC.db.raidBuffDefs

    return defs and #defs or 0
end

function Status.GetInfo(index)
    local def = getDefinition(index)

    if not def then return end

    local spellID = def.spellID
    local spellInfo = spellID and GetSpellInfo(spellID)

    return {
        index = index,
        label = def.label,
        providerClass = def.providerClass,
        spellID = spellID,
        equivalentSpellIDs = def.equivalentSpellIDs,
        iconID = spellInfo and spellInfo.iconID or FALLBACK_SPELL_ICON,
    }
end

function Status.GetInfoByProviderClass(class)
    if not class then return end

    for index = 1, Status.GetCount() do
        local info = Status.GetInfo(index)

        if info and info.providerClass == class then
            return info
        end
    end
end

function Status.CreateData()
    return {
        available = false,
        has = false,
        auraID = nil,
        time = nil,
        expirationTime = nil,
    }
end

function Status.AuraMatches(index, aura)
    local spellID = getAuraSpellID(aura)

    if issecretvalue(spellID) or not spellID then
        return false
    end

    local query = auraQueries[index]

    return query ~= nil and query.spellIDSet[spellID] == true
end

function Status.CollectAura(data, aura, index, remaining)
    if not data or data.has then return end
    if not Status.AuraMatches(index, aura) then return end

    data.available = true
    data.has = true
    if F.IsSafeNumber(remaining) then
        data.time = remaining
    end

    if F.IsSafeNumber(aura.expirationTime) and aura.expirationTime > 0 then
        data.expirationTime = aura.expirationTime
    end

    RCC.F.StoreAuraID(data, aura)
end

function Status.IsMissing(data)
    return data and data.available == true and not data.has
end

local function applyTargetedStatus(data, unit, index, now)
    local result = AuraScan.FindFirstBySpellIDs(unit, auraQueries[index].spellIDs)

    data.available = result.available

    if result.aura then
        local remaining = now and F.GetAuraRemaining(result.aura.expirationTime, now)

        Status.CollectAura(data, result.aura, index, remaining)
    end
end

-- Raid-buff availability is category-specific, not the whole scan's flag.
-- Keep readable matches and absence already proven by the scan. Otherwise query
-- this category's accepted IDs directly, using their current secrecy rules.
-- A failed or partial full scan alone never proves absence; every targeted
-- variant must confirm absence unless a readable match is found.
function Status.FinalizeScan(data, scan, index, unit, now)
    data.available = data.has == true
        or AuraScan.CanConfirmMissing(scan, auraQueries[index].spellIDs)

    if not data.available then
        applyTargetedStatus(data, unit, index, now)
    end
end

function Status.GetStatusFromScan(unit, scan, index, now)
    local data = Status.CreateData()

    if not auraQueries[index] then
        return data
    end

    for _, aura in ipairs(scan.auras) do
        local remaining = now and F.GetAuraRemaining(aura.expirationTime, now)

        Status.CollectAura(data, aura, index, remaining)

        if data.has then
            break
        end
    end

    Status.FinalizeScan(data, scan, index, unit, now)

    return data
end

function Status.ScanUnit(unit, now)
    local statuses = {}
    local count = Status.GetCount()

    for index = 1, count do
        statuses[index] = Status.CreateData()
    end

    if not unit then
        return statuses
    end

    local scan = AuraScan.ForEachAura(unit, function(aura)
        local remaining = now and F.GetAuraRemaining(aura.expirationTime, now)

        for index = 1, count do
            Status.CollectAura(statuses[index], aura, index, remaining)
        end
    end)

    for index = 1, count do
        Status.FinalizeScan(statuses[index], scan, index, unit, now)
    end

    return statuses
end

function Status.GetUnitStatus(unit, index, now)
    local data = Status.CreateData()

    if not auraQueries[index] then
        return data
    end

    applyTargetedStatus(data, unit, index, now)

    return data
end

-- Cache Blizzard's base policy each login/reload for the class spells and
-- loaded item alternatives. Targeted lookups still check current secrecy when
-- a spell is not NeverSecret.
local loginFrame = CreateFrame("Frame")

loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")

    for _, query in ipairs(auraQueries) do
        AuraScan.CacheSpellSecrecy(query.spellIDs)
    end
end)
