# TODO

## 12.1.0 / Interface 120100 Upgrade

- [ ] Add Interface `120100` to `ReadyCheckConsumables.toc` after confirming it
  against the final 12.1.0 build. Keep the existing live Interface values while
  both clients are supported.
- [ ] Find and verify the remaining data for the provisional 12.1 consumables.
  RCC currently includes only the supplied PTR item IDs; combat-potion quality
  metadata is intentionally unset until it can be confirmed.
  - Concentrated Silvermoon Health Potion: item `271884`, use spell `1295247`.
  - Liquid Luster: item `271887`, use spell `1295132`.
  - Alluring Nostrum: item `271890`, use spell `1295015`.
  - Identify every quality rank, priority order, and fleeting or other alternate
    item variant.
  - Confirm final effects, shared cooldown categories, and any separate aura
    spell IDs on a later PTR build or the final live client.
- [ ] Normalize cached aura data field by field. Retain `icon`, `name`,
  `duration`, `expirationTime`, and `auraInstanceID` only when each value is
  public; do not assume that a public spell ID makes the other fields safe.
- [ ] Make `FoodAuras.GetType` reject a secret icon before using it as a key in
  `foodAuraIconTypes`, and make the Vantus presenter omit boss-name formatting
  when the aura name is secret.
- [ ] Recheck aura instance IDs immediately before
  `SetUnitBuffByAuraInstanceID` tooltip calls and skip the aura tooltip when the
  current value or access context is restricted.
- [ ] Update managed-macro limit selection to prefer
  `Constants.MacroConsts.MAX_ACCOUNT_MACROS` and
  `Constants.MacroConsts.MAX_CHARACTER_MACROS`, then the legacy globals, then
  the existing numeric fallbacks. Resolve the limits through one helper.
- [ ] Run a restricted-context PTR test with Lua errors enabled: initiate a
  ready check in an active Mythic+ challenge, change food/flask/augment auras
  between pulls, hover aura-backed cells, enter combat, and verify that both
  frames hide without secret-value or aura-access errors.
- [ ] Repeat the restricted-aura checks in a raid encounter and PvP match when
  practical, then re-export and re-audit the final 12.1.0 live build.
- [ ] Optional: evaluate `C_Spell.GetLastCategoryCooldownSource` for a future
  combat/healing-potion cooldown display. Do not implement it until RCC has a
  reliable source for the relevant spell-category IDs and secret cooldown
  returns are handled.

## Review

- Review consumable priority/data structures before extracting shared selector
  helpers. Combat potions and flasks now use family/variant metadata, but wait
  until food, augments, weapon enchants, and other consumables are reviewed so a
  shared helper follows real common behavior instead of forcing everything into
  the first family-based shape.
- After one or two releases, consider replacing the legacy `"OIL"` raid-frame
  addon message type with a temp-weapon-enchant-specific message type and
  remove legacy `"OIL"` receive handling. It is currently kept so older RCC
  clients can still read remaining time and item ID from newer clients while
  newer clients can still read older clients.
- Update managed augment rune macros when the "Prefer Unlimited Augment Runes"
  setting changes. The setting currently refreshes the visible consumables frame,
  but does not schedule `RCC.ConsumableMacros` to rewrite existing augment
  macros until another bag, zone, spell, equipment, or macro event fires.
- Add item:253011 Brawler's Guild health pot to use first if available?
