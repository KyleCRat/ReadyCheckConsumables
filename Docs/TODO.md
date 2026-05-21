# TODO

### Findings

1. **Medium: Chat reports include offline roster members.**  
   [ChatReportReports.lua](<D:/World of Warcraft/_retail_/Interface/AddOns/ReadyCheckConsumables/Modules/ChatReport/ChatReportReports.lua:37>) scans every active roster member for food/flask/augment/buffs without a `UnitIsConnected(unit)` guard. Offline players will usually scan as having no auras, so reports can falsely list them as missing consumables. The raid-frame title path does skip offline members at [RaidFrameTitleBar.lua](<D:/World of Warcraft/_retail_/Interface/AddOns/ReadyCheckConsumables/Modules/RaidFrame/RaidFrameTitleBar.lua:99>), so chat output and UI can disagree.

2. **Medium: Food chat report treats Eating/Drinking as “fed” and does not report expiring food.**  
   [ChatReportReports.lua](<D:/World of Warcraft/_retail_/Interface/AddOns/ReadyCheckConsumables/Modules/ChatReport/ChatReportReports.lua:40>) accepts any `foodIconIDs` match, but [Data/Food.lua](<D:/World of Warcraft/_retail_/Interface/AddOns/ReadyCheckConsumables/Data/Food.lua:129>) includes Drinking/Eating icons. That can produce `Food: All Fed` while someone is only drinking/eating and not actually Well Fed. It also does not apply the expiring-soon logic that flasks use, while the raid frame distinguishes transient eating from real Well Fed at [RaidFrameColumns.lua](<D:/World of Warcraft/_retail_/Interface/AddOns/ReadyCheckConsumables/Modules/RaidFrame/RaidFrameColumns.lua:186>).

3. **Low/Medium: Potion counts undercount split inventories.**  
   The damage and healing potion data comments say all items are summed for total count, but [DamagePotion.lua](<D:/World of Warcraft/_retail_/Interface/AddOns/ReadyCheckConsumables/Modules/ConsumableFrame/Consumables/DamagePotion.lua:15>) and [HealingPotion.lua](<D:/World of Warcraft/_retail_/Interface/AddOns/ReadyCheckConsumables/Modules/ConsumableFrame/Consumables/HealingPotion.lua:13>) use `FindFirstAvailable()` and display only that one item stack’s count. If a player has multiple valid potion IDs/ranks, the icon can show a lower count than they actually have.


## Fixes
- Evaluate debouncing consumables frame `UNIT_AURA` updates to roughly once per
  second. Measure whether reduced refresh churn during test/ready-check frames
  is worth the added latency and complexity.
- Consider replacing the long `RaidFrame.lua` event `if` chain with a dispatch
  table before adding more raid-frame lifecycle events.
- After one or two releases, consider replacing the legacy `"OIL"` raid-frame
  addon message type with a temp-weapon-enchant-specific message type and
  remove legacy `"OIL"` receive handling. It is currently kept so older RCC
  clients can still read remaining time and item ID from newer clients while
  newer clients can still read older clients.
