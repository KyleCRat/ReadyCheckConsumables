# TODO

## Fixes
- Changing a setting during a test removes all test rows (not critical)
- Raid buff action bar icon on characters with no raid buff spell should not show  ? icon, it should hide

- Eating icon not showing in raid frame, may have gone secret for some reason?

## Features
- Add invisibilty potions Potion of the Hushed Zephyr:191395 - need to find newer and older ones

## Aura Lookup Validation

- [ ] Confirm the targeted and full-scan paths in game: present/missing buffs
  with an always-secret cosmetic, Evoker variants, any registered
  current-expansion item alternatives, combat, off-map/out-of-phase members,
  login/reload, and expiration-driven refreshes. BfA war-scroll IDs must not be
  queried or matched.
- [ ] Measure solo, party, and raid CPU with Raid Buff alone and alongside
  other aura categories. Confirm that disabled personal raid-buff checks perform
  no group queries and that both personal surfaces share the observations.

## Review

- Review consumable priority/data structures before extracting shared selector
  helpers. Combat potions and flasks now use family/variant metadata, but wait
  until food, augments, weapon enchants, and other consumables are reviewed so a
  shared helper follows real common behavior instead of forcing everything into
  the first family-based shape.
