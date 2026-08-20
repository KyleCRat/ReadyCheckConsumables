# Ready Check Consumables

Ready Check Consumables (RCC) is a World of Warcraft Retail addon for checking
personal and group consumable readiness. It combines a clickable personal
consumables bar, a raid-wide status table, coordinated chat reports, and managed
consumable macros.

RCC is currently built for Interface `120100`.

## Personal Consumables Frame

The Consumables Frame is a clickable icon bar that can open during a ready
check, when entering an enabled instance type, after a cauldron pickup, or when
BigWigs or DBM starts a break timer.

- Tracks food, flasks, augment runes, Vantus runes, raid buffs, temporary weapon
  enchants, healthstones, combat potions, healing potions, consumable stasis,
  and optional Recuperate.
- Shows the active item or aura, remaining duration, stack count, and warning
  styling for missing or expiring effects.
- Shows eating or drinking progress until the Well Fed aura appears.
- Supports both item-based and spell-based weapon enchants and only shows an
  enchant button when the corresponding weapon slot is applicable.
- Left-click uses or casts the selected action. Right-click stores a preferred
  item where preferences are supported.
- Flyouts expose alternate available food, flasks, runes, potions, and weapon
  enchants.
- Uses bag-only item counts; bank contents are not treated as usable inventory.
- Shows an unknown state with an explanatory tooltip when WoW does not allow an
  aura to be inspected instead of treating that aura as missing.
- Hides in combat and avoids changing protected click behavior during combat.

Each icon can be enabled globally and independently allowed for each automatic
open reason through the **Buttons by Open Event** settings matrix.

## Raid Status Frame

The Raid Status Frame opens with a ready check and can also show feast and
cauldron tracking outside ready checks.

- Shows one row per active party or raid member and excludes bench groups that
  are outside the active instance size.
- Displays ready-check response, player state, food, flask, temporary weapon
  enchant, augment rune, Vantus rune, raid buffs, durability, and active
  cauldron pickups.
- Shows actual aura or item icons and remaining durations where that information
  is available.
- Distinguishes a compatible RCC response with unavailable information from no
  compatible response.
- Treats unknown and no-response data as neutral. Only confirmed failures make
  a column header show a red X; otherwise the header becomes ready once all
  known states are good.
- Treats an enchantable weapon without an enchant, and having no applicable
  weapon equipped, as confirmed weapon-enchant failures.
- Reads Method Raid Tools durability broadcasts.
- Tracks Midnight flask and potion cauldron drops and pickup counts.
- Detects known feast placement spells and can show the food column when a feast
  is placed.
- Combines active feast and cauldron columns with the normal ready-check layout.
- Includes a countdown, finished summary, scale control, and saved position.
- Hides and resets feast or cauldron tracking when combat begins.

## Chat Reports

RCC can automatically report missing consumables after a ready check starts.

- Reports missing or expiring food, flasks, temporary weapon enchants, and
  outdated augment runes, including players without an enchantable weapon.
- Reports low durability, missing raid buffs when the providing class is
  present, and offline players.
- Suppresses aura-derived report sections when WoW does not allow the active
  roster to be inspected safely.
- Elects one RCC user to report and defers to Method Raid Tools when MRT is
  already reporting.
- Can be limited by raid role and by raid or dungeon difficulty.
- Uses local output instead of `/say` when no group chat channel is available.

## Managed Macros

The Macros settings page can create shared or character-specific macros that RCC
keeps synchronized with current bags, equipment, known spells, zone, and item
preferences.

Managed macro types include food, flask, augment rune, Vantus rune, combat
potion, healing potion, healthstone, raid buff, main-hand enchant, and off-hand
enchant.

RCC-owned macros use `#RCC:<key>` markers. Existing custom macros can use an
inline `#RCCI:<key>` marker for combat potions, healing potions, or healthstones;
RCC rewrites only the marked line and preserves the rest of the macro.

Common aliases include:

- `aug` for `augment`
- `combatpotion` or `cp` for `combatpot`
- `healingpotion` or `hp` for `healpot`
- `hs` for `healthstone`
- `mhen` for `mhenchant`
- `ohen` for `ohenchant`

Optional macro conditionals can follow an inline marker, such as
`#RCCI:cp [combat]`.

## Settings

Open settings with `/rcc s` or through **Options > AddOns > Ready Check
Consumables**.

Settings include:

- Frame enablement, scale, and ready-check display duration.
- Automatic opening on ready checks, instance entry, cauldron pickup, or break
  timers.
- Instance-type controls for dungeons, raids, scenarios, battlegrounds, and
  arenas. Delves use the Scenarios setting because WoW reports delve instances
  as `scenario`.
- Automatic hiding after an instance-entry open.
- Per-icon visibility and per-open-event visibility.
- Unlimited augment rune preference.
- Feast and cauldron tracking behavior.
- Chat-report permission and difficulty filters.
- Managed macro creation.

Settings, preferred consumable choices, raid-frame scale, and raid-frame
position are stored account-wide in `ReadyCheckConsumablesDB`.

## Slash Commands

| Short | Long | Description |
|---|---|---|
| `/rcc t` | `/rcc test` | Show a timed combined frame test |
| `/rcc tp` | `/rcc test permanent` | Show a permanent combined frame test |
| `/rcc rt` | `/rcc ready check test` | Show a timed ready-check-only test |
| `/rcc rtp` | `/rcc ready check test permanent` | Show a permanent ready-check-only test |
| `/rcc ct` | `/rcc cauldron test` | Show the cauldron-only test |
| `/rcc h` | `/rcc hide` | Hide all RCC frames |
| `/rcc r` | `/rcc report` | Print the consumable report locally |
| `/rcc rc` | `/rcc report chat` | Send the consumable report to group chat |
| `/rcc c` | `/rcc consume` | Open the Consumables Frame |
| `/rcc s` | `/rcc settings` | Open the settings panel |

Opening settings during combat is deferred until combat ends. The Consumables
Frame cannot be opened manually during combat.

## Compatibility

- Integrates with BigWigs and DBM break timers.
- Reanchors the Consumables Frame for ElvUI and ShestakUI ready-check frames.
- Reads Method Raid Tools durability data and avoids duplicate MRT chat reports.
- Exchanges lightweight presence, consumable, durability, feast, and cauldron
  data with compatible RCC clients.
- Uses public aura data only and presents restricted information as unknown.
- Keeps protected UI work out of combat.
