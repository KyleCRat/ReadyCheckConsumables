# Changelog

## [12.0.5-12] - 2026-04-28

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

### Internal
- Extracted slash commands and raid-frame test data into separate files.
- Refactored raid frame row rendering, event handling, and shared roster/MRT helper logic.

## [12.0.5-11] - 2026-04-27

### Changed
- Minimum display time slider range extended from 1-20s to 1-40s
- Added minimum display time setting for the raid status frame
- Consumables frame hides immediately on ready check response when minimum display time is disabled
- Consumables frame shows a close button after ready check response

### Fixed
- Corrected minimum display time logic and cleaned up unnecessary timer restart

### Internal
- Settings refactored and variable names clarified
