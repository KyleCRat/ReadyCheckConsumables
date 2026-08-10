local _, RCC = ...

RCC.DisplayReason = RCC.DisplayReason or {
    READY_CHECK     = "readyCheck",
    INSTANCE_ENTRY  = "instanceEntry",
    CAULDRON_PICKUP = "cauldronPickup",
    BREAK_TIMER     = "breakTimer",
    FEAST_DROP      = "feastDrop",
    CAULDRON_DROP   = "cauldronDrop",
    MANUAL_OPEN     = "manualOpen",
}

RCC.DisplaySurface = RCC.DisplaySurface or {
    CONSUMABLE_FRAME = "consumableFrame",
    RAID_FRAME       = "raidFrame",
}

RCC.DisplayContext = RCC.DisplayContext or {}
RCC.ContextualVisibility = RCC.ContextualVisibility or {}

local Context = RCC.DisplayContext
local Reason = RCC.DisplayReason
local Visibility = RCC.ContextualVisibility

local PRIMARY_REASON_ORDER = {
    Reason.READY_CHECK,
    Reason.BREAK_TIMER,
    Reason.CAULDRON_PICKUP,
    Reason.INSTANCE_ENTRY,
    Reason.FEAST_DROP,
    Reason.CAULDRON_DROP,
    Reason.MANUAL_OPEN,
}

local function updatePrimaryReason(context)
    context.primaryReason = nil

    for i = 1, #PRIMARY_REASON_ORDER do
        local reason = PRIMARY_REASON_ORDER[i]

        if context.activeReasons[reason] then
            context.primaryReason = reason

            return
        end
    end
end

local function getSourceKey(reason, sourceKey)
    return sourceKey or reason
end

local function getOrCreateReasonSources(context, reason)
    local sources = context.activeSources[reason]

    if not sources then
        sources = {}
        context.activeSources[reason] = sources
    end

    return sources
end

local function reasonHasSources(sources)
    if not sources then return false end

    return next(sources) ~= nil
end

function Context.Create(surface)
    return {
        surface           = surface,
        activeReasons     = {},
        activeSources     = {},
        autoOpenedSources = {},
        primaryReason     = nil,
    }
end

function Context.Activate(context, reason, sourceKey)
    if not context or not reason then return false end

    local sources = getOrCreateReasonSources(context, reason)
    local source = getSourceKey(reason, sourceKey)

    if sources[source] then
        return false
    end

    sources[source] = true
    context.activeReasons[reason] = true
    updatePrimaryReason(context)

    return true
end

function Context.Deactivate(context, reason, sourceKey)
    if not context or not reason or not context.activeReasons[reason] then
        return false
    end

    if sourceKey == nil then
        context.activeReasons[reason] = nil
        context.activeSources[reason] = nil
        updatePrimaryReason(context)

        return true
    end

    local sources = context.activeSources[reason]

    if not sources or not sources[sourceKey] then
        return false
    end

    sources[sourceKey] = nil

    if not reasonHasSources(sources) then
        context.activeReasons[reason] = nil
        context.activeSources[reason] = nil
        updatePrimaryReason(context)
    end

    return true
end

function Context.ResetReason(context, reason)
    if not context or not reason then return end

    Context.Deactivate(context, reason)
    context.autoOpenedSources[reason] = nil
end

function Context.Clear(context)
    if not context then return end

    wipe(context.activeReasons)
    wipe(context.activeSources)
    wipe(context.autoOpenedSources)
    context.primaryReason = nil
end

function Context.IsActive(context, reason)
    return context
        and context.activeReasons[reason] == true
        or false
end

function Context.HasAny(context)
    return context and next(context.activeReasons) ~= nil or false
end

function Context.GetPrimaryReason(context)
    return context and context.primaryReason
end

function Context.ShouldAutoOpen(context, reason, sourceKey)
    if not context or not reason then return false end

    local sources = context.autoOpenedSources[reason]
    local source = getSourceKey(reason, sourceKey)

    return not sources or sources[source] ~= true
end

function Context.MarkAutoOpened(context, reason, sourceKey)
    if not context or not reason then return end

    local sources = context.autoOpenedSources[reason]

    if not sources then
        sources = {}
        context.autoOpenedSources[reason] = sources
    end

    sources[getSourceKey(reason, sourceKey)] = true
end

local function isGloballyEnabled(definition)
    return not definition.settingKey
        or RCC.GetSetting(definition.settingKey) == true
end

local function isApplicable(definition, context, state)
    if state and state.applicable == false then
        return false
    end

    local policy = definition.visibility

    if policy and policy.IsApplicable then
        return policy.IsApplicable(context, state, definition) == true
    end

    return true
end

function Visibility.GetReasonDefault(definition, reason)
    if not definition or not reason then
        return false
    end

    local policy = definition.visibility
    local reasons = policy and policy.reasons

    return reasons and reasons[reason] == true or false
end

function Visibility.IsReasonAllowed(definition, context, reason)
    if not definition or not context or not reason then
        return false
    end

    local defaultAllowed = Visibility.GetReasonDefault(definition, reason)

    return RCC.GetContextualVisibility(
        context.surface,
        definition.key,
        reason,
        defaultAllowed
    ) == true
end

function Visibility.IsVisible(definition, context, state)
    if not definition
        or not context
        or not isGloballyEnabled(definition)
        or not isApplicable(definition, context, state)
    then
        return false
    end

    for reason in pairs(context.activeReasons) do
        if Visibility.IsReasonAllowed(definition, context, reason) then
            return true
        end
    end

    return false
end
