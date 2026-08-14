# Changelog

## [12.1.0-20] - 2026-08-14

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
