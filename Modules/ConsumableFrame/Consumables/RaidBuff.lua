local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.RaidBuff = RCC.Consumables.RaidBuff or {}

local RaidBuff = RCC.Consumables.RaidBuff

local ButtonState = RCC.ConsumableFrameButtonState
local F = RCC.F
local RaidBuffStatus = RCC.RaidBuffStatus
local Renderer = RCC.ConsumableFrameRenderer
local Timing = RCC.ConsumableTiming

local ActionType = RCC.ConsumableActionType

local UNAVAILABLE_SPELL = "Raid buff spell unavailable"

local function getPlayerRaidBuffInfo()
    local _, class = UnitClass("player")

    return RaidBuffStatus.GetInfoByProviderClass(class)
end

local function shouldCheckUnit(unit, online)
    return unit
        and online
        and not UnitIsDeadOrGhost(unit)
end

local function getGroupStatus(raidBuffIndex)
    local missingCount = 0
    local minRemaining
    local now = GetTime()

    F.ForEachActiveRosterMember(function(name, unit, subgroup, class, online)
        if shouldCheckUnit(unit, online) then
            local data = RaidBuffStatus.GetUnitStatus(unit, raidBuffIndex, now)

            if RaidBuffStatus.IsMissing(data) then
                missingCount = missingCount + 1
            elseif F.IsSafeNumber(data.time) and data.time > 0 then
                if not minRemaining or data.time < minRemaining then
                    minRemaining = data.time
                end
            end
        end
    end)

    return missingCount, minRemaining
end

function RaidBuff.Update(button)
    local info = getPlayerRaidBuffInfo()

    if not info then
        Renderer.Apply(button, ButtonState.Create({ showInLayout = false }))

        return
    end

    local missingCount, minRemaining = getGroupStatus(info.index)
    local hasMissing = missingCount > 0
    local buttonState = ButtonState.Create({
        showInLayout = true,
        icon = info.iconID,
        tooltipSpellID = info.spellID,
        clickHintSpellID = info.spellID,
        detailText = minRemaining and F.FormatDuration(minRemaining) or "",
        detailTextIsBad = Timing.IsExpiringSoon(minRemaining),
        countText = hasMissing and tostring(missingCount) or "",
        countTextIsBad = hasMissing,
        glow = info.spellID ~= nil
            and (hasMissing or Timing.IsExpiringSoon(minRemaining)),
    })

    if info.spellID then
        buttonState.action = {
            type = ActionType.SPELL,
            spellID = info.spellID,
            available = true,
        }
    elseif hasMissing then
        ButtonState.SetUnavailable(buttonState, UNAVAILABLE_SPELL)
    end

    if not hasMissing then
        buttonState.statusTexture = ButtonState.READY_TEXTURE
        buttonState.hasConsumableBuff = true
        buttonState.desaturated = false
    end

    Renderer.Apply(button, buttonState)
end
