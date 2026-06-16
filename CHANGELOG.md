# Changelog

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
