local _, RCC = ...
local RaidBuff = {}
RCC.ConsumablePresenters.RaidBuff = RaidBuff
local State = RCC.ConsumableState
local STATUS_UNAVAILABLE =
    "RCC can't check this buff for some group members because their buff "
    .. "information is unavailable"

function RaidBuff.Present(model)
    local info = model.info

    if not info then return { applicable = false } end

    local missing = model.missing > 0
    local state = State.Create({
        icon = info.iconID,
        tooltipSpellID = info.spellID,
        clickHintSpellID = info.spellID,
        detailText = model.available and model.remaining and RCC.F.FormatDuration(model.remaining) or "",
        detailTextIsBad = model.available and model.expiringSoon,
        countText = missing and tostring(model.missing) or "",
        countTextIsBad = missing,
        glow = info.spellID ~= nil and (missing or (model.available and model.expiringSoon)),
    })

    if info.spellID then
        state.action = model.action
    elseif missing then
        State.SetUnavailable(state, "Raid buff spell unavailable")
    end

    -- A confirmed missing buff takes priority over an incomplete group check.
    -- Unknown applies only when nobody is confirmed missing and some members
    -- could not be checked; a checkmark requires every eligible member's buff.
    if missing then
        state.statusIcon = State.NOT_READY_ICON
    elseif model.available then
        state.statusIcon = State.READY_ICON
        state.hasConsumableBuff = true
        state.desaturated = false
    else
        State.ApplyAuraScanAvailability(state, model.available, STATUS_UNAVAILABLE)
    end

    return state
end
