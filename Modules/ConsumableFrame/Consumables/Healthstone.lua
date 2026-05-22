local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Healthstone = RCC.Consumables.Healthstone or {}

local Healthstone = RCC.Consumables.Healthstone

local ButtonState = RCC.ConsumableFrameButtonState
local F = RCC.F
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

function Healthstone.GetItemCandidate()
    local best

    for itemID in pairs(RCC.db.healthstoneItemIDs) do
        local count = ItemCandidates.GetCount(
            itemID,
            ItemCandidates.BAGS_WITH_USES
        )

        if count > 0
            and (not best or itemID > best.itemID)
        then
            best = {
                itemID = itemID,
                count = count,
                icon = ItemCandidates.GetIcon(itemID),
            }
        end
    end

    return best
end

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
            tooltipItemID = RCC.db.healthstoneItemID,
        }))
    else
        Renderer.Apply(button, ButtonState.Create({
            showInLayout = showHealthstone,
            countText = "0",
        }))
    end
end
