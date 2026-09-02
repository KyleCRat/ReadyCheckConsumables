# Changelog

## [Unreleased]

### Added
- Added an optional permanent Consumables Action Bar with independently enabled,
  fixed button slots for the personal consumable actions.
- Added combat-usable primary and flyout actions prepared before combat. Public
  aura durations and status visuals continue updating during combat while
  glows remain suppressed.
- Added Action Bar controls for icons per row, button width and height,
  horizontal and vertical gaps, text size, duration-text side, flyout direction,
  stack counts, durations, status marks, profession-quality marks, anchor
  points, and X/Y position.
- Added cropped non-square button icons, fixed close-to-button flyout spacing,
  and exclusive flyout hover ownership across multi-row layouts.
- Added Action Bar positioning through EllesmereUI Unlock Mode when available,
  with LibEditMode-backed Blizzard Edit Mode positioning otherwise.
- Added an Action Bar Only setting that disables the temporary Consumables
  Frame without affecting the permanent bar, Raid Status Frame, chat reports,
  or managed macros.
- Added optional Inky Black Potion and Repair buttons to both personal
  consumable surfaces. Both buttons are disabled by default.
- Added Inky Black Potion buff display as a neutral optional effect without
  ready/missing marks or desaturation.
- Added repair-item selection that prefers a ready reusable Jeeves, falls back
  to Auto-Hammer, and shows repair cooldowns without ready/missing marks.
- Added both ranks of Concentrated Silvermoon Health Potion and Fleeting
  Silvermoon Health Potion.
- Added both regular and fleeting ranks of Liquid Luster and Alluring Nostrum.
- Added Venom-Spiced Cutlets, Puffer Plate, and Sweet-and-Sour Skewers, including
  their hearty variants.
- Added Amani Cornucopia and Feast of Knowledge feast items, hearty variants,
  and confirmed placement-spell detection.

### Changed
- Rebuilt the temporary Consumables Frame and permanent Action Bar around a
  shared consumable catalog, state controller, action binding, rendering, and
  flyout pipeline.
- Changed `/rcc h` and `/rcc hide` to hide only temporary RCC frames, leaving
  the enabled permanent Consumables Action Bar visible.
- Updated LibModernSettings to 1.2.0 so manually entered slider values can
  remain outside the visual slider track range.
- Embedded LibEditMode 15 as the Action Bar movement fallback when EllesmereUI
  is unavailable.
- Expanded player and maintainer documentation for the Action Bar and
  end-to-end consumable data requirements.

### Fixed
- Prevented the Raid Status Frame from briefly switching back to its
  feast/cauldron provision layout while a completed ready check fades out.
- Registered fleeting Liquid Luster and Alluring Nostrum as potion-cauldron
  pickups so they count when looted.
- Registered Fleeting Silvermoon Health Potion for both potion-cauldron pickup
  tracking and personal healing-potion selection.
- Corrected reversed quality ordering for Fleeting Lightfused Mana Potion,
  Light's Potential, Potion of Zealotry, and all four Midnight fleeting flask
  families.

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
