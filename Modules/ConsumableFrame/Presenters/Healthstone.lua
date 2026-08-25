local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Healthstone = RCC.Consumables.Healthstone or {}

local Healthstone = RCC.Consumables.Healthstone

local ButtonState = RCC.ConsumableState
local F = RCC.F
local ItemCandidates = RCC.ConsumableFrameItemCandidates

function Healthstone.ResolveState()
    local showHealthstone = F.hasClassInRoster("WARLOCK")
    local totalCount = ItemCandidates.SumCounts(
        RCC.db.healthstoneItemIDs,
        ItemCandidates.BAGS_WITH_USES
    )

    if totalCount > 0 then
        return ButtonState.Create({
            applicable = showHealthstone,
            countText = tostring(totalCount),
            statusTexture = ButtonState.READY_TEXTURE,
            desaturated = false,
            tooltipItemID = RCC.db.healthstoneItemID,
            clickHintItemID = RCC.db.healthstoneItemID,
            action = ButtonState.CreateItemAction(
                RCC.db.healthstoneItemID,
                { available = true }
            ),
        })
    end

    return ButtonState.Create({
        applicable = showHealthstone,
        countText = "0",
        tooltipItemID = RCC.db.healthstoneItemID,
        action = ButtonState.CreateItemAction(
            RCC.db.healthstoneItemID,
            { available = false }
        ),
    })
end
