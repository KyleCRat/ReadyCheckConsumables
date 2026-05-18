# TODO

## Fixes

- Evaluate debouncing consumables frame `UNIT_AURA` updates to roughly once per
  second. Measure whether reduced refresh churn during test/ready-check frames
  is worth the added latency and complexity.
- After the ConsumableFrame refactor, update raid-frame weapon oil sharing to
  broadcast the weapon enchant ID instead of only an item ID, so spell-based
  enchants like Shaman Windfury, Flametongue, and Earthliving can resolve their
  spell tooltip/icon data.
- Simplify the consumable button registry so button identity does not depend on
  both numeric array indexes and keyed lookup aliases. The current `buttons[i]`
  plus `buttons[def.key]` shape works, but it makes layout order, definition
  order, and consumer access harder to reason about as flyout choice buttons
  expand the button model.
- Rename raid-frame temp weapon enchant internals that still use legacy "oil"
  names. Keep addon message/protocol names such as `"OIL"` and `oilData` only
  where backward compatibility or MRT compatibility requires them.
