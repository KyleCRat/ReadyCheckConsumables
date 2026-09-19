local _, RCC = ...

RCC.ConsumableState = RCC.ConsumableState or {}

local State = RCC.ConsumableState
local F = RCC.F

RCC.ConsumableActionKind = RCC.ConsumableActionKind or {
    ITEM = "item",
    SPELL = "spell",
    SPELL_SEQUENCE = "spellSequence",
}

local ActionKind = RCC.ConsumableActionKind

State.READY_ICON = RCC.UI.StatusIcons.READY
State.NOT_READY_ICON = RCC.UI.StatusIcons.NOT_READY
State.UNKNOWN_ICON = RCC.UI.StatusIcons.UNKNOWN

local AURA_SCAN_UNAVAILABLE_TEXT =
    "RCC can't confirm whether this buff is missing because some aura "
    .. "information is secret or unavailable"

local COMBAT_PREPARED_FIELDS = {
    "action",
    "preference",
    "summaryCapacity",
    "flyoutChoices",
    "icon",
    "hoverState",
    "tooltipItemID",
    "tooltipSpellID",
    "qualityItemID",
    "qualityAtlas",
    "qualityResolved",
    "clickHintItemID",
    "clickHintSpellID",
    "countText",
}

State.DEFAULTS = {
    applicable = true,
    statusIcon = State.NOT_READY_ICON,
    statusTextureDesaturated = false,
    statusTextureAlpha = 1,
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

-- Effect changes are visual, not a reason to rebind secure actions or disturb
-- hover ownership. Choice order and preference targets remain interactions.
function State.SameInteractions(left, right)
    local equal = RCC.ConsumableInputs.Equal

    if not equal(left.action, right.action)
        or not equal(left.preference, right.preference)
        or left.summaryCapacity ~= right.summaryCapacity
    then
        return false
    end

    local leftChoices = left.flyoutChoices or {}
    local rightChoices = right.flyoutChoices or {}

    if #leftChoices ~= #rightChoices then return false end

    for index, choice in ipairs(leftChoices) do
        local other = rightChoices[index]

        if not equal(choice.action, other.action) or not equal(choice.preference, other.preference) then
            return false
        end
    end

    return true
end

-- The runtime fills defaults on newly created presenter states before sharing
-- them. Published primary states, choices, and nested fields are read-only.
function State.Normalize(state)
    if not state.preference and state.action and state.action.preferenceKey then
        local action = state.action
        local choice = action.itemID and RCC.ConsumableChoice.Item(action.itemID)
            or (action.spellID and RCC.ConsumableChoice.Spell(action.spellID))

        if choice then
            state.preference = {
                key = action.preferenceKey,
                capacity = action.preferenceCapacity or 1,
                choice = choice,
            }
        end
    end

    for key, value in pairs(State.DEFAULTS) do
        if state[key] == nil then
            state[key] = value
        end
    end

    return state
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
    local preferenceKey

    if options.preferenceKey and RCC.ConsumablePreferences.CanPrefer(RCC.ConsumableChoice.Item(itemID)) then
        preferenceKey = options.preferenceKey
    end

    return {
        kind = ActionKind.ITEM,
        itemID = itemID,
        targetSlot = options.targetSlot,
        available = options.available,
        preferenceKey = preferenceKey,
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
        preferenceCapacity = options.preferenceCapacity,
    }
end

-- Prepared out of combat. Native castsequence advances per successful cast;
-- observations never skip or advance its cursor.
function State.CreateSpellSequenceAction(candidates, capacity)
    if #candidates == 0 then return end

    if #candidates == 1 then
        if capacity == 1 then return candidates[1].action end

        return State.CreateSpellAction(candidates[1].spellID, { available = true })
    end

    local spells = {}
    local names = {}

    for _, candidate in ipairs(candidates) do
        if not candidate.name then return end

        spells[#spells + 1] = candidate.spellID
        names[#names + 1] = candidate.name
    end

    return {
        kind = ActionKind.SPELL_SEQUENCE,
        spellIDs = spells,
        spellNames = names,
        available = true,
    }
end

-- Capacity selects the summary mode even with no applied effects. Images and
-- readiness describe observations, never preferences or the prepared action.
function State.ApplyEffectSummary(state, model)
    state.summaryCapacity = model.selection.capacity
    state.summaryEffects = model.effects
    state.summaryAvailable = model.available
    state.summaryLabel = model.selection.label
    state.summaryPreferences = model.selection.preferences
    state.hasConsumableBuff = model.complete
    state.desaturated = not model.complete
    state.statusIcon = model.complete and State.READY_ICON or State.NOT_READY_ICON
    state.glow = not model.satisfied

    if model.remaining then
        state.detailText = F.FormatDuration(model.remaining)
        state.detailTextIsBad = model.timeIsBad
    end

    State.ApplyAuraScanAvailability(state, model.available)
end

function State.CreateItemChoice(candidate, options)
    if not candidate or not candidate.itemID then return end

    options = options or {}

    return State.Create({
        icon = candidate.icon,
        cooldown = candidate.cooldown,
        desaturated = false,
        countText = options.countText or tostring(candidate.count or 0),
        tooltipItemID = candidate.itemID,
        qualityItemID = candidate.itemID,
        qualityAtlas = candidate.qualityAtlas,
        qualityResolved = candidate.metadataLoaded,
        clickHintItemID = candidate.itemID,
        suppressGlow = options.suppressGlow == true,
        action = State.CreateItemAction(candidate.itemID, options),
    })
end

function State.SetItemQuality(state, candidate)
    state.qualityItemID = candidate and candidate.itemID
    state.qualityAtlas = candidate and candidate.qualityAtlas
    state.qualityResolved = candidate and candidate.metadataLoaded
end

function State.ApplyItemCooldowns(state, selection)
    local candidate = selection.candidate or selection.defaultCandidate
    state.itemCooldowns = selection.itemCooldowns
    state.cooldown = candidate and state.itemCooldowns[candidate.itemID]
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

    state.statusIcon = State.READY_ICON
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

function State.ApplyAuraScanAvailability(state, scanAvailable, unavailableText)
    -- A readable buff is still confirmed even when another aura made the
    -- overall scan incomplete. Only unresolved statuses become unknown.
    if not state or scanAvailable == true or state.hasConsumableBuff == true then
        return
    end

    state.statusIcon = State.UNKNOWN_ICON
    state.statusTextureDesaturated = false
    state.statusTextureAlpha = 1
    state.desaturated = true
    state.glow = false
    state.suppressGlow = true
    state.auraScanUnavailableText = unavailableText or AURA_SCAN_UNAVAILABLE_TEXT
end

-- Secure actions and flyout contents cannot be rebound in combat. Keep their
-- identifying visuals aligned with the prepared action while allowing public
-- aura/status fields, including applied-effect tooltip details, to update.
function State.MergeCombatVisual(prepared, live)
    if not prepared then
        return live
    end

    -- Only replace top-level fields on this copy. Both source states and their
    -- nested records remain shared and read-only.
    local merged = State.Create(live)

    for i = 1, #COMBAT_PREPARED_FIELDS do
        local key = COMBAT_PREPARED_FIELDS[i]

        merged[key] = prepared[key]
    end

    -- Cooldowns follow the prepared item, even if the last copy was consumed
    -- and selection now points at another item. Food's eating sweep has no
    -- itemCooldowns map and remains a category-wide aura visual.
    local itemID = State.GetClickHintItemID(prepared) or prepared.tooltipItemID

    if live.itemCooldowns then
        merged.cooldown = itemID and live.itemCooldowns[itemID]
    end

    -- Optional item-scoped visuals are distinct from category-wide aura status.
    -- Missing unavailable fields clear old item state. Desaturation is optional:
    -- without it, keep the category-wide buff status unchanged.
    if live.itemVisuals then
        local itemVisual = (itemID and live.itemVisuals[itemID]) or live.missingItemVisual

        if itemVisual then
            merged.unavailable = itemVisual.unavailable

            if itemVisual.desaturated ~= nil then
                merged.desaturated = itemVisual.desaturated
            end
        end
    end

    return merged
end
