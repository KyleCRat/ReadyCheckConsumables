local _, RCC = ...
local WeaponEnchant = {}
RCC.ConsumablePresenters.WeaponEnchant = WeaponEnchant
local State = RCC.ConsumableState
local OUT_OF_ITEMS = "No Weapon Enchant Items found in Bags"
local OUT_OF_SELECTED_ITEM = "Selected Weapon Enchant Item not found in Bags"
local STATUS_UNAVAILABLE =
    "RCC can't confirm whether this weapon enchant is missing because its "
    .. "information is unavailable"

function WeaponEnchant.Present(model)
    local selected = model.selection
    local state = State.Create({ applicable = selected.applicable })

    if not selected.applicable then return state end

    local active = selected.active

    if model.hasEnchant then
        state.statusIcon = State.READY_ICON
        state.hasConsumableBuff = true
        state.desaturated = false
        state.icon = selected.activeIcon
        state.detailText = model.remaining and RCC.F.FormatDuration(model.remaining) or ""
        state.detailTextIsBad = model.expiringSoon

        if active then
            state.tooltipItemID = active.item
            state.tooltipSpellID = not active.item and active.spellID or nil
        end
    end

    state.action = selected.action
    local needsEnchant = not model.hasEnchant or model.expiringSoon

    if selected.kind == "spell" then
        state.icon = selected.icon
        state.tooltipSpellID = selected.spellEnchant.spellID
        state.clickHintSpellID = selected.spellEnchant.spellID
        state.countText = ""
        state.glow = needsEnchant
    else
        local candidate = selected.candidate

        if candidate then
            if not active then
                state.icon = selected.icon
            end

            state.countText = tostring(candidate.count)
            State.SetItemQuality(state, candidate)
            state.clickHintItemID = candidate.itemID
            state.tooltipItemID = state.tooltipItemID or candidate.itemID
            state.glow = candidate.count > 0 and needsEnchant

            if selected.unavailable then
                if model.hasEnchant then
                    State.SetHoverUnavailable(state, OUT_OF_SELECTED_ITEM)
                else
                    State.SetUnavailable(state, OUT_OF_SELECTED_ITEM)
                end
            end
        elseif not model.hasEnchant then
            State.SetUnavailable(state, OUT_OF_ITEMS)
        end
    end

    State.ApplyAuraScanAvailability(state, model.available, STATUS_UNAVAILABLE)

    return state
end

function WeaponEnchant.Choices(selected)
    if not selected.applicable then return end

    local choices = {}

    if selected.kind ~= "spell" then
        -- An item primary offers known spell alternatives, excluding the active
        -- spell. A spell primary offers only the alternative inventory items.
        for _, spell in ipairs(selected.spells) do
            if spell.data ~= selected.active and spell.action then
                choices[#choices + 1] = {
                    icon = spell.icon,
                    desaturated = false,
                    countText = "",
                    tooltipSpellID = spell.data.spellID,
                    clickHintSpellID = spell.data.spellID,
                    action = spell.action,
                }
            end
        end
    end

    local candidate = selected.candidate

    -- Preserve the existing no-primary-item behavior.
    if selected.kind == "item" and not candidate then return end

    local itemChoices = State.CreateItemFlyoutChoices(
        selected.candidates,
        candidate and candidate.itemID,
        {
            targetSlot = selected.slotID,
            available = true,
            preferenceKey = selected.preferenceKey,
            includeSingleChoice = selected.kind == "spell" or selected.unavailable,
        }
    )

    for _, choice in ipairs(itemChoices or {}) do
        choices[#choices + 1] = choice
    end

    if #choices > 0 then return choices end
end
