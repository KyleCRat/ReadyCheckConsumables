# Changelog

## [12.0.5-9] - 2026-04-23

### Added
- Settings: minimum display time toggle and slider (1–20s) to keep the consumables frame open after the ready check ends
- Settings: `/rcc options` and `/rcc o` as aliases for opening the settings panel
- Consumables frame: drag handle appears when the frame lingers after a ready check or when you are the initiator

### Changed
- Consumables frame re-parented to UIParent — eliminates the close/re-open flicker when the ready check ends
- Settings panel reorganized: enable/disable toggles and scale at the top, followed by chat report and consumables frame sections
- Default chat report permission changed from Raid Assist to Raid Leader

### Fixed
- Oils not updating on use
- Consumables frame showing eating icon over food buff icon

## [12.0.5-8] - 2026-04-21

### Added
- Chat report: announce "Everyone is Ready!" to chat when all players accept the ready check

### Changed
- Updated interface version to 12.0.5
