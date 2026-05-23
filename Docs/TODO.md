# TODO

## Fixes

- Please review the [@ConsumableFrameTooltips.lua (56:64)](file:///D:/World%20of%20Warcraft/_retail_/Interface/AddOns/ReadyCheckConsumables/Modules/ConsumableFrame/ConsumableFrameTooltips.lua#L56:64) action type circular depency, can we fix this with load order rather than hiding circular depency via a real time load?

## Review
- Review consumable priority/data structures before extracting shared selector
  helpers. Combat potions and flasks now use family/variant metadata, but wait
  until food, augments, weapon enchants, and other consumables are reviewed so a
  shared helper follows real common behavior instead of forcing everything into
  the first family-based shape.
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
