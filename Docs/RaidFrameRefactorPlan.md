# Raid Frame Refactor Plan

## Goal

Reduce `RaidFrame.lua` from a large all-in-one implementation into a small coordinator that owns frame lifecycle and event wiring, while moving reusable UI creation, row rendering, column rules, and shared data handling into focused modules.

The refactor should preserve current behavior while making future changes to raid-frame columns and controls require edits in fewer places.

## Current Pain Points

- Column behavior is duplicated across width math, X offsets, title-bar icons, row creation, row rendering, and title summary logic.
- Row creation and row rendering are large enough to hide the actual ready-check lifecycle.
- Durability and weapon oil sharing are mixed into the visual frame file.
- Title-bar construction, countdown progress, ready counts, finished summaries, and column health checks are all in `RaidFrame.lua`.
- State is spread across closure locals, which makes extraction awkward.

## Target Shape

Keep `RaidFrame.lua` responsible for:

- Creating the top-level `RCRaidFrame`.
- Wiring ready-check and combat events.
- Calling roster/aura scans.
- Calling row/title refresh APIs.
- Coordinating show, hide, scale, position, and timers.

Move implementation details into smaller modules loaded before `RaidFrame.lua`.

## Proposed Modules

### `RaidFrameColumns.lua`

Own the raid-frame column model.

Each column descriptor should define the pieces that are currently scattered through the file:

- Key/name.
- Width and spacing behavior.
- Default icon.
- Tooltip fallback data.
- Whether it has a timer text field.
- Row creation metadata.
- Row render function or renderer key.
- Title-bar "bad" predicate.

This is the highest-value refactor because it removes the need to update multiple distant sections when adding or changing a column.

### `RaidFrameRows.lua`

Own row widget construction and row rendering.

Likely responsibilities:

- Tooltip overlay creation.
- Missing-icon background creation.
- Pre-allocating the 40 rows.
- Creating icon/time/name/durability cells from column descriptors.
- Rendering one row from member data.
- Hiding unused rows.

Candidate public API:

```lua
local rows = RCC.RaidFrameRows.Create(parent, columns, state, options)
rows:Refresh(index)
rows:RefreshAll()
rows:HideUnused()
```

### `RaidFrameColumnRenderers.lua`

Own reusable per-column cell widget creation and, later, cell rendering.

Likely responsibilities:

- Tooltip overlay creation.
- Missing-icon background creation.
- Timed cell creation.
- Icon cell creation.
- Raid-buff cell creation.
- Durability cell creation.
- Future renderer-specific `RenderCell` implementations.

Column descriptors should point to renderer functions, so `RaidFrameRows.lua` can iterate columns without knowing the mapping between column type and widget construction.

### `RaidFrameSharing.lua`

Own cross-player data sharing for durability and weapon oil.

Likely responsibilities:

- Local durability scanning.
- Local weapon oil scanning.
- Broadcast durability.
- Broadcast weapon oil.
- Parse RCC addon messages.
- Parse compatible MRT durability messages.
- Store durability and oil data by full player name.
- Reset transient shared data at ready-check start.

Candidate public API:

```lua
local sharing = RCC.RaidFrameSharing.Create({
    onDataChanged = scheduleAddonRefresh,
})

sharing:Reset()
sharing:BroadcastDurability()
sharing:BroadcastOilStatus()
sharing:HandleAddonMessage(prefix, message, sender)
sharing:GetDurability(playerKey)
sharing:GetOil(playerKey)
```

### `RaidFrameTitleBar.lua`

Own title-bar widget construction and title-bar updates.

Likely responsibilities:

- Create background, progress texture, count text, timer text, and column summary icons.
- Refresh per-column ready/not-ready summary icons.
- Update ready response count.
- Show finished summary.
- Start and stop progress countdown.

Candidate public API:

```lua
local titleBar = RCC.RaidFrameTitleBar.Create(parent, columns, state, options)
titleBar:RefreshColumns()
titleBar:UpdateReadyCount()
titleBar:ShowFinishedSummary()
titleBar:StartProgress(duration)
titleBar:StopProgress()
```

## State Refactor

Before deep extraction, introduce a single state table in `RaidFrame.lua`:

```lua
local state = {
    members = {},
    unitToIndex = {},
    rcStatus = {},
    activeCount = 0,
    readyAnnounced = false,
}
```

This gives extracted modules a stable shared context without relying on many hidden closure locals.

## Suggested Order

1. Introduce the `state` table while keeping behavior in `RaidFrame.lua`.
2. Extract `RaidFrameColumns.lua` and update width/position/title/row code to use descriptors.
3. Extract row creation and rendering into `RaidFrameRows.lua`.
4. Extract durability and oil sharing into `RaidFrameSharing.lua`.
5. Extract title-bar construction and progress/count logic into `RaidFrameTitleBar.lua`.
6. Simplify `RaidFrame.lua` around orchestration and event dispatch.

## Small Cleanups To Include

- Replace hardcoded raid-buff column counts with `#db.raidBuffDefs`.
- Recheck whether `COL_RAIDBUFF` is still needed after the column model exists.
- Make `OnReadyCheckConfirm` use the same row refresh path as other updates instead of manually changing the ready-check icon.
- Keep all extracted files Lua 5.1 compatible.
- Add new files to `ReadyCheckConsumables.toc` before `RaidFrame.lua`.

## Verification Checklist

- `/reload` has no Lua syntax or load-order errors.
- Raid frame opens on a real ready check.
- `/rcc test` still renders player and fake rows.
- Scale popup still syncs with settings and persists changes.
- Food, flask, oil, augment, Vantus, raid buffs, and durability render as before.
- Title-bar column summaries still switch between ready and not-ready correctly.
- Ready/not-ready/AFK finished summary still works.
- Durability and oil data from other RCC users still updates rows.
- MRT durability compatibility still works.
- Frame hides on combat and unregisters transient events on hide.

## Phase 2: Column/Row Boundary Tightening

The first refactor pass split `RaidFrame.lua` into coordinator, column layout, row rendering, broadcast, and title-bar modules. The next goal is to make columns the owner of per-cell behavior while keeping rows as the unit of update.

### Desired Boundary

`RaidFrame.lua` should own:

- Ready-check lifecycle and event wiring.
- Roster/aura scan timing.
- Row refresh timing.
- All-ready announcement decisions.
- Frame show/hide, position, scale, and timers.

`RaidFrameRows.lua` should own:

- Row-level UI creation.
- Ready-check status icon rendering.
- Class background rendering.
- Player name rendering.
- Showing/hiding rows.
- Iterating column descriptors when creating and rendering cells.

`RaidFrameColumns.lua` should own:

- Column order.
- Column layout and positioning.
- Cell creation for each column.
- Cell render behavior for each column.
- Tooltip/default icon metadata.
- Title-summary bad predicates.

Rows remain the unit of update: when one player changes, `RaidFrame.lua` refreshes that player row. Columns are the per-cell strategies used during that row refresh.

### Column Data Direction

During the early Phase 2 checkpoints, some descriptors still contain string field names such as `auraHasField`, `auraTimeField`, `auraIconField`, and `auraIDField`. These are temporary compatibility links back to the current hardcoded aura scan result shape.

The desired end state is normalized per-column data:

```lua
member.columnData[column.key] = {
    has = true,
    time = 3200,
    iconID = 12345,
    auraID = 987,
}
```

Aura-backed columns should eventually define how they collect or match their own data, for example through a descriptor function such as `CollectAura(result, aura, context)` or equivalent. This makes the column definition explain its data source instead of relying on unrelated string field names created elsewhere.

Any column-driven aura collection must keep the existing WoW 12.x secret-value safety rules: skip aura processing when `aura.spellId` is secret, do not index tables with secret values, and re-check stored aura IDs before using them for tooltips.

### Phase 2 Checkpoints

1. Move title-summary predicates into column descriptors.
   - Add `IsBad(member, context)` to each display column.
   - Replace `RaidFrame.lua:isBad()` branching with descriptor calls.
   - Keep the title bar display-only: `RaidFrame.lua` still computes column states, then passes simple state to `RaidFrameTitleBar.lua`.

2. Introduce one canonical ordered column list.
   - Add `layout.columns` as the primary ordered list.
   - Keep `timedColumns`, `iconColumns`, and `raidBuffColumns` temporarily only if needed during migration.
   - Ensure title icons and row cells can iterate the same column order.

2.1. Migrate column definitions to typed descriptors.
   - Keep `layout.columns` as an ordered array, not a dictionary, so display order is explicit and stable in Lua 5.1.
   - Add a private `COLUMN_TYPE` table in `RaidFrameColumns.lua`, with renderer-shape values such as `timed`, `icon`, `raidBuff`, and `durability`.
   - Add a private `DATA_SOURCE` table in `RaidFrameColumns.lua`, with data-access values such as `aura`, `oil`, `raidBuff`, and `durability`.
   - Give every column descriptor a `columnType` and `dataSource`.
   - Define the frame left-to-right directly in `columns`, instead of building separate `timedColumns`, `iconColumns`, and `raidBuffColumns` first.
   - Add field metadata needed by future renderer dispatch, such as `auraHasField`, `auraTimeField`, `auraIconField`, `auraIdField`, `timeField`, `iconField`, `overlayField`, `index`, and `spellID`.
   - Move repeated title-summary logic into shared predicate helpers where practical.
   - Update title-summary calls to pass the column into `IsBad(member, context, column)` so shared predicates can read descriptor metadata.
   - Temporarily derive `timedColumns`, `iconColumns`, and `raidBuffColumns` from `columns` so `RaidFrameRows.lua` can keep working unchanged during this checkpoint.

3. Move cell creation to column-type dispatch.
   - Add a column-type renderer registry, preferably in `RaidFrameColumnRenderers.lua`.
   - Each renderer type should expose a cell creation function, for example `CreateCell(row, column, layout, options)`.
   - Replace the separate `timedColumns`, `iconColumns`, and `raidBuffColumns` creation loops with one loop over `layout.columns`.
   - Dispatch cell creation by `column.columnType`; do not let data source details decide widget shape.
   - Have column descriptors own the selected `CreateCell` function so `RaidFrameRows.lua` only calls `column.CreateCell(row, column, layout, options)`.
   - Remove the temporary derived `timedColumns`, `iconColumns`, and `raidBuffColumns` if no consumers remain after creation dispatch moves to `layout.columns`.
   - Keep row-level ready-check icon, class background, and name outside column-type renderers.

4. Move cell rendering to column-type dispatch.
   - Extend `RaidFrameColumnRenderers.lua` with render functions, for example `RenderCell(row, member, column, context)`.
   - Replace hardcoded food/flask/oil/augment/Vantus/raid-buff/durability render calls in `Rows.ApplyData`.
   - Keep `Rows.ApplyData` responsible for row-level rendering and column iteration.
   - Use `column.dataSource` to select or guide the data extraction path where columns share the same renderer shape but read from different data.
   - Keep column-specific data access driven by descriptor metadata instead of hardcoded row field names where possible.

5. Normalize per-column member data.
   - Add `member.columnData` keyed by `column.key`.
   - Populate normalized data objects for food, flask, oil, augment, Vantus, raid buffs, and durability.
   - Move aura-backed collection toward column-owned functions or matcher definitions instead of hardcoded `hasFood`, `foodTime`, `foodIconID`, etc. fields.
   - Keep aura scanning secret-value safe: skip secret `aura.spellId` values before reading dependent aura fields, and guard any stored aura IDs before tooltip use.
   - Once normalized data is in place, update title predicates and renderers to read `member.columnData[column.key]` where practical.

6. Remove temporary column buckets and remaining legacy branching.
   - Remove `COL_FOOD`, `COL_FLASK`, `COL_OIL`, `COL_AUGMENT`, `COL_VANTUS`, and `COL_DURABILITY` once descriptors own title predicates.
   - Confirm the temporary derived `timedColumns`, `iconColumns`, and `raidBuffColumns` are gone once row creation and rendering use `layout.columns`.
   - Remove temporary string field metadata such as `auraHasField`, `auraTimeField`, `auraIconField`, and `auraIDField` once normalized `member.columnData` replaces the old aura result shape.
   - `RaidFrame.lua` should not know specific consumable column keys except for assembling context.

7. Tighten row render context.
   - Revisit the broad `rowRenderContext` table after descriptors own rendering.
   - Prefer grouped context if it improves readability, for example:

```lua
local rowRenderContext = {
    readyCheck = {
        state = state,
        pending = RC_PENDING,
        notReady = RC_NOT,
        textures = RC_TEXTURES,
    },
    shared = {
        oilData = oilData,
        durabilityData = durabilityData,
    },
    rules = {
        expireWarnSeconds = EXPIRE_WARN_SECONDS,
        noDuration = NO_DURATION,
    },
}
```

8. Reassess module size after behavior moves.
   - If `RaidFrameColumns.lua` becomes too large, split shared render helpers into a follow-up module such as `RaidFrameColumnRenderers.lua`.
   - Do not split preemptively; only split if column descriptor size makes the module harder to scan.

### Phase 2 Verification Additions

- Title summary icons still show ready/not-ready state correctly for every column.
- Adding or changing one display column should require edits primarily in `RaidFrameColumns.lua`.
- `Rows.ApplyData` should still refresh one row at a time.
- Food/flask expiration warnings still display correctly.
- Oil unknown/missing/N/A states still display correctly.
- Durability threshold summary still behaves correctly.

## Phase 3: RaidFrame Coordinator Cleanup

Phase 2 made the column/row boundary much cleaner: columns now own column data, predicates, and per-cell behavior, while rows update one player at a time by iterating the ordered column list. Phase 3 should shift the focus back to `RaidFrame.lua`.

The goal is to make `RaidFrame.lua` a small coordinator that owns ready-check lifecycle decisions and event wiring, without also owning member construction, test-data population, row/title refresh mechanics, or frame-control setup details.

### Review Findings Before Phase 3

A review after the `row.cells[column.key]` cleanup did not find more `timeField` / `iconField` / `overlayField`-style widget string bridges. The remaining smells are smaller, but they are worth carrying into Phase 3 so the next module extraction does not preserve old coupling.

#### Raid-buff icon ownership has been cleaned up

This was handled as a small cleanup before the larger Phase 3 extractions.

The current target shape is now in place:

- Raid-buff column descriptors own their fallback/default icon ID.
- `RaidFrameRows.lua` no longer receives a separate `raidBuffIcons` option.
- `RaidFrameColumnRenderers.lua` creates raid-buff cells from `column.iconID`.
- `RaidFrame.lua` no longer knows which columns are raid-buff columns.

#### Test data is now column-driven

This was handled during the member extraction checkpoint.

The current target shape is now in place:

- `RaidFrameTest.lua` generates fake member scenario inputs such as class, online/dead state, durability, and oil state.
- `RaidFrameMembers.lua` creates baseline fake `columnData` through `Columns.CreateColumnData(layout)`.
- Test aura and raid-buff values are applied by iterating `layout.columns`, so new columns receive their default shape automatically.
- `/rcc test` no longer manually mirrors every normalized `member.columnData` key.

#### `columnType` and `dataSource` need a clear role

Column descriptors currently include `columnType` and `dataSource`. `dataSource` now helps drive `/rcc test` column-data generation, but most runtime behavior is still selected by direct function references on the descriptor:

- `CreateCell`
- `RenderCell`
- `CollectAura`
- `SyncData`
- `IsBad`

That direct behavior ownership is good. The metadata should still earn its place. Good uses are:

- Test-data default generation.
- Column descriptor validation.
- Future member-data collection helpers.
- Human readability when scanning column definitions.

Avoid adding a second dispatch system that fights the direct function references. `columnType` should remain renderer-shape metadata, and `dataSource` should remain data-origin metadata.

#### `Columns.CreateColumnData(layout)` now has a consumer

`RaidFrameMembers.lua` now uses this helper for baseline fake member data. Keeping it public is justified while member/test construction lives outside `RaidFrameColumns.lua`.

#### Duplicate `getColumnData(member, column)` helpers are acceptable for now

Both columns and renderers have small local helpers for reading `member.columnData[column.key]`. This is not urgent. Only deduplicate if Phase 3 creates a natural shared owner for normalized member-column data.

### Current State

The raid-frame files now live under `Modules/RaidFrame/`, keeping the addon root cleaner and preserving explicit TOC load order.

`RaidFrame.lua` still owns too many implementation details:

- Refresh call sequencing between member data changes, rows, and title summary.
- Ready-check lifecycle and event handling.

Phase 3 should remove those non-lifecycle concerns in small testable checkpoints.

### Desired Boundary

`RaidFrame.lua` should own:

- Creating the top-level frame object.
- Creating shared state/context.
- Wiring events.
- Deciding when ready-check lifecycle actions happen.
- Starting/stopping timers and progress.
- Calling member/refresh/control modules.
- All-ready announcement decisions and finished-summary timing.

`RaidFrame.lua` should not own:

- How a member table is built.
- How fake test members are copied into state.
- How column data is scanned or external data is synced.
- How rows and title-bar summary states are rendered.
- How scale/close/position controls are constructed.

### Proposed Modules

#### `RaidFrameMembers.lua`

Own member-state construction and member data updates.

Likely responsibilities:

- Scan the roster into `state.members`.
- Populate test members for `/rcc test`.
- Refresh one member from a unit token on `UNIT_AURA`.
- Keep roster/member table shape consistent.

Candidate public API:

```lua
Members.ScanAll(state, layout, context)
Members.PopulateTestData(state, layout, context, broadcast)
Members.RefreshFromUnit(state, unit, layout, context)
```

`RaidFrame.lua` should still decide when these are called.

#### Existing row/title modules should own refresh behavior

After reviewing the proposed `RaidFrameRefresh.lua` boundary, the extra module does not earn its abstraction. A function named `Refresh.RefreshRow()` is less discoverable than row refresh behavior living in `RaidFrameRows.lua`, and title summary rendering belongs near the title-bar widget if it can be moved cleanly.

Use the existing modules instead:

- `RaidFrameRows.lua` owns row creation, one-row updates, all-row updates, unused-row hiding, and row-area height calculation.
- `RaidFrameTitleBar.lua` owns title-bar creation, column summary rendering, ready count display, finished summary display, and progress display.
- `RaidFrame.lua` still decides when row refresh and title refresh happen, and it keeps ready-check lifecycle decisions such as all-ready announcement and finished-summary timing.

Likely row API:

```lua
Rows.RefreshRow(row, member, layout, context)
Rows.RefreshAll(rows, state, layout, context)
```

Likely title API:

```lua
titleBar:RefreshFromMembers(state.members, state.activeCount, layout, context, {
    ready    = RC_TEXTURES[RC_READY],
    notReady = RC_TEXTURES[RC_NOT],
})
```

Keep the data/render boundary explicit:

- `RaidFrameMembers.lua` mutates member data, including roster scans and `UNIT_AURA` unit refreshes.
- `RaidFrameRows.lua` may call column external-data sync hooks before row rendering so oil/durability broadcasts are reflected.
- `RaidFrameRows.lua` and `RaidFrameTitleBar.lua` should not call aura scanning APIs or construct member tables.
- Do not add a generic refresh/orchestration module unless repeated coordination logic remains after row and title responsibilities move.

#### `RaidFrameControls.lua`

Own frame controls and positioning setup.

Likely responsibilities:

- Create the scale popup button.
- Create the close button.
- Wire dragging and saved position.
- Restore saved position.
- Sync scale from SavedVariables.

Candidate public API:

```lua
local controls = Controls.Create(frame, options)
controls:RestorePosition()
controls:SyncScale()
```

The controls module can depend on `RCC.UI`, but should not know ready-check lifecycle details.

### Phase 3 Checkpoints

0. Completed: clean up raid-buff default icon ownership before larger extraction.
   - Raid-buff fallback icon resolution now lives in raid-buff column descriptors.
   - `RaidFrame.lua` no longer passes a `raidBuffIcons` option into `Rows.Create`.
   - `RaidFrameColumnRenderers.lua` creates raid-buff cells from `column.iconID`.

1. Completed: extract member data handling into `RaidFrameMembers.lua`.
   - Roster scanning moved out of `RaidFrame.lua`.
   - Test data population moved out of `RaidFrame.lua`.
   - One-member unit data refresh logic moved out of `RaidFrame.lua` as `Members.RefreshFromUnit`.
   - `RaidFrame.lua` still decides when to scan or refresh.
   - `RaidFrameMembers.lua` does not render rows or title state; callers should refresh rows/title through their existing modules after member data changes.
   - The column model now creates baseline `member.columnData` for test members.
   - `/rcc test` overrides scenario values instead of manually recreating the entire column-data shape.
   - `Columns.CreateColumnData(layout)` is now a real public helper for member/test data creation.
   - `Modules/RaidFrame/RaidFrameMembers.lua` is loaded before `RaidFrame.lua` in the TOC.

2. Completed: move row/title refresh behavior into the existing row and title modules.
   - One-row and all-row update helpers now live in `RaidFrameRows.lua`.
   - `RaidFrameRows.lua` calls column external-data sync hooks before row rendering so oil/durability broadcast updates are reflected.
   - Title-summary state calculation now lives in `RaidFrameTitleBar.lua` without learning ready-check lifecycle decisions.
   - Aura scanning and member construction remain in `RaidFrameMembers.lua`.
   - `Rows.ApplyData` remains as the low-level row renderer under the public row refresh API.
   - No generic refresh/orchestration module was added.
   - All-ready announcement and finished-summary decisions remain in `RaidFrame.lua`.

3. Completed: extract frame controls and positioning into `RaidFrameControls.lua`.
   - Scale popup button creation moved out of `RaidFrame.lua`.
   - Close button creation moved out of `RaidFrame.lua`.
   - Drag handlers, position saving, and saved-position restore moved out of `RaidFrame.lua`.
   - Secure close-button behavior is unchanged.
   - `Modules/RaidFrame/RaidFrameControls.lua` is loaded before `RaidFrame.lua` in the TOC.

4. Completed: reassess `RaidFrame.lua`.
   - Reviewed remaining locals and helper functions.
   - Removed the progress-bar pass-through helper; `RaidFrame.lua` now calls `titleBar:StartProgress(duration)` directly.
   - Progress width ownership moved into `RaidFrameTitleBar.lua`, alongside the progress texture and timer behavior.
   - Event dispatch remains in `RaidFrame.lua` while the extracted boundaries settle.

5. Reassess `RaidFrameColumns.lua`.
   - The file is intentionally organized by column context now.
   - Column descriptors now define `columnType` and `dataSource` instead of repeating `CreateCell` and `RenderCell` function references.
   - `RaidFrameColumns.lua` resolves cell creation from `columnType` and cell rendering from `columnType` plus `dataSource`.
   - Shared `COLUMN_TYPE` and `DATA_SOURCE` constants are exposed for other raid-frame modules that need to inspect descriptor metadata.
   - Do not split it unless the column sections become hard to navigate after Phase 3.
   - Prefer preserving "one column section contains the behavior for that column" over splitting by function type.

### Phase 3 Verification Additions

- `/reload` has no load-order errors after each new module is added to the TOC.
- `/rcc test` still renders fake members and drives ready/not-ready responses.
- Real ready checks still scan roster members and update one member on `UNIT_AURA`.
- Oil and durability broadcasts still update rows after addon messages.
- Title-bar column summaries still update after one-row and all-row refreshes.
- Scale, close, dragging, and saved position behavior still work after controls move.
- `RaidFrame.lua` should shrink and read primarily as lifecycle/event orchestration.

## Phase 4: Cell Ownership Review

Phase 3 made `columnType` and `dataSource` real metadata: descriptors no longer repeat `CreateCell` and `RenderCell`, and `RaidFrameColumns.lua` now resolves renderer behavior from those fields.

That is cleaner than per-column function duplication, but it also exposed a naming and ownership question. The actual rendered UI object is the intersection of a row and a column: a cell. A module named `RaidFrameColumnRenderers.lua` may now be less intuitive than a cell-focused owner.

### Goal

Review whether cell widget creation and rendering should move behind a clearer `RaidFrameCells.lua` boundary.

The desired end state, if this earns its place, is:

- `RaidFrameColumns.lua` owns column descriptors, data collection, external data sync, and title-summary rules.
- `RaidFrameRows.lua` owns row creation and row-level refresh flow.
- `RaidFrameCells.lua` owns cell widget creation, cell render dispatch, common icon/time/overlay behavior, and the metadata that describes cell shape.

### Questions To Answer

1. Should `columnType` be renamed to `cellType`?
   - The value describes the shape of the cell widget (`timed`, `icon`, `raidBuff`, `durability`), not the business meaning of the column.
   - A descriptor reading `cellType = Cells.TYPE.TIMED` may be clearer than `columnType = COLUMN_TYPE.TIMED`.
   - Kyle: Likey no, as all the cells in the same column are the same. this is more of a column type than a cell type. The column decides if it needs to be a timed, icon, etc.

2. Should `DATA_SOURCE` live with cells or columns?
   - Rendering currently needs both widget shape and data source to select the display function.
   - Test-data generation also uses `dataSource`, so moving it must not make member/test construction depend on UI details in a confusing way.

3. Should `RaidFrameColumnRenderers.lua` be renamed/reworked into `RaidFrameCells.lua`?
   - A rename is only useful if the module owns the complete cell boundary, not just the same functions under a new name.
   - Avoid creating a "Cell object" with methods unless it removes real duplicated widget behavior.

4. Can `RaidFrameColumns.lua` become easier to scan?
   - Column descriptors should ideally say what the column is and how its data is collected.
   - Cell widget shape and render dispatch should not distract from column rules if a cell module can own that cleanly.

### Candidate Shape

```lua
local Cells = RCC.RaidFrameCells

local foodColumn = {
    cellType   = Cells.TYPE.TIMED,
    dataSource = Cells.DATA_SOURCE.AURA,
    key        = "food",
    ...
}
```

Possible `RaidFrameCells.lua` API:

```lua
Cells.Create(row, column, layout, options)
Cells.Render(row, member, column, context)
Cells.TYPE.TIMED
Cells.DATA_SOURCE.AURA
```

Rows would call `Cells.Create` / `Cells.Render` directly, while columns would only reference cell metadata constants.

### Constraints

- Do not add a new abstraction if it only renames existing wrappers.
- Keep cell renderers Lua 5.1 compatible.
- Preserve the current row cell storage shape unless changing it clearly improves readability:

```lua
row.cells[column.key] = {
    icon = ...,
    overlay = ...,
    timeText = ...,
}
```

- Keep food's Well Fed vs Eating/Drinking selection in column data logic, not the renderer.
- Keep tooltip secret-value safeguards in the cell/rendering layer.

### Verification Additions

- `/rcc test` still renders every cell type.
- Food still shows Eating/Drinking only while Well Fed is missing or in the bad refresh window.
- Oil missing, unknown, N/A, and present states still render correctly.
- Raid-buff tooltip fallbacks still work.
- Durability text and title summary threshold still work.
