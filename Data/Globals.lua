local _, RCC = ...

RCC.db = RCC.db or {}

RCC.ConsumableVariant = {
    FLEETING = "fleeting",
}

-- Temporary/context-only item IDs never enter saved preferences. Fleeting
-- choices instead resolve to the regular rank-2 item in their own family.
RCC.db.preferenceBlockedItemIDs = {}
RCC.db.preferenceItemAliases = {}

RCC.Data = RCC.Data or {}
local FLEETING_PREFERENCE_RANK = 2

-- Register a complete set of families after their item.family fields are set.
-- Item order and the rank of the clicked fleeting item do not change the target.
function RCC.Data.RegisterFleetingPreferenceAliases(items)
    local regularItemIDs = {}

    for _, item in ipairs(items) do
        if item.variant == nil and item.q == FLEETING_PREFERENCE_RANK then
            regularItemIDs[item.family] = item.itemID
        end
    end

    for _, item in ipairs(items) do
        if item.variant == RCC.ConsumableVariant.FLEETING then
            RCC.db.preferenceBlockedItemIDs[item.itemID] = true
            RCC.db.preferenceItemAliases[item.itemID] =
                regularItemIDs[item.family]
        end
    end
end

--------------------------------------------------------------------------------
--- Expansion Version Constants
--------------------------------------------------------------------------------
RCC.CLASSIC = 1
RCC.THE_BURNING_CRUSADE = 2
RCC.WRATH_OF_THE_LICH_KING = 3
RCC.CATACLYSM = 4
RCC.MISTS_OF_PANDARIA = 5
RCC.WARLORDS_OF_DRAENOR = 6
RCC.LEGION = 7
RCC.BATTLE_FOR_AZEROTH = 8
RCC.SHADOWLANDS = 9
RCC.DRAGONFLIGHT = 10
RCC.THE_WAR_WITHIN = 11
RCC.MIDNIGHT = 12

--------------------------------------------------------------------------------
--- Expansion Display Names
--------------------------------------------------------------------------------
RCC.xpacShortNames = {
    [RCC.CLASSIC] = "Classic",
    [RCC.THE_BURNING_CRUSADE] = "TBC",
    [RCC.WRATH_OF_THE_LICH_KING] = "WotLK",
    [RCC.CATACLYSM] = "Cata",
    [RCC.MISTS_OF_PANDARIA] = "MoP",
    [RCC.WARLORDS_OF_DRAENOR] = "WoD",
    [RCC.LEGION] = "Legion",
    [RCC.BATTLE_FOR_AZEROTH] = "BfA",
    [RCC.SHADOWLANDS] = "SL",
    [RCC.DRAGONFLIGHT] = "DF",
    [RCC.THE_WAR_WITHIN] = "TWW",
    [RCC.MIDNIGHT] = "MN",
}
