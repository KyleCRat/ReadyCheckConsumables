local _, RCC = ...

RCC.RaidBuffStatus = RCC.RaidBuffStatus or {}

local Status = RCC.RaidBuffStatus

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

local function storeAuraID(data, aura)
    local auraID = aura.auraInstanceID

    if auraID and not issecretvalue(auraID) then
        data.auraID = auraID
    else
        data.auraID = true
    end
end

function Status.GetCount()
    local defs = RCC.db.raidBuffDefs

    return defs and #defs or 0
end

function Status.GetInfo(index)
    local def = getDefinition(index)

    if not def then return end

    local spellID = def[3]
    local spellInfo = spellID and GetSpellInfo(spellID)

    return {
        index = index,
        label = def[1],
        providerClass = def[2],
        spellID = spellID,
        altSpellID = def[4],
        equivalentSpellIDs = def[5],
        iconID = spellInfo and spellInfo.iconID or FALLBACK_SPELL_ICON,
    }
end

function Status.CreateData()
    return {
        has = false,
        auraID = nil,
    }
end

function Status.AuraMatches(index, aura)
    local spellID = getAuraSpellID(aura)

    if not spellID or issecretvalue(spellID) then
        return false
    end

    local def = getDefinition(index)

    if not def then return false end

    local primarySpellID = def[3]
    local altSpellID = def[4]
    local equivalentSpellIDs = def[5]

    return spellID == primarySpellID
           or (altSpellID and spellID == altSpellID)
           or (equivalentSpellIDs and equivalentSpellIDs[spellID])
end

function Status.CollectAura(data, aura, index)
    if not data or data.has then return end
    if not Status.AuraMatches(index, aura) then return end

    data.has = true
    storeAuraID(data, aura)
end

function Status.IsMissing(data)
    return not data or not data.has
end

function Status.ScanUnit(unit)
    local statuses = {}
    local count = Status.GetCount()

    for index = 1, count do
        statuses[index] = Status.CreateData()
    end

    if not unit then
        return statuses
    end

    for auraIndex = 1, 60 do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, auraIndex, "HELPFUL")

        if not aura then
            break
        end

        local spellID = getAuraSpellID(aura)

        if spellID and not issecretvalue(spellID) then
            for index = 1, count do
                Status.CollectAura(statuses[index], aura, index)
            end
        end
    end

    return statuses
end

function Status.GetUnitStatus(unit, index)
    local data = Status.CreateData()

    if not unit or not index then
        return data
    end

    for auraIndex = 1, 60 do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, auraIndex, "HELPFUL")

        if not aura then
            break
        end

        local spellID = getAuraSpellID(aura)

        if spellID and not issecretvalue(spellID) then
            Status.CollectAura(data, aura, index)

            if data.has then
                break
            end
        end
    end

    return data
end
