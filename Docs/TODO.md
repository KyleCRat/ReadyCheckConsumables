# TODO

## Fixes
- Changing a setting during a test removes all test rows (not critical)

## Features
- Add invisibilty potions Potion of the Hushed Zephyr:191395 - need to find newer and older ones
- (? Maybe, not sure yet) Add Raid Wipe Recovery Items Irresistible Red Button:221945 - These items can be placed before pull to ressurect someone after a wipe

## ConsumableActionBar
- Add icon styling controls (Should have same options as EUI allows for action bars at minimum) (Possibly add to ALL icons so they don't inherit base / eui / dominos look? maybe allow changing between these?)

## Aura Lookup Deep Dive (After Refactors 1-3)

- [ ] After flyout updates, dependency-aware refreshes, and disabled-category
  filtering are implemented and individually confirmed in game, review aura
  acquisition across the addon before deciding on a broader refactor.
  - Compare targeted `C_UnitAuras.GetUnitAuraBySpellID(unit, spellID)` queries
    with shared full scans for each consumer, starting with raid-buff checks.
  - Preserve primary, scroll, and class-specific equivalent aura IDs.
  - Distinguish confirmed absence from an invisible/unavailable unit or a
    secret aura; retain normalized public fields and Unknown semantics.
  - Review unit/event refresh scope, expiration handling, and categories that
    need generic icon matching or several aura types rather than known IDs.
  - Measure representative solo, party, raid, and combat cases before choosing
    targeted queries, shared scans, or caching for each path.

## Performance Follow-ups (After Major Refactors)

Review these after the flyout update cleanup, dependency-aware consumable
refreshes, and disabled-category filtering. The separate aura lookup deep dive
above will determine the scope of any later aura refactor.
Implement and confirm each major step in game before starting the next. Check
whether those changes already resolve a follow-up before adding more caching.

- [ ] Remove redundant state normalization/copying between the controller,
  flyout preparation, and button renderer. Establish the normalization boundary
  and preserve isolation between shared snapshots and combat-prepared states.
- [ ] Avoid reapplying unchanged icon, text, color, and visibility values in
  the shared button renderer. Preserve hover transitions and visual-option
  changes, and build on the existing cooldown and quality-icon caches.
- [ ] Remove the redundant weapon-enchant candidate sort: the generic map
  collector sorts by item ID before the enchant selector sorts by expansion,
  quality, and item ID. Preserve final priority and flyout ordering.
- [ ] Confirm step 3's category-demand filtering in game: Repair now releases
  its candidates, cooldown observations, event subscription, and deadlines when
  neither personal surface requests it. Verify fresh ready-item selection and
  timely cooldown completion after re-enabling, including during a cooldown.

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
  - Liquid Luster: item `271887`, use spell `1295132`.
    - https://www.wowhead.com/item=274763/fleeting-liquid-luster
    - https://www.wowhead.com/item=274764/fleeting-liquid-luster
  - Alluring Nostrum: item `271890`, use spell `1295015`.
    - https://www.wowhead.com/item=274765/fleeting-alluring-nostrum
    - https://www.wowhead.com/item=274766/fleeting-alluring-nostrum
  - Identify every quality rank, priority order, and fleeting or other alternate
    item variant.
  - Confirm final effects, shared cooldown categories, and any separate aura
    spell IDs on a later PTR build or the final live client.

  - Liquid Luster: item `271887`, use spell `1295132`.
    - https://www.wowhead.com/item=274763/fleeting-liquid-luster
    - https://www.wowhead.com/item=274764/fleeting-liquid-luster
  - Alluring Nostrum: item `271890`, use spell `1295015`.
    - https://www.wowhead.com/item=274765/fleeting-alluring-nostrum
    - https://www.wowhead.com/item=274766/fleeting-alluring-nostrum

https://www.wowhead.com/item=275261/sweet-and-sour-skewers
https://www.wowhead.com/item=275263/hearty-sweet-and-sour-skewers

https://www.wowhead.com/item=275260/puffer-plate
https://www.wowhead.com/item=275262/hearty-puffer-plate

https://www.wowhead.com/item=275258/venom-spiced-cutlets
https://www.wowhead.com/item=275259/hearty-venom-spiced-cutlets

https://www.wowhead.com/item=275264/amani-cornucopia
https://www.wowhead.com/item=275267/hearty-amani-cornucopia

https://www.wowhead.com/item=275266/feast-of-knowledge
https://www.wowhead.com/item=275269/hearty-feast-of-knowledge

## Review

- Review consumable priority/data structures before extracting shared selector
  helpers. Combat potions and flasks now use family/variant metadata, but wait
  until food, augments, weapon enchants, and other consumables are reviewed so a
  shared helper follows real common behavior instead of forcing everything into
  the first family-based shape.
- Add item:253011 Brawler's Guild health pot to use first if available?
