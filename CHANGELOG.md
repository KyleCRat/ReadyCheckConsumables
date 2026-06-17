# Changelog

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

## [12.0.7-15] - 2026-06-16

### Added
- Added raid-frame cauldron tracking for Midnight flask and potion cauldrons.
  The raid frame can open with only cauldron columns when cauldrons are detected
  outside a ready check, then append cauldron columns to the normal ready-check
  layout.
- Added per-player cauldron pickup counts with the most recent fleeting flask or
  potion icon shown in each cauldron cell. Counts are colored for under, exact,
  or over the expected pickup amount.
- Added Midnight cauldron data for R1 and R2 flask and potion cauldrons,
  including cauldron spell IDs, cauldron item IDs, and fleeting pickup item IDs.
- Added raid-frame cauldron settings and synthetic cauldron test data for
  `/rcc test`, `/rcc testp`, and cauldron-only test commands.
- Added ready-check-only test commands for testing the raid frame without
  cauldron columns.
- Added chat-report checks for missing or expiring weapon enchants and low
  repair durability when RCC has known broadcast data for those players.

### Changed
- Updated the raid frame to support separate ready-check and cauldron display
  modes with dynamic column layout.
- Updated raid-frame weapon enchant and durability handling so those columns can
  refresh while a ready check is active.
- Chat-report repair and weapon-enchant checks now use the shared raid-frame
  broadcast data and skip players whose status is unknown.

### Fixed
- Fixed cauldron test data leaking into live cauldron pickup state after test
  frames were closed.
- Fixed cauldron-only name padding when the ready-check icon column is hidden.
- Fixed repair report labeling to use `Repair` instead of color-specific
  wording.
- Fixed weapon enchant status handling for missing enchants, missing weapons,
  and unknown timing values.
