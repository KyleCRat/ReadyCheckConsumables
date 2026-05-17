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

## Phase 3: Stabilize Boundaries For Future Features

Phase 3 should not add new visible features. The goal is to turn the extracted
modules into clearer state, selection, and rendering boundaries so future work
does not re-couple the consumable frame.

### Phase 3 Goals

- Preserve current in-game behavior.
- Keep the coordinator as orchestration only.
- Keep secure frame mutation centralized and combat-guarded.
- Make consumable modules produce normalized state instead of directly owning
  every raw frame mutation.
- Make item and bag selection reusable, including enough structure to support
  multiple candidates later.
- Make raid-buff status reusable without depending on raid-frame column code.
- Remove dormant or obsolete coordinator code.

### Step 1: Remove Dormant Armor Kit Logic

Remove the inactive armor-kit update path from `ConsumableCoordinator.lua`.

The coordinator should not keep unused consumable-specific logic, especially
logic that references a `buttons.kit` shape that is not currently part of the
active frame. If armor kits are expected to return later, move the code into a
small dormant module or capture the idea in `TODO.md` instead of keeping it in
the coordinator.

Acceptance target:

- `ConsumableCoordinator.lua` only imports helpers it actively uses.
- No inactive armor-kit update function remains in the coordinator.
- No visible behavior changes.

### Step 2: Introduce A Button State Model

Add a normalized state shape for consumable button updates. Consumable modules
should describe what they want shown and used; the button/render layer should
apply that state to the actual frame fields.

Example target shape:

```lua
{
    showInLayout = true,
    statusTexture = READY_CHECK_READY_TEXTURE,
    icon = iconID,
    desaturated = false,
    countText = "3",
    timeText = "5m",
    tooltipItemID = itemID,
    tooltipSpellID = spellID,
    tooltipAuraID = auraInstanceID,
    outOfItemsText = nil,
    glow = true,
    action = {
        type = "itemMacro",
        itemID = itemID,
        targetSlot = nil,
    },
}
```

The exact table can change during implementation, but it should make these
concepts explicit:

- Layout availability.
- Display state.
- Tooltip identity.
- Glow state.
- Secure click action.
- Missing-item overlay text.

This is the main cleanup needed before stacked buttons. The current modules
often write directly to fields such as `tooltipItemID`, `usableItemID`,
`clickHintItemID`, `outOfItemsText`, count text, glow, and secure actions.
Those writes should move behind one state application boundary.

### Step 3: Add A Renderer For Button State

Add a renderer layer in `ConsumableFrameButtons.lua` or a new
`ConsumableFrameRenderer.lua`.

The renderer should own the raw frame mutations:

- Status texture.
- Icon texture and desaturation.
- Count text.
- Timer text.
- Tooltip fields.
- Out-of-items overlay fields.
- Glow application.
- Secure action dispatch through `ConsumableFrameActions.lua`.
- Click enable/disable behavior.

Consumable modules should stop calling glow helpers, secure action helpers, and
raw frame setters directly where a returned state can express the same thing.
The secure action helper should still centralize combat guards.

Acceptance target:

- At least the simple consumable modules return or build state that is applied
  by the renderer.
- Direct button mutation is reduced to the renderer and button construction
  code.
- Combat guards still protect secure frame mutation.

### Step 4: Extract Shared Candidate Collection

Extract reusable bag and item candidate helpers for consumables that scan an
ordered list and choose an available item.

Current modules repeat the same broad pattern:

- Walk a data table or ordered item list.
- Check count in bags.
- Pick one preferred candidate.
- Set icon, count, tooltip, and action from that candidate.

Target helper responsibilities:

- Collect available item candidates.
- Preserve data-table order or accept a ranking callback.
- Return the selected candidate for current single-button behavior.
- Preserve the full candidate list for future stacked choice buttons.

Potential helper shapes:

```lua
function Items.CollectAvailable(itemIDs)
    -- returns { { itemID = itemID, count = count, icon = iconID }, ... }
end

function Items.SelectFirstAvailable(itemIDs)
    -- returns candidate or nil
end

function Items.SelectBest(candidates, rankFn)
    -- returns candidate or nil
end
```

Do not add stacked buttons in this phase. The point is to stop each consumable
from having its own slightly different bag-scan implementation.

### Step 5: Normalize Aura-Derived Consumable Status

Keep aura scanning separate from rendering. `ConsumableFrameAuras.lua` should
remain responsible for safe aura reads and secret-value handling, but the
per-consumable modules should receive ordinary state that is easy to render.

Phase 3 cleanup should look for repeated local logic such as:

- "active buff with icon and remaining time".
- "expiring soon".
- "currently eating or drinking".
- "missing buff but usable item exists".

Where the pattern is shared, move it into small helpers that produce normalized
button state. Avoid forcing every consumable into one generic implementation;
food, flask, augment, Vantus, and weapon enchants still have different rules.

### Step 6: Extract Reusable Raid-Buff Status Logic

Move the aura-matching logic currently embedded in raid-frame columns into a
shared raid-buff status module. The raid frame should use that shared module,
and the consumable frame can later use the same module for a raid-buff icon.

Target responsibilities:

- Load raid-buff definitions from `data/RaidBuffs.lua`.
- Match equivalent buff spell IDs.
- Return status for a unit without requiring raid-frame column state.
- Keep the raid-frame rendering code focused on columns and display.

This is a cleanup prerequisite for the future consumable-frame raid-buff
indicator. The feature should not be implemented in Phase 3.

### Step 7: Move Consumable Frame Event Ingress Out Of The Root Addon File

Move consumable-frame lifecycle and event ingress from the root addon file into
a focused controller module, such as `ConsumableFrameController.lua` or
`ConsumableFrameEvents.lua`.

The root file should delegate high-level addon events instead of owning the
details of:

- Ready-check entry.
- `/rcc test` entry.
- Instance-open entry.
- Minimum show timing.
- Hide behavior.
- `UNIT_AURA` refreshes.
- `UNIT_INVENTORY_CHANGED` refreshes.
- Combat start hide behavior.

Preserve the current product rule:

- Do not show in combat.
- Hide on combat start.
- Do not reopen automatically after combat.

### Step 8: Normalize Data Shapes Where It Reduces Coupling

Clean up data structures that are currently hard to share safely.

Candidate cleanup:

- Convert positional raid-buff definitions into named fields if it makes the
  shared raid-buff status module easier to read.
- Centralize item icon lookup so modules do not mix different icon APIs without
  a reason.
- Keep weapon-enchant spell data in the weapon-enchant database with explicit
  fields such as `spellID`, not implicit negative item IDs or duplicated lookup
  tables.

This step should remain behavior-preserving. Data reshaping is only worth doing
when it removes coupling or avoids repeated interpretation logic.

### Step 9: Consider A Dedicated Action Descriptor

If the renderer still needs to know too much about individual consumables,
introduce a small action descriptor model.

Example:

```lua
{ type = "itemMacro", itemID = itemID, targetSlot = targetSlot }
{ type = "weaponItem", itemID = itemID }
{ type = "spell", spellName = spellName }
{ type = "cancelAura", spellName = spellName }
```

The consumable module would return the desired action, and
`ConsumableFrameActions.lua` would be the only module that knows how to apply it
to secure buttons.

### Phase 3 Acceptance Checks

Run the Phase 2 checks after each boundary cleanup:

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
- Shaman weapon enchant spells still take priority over items when known and no
  item enchant is currently overriding them.
- Main-hand and offhand weapon enchant caches remain independent.

## After Refactor

These items should wait until Phase 3 has created cleaner state, candidate, and
rendering boundaries.

### Stacked Consumable Choice Buttons

Show multiple available choices for categories where picking one item for the
player is too limiting, such as:

- Food.
- Weapon enchants.
- Vantus runes.
- Potions, if multiple tracked options become useful.

Implementation notes:

- Secure choice buttons must be preallocated out of combat.
- The normal category button can keep showing the best/default choice.
- Additional choices should come from the candidate lists produced by Phase 3
  item helpers.
- Weapon enchant choices need to respect main-hand and offhand eligibility.
- The UI should not dynamically create protected click buttons during combat.

### Consumable-Frame Raid-Buff Indicator

Add a consumable-frame icon for missing raid buffs.

Implementation notes:

- Reuse the shared raid-buff status module from Phase 3.
- Do not copy raid-frame column internals into the consumable frame.
- Decide whether the icon represents "any missing raid buff" or a selectable
  stack of missing raid buffs after the shared status model exists.

### Rogue Poison Reminders

Investigate Rogue poison support as a separate class-reminder path.

Current testing with poisons applied returned:

```text
false nil nil nil false nil nil nil
```

That means retail Rogue poisons should not be treated as weapon-enchant table
rows unless later testing proves another reliable weapon-enchant signal exists.
This likely needs aura, known-spell, or class-specific reminder logic instead.

### Paladin Lightsmith Weapon Enchant Follow-Up

Verify Paladin Lightsmith rite behavior in game when a test character is
available.

Known test dumps:

```text
Rite of Sanctification: true 1580941 0 7143 false nil nil nil
Rite of Adjuration:     true 3592051 0 7144 false nil nil nil
```

The weapon-enchant data can keep commented reference entries until the behavior
is verified on a Paladin that can use the relevant hero talents.

### Configurable Expiration Severity

Add a shared idea of "bad soon" timing for consumables and show soon-to-expire
timers in red.

Implementation notes:

- Dungeon and raid thresholds may need to differ.
- Flask, food, weapon enchants, and raid buffs should not each invent their own
  hardcoded threshold.
- The Phase 3 button state model should carry severity instead of each module
  directly choosing final text color.

### Raid-Frame Weapon Enchant Identity Broadcast

After the consumable-frame refactor, fix raid-frame weapon oil sharing so it can
represent spell-based weapon enchants as well as item-based enchants.

Implementation notes:

- Broadcast enchant identity using the applied enchant ID, not only an item ID.
- Resolve item or spell display data from the shared weapon-enchant database.
- This should support Shaman and Paladin spell enchants without depending on
  consumable-frame cache behavior.
