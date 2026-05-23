# Changelog

## [12.0.5-13] - 2026-05-23

### Important
- The internal icon setting keys for Damage Potion and Mainhand/Offhand Oil were
  renamed to Combat Potion and Mainhand/Offhand Weapon Enchant. If you
  previously disabled those icons, they will re-enable after this update. You
  can disable them again in `/rcc settings` -> Consumables Frame.

### Added
- Added managed RCC macros for food, flasks, augment runes, Vantus runes,
  combat potions, healing potions, healthstones, raid buffs, and weapon enchants.
- Added item flyouts and right-click item preferences for supported consumable
  buttons.
- Added an optional Recuperate button and healing-potion macros that cast
  Recuperate out of combat.
- Added a personal raid-buff button to the consumables frame.
- Added optional consumables-frame opening when entering selected instance types.
- Added item quality badges, richer tooltips, and click hints for consumable
  buttons.
- Added food, flask, and weapon enchant broadcasts so the raid status frame can
  show richer data from other RCC users.

### Changed
- Renamed weapon oil wording to weapon enchant and improved support for both
  item-based and spell-based temporary weapon enchants.
- Renamed damage potions to combat potions and updated potion, flask, augment,
  and healing-item priority rules.
- Split consumable data into expansion-specific files and refreshed Midnight,
  The War Within, Dragonflight, Shadowlands, Battle for Azeroth, Legion, and
  Warlords data tables where applicable.
- Refactored the consumables frame into state, renderer, action, tooltip,
  candidate, presenter, and controller modules.
- Refactored the raid status frame into column, row, title-bar, control,
  broadcast, member, and test modules.
- Moved shared UI controls, frame fade animations, aura timing, roster helpers,
  and raid-buff status logic into reusable modules.
- Added an inline raid-frame scale control and improved popup slider behavior.
- Reorganized the TOC into human-readable sections while preserving load order.

### Fixed
- Protected aura, unit, spell, and duration handling against secret values and
  unsafe values in Midnight-era APIs.
- Fixed timer formatting and permanent-duration buff display.
- Fixed several weapon enchant edge cases, including missing weapons, unknown
  durations, stale spell enchants, selected items missing from bags, and
  cross-client weapon enchant display.
- Fixed consumable flyout closing, unavailable item cache handling, and glow
  behavior around active or unavailable buttons.
- Fixed raid-frame durability edge cases, including zero durability values and
  threshold handling.
- Fixed chat reporting so offline players are reported separately, offline
  players are skipped for consumable checks, and reports never fall back to
  `/say`.
- Fixed augment rune tier reporting so previous-expansion unlimited runes remain
  valid while outdated consumable runes are still reported.
- Fixed food detection drift by normalizing Well Fed and eating/drinking aura
  handling across the consumables frame, raid frame, and chat report.
- Fixed the TOC load order for consumable action constants and converted the
  raid-frame event chain to a dispatch table.

## [12.0.5-12] - 2026-04-29

### Important
- The Consumable Frame Augment Rune icon setting has been renamed internally. If you previously disabled it, it will re-enable itself after this update. You can disable it again in `/rcc settings` → Consumables Frame.

### Added
- Added timed and permanent raid status frame test modes via `/rcc test` and `/rcc testp`.
- Added Midnight augment rune and Vantus rune data.

### Changed
- Renamed augment rune UI/report wording from "Rune" to "Augment" to avoid confusion with Vantus runes.
- Improved augment rune tier handling so reports use expansion-aware tiers and readable tier names.
- Raid status frame now fades out over 0.5 seconds when it closes automatically.
- Raid status frame addon-message redraws are coalesced to reduce burst refresh work at ready-check start.

### Fixed
- Consumable icon buttons now collapse correctly when individual icons are disabled.
- Re-enabling consumable icon settings now updates the visible consumables frame without requiring a reload.
- Durability and weapon oil broadcasts now still send when the local raid status frame is disabled.
- Fixed a ready-check race where personal durability and weapon oil data could be cleared after being broadcast.
- Fixed stale chat-report election state so RCC does not suppress reports after an earlier MRT/RCC report.
- Fixed MRT compatibility by listening to MRT addon prefixes and parsing `raidcheck` as the message payload module.
- Fixed cross-realm player collisions by keying durability, weapon oil, and report election state by full `Name-Realm`.
- Healthstone visibility now ignores benched warlocks outside the active raid groups.
- Consumables frame delayed inventory updates no longer run after the frame hides or combat starts.
- Consumable buttons retry item-name lookups when item data is not cached yet.
- Fixed permanent-duration buffs (e.g. some feast buffs) showing "0m" in red instead of no time text.

### Internal
- Extracted slash commands and raid-frame test data into separate files.
- Refactored raid frame row rendering, event handling, and shared roster/MRT helper logic.
