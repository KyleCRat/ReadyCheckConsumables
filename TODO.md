# TODO

## Features

- After the ConsumableFrame refactor, consider showing multiple available
  consumable choices as stacked buttons, such as separate weapon enchants or
  feast/personal food options, so players can pick the item they want instead
  of relying on one selected best item.

## Fixes

- Evaluate debouncing consumables frame `UNIT_AURA` updates to roughly once per second. Measure whether reduced refresh churn during test/ready-check frames is worth the added latency and complexity.
