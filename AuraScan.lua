local _, RCC = ...

RCC.HelpfulAuraScan = RCC.HelpfulAuraScan or {}

local AuraScan = RCC.HelpfulAuraScan
local F = RCC.F
local neverSecretSpellIDs = {}

-- Cache base spell policies once per login/reload, never in SavedVariables.
-- A false entry is deliberately not treated as AlwaysSecret: it also covers
-- contextually secret spells, whose current policy must be checked at query time.
function AuraScan.CacheSpellSecrecy(spellIDs)
    for _, spellID in ipairs(spellIDs) do
        if neverSecretSpellIDs[spellID] == nil then
            local secrecy = C_Secrets.GetSpellAuraSecrecy(spellID)

            neverSecretSpellIDs[spellID] = not issecretvalue(secrecy)
                and secrecy == Enum.SecrecyLevel.NeverSecret
        end
    end
end

local function isPublicTrue(value)
    return not issecretvalue(value) and value == true
end

local function canQueryUnit(unit)
    if issecretvalue(unit) or type(unit) ~= "string" then
        return false
    end

    -- Both APIs can return nil for an inaccessible unit, not just a missing
    -- aura. Do not turn offline, out-of-phase, or off-map members into failures.
    if not isPublicTrue(UnitIsConnected(unit))
        or not isPublicTrue(UnitIsVisible(unit))
    then
        return false
    end

    local phaseReason = UnitPhaseReason(unit)

    return not issecretvalue(phaseReason) and phaseReason == nil
end

local function createPublicAura(aura)
    if issecretvalue(aura) or type(aura) ~= "table" then
        return nil
    end

    local spellID = F.GetPublicAuraField(aura, "spellId")

    if not F.IsSafeNumber(spellID) then
        return nil
    end

    return {
        auraInstanceID = F.GetPublicAuraField(aura, "auraInstanceID"),
        duration = F.GetPublicAuraField(aura, "duration"),
        expirationTime = F.GetPublicAuraField(aura, "expirationTime"),
        icon = F.GetPublicAuraField(aura, "icon"),
        name = F.GetPublicAuraField(aura, "name"),
        spellID = spellID,
    }
end

-- Full-scan contract:
-- complete: reached the terminating nil without access/query/invalid-data errors.
-- available: complete AND every aura could be identified by a public spell ID.
-- Readable matches remain valid even if either flag is false. Secret auras are
-- skipped, not classified. Only CanConfirmMissing may use complete on its own,
-- and only for an exhaustive set of known NeverSecret spell IDs. Food's generic
-- icon detection and whole-roster chat reports still require available.
function AuraScan.ForEachAura(unit, callback)
    local result = {
        available = false,
        complete = false,
    }

    if not canQueryUnit(unit) or C_Secrets.ShouldAurasBeSecret() then
        return result
    end

    local allIdentified = true

    for index = 1, RCC.MAX_AURAS do
        local succeeded, rawAura = pcall(
            C_UnitAuras.GetAuraDataByIndex,
            unit,
            index,
            "HELPFUL"
        )

        if not succeeded then
            return result
        end

        if issecretvalue(rawAura) then
            allIdentified = false
        elseif rawAura == nil then
            result.complete = true
            result.available = allIdentified

            return result
        elseif type(rawAura) ~= "table" then
            return result
        elseif issecretvalue(rawAura.spellId) then
            allIdentified = false
        else
            local aura = createPublicAura(rawAura)

            if not aura then
                return result
            end

            callback(aura)
        end
    end

    -- Hitting the bound without a terminating nil cannot establish absence.
    return result
end

function AuraScan.CanConfirmMissing(scan, spellIDs)
    if scan.available then
        return true
    end

    if not scan.complete or #spellIDs == 0 then
        return false
    end

    for _, spellID in ipairs(spellIDs) do
        if neverSecretSpellIDs[spellID] ~= true then
            return false
        end
    end

    return true
end

function AuraScan.ScanUnit(unit, now)
    local auras = {}
    local result = AuraScan.ForEachAura(unit, function(aura)
        if now then
            aura.remaining = F.GetAuraRemaining(
                aura.expirationTime,
                now
            )
        end

        auras[#auras + 1] = aura
    end)

    result.auras = auras

    return result
end

-- Single-spell query contract:
-- available + aura: a readable match was found.
-- available without aura: the query confirmed this spell is absent.
-- unavailable: absence cannot be established. A nil for a currently secret
-- spell proves nothing, even when general restrictions are off. NeverSecret
-- spells remain queryable under general restrictions; errors and unexpectedly
-- secret results still leave the result unavailable.
function AuraScan.FindBySpellID(unit, spellID)
    local result = { available = false }

    if not F.IsSafeNumber(spellID) then
        return result
    end

    if not canQueryUnit(unit) then
        return result
    end

    local canQuerySpell = neverSecretSpellIDs[spellID] == true

    if not canQuerySpell then
        local secret = C_Secrets.ShouldSpellAuraBeSecret(spellID)

        canQuerySpell = not issecretvalue(secret) and secret == false
    end

    if not canQuerySpell then
        return result
    end

    local succeeded, rawAura = pcall(
        C_UnitAuras.GetUnitAuraBySpellID,
        unit,
        spellID
    )

    if not succeeded or issecretvalue(rawAura) then
        return result
    end

    if rawAura == nil then
        result.available = true

        return result
    end

    local aura = createPublicAura(rawAura)

    if not aura or aura.spellID ~= spellID then
        return result
    end

    result.available = true
    result.aura = aura

    return result
end

-- Search alternative IDs in order, returning the first readable match, not
-- merely the first available query. A match wins even after an unavailable
-- alternative; without a match, every alternative must be confirmed absent
-- before the combined result can be available. An empty list is unavailable.
function AuraScan.FindFirstBySpellIDs(unit, spellIDs)
    local result = { available = false }

    if #spellIDs == 0 then
        return result
    end

    local allQueryable = true

    for _, spellID in ipairs(spellIDs) do
        local queryResult = AuraScan.FindBySpellID(unit, spellID)

        if queryResult.aura then
            return queryResult
        end

        if not queryResult.available then
            allQueryable = false
        end
    end

    result.available = allQueryable

    return result
end
