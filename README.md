# Ready Check Consumables

Ready Check Consumables is a World of Warcraft addon that shows personal and
group consumable status during ready checks. It is built for raid leaders and
raiders who want a quick view of missing buffs, expiring consumables, durability,
cauldron pickups, and ready-check responses.

## Features

### Consumables Frame

A personal icon bar appears during ready checks and can optionally open when
entering instances or after collecting a consumable from a cauldron.

- Tracks food, flasks, augment runes, Vantus runes, raid buffs, weapon enchants,
  healthstones, combat potions, healing potions, and optional Recuperate.
- Shows Well Fed duration, flask duration, weapon enchant duration, and warning
  styling when timed buffs are close to expiring.
- Shows eating/drinking progress on the food icon until the Well Fed aura lands.
- Uses main-hand and off-hand weapon enchant buttons only when those slots can
  be enchanted.
- Supports spell-based and item-based weapon enchants, with fallback to bag
  items when the selected enchant is not available.
- Left-click uses or casts the selected consumable action.
- Right-click stores a preferred item where an item preference is supported.
- Flyouts expose alternate available items for food, flasks, augment runes,
  Vantus runes, combat potions, healing potions, and weapon enchants.
- Item quality badges appear on quality-ranked consumable buttons.
- Tooltips show the relevant item, spell, or aura, plus click hints and
  unavailable-item warnings.
- Shows a desaturated question mark with an explanatory tooltip when WoW
  restricts aura information, rather than treating an unknown buff as missing.
- Glow highlights missing or expiring consumables, with hover colors showing
  whether an action is available.
- Closes immediately when you click Ready or Not Ready if Keep Open After
  Response is disabled, or stays open for the configured duration when enabled.
- Can optionally open after you collect a known flask or potion from a
  cauldron.
- Can optionally open with a consumable stasis item when BigWigs or DBM starts
  a break timer.
- Individual icons can be toggled in settings.

### Raid Status Frame

A raid overview frame appears alongside the ready check.

- Shows one row per active party or raid member.
- Filters raid members by active instance groups so bench players outside the
  relevant groups are ignored.
- Displays ready-check response, player name, online/dead state, food, flask,
  weapon enchant, augment rune, Vantus rune, raid buffs, and durability.
- Shows remaining duration for timed food, flask, and weapon enchant data.
- Reads local aura data and RCC broadcasts from other users for food, flask,
  weapon enchant, and durability status.
- Reads Method Raid Tools durability broadcasts.
- Tracks Midnight flask and potion cauldron pickups, showing each player's
  pickup count and the most recent fleeting flask or potion icon they collected.
- Detects Midnight feast placements and opens with only the food column outside
  a ready check.
- Combines the food column with active cauldron columns when feasts and
  cauldrons are detected together, and appends active cauldron columns to the
  ready-check layout.
- Colors cauldron pickup counts when players are under, at, or over the expected
  pickup amount.
- Shows title-bar summary icons for each tracked column.
- Includes a ready-check countdown progress bar and finished summary text.
- Announces when everyone in the active raid groups is ready, while ignoring
  benched players.
- Includes an inline scale control, is draggable, and remembers position.
- Hides on combat start to avoid protected-frame issues and clears feast and
  cauldron tracking when combat begins.

### Chat Report

Chat reporting can automatically summarize missing consumables when a ready
check starts.

- Reports missing or expiring food and flasks.
- Reports missing or expiring weapon enchants when RCC has known status data.
- Reports players who need repairs when RCC has known durability data.
- Reports missing or outdated augment runes.
- Accepts previous-expansion unlimited augment runes as valid.
- Reports missing raid buffs only when the providing class is present.
- Reports offline players separately.
- Skips offline players and unknown status data for consumable, repair, and
  weapon-enchant checks.
- Avoids reporting to `/say`; local output is used when no group chat is
  available.
- Coordinates between RCC users so only one elected reporter posts.
- Detects Method Raid Tools raid-check reports and avoids duplicate output.
- Can be limited by difficulty and by required raid role: leader, assist, or
  anyone.

### Managed Macros

The settings panel can create marker-based macros that RCC keeps updated.

- Supports shared or character-specific macros.
- Available macro types: food, flask, augment rune, Vantus rune, combat potion,
  healing potion, healthstone, raid buff, main-hand enchant, and off-hand
  enchant.
- Macros use `#RCC:<key>` markers and are rewritten when bags, equipment,
  spells, zone, macros, or preferred item selections change. Aliases include
  `aug` for `augment`, `combatpotion` and `cp` for `combatpot`,
  `healingpotion` and `hp` for `healpot`, `hs` for `healthstone`, `mhen` for
  `mhenchant`, and `ohen` for `ohenchant`.
- Existing custom macros can use inline markers on a single line:
  `#RCCI:combatpot`, `#RCCI:combatpotion`, `#RCCI:cp`, `#RCCI:healpot`,
  `#RCCI:healingpotion`, `#RCCI:hp`, `#RCCI:healthstone`, or `#RCCI:hs`.
  Optional selectors can follow the key, such as `#RCCI:cp [combat]`. RCC
  rewrites only that line to `/use [combat] item:<id> #RCCI:cp` when an item is
  available, or back to the marker-only line with selectors when no item is
  available.
- Food, flask, augment, Vantus, potion, and weapon enchant macros follow the
  same preferred selections used by the consumable frame.
- Healing potion macros cast Recuperate out of combat, stop your current cast in
  combat, and use a healing potion when one is available.

## Slash Commands

| Short | Long | Description |
|---|---|---|
| `/rcc t` | `/rcc test` | Show a timed combined test that auto-hides |
| `/rcc tp` | `/rcc test permanent` | Show a permanent combined test |
| `/rcc rt` | `/rcc ready check test` | Show a timed ready-check-only test |
| `/rcc rtp` | `/rcc ready check test permanent` | Show a permanent ready-check-only test |
| `/rcc ct` | `/rcc cauldron test` | Show the cauldron-only test |
| `/rcc h` | `/rcc hide` | Hide all RCC frames |
| `/rcc r` | `/rcc report` | Print a consumable report locally |
| `/rcc rc` | `/rcc report chat` | Send a consumable report to group chat |
| `/rcc c` | `/rcc consume` | Open the Consumables Frame |
| `/rcc s` | `/rcc settings` | Open the settings panel |

## Settings

Access settings through `/rcc s` or the WoW AddOns settings panel.

- Enable or disable the consumables frame and raid status frame.
- Adjust consumables frame and raid status frame scale.
- Keep frames visible for a configurable minimum time after ready checks.
- Enable or disable feast and cauldron tracking in the raid status frame.
- Choose whether food and cauldron columns can appear outside ready checks when
  their placed consumables are detected.
- Open the consumables frame after collecting a known flask or potion from a
  cauldron.
- Open the consumables frame on BigWigs or DBM break timers.
- Open the consumables frame when entering selected instance types.
- Auto-hide the instance-opened consumables frame after a configurable delay.
- Toggle individual consumable icons.
- Prefer unlimited augment runes before higher-expansion consumable runes.
- Configure chat-report difficulties and report permission.
- Create and update managed RCC macros.

## Compatibility

- Reanchors the consumables frame for ElvUI and ShestakUI ready-check frames.
- Shares and reads RCC addon messages for food, flask, weapon enchant, and
  durability data.
- Shares lightweight cauldron-drop messages so other RCC users can open the
  correct cauldron columns, while pickup counts are still driven by local loot
  chat item IDs.
- Reads Method Raid Tools durability broadcasts and defers chat reporting when
  MRT is already reporting.
- Avoids protected frame work in combat and hides frames on combat start.
