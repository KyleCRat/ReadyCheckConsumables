# Changelog

## [12.0.7-14] - 2026-06-02

### Added
- Added inline marker automation for existing custom macros, including optional
  macro condition selectors on inline marker lines.
- Added more LibPopupSlider configuration for automatic sizing, padding, font
  handling, and silent value updates.

### Changed
- Updated supported Interface metadata for WoW 12.0.7.
- Renamed the embedded popup slider library folder to `LibPopupSlider-1.0` and
  updated the embed path.
- Removed obsolete internal refactor planning docs from the packaged project.

### Fixed
- Consumables frame now closes immediately when you click Ready or Not Ready on
  the Blizzard ready-check prompt while Keep Open After Response is disabled.
  The configured minimum-show timer is still respected when that setting is
  enabled.
- Non-initiator ready checks now hide the consumables frame anchor, drag handle,
  and close button before reanchoring above the Blizzard ready-check listener.
- Healing potion macros now stop the current cast before using a healing potion
  in combat.

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
