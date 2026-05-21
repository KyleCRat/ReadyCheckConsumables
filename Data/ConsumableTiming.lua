local _, RCC = ...

RCC.ConsumableTiming = RCC.ConsumableTiming or {}

local F = RCC.F
local Timing = RCC.ConsumableTiming

local DEFAULT_EXPIRE_WARN_SECONDS = 60 * 10
local DUNGEON_EXPIRE_WARN_SECONDS = 60 * 30
local DUNGEON_INSTANCE_TYPE = "party"

local function isDungeonInstance()
    local _, instanceType = GetInstanceInfo()

    return instanceType == DUNGEON_INSTANCE_TYPE
end

local function getExpireWarnSeconds()
    if isDungeonInstance() then
        return DUNGEON_EXPIRE_WARN_SECONDS
    end

    return DEFAULT_EXPIRE_WARN_SECONDS
end

function Timing.IsExpiringSoon(remaining)
    if not F.IsSafeNumber(remaining) then
        return false
    end

    if remaining <= 0 then
        return false
    end

    return remaining <= getExpireWarnSeconds()
end
