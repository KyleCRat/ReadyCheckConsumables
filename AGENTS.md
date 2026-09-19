# Ready Check Consumables Development Context

This file applies to the entire repository. It records durable product decisions
and working conventions that are easy to miss when reading one module in
isolation. Detailed rendering and protocol contracts should remain beside the
code that implements them.

## Product Intent

Ready Check Consumables is a Retail WoW addon with five connected surfaces:

1. A personal, clickable Consumables Frame.
2. A permanent, combat-usable Consumables Action Bar.
3. A group Raid Status Frame.
4. Coordinated ready-check chat reports.
5. Managed consumable macros.

The addon should help a group act on known readiness information without
turning unavailable information into a false failure. Unknown data is not bad
data.

## Runtime and Compatibility

- Target the Interface version declared in `ReadyCheckConsumables.toc`; the
  current target is Retail `120100`.
- WoW uses Lua 5.1 semantics. Avoid newer Lua language features and account for
  sparse tables, multiple returns, local forward declarations, and colon versus
  dot calls.
- Treat secret or restricted values as an expected runtime state. Use the
  helpers in `Functions.lua` and the centralized scan boundary in `AuraScan.lua`.
  Follow that boundary's availability rules; an unreadable result alone is
  never evidence that a buff is missing.
- Use `spellID` in RCC-owned data and APIs. Blizzard's raw aura field is named
  `spellId`; normalize it to `spellID` at the boundary.
- One released RCC version of backward interoperability is sufficient unless a
  feature explicitly needs a longer migration window.
- `OIL` is intentionally the stable addon-message type for temporary weapon
  enchants. It is a wire-protocol name, not a user-facing domain name. Do not
  rename it without a staged compatibility plan.
- Feast and cauldron messages are additive coordination signals. Local pickup
  counts still come from loot events.
- Delves currently follow the Scenarios instance setting because WoW reports
  them with instance type `scenario`. Do not add a separate delve setting
  unless detection can reliably distinguish it and the product decision is
  revisited.

## Core Product Contracts

- Confirmed failures make a Raid Status Frame column header bad. Unknown and
  no-response states are neutral and must not block the header from becoming
  good once all known states are good. The detailed row visual contract lives
  in `Modules/RaidFrame/RaidFrameColumnRenderers.lua`; the header aggregation
  contract lives with the column definitions and title bar.
- A player without an enchantable weapon is a confirmed bad temporary weapon-
  enchant state, not unknown.
- Food is good only after a valid Well Fed aura is present for the required
  duration. Eating is an in-progress visual state and still not good.
- Presence answers "is a compatible RCC client responding?" separately from
  whether that client could inspect aura data.
- Aura-derived chat-report sections are all-or-nothing for the active online
  roster. If a safe scan cannot be completed, omit those sections instead of
  reporting false missing buffs.
- Contextual visibility composes semantic reasons rather than replacing one
  open mode with another. The shared reasons live in
  `Modules/ContextualVisibility.lua` and include ready check, instance entry,
  cauldron pickup, break timer, feast drop, cauldron drop, and manual test.
- Closing the Raid Status Frame's ready-check display is also a close boundary
  for its visible feast/cauldron provision mode. Do not hand the frame back to
  active provision reasons when a ready check finishes.
- Global enablement, reason visibility, and current applicability are separate
  gates. Keep policy in definitions/context, status data in presenters, and
  rendering in renderers.
- Short status labels and tooltip fragments normally omit terminal periods.
  Use normal punctuation for full instructional sentences.

## UI and Combat Safety

- Secure action buttons and protected attributes are created before combat and
  only mutated out of combat. The permanent Action Bar keeps its prepared
  primary actions through combat while public aura/status visuals continue to
  update and glows remain hidden. Flyouts are out-of-combat preparation UI:
  close any open flyout securely when combat starts and do not reopen it during
  combat. Preferred items must be selected before combat.
- The temporary Consumables Frame and Raid Status Frame hide when combat starts.
  Do not queue combat-time frame opens unless the product behavior explicitly
  calls for it. The permanent Action Bar is intentionally combat-usable.
- Settings opened in combat are deferred until `PLAYER_REGEN_ENABLED`; the
  Consumables Frame manual-open command prints a message and does not open.
- The Raid Status Frame owns its SavedVariables position and scale. Keep one
  clear owner for frame positioning.
- The Consumables Action Bar uses EllesmereUI Unlock Mode when its public API is
  available and LibEditMode otherwise; never register both movement providers.
- LibModernSettings owns normal settings-page layout. Addon pages should express
  full- or half-width placement through its canvas layout API and use direct
  pixel positioning only for genuinely custom layouts such as matrices.
- Settings matrices use the library's table builder so row colors and 8 px left
  and right table padding remain consistent.

## SavedVariables and Settings

- `ReadyCheckConsumablesDB` is an account-wide profile container, not a settings
  payload. LibSimpleDBProfiles owns profile selection and storage;
  `RCC.settingsDB` is the stable LibSimpleDB instance for the active profile.
  Do not confuse it with `RCC.db`, which remains the gameplay-data registry.
- Module settings and saved positions belong to the active profile.
  New characters start on Global; choosing Specialization shares a
  profile by spec across characters, while Character is individual. Profiles
  do not inherit settings from Global; missing values use addon defaults.
- `Modules/Profiles/ProfileMigration.lua` adopts the complete pre-profile
  settings table into Global once and freezes a detached copy of the legacy
  item preferences outside the profiles. Each character is seeded from that
  copy once on login, so later-login alts inherit the original choices and
  cleared choices are never restored. Keep outer storage migrations separate
  from per-profile payload migrations, and never discard an unsupported
  storage version to recover silently. Within each store, add sequential
  migration steps under its existing version marker rather than independent
  format flags. Keep completed steps for characters that log in later.
- `ReadyCheckConsumablesCharacterDB` is per-character SavedVariables, wrapped
  by `RCC.characterDB`. It owns item preferences by default and the
  `useProfileConsumablePreferences` toggle, which defaults to false. The toggle
  is not a profile setting: switching/copying/resetting profiles cannot change
  it or the character's stored choices. Opting in uses only the active profile's
  preferences; opting out uses only the character's. Never copy, merge, delete,
  or fall back between the two stores when toggling. An empty selected store
  means automatic item selection.
- Each module owns its own Enabled setting. Do not add combined enable/disable
  modes or let one module's settings reset change another module's enablement.
- `Settings.lua` owns defaults; LibSimpleDB supplies nil-only default lookup.
  Preserve stored `false` values and validate or migrate malformed structured
  data explicitly. Read returned tables without mutating them; write structured
  settings through `RCC.settingsDB:Set`/`ResetPath`.
- Prefer `RCC.GetSetting` and `RCC.SetSettingValue` over direct access for normal
  scalar settings.
- `contextualVisibility` is intentionally sparse: `nil` means use the definition
  default, while explicit `true` or `false` is an override.
- Preferred consumable choices are shared by both personal displays and
  managed macros through `ConsumablePreferences`, which owns storage routing.
  Do not read/write preference storage directly from individual consumers.
  Prefer Unlimited Augment Runes remains a profile-owned automatic-order setting,
  not a character item preference. The selection contract for preferences,
  automatic overrides, and fallbacks lives in
  `Modules/Consumables/ConsumableSelection.lua`.
- Preferences use typed item/spell identities in separate numeric-capacity
  branches. Talent changes must not overwrite a different branch. Confirmed
  application history is character-owned even when preferences use a profile;
  it supplies eligible fallbacks, never rewrites explicit preferences. Keep
  these contracts beside `ConsumablePreferences` and `ConsumableHistory`.
- Bulk profile switches/copies/resets refresh existing displays and macros;
  they do not create ready-check sessions, reopen closed temporary frames, or
  replay reports. Manual profile changes are blocked in combat and movement
  editing; protected refreshes from automatic changes wait until safe.
- Profile management belongs in a compact section of the base RCC settings
  page, between its subtitle and module Settings buttons, not a separate page.
  Use the YvBags-style selector, New/Copy/Reset button row, Rename/Delete
  dropdowns, and native dialogs. Keep the character preference-storage toggle
  in that section and revalidate dialog targets before changing profile data.

## Module Ownership and Load Order

- `ReadyCheckConsumables.toc` is the authoritative load order.
- `Modules/Profiles/` owns legacy storage adoption, profile lifecycle refreshes,
  and the selector/management UI. All settings pages register their `Sync`
  method with this shared owner so a profile change updates hidden pages too.
- `Data/` builds normalized registries in `RCC.db`; expansion files append to
  those registries before runtime modules load.
- Permanent enchant data under `Data/*/Enchants.lua` is intentionally retained
  for possible future features but is not part of current runtime readiness
  checks. Do not delete it merely because it is dormant.
- `Modules/Consumables/` owns the canonical consumable catalog, neutral action
  descriptors, public input readers, category dependency declarations, pure
  selection/status resolution, and the shared state controller. See
  `Docs/CONSUMABLE_PIPELINE.md` for the implementation walkthrough and examples
  of adding items or button categories.
- `Modules/ConsumableUI/Presenters/` translates domain results into normalized
  personal-surface view state without live queries or preference writes.
- `Modules/ConsumableUI/` owns shared button rendering, secure action binding,
  flyouts, surface application, and cross-page settings behavior.
- `Modules/ConsumableFrame/` owns the temporary personal frame, contextual
  visibility, automatic-open lifecycle, and its settings.
- `Modules/ConsumableActionBar/` owns permanent-bar layout, visibility,
  positioning-provider selection, and settings.
- `Modules/ReadyCheckController.lua` owns real ready-check lifecycle and native
  responses through the shared model in `Modules/ReadyCheckState.lua`. The Raid
  Status Frame and Chat Report consume the same active roster and summary;
  neither keeps a second response store or derives readiness independently.
  Closing or disabling a display must not cancel the shared session. Synthetic
  previews use isolated model instances and never drive real chat announcements.
- `Modules/RaidFrame/` owns group consumable state, RCC broadcasts, row/column
  rendering, feast/cauldron tracking, tests, and frame controls.
- `Modules/ChatReport/` owns reporter election, ready-check completion
  announcements, report construction, output chunking, and report settings.
- `Modules/ConsumableMacros/ConsumableMacros.lua` owns both managed `#RCC`
  macros and inline `#RCCI` rewrites.
- LibModernSettings is embedded as the `Libs/LibModernSettings-1.0` submodule
  and fetched by `.pkgmeta` from its released tag. Keep the submodule commit and
  `.pkgmeta` tag aligned when updating it.
- LibEditMode is embedded as the `Libs/LibEditMode` submodule and is only the
  fallback movement provider when EllesmereUI is unavailable. Keep its gitlink
  and `.pkgmeta` tag aligned.
- LibSimpleDB and LibSimpleDBProfiles are embedded submodules at
  `Libs/LibSimpleDB-2.0` and `Libs/LibSimpleDBProfiles-1.0`. Load the database
  library before Profiles. Release library API changes before pointing an RCC
  package at them, then align its gitlink and `.pkgmeta` release tag.

## Data Completeness

- Treat every gameplay-data addition as an end-to-end dataset, not as a single
  ID edit. Before considering it complete, search the category's registries and
  runtime consumers and verify inventory/action selection, active-effect
  detection, acquisition or placement signals, context mappings, every rank and
  variant, priority ordering, fallback icons, and TOC load order. Registration
  in one purpose-specific table never implies registration in another.
- Known coupled datasets that must be audited together are:
  - Flasks: item families, ranks, and priority live in
    `Data/<expansion>/Flasks.lua`; applied flask aura IDs live in
    `Data/Flasks.lua`; every cauldron-granted fleeting flask item must also be
    present in `Data/<expansion>/Cauldrons.lua` under `pickupItemIDs`.
  - Potion cauldrons: fleeting combat-potion outputs must be registered in
    `Data/<expansion>/CombatPotions.lua`, fleeting healing-potion outputs in
    `Data/<expansion>/HealingItems.lua`, and every output in the cauldron's
    `pickupItemIDs`. A cauldron definition also needs its placement/use spell
    IDs, cauldron item ranks, pickup target, and pickup quantity.
    Preserve item family and fleeting-variant metadata: selection uses it to
    limit overrides to the preferred family and prevent fleeting preferences.
  - Augment Runes: register both inventory item IDs and applied aura spell IDs,
    with matching expansion, priority, and unlimited metadata.
  - Vantus Runes: register the raid instance-to-item mapping and every
    boss-specific applied aura spell ID for every supported rank.
  - Feasts: retain the feast item IDs and separately register only confirmed
    feast-placement spell IDs; eating or food-use spells are not placement
    signals.
  - Food: register usable food items and confirm the resulting Well Fed/eating
    auras still match `foodAuraIconTypes`; add a new aura classification only
    when the existing generic icons do not cover it.
  - Temporary weapon enchants: each item-based rank needs the detected enchant
    ID plus its item, quality, expansion, and icon metadata. Spell-based
    enchants instead need the spell ID and complete weapon-slot applicability
    rules.
  - Repair devices: keep the ordered item list, per-item reusable metadata, and
    intentional default/fallback item consistent.
  - Raid buffs: keep class-provided auras in `Data/RaidBuffs.lua` and item-granted
    alternatives in `Data/<expansion>/RaidBuffs.lua`. When updating expansions,
    load only the current expansion's item file in the TOC; retain older files
    without loading them. Verify matching, targeted queries, and secrecy checks
    use the same accepted aura IDs.
- Adding an entirely new consumable category also requires tracing the
  canonical catalog, domain resolver, presenter, settings/defaults, both
  personal surfaces, and managed macros where applicable; a `Data/` entry alone
  cannot expose a new category.

## External Boundaries

- BigWigs and DBM are optional break-timer providers.
- Method Raid Tools is an optional durability/reporting peer. RCC reads MRT
  durability messages and suppresses duplicate automatic reports when MRT is
  reporting.
- ElvUI and ShestakUI only affect personal-frame ready-check anchoring.
- Keep addon-message payloads compact and validate prefix, message type, public
  values, channel, and sender where applicable.

## Working Style

- Preserve unrelated user changes and the existing four-space Lua style.
- Prefer small, explicit modules and one state owner over cross-module fallback
  chains.
- Keep gameplay spell/item/icon IDs in `Data/`, including single-ability
  categories. Use named constants for inventory slots, item classes, and time
  units rather than unexplained numeric literals in module logic.
- Favor readability over compactness: register fixed event lists explicitly,
  grouped by purpose, and use named options when positional arguments would
  require unexplained `nil`, boolean, or numeric placeholders.
- Keep detailed contracts next to the relevant implementation. Use this file
  for repository-wide intent and workflow only.
- Update `README.md` from implemented player-facing behavior, not planned work.
- `Docs/TODO.md` is a backlog, not an implementation contract; confirm an item
  is still current before acting on it.
- Do not add test harnesses or LibStub stubs as routine work. The primary
  validation path is in-game testing by the maintainer, assisted by `/rcc t`,
  `/rcc rt`, and `/rcc ct`. Static syntax or whitespace checks are still useful.
- For profile changes, verify legacy-to-Global adoption and a second login,
  Character and Specialization isolation, one-time preference migration on a
  later-login alt, toggling preference storage without copying, and preservation
  of character preferences/toggle through profile copy/reset. Verify both
  displays and macros, frame positions with both movement providers, and
  combat-safe application. Never test migration by overwriting the maintainer's
  live SV file.
- When changing ready-check state, test at least: a compatible RCC response,
  aura-unavailable response, no response/addon absent, missing consumable, no
  weapon, and an all-good column.
- When changing instance behavior, test party, raid, scenario/delve, arena, and
  battleground entry independently.
- When changing communication, test current-to-current and current-to-previous-
  release clients.
- When changing the permanent Action Bar, test primary actions before and
  during combat, out-of-combat flyout use and preference selection, secure
  closure of an open flyout on combat entry, blocked combat flyout hover, and
  normal flyout use after combat. Also check public aura/status updates during
  combat, non-square icon cropping, every flyout direction, multi-row hover
  ownership, EllesmereUI Unlock Mode, and the LibEditMode fallback.

## Patch and Season Updates

- Follow `Docs/PATCH_UPDATE_CHECKLIST.md` for every Retail patch, season, or
  raid addition, including content updates that do not change the Interface
  number.
- Treat Vantus support for every new raid as release-blocking. Register both the
  raid instance/item mapping and every boss-specific applied aura spell ID;
  without both datasets, the personal control, managed macro, or Raid Status
  Frame Vantus column cannot function correctly.

## Release Workflow

- Only prepare a release when explicitly requested.
- The addon version comes from `ReadyCheckConsumables.toc` and follows
  `<interface-major>.<interface-minor>.<interface-patch>-<release>`.
- Keep `CHANGELOG.md` current and retain the latest two release sections for the
  CurseForge manual changelog.
- Do not commit, tag, or push automatically during release preparation. After
  updating release files, print the exact commands for the maintainer:

  ```text
  git add <release files>
  git commit -m "Release VERSION"
  git tag -a VERSION -m "Release VERSION"
  git push origin main
  git push origin VERSION
  ```

- CurseForge watches tags and packages through `.pkgmeta`.
- Do not bump a LibModernSettings minor merely because RCC consumed an
  unreleased local library change. Release and retag the library only when its
  own API/package is ready.
