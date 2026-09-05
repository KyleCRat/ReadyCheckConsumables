local _, RCC = ...

RCC.ConsumableState = RCC.ConsumableState or {}

local State = RCC.ConsumableState
local F = RCC.F

RCC.ConsumableActionKind = RCC.ConsumableActionKind or {
    ITEM = "item",
    SPELL = "spell",
}

local ActionKind = RCC.ConsumableActionKind

State.READY_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Ready"
State.NOT_READY_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-NotReady"
State.UNKNOWN_ATLAS = "UI-LFG-PendingMark"

local AURA_SCAN_UNAVAILABLE_TEXT =
    "RCC was unable to see this buff information."

State.DEFAULTS = {
    applicable = true,
    statusTexture = State.NOT_READY_TEXTURE,
    statusTextureDesaturated = false,
    showStatusTexture = true,
    desaturated = true,
    countText = "",
    countTextIsBad = false,
    detailText = "",
    detailTextIsBad = false,
    hasConsumableBuff = false,
    glow = false,
    suppressGlow = false,
}

function State.Create(fields)
    local state = {}

    if fields then
        for key, value in pairs(fields) do
            state[key] = value
        end
    end

    return state
end

function State.Normalize(state)
    local normalized = {}

    for key, value in pairs(State.DEFAULTS) do
        normalized[key] = value
    end

    if state then
        for key, value in pairs(state) do
            normalized[key] = value
        end
    end

    return normalized
end

function State.SetUnavailable(state, text)
    if state and text then
        state.unavailable = { text = text }
    end
end

function State.SetHoverState(state, hoverState)
    if state and hoverState then
        state.hoverState = hoverState
    end
end

function State.SetHoverUnavailable(state, text, fields)
    if not state or not text then return end

    local hoverState = State.Create(fields)

    State.SetUnavailable(hoverState, text)
    State.SetHoverState(state, hoverState)
end

function State.GetUnavailableText(state, hoverActive)
    if not state then return end

    if hoverActive and state.hoverState then
        local unavailable = state.hoverState.unavailable
        local hoverText = unavailable and unavailable.text

        if hoverText then
            return hoverText
        end
    end

    return state.unavailable and state.unavailable.text
end

function State.GetClickHintItemID(state)
    if not state then return end

    return state.clickHintItemID
        or (state.action and state.action.itemID)
end

function State.GetClickHintSpellID(state)
    if not state then return end

    return state.clickHintSpellID
        or (state.action and state.action.spellID)
end

function State.IsApplicable(state)
    local applicable = state and state.applicable

    if applicable == nil then
        applicable = State.DEFAULTS.applicable
    end

    return applicable == true
end

function State.GetAuraScanUnavailableText(state)
    return state and state.auraScanUnavailableText
end

function State.HasConsumableBuff(state)
    local value = state and state.hasConsumableBuff

    if value == nil then
        value = State.DEFAULTS.hasConsumableBuff
    end

    return value == true
end

function State.IsGlowSuppressed(state)
    return state and state.suppressGlow == true
end

function State.GetIcon(state, defaultIcon, hoverActive)
    local icon = state and state.icon

    if hoverActive
        and state
        and state.hoverState
        and state.hoverState.icon
    then
        icon = state.hoverState.icon
    end

    return icon or defaultIcon
end

function State.CreateItemAction(itemID, options)
    if not itemID then return end

    options = options or {}

    return {
        kind = ActionKind.ITEM,
        itemID = itemID,
        targetSlot = options.targetSlot,
        available = options.available,
        preferenceKey = options.preferenceKey,
        selectionOnly = options.selectionOnly == true,
    }
end

function State.CreateSpellAction(spellID, options)
    if not spellID then return end

    options = options or {}

    return {
        kind = ActionKind.SPELL,
        spellID = spellID,
        spellName = options.spellName,
        available = options.available,
        preferenceKey = options.preferenceKey,
    }
end

function State.CreateItemChoice(candidate, options)
    if not candidate or not candidate.itemID then return end

    options = options or {}

    return State.Create({
        icon = candidate.icon,
        desaturated = false,
        countText = options.countText or tostring(candidate.count or 0),
        tooltipItemID = candidate.itemID,
        qualityItemID = candidate.itemID,
        clickHintItemID = candidate.itemID,
        suppressGlow = options.suppressGlow == true,
        action = State.CreateItemAction(candidate.itemID, options),
    })
end

function State.CreateItemFlyoutChoices(candidates, selectedItemID, options)
    if not candidates then return end

    options = options or {}

    if not options.includeSingleChoice and #candidates <= 1 then
        return
    end

    local choices = {}

    for i = 1, #candidates do
        local candidate = candidates[i]

        if candidate.itemID ~= selectedItemID then
            local choiceOptions = {
                targetSlot = options.targetSlot,
                available = options.available,
                preferenceKey = options.preferenceKey,
                selectionOnly = options.selectionOnly,
                suppressGlow = options.suppressGlow,
            }

            if options.getCountText then
                choiceOptions.countText = options.getCountText(candidate)
            else
                choiceOptions.countText = options.countText
            end

            local choice = State.CreateItemChoice(candidate, choiceOptions)

            if choice then
                choices[#choices + 1] = choice
            end
        end
    end

    if #choices > 0 then
        return choices
    end
end

function State.ApplyActiveAura(state, auraState)
    if not state or not auraState or not auraState.active then return end

    state.statusTexture = State.READY_TEXTURE
    state.hasConsumableBuff = true
    state.desaturated = false

    if auraState.icon then
        state.icon = auraState.icon
    end

    if auraState.remaining then
        state.detailText = F.FormatDuration(auraState.remaining)
    end

    if auraState.timeIsBad ~= nil then
        state.detailTextIsBad = auraState.timeIsBad
    end

    if auraState.auraInstanceID then
        state.tooltipAuraID = auraState.auraInstanceID
    end
end

function State.ApplyAuraScanAvailability(state, scanAvailable)
    if not state or scanAvailable == true then return end

    state.statusAtlas = State.UNKNOWN_ATLAS
    state.statusTextureDesaturated = true
    state.desaturated = true
    state.glow = false
    state.suppressGlow = true
    state.auraScanUnavailableText = AURA_SCAN_UNAVAILABLE_TEXT
end

-- Secure actions and flyout contents cannot be rebound in combat. Keep their
-- identifying visuals aligned with the prepared action while allowing public
-- aura/status fields to continue updating.
function State.MergeCombatVisual(prepared, live)
    if not prepared then
        return live
    end

    local merged = State.Normalize(live)
    local frozenFields = {
        "action",
        "flyoutChoices",
        "icon",
        "hoverState",
        "tooltipItemID",
        "tooltipSpellID",
        "qualityItemID",
        "clickHintItemID",
        "clickHintSpellID",
        "countText",
    }

    for i = 1, #frozenFields do
        local key = frozenFields[i]

        merged[key] = prepared[key]
    end

    return merged
end
