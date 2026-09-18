# TODO

## Fixes
- Changing a setting during a test removes all test rows (not critical)

## Features
- Add invisibilty potions Potion of the Hushed Zephyr:191395 - need to find newer and older ones
- (? Maybe, not sure yet) Add Raid Wipe Recovery Items Irresistible Red Button:221945 - These items can be placed before pull to ressurect someone after a wipe

## ConsumableActionBar
- Add icon styling controls (Should have same options as EUI allows for action bars at minimum) (Possibly add to ALL icons so they don't inherit base / eui / dominos look? maybe allow changing between these?)

## Aura Lookup Validation

- [ ] Confirm the targeted and full-scan paths in game: present/missing buffs
  with an always-secret cosmetic, Evoker variants, any registered
  current-expansion item alternatives, combat, off-map/out-of-phase members,
  login/reload, and expiration-driven refreshes. BfA war-scroll IDs must not be
  queried or matched.
- [ ] Measure solo, party, and raid CPU with Raid Buff alone and alongside
  other aura categories. Confirm that disabled personal raid-buff checks perform
  no group queries and that both personal surfaces share the observations.

## Performance Follow-ups (After Major Refactors)

Review these after the flyout update cleanup, dependency-aware consumable
refreshes, and disabled-category filtering. Complete the aura lookup validation
above before considering further changes to aura acquisition.
Check whether those changes already resolve a follow-up before adding more
caching. Keep implementation completion separate from in-game validation.

- [x] Normalize new primary and flyout states once in the runtime. Renderers
  consume read-only states; combat merges use separate copies only when a
  button needs a visual update.
- [x] Cache unchanged icon, text, color, opacity, and visibility values in the
  shared button renderer, alongside the existing cooldown/quality caches.
  Reset render state when releasing primary or pooled flyout buttons.
- [x] Sort weapon-enchant and augment candidates once using their category's
  priority. Preserve default item-ID ordering and charge counts for Healthstones.
- [x] Confirm step 3's category-demand filtering in game: Repair now releases
  its candidates, cooldown observations, event subscription, and deadlines when
  neither personal surface requests it. Verify fresh ready-item selection and
  timely cooldown completion after re-enabling, including during a cooldown.
- [ ] Validate the rendering cleanups on both personal surfaces: hover icon
  changes, display-option toggles, flyout reuse, disable/re-enable, duration and
  warning updates, and combat-prepared actions with live status/cooldown visuals.
- [ ] Confirm weapon-enchant and augment primary/flyout ordering, including the
  unlimited-augment preference, plus Healthstone selection and charge counts.

## Review

- Review consumable priority/data structures before extracting shared selector
  helpers. Combat potions and flasks now use family/variant metadata, but wait
  until food, augments, weapon enchants, and other consumables are reviewed so a
  shared helper follows real common behavior instead of forcing everything into
  the first family-based shape.
