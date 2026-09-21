# Changelog

## [12.1.0-27] - 2026-09-21

### Fixed

- Vantus Rune buttons and macros now support The Tidebound Grotto, and personal
  and raid displays recognize Nymrissa Wavecaller's active rune.

## [12.1.0-26] - 2026-09-20

### Added

- Full settings profiles on the main RCC settings page, including character,
  specialization, and custom profiles. Existing settings are preserved in
  Global, which remains selected by default.
- Consumable preferences are now character-specific by default. Existing
  choices are copied to each character on first login, with an option to use
  profile-specific preferences instead.
- Separate Lethal Poison and Non-lethal Poison buttons for rogues on both
  personal displays, enabled by default. Dragon-Tempered Blades adds split
  icons showing both active poisons, with one click per poison to apply the
  selected pair. Single- and double-poison modes remember separate preferences
  across talent changes; flyouts show which poisons are active.
- Drag Blizzard's ready-check dialog outside combat and save its position per
  profile. Allow Dragging is on by default; turning it off forgets the position.
- Cooldown displays for unlimited augment runes, combat and healing potions,
  and consumable-pausing items, including their flyout buttons.
- Brawler's Guild healing potions take priority on buttons and in macros while
  inside its venues, without changing your normal potion preference.

### Changed

- Reduced CPU usage by avoiding unnecessary buff checks, inventory reads, and
  button redraws, and skipping work for disabled personal-display categories.
- Removed persistent Action Bar reminder glows to reduce idle CPU usage.
  Hover glows and temporary Consumables Frame reminders are unchanged.
- Action Bar flyouts now close and stay disabled during combat. Primary
  buttons remain usable with the items or spells selected before combat.
- Preferred items keep their exact rank on buttons when out of stock; macros
  can use available alternatives without changing your preference.
  Matching-family fleeting flasks and potions take priority while carried.
- Right-click a preferred item again to clear the preference. Tooltips mark
  preferred choices and update immediately when you change them.
- Fleeting items can no longer be preferred. If you previously preferred one,
  select a regular item instead.
- Weapon enchants remember recently applied oils for automatic selection,
  without overriding explicit preferences or class-spell priority.
- Prefer Unlimited Augment Runes now affects automatic selection without
  overriding your explicit preference. A cooldown does not switch the chosen
  unlimited rune to a consumable rune.
- Item macros now include one available backup for when the primary runs out.
  Augment Rune macros have no backup to prevent accidental consumable use.
- Healthstones automatically favor a carried Demonic Healthstone, showing
  the selected stone's icon and remaining charges.
- Simplified Action Bar settings and added the shared Prefer Unlimited Augment
  Runes option. Removed Action Bar Only; enable or disable each display separately.
- The Action Bar hides off-hand enchants when the slot cannot be enchanted,
  and Raid Buff on classes without a raid-buff spell.
- Updated status artwork and added clearer, wrapped Raid Status Frame tooltips.
  Unknown buff information uses a question mark; no response uses a grey X.

### Fixed

- Weapon-enchant preferences no longer switch back to the applied oil after
  a refresh or macro update.
- Combat-potion selection no longer chooses an incompatible potion type.
- Missing raid buffs that WoW never hides no longer appear Unknown because
  an unrelated secret aura is present.
- Unreadable buffs on your own character no longer suggest RCC is not installed.
- Action Bar flyouts now switch correctly when hovering between primary buttons.
- The announcement that all non-benched players are ready works with the Raid
  Status Frame closed or disabled, including when everyone responds quickly.
- Inline macro updates preserve conditions and replace old backup lines.
  Macros that would exceed the size limit are left unchanged with a warning.
