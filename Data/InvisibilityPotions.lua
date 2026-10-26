local _, RCC = ...

RCC.db = RCC.db or {}
RCC.Data = RCC.Data or {}

-- Optional-use potions, separate from combat-potion selection and readiness.
-- Expansion files append items newest-first, then highest-quality-first.
RCC.db.invisibilityPotionItemIDs = {}
RCC.db.invisibilityPotionItemData = {}

function RCC.Data.AddInvisibilityPotionItems(items)
    for _, item in ipairs(items) do
        RCC.db.invisibilityPotionItemIDs[#RCC.db.invisibilityPotionItemIDs + 1] =
            item.itemID
        RCC.db.invisibilityPotionItemData[item.itemID] = item
    end
end
