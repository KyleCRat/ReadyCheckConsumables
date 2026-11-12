local _, RCC = ...

-- Curate a few useful changes, not a second full changelog. Keep the release
-- key aligned with the generated notes; unmatched releases simply have no cards.
local function settingsButton(text, destination)
    return {
        type = "button",
        options = {
            text = text,

            onClick = function()
                return RCC.OpenSettings(
                    RCC.settingsCategories[destination]:GetID()
                )
            end,
        },
    }
end

RCC.ChangelogHighlights = {
    ["12.1.5-30"] = function()
        return {
            {
                title = "Choose preferences from fleeting items",
                emphasis = "requested",
                body = "Right-click a fleeting flask or potion to save its regular rank-2"
                    .. " version as your preference, even if you have none in your bags."
                    .. " Matching fleeting items take priority while available.",
            },
            {
                title = "Adjust Action Bar layering",
                body = "The Action Bar now defaults to Medium, matching Blizzard's action bars."
                    .. " Use Frame Strata under Position to adjust how it overlaps other UI elements.",
                controls = {
                    settingsButton("Action Bar settings", "actionBar"),
                },
            },
        }
    end,
}
