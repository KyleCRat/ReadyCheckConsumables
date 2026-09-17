# Personal consumable pipeline: a Flask walkthrough

This guide follows the existing Flask button from its item registration to a
clickable icon. The temporary Consumables Frame and permanent Action Bar use
the same Flask logic; each decides whether and how to display the result.

There are two different additions you might make:

- **Another item for an existing button**, such as a new flask rank: add it to
  that category's gameplay data. The existing selection, buff detection, and
  button code can then use it.
- **A new kind of button**: give it a catalog entry, settings defaults, a module
  that decides what it does, and a presenter that describes how it looks.

There is no single `RegisterConsumable()` call. The walkthrough shows how those
pieces connect. It uses real Flask code and data; example result tables omit
unrelated fields and use illustrative counts and times.

Read the numbered walkthrough in order, or jump to the
[running event flow](#follow-one-flask-use-through-the-running-addon),
[new-category examples](#adapting-the-walkthrough-to-a-new-button-category), or
[raid-buff and macro differences](#two-related-paths-that-do-not-work-exactly-like-flask).

## 1. Register the usable items and their buffs

Start in [Data/12_Midnight/Flasks.lua](../Data/12_Midnight/Flasks.lua). One of
its existing families is registered like this:

```lua
local _, RCC = ...
local FLEETING = RCC.FlaskVariant.FLEETING

RCC.Data.AddFlaskItems({
    { -- Flask of Thalassian Resistance
        xpac = RCC.MIDNIGHT,
        items = {
            { itemID = 245926, q = 2, variant = FLEETING },
            { itemID = 245927, q = 1, variant = FLEETING },
            { itemID = 241320, q = 2 },
            { itemID = 241321, q = 1 },
        },
    },
})
```

A family groups interchangeable versions of a flask. `q` is its quality rank;
`variant` distinguishes a fleeting item from a regular one. The array order
matters to selection: families define fallback order, and items within a family
define their priority. The selector also considers the player's saved choice.

`AddFlaskItems`, defined in [Data/Flasks.lua](../Data/Flasks.lua), builds the
tables used by the rest of the addon:

- `RCC.db.flaskItemIDs`: all item IDs that the inventory reader should check.
- `RCC.db.flaskItemData[itemID]`: family, variant, quality, and ordering data.
- `RCC.db.flaskItems`: the registered families.

Edit the family definitions, not these generated lists.

Knowing which item to use is separate from recognizing its active effect.
The same base data file contains the applied buff IDs:

```lua
-- Entry inside RCC.db.flaskBuffIDs:
[1235057] = true, -- Flask of Thalassian Resistance
```

Without the item entry, RCC cannot offer that flask as a button or flyout
choice. Without the buff entry, using it cannot satisfy Flask's aura check.
The item ID and applied aura spell ID answer different questions.

Cauldron pickup tracking is a third use of the data: fleeting flask items also
appear in the cauldron's `pickupItemIDs` in
[Data/12_Midnight/Cauldrons.lua](../Data/12_Midnight/Cauldrons.lua).
That list detects collection from a cauldron; it does not register a usable flask.

If you are adding another flask with the existing behavior, these data additions
are the work. The remaining sections explain the button machinery they feed.
A new data file also needs a line in
[ReadyCheckConsumables.toc](../ReadyCheckConsumables.toc); Lua files are not
discovered automatically.

## 2. Connect the button name, logic, and settings

[ConsumableCatalog.lua](../Modules/Consumables/ConsumableCatalog.lua) contains
one definition per button category. Flask's entry is:

```lua
{
    key = "flask",
    domain = "Flask",
    label = "Flask",
    settingKey = "icon_flask",
    defaultIcon = RCC.db.flaskIconID,
    temporaryClickable = true,
    tooltipAction = "use",
},
```

The important connections are:

| Field | What uses it |
| --- | --- |
| `key = "flask"` | Identifies this button in requests, snapshots, and UI button tables |
| `domain = "Flask"` | Looks up its logic at `RCC.Consumables.Flask` and its presenter at `RCC.ConsumablePresenters.Flask` |
| `settingKey` | Enables this category on the temporary frame |
| `defaultIcon` | Gives the renderer an icon when the result has no item or aura icon |
| `temporaryClickable` | Controls whether the temporary frame creates a clickable control |
| `tooltipAction` | Supplies the verb for the click hint |

The entry's position in the catalog determines button order on both personal
displays. The fallback icon itself is defined in
[Data/Settings.lua](../Data/Settings.lua).

The catalog generates the Action Bar setting name from the key:
`consumablesActionBar_icon_flask`. Both settings have explicit defaults in
[Settings.lua](../Settings.lua):

```lua
icon_flask = true,
consumablesActionBar_icon_flask = true,
```

These defaults are not generated from the catalog. A new category needs both
defaults, even though its settings controls are generated automatically:
[ConsumableFrameSettings.lua](../Modules/ConsumableFrame/ConsumableFrameSettings.lua)
builds the matrix rows from the catalog, and
[ConsumableActionBarSettings.lua](../Modules/ConsumableActionBar/ConsumableActionBarSettings.lua)
builds the button checkboxes from it.

For the temporary frame, the catalog's `visibility.reasons` supplies the default
matrix choices. Flask uses the standard reasons because it does not override
that field. Per-user matrix choices are handled by
[ContextualVisibility.lua](../Modules/ContextualVisibility.lua), separately
from whether the Flask button is enabled at all.

## 3. Tell the controller what information Flask needs

The category's logic lives in
[Modules/Consumables/Flask.lua](../Modules/Consumables/Flask.lua).
This is the **domain module**: it chooses an item and decides the flask's current
status, without creating frames.

It declares the inputs it uses:

```lua
Flask.Inventory = { list = RCC.db.flaskItemIDs }

Flask.Dependencies = {
    selection = { "inventory", "preferences.flask" },
    observation = { "playerAuras" },
    evaluation = { "context.warningSeconds" },
    expiration = "playerAuras",
}
```

An **input** is data already read from the game or saved settings. For Flask,
that means item counts and icons, the saved flask preference, the player's
helpful auras, and the duration-warning threshold.

A **reader** is the function that obtains that data. For example,
`ConsumableInputs.ReadInventory` calls the item APIs and returns a table keyed
by item ID. `ReadPreferences` reads saved item choices. The controller obtains
`playerAuras` through `HelpfulAuraScan.ScanUnit("player")` in
[AuraScan.lua](../AuraScan.lua), which leaves restricted fields out of the result.

The dependency entries connect those inputs to four jobs:

| Entry | What it means for Flask |
| --- | --- |
| `selection` | Run `Flask.Select` when inventory or the saved flask choice changes |
| `observation` | Run `Flask.Observe` when the player's aura scan changes |
| `evaluation` | Recalculate the result when the warning threshold changes, even if selection and auras are unchanged |
| `expiration` | Read player auras again when the cached buff reaches its expiry time |

`Evaluate` also runs when selection or observation changes, and at scheduled
time updates. The `evaluation` list is for its additional input dependencies;
it is not the only reason that function runs.

The dotted name `preferences.flask` means that specific value in the inputs
table. A food-preference change does not require Flask to select an item again.

### How this declaration leads to event handling

Neither `Flask.lua` nor its presenter registers bag or aura events.
[ConsumableStateController.lua](../Modules/Consumables/ConsumableStateController.lua)
handles those events for all categories. Existing examples are:

| Change | Input marked for another read |
| --- | --- |
| `UNIT_AURA` for the player | `playerAuras` |
| `ITEM_COUNT_CHANGED` for a tracked item | That item in `inventory` |
| `BAG_UPDATE_DELAYED` | All requested inventory items |
| `ITEM_DATA_LOAD_RESULT` for a tracked item | That item's count/icon/quality data |
| Right-clicking a preferred flask | `preferences`, through the item-choice cache |

The controller only watches data that a personal display currently needs.
Each display registers a **consumer**, an object with two functions:
`GetCategories()` says which buttons it needs, and `ApplySnapshot()` receives
their results: icon, text, action, and other button instructions. Those results
are packaged in a snapshot; section 6 shows the table's contents.

For example:

```lua
-- The two consumers might return:
-- Temporary frame:
{ food = true, flask = true }

-- Action Bar:
{ flask = true, repair = true }
```

The controller prepares food, flask, and repair, with Flask calculated once
for both displays. [ConsumableDemand.lua](../Modules/Consumables/ConsumableDemand.lua)
turns those category names and their dependencies into the required input
names, item IDs, and weapon slots. Here, Flask contributes its inventory list,
preferences, player auras, and context.

The temporary frame requests buttons only while shown out of combat and allowed
by its current matrix settings. The Action Bar requests its enabled buttons.
If neither requests Flask, this pipeline stops maintaining Flask's result;
other requested categories may still need the same inventory or aura input.

This request is separate from whether a button can be used right now. For
example, an enabled off-hand enchant button still needs equipment updates while
its slot is inapplicable, so equipping a weapon can make the button return.

## 4. Choose an item; inspect the buff; decide its status

[ConsumableRuntime.lua](../Modules/Consumables/ConsumableRuntime.lua) calls the
category functions and keeps their results until their inputs change.
Flask answers three different questions.

### `Select(inputs, preserveUnavailable)`: what should clicking use?

Flask's selector examines the registered items in `inputs.inventory` and the
saved choice in `inputs.preferences.flask`. Its family/variant preference rules
live in `Flask.lua`; the shared
[ConsumableSelection.lua](../Modules/Consumables/ConsumableSelection.lua)
helpers construct candidates and result tables.

A **candidate** is an item that selection can consider. For example, a result
might contain:

```lua
selection = {
    candidate = {
        itemID = 241320,
        count = 3,
        icon = flaskItemIcon,
        -- Also includes quality and family metadata.
    },
    candidates = availableFlaskCandidates,
    unavailable = false,
    action = {
        kind = "item",
        itemID = 241320,
        preferenceKey = "flask",
        selectionOnly = false,
    },
}
```

`candidate` is the primary choice. `candidates` supplies the alternatives for
the flyout. `action` describes what clicking should do; it does not use the item
or change a secure button yet. It is created through
`ConsumableState.CreateItemAction`, via `Selection.WithItemAction`.

The UI calls `Select` with `preserveUnavailable = true`. Flask can therefore
retain a saved item with a zero count, so its button can explain that the selected
item is unavailable instead of silently replacing it. With no usable selected
item, `WithItemAction` supplies no action.

### `Observe(inputs)`: what flask buff did the scan find?

The implementation is small because the shared effect helper can match Flask's
registered aura IDs:

```lua
function Flask.Observe(inputs)
    return RCC.ConsumableEffects.Observe(
        inputs.playerAuras,
        RCC.db.flaskBuffIDs
    )
end
```

This function does not query WoW. It searches the already-read aura list.
An **observation** is its answer, before duration-warning decisions:

```lua
observation = {
    available = true,
    aura = {
        spellID = 1235057,
        expirationTime = 4600,
        -- Also includes public icon, name, duration, and aura instance ID.
    },
}
```

If the scan found no matching buff, the `aura` field is absent. `available`
records whether the scan could identify every aura: no match in an available
scan means missing; no match in an unavailable scan means unknown. A readable
matching flask is still useful even if another aura was restricted.

A new scan replaces the old aura list. It is not added to the previous list,
which would leave removed buffs behind.

### `Evaluate(selection, observation, inputs, now)`: what does that mean now?

Flask delegates to
[ConsumableEffects.lua](../Modules/Consumables/ConsumableEffects.lua):

```lua
function Flask.Evaluate(selection, observation, inputs, now)
    return RCC.ConsumableEffects.Evaluate(
        selection,
        observation,
        inputs.context,
        now
    )
end
```

The return value is called the **model**. It combines the selected item/action,
scan availability, and the buff's current meaning. For the observation above,
at `now = 1000` with a five-minute warning threshold, the relevant fields are:

```lua
model = {
    selection = selection,
    action = selection.action,
    available = true,
    effect = {
        active = true,
        remaining = 3600,
        timeIsBad = false,
        satisfied = true,
        -- Icon, aura instance ID, and other effect fields are omitted here.
    },
    -- nextUpdateAt and recheckAt tell the controller when to revisit this.
}
```

The distinction between `active` and `satisfied` matters: a flask can still be
active but have too little time left. The UI can keep its buff display while
warning that it should be refreshed.

The controller uses the model's `nextUpdateAt` to schedule the next duration
label or warning change. It can recalculate remaining time from the saved
expiration timestamp without another aura scan. At `recheckAt`, it rereads the
source named by `Dependencies.expiration` before deciding the new status.

## 5. Describe the button and its flyout

[Modules/ConsumableUI/Presenters/Flask.lua](../Modules/ConsumableUI/Presenters/Flask.lua)
defines `RCC.ConsumablePresenters.Flask`. This is a different table from the
domain module, even though both files use the local name `Flask`.

A **presenter** converts the model into instructions for the common button
renderer. `Flask.Present(model)` returns a plain Lua table; it does not call
`SetTexture`, query bags, or choose a replacement item.

For example, Flask uses:

```lua
ButtonState.ApplyActiveAura(buttonState, model.effect)
```

That helper supplies the active-buff icon, check mark, duration text, and
warning-text color information. Flask then adds the selected item's icon and
quality, bag count, click action, and any unavailable-item message. It requests
a reminder glow when the buff is not satisfactory and a usable flask is held.
`ApplyAuraScanAvailability` handles an unresolved aura result without claiming
the buff is missing.

These are some of the fields the renderer understands:

| Button-state field | Effect on the button |
| --- | --- |
| `icon`, `desaturated` | Texture and whether it is shown in color |
| `countText` | Item count or charges text |
| `detailText`, `detailTextIsBad` | Duration/detail label and warning color |
| `statusIcon`, `showStatusTexture` | Status artwork and whether this category uses an overlay |
| `tooltipItemID`, `tooltipAuraID` | Item or active-aura tooltip information |
| `action` | Prepared click behavior described by an item/spell action |
| `glow`, `suppressGlow` | Reminder request and category-specific glow suppression |
| `applicable` | Whether this category applies to the current situation |

`ConsumableState.Normalize` fills omitted fields from `State.DEFAULTS`.
Those defaults include a not-ready status mark and a desaturated icon. An
optional-use category needs to express its different appearance: the
[Inky Black Potion presenter](../Modules/ConsumableUI/Presenters/InkyBlackPotion.lua),
for example, sets `showStatusTexture = false`, `suppressGlow = true`, and keeps
`desaturated = false`.

Choose `statusIcon` from `ConsumableState.READY_ICON`, `NOT_READY_ICON`, or
`UNKNOWN_ICON`. These shared artwork records identify an atlas or texture;
`UI.SetStatusIcon` draws it without changing the overlay's size or opacity.

### Flyout choices use the selection, not another inventory read

`Flask.Choices(selection)` calls `CreateItemFlyoutChoices` with the available
candidates, the selected item ID, and the Flask preference key. The helper
returns button-state tables for the alternatives, excluding the primary item.

The runtime keeps those choices until the selection changes, then attaches them
to the primary state as `flyoutChoices`. A duration update does not rebuild
the choices. A category with no alternatives can omit `Choices` entirely.

## 6. Send the result to each display

A **snapshot** is the output table built by the runtime for one refresh. It
contains the latest button instructions for all currently requested categories,
plus change numbers used by the displays. It is not the raw aura scan, the
inventory table, or saved settings.

Here is an abbreviated example after a Flask aura update. The revision numbers
are illustrative; the action and flyout choices have not changed in this update:

```lua
snapshot = {
    generatedAt = 1000,
    states = {
        flask = {
            applicable = true,
            icon = flaskItemIcon,
            countText = "3",
            detailText = "1h",
            detailTextIsBad = false,
            statusIcon = RCC.ConsumableState.READY_ICON,
            showStatusTexture = true,
            desaturated = false,
            hasConsumableBuff = true,
            action = selection.action,
            flyoutChoices = otherFlaskButtonStates,
            -- Tooltip, quality, and other normalized fields omitted.
        },
        -- Food, Repair, etc. appear here if either display requested them.
    },
    revisions = {
        flask = {
            visual = 12,
            interaction = 8,
            applicability = 1,
        },
    },
    changed = {
        flask = {
            visual = true,
            interaction = false,
            applicability = false,
        },
    },
}
```

`states.flask` is what to display and bind. `revisions.flask` contains change
numbers, not counts or timestamps: the display compares them with the last ones
it applied. `changed.flask` describes this particular refresh. Using revisions
lets a display catch up even if it missed an earlier refresh.

The controller calls each consumer's `ApplySnapshot(snapshot, categories)`.
It passes the same snapshot to both displays, but a different `categories`
table: the temporary frame from the earlier example receives
`{ food = true, flask = true }`, while the Action Bar receives
`{ flask = true, repair = true }`. Each applies only its own requested buttons.

An absent entry in `snapshot.states` means neither display requested that
category; it does not mean the consumable is missing. Unchanged result tables
may be shared across refreshes, so consumers read them rather than modifying them.

[ConsumableSurface.ApplySnapshot](../Modules/ConsumableUI/ConsumableSurface.lua)
does the actual handoff:

| Changed part | Work performed |
| --- | --- |
| Visual state | [ConsumableButtonView.ApplyVisual](../Modules/ConsumableUI/ConsumableButtonView.lua) updates textures, text, status, cooldowns, and tooltip state |
| Action or flyout choices | [ConsumableActionBinder.Bind](../Modules/ConsumableUI/ConsumableActionBinder.lua) prepares the secure click action; [ConsumableFlyout.SetChoices](../Modules/ConsumableUI/ConsumableFlyout.lua) updates alternatives |
| Applicability/visibility | The owning frame decides which buttons occupy its layout |

This is why changing only a duration label does not rebind the item action.

### The same result can have different display options

The presenter describes the consumable, not the Action Bar's size or the user's
Show Duration checkbox. Those options belong to the display:

- `Surface.ApplyGeometry` supplies button width/height, spacing, text size, and
  flyout direction.
- `Surface.ApplyVisualOptions` controls counts, durations, status overlays,
  profession quality, and reminder glows without another inventory/aura read.
- [ConsumableActionBar.GetVisualOptions](../Modules/ConsumableActionBar/ConsumableActionBar.lua)
  maps the Action Bar settings into these options and disables persistent
  reminder glows. The temporary frame can still show Flask's reminder.

In combat, the Action Bar keeps the action prepared before combat. The surface
merges new public status/duration information with that prepared state, so an
updated selection cannot make the icon claim to use an item the secure button
has not been rebound to. Flyouts and glows remain closed/off; protected action
and layout changes are applied after combat. The temporary frame hides in combat.

## Follow one flask use through the running addon

With the Flask category wired as above, a click can follow this path:

```text
Prepared item button is clicked
    -> WoW applies the flask buff and consumes an item
    -> Controller receives aura/inventory events
    -> Changed inputs are read
    -> Flask.Select / Observe / Evaluate run as needed
    -> Flask.Present describes the updated button
    -> Runtime builds a snapshot
    -> Each requesting display applies its changed visuals/actions
```

The event handler calls `Invalidate`, which simply means "this saved input may
be out of date; read it again":

```lua
Controller.Invalidate("playerAuras")
Controller.Invalidate("inventory", { scope = { [itemID] = true } })
```

The normal refresh delay is 0.2 seconds. If several aura events arrive before
that refresh runs, the controller reads the current aura list once. If two
different item IDs change, it remembers both IDs and reads both. A request to
refresh all inventory replaces the need to track individual IDs for that batch.
It does not store and replay each event in order; it needs the current answer.

If both item counts and the buff changed, Flask's selection and observation can
both change. If only the buff changed, its cached selection and flyout choices
are reused. The controller also compares newly read inputs with the saved
values, so an event that reports no actual change need not rebuild the button
result.

Right-clicking a flyout choice takes a shorter route:
the binder saves its `preferenceKey` and item ID through
[ConsumableFrameItemCache.Set](../Modules/ConsumableFrame/ConsumableFrameItemCache.lua).
That calls `Invalidate("preferences", { nextFrame = true })` and schedules a
macro update. The next selection uses the new preference; it does not need a
new aura scan. `nextFrame` skips the normal delay when starting a new batch;
if one is already scheduled, the change joins it.

## Adapting the walkthrough to a new button category

For a new category, the connections are the same as Flask's. For example,
Inky Black Potion is a smaller complete implementation you can follow:

| Piece | Existing example |
| --- | --- |
| Gameplay IDs | [Data/InkyBlackPotion.lua](../Data/InkyBlackPotion.lua) defines the item and applied buff IDs |
| Category identity | The `inkyBlackPotion` catalog entry names domain `InkyBlackPotion` and its temporary setting |
| Settings defaults | `icon_inkyBlackPotion` and `consumablesActionBar_icon_inkyBlackPotion` in `Settings.lua` |
| Item and buff decisions | [Consumables/InkyBlackPotion.lua](../Modules/Consumables/InkyBlackPotion.lua) declares inputs and implements `Select`, `Observe`, and `Evaluate` |
| Button appearance | [Presenters/InkyBlackPotion.lua](../Modules/ConsumableUI/Presenters/InkyBlackPotion.lua) returns its optional-use icon/buff display without a readiness mark |

A new category's domain table is assigned to `RCC.Consumables[domain]`, and its
presenter to `RCC.ConsumablePresenters[domain]`, using the same `domain` name as
the catalog. Its fallback icon goes in `Data/Settings.lua`. Add its files to
the TOC alongside their equivalents: gameplay data before modules, domain and
presenter files before the runtime/controller and UI consumers.

If the new button supports a saved item preference, add a named entry to
`ConsumableItemCacheKey` in `ConsumableFrameItemCache.lua`. `ReadPreferences`
collects the keys from that table. Use the same key in the selection dependency
(like `preferences.flask`) and in the primary/flyout actions' `preferenceKey`,
so a right-click saves the value that the selector reads.

Choose the phases that match the button's behavior:

- An inventory-only button can omit `Observe`. If selection is already the whole
  answer, it can also omit `Evaluate`; the runtime passes
  `{ selection = selection, action = selection.action }` to the presenter.
- An item with an active buff can use the same `ConsumableEffects` helpers as
  Flask. Inky Black Potion uses `Inventory = { itemID = ... }` instead of a list.
- A spell-only button does not need inventory reads.
  [Recuperate.lua](../Modules/Consumables/Recuperate.lua) returns an icon and a
  `ConsumableState.CreateSpellAction` from `Select`, with no observation or
  evaluation function.
- A button whose availability changes with context expresses that in its model
  and presenter. [Vantus.lua](../Modules/Consumables/Vantus.lua) also sets
  `allowFlyout = false` and removes the action while a rune is active.
- A button that renders a cooldown, such as Repair, sets `hasCooldown = true`
  in the catalog so its widget exists, and supplies `cooldown.start` and
  `cooldown.duration` in its button state.

Existing input names already have readers and event handling. Adding another
item-plus-buff category does not need a new controller branch. For genuinely
new information, the connection points are
[ConsumableInputs.lua](../Modules/Consumables/ConsumableInputs.lua) for reading it,
`ConsumableDemand.lua` for any prerequisite inputs, and
`ConsumableStateController.lua` for reading it on the relevant events.

## Two related paths that do not work exactly like Flask

### Raid buffs use targeted aura queries

The personal Raid Buff button checks the buff supplied by the player's class
on eligible group members. Its `groupAuras` input contains each member's
`available`, `has`, and `expirationTime` values, not their full aura lists.

The baseline in [Data/RaidBuffs.lua](../Data/RaidBuffs.lua) contains the class
spells and class-specific variants such as Blessing of the Bronze. Item-granted
alternatives are separate: `RCC.Data.AddRaidBuffItemAuras` maps a primary class
buff spell ID to a list of applied item aura spell IDs. Put those entries in
`Data/<expansion>/RaidBuffs.lua`; the TOC loads only the current expansion's file
after the baseline. Midnight currently has no registered item alternatives.
The BfA war-scroll entries are retained in their expansion file but not loaded.
The combined accepted-ID list is shared by matching, targeted queries, and
secrecy checks, so an unloaded legacy item cannot affect a current buff's status.

[ConsumableInputs.ReadGroupAuras](../Modules/Consumables/ConsumableInputs.lua)
uses [RaidBuffStatus.lua](../Modules/RaidBuffStatus.lua). That module can reuse a
fresh full player scan when it gives a definite answer; otherwise it searches
the accepted spell IDs with `HelpfulAuraScan.FindFirstBySpellIDs`.

In `AuraScan.lua`, `FindBySpellID` queries one ID using
`C_UnitAuras.GetUnitAuraBySpellID`. `FindFirstBySpellIDs` calls it for each
alternative and returns the first **found buff**, not merely the first
successful query. If none is found, every alternative must be confirmed absent
before it can return `available = true`.

At login, RCC caches Blizzard's NeverSecret policy for every supported
raid-buff variant. This also lets a finished full scan confirm those buffs
missing even when an unrelated aura's ID was unreadable: if all accepted IDs
are NeverSecret, that unreadable aura cannot be one of them.

If the scan still cannot answer a raid-buff category, `RaidBuffStatus.FinalizeScan`
uses the same targeted lookup, including for Raid Status Frame columns. For
example, an item alternative may not be NeverSecret but may be readable right
now. `FindBySpellID` checks `C_Secrets.ShouldSpellAuraBeSecret` before querying
that alternative. A found buff confirms presence; all alternatives confirmed
absent means Missing; otherwise the category stays Unknown. Inaccessible units
stay Unknown. Confirmed full-scan results do not need this extra lookup, and a
successful lookup does not mark the whole scan available for food, other
consumables, or chat reports.

### Managed macros share selection, not the UI snapshot

A macro may need an item while both personal displays are disabled.
Consequently, its getter reads fresh selection inputs instead of asking for
the last button snapshot. Flask's adapter is:

```lua
function Flask.GetItemCandidate(preserveUnavailable)
    return S.Unpack(Flask.Select(
        RCC.ConsumableInputs.ReadSelection("flask"),
        preserveUnavailable
    ))
end
```

The Flask macro calls this without `preserveUnavailable`, allowing its available
fallback selection. The UI passes `true` to retain an unavailable saved choice.
Both use the same selector, with an explicit difference in how its result
should be chosen.

A new personal button does not automatically add a managed macro, Raid Status
Frame column, or chat-report section. Macros are defined separately in
[ConsumableMacros.lua](../Modules/ConsumableMacros/ConsumableMacros.lua);
group rendering and reporting have their own consumers and lifecycle.
