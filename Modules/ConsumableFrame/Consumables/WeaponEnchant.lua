local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.WeaponEnchant = RCC.Consumables.WeaponEnchant or {}

local WeaponEnchant = RCC.Consumables.WeaponEnchant

local ButtonState = RCC.ConsumableFrameButtonState
local F = RCC.F
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType
local GetSpellInfo = C_Spell.GetSpellInfo
local IsSpellKnown = C_SpellBook.IsSpellKnown
local GetItemInfoInstant = C_Item.GetItemInfoInstant

local OUT_OF_ITEMS = "No Weapon Enchant Items found in Bags"
local MAIN_HAND_INVENTORY_SLOT = 16
local OFF_HAND_INVENTORY_SLOT = 17

local cachedWeaponEnchantItemIDs = {}

local function getWeaponEnchantItemCount(itemID)
    return ItemCandidates.GetCount(itemID, ItemCandidates.BAGS_ONLY)
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

local function buildItemFlyoutChoices(candidates, selectedItemID, slotState,
                                      includeSingleChoice)
    if not candidates then return end
    if not includeSingleChoice and #candidates <= 1 then return end

    local choices = {}

    for i = 1, #candidates do
        local candidate = candidates[i]

        if candidate.itemID ~= selectedItemID then
            choices[#choices + 1] = ButtonState.CreateItemChoice(
                candidate,
                ActionType.WEAPON_ENCHANT_ITEM,
                {
                    targetSlot = slotState.slotID,
                    available = slotState.canBeEnchanted,
                }
            )
        end
    end

    if #choices > 0 then
        return choices
    end
end

local function canWeaponSlotBeEnchanted(slotID)
    local itemID = GetInventoryItemID("player", slotID)

    if not itemID then return false end

    local itemClassID = select(6, GetItemInfoInstant(itemID))

    return itemClassID == 2
end

local function buildWeaponSlotState(slotID, hasEnchant, expiration, enchantID,
                                    expireWarnSeconds)
    local canBeEnchanted = canWeaponSlotBeEnchanted(slotID)

    return {
        canBeEnchanted = canBeEnchanted,
        hasEnchant = canBeEnchanted and hasEnchant == true,
        expiration = canBeEnchanted and expiration or nil,
        enchantID = canBeEnchanted and enchantID or nil,
        expireWarnSeconds = expireWarnSeconds,
        slotID = slotID,
    }
end

local function isExpiringSoon(slotState)
    return slotState.expiration ~= nil
           and slotState.expireWarnSeconds ~= nil
           and slotState.expiration <= slotState.expireWarnSeconds * 1000
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
            cachedWeaponEnchantItemIDs[slotID] = enchantData.item
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

local function selectKnownSpellEnchantForSlot(slotID)
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

    if candidates[1] then
        return candidates[1].enchantData
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
           or (activeEnchantData and activeEnchantData.spellID ~= nil)
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
    }
    buttonState.countText = ""
    buttonState.tooltipSpellID = enchantData.spellID
    buttonState.clickHintSpellID = enchantData.spellID
    buttonState.glow = slotState.canBeEnchanted
                       and (not slotState.hasEnchant
                            or isExpiringSoon(slotState))
    buttonState.flyoutChoices = buildItemFlyoutChoices(
        itemCandidates,
        nil,
        slotState,
        true
    )

    return true
end

local function configureMissingItemState(buttonState, showHint)
    if showHint then
        buttonState.outOfItemsText = OUT_OF_ITEMS
    end

    buttonState.glow = false
end

local function configureItemEnchantState(buttonState, itemID, count, slotState)
    local hasItem = count ~= nil and count > 0

    buttonState.countText = tostring(count or 0)
    buttonState.usableItemID = itemID
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
        }
    end

    buttonState.glow = slotState.canBeEnchanted
                       and hasItem
                       and (not slotState.hasEnchant
                            or isExpiringSoon(slotState))
end

local function getUsableWeaponEnchantItemForSlot(slotID, candidates)
    local cachedItem = cachedWeaponEnchantItemIDs[slotID]

    if cachedItem
        and getWeaponEnchantItemCount(cachedItem) > 0
    then
        return cachedItem
    end

    return candidates and candidates[1] and candidates[1].itemID
end

local function configureItemEnchantForSlot(buttonState, slotID, slotState,
                                           activeEnchantData, showMissingHint,
                                           itemCandidates)
    local itemID = getUsableWeaponEnchantItemForSlot(slotID, itemCandidates)

    if not itemID then
        configureMissingItemState(buttonState, showMissingHint)

        return
    end

    addCachedItemIconToState(buttonState, itemID, activeEnchantData)

    configureItemEnchantState(
        buttonState,
        itemID,
        getWeaponEnchantItemCount(itemID),
        slotState
    )

    buttonState.flyoutChoices = buildItemFlyoutChoices(
        itemCandidates,
        itemID,
        slotState,
        false
    )
end

local function updateWeaponEnchantSlot(button, slotID, hasEnchant, expiration,
                                       enchantID, showMissingHint)
    local slotState = buildWeaponSlotState(
        slotID,
        hasEnchant,
        expiration,
        enchantID,
        button.expireWarnSeconds
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
    local itemCandidates = collectWeaponEnchantItemCandidatesInBags()

    if not shouldPreferSpellEnchant(slotState.hasEnchant, activeEnchantData)
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
                                         enchantID, showMissingHint)
    if not button or not button.weaponSlot then return end

    updateWeaponEnchantSlot(
        button,
        button.weaponSlot,
        hasEnchant,
        expiration,
        enchantID,
        showMissingHint
    )
end

function WeaponEnchant.Update(buttons)
    local hasMainHandEnchant, mainHandExpiration, _, mainHandEnchantID,
          hasOffHandEnchant, offHandExpiration, _, offHandEnchantID =
          GetWeaponEnchantInfo()

    updateWeaponEnchantButton(
        buttons.mainHandTempWeaponEnchant,
        hasMainHandEnchant,
        mainHandExpiration,
        mainHandEnchantID,
        true
    )

    updateWeaponEnchantButton(
        buttons.offHandTempWeaponEnchant,
        hasOffHandEnchant,
        offHandExpiration,
        offHandEnchantID,
        true
    )
end
