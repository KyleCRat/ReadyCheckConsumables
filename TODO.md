# TODO

## Fixes

- Evaluate debouncing consumables frame `UNIT_AURA` updates to roughly once per
  second. Measure whether reduced refresh churn during test/ready-check frames
  is worth the added latency and complexity.
- Simplify the consumable button registry so button identity does not depend on
  both numeric array indexes and keyed lookup aliases. The current `buttons[i]`
  plus `buttons[def.key]` shape works, but it makes layout order, definition
  order, and consumer access harder to reason about as flyout choice buttons
  expand the button model.
- After one or two releases, consider replacing the legacy `"OIL"` raid-frame
  addon message type with a temp-weapon-enchant-specific message type and
  remove legacy `"OIL"` receive handling. It is currently kept so older RCC
  clients can still read remaining time and item ID from newer clients while
  newer clients can still read older clients.
