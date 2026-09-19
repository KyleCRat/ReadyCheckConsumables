# Ready Check Consumables

Ready Check Consumables (RCC) helps you and your group prepare for the next pull
in World of Warcraft Retail. Keep consumables close at hand, see what needs
refreshing, check your group's readiness, and maintain consumable macros as
your inventory changes.

Open settings with `/rcc s` or **Options > AddOns > Ready Check Consumables**.
Each display and automatic chat reporting has its own **Enabled** checkbox,
so you can use only the features you want. Settings and item preferences are
account-wide.

## Personal Consumables

Choose a temporary preparation frame, a permanent Action Bar, or both. Their
buttons are configured separately, while preferred item choices are shared.

### Consumables Frame

A temporary, clickable bar brings food, flasks, augment runes, vantus runes,
weapon enchants, raid buffs, and other essentials together during ready checks.
Remaining buff durations, item counts, and warnings help you see what needs
attention. Hover an icon to see details and available alternatives.

On the **Consumables Frame** settings page:

- **Choose buttons:** Use **Buttons by Open Event**. Each row's **Enabled**
  checkbox controls that button overall; the event columns choose when it
  appears.
- **Choose when it opens:** Ready checks are supported by default. Under
  **Automatic Open Events**, enable instance entry, cauldron pickups, or
  BigWigs/DBM break timers. For instance entry, select the instance types you
  want; delves use **Scenarios**.
- **Adjust the size:** Change **Scale** for the whole frame or **Icon Width**
  to make buttons narrower, from 50% to 100%, without stretching their images.
- **Keep it visible longer:** Enable **Keep Open After Ready Response** and
  adjust **Ready Check Duration**. Instance-entry opens have a separate
  auto-hide toggle and delay.

### Consumables Action Bar

Keep selected consumables on a permanent bar that stays usable in combat.
Use flyouts before combat to choose preferred items, then use the primary
buttons during the fight. Buttons keep a consistent order, making it suitable
for everyday use as well as preparation before a pull.

On the **Consumables Action Bar** settings page:

- **Turn it on:** Check **Enabled**; the permanent bar is off by default.
  Choose individual icons under **Buttons**.
- **Arrange it:** Set **Icons Per Row**, button width and height, and horizontal
  and vertical gaps. Non-square icons are cropped rather than stretched.
- **Choose the information shown:** Adjust text size, duration-text side, and
  flyout direction. Under **Button Information**, toggle counts, durations,
  status marks, and profession-quality marks.
- **Move it:** Use EllesmereUI Unlock Mode when available, or Blizzard Edit
  Mode otherwise. The settings page also offers anchor and X/Y position controls.

Both personal displays also offer optional Inky Black Potion, Repair, and
Recuperate buttons, which are off by default.

## Group Readiness

The Raid Status Frame and Chat Reports work independently of the personal
displays and of each other.

### Raid Status Frame

See your party or raid's food, flasks, runes, temporary weapon enchants, raid
buffs, and durability alongside their ready-check responses in one table.
Buff icons and remaining durations help identify what needs refreshing.
Feast and cauldron tracking also shows available provisions and members'
flask or potion pickup counts.

On the **Raid Frame** settings page:

- **Display:** Turn the frame on or off with **Enabled**, and adjust **Scale**.
  You can also drag the frame to move it and use its bottom scale control.
- **Ready-check timing:** Use **Keep Open After Finished** and **Keep Open
  Duration** to leave the results visible briefly.
- **Feasts and cauldrons:** Enable **Track Feasts and Cauldrons**. Turn on
  **Show Outside Ready Checks** if you also want those columns to appear when
  provisions are detected between ready checks.

### Chat Reports

Automatically share missing or expiring consumables, missing raid buffs,
low durability, and offline players in group chat during ready checks.
RCC coordinates with other RCC users and Method Raid Tools to avoid duplicate
automatic reports.

On the **Chat Report** settings page:

- **Enabled** turns your automatic reporting on or off.
- **Who Can Report** selects raid leader, leader/assist, or any raid member.
  This role restriction applies only in raids.
- **Raid Instances** and **Dungeon Instances** select the difficulties where
  automatic reports are allowed.

By default, automatic reporting is enabled for Heroic and Mythic raids and
limited to raid leaders or assistants. Dungeon reporting is off by default.

## Managed Macros

Create macros for food, flasks, augment runes, vantus runes, potions,
healthstones, raid buffs, and weapon enchants. RCC keeps them updated as your
bags, equipment, known spells, zone, and preferred items change.

Item macros, except Augment Rune, include one eligible backup from your bags,
so the macro can still work if the primary runs out during combat. Augment Rune
macros use one item only. Inside the Brawler's Guild, its potion takes priority
when carried, with your normal healing potion as backup.

To create one:

1. Open the **Macros** settings page.
2. Find the consumable you want and click **Shared** for an account-wide macro,
   or **Character** for a character-specific macro.
3. Place the created macro on your normal WoW action bar.

You can also include automatically updated potion or healthstone lines in your
own custom macros. See [custom macro markers](#custom-macro-markers) below for
the syntax.

## Preview and Open Frames

- `/rcc c` opens the enabled Consumables Frame outside combat.
- `/rcc t` previews the temporary personal and raid frames with sample data;
  it does not start a real group ready check.
- `/rcc h` closes temporary RCC frames and previews without hiding the
  permanent Action Bar.

---

## Advanced Reference

### Buttons, item choices, and combat

Left-click usable buttons to consume an item or cast a spell. Where supported,
right-click an item outside combat to save it as your preferred choice.
Right-click the preferred item again to clear that choice and return to
automatic selection, including any applicable overrides.
Preferences are shared by the personal displays and managed macros. Item counts
use your bags, not your bank.

Your preference keeps the exact item and rank you chose. If it runs out, the
button keeps showing that item with a zero count; macros can select an available
alternative without changing your choice. Carried fleeting flasks and potions from
the same family take priority over your regular choice, even if that rank is
out of stock. Fleeting items cannot be saved as preferences.

**Prefer Unlimited Augment Runes**, on the Consumables Frame settings page,
also applies to the Action Bar and macros. It puts carried unlimited runes
ahead of consumable runes when choosing automatically, even across expansions.
An explicit item preference takes priority over this setting; clearing it
restores automatic selection. Cooldowns never change the selected rune.
Augment Rune macros always contain just one item-use line, with no backup:
if the selected unlimited rune is on cooldown, it simply cannot be used yet.
You can still left-click a consumable rune in the flyout or prefer it for your
primary button and macro.

Some buttons have different purposes on the two displays:

| Item type | Consumables Frame | Consumables Action Bar |
|---|---|---|
| Food, flasks, runes, and weapon enchants | Use or apply the selected item/spell | Use or apply the selected item/spell |
| Combat and healing potions | Right-click to choose a preferred item | Left-click to use; right-click to prefer |
| Healthstones | Display available supply | Left-click to use |

Healthstones are selected automatically: a carried Demonic Healthstone takes
priority over a normal one. The icon and charge count describe the selected
stone; there is no saved preference.

Inside Bizmo's Brawlpub or Brawl'gar Arena, both displays automatically show the
Brawler's Guild healing potion when you carry one. Your normal potion preference
is kept for when you leave or run out of the Guild potion; normal potions remain
available in the flyout.

Enabled Action Bar buttons normally remain visible even when unavailable.
The off-hand enchant button hides when that slot cannot be enchanted, and the
bar closes the gap. Equipment changes during combat update the layout afterward.

The temporary Consumables Frame and Raid Status Frame hide in combat. Action
Bar flyouts close when combat starts and cannot open during combat. The bar's
primary buttons keep using the items or spells selected beforehand. Item choices
refresh after combat. Readable buff durations and status marks continue updating;
glows stay hidden. Managed macro updates also wait until combat ends.

Settings requested in combat open afterward. Manual Consumables Frame and
Feast/Cauldron Frame opens are blocked during combat, not queued.

### Optional utility buttons

- **Repair** prefers a ready reusable device such as Jeeves before a consumable
  such as Auto-Hammer. It shows cooldowns rather than ready/missing marks.
- **Inky Black Potion** shows the item or active buff without ready/missing marks.
- **Consumable Stasis** provides access to items that pause consumable buff
  durations during breaks. Its temporary-frame button appears for break timers
  by default.

### Reading group status

The Raid Status Frame covers active party or raid members, excluding bench
groups outside the instance size.

- **Column headers:** Confirmed failures show a red X. Unknown and no-response
  states are neutral, so they do not block a green check for known-good members.
- **Food:** Eating is still in progress until a sufficiently long Well Fed
  buff appears.
- **Weapons:** A missing temporary weapon enchant or having no enchantable
  main-hand weapon equipped is a failure.
- **Unavailable information:** Tooltips distinguish a responding RCC user whose
  information could not be checked from a player with no compatible response.

Readable buffs still show when another buff is restricted; buffs that cannot
be confirmed remain unknown. When WoW prevents a reliable check of the active
group's buffs, RCC omits the affected buff-based chat-report sections instead
of reporting false missing buffs. RCC also reads Method Raid Tools durability
data.

Closing the ready-check display also closes its feast/cauldron display.
`/rcc ca` reopens provision tracking while it remains active. Combat hides the
frame and resets feast/cauldron tracking.

### Custom macro markers

RCC-owned macros use `#RCC:<key>` markers. Inline `#RCCI:<key>` markers update
a small group of item-use lines inside your own macro without changing the rest.

| Macro type | Key and aliases | Inline marker |
|---|---|---|
| Food | `food` | Not supported |
| Flask | `flask` | Not supported |
| Augment rune | `augment`, `aug` | Not supported |
| Vantus rune | `vantus` | Not supported |
| Combat potion | `combatpot`, `combatpotion`, `cp` | `#RCCI:cp` |
| Healing potion | `healpot`, `healingpotion`, `hp` | `#RCCI:hp` |
| Healthstone | `healthstone`, `hs` | `#RCCI:hs` |
| Raid buff | `raidbuff` | Not supported |
| Main-hand enchant | `mhenchant`, `mhen` | Not supported |
| Off-hand enchant | `ohenchant`, `ohen` | Not supported |

Put an inline marker on its own line. Optional macro conditions can follow it,
for example:

```text
#RCCI:cp [combat]
```

The complete Healing Potion macro casts Recuperate out of combat and uses a
potion in combat. Its inline marker adds only the potion choices, not Recuperate
or a combat restriction unless you include `[combat]` yourself.

Item macros choose from available automatic overrides first, then your
available preferred item, then the category's fallbacks. Augment Rune macros
use only the first choice; other item macros include one eligible backup.
These choices never change your saved preference.
Healing potion macros select the Brawler's Guild potion (`253011`) only inside
Bizmo's Brawlpub or Brawl'gar Arena when you
carry one, with your normal potion as the backup. Outside those venues, or if
you have none, they use the normal primary and backup. There are at most two
potion-use lines. Both personal displays use the same location-aware primary
selection without changing your saved preference. Spell-based macros remain
single casts.

Entering or leaving a venue refreshes the macro outside combat. Choices stay
fixed during combat, with pending changes applied afterward;
RCC does not rewrite the macro when you use the last item mid-fight. The backup
is already included as a second `/use` command. WoW applies its normal item-use
restrictions and cooldowns to each command.

Inline choices all inherit the marker's conditions. Extra generated lines end
with `#RCCI+`; keep them immediately below the first marked line so RCC can
replace them together. To remove an inline marker, remove its generated lines
too. If an update would exceed WoW's 255-character macro limit, RCC prints a
message and leaves the macro unchanged so you can shorten it.

### Command reference

Use `/rcc` for in-game help.

#### Everyday commands

| Short | Long | Description |
|---|---|---|
| `/rcc s` | `/rcc settings` | Open settings |
| `/rcc c` | `/rcc consume` | Open the Consumables Frame |
| `/rcc h` | `/rcc hide` | Hide temporary frames; leave the Action Bar visible |
| `/rcc ca` | `/rcc cauldron` | Reopen active feast/cauldron tracking |
| `/rcc r` | `/rcc report` | Print a report locally |
| `/rcc rc` | `/rcc report chat` | Send a report to group chat |

With no group channel available, reports stay local.

#### Previews

These commands use sample data, not a real group ready check.

| Short | Long | Description |
|---|---|---|
| `/rcc t` | `/rcc test` | Timed combined frame preview |
| `/rcc tp` | `/rcc test permanent` | Combined preview that stays open |
| `/rcc rt` | `/rcc ready check test` | Timed ready-check-only preview |
| `/rcc rtp` | `/rcc ready check test permanent` | Ready-check-only preview that stays open |
| `/rcc ct` | `/rcc cauldron test` | Cauldron-only preview |
