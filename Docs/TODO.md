# TODO

## Fixes
- Changing a setting during a test removes all test rows (not critical)

## Features
- Add invisibilty potions Potion of the Hushed Zephyr:191395 - need to find newer and older ones
- (? Maybe, not sure yet) Add Raid Wipe Recovery Items Irresistible Red Button:221945 - These items can be placed before pull to ressurect someone after a wipe

## ConsumableActionBar
- Add icon styling controls (Should have same options as EUI allows for action bars at minimum) (Possibly add to ALL icons so they don't inherit base / eui / dominos look? maybe allow changing between these?)

## Aura Lookup Validation

- [x] Use targeted spell-ID queries for the shared personal Raid Buff button,
  retaining per-member caching and reusing conclusive fresh player scans.
  Preserve primary, scroll, and class-specific equivalent IDs. Keep full scans
  for food and the Raid Status Frame rather than replacing generic icon detection.
- [x] Cache Blizzard's secrecy policies at login/reload. A finished full scan
  can confirm missing raid buffs whose accepted IDs are all NeverSecret even
  after skipping an unrelated secret aura. Do not relax whole-scan availability
  for other consumables or chat reports.
- [ ] Confirm the targeted and full-scan paths in game: present/missing buffs
  with an always-secret cosmetic, scroll and Evoker variants, combat, off-map/
  out-of-phase members, login/reload, and expiration-driven refreshes.
- [ ] Measure solo, party, and raid CPU with Raid Buff alone and alongside
  other aura categories. Confirm that disabled personal raid-buff checks perform
  no group queries and that both personal surfaces share the observations.

## Performance Follow-ups (After Major Refactors)

Review these after the flyout update cleanup, dependency-aware consumable
refreshes, and disabled-category filtering. Complete the aura lookup validation
above before considering further changes to aura acquisition.
Implement and confirm each major step in game before starting the next. Check
whether those changes already resolve a follow-up before adding more caching.

- [ ] Remove redundant state normalization/copying between the controller,
  flyout preparation, and button renderer. Establish the normalization boundary
  and preserve isolation between shared snapshots and combat-prepared states.
- [ ] Avoid reapplying unchanged icon, text, color, and visibility values in
  the shared button renderer. Preserve hover transitions and visual-option
  changes, and build on the existing cooldown and quality-icon caches.
- [ ] Remove the redundant weapon-enchant candidate sort: the generic map
  collector sorts by item ID before the enchant selector sorts by expansion,
  quality, and item ID. Preserve final priority and flyout ordering.
- [ ] Confirm step 3's category-demand filtering in game: Repair now releases
  its candidates, cooldown observations, event subscription, and deadlines when
  neither personal surface requests it. Verify fresh ready-item selection and
  timely cooldown completion after re-enabling, including during a cooldown.

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

## Review

- Review consumable priority/data structures before extracting shared selector
  helpers. Combat potions and flasks now use family/variant metadata, but wait
  until food, augments, weapon enchants, and other consumables are reviewed so a
  shared helper follows real common behavior instead of forcing everything into
  the first family-based shape.
- Add item:253011 Brawler's Guild health pot to use first if available?
