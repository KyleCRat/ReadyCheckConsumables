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
[poison, raid-buff, and macro differences](#related-paths-that-do-not-work-exactly-like-flask).

## 1. Register the usable items and their buffs

Start in [Data/12_Midnight/Flasks.lua](../Data/12_Midnight/Flasks.lua). One of
its existing families is registered like this:

```lua
local _, RCC = ...
local FLEETING = RCC.ConsumableVariant.FLEETING

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

Family membership also limits fleeting overrides: a fleeting Resistance flask
can replace a preferred regular Resistance flask, but not a flask with another
effect. Registration marks fleeting items as ineligible saved preferences.
Healing potions use the same `family` and `variant` metadata in their ordered
item records; concentrated and ordinary Silvermoon potions are separate families.

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
    logic = RCC.Consumables.Flask,
    presenter = RCC.ConsumablePresenters.Flask,
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
| `logic = RCC.Consumables.Flask` | References the module that declares inputs, selects items, and checks buff status |
| `presenter = RCC.ConsumablePresenters.Flask` | References the module that turns those results into button and flyout display states |
| `settingKey` | Enables this category on the temporary frame |
| `defaultIcon` | Gives the renderer an icon when the result has no item or aura icon |
| `temporaryClickable` | Controls whether the temporary frame creates a clickable control |
| `tooltipAction` | Supplies the verb for the click hint |

`logic` and `presenter` hold the module tables themselves, not names to look up
later. The TOC loads those modules before the catalog so the references exist
when these definitions are created. Their names do not need to match, and
multiple categories can reference the same logic or presenter.

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
    evaluation = { "instance.warningSeconds" },
    expiration = "playerAuras",
}
```

An **input** is data already read from the game or saved settings, including
values derived from that information. For Flask, that means item counts and
icons, the saved flask preference, the player's helpful auras, and the
duration-warning threshold.

A **reader** is the function that obtains that data. For example,
`ConsumableInputs.ReadInventory` calls the item APIs and returns a table keyed
by item ID. `ReadPreferences` reads saved item choices. The controller obtains
`playerAuras` through `HelpfulAuraScan.ScanUnit("player")` in
[AuraScan.lua](../AuraScan.lua), which leaves restricted fields out of the result.

Instance, location, and class information have separate readers and inputs:

| Input | Reader and contents | Example use |
| --- | --- | --- |
| `instance` | `ReadInstance`: `instanceID`, `instanceType`, and derived `warningSeconds` | Choose the raid's vantus rune; decide whether a buff expires too soon |
| `location` | `ReadLocation`: `uiMapID` | Offer the Brawler's Guild healing potion in its venues |
| `class` | `ReadClass`: `classToken` and the provided `raidBuff` definition | Decide which raid buff the personal Raid Buff button checks |

The warning threshold is derived from instance type: 30 minutes in a dungeon
(`party`) and 10 minutes elsewhere. It is not another live query or a user
setting. The class input describes which buff to check, not whether it is
present; actual buff observations are in `playerAuras`, `playerSpellAuras`, and
`groupAuras`. `playerSpellAuras` contains targeted results by spell ID rather
than a full scan; the poison example below shows how a category requests them.

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

The dotted name `preferences.flask` means that category's capacity-keyed lists
in the inputs table. Unchanged lists retain their identity, so a food-preference
change does not require Flask to select an item again.
Likewise, `instance.warningSeconds` compares only the threshold. A new instance
ID with the same threshold does not by itself require Flask's evaluation to run.

### How this declaration leads to event handling

Neither `Flask.lua` nor its presenter registers bag or aura events.
[ConsumableStateController.lua](../Modules/Consumables/ConsumableStateController.lua)
handles those events for all categories. Existing examples are:

| Change | Input marked for another read |
| --- | --- |
| `UNIT_AURA` for the player | `playerAuras` and/or `playerSpellAuras`, where requested |
| Spellbook or player specialization changes | Known `spells`, targeted `playerSpellAuras`, `class`, and `weapons`, where requested |
| `ITEM_COUNT_CHANGED` for a tracked item | That item in `inventory` |
| `BAG_UPDATE_DELAYED` | All requested inventory items |
| `ITEM_DATA_LOAD_RESULT` for a tracked item | That item's count/icon/quality data |
| Right-clicking a preferred flask | `preferences`, through `ConsumablePreferences` |
| Confirming an opted-in application | `history`, using the observations already read |
| `ZONE_CHANGED` or `ZONE_CHANGED_INDOORS` | `location` only |
| `ZONE_CHANGED_NEW_AREA` or `PLAYER_DIFFICULTY_CHANGED` | `instance`, `location`, `roster`, `playerAuras`, `playerSpellAuras`, and `groupAuras`, where requested |
| `PLAYER_ENTERING_WORLD` | All currently requested inputs |

Local movement does not request another aura scan or inventory read in this
pipeline. Major zone/difficulty transitions explicitly request fresh aura
observations, even if the instance ID and type are unchanged. Loading screens
refresh all requested inputs. Changing the warning threshold itself only
recalculates status and deadlines using the cached buff expiration times.

The controller only watches data that a personal display currently needs.
Each display registers a **consumer**:
`GetCategories()` says which buttons it needs, and `ApplySnapshot()` receives
their results: icon, text, action, and other button instructions. Those results
are packaged in a snapshot; section 6 shows the table's contents.

`GetDisplayedItemIDs()` returns the primary item ID for each displayed category.
This keeps an item's cooldown readable after its last copy is used, especially
when combat prevents rebinding the button. The controller only includes IDs from
that display's requested categories and the category's registered cooldown items.

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
preferences, player auras, and instance information. A Flask-only display does
not request location or class information, so it does not subscribe to local
zone or spell-data events for those inputs.

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

### `Select(inputs)`: what should clicking use?

Flask's selector examines the registered items in `inputs.inventory` and the
saved choice in `inputs.preferences.flask`. It asks the shared
[ConsumableSelection.lua](../Modules/Consumables/ConsumableSelection.lua)
helpers to construct and order its choices:

```lua
local choices = Selection.FamilyCandidates(inputs.inventory, {
    itemIDs = RCC.db.flaskItemIDs,
    itemData = RCC.db.flaskItemData,
    preferredID = RCC.ConsumablePreferences.GetItemID(inputs.preferences, PREFERENCE_KEY),
})

return Selection.Resolve(choices, { preferenceKey = PREFERENCE_KEY })
```

Every item selector keeps three concepts separate:

| Field | What it contains | Flask example |
| --- | --- | --- |
| `preferred` | The exact saved item, including a zero count if it has run out | Regular Resistance R1 |
| `overrides` | Available special choices that should take priority without changing the preference | Fleeting Resistance, in data-defined rank order |
| `fallbacks` | Ordered automatic choices when no preference exists, or eligible macro alternatives | Other Resistance ranks first, then other flask families |

Buttons take the first override, otherwise the preference, otherwise the first
fallback. A different regular rank never replaces an out-of-stock preference
on the button. A matching fleeting item does: if Resistance R1 is preferred
but only fleeting Resistance R2 is carried, the button shows fleeting R2.
When the fleeting item runs out, it returns to R1 and shows its current count.
Fleeting items from another family are not overrides.

A **candidate** is an item that selection can consider. For example, a result
with a carried regular preference and no fleeting override might contain:

```lua
local preferred = {
    itemID = 241320,
    count = 3,
    icon = flaskItemIcon,
    -- Also includes quality and family metadata.
}

selection = {
    preferred = preferred,
    overrides = {},
    fallbacks = orderedFlaskFallbacks,
    candidate = preferred,
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
the flyout, including items that may be ineligible for automatic fallback.
`action` describes what clicking should do; it does not use the item or change
a secure button yet. `Selection.Resolve` creates it through
`ConsumableState.CreateItemAction`. If the selected item has zero count,
`unavailable` is true and there is no action.

The same result supplies macros: `Selection.GetAvailableCandidates` returns
overrides, the preference if carried, and eligible fallbacks, skipping missing
items and duplicates. Most item macros use the first two; Augment uses only
the first. There is no macro-specific preference rule or second selection pass,
and selection never writes a preference.

Categories still decide their own priorities and eligibility. Combat potions
allow fallbacks within the preferred damage or mana type; utility potions stay
within their family. Healthstones have no saved preference and order Demonic
before normal. A weapon spell can supply `overrideAction` instead of an item
override. Repair orders ready reusable devices before consumables. Categories
that need an empty-inventory icon use `defaultCandidate` for that display data;
it is not a usable fallback.

Augment's Prefer Unlimited setting changes only the candidate sort: carried
unlimited runes come before consumable runes, even from newer expansions.
The selector supplies `preferred` and ordered `fallbacks`, with no override.
An explicit choice still wins; an out-of-stock preference remains on the
button, while macros can select the next available choice when rebuilt.
Clearing the preference restores automatic selection. Cooldowns are attached
for display only and never reorder or exclude a rune. Augment macros use one
item with no backup, so an unlimited rune on cooldown cannot spend a consumable.

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
        inputs.instance,
        now
    )
end
```

The return value is called the **model**. It combines the selected item/action,
scan availability, and the buff's current meaning. For the observation above,
at `now = 1000` with a ten-minute warning threshold, the relevant fields are:

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

Item cooldowns have their own completion deadline in the controller, using the
same timer. Finishing an unlimited rune's cooldown rereads `cooldowns`, not its
buff aura; its duration label and buff-expiration checks continue independently.

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
| `tooltipItemID`, `tooltipSpellID`, `tooltipAuraID` | Item, spell, or active-aura tooltip information |
| `tooltipAppliedItemID`, `tooltipAppliedSpellID` | Optional "Currently applied" line, separate from the selected click action |
| `action` | Prepared click behavior described by an item/spell action |
| `glow`, `suppressGlow` | Reminder request and category-specific glow suppression |
| `applicable` | Whether this category applies to the current situation |

The runtime calls `ConsumableState.Normalize` once on each newly built primary
state and flyout choice, filling omitted fields from `State.DEFAULTS` before
sharing the table. Presenters return fresh tables; renderers and displays read
the finalized states without changing them or making another normalized copy.
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

`CreateItemAction` leaves out `preferenceKey` for items that cannot be preferred,
such as fleeting consumables and the venue-only Guild potion. Both the primary
and flyout therefore omit their right-click preference action and hint, while
retaining left-click use wherever that surface allows it.

The runtime keeps those choices until the selection changes, then attaches them
to the primary state as `flyoutChoices`. A duration update does not rebuild
the choices. A category with no alternatives can omit `Choices` entirely.

Categories whose alternatives display active effects can set
`choicesUseModel = true` on their presenter. Their `Choices(model)` receives
the evaluated effects as well as `model.selection`. Set `flyoutStatus = true`
on those choice states to opt into status overlays; ordinary item flyouts keep
their existing appearance.

`State.SameInteractions` compares action identities, preference targets, and
choice order, separately from visual fields. Effect-only changes use
`Flyout.ApplyChoiceVisuals`: no creation, secure rebinding, layout, or hover
changes. This is how both active poisons can gain checkmarks without closing
the flyout.

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
| Action, preference target, or flyout choice order | [ConsumableActionBinder.Bind](../Modules/ConsumableUI/ConsumableActionBinder.lua) prepares the secure click action; [ConsumableFlyout.SetChoices](../Modules/ConsumableUI/ConsumableFlyout.lua) updates alternatives |
| Applicability/visibility | The owning frame decides which buttons occupy its layout |

This is why changing only a duration label does not rebind the item action.
The button renderer also remembers the values it last drew: changing `25m` to
`24m` updates that text without resetting the unchanged icon or colors. Hover
icons and display options use the same checks. Releasing a button clears its
render cache so it is fully redrawn when reused.

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
creates a separate merged state only when the button needs a visual update.
It combines new public status/duration information with the prepared action
without editing either source table, so an updated selection cannot make the
icon claim to use an item the secure button has not been rebound to. Flyouts
and glows remain closed/off; protected action and layout changes are applied
after combat. The temporary frame hides in combat.

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

Right-clicking a primary button or flyout choice takes a shorter route:
the binder passes its typed identity, preference key, and capacity to
[ConsumablePreferences.Toggle](../Modules/Consumables/ConsumablePreferences.lua).
An existing preference is removed; a new choice is appended, evicting the oldest
preference if the branch is full. This calls
`Invalidate("preferences", { nextFrame = true })` and schedules a macro
update when the choice changes. The next selection uses the new preference, or
the category's automatic overrides and fallbacks after clearing it; neither
needs a new aura scan. `nextFrame` skips the normal delay when starting a new
batch; if one is already scheduled, the change joins it.

The preference owner also rejects attempts to save blocked items.
`ReadPreferences` returns a detached snapshot, ignoring any fleeting choice
saved by an older version rather
than guessing a regular replacement. Choosing a regular item explicitly creates
the new preference. Inventory changes, overrides, and macro refreshes only read it.

The preference owner routes these reads and writes to character storage by default.
The character-owned **Use profile-specific consumable preferences** checkbox
switches it to the active settings profile instead. No consumer needs its own
storage check: `ReadPreferences`, the tooltips, and right-click actions all use
that owner. Switching stores refreshes the preference input and macros without
copying choices or falling back to the other store when a choice is absent.

All categories use the same storage shape, including ordinary single-item ones:

```lua
consumablePreferences = {
    flask = {
        [1] = { { kind = "item", id = flaskItemID } },
    },
    lethalPoison = {
        [1] = { { kind = "spell", id = 2823 } },
        [2] = {
            { kind = "spell", id = 2823 },
            { kind = "spell", id = 381664 },
        },
    },
}
```

The numeric keys are capacities, not array positions. The inner lists are dense,
ordered by preference selection age. Changing talents selects another branch;
it does not truncate, copy, or overwrite the previous one.
`GetItemID(preferences, key)` reads the ordinary capacity-one item choice.
Multi-choice selectors use `GetChoices(preferences, key, capacity)`.

`ProfileMigration` converts the old flat item choices for every profile through
the Profiles library's payload migration from version 1 to 2, including inactive
profiles. Characters use their own ordered `preferenceMigrationVersion` steps:
0 to 1 seeds the original shared choices once; 1 to 2 converts their format.
A character already at version 1 runs only the conversion. Completed steps
do not run again, and choices already converted by a development build are kept.
The original frozen legacy seed remains available for later-login characters;
an already-migrated character's cleared preferences are never seeded again.

### Remembering applications without changing preferences

[ConsumableHistory](../Modules/Consumables/ConsumableHistory.lua) always writes
to the character DB. It uses the same category/capacity/typed-identity shape,
but stores a bounded recent-use list rather than explicit preferences.
It never copies a profile's choices.

A domain opts in with `GetApplications(inputs, definition)`, returning an
ordered list of confirmed choices, observation availability, and capacity.
It can also return a fourth value: public application evidence indexed by typed
identity. Poisons use expiry timestamps to recognize a genuine reapplication,
while weapon enchants need only recognize a different applied item.
Its observation dependencies must include the evidence and capacity inputs.
The shared owner records newly observed applications; repeated reads,
failed clicks, and preference changes do not record use. Unavailable observations
and expired effects do not erase history. Reloading does not reorder an
established list.

The controller calls this after the requested observations are read and before
selection. It does not scan auras again. A `categoryHistory` selection dependency
compares only `inputs.history[definition.key]`; `categoryPreference` similarly
reads that category's saved preferences. Weapon enchants retain their
`slotPreference` and `slotWeapon` aliases.

History supplies eligible **fallbacks**, not another priority tier.
`Selection.ResolveChoices(overrides, preferences, fallbacks, capacity)` takes
distinct typed identities in that order. The ordinary item `Resolve` also uses
this helper with capacity one. Missing explicit items still occupy their slot;
unavailable historical items do not become automatic choices.
An optional fallback comparator stabilizes casting order after the recent-use
list chooses membership. Thus refreshing either member of the same remembered
pair does not change its cast sequence, while a newly used third spell can
replace the least recently used one. Explicit preference order is untouched.

Weapon enchants keep the saved item choice separate from what is applied.
A known class enchant remains primary while active, and a weapon without an
enchant defaults to its eligible class spell. With an oil applied, selection uses the
saved item choice; without one, it tries the most recently applied oil still
carried, then normal inventory priority. Applying a class spell does not erase
oil history. When the
oil expires, an eligible class spell takes priority again without clearing the
saved oil choice.

For example, preferring Mana Oil while Phoenix Oil is active shows Mana Oil's
icon, count, quality, and click action. The check and duration still describe
Phoenix Oil, identified by the tooltip's "Currently applied" line. Weapon scans
and macro refreshes never save a different preference. During combat, the
prepared click action and its identifying visuals stay fixed, while the
applied-enchant status and tooltip details can still update.

## Adapting the walkthrough to a new button category

For a new category, the connections are the same as Flask's. For example,
Inky Black Potion is a smaller complete implementation you can follow:

| Piece | Existing example |
| --- | --- |
| Gameplay IDs | [Data/InkyBlackPotion.lua](../Data/InkyBlackPotion.lua) defines the item and applied buff IDs |
| Category identity | The `inkyBlackPotion` catalog entry references its logic and presenter modules and names its temporary setting |
| Settings defaults | `icon_inkyBlackPotion` and `consumablesActionBar_icon_inkyBlackPotion` in `Settings.lua` |
| Item and buff decisions | [Consumables/InkyBlackPotion.lua](../Modules/Consumables/InkyBlackPotion.lua) declares inputs and implements `Select`, `Observe`, and `Evaluate` |
| Button appearance | [Presenters/InkyBlackPotion.lua](../Modules/ConsumableUI/Presenters/InkyBlackPotion.lua) returns its optional-use icon/buff display without a readiness mark |

Assign the new logic and presenter tables to the addon namespace, then reference
them in the catalog's `logic` and `presenter` fields. For example, Inky Black
Potion uses `RCC.Consumables.InkyBlackPotion` and
`RCC.ConsumablePresenters.InkyBlackPotion`. Its fallback icon goes in
`Data/Settings.lua`. Add its files to the TOC alongside their equivalents:
gameplay data before modules, logic and presenter files before the catalog,
then the runtime/controller and UI consumers.

If the new button supports saved preferences, add a named entry to
`ConsumablePreferenceKey` in `ConsumablePreferences.lua`. Use the same key in the selection dependency
(like `preferences.flask`) and in the primary/flyout actions' `preferenceKey`,
so a right-click saves the value that the selector reads.

Have the selector provide its `preferred`, `overrides`, and `fallbacks` to
`ConsumableSelection.Resolve`. Omit concepts the category does not use; a
category without preferences only needs ordered fallbacks. Keep the full flyout
`candidates` separate if manual choices can go beyond automatic fallback rules.
Flasks, combat potions, and healing potions share `FamilyCandidates` for matching
fleeting overrides; combat potions add their type restriction through
`canFallbackToFamily`.

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
- A button whose availability depends on the current instance expresses that in
  its model and presenter. [Vantus.lua](../Modules/Consumables/Vantus.lua) also sets
  `allowFlyout = false` and removes the action while a rune is active.
- A button that renders an item cooldown, such as Repair, potions, pausing items,
  or an unlimited augment rune, declares `cooldowns` as an input and lists the
  tracked items in `Inventory.cooldownItemIDs`. Only carried or displayed items
  from requested categories are queried. Before resolving the new selection,
  call `ConsumableSelection.ApplyItemCooldowns(selection, inputs.cooldowns,
  Inventory.cooldownItemIDs)`. In its presenter, call
  `ConsumableState.ApplyItemCooldowns(state, model.selection)`; flyout choices
  inherit `candidate.cooldown`. Set `hasCooldown = true` in the catalog to create
  the native widget. The controller schedules a fresh cooldown read when the
  earliest item timer finishes, so categories need no separate timer.

An item cooldown need not change selection. Repair uses it to prefer a ready
device, but Augment keeps its selected rune even on cooldown, and
potions keep their preference/family/venue selection rules. The shared
`itemCooldowns` map lets the Action Bar show the prepared item's cooldown in
combat even when a different item becomes the desired selection or the
prepared item has been used up. Buff status remains separate from item reuse.

Existing input names already have readers and event handling. Adding another
item-plus-buff category does not need a new controller branch. For genuinely
new information, the connection points are
[ConsumableInputs.lua](../Modules/Consumables/ConsumableInputs.lua) for reading it,
`ConsumableDemand.lua` for any prerequisite inputs, and
`ConsumableStateController.lua` for reading it on the relevant events.

## Related paths that do not work exactly like Flask

### Rogue poisons are spell choices, not weapon-slot enchants

[Data/RoguePoisons.lua](../Data/RoguePoisons.lua) lists lethal and non-lethal
poisons separately. For these spells, the cast ID is also the player's buff
ID. Add a poison to its ordered list; the shared domain and presenter use that
list for both detection and flyout choices.

Both catalog entries reference `RCC.Consumables.RoguePoison` as their `logic`
and `RCC.ConsumablePresenters.RoguePoison` as their `presenter`, with `poisonType`
choosing the list. `Select(inputs, definition)` and `Observe(inputs, definition)` receive
the whole catalog definition, just as WeaponEnchant reads `definition.weaponSlot`.
The poison entries also declare `classToken = "ROGUE"`, so other classes do not
request their data or display their buttons. Their `supportedCapacities = { 1, 2 }`
declares the allowed selection counts; categories without a declaration default
to `{ 1 }`. The domain selects the current count from its inputs, and the runtime
checks that it is supported by the category.

`GetSpellIDs(definition)` declares which spells need known/name/icon metadata
in `inputs.spells`. `GetPlayerAuraSpellIDs(definition)` separately declares the
buff IDs for `inputs.playerSpellAuras`. The poison spell list also includes
Dragon-Tempered Blades for its capacity check, but the aura list does not.
The controller collects only the IDs requested by active categories.

`ReadPlayerSpellAuras` returns entries such as
`[2823] = { available = true, aura = <public aura fields> }`. A readable absence
has no `aura`; an unavailable query has `available = false`. It reuses a fresh
full scan when conclusive, otherwise calls `HelpfulAuraScan.FindBySpellID`.
Requesting poisons alone never requests a full player aura scan.

The data defines capacity one normally and two with Dragon-Tempered Blades.
The selector passes known explicit preferences and remembered applications to
`ResolveChoices`. It fills distinct slots in that order, using the existing
first-known default only when neither preferences nor history supplies a choice.
It never invents a second spell to complete an unestablished pair.

`Effects.ObserveSpells` retains all readable matches and per-spell availability.
`EvaluateMany` checks every slot, schedules the existing duration/expiry
deadlines, and finds the earliest remaining duration. This replaces the former
first-match-only poison result.

At capacity two, `State.ApplyEffectSummary` supplies the applied effects to the
shared view. Native texture masks reveal the first icon in the bottom-left and
the second in the top-right; the icons keep their normal aspect-ratio crop.
Masks are positioned and rotated for the button's dimensions, since changing
texture coordinates on a mask is unsupported by the client.
Empty halves show faded category artwork. One centered status covers the whole
summary: a check when both effects are applied, an X when either is missing,
or a question mark when absence cannot be confirmed. All known poisons move
into the flyout, where each applied spell still has its own checkmark and duration.
The summary's tooltip separates applied effects, preferences, and prepared casts.

`ConsumableButtonView` keeps summary layouts keyed by count in `SUMMARY_LAYOUTS`.
It prepares the category's declared layouts before combat and switches their
visibility when the active count changes. Supporting a third effect requires a
three-part layout and a declared capacity of 3; the preference/history format
does not change. Declaring a count without a layout raises an error instead of
silently drawing it with the two-part layout.

`CreateSpellSequenceAction` emits one ordinary spell action for one resolved
choice, or a `spellSequence` descriptor for a pair. The shared binder prepares
`/castsequence reset=combat` with localized spell names outside combat.
Each successful click advances one spell; current buffs never advance or skip
the sequence. During combat its action remains fixed while applied icons,
durations, and status can change. Flyouts remain disabled in combat. No managed
poison macro is added.

### Raid buffs use targeted aura queries

The personal Raid Buff button checks the buff supplied by the player's class
on eligible group members. Its `groupAuras` input contains each member's
`available`, `has`, and `expirationTime` values, not their full aura lists.
The group reader requires `roster` and `class` to know whom and what to check;
`ConsumableDemand` includes those inputs whenever `groupAuras` is requested.
Class/spell-data events reread the class information, and a changed class input
refreshes its group observations without requesting a full player aura scan.

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

A macro may need an item while both personal displays are disabled. The private
`selectMacroAction` helper in `ConsumableMacros.lua` reads fresh selection inputs
instead of asking for the last button snapshot. For Flask, it uses:

```lua
local inputs = RCC.ConsumableInputs.ReadSelection("flask")
local selection = Flask.Select(inputs)
local choices = RCC.ConsumableSelection.GetAvailableCandidates(selection)
local primary = choices[1]
local backup = choices[2]

-- Write the primary and, if present, backup into separate /use lines.
```

This reads the selector's ordering without modifying its inventory inputs or
selecting again. Most item macros take the first two distinct available choices:
automatic overrides first, then the preferred item, then eligible fallbacks.
Augment calls `selectMacroAction("augment", { includeBackup = false })` to emit
only the primary item-use line, regardless of which rune or setting is selected.
A cooling-down unlimited rune stays selected; there is no second item to try.
With no items available there is no item action. A missing preferred rank can
remain on the button while the macro selects another rank when rebuilt;
neither changes the saved choice. Spell actions remain a single cast with no
item backup.

Healing-potion location rules live in `HealingPotion.Select`, shared by both
personal displays and macros. `ReadLocation` supplies the player's `uiMapID`,
and HealingPotion declares `location.uiMapID` as a selection dependency. Its
inventory declaration combines the normal potion list with the separate
Brawler's Guild item from `Data/HealingItems.lua`.

Inside a listed venue, the selector puts a carried Guild potion first and
returns it as the primary override, ahead of matching fleeting potions. Its
action omits `preferenceKey` so it cannot replace the saved normal potion;
regular candidates still supply the flyout's preference choices. Outside the
venue, or without the Guild potion, selection follows the normal rules. The
macro uses the next available choice as backup, with no macro-specific location
override or second inventory read.

Local, indoor, and major zone events refresh location for the personal pipeline
and trigger the macros' independent live selection reads. The personal pipeline
keeps its cached inventory on local movement; macros still read the current
items they need even if both displays are disabled. Secure button actions and
macro text keep their prepared choices during combat and switch after combat ends.

Managed and inline macros share these item lists. Inline markers own
their first line and the adjacent `#RCCI+` continuation lines, so a refresh
replaces the whole group without duplicating backups or altering unmarked text.
These lines are prepared outside combat; using a backup in combat does not
require a macro rewrite.

A new personal button does not automatically add a managed macro, Raid Status
Frame column, or chat-report section. Macros are defined separately in
[ConsumableMacros.lua](../Modules/ConsumableMacros/ConsumableMacros.lua);
group rendering and reporting have their own consumers and lifecycle.
