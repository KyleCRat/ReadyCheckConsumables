# Changelog

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

## [12.0.5-10] - 2026-04-24

### Fixed
- Durability and weapon oil status not broadcasting to raid members when the raid status frame is disabled
