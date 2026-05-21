local _, RCC = ...

RCC.RaidBuffStatus = RCC.RaidBuffStatus or {}

local Status = RCC.RaidBuffStatus
local F = RCC.F

local GetSpellInfo = C_Spell.GetSpellInfo

local FALLBACK_SPELL_ICON = 134400 -- INV_Misc_QuestionMark

local function getDefinition(index)
    local defs = RCC.db.raidBuffDefs

    return defs and defs[index]
end

local function getAuraSpellID(aura)
    if not aura then return end

    return aura.spellId or aura.spellID
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
        altSpellID = def.altSpellID,
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
        has = false,
        auraID = nil,
        time = nil,
    }
end

function Status.AuraMatches(index, aura)
    local spellID = getAuraSpellID(aura)

    if not spellID or issecretvalue(spellID) then
        return false
    end

    local def = getDefinition(index)

    if not def then return false end

    local primarySpellID = def.spellID
    local altSpellID = def.altSpellID
    local equivalentSpellIDs = def.equivalentSpellIDs

    return spellID == primarySpellID
           or (altSpellID and spellID == altSpellID)
           or (equivalentSpellIDs and equivalentSpellIDs[spellID])
end

function Status.CollectAura(data, aura, index, remaining)
    if not data or data.has then return end
    if not Status.AuraMatches(index, aura) then return end

    data.has = true
    if F.IsSafeNumber(remaining) then
        data.time = remaining
    end

    RCC.F.StoreAuraID(data, aura)
end

function Status.IsMissing(data)
    return not data or not data.has
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

    F.ForEachHelpfulAura(unit, function(aura, spellID)
        if spellID then
            local remaining = now and F.GetAuraRemaining(
                aura.expirationTime,
                now
            )

            for index = 1, count do
                Status.CollectAura(statuses[index], aura, index, remaining)
            end
        end
    end)

    return statuses
end

function Status.GetUnitStatus(unit, index, now)
    local data = Status.CreateData()

    if not unit or not index then
        return data
    end

    F.ForEachHelpfulAura(unit, function(aura, spellID)
        if spellID then
            local remaining = now and F.GetAuraRemaining(
                aura.expirationTime,
                now
            )

            Status.CollectAura(data, aura, index, remaining)

            if data.has then
                return true
            end
        end
    end)

    return data
end
