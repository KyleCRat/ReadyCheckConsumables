# Changelog

## [Unreleased]

### Changed

- Reorganized the README around personal consumables, group readiness, and
  macros, with clearer consumable lists, common settings beside each feature,
  and a separate advanced reference for behavior, macro syntax, and commands.
- Removed the Action Bar Only checkbox. The Consumables Frame and Action Bar
  now use only their independent Enabled settings, and resetting the Action
  Bar no longer changes Consumables Frame enablement.

## [12.1.0-25] - 2026-09-09

### Fixed
- Preserved readable consumable and raid-buff information when another aura
  has a restricted spell ID, instead of discarding the entire scan. Confirmed
  food and flask results are still shared; unresolved statuses remain Unknown.

## [12.1.0-24] - 2026-09-04

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
- Added a 50% to 100% Consumables Frame icon-width setting with cropped icons,
  matching flyout widths, and strict range validation.
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
- Updated LibModernSettings to 1.5.0 so manually entered slider values can
  remain outside the visual slider track range and to include cumulative
  control fixes.
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
