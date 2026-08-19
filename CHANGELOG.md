# Changelog

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

## [12.1.0-21] - 2026-08-18

### Fixed
- Restricted feast-drop detection to confirmed placement spell IDs so ordinary
  refreshment and eating spells no longer open the raid status frame.
