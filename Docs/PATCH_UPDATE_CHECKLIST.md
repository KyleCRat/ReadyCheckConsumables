# Patch and Season Update Checklist

Use this checklist for every Retail patch, season, or raid addition. Copy it
into the tracking issue or pull request and keep the completed copy with the
release work.

Items under **Release blockers** must be complete before tagging a release for
the new client or content.

## 1. Record the Target Build

- [ ] Record the live or prerelease game version, build number, and Interface
  number.
- [ ] Refresh the local Blizzard Interface export and record which live and
  prerelease exports were compared.
- [ ] Review changes to every Blizzard API, event, template, and global used by
  RCC. Prefer capability checks over client-version branches.
- [ ] Update `## Interface` in `ReadyCheckConsumables.toc` only when the final
  live Interface number is known.

## 2. Release Blockers

- [ ] RCC loads on the target client without Lua errors.
- [ ] Aura restrictions and secret values resolve to unknown data instead of a
  false missing-consumable failure.
- [ ] Secure buttons and protected attributes are not created or changed during
  combat.

### Vantus Runes — Required for Every New Raid

Vantus support is data-driven and has no useful generic fallback. The Raid
Status Frame's Vantus column cannot detect a rune for a new raid until its boss
aura spell IDs are registered. The personal Vantus control and managed macro
cannot select the new rune until its raid instance and item IDs are registered.

| Value | What RCC uses it for | How to identify it |
| --- | --- | --- |
| Instance ID | Selects the raid's Vantus item list | Eighth return from `GetInstanceInfo()` while inside the raid |
| Item ID | Bags, personal control, and managed macro | Item link or item tooltip |
| Applied aura spell ID | Active-rune detection in personal and raid status | The boss-specific player aura, inspected for every rune rank |
| Icon file ID | Presentation only | Item or spell icon APIs; never register this as an aura spell ID |

- [ ] Enter every new raid difficulty and verify the runtime instance ID with
  `/dump GetInstanceInfo()`. Register the eighth return value; do not use the
  map, journal, or encounter ID.
- [ ] Identify every supported Vantus Rune item rank and register the item IDs
  with `RCC.Data.AddVantusItemsByRaid`. List the highest-quality item first.
- [ ] Apply every rune rank to every boss and capture each boss-specific aura
  spell ID. Register all variants with `RCC.Data.AddVantusBuffs`.
- [ ] Confirm each recorded number is the correct kind of ID. Item IDs, use-
  spell IDs, applied aura spell IDs, encounter IDs, and icon file IDs are not
  interchangeable.
- [ ] If a new expansion data file was added, place it after
  `Data/VantusRunes.lua` in `ReadyCheckConsumables.toc`.
- [ ] In game, verify the personal control selects and uses the correct item,
  the managed macro selects the correct item, and the Raid Status Frame detects
  present and missing runes.

## 3. Consumable and Content Data

Audit each registry even when patch notes do not mention consumables. Blizzard
may replace items or applied spell IDs while retaining familiar names.

- [ ] Food items, Well Fed auras, eating state, and duration thresholds.
- [ ] Feast items and feast-placement spell IDs. Placement signals must not use
  food/eating spell IDs.
- [ ] Flasks and cauldron placement/pickup data.
- [ ] Combat potions, healing items, and Consumable Stasis contents.
- [ ] Augment Rune items and auras.
- [ ] Temporary weapon-enchant items, effects, enchant IDs, and weapon-slot
  applicability.
- [ ] Gems, permanent enchants, armor kits, and any class/spec applicability
  changes.
- [ ] Raid buffs, class spell changes, and removed or newly added classes/specs.
- [ ] Item ranks, preferred ordering, icons, durations, and quality labels.
- [ ] New data files are loaded in dependency order by
  `ReadyCheckConsumables.toc`.

Permanent-enchant data may remain dormant. Do not remove it solely because the
current readiness checks do not consume it.

## 4. Runtime and API Audit

- [ ] Review aura APIs, filters, instance IDs, tooltip access, secret-value
  behavior, and scan availability through the centralized `AuraScan.lua`
  boundary.
- [ ] Review bag/container, item-information, item-location, and equipment APIs.
- [ ] Review ready-check, roster, instance-entry, combat, loot, and encounter
  events and their payloads.
- [ ] Review Settings UI, scroll widgets, frame templates, secure actions, and
  combat-lockdown behavior.
- [ ] Verify optional BigWigs, DBM, Method Raid Tools, ElvUI, and ShestakUI
  boundaries still degrade safely when absent or changed.

## 5. Settings and SavedVariables

- [ ] Add defaults and migrations with nil-only backfilling so stored `false`
  values remain intact.
- [ ] Validate malformed structured settings before migrating them.
- [ ] Verify contextual-visibility defaults and explicit overrides remain
  separate.
- [ ] Test instance auto-open behavior independently in party, raid,
  scenario/delve, arena, and battleground content.
- [ ] Update settings labels and help text for player-visible behavior changes.

## 6. Communication Compatibility

- [ ] Test addon messages current-to-current and current-to-the-previous RCC
  release.
- [ ] Verify presence acknowledgement remains separate from aura scan
  availability and consumable readiness.
- [ ] Verify compatible response, aura-unavailable response, no response/addon
  absent, missing consumable, no weapon, and all-good states.
- [ ] Preserve `OIL` as the temporary-weapon-enchant wire message unless a
  staged protocol migration is explicitly planned.
- [ ] Verify feast and cauldron messages remain additive coordination signals;
  local pickup counts still come from loot events.
- [ ] Validate prefix, message type, channel, sender, public values, and payload
  size at the communication boundary.

## 7. In-Game Regression Pass

- [ ] Run the personal-frame test (`/rcc t`).
- [ ] Run the Raid Status Frame test (`/rcc rt`).
- [ ] Run the cauldron/provision test (`/rcc ct`).
- [ ] Complete a real ready check with a current client, previous-release
  client, player without RCC, and player whose auras cannot be scanned.
- [ ] Verify food, flask, temporary weapon enchant, durability, cauldron,
  Vantus, raid buffs, and header aggregation.
- [ ] Verify chat reports, reporter election, Method Raid Tools coexistence,
  and report omission when aura data is unavailable.
- [ ] Verify contextual opens and closes for ready checks, instance entry,
  breaks, feasts, cauldrons, manual tests, and combat start.
- [ ] Verify managed `#RCC` macros and inline `#RCCI` rewrites out of combat and
  their safe behavior during combat.

## 8. Documentation and Release Handoff

- [ ] Update player-facing behavior in `README.md`.
- [ ] Update `CHANGELOG.md` and any patch-specific cleanup document.
- [ ] Revisit relevant entries in `Docs/TODO.md`; it is a backlog, not a
  release contract.
- [ ] Update the TOC version only when preparing the release.
- [ ] Update `.pkgmeta` or embedded-library revisions only when those
  dependencies actually changed.
- [ ] Run available Lua syntax checks and `git diff --check`.
- [ ] Follow the release workflow in `AGENTS.md`. Do not commit, tag, or push
  during release preparation.
