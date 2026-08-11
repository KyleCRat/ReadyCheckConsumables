# Changelog

## [Unreleased]

### Changed
- Made ReadyCheckConsumables require Interface `120100` and use the final 12.1
  macro-limit constants directly.
- Migrated temporary weapon-enchant detection to
  `C_PaperDollInfo.GetTemporaryEnchantmentInfo` through one shared slot-state
  adapter.

### Fixed
- Made helpful-aura scans fail closed when 12.1 restricts aura access, with
  unavailable scans omitted from reports, raid-frame status, and missing-buff
  prompts instead of being treated as empty aura lists.

## [12.1.0-18] - 2026-08-10

### Added
- Added Consumable Stasis support to the Consumables Frame, including optional
  automatic opening when BigWigs or DBM starts a break timer.
- Added feast detection that can show the Raid Status Frame's food column
  outside ready checks.
- Added `/rcc c` and `/rcc consume` to open the Consumables Frame.

### Changed
- Rebuilt addon settings on the native Blizzard Settings canvas using the
  embedded LibModernSettings 1.0.0 release, with standardized full-width,
  two-column, indented, and matrix layouts.
- Moved consumable-frame, raid-frame, and chat-report settings into
  feature-owned modules and centralized contextual frame visibility.
- Shortened and standardized slash-command aliases while retaining descriptive
  command names.

### Fixed
- Prevented `/rcc settings` from calling the protected Settings API in combat;
  the panel now opens after combat ends.

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
