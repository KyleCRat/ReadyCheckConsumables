# TODO

## Fixes

- Evaluate debouncing consumables frame `UNIT_AURA` updates to roughly once per
  second. Measure whether reduced refresh churn during test/ready-check frames
  is worth the added latency and complexity.
- Consider replacing the long `RaidFrame.lua` event `if` chain with a dispatch
  table before adding more raid-frame lifecycle events.
- After one or two releases, consider replacing the legacy `"OIL"` raid-frame
  addon message type with a temp-weapon-enchant-specific message type and
  remove legacy `"OIL"` receive handling. It is currently kept so older RCC
  clients can still read remaining time and item ID from newer clients while
  newer clients can still read older clients.
