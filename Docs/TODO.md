# TODO

## Profile Migration Release Gate

- [x] Released LibSimpleDBProfiles 1.1.0 with the `initialProfile` API and
  aligned RCC's submodule checkout and `.pkgmeta` tag. Implementation minor 2
  takes precedence over older 1.0.0 embeds regardless of addon load order.
- [ ] Confirm the profile migration in game with a backup of the pre-migration
  SavedVariables: existing settings/positions survive in Global, preferences
  seed each character once from the original shared choices (including a
  later-login alt), and reload never restores a cleared preference. Confirm
  the character-owned storage toggle defaults off, persists through profile
  changes, and switches stores without copying. Profile copy/reset must leave
  character preferences and the toggle untouched. Character and Specialization settings
  must stay separate, both displays/macros must refresh, and both movement
  providers must use the active profile's positions. Confirm no temporary
  frames reopen or chat reports replay on a profile change.

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

## Review

- Review consumable priority/data structures before extracting shared selector
  helpers. Combat potions and flasks now use family/variant metadata, but wait
  until food, augments, weapon enchants, and other consumables are reviewed so a
  shared helper follows real common behavior instead of forcing everything into
  the first family-based shape.
