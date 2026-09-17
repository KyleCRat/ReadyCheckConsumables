# Personal Consumable Pipeline

This covers the temporary Consumables Frame, permanent Action Bar, and shared
selectors used by managed macros. Group broadcasts and chat reports retain
their existing contracts. Personal raid-buff observations use targeted queries;
food and the Raid Status Frame still use full helpful-aura scans.

## Ownership

```text
Surface settings/context -> requested categories -> input/event demand
                                                     |
WoW events -> pending source invalidations -> public input snapshots
                                             |
                                  category Select + Observe caches
                                             |
                                      Evaluate(time, context)
                                             |
                                   Present + cached flyout choices
                                             |
                         requested snapshot + per-category revisions
                                             |
                          temporary frame / permanent action bar
```

- `ConsumableCatalog.lua` is the single category/order registry and identifies
  each domain module. Adding a category does not require a controller switch.
- `ConsumableInputs.lua` reads live APIs, normalizes public data, and remembers
  applied item enchants explicitly before dependent selection. It also supplies
  live input adapters to macros independently of UI activity.
- Each category declares its `Inventory` and `Dependencies` beside its pure
  selectors and status rules. `ConsumableSelection.lua` provides mechanical
  candidate construction, not a universal scoring policy.
- `ConsumableDemand.lua` derives source, item-ID, and weapon-slot demand from
  the union of both surfaces' requested categories and the existing domain
  dependencies. It also includes reader prerequisites, such as roster/context
  for group aura observations.
- `ConsumableRuntime.lua` caches selection and observation independently,
  evaluates time/context changes, and publishes read-only normalized state.
- `ConsumableUI/Presenters/` formats domain results. Presenters cannot read
  inventory, scan auras, select a different item, or write preferences.
- `ConsumableStateController.lua` owns pending invalidations, batching, source
  lifetime, consumer publication, and the single shared deadline timer.
- `ConsumableSurface.lua` tracks revisions separately for each surface and
  owns the distinction between desired state and combat-prepared state.

## Category dependencies

All inventory-driven categories also react when relevant item data finishes
loading. Preferences are compared by their individual setting/cache key.

| Category | Selection/action inputs | Status/applicability inputs |
| --- | --- | --- |
| Food | Inventory, food preference | Well Fed/eating observations, warning threshold, time |
| Flask | Inventory, flask preference and family/variant order | Flask observation, warning threshold, time |
| Augment | Inventory, preference, unlimited-rune setting | Augment observation, warning threshold, time |
| Main/off-hand enchant | Inventory, slot preference, equipped weapon/applied enchant, known spells and slot rules | Slot observation, warning threshold, time |
| Raid buff | Player's class-provided buff/spell | Eligible roster members' observations, shortest expiry, warning threshold |
| Healthstone | Inventory charges across supported stones | Presence of a warlock in the active roster |
| Combat potion | Inventory, preference, potion type/family/variant order | Selected-item possession |
| Healing potion | Inventory, preference and list order | Selected-item possession |
| Consumable stasis | Inventory/list order | Possession; no ready/missing status |
| Recuperate | Spell/icon from `Data/Recuperate.lua` | Always applicable; no ready/missing status |
| Inky Black Potion | Inventory | Optional buff observation/time; no ready/missing status |
| Repair | Inventory, reusable priority, cooldowns | Possession/cooldown; no ready/missing status |
| Vantus | Raid instance, inventory, preference | Applied rune/boss; applied rune suppresses action and flyout |

## Refresh contract

Each consumer supplies a category-key set through `GetCategories()`:

- The temporary frame requests enabled categories allowed by its current
  display reasons, only while shown out of combat.
- The Action Bar requests its enabled categories while the module is enabled,
  even when an off-hand-only bar is hidden because the slot is inapplicable.
- Demand is decided **before applicability**, never from the current icon's
  visibility/status. Equipment, roster, and instance changes must still be able
  to make an enabled category applicable again.
- During combat the Action Bar keeps its last prepared category set; secure
  layout/enablement changes take effect after combat. The temporary frame drops
  its demand when it hides.

The controller observes the union once, then supplies each consumer's own set
with `ApplySnapshot(snapshot, categories)`. Disabling a category on one surface
does not remove another surface's demand. Source events are registered only
while needed; item reads are limited to requested inventory IDs, and weapon
reads to requested slots. Group aura/life/range observations and repair cooldown
reads stop when no personal consumer needs those sources. Lifecycle events
remain registered so the pipeline can wake again.

`RefreshDemand()` reconciles settings/display-context changes immediately.
Removed categories lose their runtime cache and deadlines; unused input caches
are dropped. Surfaces release inactive actions/flyouts and clear feedback out
of combat. New demand refreshes live inputs before preparing controls, without
resetting the monotonically increasing revision counter. Ordinary input events
and deadline ticks reuse the resolved demand rather than rereading UI settings.
With no categories requested, ongoing input reads and refresh/deadline work stop.

Invalidations are a union, not an event replay queue. `inventory` can be a full
refresh or a set of item IDs; `groupAuras` can be the full eligible roster or a
set of unit tokens. A full invalidation supersedes narrower ones. The controller
detaches the pending batch before reading/publishing, so new invalidations are
not lost during reentrant callbacks.

Refresh requests use named options rather than positional scope/delay values:

```lua
Controller.Invalidate("playerAuras") -- Full source, normal batching delay
Controller.Invalidate("groupAuras", { scope = { [unit] = true } })
Controller.Invalidate("preferences", { nextFrame = true })
```

`nextFrame` schedules a new batch without the normal 0.2-second delay; it is
still asynchronous. If a batch is already scheduled, the change joins that
batch without changing its timing. `RequestRefresh` uses the same timing option
and reconciles demand before rereading requested sources. `RefreshNow(true)` is
the synchronous fresh-read boundary; it never bypasses category demand to read
disabled categories. Invalidations for unrequested sources are ignored.

Readers replace observations, never append to an old aura result. A readable
match remains confirmed when another aura could not be identified. Unknown is
not missing: the shared aura boundary distinguishes a finished enumeration from
one in which every aura was identifiable, as described below. World/context and
roster identity changes discard the affected observation cache. Group member
aura events refresh that member, not every group member.

### Raid-buff queries and secrecy

`AuraScan.lua` owns live aura queries and public-field normalization for both
acquisition paths. `RaidBuffStatus.lua` builds each buff's accepted spell-ID list
from `Data/RaidBuffs.lua`: primary, optional scroll, and class-specific equivalents.
At `PLAYER_LOGIN`, it asks the aura boundary to cache Blizzard's base secrecy
policy for every accepted ID. The cache lasts only until logout/reload; it is
neither a copied whitelist nor SavedVariables data.

`AuraScan.FindBySpellID(unit, spellID)` owns the single-spell safety checks,
Blizzard lookup, and normalized result. `available = true` means the query could
answer; `aura` is present only when the buff was found. `FindFirstBySpellIDs`
calls that function for each alternative in order and returns the first found
aura, not the first successful-but-empty query. If none is found, any unavailable
alternative keeps the combined result Unknown. An empty list is unavailable.

- The personal Raid Buff button queries only the player's class-provided buff
  with `C_UnitAuras.GetUnitAuraBySpellID`. It stops on a readable matching variant.
  Missing requires readable absence for every accepted variant. Non-NeverSecret
  variants also require a current `ShouldSpellAuraBeSecret` check; a suppressed
  query is Unknown, not a missing buff.
- General aura restrictions do not block targeted queries for NeverSecret IDs.
  Unit visibility, connection, phase, API errors, and secret return values still
  gate what the addon can conclude.
- The existing per-member observation cache, unit-scoped invalidations, and
  expiration deadlines are unchanged. Both personal surfaces share that work.
  When another category already obtained a fresh full player scan, use it if it
  proves presence or absence; otherwise try the targeted query. A blocked full
  scan does not prevent a separate public query from answering the raid-buff check.
- Full scans return `complete` only after reaching the end without a query or
  invalid-data error, and `available` only if every aura was also identifiable.
  Found public matches remain valid regardless of those flags. A finished scan
  containing unidentified secret auras can prove a raid buff missing only if
  **all** its accepted spell IDs are cached as NeverSecret.
- The Raid Status Frame still scans all helpful auras for food and the other
  columns. Its raid-buff columns use the same category-specific absence rule;
  they do not change the whole scan's `available` flag. Unresolved food/flask/
  rune observations remain Unknown, and aura-derived chat reports still require
  a fully available scan for every active online member.

For example, a finished scan with an unidentified cosmetic aura can still show
missing Skyfury when Blizzard marks Skyfury NeverSecret. RCC never needs to know
the cosmetic's spell ID or assume that every secret aura is harmless.

Selection dependencies are distinct from observation/evaluation dependencies.
For example, an aura update can change a flask's status without recounting
inventory, sorting candidates, rebuilding choices, or rebinding secure actions.
Repair cooldown completion and changed weapon enchant observations can change
selection and therefore deliberately take the interaction path.

Duration labels and warning boundaries use cached public expiration timestamps.
One shared timer wakes for the next relevant deadline. Actual expiry rereads
the relevant source before deriving the new status; it does not loop through
retry scans. Repair completion is a deadline even if no new cooldown event fires.

Snapshots are complete for the **currently requested union**, and read-only.
An absent category means unrequested, not Missing or Unknown. Unchanged state
objects are reused;
`visual`, `interaction`, and `applicability` revisions let a surface catch up
even if it did not receive the most recent delta. Opening/re-enabling explicitly
refreshes live inputs. Visual options can repaint cached state without rescanning.

During combat, primary actions and their identifying visuals remain tied to
the last prepared state. Public status/duration visuals can update; glows and
flyouts stay suppressed. Combat end refreshes desired data before rebinding.
No combat-time flyout opening or protected attribute/layout mutation is added.
Repair supplies optional `itemVisuals` keyed by item ID so its cooldown and
availability visuals follow the prepared item, even if another device becomes
the desired primary. `missingItemVisual` covers a prepared item that was consumed.

## Example: a new flask aura

1. With Flask requested, `UNIT_AURA` for the player invalidates `playerAuras`
   and, if Raid Buff is also requested, the player's group observation. The
   controller coalesces the event with other pending changes.
2. The reader obtains one normalized player aura scan. `Flask.Select` does not
   run unless inventory or the flask preference also changed:

   ```lua
   Flask.Dependencies = {
       selection = { "inventory", "preferences.flask" },
       observation = { "playerAuras" },
       evaluation = { "context.warningSeconds" },
       expiration = "playerAuras",
   }
   ```

3. `Flask.Observe(inputs)` finds the registered flask aura. `Flask.Evaluate`
   combines the cached selection with that observation and the current time.
4. `Flask.Present(model)` formats the icon, duration, readiness and tooltip.
   `Flask.Choices(selection)` remains cached because selection did not change.
5. The runtime advances the visual revision. The surface applies the new visual
   state, but unchanged interaction revisions skip `Binder.Bind` and
   `Flyout.SetChoices`. The shared timer handles the next duration/warning change.

## Macros

Macro getters explicitly read the inputs their selector needs and invoke the
same pure `Select` function. They do not borrow a potentially inactive surface's
snapshot. Their own coalescing and combat-deferral scheduler is unchanged.

The UI may preserve an unavailable saved item. Macro policies remain specific
to each category: flask/combat/healing potion getters can choose their existing
available fallback, while food/augment/vantus keep their existing preference
behavior. Applied weapon-enchant preferences are reconciled explicitly before
a macro update, including when both personal surfaces are disabled.

## Extending a category

1. Register its domain in the catalog and its files in the TOC.
2. Declare inventory IDs and selection/observation/evaluation dependencies in
   the domain. Add a new source only for genuinely new input, not a new button.
   Include any reader prerequisites in `ConsumableDemand.lua`, and wire the
   source's conditional event subscriptions in the controller. Existing sources
   need no category-specific controller branch.
   Gameplay IDs belong in `Data/`, including single-spell actions such as
   Recuperate; modules consume that data rather than duplicating IDs.
3. Implement the pure phases it needs. Omitted `Select`/`Observe` phases use an
   empty result; omitted `Evaluate` passes selection and its action through.
4. Format the result in a presenter; build flyout choices from selection only.
   Status-dependent availability belongs in `Evaluate` (see Vantus).
5. Define expiration deadlines and the source to recheck, if applicable.
6. Verify settings, both surfaces, macros, and coupled gameplay data as described
   in `AGENTS.md`. Do not infer enablement from current applicability.

## In-game review checklist

- Demand: disable a category on one surface while keeping it active on the
  other, then disable it on both. Re-enable it or reopen the temporary frame
  after changing items/buffs while it was inactive; actions/status must be fresh.
- Demand scope: try inventory-only buttons, Recuperate alone, and no enabled
  buttons. Re-enable Repair during a cooldown and Raid Buff after roster changes.
  Keep off-hand-only, healthstone-without-warlock, and instance-specific Vantus
  enabled while inapplicable, then make each applicable again.
- Food: missing, eating, fresh Well Fed, warning threshold, expiration, no food
  in bags, and an unavailable saved food choice.
- Flask/augment: active/missing/Unknown, empty saved preference, fleeting-family
  fallback, unlimited preference, duration warning, and expiry without bag changes.
- Weapon enchants: empty/non-enchantable slots, applied oils, known spell
  alternatives and slot restrictions, preference selection, weapon swaps,
  expiration, and off-hand-only Action Bar hide/reopen.
- Raid buff: buff/unbuff one member, death/resurrection, offline/reconnect,
  phase/range changes, subgroup/bench changes, scroll alternatives, and Evoker's
  class-specific equivalents. Repeat with only Raid Buff enabled and with other
  aura categories enabled to cover both targeted queries and player-scan reuse.
- Secret auras: with the Essence of Yu'lon cosmetic active, check present and
  missing Skyfury on both personal surfaces and the Raid Status Frame. Missing
  Skyfury should not be Unknown; unresolved food/flask/rune data still can be.
  Off-map/out-of-phase members stay Unknown rather than becoming missing.
  Repeat public raid-buff checks in combat, and reload with the cosmetic active
  to exercise policy-cache initialization.
- Inventory-only buttons: potion preference/fallback, healthstone charges and
  warlock roster changes, stasis, and Recuperate.
- Repair: ready Jeeves, ready Auto-Hammer fallback, both cooling down, cooldown
  completion with no inventory change, cooldown visuals on flyout choices, and
  prepared-item visuals when the preferred device changes during combat.
- Inky Black Potion: colored optional icon/buff, duration, and no ready/missing mark.
- Vantus: enter/leave a supported raid, apply/remove rune, and action/flyout gating.
- Both personal surfaces: right-click preferences, hide/reopen, layout and visual
  settings, non-square icons, each flyout direction, and movement providers.
- Combat: prepared primary use, closed flyouts, suppressed glows, live status
  and durations, then fresh action/flyout bindings immediately after combat.
- Macros: both personal modules disabled, preference/fallback updates, equipment
  changes, and deferred combat updates.
