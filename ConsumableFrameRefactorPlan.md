# Consumable Frame Refactor Plan

## Goal

Reduce `ConsumablesFrame.lua` from a large all-in-one implementation into a
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

`ConsumablesFrame.lua` currently owns too many responsibilities at once:

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

Phase 1 should stay mostly inside `ConsumablesFrame.lua`. The goal is to reduce
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
