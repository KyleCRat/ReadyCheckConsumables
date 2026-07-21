# Changelog

## [12.1.0-17] - 2026-07-21

### Added
- Added initial World of Warcraft 12.1.0 support.
- Added provisional support for Concentrated Silvermoon Health Potion, Liquid
  Luster, and Alluring Nostrum.
- Added a disabled-by-default option to open the Consumables Frame after
  collecting a known flask or potion from a cauldron.

### Changed
- Updated managed-macro limit discovery for 12.1 while retaining compatibility
  with the legacy 12.0.7 limits.

### Fixed
- Hardened aura caching, tooltips, food and Vantus handling, and `UNIT_AURA`
  processing against restricted values.
- Corrected per-cauldron-type auto-open session tracking.

## [12.0.7-16] - 2026-06-17

### Added
- Added Sporefall Vantus rune support, including Rotmire Vantus aura IDs and
  standard Midnight Vantus rune items.
- Added support for Mythic Flexible raid difficulty `233` as a 15-25 player
  Mythic raid for active group filtering and chat-report settings.

### Fixed
- Fixed cauldron-only raid frames reopening on every pickup after the frame was
  manually closed. Subsequent pickups now update active cauldron state without
  forcing the frame back open.
