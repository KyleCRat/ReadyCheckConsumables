# Changelog

## [Unreleased]

### Fixed
- Made scenario instance entry wait for settled instance data and respond to
  scenario-data events when the world-entry event alone misses the transition.

## [12.1.0-19] - 2026-08-11

### Changed
- Made ReadyCheckConsumables require Interface `120100` and use the final 12.1
  macro-limit constants directly.
- Migrated temporary weapon-enchant detection to
  `C_PaperDollInfo.GetTemporaryEnchantmentInfo` through one shared slot-state
  adapter.
- Consolidated aura-backed chat reports around one point-in-time roster scan
  instead of rescanning every player for each report category.
- Updated the embedded LibModernSettings dependency to 1.1.0.

### Fixed
- Made helpful-aura scans fail closed when 12.1 restricts aura access, with
  unavailable scans omitted from reports, raid-frame status, and missing-buff
  prompts instead of being treated as empty aura lists.
- Added an explicit grey question-mark state and explanatory tooltip when the
  Consumables Frame cannot read aura status.

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
