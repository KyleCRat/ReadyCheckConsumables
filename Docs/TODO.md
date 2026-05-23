# TODO

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
