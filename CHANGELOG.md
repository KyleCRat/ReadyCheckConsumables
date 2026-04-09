# Changelog

All notable changes to Ready Check Consumables will be documented in this file.

## [12.0.1-7] - 2026-04-09

### Added
- Settings: consumables frame and raid frame scale sliders (0.5x–2.0x, 0.1 increments)
- Consumables frame: food icon now shows the actual buff icon (e.g. feast Well Fed) instead of the bag item icon
- Consumables frame: food tooltip shows both the active buff and the bag item side-by-side when buffed

### Fixed
- Raid frame: players who accept a resurrection during a ready check now update from dead (red name / tombstone) to alive
- Raid frame: fix tooltip error when hovering test data rows with no real aura instance ID

## [12.0.1-6] - 2026-03-31

### Added
- Raid frame: durability column showing each member's gear durability percentage
- Raid frame: weapon oil column with remaining duration
- Raid frame: read MRT repair data from ready check broadcasts
- Delegate chat reporting to MRT when it is installed to avoid duplicate messages
- Deduplicate chat report lines
- `/rcc test` now shows a full fake raid with one row per class, randomized buff/consumable states, durability, oil status, and ready check responses
- Test mode runs a 15-second countdown with staggered ready check confirmations
- Smooth per-frame progress bar animation on the raid frame title bar

### Changed
- Update to use `issecretvalue()` API

## [12.0.1-5] - 2026-03-30

### Added
- Food icon shows a cooldown swipe while eating, before the Well Fed buff applies
- Frames now linger for 15 seconds after ready check ends to show late consumable use

### Fixes
- Fix remaining "secret" aura value errors across all aura scanning code (icon, expirationTime)
- Fix crash when memberData is empty on ready check finish
- Fix protected frame action error when hiding raid frame during combat
- Ignore ready checks that fire during combat

## [12.0.1-4] - 2026-03-29

### Added
- Food button on consumables frame is now clickable to use food from inventory

### Fixes
- Fix "table index is secret" error when scanning auras on other players
