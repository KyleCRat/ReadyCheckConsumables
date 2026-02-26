# Changelog

All notable changes to Ready Check Consumables will be documented in this file.

## [12.0.1-2] - 2026-02-26

### Fixes
- Add tooltips to items on readycheck frame
- Fix icon using item vs buff on raid frame incorrectly

## [12.0.1-1] - 2026-02-26

- Initial Addon Release

### Consumables Frame
- Personal consumable status icons on the ready check frame
- Tracks food, flask, weapon oils (MH/OH), augment rune, healthstone, damage potion, healing potion, and vantus rune
- Remaining duration for timed buffs; inventory counts for potions, healthstones, and runes
- Click-to-use buttons for flasks, oils, augment runes, and vantus runes
- Glow highlights when a consumable is missing or expiring
- Auto-detects weapon enchant items in bags when no enchant is applied
- Each icon individually toggleable in settings

### Raid Status Frame
- Per-member consumable and buff overview for the entire raid
- Columns for food, flask, augment rune, vantus rune, and all six raid buffs
- Ready check response tracking with disconnect/dead player icons
- Colored summary text on completion (ready / not ready / AFK)
- Countdown progress bar and draggable frame

### Chat Report
- Automatic missing consumable reports to raid/party chat on ready check
- Reports food, flasks, augment runes, and raid buffs (only when provider class is present)
- Flask expiration and low-tier rune warnings
- Configurable per difficulty with role-based permission system

### General
- Settings panel via `/rcc settings` or the WoW AddOns menu
- Hides on combat start
- ElvUI compatible
