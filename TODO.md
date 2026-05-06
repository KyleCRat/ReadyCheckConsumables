# TODO

## Features

## Fixes

- Fix weapon enchant bag fallback priority. The current highest-`q` scan can prefer older expansion `q = 3` weapon enchant items over current Midnight `q = 2` items; use explicit current-expansion or ordered item priority instead of comparing `q` across all expansions.
- Evaluate debouncing consumables frame `UNIT_AURA` updates to roughly once per second. Measure whether reduced refresh churn during test/ready-check frames is worth the added latency and complexity.
