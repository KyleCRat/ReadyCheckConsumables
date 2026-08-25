# Changelog

## [12.1.0-23] - 2026-08-25

### Added
- Added Vantus Rune detection and item selection for The Venomous Abyss.
- Added `/rcc ca` to reopen the Feast/Cauldron Frame while active provision
  tracking is available.

### Changed
- Made the Raid Status Frame close its visible feast and cauldron provision
  mode when a ready-check display finishes.
- Made the "Prefer Unlimited Augment Runes" setting immediately refresh managed
  augment rune macros.
- Coalesced closely spaced Consumables Frame updates to avoid redundant
  refreshes.

### Fixed
- Included players without an enchantable weapon in weapon-enchant chat
  reports.
- Restricted RCC and Method Raid Tools addon messages to active group members
  on trusted group channels.

## [12.1.0-22] - 2026-08-19

### Changed
- Added a backwards-compatible RCC presence message so the raid status frame
  can distinguish unavailable information from players without a response.
- Delayed initial ready-check status broadcasts briefly to reduce messages
  being lost while clients initialize their ready-check state.
- Standardized raid status row visuals and tooltips for present, expiring,
  missing, in-progress, no-weapon, unknown, and no-response states.
- Made unknown and no-response data neutral when aggregating column header
  status, while confirmed failures continue to produce a red X.

### Fixed
- Made a missing enchantable weapon count as a confirmed bad weapon-enchant
  state and display the standard red X overlay.
