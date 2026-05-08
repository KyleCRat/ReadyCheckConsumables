# TODO

## Features

## Fixes

- Update augment rune bag detection to use `RCC.db.augmentItemIDs` instead of fixed item IDs, prioritizing higher `xpac` first and then higher `priority`. Weapon enchant settings only provide default icons while item selection is data-driven by `RCC.db.weaponEnchantItems`; augment settings still assign `RCC.db.augment_item_id` and `RCC.db.unlimited_augment_item_id`, and `updateAugments()` uses those fixed item IDs directly.
- Evaluate debouncing consumables frame `UNIT_AURA` updates to roughly once per second. Measure whether reduced refresh churn during test/ready-check frames is worth the added latency and complexity.
