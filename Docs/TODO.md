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

## Review

- Review consumable priority/data structures before extracting shared selector
  helpers. Combat potions and flasks now use family/variant metadata, but wait
  until food, augments, weapon enchants, and other consumables are reviewed so a
  shared helper follows real common behavior instead of forcing everything into
  the first family-based shape.
