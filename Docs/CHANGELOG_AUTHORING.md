# Update highlights and bundled notes

`CHANGELOG.md` remains the full changelog. The game cannot read that Markdown
file, so a development/release command converts one section into
`Modules/Changelog/ReleaseNotes.lua`. Do not edit the generated Lua by hand.

## During development

Update the existing Unreleased entry when a change affects players. Keep small
adjustments to the same feature in its existing bullet. Regenerate the preview:

```powershell
lua Libs/LibChangelog-1.0/tools/generate.lua CHANGELOG.md Modules/Changelog/ReleaseNotes.lua Unreleased
```

Use `/changelog` to preview the latest notes from all registered addons, including
read or opted-out updates. **Show update highlights** on RCC's main settings page
opens RCC's highlights; the **Changelog** subcategory is also available. Unreleased
never opens automatically or changes the acknowledged release.

`Modules/Changelog/Highlights.lua` contains only the few changes worth calling
out. Its entries are keyed by the same version as the bundled notes. Each
entry can have a title, body, emphasis, artwork, and LMS controls. Use `featured`,
`important`, or `requested` (User Requested) for emphasis, or omit it. The
library's README documents the schema. Do not copy every changelog bullet into
highlights.

For a setting control, read through the normal setting owner and call its
existing apply function. Extract a shared apply function if needed; do not put
a second implementation in the highlight. Controls use the currently selected
profile. Profile changes/reset/copy cancel
uncommitted input drafts. Merely opening the page never changes settings.

## During the next release preparation

1. Finalize the release heading and TOC version as usual.
2. Rename the `Unreleased` highlight key to that exact release ID. Keep only
   the current release's curated entries; the Markdown retains release history.
3. Generate notes for the release, using the exact heading (no brackets):

   ```powershell
   lua Libs/LibChangelog-1.0/tools/generate.lua CHANGELOG.md Modules/Changelog/ReleaseNotes.lua VERSION
   lua Libs/LibChangelog-1.0/tools/generate.lua CHANGELOG.md Modules/Changelog/ReleaseNotes.lua VERSION --check
   ```

4. Review the generated version/date/content and include the generated Lua and
   highlights in the release commit. A missing highlight key is valid (notes
   only); stale generated notes or an Unreleased production bundle is not.

The generator supports headings, paragraphs, wrapped bullets, code fences,
inline code/bold, and Markdown links. Avoid complex Markdown tables in release
notes; use prose or bullets that also read clearly in game.

## Library packaging

`Libs/LibChangelog-1.0` is currently a self-contained development embed, not a
published external. Before publishing RCC with it, create the independent
LibChangelog repository, test and release it, then convert this directory to a
submodule and add the matching released tag to `.pkgmeta`. Do not invent a tag
before the library has been published. LibStub and LMS are supplied by RCC.

Notification data is in `ReadyCheckConsumablesDB.changelog`, outside all
profiles, accessed through its own LibSimpleDB instance. Profile operations
must leave it alone. The library does not own SavedVariables or require
LibSimpleDB; the RCC bridge supplies get/set callbacks.

## In-game checks

- Preview the window and Settings page at different UI scales; inspect long
  notes, collapsed/expanded layout, mouse scrolling and keyboard navigation.
- Change a highlight checkbox and confirm its normal Settings control and
  personal display update. Open a different profile and confirm the values
  change, without copying settings between profiles.
- Use the library's optional example registration for a second addon. The first
  page should be visible while both entries remain NEW. Select, scroll or use a
  control to clear only that entry. Dismiss all/X/Escape dismiss the whole batch.
- Run `/changelog` after dismissing updates or disabling automatic notices. All
  registered addons should still appear, without changing notification consent.
  Run it with a single-addon popup already open to switch to the complete list.
- Test Escape while editing text, using a dropdown, and editing a color in the
  library example; that interaction should close before the entire window.
- Interrupt an automatic popup with combat, travel, a cinematic and a ready
  check. Unread updates should remain pending, and the window should resume
  when safe. Late registrations must not replace the open batch.
- Disable automatic notices, reload, and re-enable: the installed release must
  not immediately pop up again. A different release ID should notify normally.

Do not alter live SavedVariables to simulate updates; use a separate development
registration/storage table or a disposable test account.
