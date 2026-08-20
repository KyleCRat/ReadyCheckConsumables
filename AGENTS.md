# Ready Check Consumables Development Context

This file applies to the entire repository. It records durable product decisions
and working conventions that are easy to miss when reading one module in
isolation. Detailed rendering and protocol contracts should remain beside the
code that implements them.

## Product Intent

Ready Check Consumables is a Retail WoW addon with four connected surfaces:

1. A personal, clickable Consumables Frame.
2. A group Raid Status Frame.
3. Coordinated ready-check chat reports.
4. Managed consumable macros.

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
  Never infer "missing" when an aura scan was unavailable.
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
  only mutated out of combat.
- Both primary frames hide when combat starts. Do not queue combat-time frame
  opens unless the product behavior explicitly calls for it.
- Settings opened in combat are deferred until `PLAYER_REGEN_ENABLED`; the
  Consumables Frame manual-open command prints a message and does not open.
- The Raid Status Frame owns its SavedVariables position and scale. Keep one
  clear owner for frame positioning.
- LibModernSettings owns normal settings-page layout. Addon pages should express
  full- or half-width placement through its canvas layout API and use direct
  pixel positioning only for genuinely custom layouts such as matrices.
- Settings matrices use the library's table builder so row colors and 8 px left
  and right table padding remain consistent.

## SavedVariables and Settings

- `ReadyCheckConsumablesDB` is account-wide. There are no profiles.
- `Settings.lua` owns defaults and nil-only default backfilling. Preserve stored
  `false` values and validate or migrate malformed structured data explicitly.
- Prefer `RCC.GetSetting` and `RCC.SetSettingValue` over direct access for normal
  scalar settings.
- `contextualVisibility` is intentionally sparse: `nil` means use the definition
  default, while explicit `true` or `false` is an override.
- Preferred consumable item choices are shared by the personal frame and
  managed macros.

## Module Ownership and Load Order

- `ReadyCheckConsumables.toc` is the authoritative load order.
- `Data/` builds normalized registries in `RCC.db`; expansion files append to
  those registries before runtime modules load.
- Permanent enchant data under `Data/*/Enchants.lua` is intentionally retained
  for possible future features but is not part of current runtime readiness
  checks. Do not delete it merely because it is dormant.
- `Modules/Consumables/` resolves domain state and actions.
- `Modules/ConsumableFrame/Presenters/` translates domain state into view state.
- `Modules/ConsumableFrame/` owns the personal frame, secure actions, rendering,
  tooltips, contextual visibility, and settings.
- `Modules/RaidFrame/` owns group state, RCC broadcasts, row/column rendering,
  feast/cauldron tracking, tests, and frame controls.
- `Modules/ChatReport/` owns reporter election, report construction, output
  chunking, and report settings.
- `Modules/ConsumableMacros/ConsumableMacros.lua` owns both managed `#RCC`
  macros and inline `#RCCI` rewrites.
- LibModernSettings is embedded as the `Libs/LibModernSettings-1.0` submodule
  and fetched by `.pkgmeta` from its released tag. Keep the submodule commit and
  `.pkgmeta` tag aligned when updating it.

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
- Keep detailed contracts next to the relevant implementation. Use this file
  for repository-wide intent and workflow only.
- Update `README.md` from implemented player-facing behavior, not planned work.
- `Docs/TODO.md` is a backlog, not an implementation contract; confirm an item
  is still current before acting on it.
- Do not add test harnesses or LibStub stubs as routine work. The primary
  validation path is in-game testing by the maintainer, assisted by `/rcc t`,
  `/rcc rt`, and `/rcc ct`. Static syntax or whitespace checks are still useful.
- When changing ready-check state, test at least: a compatible RCC response,
  aura-unavailable response, no response/addon absent, missing consumable, no
  weapon, and an all-good column.
- When changing instance behavior, test party, raid, scenario/delve, arena, and
  battleground entry independently.
- When changing communication, test current-to-current and current-to-previous-
  release clients.

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
