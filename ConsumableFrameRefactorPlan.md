# Consumable Frame Refactor Plan

## Goal

Reduce `ConsumableCoordinator.lua` from a large all-in-one implementation into a
smaller coordinator with focused helpers for consumable state, secure click
actions, aura scanning, layout, and display rendering.

The refactor should preserve the current product rule: the consumable frame is
a pre-combat assistant. It should not show in combat, and it should not reopen
after combat unless a normal ingress path happens again, such as a ready check,
test command, or instance-open behavior.

## Current Rules To Preserve

- Do not show the consumable frame when `InCombatLockdown()` is true.
- Hide the consumable frame on `PLAYER_REGEN_DISABLED`.
- Do not defer a ready check that starts during combat.
- Do not reopen automatically on `PLAYER_REGEN_ENABLED`.
- Keep secure action button changes guarded by `not InCombatLockdown()`.

## Refactor Items

### Remove Secure Click Restore State

The current secure state driver hides secure click overlays on combat start and
then tries to restore them on combat end using a custom `.IsON` field:

```lua
if self:GetFrameRef("Button"..i).IsON then
    self:GetFrameRef("Button"..i):Show()
end
```

That restore path does not match the current consumable-frame behavior. The
entire frame hides on combat start, and we do not want a post-combat restore
without re-entering through `READY_CHECK`, `/rcc test`, or instance-open logic.

Refactor target:

- Remove `.IsON` as a combat-exit restore flag.
- Remove the `[nocombat]` restore branch from the secure state driver, or remove
  the state driver entirely if the parent-frame combat hide is sufficient.
- Keep click overlay show/hide decisions in the normal out-of-combat update
  path.
- If secure click state still needs to be tracked for layout or rendering, use a
  normal Lua state model first and only mirror into secure attributes when a
  restricted snippet truly needs to read it.

### Clarify Visibility State

The current frame mixes several concepts:

- Consumable category availability, such as offhand weapon or current-raid
  Vantus support.
- User setting visibility, such as `icon_food` or `icon_mhOil`.
- Secure click availability, such as whether a usable item exists in bags.

Refactor target:

- Track category visibility separately from secure click availability.
- Treat settings as an input to final layout visibility.
- Keep the status icon visible when it communicates useful state, even if the
  secure click overlay is disabled because no usable item exists.

## Candidate Module Areas

- Aura scanning and buff-status normalization.
- Bag/item selection.
- Weapon enchant status and click setup.
- Secure click action helpers.
- Layout and icon visibility.
- Tooltip construction.

## Holistic Review

`ConsumableCoordinator.lua` currently owns too many responsibilities at once:

- Top-level frame construction, drag controls, close controls, and positioning.
- Button widget creation for all nine consumable slots.
- Secure click button setup and combat-state-driver behavior.
- Tooltip behavior for status icons and secure click overlays.
- Glow behavior, hover behavior, and out-of-items overlays.
- Aura scanning for food, flask, augment, Vantus, and eating/drinking.
- Bag/item selection for food, flask, augment, weapon enchants, potions,
  healthstones, Vantus, and dormant armor kits.
- Per-consumable rendering, including status textures, count text, timers,
  tooltips, click macros, and glow decisions.
- Layout filtering using a mix of logical availability, settings visibility,
  and current frame shown state.

The largest risk areas are:

- `updateWeaponEnchants()` is the densest function and mixes equipment checks,
  enchant detection, cached item choice, secure item/spell setup, icon choice,
  count rendering, tooltip state, and glow logic.
- `scanPlayerAuras()` both scans data and mutates UI buttons. This makes it
  harder to test or reuse aura state independently from rendering.
- Parent icon visibility is sometimes used as logical availability, such as
  `buttons.oil:IsShown()` and `buttons.vantus:IsShown()` feeding layout.
- Secure click availability is manually paired everywhere with `.IsON`, which
  is now known to be combat-exit restore cruft.
- `InCombatLockdown()` guards are correct but spread through many update
  functions, making it easy for a future edit to miss one.

## Phase 1: Stabilize State And Helpers

Phase 1 should stay mostly inside `ConsumableCoordinator.lua`. The goal is to reduce
fragile state coupling before splitting modules. Avoid moving the large
per-consumable update functions until button state and secure-click behavior are
explicit.

### Phase 1 Goals

- Preserve current behavior.
- Keep the frame hidden in combat and do not add post-combat restore behavior.
- Make icon visibility, click availability, and layout visibility explicit.
- Remove `.IsON` and the secure click restore branch.
- Reduce repeated secure click show/hide code.
- Keep every secure frame mutation guarded by `not InCombatLockdown()`.

### Step 1: Add Button State Helpers

Introduce small local helpers while the code is still in one file:

```lua
local function resetButtonState(button)
    -- status texture, timer, count, tooltip fields, item IDs, out-of-items text
end

local function setButtonShownInLayout(button, shown)
    button.showInLayout = shown == true
end

local function setClickEnabled(button, enabled)
    button.clickEnabled = enabled == true
    if not button.click or InCombatLockdown() then return end

    if enabled then
        button.click:Show()
    else
        button.click:Hide()
    end
end
```

Notes:

- `showInLayout` should describe whether the consumable category belongs in the
  layout before settings are applied.
- `clickEnabled` should describe whether the secure overlay is usable.
- `setClickEnabled()` replaces repeated `click:Show()/Hide()` plus `.IsON`
  assignments.
- `isButtonClickable()` should use `button.clickEnabled` and
  `button.click:IsShown()` instead of `.IsON`.

### Step 2: Remove Combat-Exit Restore Logic

Keep the current rule that ready checks in combat are ignored.

Refactor the secure state driver so it only hides secure click overlays on
combat start, or remove it after confirming the parent frame combat hide is
sufficient for protected children.

Preferred low-risk first change:

```lua
if newstate == "hide" then
    self:GetFrameRef("Button"..i):Hide()
end
```

Then remove every `.IsON` write.

Do not add `PLAYER_REGEN_ENABLED` behavior. A hidden consumable frame should only
come back through `READY_CHECK`, `/rcc test`, or instance-open logic.

### Step 3: Stop Using Parent Visibility As Availability

Replace layout checks like:

```lua
[i_mh_oil] = buttons.oil:IsShown()
[i_oh_oil] = buttons.oiloh:IsShown()
[i_vantus] = buttons.vantus:IsShown()
```

with explicit availability:

```lua
[i_mh_oil] = buttons.oil.showInLayout
[i_oh_oil] = buttons.oiloh.showInLayout
[i_vantus] = buttons.vantus.showInLayout
```

The update functions should set availability, and
`applyIconVisibilityAndLayout()` should be the only place that applies user icon
settings to final parent-frame visibility.

### Step 4: Create Button Metadata

Replace parallel constants with a single descriptor table:

```lua
local BUTTON_DEFS = {
    {
        key = "food",
        index = 1,
        settingKey = "icon_food",
        defaultIcon = RCC.db.food_icon_id,
        clickable = true,
        tooltipAction = "eat",
    },
}
```

This should eventually replace:

- `i_food`, `i_flask`, etc.
- `CLICKABLE_BUTTONS`.
- `TOOLTIP_ACTIONS`.
- `ICON_SETTINGS`.
- `BUTTON_LAYOUT_ORDER`.

For Phase 1, it is acceptable to add the descriptors and migrate one piece at a
time, as long as behavior stays stable.

### Step 5: Decide First Module Boundary

After Steps 1-4, choose the first extraction boundary. The safest candidates
are:

- `ConsumableFrameButtons.lua` for button descriptors, widget creation, reset,
  click helpers, and layout.
- `ConsumableFrameTooltips.lua` for tooltip helpers.
- `ConsumableFrameGlow.lua` for glow helpers.

Do not extract `updateWeaponEnchants()` or `scanPlayerAuras()` first. They have
too much mixed behavior and should be split only after state/render helpers are
stable.

### Phase 1 Acceptance Checks

- `/rcc test` shows the frame out of combat.
- `/rcc hide` hides immediately.
- Starting combat hides the entire consumable frame.
- Ending combat does not reopen the consumable frame.
- A ready check started during combat still does not show the frame.
- Food, flask, augment, Vantus, and weapon-enchant click actions still work out
  of combat.
- Missing items still show the existing red unusable overlay behavior.
- User icon settings still control final layout visibility.

## Phase 2: Split Frame, Coordinator, And Consumable Logic

Phase 2 should separate the remaining responsibilities in
`Modules/ConsumableFrame/ConsumableCoordinator.lua`. After Phase 1, generic button
widgets, tooltips, and glows are already extracted. The remaining file still
does too much:

- It creates the parent consumable frame, anchor, drag handle, close button, and
  positioning behavior.
- It coordinates the update cycle.
- It scans player auras.
- It owns all per-consumable update logic.
- It configures secure click actions directly from each consumable update
  function.

Phase 2 should make `ConsumableCoordinator.lua` stop being an all-purpose module.
The target is a small frame module, a small coordinator module, shared action
and aura helpers, and focused consumable modules.

### Design Direction

The observation that button-specific logic still lives in the coordinator is
correct, but the button widget itself should stay mostly dumb. A frame button
should know how to display fields such as texture, count, timer, tooltip item,
click overlay, and glow. It should not own game rules like "which flask is best"
or "is this offhand enchantable".

The better boundary is a module per consumable type. Each consumable module
should understand how to update its own button state:

- Select the item to display or use.
- Interpret the relevant buff state.
- Set status texture, icon, count, timer, tooltip fields, and out-of-items text.
- Request click action changes through shared secure-action helpers.
- Request glow state through the glow helper.

Weapon enchants should remain one module, not separate main-hand and offhand
modules. Main-hand and offhand share selected item state, cached enchant item,
inventory count, weapon-slot eligibility, spell fallback behavior, and icon
selection.

The observation that frame creation does not belong in the coordinator is also
correct. Frame creation and lifecycle can be extracted cleanly before moving
the high-risk consumable update logic.

### Target File Shape

```text
Modules/ConsumableFrame/
  ConsumableFrame.lua          -- parent frame, anchor, drag, close, Repos, OnHide
  ConsumableCoordinator.lua    -- update coordinator
  ConsumableFrameAuras.lua     -- aura scan and normalized aura state
  ConsumableFrameActions.lua   -- secure click and item-use macro helpers
  ConsumableFrameButtons.lua   -- button descriptors, widgets, reset, layout
  ConsumableFrameTooltips.lua
  ConsumableFrameGlow.lua

  Consumables/
    Food.lua
    Flask.lua
    Healthstone.lua
    WeaponEnchant.lua
    Augment.lua
    DamagePotion.lua
    HealingPotion.lua
    Vantus.lua
```

The final coordinator should ideally read close to:

```lua
function ConsumableCoordinator.Update(frame)
    local buttons = frame.buttons
    local state = Auras.ScanPlayer(GetTime())

    Buttons.ResetAll(buttons)

    Food.Update(buttons.food, state)
    Healthstone.Update(buttons.hs, state)
    Flask.Update(buttons.flask, state)
    WeaponEnchant.Update(buttons, state)
    Augment.Update(buttons.augment, state)
    DamagePotion.Update(buttons.dmgpot, state)
    HealingPotion.Update(buttons.healpot, state)
    Vantus.Update(buttons.vantus, state)

    if not InCombatLockdown() then
        Buttons.ApplyLayout(frame, buttons)
    end

    Buttons.UpdateOutOverlays(buttons)
end
```

The exact names can change, but the intent should stay: the coordinator orders
work and passes shared state; it should not contain consumable-specific item,
buff, or rendering rules.

### Phase 2 Goals

- Preserve current in-game behavior after every step.
- Keep secure button creation preallocated at load time.
- Keep secure `SetAttribute()`, secure `Show()`, and secure `Hide()` guarded by
  `not InCombatLockdown()`.
- Keep the consumable frame hidden in combat.
- Keep the frame from reopening after combat unless a normal ingress path runs.
- Make aura scanning return data instead of mutating buttons directly.
- Move per-consumable update logic out of the coordinator.
- Avoid making the raw button widgets responsible for game rules.
- Keep weapon enchant extraction until the shared patterns are proven.

### Step 1: Extract Frame Construction

Create `Modules/ConsumableFrame/ConsumableFrame.lua`.

Move these responsibilities out of the current coordinator:

- `RCC.consumables = CreateFrame(...)`.
- Default positioning against `ReadyCheckListenerFrame`.
- Anchor frame creation.
- Drag handle creation and scripts.
- Secure close button creation and restricted `_onclick` snippet.
- `Repos()`.
- `OnHide()`.
- ElvUI/ShestakUI re-anchor behavior.

`ConsumableFrame.lua` should call `Buttons.CreateAll(frame)` after the parent
frame exists. It should expose `RCC.consumables` as it does today so existing
ingress paths do not need to change in the same step.

After this step, `ConsumableCoordinator.lua` should no longer create UI. It
should only attach update behavior.

### Step 2: Extract Secure Action Helpers

Create `Modules/ConsumableFrame/ConsumableFrameActions.lua`.

Move shared secure-click behavior into one helper module:

- `GetItemUseMacro(itemID, targetSlot)`.
- Setting macro text for item use.
- Setting direct item/spell/cancelaura attributes for weapon enchants.
- Enabling/disabling click overlays via `Buttons.SetClickEnabled()`.

The helper should centralize combat guards. Consumable modules should not need
to repeat the full secure mutation pattern every time they update a button.

Expected helper shape:

```lua
function Actions.SetItemMacro(button, itemID, targetSlot)
    if not button.click or InCombatLockdown() then return end

    button.click:SetAttribute("macrotext1",
        Actions.GetItemUseMacro(itemID, targetSlot))
    Buttons.SetClickEnabled(button, true)
end
```

Weapon enchant helpers may need separate functions because they use secure
`type = "item"`, `type = "spell"`, and `type = "cancelaura"` paths rather than
only macro text.

### Step 3: Extract Aura Scanning

Create `Modules/ConsumableFrame/ConsumableFrameAuras.lua`.

`scanPlayerAuras()` should stop mutating buttons. It should return a normalized
state table, for example:

```lua
{
    food = {
        active = true,
        icon = foodIcon,
        auraInstanceID = foodAuraID,
        remaining = remaining,
    },
    eating = {
        active = true,
        expiry = eatingExpiry,
        duration = eatingDuration,
        icon = eatingIcon,
    },
    flask = {
        active = true,
        expiringSoon = remaining and remaining <= 600,
        icon = auraData.icon,
        remaining = remaining,
    },
    augment = {
        active = true,
        icon = auraData.icon,
        remaining = remaining,
    },
    vantus = {
        bossName = bossName,
    },
}
```

Keep secret-value checks inside the aura module so callers receive safe,
ordinary Lua values or nils.

### Step 4: Extract Simple Consumables First

Create the `Modules/ConsumableFrame/Consumables/` folder and move the lowest
risk update functions first:

- `Healthstone.lua`
- `DamagePotion.lua`
- `HealingPotion.lua`

These do not currently configure secure click actions and mostly render count,
ready status, icon, and tooltip item. They are good first examples for the
module pattern.

Each module should expose one update function:

```lua
function Healthstone.Update(button, state)
    -- update button display fields
end
```

### Step 5: Extract Food And Flask

Move food and flask next because they follow the same basic pattern:

- Find first available item in bags.
- Use aura state to decide whether the player is already buffed.
- Set icon, count, tooltip, click macro, out-of-items text, and glow.

This step should establish shared item-in-bags helper behavior if useful, but
avoid over-abstracting too early. Food and flask are similar enough to compare,
but not every consumable will fit a single generic model.

### Step 6: Extract Augment And Vantus

Move augment after food/flask because it has a similar click-and-glow shape but
has unique item selection rules:

- `consumables_preferUnlimitedAugment`.
- `data.unlimited == true`.
- Expansion and priority ranking.

Move Vantus after augment because it combines instance-specific availability,
current buff state, click action setup, layout visibility, and out-of-items
state.

### Step 7: Extract Weapon Enchants Last

Move weapon enchants only after the simple modules and shared action helpers
are stable.

`WeaponEnchant.lua` should own both `buttons.oil` and `buttons.oiloh` because
the two buttons share:

- Last selected enchant item cache.
- Main-hand and offhand item checks.
- Offhand enchant eligibility.
- Applied enchant lookup.
- Spell fallback behavior.
- Usable item selection.
- Shared inventory count.
- Main-hand/offhand icon selection.
- Glow rules.

This module can be split internally into small local functions, but it should
remain one public consumable module at first.

### Phase 2 Acceptance Checks

Run the same functional checks after each extraction step:

- `/rcc test` shows the frame out of combat.
- `/rcc hide` hides immediately.
- Starting combat hides the entire consumable frame.
- Ending combat does not reopen the consumable frame.
- A ready check started during combat still does not show the frame.
- Food, flask, augment, Vantus, and weapon-enchant click actions still work out
  of combat.
- Missing items still show the existing red unusable overlay behavior.
- User icon settings still control final layout visibility.
- Hover glow color changes do not restart particle positions.
- Unlimited augment preference still prioritizes the unlimited rune when the
  setting is enabled.
