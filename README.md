# Ready Check Consumables

Ready Check Consumables is a World of Warcraft addon that shows personal and
group consumable status during ready checks. It is built for raid leaders and
raiders who want a quick view of missing buffs, expiring consumables, durability,
and ready-check responses.

## Features

### Consumables Frame

A personal icon bar appears during ready checks and can optionally open when
entering instances.

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
- Glow highlights missing or expiring consumables, with hover colors showing
  whether an action is available.
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
- Shows title-bar summary icons for each tracked column.
- Includes a ready-check countdown progress bar and finished summary text.
- Announces when everyone in the active raid groups is ready, while ignoring
  benched players.
- Includes an inline scale control, is draggable, and remembers position.
- Hides on combat start to avoid protected-frame issues.

### Chat Report

Chat reporting can automatically summarize missing consumables when a ready
check starts.

- Reports missing or expiring food and flasks.
- Reports missing or outdated augment runes.
- Accepts previous-expansion unlimited augment runes as valid.
- Reports missing raid buffs only when the providing class is present.
- Reports offline players separately.
- Skips offline players for consumable checks.
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
  spells, zone, macros, or preferred item selections change.
- Food, flask, augment, Vantus, potion, and weapon enchant macros follow the
  same preferred selections used by the consumable frame.
- Healing potion macros cast Recuperate out of combat and use a healing potion
  in combat when one is available.

## Slash Commands

| Command | Cmd | Description |
|---|---|---|
| `/rcc test` | `/rcc t` | Show timed test frames that auto-hide |
| `/rcc testp` | `/rcc tp` | Show permanent test frames |
| `/rcc hide` | `/rcc h` | Hide all RCC frames |
| `/rcc report` | `/rcc r` | Print a consumable report locally |
| `/rcc reportchat` | `/rcc rc` | Send a consumable report to group chat |
| `/rcc settings` | `/rcc s` | Open the settings panel |
| `/rcc options` | `/rcc o` | Open the settings panel |

## Settings

Access settings through `/rcc settings` or the WoW AddOns settings panel.

- Enable or disable the consumables frame and raid status frame.
- Adjust consumables frame and raid status frame scale.
- Keep frames visible for a configurable minimum time after ready checks.
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
- Reads Method Raid Tools durability broadcasts and defers chat reporting when
  MRT is already reporting.
- Avoids protected frame work in combat and hides frames on combat start.
