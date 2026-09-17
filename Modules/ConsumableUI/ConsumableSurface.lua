local _, RCC = ...

RCC.ConsumableSurface = RCC.ConsumableSurface or {}

local Surface = RCC.ConsumableSurface
local Binder = RCC.ConsumableActionBinder
local Catalog = RCC.ConsumableCatalog
local Flyout = RCC.ConsumableFlyout
local State = RCC.ConsumableState
local View = RCC.ConsumableButtonView
local Visibility = RCC.ContextualVisibility

local DEFAULT_GEOMETRY = {
    buttonWidth = View.SIZE,
    buttonHeight = View.SIZE,
    gapX = View.SPACING,
    textSize = 16,
    flyoutDirection = "UP",
    durationTextPosition = "TOP",
}

local DEFAULT_VISUAL_OPTIONS = {
    showStackCount = true,
    showDuration = true,
    showStatus = true,
    showProfessionQuality = true,
    showReminderGlow = true,
}

local function copyOptions(source, defaults)
    local result = {}

    for key, value in pairs(defaults) do
        result[key] = value
    end

    if source then
        for key, value in pairs(source) do
            result[key] = value
        end
    end

    return result
end

function Surface.Create(parent, options)
    options = options or {}

    local surface = {
        frame = parent,
        capabilities = options.capabilities
            or Binder.Capabilities.TEMPORARY,
        preparedStates = {},
        appliedRevisions = {},
        categories = {},
        secureDirty = false,
        geometry = copyOptions(options.geometry, DEFAULT_GEOMETRY),
        visualOptions = copyOptions(
            options.visualOptions,
            DEFAULT_VISUAL_OPTIONS
        ),
    }

    surface.flyoutManager = Flyout.CreateManager(
        parent,
        surface.capabilities.allowCombat
    )
    surface.buttons = View.CreateSet(parent, {
        capabilities = surface.capabilities,
        isClickable = options.isClickable,
        clickable = options.clickable,
    })

    local definitions = Catalog.GetDefinitions()
    local previous

    for i = 1, #definitions do
        local button = surface.buttons[definitions[i].key]

        Flyout.AttachPrimary(button, surface.flyoutManager)
        button:ClearAllPoints()

        if previous then
            button:SetPoint(
                "LEFT",
                previous,
                "RIGHT",
                surface.geometry.gapX,
                0
            )
        else
            button:SetPoint("LEFT", parent, "LEFT", 0, 0)
        end

        View.ApplyGeometry(button, surface.geometry)
        Flyout.ApplyGeometry(button, surface.geometry)
        View.ApplyVisualOptions(button, surface.visualOptions, false)
        Flyout.ApplyVisualOptions(button, surface.visualOptions)
        previous = button
    end

    parent.buttons = surface.buttons
    parent.consumableSurface = surface

    return surface
end

function Surface.ApplyGeometry(surface, geometry)
    if not surface or InCombatLockdown() then return false end

    surface.geometry = copyOptions(geometry, DEFAULT_GEOMETRY)
    surface.temporaryLayoutSignature = nil

    local definitions = Catalog.GetDefinitions()

    for i = 1, #definitions do
        local button = surface.buttons[definitions[i].key]

        View.ApplyGeometry(button, surface.geometry)
        Flyout.ApplyGeometry(button, surface.geometry)
    end

    return true
end

function Surface.ApplyVisualOptions(surface, options)
    if not surface then return false end

    surface.visualOptions = copyOptions(options, DEFAULT_VISUAL_OPTIONS)
    surface.visualDirty = true

    local definitions = Catalog.GetDefinitions()

    for i = 1, #definitions do
        local button = surface.buttons[definitions[i].key]

        View.ApplyVisualOptions(button, surface.visualOptions, false)
        Flyout.ApplyVisualOptions(button, surface.visualOptions)
    end

    if surface.latestSnapshot then Surface.ApplySnapshot(surface, surface.latestSnapshot) end
    return true
end

function Surface.ApplySnapshot(surface, snapshot, categories)
    if not surface or not snapshot or not snapshot.states then
        return false
    end

    surface.latestSnapshot = snapshot
    surface.categories = categories or surface.categories

    local inCombat = InCombatLockdown()
    local policyChanged = surface.inCombat ~= inCombat or surface.visualDirty
    -- Secure frames remain allocated, but inactive categories release their
    -- prepared actions/flyouts and visual feedback once out of combat.
    if not inCombat then
        for key in pairs(surface.preparedStates) do
            if not surface.categories[key] then
                local button = surface.buttons[key]
                Binder.Disable(button)
                Flyout.SetChoices(button, nil)
                View.Clear(button)
                button:Hide()
                surface.preparedStates[key] = nil
                surface.appliedRevisions[key] = nil
            end
        end
    end

    for key in pairs(surface.categories) do
        local button = surface.buttons[key]
        local state = snapshot.states[key]
        local revisions = snapshot.revisions[key]
        local applied = surface.appliedRevisions[key] or {}
        local visualState = state

        if inCombat and surface.capabilities.allowCombat then
            visualState = State.MergeCombatVisual(
                surface.preparedStates[key],
                state
            )
        end

        if policyChanged or applied.visual ~= revisions.visual then
            View.ApplyVisual(button, visualState)
        end

        if not inCombat then
            if applied.interaction ~= revisions.interaction then
                Binder.Bind(button, state.action, surface.capabilities)
                Flyout.SetChoices(button, state.flyoutChoices)
            end
            surface.preparedStates[key] = state
            applied.interaction = revisions.interaction
        end
        applied.visual = revisions.visual
        surface.appliedRevisions[key] = applied
    end

    surface.secureDirty = inCombat
    surface.inCombat = inCombat
    surface.visualDirty = false

    return true
end

function Surface.ReconcileSecure(surface)
    if not surface or InCombatLockdown() then return false end
    RCC.ConsumableStateController.PrepareOutOfCombat()
    if not surface.latestSnapshot then return false end

    surface.secureDirty = false

    return Surface.ApplySnapshot(surface, surface.latestSnapshot)
end

function Surface.ApplyTemporaryLayout(surface, context)
    if not surface or InCombatLockdown() then return false end

    local definitions = Catalog.GetDefinitions()
    local geometry = surface.geometry or DEFAULT_GEOMETRY
    local buttonWidth = math.max(
        1,
        tonumber(geometry.buttonWidth) or View.SIZE
    )
    local buttonHeight = math.max(
        1,
        tonumber(geometry.buttonHeight) or View.SIZE
    )
    local gapX = math.max(
        0,
        tonumber(geometry.gapX) or View.SPACING
    )
    local previous
    local visibleCount = 0
    local shown = {}
    local signature = { tostring(buttonWidth), tostring(buttonHeight), tostring(gapX) }

    for i = 1, #definitions do
        local definition = definitions[i]
        shown[definition.key] = surface.categories[definition.key] == true and Visibility.IsVisible(
            definition, context, surface.buttons[definition.key].consumableState
        )
        if shown[definition.key] then signature[#signature + 1] = definition.key end
    end
    signature = table.concat(signature, "|")
    if signature == surface.temporaryLayoutSignature then return true end
    surface.temporaryLayoutSignature = signature

    for i = 1, #definitions do
        local definition = definitions[i]
        local button = surface.buttons[definition.key]
        local shouldShow = shown[definition.key]

        button:ClearAllPoints()

        if shouldShow then
            if previous then
                button:SetPoint(
                    "LEFT",
                    previous,
                    "RIGHT",
                    gapX,
                    0
                )
            else
                button:SetPoint("LEFT", surface.frame, "LEFT", 0, 0)
            end

            button:Show()
            previous = button
            visibleCount = visibleCount + 1
        else
            Flyout.Hide(button)
            button:Hide()
        end
    end

    surface.frame:SetSize(
        View.GetWidth(visibleCount, buttonWidth, gapX),
        buttonHeight
    )

    return true
end

function Surface.HideFlyouts(surface)
    return surface and Flyout.HideAll(surface.buttons)
end
