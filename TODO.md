# TODO

## Fixes

- Evaluate debouncing consumables frame `UNIT_AURA` updates to roughly once per
  second. Measure whether reduced refresh churn during test/ready-check frames
  is worth the added latency and complexity.
- After one or two releases, consider replacing the legacy `"OIL"` raid-frame
  addon message type with a temp-weapon-enchant-specific message type and
  remove legacy `"OIL"` receive handling. It is currently kept so older RCC
  clients can still read remaining time and item ID from newer clients while
  newer clients can still read older clients.

## Refactor Review (2025-05-18)

### Bugs

- `RaidFrameColumnRenderers.lua:313-325` — `renderIconAuraCell` does not clear
  stale overlay fields (`spellID`, `itemID`, `label`) before setting new ones.
  If a previous render set those fields, tooltips could show wrong data.
  Compare to `renderTimedAuraCell:235-239` which does a full overlay reset.
- `RaidFrameColumnRenderers.lua:262-310` — `renderTempWeaponEnchantCell` has no
  `else` fallback. If `remaining` is an unexpected negative value (not `-1`),
  no branch executes and the cell retains its previous render state.
- `ConsumableFrameButtonState.lua:101` — `CreateItemFlyoutChoices` appends the
  return of `CreateItemChoice` directly to `choices`. If it returns `nil` (a
  candidate lacking `itemID`), this creates a nil hole and `#choices` becomes
  unreliable. Latent — candidates from bag scans always have `itemID` today.
- `Vantus.lua:108` — `if itemID and count > 0 then` is unreachable when
  `bossName` is set, because the `bossName` branch at line 88 returns early.
  When the player has an active Vantus buff AND items in bags, the button gets
  no click action and no flyout. Likely intentional (can't re-apply), but the
  "has items" path is dead code in that case. The `bossName` branch also never
  sets `glow`, relying on reset defaults — inconsistent with all other modules.

### High Priority

- `Vantus.lua:30-66` — `getVantusForCurrentRaid` returns 6 values, combining
  raid lookup, candidate collection, cache resolution, and unavailability
  checking. Violates global coding rule: "Separate concerns into their own
  functions — avoid combining multiple responsibilities into one function that
  returns multiple values."
- `Vantus.lua` — Calls `Renderer.Apply` four times across early-return branches
  (lines 77, 103, 124, 146). Every other consumable module calls it exactly
  once at the end. `glow` is not explicitly set in the `bossName` or
  `itemID and count > 0` branches. Restructure to a single `Renderer.Apply`
  at the end like all other consumable modules.
- `RaidFrameBroadcast.lua:179-441` — All ~15 broadcast methods are inner
  functions inside `Broadcast.Create()`. Each call allocates fresh closures.
  Only called once so no perf issue, but violates project style preference for
  module-scope functions. Same pattern in `RaidFrameTitleBar.lua:76-185` and
  `RaidFrameControls.lua:77-108`.
- `ChatReport.lua:91-426` — Roster loop duplicated across `reportFood`,
  `reportFlasks`, `reportAugments`, `reportBuffs`. Extract a shared
  `forEachRosterMember(maxGroup, callback)` iterator.
- `ChatReport.lua` — 220-char message chunking logic duplicated in three report
  functions. `reportBuffs` doesn't chunk at all and could exceed chat limits
  for large raids. Extract a shared `sendChunked` helper.

### Medium Priority

- `ConsumableFrameGlow.lua:88-118` — `Glow.Set` and `Glow.SetHovered` have
  identical 3-way branching (hovered+shouldUseHoverGlow -> clickable/unavailable
  color, enabled -> base color, else -> stop). Extract a shared
  `resolveAndApplyGlow(button)` to eliminate duplication.
- `ConsumableFrameGlow.lua:22` — `applyButtonGlowPhase` accesses `glow.timer`
  as a table, depending on `LibCustomGlow-1.0` internal implementation detail.
  If the library updates, this silently breaks. Add a guard or comment.
- `ConsumableFrameButtons.lua:96-105` — `BUTTON_LAYOUT_ORDER` copies
  `BUTTON_DEFS` then sorts by `order`, but `BUTTON_DEFS` is already declared in
  order (1-9). The sort is dead work. Either remove it or add a comment
  explaining the intent for future-proofing.
- `ConsumableFrameButtons.lua:44,53` — `settingKey = "icon_mhOil"` and
  `"icon_ohOil"` use stale "Oil" naming after the rename to temp weapon enchant.
  These are SavedVariables keys and can't be casually renamed — add a comment
  explaining why.
- `data/Food.lua` — `RCC.db.feastItemids` uses lowercase `ids`. Every other key
  uses `ItemIDs` (capital I, D). If anything references `feastItemIDs`, it gets
  `nil` silently. Currently unused, but fix casing for consistency.
- `data/Settings.lua:59` / `Healthstone.lua:26` — `healthstone_item_id` uses
  `snake_case`. Every other `RCC.db` key uses `camelCase`. Rename for
  consistency.
- `DamagePotion.lua` / `HealingPotion.lua` — Near-identical files differing
  only in the `RCC.db` key. Consider a shared factory or parameterized function.
- `RaidBuffStatus.lua` / `RaidFrameColumns.lua` — `storeAuraID` helper is
  duplicated between both files. Extract to a shared utility.
- `WeaponEnchant.lua` — `collectWeaponEnchantItemCandidatesInBags()` called
  inside `updateWeaponEnchantSlot`, which runs once per hand. The bag scan is
  identical for both slots — collect once in `WeaponEnchant.Update` and pass it.
- `ConsumableFrameAuras.lua:72` — `ScanPlayer` hard-codes a 60-aura cap. The
  loop already breaks on nil, so the cap is defensive but could silently
  truncate in edge cases. Consider `while true` with break-on-nil, or document
  the 60 limit.

### Low Priority

- `Food.lua:130` — `elseif not displayAuraState` is always true at that point
  (follows `if displayAuraState`). Should be a plain `else`.
- `ConsumableFrameGlow.lua:75`, `ConsumableFrameTooltips.lua:33`,
  `ConsumableFrameButtons.lua:436` — Three files use deferred `RCC.*` lookups
  to break circular module dependencies. None have a comment explaining why.
  Add a brief comment at each site.
- `ConsumableFrameButtons.lua:259` — `getFlyoutButton` creates frames as a side
  effect. Name should be `getOrCreateFlyoutButton` for clarity.
- `ConsumableFrameController.lua:34-38` — `cancelDelay` function name collides
  with `self.cancelDelay` field. Rename the function for clarity.
- `ConsumableFrame.lua:12` — Initial frame width hardcoded to 5 buttons rather
  than using the definition count. Cosmetic — overwritten on first update.
- `ConsumableFrame.lua:70-72` — `UpdateReadyCheckAnchor` checks for ElvUI and
  ShestakUI but has no comment explaining why the anchor fix is needed.
- `RaidFrame.lua:102` — Variable named `readyCount` actually counts all
  responders (ready + not-ready). Rename to `respondedCount`.
- `Buttons.ResetState` (`ConsumableFrameButtons.lua:176`) sets
  `clickEnabled = false` but doesn't hide the click frame directly — relies on
  `Actions.Apply` running afterward. If a module returns early without calling
  `Renderer.Apply`, click frame state could be stale.
- `ConsumableFrameActions.lua:49-53` — `commitPendingCacheAction` uses magic
  strings `"set"` and `"clear"` for action types. Extract to local constants.
- `data/Settings.lua:43` — `RCC.ordered_xpac_ids` is exposed on `RCC` but only
  read locally. Could be a local variable.
- `Augment.lua` — `getCountText` function exists but inline logic in `Update`
  re-implements the same unlimited/count check. Use `getCountText` in both
  places to avoid drift.
- `RaidFrameColumns.lua:151` — `data.has = source and source.has == true or
  false` has ambiguous operator precedence. Add explicit parentheses.
