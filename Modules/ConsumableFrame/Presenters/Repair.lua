local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Repair = RCC.Consumables.Repair or {}

local Repair = RCC.Consumables.Repair

local ButtonState = RCC.ConsumableState
local ItemCandidates = RCC.ConsumableFrameItemCandidates

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

function Repair.ResolveState(now)
    local candidate, candidates = Repair.GetItemCandidate(now)
    local itemID = candidate and candidate.itemID
        or Repair.GetDefaultItemID()
    local buttonState = ButtonState.Create({
        countText = getCountText(candidate),
        tooltipItemID = itemID,
        clickHintItemID = itemID,
        icon = candidate and candidate.icon
            or ItemCandidates.GetIcon(itemID),
        suppressGlow = true,
    })

    if candidate then
        buttonState.cooldown = candidate.cooldown
        buttonState.action = ButtonState.CreateItemAction(itemID, {
            available = candidate.ready,
        })

        if candidate.ready then
            buttonState.statusTexture = ButtonState.READY_TEXTURE
            buttonState.desaturated = false
        end
    else
        ButtonState.SetUnavailable(buttonState, OUT_OF_ITEMS)
    end

    buttonState.flyoutChoices = createFlyoutChoices(candidates, itemID)

    return buttonState
end
