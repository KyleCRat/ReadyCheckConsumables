# ChatReport Refactor Plan

## High Priority

- `ChatReport.lua:91-426` — Roster loop duplicated across `reportFood`,
  `reportFlasks`, `reportAugments`, `reportBuffs`. Extract a shared
  `forEachRosterMember(maxGroup, callback)` iterator.
- `ChatReport.lua` — 220-char message chunking logic duplicated in three report
  functions. `reportBuffs` doesn't chunk at all and could exceed chat limits
  for large raids. Extract a shared `sendChunked` helper.
- `ChatReport.lua:544-548` — ready-check election uses an uncancelled
  `C_Timer.After(1, onReadyCheck)`. Add a generation token so overlapping or
  back-to-back ready checks cannot produce duplicate or stale reports.
