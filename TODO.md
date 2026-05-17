# TODO

## Features

- Consumable frame should also have an idea of "isBad" timing and show timers
  are red if they are soon to expire.
- Define shared expiration severity rules for consumables and reports. The
  consumable frame, raid frame, and chat report currently each define their own
  "is bad soon" timing for button/icon/report state. Move those thresholds into
  one shared definition that each module consumes. `ConsumableFrameButtons.lua`
  currently carries `expireWarnSeconds` in button definitions, which makes
  button construction own consumable severity policy; move that ownership as
  part of this cleanup. (Maybe even understand a different isBad depending on
  content type. Dungeons need 30+ minutes for a run, raid needs approx 10 min
  for a boss fight.)

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
