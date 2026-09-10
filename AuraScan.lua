local _, RCC = ...

RCC.HelpfulAuraScan = RCC.HelpfulAuraScan or {}

local AuraScan = RCC.HelpfulAuraScan
local F = RCC.F

function AuraScan.ScanUnit(unit, now)
    local result = {
        available = false,
    }
    local auras = {}
    local scanAvailable = F.ForEachHelpfulAura(unit, function(aura)
        if now then
            aura.remaining = F.GetAuraRemaining(
                aura.expirationTime,
                now
            )
        end

        auras[#auras + 1] = aura
    end)

    -- Readable matches survive an incomplete scan. Only a complete scan can
    -- establish that an unmatched buff is missing (or support a full report).
    result.available = scanAvailable
    result.auras = auras

    return result
end
