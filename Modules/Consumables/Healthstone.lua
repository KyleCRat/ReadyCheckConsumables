local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.Healthstone = RCC.Consumables.Healthstone or {}

local Healthstone = RCC.Consumables.Healthstone

local ItemCandidates = RCC.ConsumableFrameItemCandidates

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
