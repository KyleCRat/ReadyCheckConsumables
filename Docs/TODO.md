# TODO

## Changes
- Update health pots and dmg potions to show all items in bags in flyout to allow clicking and choosing a cached item for the macro to use. 
- Macros should use the priority finder to pick the next best item to use in the macro. This is slightly diff than what we do now. If we use a R2 Thal oil, we should prio using the same type of oil and a diff quality before a higher quality diff type oil. Damage pots should do the same, use a lower quality light potion before a R2 recklessness if light is cached. This will likey require a re-work of our db's as this includes fleeting flasks and damage pots. A R1 fleeting dmg pot should be used before a R2 non-fleeting even if the R2 non-fleeting is cached. R2 fleeting should be used before R1 fleeting, even if R1 fleeting is in bag and R2 non-fleeting is cached.
- Review all priority logic. 
- we are now sharing consumable/xyz.lua logic between two modules. Macros and ConsumeableFrame. Should we move these into the modules directory itself now that they are defining logic for more than one module?

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
