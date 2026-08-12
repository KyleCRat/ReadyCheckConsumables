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

local function shouldCheckUnit(unit, online)
    return unit
        and online
        and not UnitIsDeadOrGhost(unit)
end

local function getGroupStatus(raidBuffIndex)
    local missingCount = 0
    local minRemaining
    local statusAvailable = true
    local now = GetTime()

    F.ForEachActiveRosterMember(function(name, unit, subgroup, class, online)
        if shouldCheckUnit(unit, online) then
            local data = RaidBuffStatus.GetUnitStatus(unit, raidBuffIndex, now)

            if data.available ~= true then
                statusAvailable = false

                return false
            elseif RaidBuffStatus.IsMissing(data) then
                missingCount = missingCount + 1
            elseif F.IsSafeNumber(data.time) and data.time > 0 then
                if not minRemaining or data.time < minRemaining then
                    minRemaining = data.time
                end
            end
        end
    end)

    return missingCount, minRemaining, statusAvailable
end

function RaidBuff.Update(button)
    local info = RaidBuff.GetPlayerRaidBuffInfo()

    if not info then
        Renderer.Apply(button, ButtonState.Create({ applicable = false }))

        return
    end

    local missingCount, minRemaining, statusAvailable = getGroupStatus(
        info.index
    )
    local hasMissing = statusAvailable and missingCount > 0
    local buttonState = ButtonState.Create({
        icon = info.iconID,
        tooltipSpellID = info.spellID,
        clickHintSpellID = info.spellID,
        detailText = statusAvailable and minRemaining
            and F.FormatDuration(minRemaining)
            or "",
        detailTextIsBad = statusAvailable
            and Timing.IsExpiringSoon(minRemaining),
        countText = hasMissing and tostring(missingCount) or "",
        countTextIsBad = hasMissing,
        glow = statusAvailable
            and info.spellID ~= nil
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

    if statusAvailable and not hasMissing then
        buttonState.statusTexture = ButtonState.READY_TEXTURE
        buttonState.hasConsumableBuff = true
        buttonState.desaturated = false
    end

    ButtonState.ApplyAuraScanAvailability(buttonState, statusAvailable)

    Renderer.Apply(button, buttonState)
end
