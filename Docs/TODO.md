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
- Update managed augment rune macros when the "Prefer Unlimited Augment Runes"
  setting changes. The setting currently refreshes the visible consumables frame,
  but does not schedule `RCC.ConsumableMacros` to rewrite existing augment
  macros until another bag, zone, spell, equipment, or macro event fires.
- Add item:253011 Brawler's Guild health pot to use first if available?

## LibPopupSlider

1. **Programmatic `SetValue` triggers `onValueChanged`**
   [LibPopupSlider-1.0.lua](<D:/World of Warcraft/_retail_/Interface/AddOns/ReadyCheckConsumables/Libs/LibPopupSlider/LibPopupSlider-1.0.lua:491>) means initialization/sync calls also fire the callback. That is often fine, but if ported to another app, you may want `SetValue(value, silent)` or `SetValueSilently`.
