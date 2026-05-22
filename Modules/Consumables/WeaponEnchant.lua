local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.WeaponEnchant = RCC.Consumables.WeaponEnchant or {}

local WeaponEnchant = RCC.Consumables.WeaponEnchant

local F = RCC.F
local ItemCache = RCC.ConsumableFrameItemCache
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Timing = RCC.ConsumableTiming

local ActionType = RCC.ConsumableActionType
local CacheKey = RCC.ConsumableItemCacheKey
local GetSpellInfo = C_Spell.GetSpellInfo
local IsSpellKnown = C_SpellBook.IsSpellKnown
local GetItemInfoInstant = C_Item.GetItemInfoInstant

local MAIN_HAND_INVENTORY_SLOT = 16
local OFF_HAND_INVENTORY_SLOT = 17

WeaponEnchant.MAIN_HAND_INVENTORY_SLOT = MAIN_HAND_INVENTORY_SLOT
WeaponEnchant.OFF_HAND_INVENTORY_SLOT = OFF_HAND_INVENTORY_SLOT

function WeaponEnchant.GetCacheKey(slotID)
    if slotID == MAIN_HAND_INVENTORY_SLOT then
        return CacheKey.MAIN_HAND_TEMP_WEAPON_ENCHANT
    elseif slotID == OFF_HAND_INVENTORY_SLOT then
        return CacheKey.OFF_HAND_TEMP_WEAPON_ENCHANT
    end
end

local function getCachedWeaponEnchantCandidate(slotID)
    return ItemCandidates.CreateFromMap(
        RCC.db.weaponEnchantItemIDs,
        ItemCache.Get(WeaponEnchant.GetCacheKey(slotID)),
        ItemCandidates.BAGS_ONLY
    )
end

function WeaponEnchant.GetData(enchantID)
    return RCC.db.weaponEnchants[enchantID or 0]
end

function WeaponEnchant.GetIcon(enchantData)
    if not enchantData then return end

    local icon = enchantData.icon or ItemCandidates.GetIcon(enchantData.item)

    if icon then
        return icon
    end

    local spellInfo = enchantData.spellID and GetSpellInfo(enchantData.spellID)

    return spellInfo and spellInfo.iconID
end

function WeaponEnchant.CacheActiveEnchantItem(slotID, enchantData)
    if enchantData and enchantData.item then
        ItemCache.Set(WeaponEnchant.GetCacheKey(slotID), enchantData.item)
    end
end

local function isBetterWeaponEnchantCandidate(candidate, best)
    local data = candidate.data or {}
    local bestData = best.data or {}
    local xpac = data.xpac or 0
    local rank = data.q or 0
    local bestXpac = bestData.xpac or 0
    local bestRank = bestData.q or 0

    return xpac > bestXpac
        or (xpac == bestXpac and rank > bestRank)
        or (xpac == bestXpac and rank == bestRank
            and candidate.itemID > (best.itemID or 0))
end

function WeaponEnchant.CollectItemCandidatesInBags()
    local candidates = ItemCandidates.CollectAvailableFromMap(
        RCC.db.weaponEnchantItemIDs,
        ItemCandidates.BAGS_ONLY
    )

    table.sort(candidates, isBetterWeaponEnchantCandidate)

    return candidates
end

function WeaponEnchant.CanSlotBeEnchanted(slotID)
    local itemID = GetInventoryItemID("player", slotID)

    if not itemID then return false end

    local itemClassID = select(6, GetItemInfoInstant(itemID))

    return itemClassID == 2
end

function WeaponEnchant.BuildSlotState(slotID, hasEnchant, expiration, enchantID)
    local canBeEnchanted = WeaponEnchant.CanSlotBeEnchanted(slotID)

    return {
        canBeEnchanted = canBeEnchanted,
        hasEnchant = canBeEnchanted and hasEnchant == true,
        expiration = canBeEnchanted and expiration or nil,
        enchantID = canBeEnchanted and enchantID or nil,
        slotID = slotID,
    }
end

function WeaponEnchant.IsExpiringSoon(slotState)
    return slotState.expiration ~= nil
           and Timing.IsExpiringSoon(slotState.expiration / 1000)
end

local function playerKnowsSpellEnchantData(enchantData)
    return enchantData
           and type(enchantData.spellID) == "number"
           and IsSpellKnown(enchantData.spellID)
end

local function playerKnowsWeaponEnchantSpell(enchantID)
    local enchantData = RCC.db.weaponEnchants[enchantID]

    return playerKnowsSpellEnchantData(enchantData)
end

local function spellSlotRuleMatchesKnownSpells(slotRule)
    local required = slotRule.requiresKnownEnchants

    if required then
        for i = 1, #required do
            if not playerKnowsWeaponEnchantSpell(required[i]) then
                return false
            end
        end
    end

    local blocked = slotRule.blockedByKnownEnchants

    if blocked then
        for i = 1, #blocked do
            if playerKnowsWeaponEnchantSpell(blocked[i]) then
                return false
            end
        end
    end

    return true
end

local function addKnownSpellEnchantCandidate(candidates, enchantID, enchantData,
                                             slotRule)
    if playerKnowsSpellEnchantData(enchantData)
        and spellSlotRuleMatchesKnownSpells(slotRule)
    then
        candidates[#candidates + 1] = {
            enchantID = enchantID,
            enchantData = enchantData,
            priority = slotRule.priority or 0,
        }
    end
end

function WeaponEnchant.CollectKnownSpellEnchantCandidatesForSlot(slotID)
    local candidates = {}

    for enchantID, enchantData in pairs(RCC.db.weaponEnchants) do
        local slotRule = enchantData.spellSlots
            and enchantData.spellSlots[slotID]

        if slotRule then
            addKnownSpellEnchantCandidate(candidates, enchantID, enchantData,
                                          slotRule)
        end
    end

    table.sort(candidates, function(a, b)
        if a.priority == b.priority then
            return a.enchantID < b.enchantID
        end

        return a.priority < b.priority
    end)

    return candidates
end

local function selectKnownSpellEnchantForSlot(slotID)
    local candidates = WeaponEnchant.CollectKnownSpellEnchantCandidatesForSlot(
        slotID
    )

    if candidates[1] then
        return candidates[1].enchantData
    end
end

function WeaponEnchant.CreateSpellEnchantAction(enchantData, slotState)
    if not enchantData or not enchantData.spellID then return end

    local spellInfo = GetSpellInfo(enchantData.spellID)
    local spellName = spellInfo and spellInfo.name

    if not spellName then return end

    return {
        type = ActionType.SPELL,
        spellName = spellName,
        spellID = enchantData.spellID,
        available = slotState.canBeEnchanted,
        cacheKey = WeaponEnchant.GetCacheKey(slotState.slotID),
    }
end

local function selectSpellEnchantForSlot(slotID, activeEnchantData)
    if playerKnowsSpellEnchantData(activeEnchantData) then
        return activeEnchantData
    end

    return selectKnownSpellEnchantForSlot(slotID)
end

local function shouldPreferSpellEnchant(hasEnchant, activeEnchantData)
    return not hasEnchant
           or playerKnowsSpellEnchantData(activeEnchantData)
end

function WeaponEnchant.CreateItemEnchantAction(candidate, slotState)
    if not candidate or not candidate.itemID then return end

    return {
        type = ActionType.WEAPON_ENCHANT_ITEM,
        itemID = candidate.itemID,
        targetSlot = slotState.slotID,
        available = slotState.canBeEnchanted
                    and (candidate.count or 0) > 0,
        cacheKey = WeaponEnchant.GetCacheKey(slotState.slotID),
    }
end

local function selectWeaponEnchantItemForSlot(slotID, candidates)
    return ItemCache.SelectCandidate(
        WeaponEnchant.GetCacheKey(slotID),
        candidates,
        getCachedWeaponEnchantCandidate(slotID)
    )
end

function WeaponEnchant.ResolveAction(slotState, activeEnchantData,
                                     itemCandidates)
    if not slotState or not slotState.canBeEnchanted then return end

    local spellEnchant = selectSpellEnchantForSlot(
        slotState.slotID,
        activeEnchantData
    )

    if shouldPreferSpellEnchant(slotState.hasEnchant, activeEnchantData) then
        local spellAction = WeaponEnchant.CreateSpellEnchantAction(
            spellEnchant,
            slotState
        )

        if spellAction then
            return {
                kind = "spell",
                action = spellAction,
                spellEnchant = spellEnchant,
            }
        end
    end

    local candidate = selectWeaponEnchantItemForSlot(
        slotState.slotID,
        itemCandidates
    )

    return {
        kind = "item",
        action = WeaponEnchant.CreateItemEnchantAction(candidate, slotState),
        itemCandidate = candidate,
        outOfCachedItem = ItemCache.IsUnavailableCachedCandidate(
            WeaponEnchant.GetCacheKey(slotState.slotID),
            candidate
        ),
    }
end

function WeaponEnchant.GetCurrentSlotState(slotID)
    local hasMainHandEnchant, mainHandExpiration, _, mainHandEnchantID,
          hasOffHandEnchant, offHandExpiration, _, offHandEnchantID =
          GetWeaponEnchantInfo()

    if slotID == MAIN_HAND_INVENTORY_SLOT then
        return WeaponEnchant.BuildSlotState(
            slotID,
            hasMainHandEnchant,
            mainHandExpiration,
            mainHandEnchantID
        )
    elseif slotID == OFF_HAND_INVENTORY_SLOT then
        return WeaponEnchant.BuildSlotState(
            slotID,
            hasOffHandEnchant,
            offHandExpiration,
            offHandEnchantID
        )
    end
end

function WeaponEnchant.GetActionForSlot(slotID)
    local slotState = WeaponEnchant.GetCurrentSlotState(slotID)

    if not slotState or not slotState.canBeEnchanted then return end

    local itemCandidates = WeaponEnchant.CollectItemCandidatesInBags()
    local activeEnchantData = slotState.hasEnchant
        and WeaponEnchant.GetData(slotState.enchantID)

    WeaponEnchant.CacheActiveEnchantItem(slotID, activeEnchantData)

    local resolution = WeaponEnchant.ResolveAction(
        slotState,
        activeEnchantData,
        itemCandidates
    )

    return resolution and resolution.action
end
