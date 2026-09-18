local _, RCC = ...
local RaidBuff = {}
RCC.ConsumablePresenters.RaidBuff = RaidBuff
local State = RCC.ConsumableState

function RaidBuff.Present(model)
    local info = model.info

    if not info then return { applicable = false } end

    local missing = model.available and model.missing > 0
    local state = State.Create({
        icon = info.iconID,
        tooltipSpellID = info.spellID,
        clickHintSpellID = info.spellID,
        detailText = model.available and model.remaining and RCC.F.FormatDuration(model.remaining) or "",
        detailTextIsBad = model.available and model.expiringSoon,
        countText = missing and tostring(model.missing) or "",
        countTextIsBad = missing,
        glow = model.available and info.spellID ~= nil and (missing or model.expiringSoon),
    })

    if info.spellID then
        state.action = model.action
    elseif missing then
        State.SetUnavailable(state, "Raid buff spell unavailable")
    end

    if model.available and not missing then
        state.statusIcon = State.READY_ICON
        state.hasConsumableBuff = true
        state.desaturated = false
    end

    State.ApplyAuraScanAvailability(state, model.available)

    return state
end
