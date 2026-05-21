local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.WeaponEnchant = RCC.Consumables.WeaponEnchant or {}

local WeaponEnchant = RCC.Consumables.WeaponEnchant

local ButtonState = RCC.ConsumableFrameButtonState
local F = RCC.F
local ItemCache = RCC.ConsumableFrameItemCache
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer
local Timing = RCC.ConsumableTiming

local ActionType = RCC.ConsumableActionType
local CacheKey = RCC.ConsumableItemCacheKey
local GetSpellInfo = C_Spell.GetSpellInfo
local IsSpellKnown = C_SpellBook.IsSpellKnown
local GetItemInfoInstant = C_Item.GetItemInfoInstant

local OUT_OF_ITEMS = "No Weapon Enchant Items found in Bags"
local OUT_OF_SELECTED_ITEM = "Selected Weapon Enchant Item not found in Bags"
local MAIN_HAND_INVENTORY_SLOT = 16
local OFF_HAND_INVENTORY_SLOT = 17

local function getWeaponEnchantCacheKey(slotID)
    if slotID == MAIN_HAND_INVENTORY_SLOT then
        return CacheKey.MAIN_HAND_TEMP_WEAPON_ENCHANT
    elseif slotID == OFF_HAND_INVENTORY_SLOT then
        return CacheKey.OFF_HAND_TEMP_WEAPON_ENCHANT
    end
end

local function getCachedWeaponEnchantCandidate(slotID)
    return ItemCandidates.CreateFromMap(
        RCC.db.weaponEnchantItemIDs,
        ItemCache.Get(getWeaponEnchantCacheKey(slotID)),
        ItemCandidates.BAGS_ONLY
    )
end

local function getWeaponEnchantData(enchantID)
    return RCC.db.weaponEnchants[enchantID or 0]
end

local function getWeaponEnchantIcon(enchantData)
    if not enchantData then return end

    local icon = enchantData.icon or ItemCandidates.GetIcon(enchantData.item)

    if icon then
        return icon
    end

    local spellInfo = enchantData.spellID and GetSpellInfo(enchantData.spellID)

    return spellInfo and spellInfo.iconID
end

local function addEnchantIconToState(buttonState, enchantData)
    local icon = getWeaponEnchantIcon(enchantData)

    if icon then
        buttonState.icon = icon
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

local function collectWeaponEnchantItemCandidatesInBags()
    local candidates = ItemCandidates.CollectAvailableFromMap(
        RCC.db.weaponEnchantItemIDs,
        ItemCandidates.BAGS_ONLY
    )

    table.sort(candidates, isBetterWeaponEnchantCandidate)

    return candidates
end

local function canWeaponSlotBeEnchanted(slotID)
    local itemID = GetInventoryItemID("player", slotID)

    if not itemID then return false end

    local itemClassID = select(6, GetItemInfoInstant(itemID))

    return itemClassID == 2
end

local function buildWeaponSlotState(slotID, hasEnchant, expiration, enchantID)
    local canBeEnchanted = canWeaponSlotBeEnchanted(slotID)

    return {
        canBeEnchanted = canBeEnchanted,
        hasEnchant = canBeEnchanted and hasEnchant == true,
        expiration = canBeEnchanted and expiration or nil,
        enchantID = canBeEnchanted and enchantID or nil,
        slotID = slotID,
    }
end

local function isExpiringSoon(slotState)
    return slotState.expiration ~= nil
           and Timing.IsExpiringSoon(slotState.expiration / 1000)
end

local function addActiveEnchantToState(buttonState, slotID, slotState)
    if not slotState.hasEnchant then return end

    local enchantData = getWeaponEnchantData(slotState.enchantID)

    buttonState.statusTexture = ButtonState.READY_TEXTURE
    buttonState.hasConsumableBuff = true
    buttonState.desaturated = false
    buttonState.detailText = F.FormatDuration(
        (slotState.expiration or 0) / 1000
    )

    if slotState.expiration ~= nil then
        buttonState.detailTextIsBad = isExpiringSoon(slotState)
    end

    if enchantData then
        addEnchantIconToState(buttonState, enchantData)

        if enchantData.item then
            ItemCache.Set(getWeaponEnchantCacheKey(slotID), enchantData.item)
            buttonState.tooltipItemID = enchantData.item
        elseif enchantData.spellID then
            buttonState.tooltipSpellID = enchantData.spellID
        end
    end

    return enchantData
end

local function addCachedItemIconToState(buttonState, itemID, activeEnchantData)
    local enchantData = itemID and RCC.db.weaponEnchantItemIDs[itemID]

    if activeEnchantData or not enchantData then return end

    addEnchantIconToState(buttonState, enchantData)
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

local function collectKnownSpellEnchantCandidatesForSlot(slotID)
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
    local candidates = collectKnownSpellEnchantCandidatesForSlot(slotID)

    if candidates[1] then
        return candidates[1].enchantData
    end
end

local function createSpellFlyoutChoice(enchantData, slotState)
    if not enchantData or not enchantData.spellID then return end

    local spellInfo = GetSpellInfo(enchantData.spellID)
    local spellName = spellInfo and spellInfo.name

    if not spellName then return end

    return ButtonState.Create({
        icon = getWeaponEnchantIcon(enchantData),
        desaturated = false,
        countText = "",
        tooltipSpellID = enchantData.spellID,
        clickHintSpellID = enchantData.spellID,
        action = {
            type = ActionType.SPELL,
            spellName = spellName,
            available = slotState.canBeEnchanted,
            cacheKey = getWeaponEnchantCacheKey(slotState.slotID),
        },
    })
end

local function appendSpellFlyoutChoices(choices, slotState, activeEnchantData)
    local spellCandidates =
        collectKnownSpellEnchantCandidatesForSlot(slotState.slotID)

    for i = 1, #spellCandidates do
        local enchantData = spellCandidates[i].enchantData

        if enchantData ~= activeEnchantData then
            local choice = createSpellFlyoutChoice(enchantData, slotState)

            if choice then
                choices[#choices + 1] = choice
            end
        end
    end
end

local function appendChoices(choices, additions)
    if not additions then return end

    for i = 1, #additions do
        choices[#choices + 1] = additions[i]
    end
end

local function buildItemPrimaryFlyoutChoices(itemCandidates, itemID, slotState,
                                             activeEnchantData,
                                             outOfCachedItem)
    local choices = {}

    appendSpellFlyoutChoices(choices, slotState, activeEnchantData)
    appendChoices(choices, ButtonState.CreateItemFlyoutChoices(
        itemCandidates,
        itemID,
        ActionType.WEAPON_ENCHANT_ITEM,
        {
            targetSlot = slotState.slotID,
            available = slotState.canBeEnchanted,
            cacheKey = getWeaponEnchantCacheKey(slotState.slotID),
            includeSingleChoice = outOfCachedItem,
        }
    ))

    if #choices > 0 then
        return choices
    end
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

local function configureSpellEnchantState(buttonState, enchantData, slotState,
                                          itemCandidates)
    if not enchantData or not enchantData.spellID then return false end

    local spellInfo = GetSpellInfo(enchantData.spellID)
    local spellName = spellInfo and spellInfo.name

    if not spellName then
        return false
    end

    addEnchantIconToState(buttonState, enchantData)

    buttonState.action = {
        type = ActionType.SPELL,
        spellName = spellName,
        available = slotState.canBeEnchanted,
        cacheKey = getWeaponEnchantCacheKey(slotState.slotID),
    }
    buttonState.countText = ""
    buttonState.tooltipSpellID = enchantData.spellID
    buttonState.clickHintSpellID = enchantData.spellID
    buttonState.glow = slotState.canBeEnchanted
                       and (not slotState.hasEnchant
                            or isExpiringSoon(slotState))
    buttonState.flyoutChoices = ButtonState.CreateItemFlyoutChoices(
        itemCandidates,
        nil,
        ActionType.WEAPON_ENCHANT_ITEM,
        {
            targetSlot = slotState.slotID,
            available = slotState.canBeEnchanted,
            includeSingleChoice = true,
            cacheKey = getWeaponEnchantCacheKey(slotState.slotID),
        }
    )

    return true
end

local function configureMissingItemState(buttonState, showHint)
    if showHint then
        ButtonState.SetUnavailable(buttonState, OUT_OF_ITEMS)
    end

    buttonState.glow = false
end

local function configureItemEnchantState(buttonState, itemID, count, slotState)
    local hasItem = count ~= nil and count > 0

    buttonState.countText = tostring(count or 0)
    buttonState.usableItemID = itemID
    buttonState.qualityItemID = itemID
    buttonState.clickHintItemID = itemID

    if not buttonState.tooltipItemID then
        buttonState.tooltipItemID = itemID
    end

    if hasItem then
        buttonState.action = {
            type = ActionType.WEAPON_ENCHANT_ITEM,
            itemID = itemID,
            targetSlot = slotState.slotID,
            available = slotState.canBeEnchanted,
            cacheKey = getWeaponEnchantCacheKey(slotState.slotID),
        }
    end

    buttonState.glow = slotState.canBeEnchanted
                       and hasItem
                       and (not slotState.hasEnchant
                            or isExpiringSoon(slotState))
end

local function selectWeaponEnchantItemForSlot(slotID, candidates)
    return ItemCache.SelectCandidate(
        getWeaponEnchantCacheKey(slotID),
        candidates,
        getCachedWeaponEnchantCandidate(slotID)
    )
end

local function configureItemEnchantForSlot(buttonState, slotID, slotState,
                                           activeEnchantData, showMissingHint,
                                           itemCandidates)
    local candidate = selectWeaponEnchantItemForSlot(slotID, itemCandidates)
    local itemID = candidate and candidate.itemID
    local outOfCachedItem = ItemCache.IsUnavailableCachedCandidate(
        getWeaponEnchantCacheKey(slotID),
        candidate
    )

    if not itemID then
        if not slotState.hasEnchant then
            configureMissingItemState(buttonState, showMissingHint)
        end

        return
    end

    addCachedItemIconToState(buttonState, itemID, activeEnchantData)

    configureItemEnchantState(
        buttonState,
        itemID,
        candidate.count,
        slotState
    )

    if outOfCachedItem then
        if slotState.hasEnchant then
            ButtonState.SetHoverUnavailable(buttonState, OUT_OF_SELECTED_ITEM)
        else
            ButtonState.SetUnavailable(buttonState, OUT_OF_SELECTED_ITEM)
        end
    end

    buttonState.flyoutChoices = buildItemPrimaryFlyoutChoices(
        itemCandidates,
        itemID,
        slotState,
        activeEnchantData,
        outOfCachedItem
    )
end

local function updateWeaponEnchantSlot(button, slotID, hasEnchant, expiration,
                                       enchantID, showMissingHint,
                                       itemCandidates)
    local slotState = buildWeaponSlotState(
        slotID,
        hasEnchant,
        expiration,
        enchantID
    )
    local buttonState = ButtonState.Create({
        showInLayout = slotState.canBeEnchanted,
        glow = false,
    })

    if not slotState.canBeEnchanted then
        Renderer.Apply(button, buttonState)

        return
    end

    local activeEnchantData = addActiveEnchantToState(
        buttonState,
        slotID,
        slotState
    )
    local spellEnchant = selectSpellEnchantForSlot(slotID, activeEnchantData)
    if not shouldPreferSpellEnchant(
            slotState.hasEnchant,
            activeEnchantData
        )
        or not configureSpellEnchantState(
            buttonState,
            spellEnchant,
            slotState,
            itemCandidates
        )
    then
        configureItemEnchantForSlot(
            buttonState,
            slotID,
            slotState,
            activeEnchantData,
            showMissingHint,
            itemCandidates
        )
    end

    Renderer.Apply(button, buttonState)
end

local function updateWeaponEnchantButton(button, hasEnchant, expiration,
                                         enchantID, showMissingHint,
                                         itemCandidates)
    if not button or not button.weaponSlot then return end

    updateWeaponEnchantSlot(
        button,
        button.weaponSlot,
        hasEnchant,
        expiration,
        enchantID,
        showMissingHint,
        itemCandidates
    )
end

function WeaponEnchant.Update(buttons)
    local hasMainHandEnchant, mainHandExpiration, _, mainHandEnchantID,
          hasOffHandEnchant, offHandExpiration, _, offHandEnchantID =
          GetWeaponEnchantInfo()
    local itemCandidates = collectWeaponEnchantItemCandidatesInBags()

    updateWeaponEnchantButton(
        buttons.mainHandTempWeaponEnchant,
        hasMainHandEnchant,
        mainHandExpiration,
        mainHandEnchantID,
        true,
        itemCandidates
    )

    updateWeaponEnchantButton(
        buttons.offHandTempWeaponEnchant,
        hasOffHandEnchant,
        offHandExpiration,
        offHandEnchantID,
        true,
        itemCandidates
    )
end
