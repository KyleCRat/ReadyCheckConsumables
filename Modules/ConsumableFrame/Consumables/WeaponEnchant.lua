local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.WeaponEnchant = RCC.Consumables.WeaponEnchant or {}

local WeaponEnchant = RCC.Consumables.WeaponEnchant

local Actions = RCC.ConsumableFrameActions
local Buttons = RCC.ConsumableFrameButtons
local F = RCC.F
local Glow = RCC.ConsumableFrameGlow
local ItemCandidates = RCC.ConsumableFrameItemCandidates

local GetSpellInfo = C_Spell.GetSpellInfo
local IsSpellKnown = C_SpellBook.IsSpellKnown
local GetItemInfoInstant = C_Item.GetItemInfoInstant

local setButtonGlow = Glow.Set
local setButtonShownInLayout = Buttons.SetShownInLayout
local setTimeTextBad = Buttons.SetTimeTextBad

local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"
local OUT_OF_ITEMS = "No Weapon Enchant Items found in Bags"
local MAIN_HAND_INVENTORY_SLOT = 16
local OFF_HAND_INVENTORY_SLOT = 17
local EXPIRING_SOON_MS = 300000

local cachedWeaponEnchantItemIDs = {}

local function getWeaponEnchantItemCount(itemID)
    return ItemCandidates.GetCount(itemID, ItemCandidates.BAGS_ONLY)
end

local function getWeaponEnchantDataByID(enchantID)
    return RCC.db.weaponEnchants[enchantID or 0]
end

local function getIconForWeaponEnchant(enchantData)
    if not enchantData then return end

    if enchantData.icon then
        return enchantData.icon
    end

    local spellInfo = enchantData.spellID and GetSpellInfo(enchantData.spellID)

    return spellInfo and spellInfo.iconID
end

local function setButtonIconForWeaponEnchant(button, enchantData)
    local icon = getIconForWeaponEnchant(enchantData)

    if icon then
        button.texture:SetTexture(icon)
    end
end

local function findBestWeaponEnchantItemInBags()
    local candidates = ItemCandidates.CollectAvailableFromMap(
        RCC.db.weaponEnchantItemIDs,
        ItemCandidates.BAGS_ONLY
    )
    local best = ItemCandidates.SelectBest(candidates, function(candidate, best)
        local data = candidate.data or {}
        local bestData = best.data or {}
        local xpac = data.xpac or 0
        local rank = data.q or 0
        local bestXpac = bestData.xpac or 0
        local bestRank = bestData.q or 0

        return xpac > bestXpac
            or (xpac == bestXpac and rank > bestRank)
    end)

    if best then
        return best.itemID
    end
end

local function getWeaponSlotEnchantability(slotID)
    local itemID = GetInventoryItemID("player", slotID)

    if not itemID then
        return nil, false
    end

    local itemClassID = select(6, GetItemInfoInstant(itemID))

    return itemID, itemClassID == 2
end

local function normalizeWeaponSlotEnchantState(button, slotID, hasEnchant,
                                               expiration, enchantID)
    local _, canBeEnchanted = getWeaponSlotEnchantability(slotID)

    setButtonShownInLayout(button, canBeEnchanted)

    if not canBeEnchanted then
        return false, false, nil, nil
    end

    return true, hasEnchant, expiration, enchantID
end

local function renderActiveWeaponEnchant(button, hasEnchant, expiration,
                                         enchantID, slotID)
    if not hasEnchant then return end

    local enchantData = getWeaponEnchantDataByID(enchantID)

    button.statustexture:SetTexture(READY)
    button.hasConsumableBuff = true
    button.texture:SetDesaturated(false)
    button.timeleft:SetText(F.FormatDuration((expiration or 0) / 1000))
    setTimeTextBad(button, expiration and expiration <= EXPIRING_SOON_MS)

    if enchantData then
        setButtonIconForWeaponEnchant(button, enchantData)

        if enchantData.item then
            cachedWeaponEnchantItemIDs[slotID] = enchantData.item
            button.tooltipItemID = enchantData.item
        elseif enchantData.spellID then
            button.tooltipSpellID = enchantData.spellID
        end
    end

    return enchantData
end

local function setCachedItemIconWhenNoEnchantActive(button, itemID,
                                                    activeEnchantData)
    local enchantData = itemID and RCC.db.weaponEnchantItemIDs[itemID]

    if activeEnchantData or not enchantData then
        return
    end

    setButtonIconForWeaponEnchant(button, enchantData)
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

    return nil
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

local function configureSpellEnchantButton(button, enchantData, canBeEnchanted,
                                           hasEnchant, expiration)
    if not enchantData or not enchantData.spellID then return false end

    local spellInfo = GetSpellInfo(enchantData.spellID)
    local spellName = spellInfo and spellInfo.name

    if not spellName then
        Actions.Disable(button)

        return false
    end

    setButtonIconForWeaponEnchant(button, enchantData)
    Actions.SetSpell(button, spellName, canBeEnchanted)

    button.count:SetText("")
    button.tooltipSpellID = enchantData.spellID
    button.clickHintSpellID = enchantData.spellID
    setButtonGlow(button, canBeEnchanted
                         and (not hasEnchant
                             or (expiration
                                 and expiration <= EXPIRING_SOON_MS)))

    return true
end

local function showMissingWeaponEnchantItem(button, showHint)
    if showHint then
        button.outOfItemsText = OUT_OF_ITEMS
    end

    Actions.Disable(button)
    setButtonGlow(button, false)
end

local function configureItemEnchantButton(button, itemID, count,
                                          canBeEnchanted, hasEnchant,
                                          expiration)
    button.count:SetText(count)
    button.usableItemID = itemID
    button.clickHintItemID = itemID

    if not button.tooltipItemID then
        button.tooltipItemID = itemID
    end

    if count and count > 0 then
        Actions.SetWeaponEnchantItem(button, itemID, canBeEnchanted)
    else
        Actions.Disable(button)
    end

    local needsEnchant = canBeEnchanted and count and count > 0
                         and (not hasEnchant
                             or (expiration
                                 and expiration <= EXPIRING_SOON_MS))

    setButtonGlow(button, needsEnchant)
end

local function getUsableWeaponEnchantItemForSlot(slotID)
    local cachedItem = cachedWeaponEnchantItemIDs[slotID]

    if cachedItem
        and getWeaponEnchantItemCount(cachedItem) > 0
    then
        return cachedItem
    end

    return findBestWeaponEnchantItemInBags()
end

local function configureItemEnchantSlot(button, slotID, canBeEnchanted,
                                        hasEnchant, expiration,
                                        activeEnchantData, showMissingHint)
    local itemID = getUsableWeaponEnchantItemForSlot(slotID)

    if not itemID then
        showMissingWeaponEnchantItem(button, showMissingHint)

        return
    end

    setCachedItemIconWhenNoEnchantActive(button, itemID, activeEnchantData)

    configureItemEnchantButton(button, itemID, getWeaponEnchantItemCount(itemID),
                               canBeEnchanted, hasEnchant, expiration)
end

function WeaponEnchant.Update(buttons)
    local mainHandCanBeEnchanted
    local offHandCanBeEnchanted

    local hasMainHandEnchant, mainHandExpiration, _, mainHandEnchantID,
          hasOffHandEnchant, offHandExpiration, _, offHandEnchantID =
          GetWeaponEnchantInfo()

    mainHandCanBeEnchanted, hasMainHandEnchant, mainHandExpiration,
        mainHandEnchantID = normalizeWeaponSlotEnchantState(
            buttons.oil, MAIN_HAND_INVENTORY_SLOT, hasMainHandEnchant,
            mainHandExpiration, mainHandEnchantID
        )

    offHandCanBeEnchanted, hasOffHandEnchant, offHandExpiration,
        offHandEnchantID = normalizeWeaponSlotEnchantState(
            buttons.oiloh, OFF_HAND_INVENTORY_SLOT, hasOffHandEnchant,
            offHandExpiration, offHandEnchantID
        )

    local activeMainHandEnchantData = renderActiveWeaponEnchant(
        buttons.oil, hasMainHandEnchant, mainHandExpiration,
        mainHandEnchantID, MAIN_HAND_INVENTORY_SLOT
    )

    local activeOffHandEnchantData = renderActiveWeaponEnchant(
        buttons.oiloh, hasOffHandEnchant, offHandExpiration,
        offHandEnchantID, OFF_HAND_INVENTORY_SLOT
    )

    setCachedItemIconWhenNoEnchantActive(
        buttons.oil,
        cachedWeaponEnchantItemIDs[MAIN_HAND_INVENTORY_SLOT],
        activeMainHandEnchantData
    )
    setCachedItemIconWhenNoEnchantActive(
        buttons.oiloh,
        cachedWeaponEnchantItemIDs[OFF_HAND_INVENTORY_SLOT],
        activeOffHandEnchantData
    )

    local mainHandSpellEnchant = selectSpellEnchantForSlot(
        MAIN_HAND_INVENTORY_SLOT, activeMainHandEnchantData
    )

    if not shouldPreferSpellEnchant(hasMainHandEnchant,
                                    activeMainHandEnchantData)
        or not configureSpellEnchantButton(
            buttons.oil,
            mainHandSpellEnchant,
            mainHandCanBeEnchanted,
            hasMainHandEnchant,
            mainHandExpiration
        )
    then
        configureItemEnchantSlot(
            buttons.oil,
            MAIN_HAND_INVENTORY_SLOT,
            mainHandCanBeEnchanted,
            hasMainHandEnchant,
            mainHandExpiration,
            activeMainHandEnchantData,
            true
        )
    end

    local offHandSpellEnchant = selectSpellEnchantForSlot(
        OFF_HAND_INVENTORY_SLOT, activeOffHandEnchantData
    )

    if not shouldPreferSpellEnchant(hasOffHandEnchant,
                                    activeOffHandEnchantData)
        or not configureSpellEnchantButton(
            buttons.oiloh,
            offHandSpellEnchant,
            offHandCanBeEnchanted,
            hasOffHandEnchant,
            offHandExpiration
        )
    then
        configureItemEnchantSlot(
            buttons.oiloh,
            OFF_HAND_INVENTORY_SLOT,
            offHandCanBeEnchanted,
            hasOffHandEnchant,
            offHandExpiration,
            activeOffHandEnchantData,
            offHandCanBeEnchanted
        )
    end
end
