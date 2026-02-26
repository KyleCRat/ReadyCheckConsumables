# Ready Check Consumables

A World of Warcraft addon that displays consumable and buff status during ready checks. Designed for raid leaders and raiders who want a quick overview of group preparedness.

## Features

### Consumables Frame

A row of icons appears on the ready check frame showing your own consumable status:

- **Food**, **Flask**, **Augment Rune** — buff detection with remaining duration
- **Mainhand / Offhand Oil** — weapon enchant detection for both slots
- **Healthstone** — inventory count (includes Demonic Healthstone)
- **Damage Potion / Healing Potion** — inventory count
- **Vantus Rune** — raid-only, detects the correct rune for the current instance
- Click-to-use buttons for flasks, oils, augment runes, and vantus runes
- Glow highlights when a consumable is missing or about to expire
- Each icon can be individually toggled in settings

### Raid Status Frame

A full raid overview frame that appears alongside the ready check:

- One row per raid member showing ready check response, name, and buff/consumable status
- Columns for food, flask, augment rune, vantus rune, and all six raid buffs
- Remaining duration shown for timed buffs (flasks, food)
- Missing consumables highlighted with reduced opacity
- Title bar shows column summary icons (green check / red X per category)
- Ready check response counter with colored summary text on completion:
  - Green: "Everyone is Ready!"
  - Red: "X Players not Ready" (explicitly declined)
  - Yellow: "X Players are AFK" (never responded)
- Distinct icons for offline (disconnect) and dead (tombstone) players
- Countdown progress bar for ready check duration
- Draggable, remembers position between checks

### Chat Report

Automatically reports missing consumables to raid/party chat on ready check:

- Reports missing food, flasks, augment runes, and raid buffs
- Flask expiration warnings (under 10 minutes remaining)
- Low-tier augment rune detection
- Raid buff reporting only when the providing class is present
- Configurable per difficulty (Mythic/Heroic/Normal raid, LFR, dungeons)
- Permission system: restrict reporting to raid leader, assist, or anyone

## Slash Commands

| Command | Cmd | Description |
|---|---|---|
| `/rcc test` | `/rcc t` | Show test frames (simulates a ready check) |
| `/rcc hide` | `/rcc h` | Hide all frames |
| `/rcc report` | `/rcc r` | Print consumable report locally |
| `/rcc reportchat` | `/rcc r` | Send report to raid/party chat |
| `/rcc settings` | `/rcc s` | Open the settings panel |

## Settings

Access via `/rcc settings` or the WoW AddOns settings panel. Options include:

- Toggle the consumables frame and individual icons
- Toggle the raid status frame
- Toggle chat reporting and configure which difficulties trigger it
- Set the required raid role for chat reports (Leader / Assist / Any)

## Compatibility

- **ElvUI**: Automatic frame reparenting for compatibility
- Hides on combat start to avoid taint issues
