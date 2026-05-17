local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.WeaponEnchant = RCC.Consumables.WeaponEnchant or {}

local WeaponEnchant = RCC.Consumables.WeaponEnchant

local Actions = RCC.ConsumableFrameActions
local Buttons = RCC.ConsumableFrameButtons
local F = RCC.F
local Glow = RCC.ConsumableFrameGlow

local GetSpellInfo = C_Spell.GetSpellInfo
local IsSpellKnown = C_SpellBook.IsSpellKnown
local GetItemInfoInstant = C_Item.GetItemInfoInstant
local GetItemCount = C_Item.GetItemCount

local setButtonGlow = Glow.Set
local setButtonShownInLayout = Buttons.SetShownInLayout

local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"
local OUT_OF_ITEMS = "No Weapon Enchant Items found in Bags"
local MAIN_HAND_INVENTORY_SLOT = 16
local OFF_HAND_INVENTORY_SLOT = 17
local EXPIRING_SOON_MS = 300000

local cachedWeaponEnchantItemIDs = {}

local function getWeaponEnchantData(enchantID)
    return RCC.db.weaponEnchants[enchantID or 0]
end

local function getWeaponEnchantIcon(enchantData)
    if not enchantData then return end

    if enchantData.icon then
        return enchantData.icon
    end

    local spellInfo = enchantData.spellID and GetSpellInfo(enchantData.spellID)

    return spellInfo and spellInfo.iconID
end

local function setWeaponEnchantIcon(button, enchantData)
    local icon = getWeaponEnchantIcon(enchantData)

    if icon then
        button.texture:SetTexture(icon)
    end
end

local function findWeaponEnchantItemInBags()
    local bestItem
    local bestXpac = -1
    local bestRank = -1

    for itemID, data in pairs(RCC.db.weaponEnchantItemIDs) do
        if GetItemCount(itemID, false, true) > 0 then
            local xpac = data.xpac or 0
            local rank = data.q or 0

            if xpac > bestXpac or (xpac == bestXpac and rank > bestRank) then
                bestXpac = xpac
                bestRank = rank
                bestItem = itemID
            end
        end
    end

    return bestItem
end

local function getEnchantableWeaponSlot(slotID)
    local itemID = GetInventoryItemID("player", slotID)

    if not itemID then
        return nil, false
    end

    local itemClassID = select(6, GetItemInfoInstant(itemID))

    return itemID, itemClassID == 2
end

local function getWeaponSlotState(button, slotID, hasEnchant,
                                  expiration, enchantID)
    local _, canBeEnchanted = getEnchantableWeaponSlot(slotID)

    setButtonShownInLayout(button, canBeEnchanted)

    if not canBeEnchanted then
        return false, false, nil, nil
    end

    return true, hasEnchant, expiration, enchantID
end

local function applyAppliedEnchant(button, hasEnchant, expiration, enchantID,
                                   slotID)
    if not hasEnchant then return end

    local enchantData = getWeaponEnchantData(enchantID)

    button.statustexture:SetTexture(READY)
    button.hasConsumableBuff = true
    button.texture:SetDesaturated(false)
    button.timeleft:SetText(F.FormatDuration((expiration or 0) / 1000))

    if enchantData then
        setWeaponEnchantIcon(button, enchantData)

        if enchantData.item then
            cachedWeaponEnchantItemIDs[slotID] = enchantData.item
            button.tooltipItemID = enchantData.item
        elseif enchantData.spellID then
            button.tooltipSpellID = enchantData.spellID
        end
    end

    return enchantData
end

local function setFallbackIcon(button, itemID, appliedEnchant)
    local enchantData = itemID and RCC.db.weaponEnchantItemIDs[itemID]

    if appliedEnchant or not enchantData then
        return
    end

    setWeaponEnchantIcon(button, enchantData)
end

local function isKnownSpellEnchantData(enchantData)
    return enchantData
           and type(enchantData.spellID) == "number"
           and IsSpellKnown(enchantData.spellID)
end

local function isKnownSpellEnchant(enchantID)
    local enchantData = RCC.db.weaponEnchants[enchantID]

    return isKnownSpellEnchantData(enchantData)
end

local function isCandidateAllowed(slotRule)
    local required = slotRule.requiresKnownEnchants

    if required then
        for i = 1, #required do
            if not isKnownSpellEnchant(required[i]) then
                return false
            end
        end
    end

    local blocked = slotRule.blockedByKnownEnchants

    if blocked then
        for i = 1, #blocked do
            if isKnownSpellEnchant(blocked[i]) then
                return false
            end
        end
    end

    return true
end

local function addKnownSpellCandidate(candidates, enchantID, enchantData,
                                      slotRule)
    if isKnownSpellEnchantData(enchantData)
        and isCandidateAllowed(slotRule)
    then
        candidates[#candidates + 1] = {
            enchantID = enchantID,
            enchantData = enchantData,
            priority = slotRule.priority or 0,
        }
    end
end

local function getKnownSpellEnchantForSlot(slotID)
    local candidates = {}

    for enchantID, enchantData in pairs(RCC.db.weaponEnchants) do
        local slotRule = enchantData.spellSlots
            and enchantData.spellSlots[slotID]

        if slotRule then
            addKnownSpellCandidate(candidates, enchantID, enchantData,
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

local function getSpellEnchantForSlot(slotID, appliedEnchant)
    if isKnownSpellEnchantData(appliedEnchant) then
        return appliedEnchant
    end

    return getKnownSpellEnchantForSlot(slotID)
end

local function shouldUseSpellEnchant(hasEnchant, appliedEnchant)
    return not hasEnchant
           or (appliedEnchant and appliedEnchant.spellID ~= nil)
end

local function updateSpellSlot(button, enchantData, canBeEnchanted, hasEnchant,
                               expiration)
    if not enchantData or not enchantData.spellID then return false end

    local spellInfo = GetSpellInfo(enchantData.spellID)
    local spellName = spellInfo and spellInfo.name

    if not spellName then
        Actions.Disable(button)

        return false
    end

    setWeaponEnchantIcon(button, enchantData)
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

local function updateMissingItemSlot(button, showHint)
    if showHint then
        button.outOfItemsText = OUT_OF_ITEMS
    end

    Actions.Disable(button)
    setButtonGlow(button, false)
end

local function updateUsableItemSlot(button, itemID, count, canBeEnchanted,
                                    hasEnchant, expiration)
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

local function getUsableItemForSlot(slotID)
    local cachedItem = cachedWeaponEnchantItemIDs[slotID]

    if cachedItem
        and GetItemCount(cachedItem, false, true) > 0
    then
        return cachedItem
    end

    return findWeaponEnchantItemInBags()
end

local function updateItemSlot(button, slotID, canBeEnchanted, hasEnchant,
                              expiration, appliedEnchant, showMissingHint)
    local itemID = getUsableItemForSlot(slotID)

    if not itemID then
        updateMissingItemSlot(button, showMissingHint)

        return
    end

    setFallbackIcon(button, itemID, appliedEnchant)

    updateUsableItemSlot(button, itemID,
                         GetItemCount(itemID, false, true),
                         canBeEnchanted, hasEnchant, expiration)
end

function WeaponEnchant.Update(buttons)
    local mainHandCanBeEnchanted
    local offhandCanBeEnchanted

    local hasMainHandEnchant, mainHandExpiration, _, mainHandEnchantID,
          hasOffHandEnchant, offHandExpiration, _, offHandEnchantID =
          GetWeaponEnchantInfo()

    mainHandCanBeEnchanted, hasMainHandEnchant, mainHandExpiration,
        mainHandEnchantID = getWeaponSlotState(
            buttons.oil, MAIN_HAND_INVENTORY_SLOT, hasMainHandEnchant,
            mainHandExpiration, mainHandEnchantID
        )

    offhandCanBeEnchanted, hasOffHandEnchant, offHandExpiration,
        offHandEnchantID = getWeaponSlotState(
            buttons.oiloh, OFF_HAND_INVENTORY_SLOT, hasOffHandEnchant,
            offHandExpiration, offHandEnchantID
        )

    local appliedMainHandEnchant = applyAppliedEnchant(
        buttons.oil, hasMainHandEnchant, mainHandExpiration,
        mainHandEnchantID, MAIN_HAND_INVENTORY_SLOT
    )

    local appliedOffHandEnchant = applyAppliedEnchant(
        buttons.oiloh, hasOffHandEnchant, offHandExpiration,
        offHandEnchantID, OFF_HAND_INVENTORY_SLOT
    )

    setFallbackIcon(
        buttons.oil,
        cachedWeaponEnchantItemIDs[MAIN_HAND_INVENTORY_SLOT],
        appliedMainHandEnchant
    )
    setFallbackIcon(
        buttons.oiloh,
        cachedWeaponEnchantItemIDs[OFF_HAND_INVENTORY_SLOT],
        appliedOffHandEnchant
    )

    local mainHandSpellEnchant = getSpellEnchantForSlot(
        MAIN_HAND_INVENTORY_SLOT, appliedMainHandEnchant
    )

    if not shouldUseSpellEnchant(hasMainHandEnchant, appliedMainHandEnchant)
        or not updateSpellSlot(buttons.oil, mainHandSpellEnchant,
                               mainHandCanBeEnchanted, hasMainHandEnchant,
                               mainHandExpiration)
    then
        updateItemSlot(
            buttons.oil,
            MAIN_HAND_INVENTORY_SLOT,
            mainHandCanBeEnchanted,
            hasMainHandEnchant,
            mainHandExpiration,
            appliedMainHandEnchant,
            true
        )
    end

    local offHandSpellEnchant = getSpellEnchantForSlot(
        OFF_HAND_INVENTORY_SLOT, appliedOffHandEnchant
    )

    if not shouldUseSpellEnchant(hasOffHandEnchant, appliedOffHandEnchant)
        or not updateSpellSlot(buttons.oiloh, offHandSpellEnchant,
                               offhandCanBeEnchanted, hasOffHandEnchant,
                               offHandExpiration)
    then
        updateItemSlot(
            buttons.oiloh,
            OFF_HAND_INVENTORY_SLOT,
            offhandCanBeEnchanted,
            hasOffHandEnchant,
            offHandExpiration,
            appliedOffHandEnchant,
            offhandCanBeEnchanted
        )
    end
end
