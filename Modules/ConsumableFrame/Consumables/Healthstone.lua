local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Healthstone = RCC.Consumables.Healthstone or {}

local Healthstone = RCC.Consumables.Healthstone

local ButtonState = RCC.ConsumableFrameButtonState
local F = RCC.F
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

function Healthstone.Update(button)
    local showHealthstone = F.hasClassInRoster("WARLOCK")
    local totalCount = ItemCandidates.SumCounts(
        RCC.db.healthstoneItemIDs,
        ItemCandidates.BAGS_WITH_USES
    )

    if totalCount > 0 then
        Renderer.Apply(button, ButtonState.Create({
            showInLayout = showHealthstone,
            countText = tostring(totalCount),
            statusTexture = ButtonState.READY_TEXTURE,
            desaturated = false,
            tooltipItemID = RCC.db.healthstone_item_id,
        }))
    else
        Renderer.Apply(button, ButtonState.Create({
            showInLayout = showHealthstone,
            countText = "0",
        }))
    end
end
