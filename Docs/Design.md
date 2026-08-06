# Legend:
[R] = Check Icon
[X] = Not Ready X Icon
[?] = Has not answered "?" Icon
[Fo] = Food Buff Icon (Should show the actual food buff the player has with the tooltip showing buff time remaining)
[Fl] = Flask Buff Icon (Same should show the actual buff the player has)
[AR] = Augment Rune Buff Icon
[VR] = Vantus Rune Buff Icon
[BS] = Battle Shout Buff icon
[PF] = Power word Fort Buff icon
[AI] = Arcane Intellect Buff Icon
[MW] = Mark of the Wild Buff icon
[SF] = Skyfury Buff icon
[BB] = Blessing of the Bronze Buff Icon

--------------------------------------------------------------------------------
| X/4 39s                 [X]     [X]  [X]  [X]  [X]  [X]  [R]  [X]  [X]  [X]  |
--------------------------------------------------------------------------------
| [R] PlayerName1    59m [Fo] 12m [Fl] [AR] [VR] [BS] [PF] [AI] [MW] [SF] [BB] |
| [X] Yvairel                 11m [Fl] [AR] [VR] [BS]      [AI] [MW] [SF] [BB] |
| [?] PName2         12m [Fo] 13m [Fl] [AR]      [BS] [PF] [AI]      [SF] [BB] |
| [?] SuperLongPl... 10m [Fo]               [VR]           [AI]                |
--------------------------------------------------------------------------------

## Contextual Visibility

`Modules/ContextualVisibility.lua` separates why a frame is open from whether
an element is relevant. Event adapters translate WoW, BigWigs, and DBM events
into semantic reasons:

- `readyCheck`
- `instanceEntry`
- `cauldronPickup`
- `breakTimer`
- `feastDrop`
- `cauldronDrop`
- `manualTest`

Each frame owns a display context containing a set of active reasons. Reasons
compose: starting a break timer during a ready check adds the break-only button
without replacing the ready-check lifecycle.

An element is visible only when all three gates pass:

1. Its global setting is enabled, when it has one.
2. At least one active reason allows it.
3. Its current state is applicable, such as a usable weapon slot or an active
   cauldron kind.

Button and column definitions own their default reason policies. Presenters
only produce content, availability, and applicability. Raid columns are
filtered from one ordered registry and positioned left to right for every
layout, so arbitrary subsets do not leave gaps.

Context overrides are stored sparsely in
`ReadyCheckConsumablesDB.contextualVisibility`. Use
`RCC.SetContextualVisibilityOverride(surface, elementKey, reason, value)` to
set `true` or `false`, and pass `nil` to restore the definition default. The
setter refreshes both frames. No settings matrix is exposed yet.

Feast and cauldron trackers publish semantic reasons to the Raid Frame. The
frame owns per-source auto-open handling, including separate flask and potion
cauldron sources. Closing the frame acknowledges the current sources; a new
source may still reopen it. Combat resets the contextual session.
