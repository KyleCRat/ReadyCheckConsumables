local _, RCC = ...

RCC.ConsumablePresenters = RCC.ConsumablePresenters or {}
local Repair = {}
RCC.ConsumablePresenters.Repair = Repair

local ButtonState = RCC.ConsumableState

local OUT_OF_ITEMS = "No Repair Items found in Bags"

local function getCountText(candidate)
    if candidate and candidate.reusable then
        return ""
    end

    return tostring(candidate and candidate.count or 0)
end

local function createFlyoutChoices(candidates, selectedItemID)
    if not candidates or #candidates <= 1 then return end

    local choices = {}

    for i = 1, #candidates do
        local candidate = candidates[i]

        if candidate.itemID ~= selectedItemID then
            local choice = ButtonState.CreateItemChoice(candidate, {
                available = candidate.ready,
                countText = getCountText(candidate),
                suppressGlow = true,
            })

            choice.cooldown = candidate.cooldown
            choice.desaturated = not candidate.ready
            choices[#choices + 1] = choice
        end
    end

    if #choices > 0 then
        return choices
    end
end

function Repair.Present(model)
    local candidate, candidates = RCC.ConsumableSelection.Unpack(model.selection)
    local itemID = candidate and candidate.itemID
        or model.selection.defaultCandidate.itemID
    local buttonState = ButtonState.Create({
        countText = getCountText(candidate),
        tooltipItemID = itemID,
        clickHintItemID = itemID,
        icon = candidate and candidate.icon
            or model.selection.defaultCandidate.icon,
        showStatusTexture = false,
        suppressGlow = true,
    })

    -- The desired primary can switch when a reusable device comes off cooldown.
    -- Keep per-item visuals available for whichever action is prepared in combat.
    buttonState.itemVisuals = {}
    buttonState.missingItemVisual = { desaturated = true, unavailable = { text = OUT_OF_ITEMS } }

    for _, item in ipairs(candidates) do
        buttonState.itemVisuals[item.itemID] = {
            cooldown = item.cooldown,
            desaturated = not item.ready,
        }
    end

    if candidate then
        buttonState.cooldown = candidate.cooldown
        buttonState.action = model.action

        if candidate.ready then
            buttonState.desaturated = false
        end
    else
        ButtonState.SetUnavailable(buttonState, OUT_OF_ITEMS)
    end

    return buttonState
end

function Repair.Choices(selection)
    local candidate = selection.candidate or selection.defaultCandidate

    return createFlyoutChoices(selection.candidates, candidate.itemID)
end
