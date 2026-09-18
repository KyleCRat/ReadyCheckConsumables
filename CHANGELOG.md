# Changelog

## [Unreleased]

### Changed

- Item macros now include their primary choice and one eligible backup from
  your bags, selected using the same category rules. The backup remains usable
  if the primary runs out during combat, without rewriting the macro mid-fight.
- Healing-potion buttons and macros now share location-aware selection: a
  carried Brawler's Guild potion (`253011`) takes priority only inside its
  venues, without replacing your saved normal-potion preference. Leaving the
  venue restores normal selection. Macros include the normal potion as their
  one backup; the complete macro still casts Recuperate out of combat. Prepared
  button actions and macro updates wait until combat ends before switching.
- Inline potion/healthstone markers now maintain their complete group of item
  choices and preserve conditions on every line. Updates replace old backups
  instead of accumulating lines. Oversized macros are left unchanged with a
  message rather than risking truncated macro text.
- Test raids now randomize cauldron flask and potion choices per player in
  `/rcc t`, `/rcc tp`, and `/rcc ct`, while retaining the existing pickup-count
  examples. Choices stay fixed until a new test starts.
- Check and X status icons now use Blizzard's higher-resolution
  `common-icon-checkmark` and `common-icon-redx` artwork across personal
  buttons and raid-frame headers and rows. Existing icon sizes, colors, and
  opacity are unchanged.
- Unknown indicators use common-style question-mark artwork matching RCC's other
  status icons: grey at 80% opacity on the Raid Status Frame, and fully opaque
  and colored on personal consumable buttons. No Response keeps a grey X,
  distinct from No Weapon's red X; faded category icons remain visible behind
  unavailable raid-frame states.
- Raid Status Frame unavailable tooltips now have short titles and wrapped
  descriptions. Buff tooltips explain why secret or unreadable auras prevent
  confirming absence; No Response explains that no addon confirmation arrived
  and the player may lack RCC or have been unable to reply.
- Reorganized the README around personal consumables, group readiness, and
  macros, with clearer consumable lists, common settings beside each feature,
  and a separate advanced reference for behavior, macro syntax, and commands.
- Rewrote the contributor consumable guide as an end-to-end Flask walkthrough,
  with concrete data and snapshot examples, event-to-button tracing, and guidance
  for adding items or new button categories.
- Removed the Action Bar Only checkbox. The Consumables Frame and Action Bar
  now use only their independent Enabled settings, and resetting the Action
  Bar no longer changes Consumables Frame enablement.
- The Action Bar now hides Off-hand Enchant when the off-hand slot cannot be
  enchanted and closes the gap. It returns when an enchantable off-hand is
  equipped; combat-time equipment changes update the layout after combat.
- Removed persistent reminder glows from the Action Bar to reduce idle CPU
  usage. Hover glows and temporary Consumables Frame reminders are unchanged.
- Separated flyout configuration from choice updates, avoiding duplicate
  rendering and unchanged layout work.
- Reduced repeated personal-button work by normalizing shared states once,
  creating combat-only visual copies only when needed, and skipping unchanged
  icon, text, color, opacity, and visibility writes. Hover changes and display
  options still update immediately, and released buttons reset before reuse.
- Removed duplicate weapon-enchant and augment candidate sorting while keeping
  their existing priorities, flyout ordering, and Healthstone charge selection.
- Action Bar flyouts now close when combat starts and remain disabled until
  combat ends. Choose preferred items before combat; primary buttons remain
  usable with their preselected items and spells during combat.
- Rebuilt personal consumable refreshes around shared public input snapshots,
  category-owned dependencies, and independently cached item selection and
  status. Aura updates no longer recount bags or rebuild unchanged flyouts.
- Separated instance rules, local venue detection, and class information so
  local movement no longer triggers unrelated personal consumable aura scans.
  Major zone/difficulty transitions explicitly refresh needed aura observations,
  even when the instance ID and type are unchanged.
- Added one shared deadline timer for duration labels, expiration warnings,
  aura rechecks, and repair cooldown completion. Unchanged cooldown events no
  longer run the full consumable pipeline.
- Cached raid-buff observations per group member, refreshing affected members
  on aura, connection, phase, range, and life-state changes. The player's fresh
  aura scan is reused when it can answer their own raid-buff check.
- The personal Raid Buff button now uses targeted spell-ID queries instead of
  full group-member aura scans, shared by the Consumables Frame and Action Bar.
  Class-specific equivalents remain supported, and public raid buffs can still
  be checked during combat. The Raid Status Frame keeps its full scans.
- Separated baseline class raid buffs from expansion-specific item alternatives.
  Only the current expansion's item data is loaded, so legacy BfA war-scrolls
  no longer affect detection or secrecy checks. Their data is retained separately.
- Separated reusable single-spell aura lookups from first-matching-variant
  searches, keeping their availability and secret-value handling consistent.
- Read Blizzard's raid-buff secrecy policies once each login/reload rather than
  maintaining a hardcoded list, covering every supported aura variant.
- Separated visual, interaction, and applicability revisions so both personal
  surfaces can apply only changed state. Combat-end reconciliation refreshes
  desired data before rebinding secure actions; opening a hidden surface still
  refreshes its inputs. Repair cooldown visuals stay tied to the prepared item
  during combat even if another device becomes preferable.
- Kept managed macros on live-read adapters over the shared selectors, with
  their existing fallback policies and support for both personal frames being
  disabled. Applied-enchant preference tracking is now an explicit operation,
  and presenters no longer query inventory or change saved preferences.
- Centralized Recuperate spell/icon data for personal buttons and the healing-
  potion macro. Clarified the refresh API with named options and made fixed
  event registrations and weapon-slot constants explicit.
- Personal consumable processing now follows the categories requested by the
  visible Consumables Frame and enabled Action Bar. Unused categories no longer
  select items, evaluate status, prepare flyouts, or retain refresh deadlines;
  unneeded input events, group-aura checks, and repair cooldown reads stop too.
- Both surfaces share observations for overlapping categories but render only
  their own requests. Re-enabling refreshes live data, inapplicable enabled
  buttons keep their recovery inputs, and prepared Action Bar buttons remain
  usable in combat. Macros, raid broadcasts, and chat reports stay independent.
- Centralized ready-check responses, active-roster membership, and summary
  counts in one shared session used by the Raid Status Frame and Chat Report.
  In-game previews use the same model in isolation without sending announcements.

### Fixed

- Combat-potion auto-selection no longer picks an incompatible potion type or
  utility family when none of the carried items match the saved preference.
- The Unknown preview row now keeps public raid buffs readable while simulating
  an unresolved consumable scan. Random secret-aura cases no longer mark raid
  buffs Unknown, and the guaranteed-good mirrored columns are preserved.
- Recognize the local player as having RCC without needing a presence message.
  Unreadable self-statuses in Raid Status Frame previews now use the Unknown
  tooltip instead of suggesting RCC might not be installed.
- Missing never-secret raid buffs no longer become Unknown just because an
  unrelated secret aura is present. Unresolved raid-buff categories now reuse
  targeted lookups with current secrecy checks to confirm presence or absence
  wherever possible. Inaccessible or still-unresolved results remain
  Unknown; food, other consumables, and chat-report completeness rules are unchanged.
- Fixed Action Bar flyouts failing to switch when hovering directly between
  primary buttons. Hovering inside an open flyout still blocks overlapping
  primary buttons, and flyouts remain unavailable in combat.
- Decoupled the bench-aware ready announcement from the Raid Status Frame so
  the elected reporter can announce even when their frame is disabled or closed.
- Wait for the existing reporter-selection window before announcing, retain
  early completions through that window, and mark announcements sent only after
  issuing group chat. Keep one reporter for each check and cancel pending work
  on combat, group exit, travel, difficulty changes, or a replacement ready check.

### Removed

- Removed the unused temporary Armor Kit prototype and its icon configuration.
  Permanent-enchant data is unchanged; existing consumable features are unaffected.

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
