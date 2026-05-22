# Consumable Frame State Refactor Plan

## Goal

Define consumable button state once, render from that complete state, and avoid a separate reset path that has to duplicate state defaults.

The key change is not only "store metadata on `button.consumableState`". The stronger target is:

1. consumable modules return partial input state
2. `ConsumableFrameButtonState` normalizes that into a complete view state
3. the renderer applies that complete view state every update
4. stateful visual systems defend themselves with idempotent appliers

This gives us one state contract to update when adding future fields.

## Original Problem

`ConsumableFrameRenderer.Apply` currently applies optional state fields only when they exist, while `ConsumableFrameButtons.ResetState` separately defines what missing fields mean.

That creates two obligations for every state-backed visual:

1. apply the field in the renderer
2. remember to clear or default it in reset

Moving passive metadata to `button.consumableState` helps tooltips and glow, but it does not fully solve this. Visual fields like `detailText`, `countText`, `qualityItemID`, `cooldown`, and `glow` would still need renderer logic plus reset defaults.

The real fix is to remove reset as a second source of state defaults.

## State Model

Use three explicit categories.

### Input State

Partial state built by consumable modules.

Example:

```lua
ButtonState.Create({
    countText = tostring(foodCount),
    tooltipItemID = foodItemID,
    qualityItemID = foodItemID,
    action = {
        type = ActionType.ITEM_MACRO,
        itemID = foodItemID,
    },
})
```

Consumable modules should only describe what is special about the current consumable result.

### View State

Complete normalized state produced by `ConsumableFrameButtonState`.

Example:

```lua
local viewState = ButtonState.Normalize(state)
button.consumableState = viewState
```

The view state contains every supported field with an explicit default. It is the single source of truth for the current rendered button.

### Frame Internals

Actual WoW frame objects and runtime implementation details that cannot live as pure state:

- `button.texture`
- `button.count`
- `button.detailText`
- `button.cooldown`
- `button.click`
- `button.qualityIcon`
- hover/flyout tracking
- secure click attributes
- glow internals and animation phase caches

These are allowed to keep private mutable fields when needed to apply view state safely. They are not semantic consumable state.

If a frame applier needs to remember what it last applied, it should keep that bookkeeping under one clearly named implementation cache:

```lua
button.consumableFrameRenderCache
```

That cache must only contain applied-frame bookkeeping used to avoid repeating stateful UI operations. It must not become a second place to store consumable meaning. If other code needs to know the current consumable result, it should read `button.consumableState`.

## Normalized Defaults

Add defaults to `ConsumableFrameButtonState.lua`.

The exact field list can be adjusted during implementation, but the shape should look like this:

```lua
State.DEFAULTS = {
    showInLayout = true,
    statusTexture = State.NOT_READY_TEXTURE,
    showStatusTexture = true,
    icon = nil,
    hoverState = nil,
    desaturated = true,
    countText = "",
    countTextIsBad = false,
    detailText = "",
    detailTextIsBad = false,
    hasConsumableBuff = false,
    tooltipAuraID = nil,
    tooltipItemID = nil,
    tooltipSpellID = nil,
    clickHintItemID = nil,
    clickHintSpellID = nil,
    qualityItemID = nil,
    unavailable = nil,
    cooldown = nil,
    action = nil,
    glow = false,
    flyoutChoices = nil,
}
```

Add:

```lua
function State.Normalize(state)
```

`Normalize` should copy defaults first, then overlay the input state. It should return a new table so module-owned input state is not mutated unexpectedly.

## Rendering Model

`ConsumableFrameRenderer.Apply` should normalize first, then render from the complete state:

```lua
function Renderer.Apply(button, state)
    if not button then return end

    local viewState = ButtonState.Normalize(state)
    button.consumableState = viewState

    Buttons.ApplyState(button, viewState)
    Actions.Apply(button, viewState.action)
    Glow.Set(button, viewState.glow == true)
    Buttons.SetFlyoutChoices(button, viewState.flyoutChoices)
end
```

The renderer should not call a broad `ResetState` before applying. Defaults in the view state replace reset as the way omitted fields become inactive.

## Idempotent Appliers

Rendering a complete state every update is only safe if appliers are idempotent.

That means each applier accepts desired state and makes the frame match it without unnecessarily restarting animations, recreating frames, reanchoring active UI, or rewriting secure attributes when nothing changed.

This is how we defend against glow position resets and similar visual bugs.

### Glow

Glow is the highest-risk example because restarting `LibCustomGlow` can reset animation position.

The current glow code already has part of the right defense:

```lua
if cache.glowActiveColor == color then return end
```

That prevents restarting the same glow color every render.

The refactor should preserve and tighten that pattern:

- `Glow.Set(button, enabled)` stores desired glow state.
- `resolveGlow(button)` computes the desired glow color or no glow.
- `startButtonGlow(button, color)` returns immediately if the desired color is already active.
- `stopButtonGlow(button)` returns immediately if no glow is active.
- glow animation phase fields remain private implementation caches on the button.

So the renderer can call `Glow.Set` every pass without resetting glow movement.

### Cooldown

Cooldown should be applied through a small idempotent helper.

The helper may cache the last applied `start` and `duration` in the private render cache, for example:

```lua
button.consumableFrameRenderCache.cooldownStart
button.consumableFrameRenderCache.cooldownDuration
```

If the desired cooldown matches the applied cooldown, do nothing. If desired cooldown is nil, clear and hide only if a cooldown is currently applied.

These cache fields are acceptable because they are not semantic addon state. They are only used to avoid repeating stateful frame operations.

### Quality Overlay

`Buttons.SetQualityOverlay(button, itemID)` can also be idempotent.

It can keep the last applied quality item in the private render cache:

```lua
button.consumableFrameRenderCache.qualityItemID
```

If the desired item is unchanged, do nothing. If it changes to nil, hide the overlay. If it changes to a new item, update the atlas.

This keeps `qualityItemID` as clean display state while avoiding unnecessary repeated atlas work.

### Secure Click Actions

Secure click setup is frame state, not pure data. It also has combat-lockdown restrictions.

`Actions.Apply(button, action)` should remain the boundary that translates state into secure button attributes. It should become idempotent where practical:

- cache the last applied action signature on the click frame
- skip rewriting secure attributes when the action did not change
- keep all `SetAttribute`, `Show`, and `Hide` calls guarded by `InCombatLockdown()`
- when no action is desired, disable the click overlay without relying on reset

`button.clickEnabled` can remain a runtime frame flag because it describes the actual click overlay state after secure-frame rules are applied.

### Flyouts

Flyout frames are dynamic UI internals. They should keep owner, hover, open, and hide-token fields on the button.

`Buttons.SetFlyoutChoices(button, choices)` should remain idempotent:

- choice count changes update created flyout buttons
- missing choices hide stale buttons
- active hover/open state is preserved where possible
- no choices means hide flyout

The state field is `flyoutChoices`. The created flyout frames are implementation detail.

## Button Metadata Reads

Tooltips, layout, unavailable overlays, hover icon logic, and glow should read from `button.consumableState`, not copied fields.

Add state reader helpers for shared interpretation:

```lua
State.GetUnavailableText(state, hoverActive)
State.GetClickHintItemID(state)
State.GetClickHintSpellID(state)
State.IsShownInLayout(state)
State.HasConsumableBuff(state)
State.GetIcon(state, defaultIcon, hoverActive)
```

These helpers keep behavior aligned across modules without making each UI file understand every state detail.

## Remove ResetState As State Defaults

`Buttons.ResetState` should not define render defaults after this refactor.

Either remove it from the normal render path, or rename/scope any remaining function to what it actually does, such as:

```lua
Buttons.ClearTransientFrameState(button)
```

That function should only handle frame implementation cleanup that cannot be represented by view state. It should not set default consumable values like:

- empty count text
- empty detail text
- bad text colors
- not-ready texture
- desaturation
- no tooltip
- no quality item
- no glow
- no action

Those defaults belong in `State.DEFAULTS` and should reach the frame through normal rendering.

## Remove usableItemID

Once click hint resolution can read from action state, remove `usableItemID`.

For item actions, click hint text can resolve from:

```lua
state.clickHintItemID or (state.action and state.action.itemID)
```

That removes the context-inappropriate field and lets non-clickable buttons show quality icons without pretending the item is usable.

Keep `qualityItemID` because quality overlay is explicit display intent, independent of clickability.

## Implementation Steps

### Step 1: Normalize Button State

- Add `State.DEFAULTS`.
- Add `State.Normalize`.
- Add state reader helpers.
- Update docs/comments around `State.Create` so omitted fields mean "use defaults".

### Step 2: Render Complete View State

- Update `Renderer.Apply` to normalize first.
- Replace broad `Buttons.ResetState` usage with complete state application.
- Add or update `Buttons.ApplyState(button, state)` for visual fields.
- Ensure text, colors, icon, desaturation, status texture, quality overlay, and cooldown all render from normalized state.

### Step 3: Move Metadata Readers To consumableState

- Update tooltips to read `button.consumableState`.
- Update unavailable text and hover icon resolution to read state.
- Update layout visibility to read normalized state.
- Update glow's consumable-buff check to read normalized state.
- Stop copying passive metadata fields from state to button.

### Step 4: Make Side-Effect Appliers Idempotent

- Preserve glow animation phase and avoid restarting unchanged glow.
- Make cooldown application avoid repeated clear/set calls when unchanged.
- Make quality overlay avoid repeated atlas work when unchanged.
- Make secure action application skip unchanged attribute writes where practical.
- Keep combat-lockdown guards intact.

### Step 5: Remove usableItemID

- Remove `usableItemID` from state creation and consumable modules.
- Resolve item click hint text from `clickHintItemID` or `action.itemID`.
- Keep `qualityItemID` for display-only quality overlays.

## Expected Result

Adding a new render-backed state field should require updating the state contract and the relevant applier, not a separate reset path.

The renderer can safely apply complete view state every update because stateful systems guard their own side effects. Semantic state stays in one normalized table, while private frame caches only exist to make WoW UI operations stable and efficient.
