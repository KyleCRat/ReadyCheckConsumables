local _, RCC = ...

RCC.ChatReportRoster = RCC.ChatReportRoster or {}
local Roster = RCC.ChatReportRoster

local F = RCC.F

local getRosterInfo = F.GetRosterInfo

function Roster.ForEachMember(callback)
    local maxGroup = F.GetRaidDiffMaxGroup()

    for j = 1, 40 do
        local name, unit, subgroup, class = getRosterInfo(j)

        if not name then
            if not IsInRaid() then
                break
            end
        elseif subgroup <= maxGroup then
            if callback(name, unit, subgroup, class, j) == false then
                break
            end
        end
    end
end

function Roster.ForEachHelpfulAura(unit, callback)
    for i = 1, RCC.MAX_AURAS do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")

        if not aura then
            break
        end

        if not issecretvalue(aura.spellId)
            and callback(aura, aura.spellId) == true
        then
            break
        end
    end
end
