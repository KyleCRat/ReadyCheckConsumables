local _, RCC = ...

RCC.ConsumablePresenters = RCC.ConsumablePresenters or {}
local InvisibilityPotion = {}
RCC.ConsumablePresenters.InvisibilityPotion = InvisibilityPotion

local ButtonState = RCC.ConsumableState
local PREFERENCE_KEY = RCC.ConsumablePreferenceKey.INVISIBILITY_POTION
local OUT_OF_ITEMS = "No invisibility potions found in bags"
local OUT_OF_PREFERRED_ITEM =
    "Your preferred invisibility potion is not in your bags"

function InvisibilityPotion.Present(model)
    local selection = model.selection
    local candidate = selection.candidate or selection.defaultCandidate
    local state = ButtonState.Create({
        icon = candidate.icon,
        countText = tostring(candidate.count),
        tooltipItemID = candidate.itemID,
        clickHintItemID = candidate.itemID,
        action = model.action,
        desaturated = candidate.count == 0,
        showStatusTexture = false,
        suppressGlow = true,
    })

    ButtonState.SetItemQuality(state, candidate)
    ButtonState.ApplyItemCooldowns(state, selection)

    if candidate.count == 0 then
        ButtonState.SetUnavailable(
            state,
            selection.preferred and OUT_OF_PREFERRED_ITEM or OUT_OF_ITEMS
        )
    end

    return state
end

function InvisibilityPotion.Choices(selection)
    local candidate = selection.candidate or selection.defaultCandidate
    local choices = ButtonState.CreateItemFlyoutChoices(
        selection.candidates,
        candidate.itemID,
        {
            preferenceKey = PREFERENCE_KEY,
            includeSingleChoice = selection.unavailable,
            suppressGlow = true,
        }
    )

    for _, choice in ipairs(choices or {}) do
        choice.showStatusTexture = false
    end

    return choices
end
