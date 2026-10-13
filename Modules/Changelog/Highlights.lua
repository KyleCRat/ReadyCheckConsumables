local _, RCC = ...

-- Curate a few useful changes, not a second full changelog. Keep the release
-- key aligned with the generated notes; unmatched releases simply have no cards.
local function categoryControls(category)
    local definition = RCC.ConsumableCatalog.GetDefinition(category)
    local controls = {}

    for _, event in ipairs(RCC.ConsumableCatalog.GetFrameOpenEvents()) do
        controls[#controls + 1] = {
            type = "checkbox",
            getValue = function()
                return RCC.ConsumableCatalog.GetFrameEventEnabled(definition, event.reason)
            end,
            enabled = function()
                return RCC.GetSetting("consumables_enabled"), "Enable the Consumables Frame in its settings first"
            end,
            options = {
                label = "Show " .. definition.label .. " on: " .. event.label,
                tooltip = string.format(event.tooltip, definition.label),
                onChanged = function(checked)
                    RCC.ConsumableSettingsShared.SetFrameEventEnabled(definition, event.reason, checked)
                end,
            },
        }
    end

    controls[#controls + 1] = {
        type = "checkbox",
        getValue = function() return RCC.GetSetting(definition.actionBarSettingKey) end,
        enabled = function()
            return RCC.GetSetting("consumablesActionBar_enabled"), "Enable the Action Bar in its settings first"
        end,
        options = {
            label = "Show on the Action Bar",
            onChanged = function(checked)
                RCC.ConsumableSettingsShared.SetActionBarCategoryEnabled(definition, checked)
            end,
        },
    }

    return controls
end

local function settingsButton(text, destination)
    return {
        type = "button",
        options = {
            text = text,
            onClick = function()
                return RCC.OpenSettings(RCC.settingsCategories[destination]:GetID())
            end,
        },
    }
end

RCC.ChangelogHighlights = {
    Unreleased = function()
        return {
            {
                title = "Choose what to include in chat reports",
                emphasis = "requested",
                body = "Control what chat report announces. The selected announcer's settings are"
                       .. " used. Ensure all members with assist use the same settings if you want"
                       .. " consistent reports.",
                controls = { settingsButton("Chat Report settings", "chatReport") },
            },
            {
                title = "Glider Kits and Slowfall Toy support",
                body = "Add Goblin Glider Kits and collected parasol toys to Consumable Frame or"
                    .. "Action Bar. The button is off by default; choose where you want it below.",
                controls = categoryControls("glide"),
            },
            {
                title = "Invisibility potions support",
                body = "Choose a preferred invisibility potion separately from your combat potions. "
                    .. "This optional button shows your supply and cooldown without group reporting.",
                controls = categoryControls("invisibilityPotion"),
            },
        }
    end,
}
