# TODO

## LibModernSettings Migration

- [ ] Smoke-test every RCC Settings page after the library migration, including
  value editing, dependent disabled states, disabled tooltips, defaults, and
  reopening each canvas.
- [ ] Exercise `LibModernSettings-1.0` from a second addon before its first
  stable release.
- [ ] Tag the reviewed library release and configure RCC's release packaging to
  fetch that exact tag, or verify that the packager recursively includes the
  pinned Git submodule contents.

## 12.1.0 / Interface 120100 Upgrade

- [ ] In the next LibModernSettings release, replace the slider tooltip hooks
  in `Libs/LibModernSettings-1.0/Controls/Slider.lua` with
  `Slider:SetTooltipFunc` and `Settings.InitTooltip`. Release the library
  update, then advance RCC's pinned library commit. Confirm the method exists
  on the live `MinimalSliderWithSteppersTemplate` slider as part of that
  library change.
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
- Add item:253011 Brawler's Guild health pot to use first if available?
