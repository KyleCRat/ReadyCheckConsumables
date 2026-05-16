local ADDON_NAME, RCC = ...

local Auras = RCC.ConsumableFrameAuras
local F = RCC.F
local Actions = RCC.ConsumableFrameActions
local Buttons = RCC.ConsumableFrameButtons
local Glow = RCC.ConsumableFrameGlow

local            GetTime = GetTime
local       GetSpellInfo = C_Spell.GetSpellInfo
local GetItemInfoInstant = C_Item.GetItemInfoInstant
local       GetItemCount = C_Item.GetItemCount
local        GetItemIcon = C_Item.GetItemIconByID

local setButtonGlow = Glow.Set
local setButtonShownInLayout = Buttons.SetShownInLayout
local resetButtonState = Buttons.ResetState
local isPositiveAuraDuration = Auras.IsPositiveDuration

--------------------------------------------------------------------------------
--- Update helper functions
--------------------------------------------------------------------------------

local function applyAuraState(buttons, state)
    local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

    if state.food and state.food.active then
        buttons.food.statustexture:SetTexture(READY)
        buttons.food.hasConsumableBuff = true
        buttons.food.texture:SetDesaturated(false)

        if state.food.remaining then
            buttons.food.timeleft:SetText(F.FormatDuration(state.food.remaining))
        end

        if state.food.icon then
            buttons.food.texture:SetTexture(state.food.icon)
        end

        if state.food.auraInstanceID then
            buttons.food.tooltipAuraID = state.food.auraInstanceID
        end
    end

    if state.flask and state.flask.active then
        buttons.flask.statustexture:SetTexture(READY)
        buttons.flask.hasConsumableBuff = true
        buttons.flask.texture:SetDesaturated(false)
        buttons.flask.texture:SetTexture(state.flask.icon)

        if state.flask.remaining then
            buttons.flask.timeleft:SetText(F.FormatDuration(state.flask.remaining))
        end
    end

    if state.augment and state.augment.active then
        buttons.augment.statustexture:SetTexture(READY)
        buttons.augment.hasConsumableBuff = true
        buttons.augment.texture:SetDesaturated(false)
        buttons.augment.texture:SetTexture(state.augment.icon)

        if state.augment.remaining then
            buttons.augment.timeleft:SetText(
                F.FormatDuration(state.augment.remaining))
        end
    end
end

local function updateFood(buttons, isFood)
    local food_count = 0
    local food_item_id

    for food_index = 1, #RCC.db.foodItemIDs do
        local fid = RCC.db.foodItemIDs[food_index]
        local count = GetItemCount(fid, false, false)

        if count and count > 0 then
            food_item_id = fid
            food_count = count

            break
        end
    end

    if food_count > 0 then
        buttons.food.tooltipItemID = food_item_id
        buttons.food.usableItemID = food_item_id

        if not isFood then
            local texture = select(5, GetItemInfoInstant(food_item_id))

            if texture then
                buttons.food.texture:SetTexture(texture)
            end
        end

        Actions.SetItemMacro(buttons.food, food_item_id)
    else
        Actions.Disable(buttons.food)

        if not isFood then
            buttons.food.outOfItemsText = "No Food found in Bags"
        end
    end

    buttons.food.count:SetFormattedText(
        "%s", food_count > 0 and food_count or "")

    if not isFood and food_count > 0 then
        setButtonGlow(buttons.food, true)
    else
        setButtonGlow(buttons.food, false)
    end
end

local function updateHealthstones(buttons)
    local totalCount = 0

    for itemID in pairs(RCC.db.healthstoneItemIDs) do
        local count = GetItemCount(itemID, false, true)

        if count and count > 0 then
            totalCount = totalCount + count
        end
    end

    if totalCount > 0 then
        local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"
        buttons.hs.count:SetFormattedText("%d", totalCount)
        buttons.hs.statustexture:SetTexture(READY)
        buttons.hs.texture:SetDesaturated(false)
        buttons.hs.tooltipItemID = RCC.db.healthstone_item_id
    else
        buttons.hs.count:SetText("0")
    end
end

local function updateFlasks(buttons, isFlask)
    local flask_count = 0
    local flask_item_id

    for flask_index = 1, #RCC.db.flaskItemIDs do
        local fid = RCC.db.flaskItemIDs[flask_index]
        local count = GetItemCount(fid, false, false)

        if count and count > 0 then
            flask_item_id = fid
            flask_count = count

            break
        end
    end

    if flask_count > 0 then
        buttons.flask.tooltipItemID = flask_item_id
        buttons.flask.usableItemID = flask_item_id

        if not isFlask then
            local texture = select(5, GetItemInfoInstant(flask_item_id))

            if texture then
                buttons.flask.texture:SetTexture(texture)
            end
        end

        Actions.SetItemMacro(buttons.flask, flask_item_id)
    else
        Actions.Disable(buttons.flask)

        if not isFlask then
            buttons.flask.outOfItemsText = "No Flasks found in Bags"
        end
    end

    buttons.flask.count:SetFormattedText(
        "%s", flask_count > 0 and flask_count or "")

    if not isFlask and flask_count > 0 then
        setButtonGlow(buttons.flask, true)
    else
        setButtonGlow(buttons.flask, false)
    end
end

local lastWeaponEnchantItem
local WEAPON_ENCHANT_OUT_OF_ITEMS = "No Weapon Enchant Items found in Bags"

local function getWeaponEnchantItem(enchantID)
    local enchantData = RCC.db.weaponEnchants[enchantID or 0]

    return enchantData and enchantData.item
end

local function setWeaponEnchantIcon(button, itemID, isOffhand)
    local enchantData = itemID and RCC.db.weaponEnchantItemIDs[itemID]

    if enchantData then
        button.texture:SetTexture(isOffhand and
            (enchantData.iconoh or enchantData.icon) or enchantData.icon)
    end
end

local function findWeaponEnchantItemInBags()
    local bestItem
    local bestXpac = -1
    local bestRank = -1

    for itemID, data in pairs(RCC.db.weaponEnchantItemIDs) do
        if itemID > 0
            and GetItemCount(itemID, false, true) > 0
        then
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

local function hideWeaponEnchantClicks(buttons)
    Actions.Disable(buttons.oil)
    Actions.Disable(buttons.oiloh)
end

local function getEnchantableWeaponSlot(slotID)
    local itemID = GetInventoryItemID("player", slotID)

    if not itemID then
        return nil, false
    end

    local itemClassID = select(6, GetItemInfoInstant(itemID))

    return itemID, itemClassID == 2
end

local function updateWeaponEnchants(buttons)
    local _, mainHandCanBeEnchanted = getEnchantableWeaponSlot(16)
    local _, offhandCanBeEnchanted = getEnchantableWeaponSlot(17)

    setButtonShownInLayout(buttons.oil, mainHandCanBeEnchanted)
    setButtonShownInLayout(buttons.oiloh, offhandCanBeEnchanted)

    local hasMainHandEnchant, mainHandExpiration,
          mainHandCharges, mainHandEnchantID,
          hasOffHandEnchant, offHandExpiration,
          offHandCharges, offHandEnchantID = GetWeaponEnchantInfo()

    if not mainHandCanBeEnchanted then
        hasMainHandEnchant = false
        mainHandExpiration = nil
        mainHandEnchantID = nil
    end

    local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

    local appliedMainHandItem

    if hasMainHandEnchant then
        appliedMainHandItem = getWeaponEnchantItem(mainHandEnchantID)

        buttons.oil.statustexture:SetTexture(READY)
        buttons.oil.hasConsumableBuff = true
        buttons.oil.texture:SetDesaturated(false)
        buttons.oil.timeleft:SetText(
            F.FormatDuration((mainHandExpiration or 0) / 1000)
        )

        if appliedMainHandItem then
            lastWeaponEnchantItem = appliedMainHandItem
            buttons.oil.appliedItemID = appliedMainHandItem
            setWeaponEnchantIcon(buttons.oil, appliedMainHandItem)

            if appliedMainHandItem > 0 then
                buttons.oil.tooltipItemID = appliedMainHandItem
            end
        end
    elseif lastWeaponEnchantItem and lastWeaponEnchantItem < 0 then
        lastWeaponEnchantItem = nil
    end

    local appliedOffHandItem

    if offhandCanBeEnchanted and hasOffHandEnchant then
        appliedOffHandItem = getWeaponEnchantItem(offHandEnchantID)

        buttons.oiloh.statustexture:SetTexture(READY)
        buttons.oiloh.hasConsumableBuff = true
        buttons.oiloh.texture:SetDesaturated(false)
        buttons.oiloh.timeleft:SetText(
            F.FormatDuration((offHandExpiration or 0) / 1000)
        )

        if appliedOffHandItem then
            buttons.oiloh.appliedItemID = appliedOffHandItem
            setWeaponEnchantIcon(buttons.oiloh, appliedOffHandItem, true)

            if appliedOffHandItem > 0 then
                buttons.oiloh.tooltipItemID = appliedOffHandItem
            end
        end
    end

    if lastWeaponEnchantItem
        and RCC.db.weaponEnchantItemIDs[lastWeaponEnchantItem]
    then
        setWeaponEnchantIcon(buttons.oil, lastWeaponEnchantItem)

        if not appliedOffHandItem then
            setWeaponEnchantIcon(buttons.oiloh, lastWeaponEnchantItem, true)
        end
    end

    if type(lastWeaponEnchantItem) == "number" and lastWeaponEnchantItem < 0 then
        local spellInfo = GetSpellInfo(-lastWeaponEnchantItem)
        local spellName = spellInfo and spellInfo.name

        if spellName then
            Actions.SetSpell(buttons.oil, spellName, mainHandCanBeEnchanted)
            Actions.SetSpell(buttons.oiloh, spellName, offhandCanBeEnchanted)
        else
            hideWeaponEnchantClicks(buttons)
        end

        buttons.oil.count:SetText("")
        buttons.oiloh.count:SetText("")

        setButtonGlow(buttons.oil, false)
        setButtonGlow(buttons.oiloh, false)

        return
    end

    local usableOilItemID = lastWeaponEnchantItem

    if not usableOilItemID
        or usableOilItemID <= 0
        or GetItemCount(usableOilItemID, false, true) == 0
    then
        usableOilItemID = findWeaponEnchantItemInBags()

        if usableOilItemID then
            if not appliedMainHandItem then
                setWeaponEnchantIcon(buttons.oil, usableOilItemID)
            end

            if not appliedOffHandItem then
                setWeaponEnchantIcon(buttons.oiloh, usableOilItemID, true)
            end
        end
    end

    if not usableOilItemID then
        buttons.oil.outOfItemsText = WEAPON_ENCHANT_OUT_OF_ITEMS

        if offhandCanBeEnchanted then
            buttons.oiloh.outOfItemsText = WEAPON_ENCHANT_OUT_OF_ITEMS
        end

        hideWeaponEnchantClicks(buttons)

        setButtonGlow(buttons.oil, false)
        setButtonGlow(buttons.oiloh, false)

        return
    end

    local oilCount = GetItemCount(usableOilItemID, false, true)
    buttons.oil.count:SetText(oilCount)
    buttons.oiloh.count:SetText(oilCount)
    buttons.oil.usableItemID = usableOilItemID
    buttons.oil.clickHintItemID = usableOilItemID
    buttons.oiloh.usableItemID = usableOilItemID
    buttons.oiloh.clickHintItemID = usableOilItemID

    if not buttons.oil.tooltipItemID then
        buttons.oil.tooltipItemID = usableOilItemID
    end

    if not buttons.oiloh.tooltipItemID then
        buttons.oiloh.tooltipItemID = usableOilItemID
    end

    if oilCount and oilCount > 0 then
        Actions.SetWeaponEnchantItem(buttons.oil, usableOilItemID,
                                     mainHandCanBeEnchanted)
        Actions.SetWeaponEnchantItem(buttons.oiloh, usableOilItemID,
                                     offhandCanBeEnchanted)
    else
        hideWeaponEnchantClicks(buttons)
    end

    local needsMH = mainHandCanBeEnchanted and oilCount and oilCount > 0
                    and (not hasMainHandEnchant
                        or (mainHandExpiration
                            and mainHandExpiration <= 300000))

    setButtonGlow(buttons.oil, needsMH)

    local needsOH = offhandCanBeEnchanted and oilCount and oilCount > 0
                    and (not hasOffHandEnchant
                        or (offHandExpiration
                            and offHandExpiration <= 300000))

    setButtonGlow(buttons.oiloh, needsOH)
end

local function findAugmentItemInBags()
    local bestItemID
    local bestCount
    local bestData
    local bestXpac = -1
    local bestPriority = -1
    local preferUnlimited =
        RCC.GetSetting("consumables_preferUnlimitedAugment")

    for itemID, data in pairs(RCC.db.augmentItemIDs) do
        local count = GetItemCount(itemID, false, true)

        if count and count > 0 then
            local xpac = data.xpac or 0
            local priority = data.priority or 0
            local unlimited = data.unlimited == true
            local bestUnlimited = bestData
                and bestData.unlimited == true
                or false

            if preferUnlimited and unlimited ~= bestUnlimited
                and unlimited
            then
                bestItemID = itemID
                bestCount = count
                bestData = data
                bestXpac = xpac
                bestPriority = priority
            elseif not (preferUnlimited and unlimited ~= bestUnlimited)
                and (xpac > bestXpac
                    or (xpac == bestXpac and priority > bestPriority)
                    or (xpac == bestXpac and priority == bestPriority
                        and itemID > (bestItemID or 0)))
            then
                bestItemID = itemID
                bestCount = count
                bestData = data
                bestXpac = xpac
                bestPriority = priority
            end
        end
    end

    return bestItemID, bestCount, bestData
end

local function updateAugments(buttons, isAugment)
    local augmentItemID, augmentItemCount, augmentItemData =
        findAugmentItemInBags()

    if augmentItemID and augmentItemCount and augmentItemCount > 0 then
        if augmentItemData and augmentItemData.unlimited then
            buttons.augment.count:SetText("")
        else
            buttons.augment.count:SetFormattedText("%d", augmentItemCount)
        end

        buttons.augment.tooltipItemID = augmentItemID
        buttons.augment.usableItemID = augmentItemID

        if not isAugment then
            local icon = GetItemIcon(augmentItemID)

            if icon then
                buttons.augment.texture:SetTexture(icon)
            end
        end

        Actions.SetItemMacro(buttons.augment, augmentItemID)
    else
        buttons.augment.count:SetText("0")

        Actions.Disable(buttons.augment)

        if not isAugment then
            buttons.augment.outOfItemsText = "No Augment Runes found in Bags"
        end
    end

    if augmentItemID and not isAugment then
        setButtonGlow(buttons.augment, true)
    else
        setButtonGlow(buttons.augment, false)
    end
end

-- TODO: Update logic to only show most powerful found pot?
-- This will get weird if a healer has dmg pots and mana pots
local function updateDamagePotions(buttons)
    local inventoryItem,
          inventoryItemCount

    for i = 1, #RCC.db.potionItemIDs do
        local item  = RCC.db.potionItemIDs[i]
        local count = GetItemCount(item, false, true)

        if count and count > 0 then
            inventoryItem      = item
            inventoryItemCount = count

            break
        end
    end

    if inventoryItem and inventoryItemCount > 0 then
        buttons.dmgpot.count:SetFormattedText("%d", inventoryItemCount)
        buttons.dmgpot.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        buttons.dmgpot.texture:SetTexture(GetItemIcon(inventoryItem))
        buttons.dmgpot.texture:SetDesaturated(false)
        buttons.dmgpot.tooltipItemID = inventoryItem
    else
        buttons.dmgpot.count:SetText("0")
    end
end

local function updateHealingPotions(buttons)
    local inventoryItem,
          inventoryItemCount

    for i = 1, #RCC.db.healingPotionItemIDs do
        local item  = RCC.db.healingPotionItemIDs[i]
        local count = GetItemCount(item, false, true)

        if count and count > 0 then
            inventoryItem      = item
            inventoryItemCount = count

            break
        end
    end

    if inventoryItem and inventoryItemCount > 0 then
        buttons.healpot.count:SetFormattedText("%d", inventoryItemCount)
        buttons.healpot.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        buttons.healpot.texture:SetTexture(GetItemIcon(inventoryItem))
        buttons.healpot.texture:SetDesaturated(false)
        buttons.healpot.tooltipItemID = inventoryItem
    else
        buttons.healpot.count:SetText("0")
    end
end

local function getVantusForCurrentRaid()
    local instanceID = select(8, GetInstanceInfo())
    local vantusRuneIDs = RCC.db.vantusItemsByRaid[instanceID]

    -- db.vantusItemsByRaid does not have instance ID, return nils
    if not vantusRuneIDs then
        return nil, nil, 0
    end

    -- Return the first Vantus Rune we have in our inventory and the count
    for i = 1, #vantusRuneIDs do
        local count = GetItemCount(vantusRuneIDs[i], false, true)

        if count and count > 0 then
            return vantusRuneIDs, vantusRuneIDs[i], count
        end
    end

    -- Return the first Vantus Rune in the list so we can use the icon
    return vantusRuneIDs, vantusRuneIDs[1], 0
end

local function updateVantusRune(buttons, isVantus)
    local vantusRuneIDs, itemID, count = getVantusForCurrentRaid()
    local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

    -- db.vantusItemsByRaid does not have a entry for instance ID, hide
    if not vantusRuneIDs then
        setButtonShownInLayout(buttons.vantus, false)
        Actions.Disable(buttons.vantus)

        return
    end

    setButtonShownInLayout(buttons.vantus, true)

    if itemID then
        local icon_texture_id = GetItemIcon(itemID)
        buttons.vantus.texture:SetTexture(icon_texture_id)
    end

    if isVantus then
        buttons.vantus.timeleft:SetText(isVantus)
        buttons.vantus.statustexture:SetTexture(READY)
        buttons.vantus.hasConsumableBuff = true
        buttons.vantus.texture:SetDesaturated(false)

        if count > 0 then
            buttons.vantus.count:SetFormattedText("%d", count)
        end

        Actions.Disable(buttons.vantus)

        return
    end

    if itemID and count > 0 then
        buttons.vantus.count:SetFormattedText("%d", count)
        buttons.vantus.tooltipItemID = itemID
        buttons.vantus.usableItemID = itemID

        Actions.SetItemMacro(buttons.vantus, itemID)

        return
    end

    buttons.vantus.count:SetText("0")
    buttons.vantus.tooltipItemID = itemID
    buttons.vantus.outOfItemsText = "No Vantus Runes found in Bags"

    Actions.Disable(buttons.vantus)
end

--------------------------------------------------------------------------------
--- Dormant: Armor Kit handling
--- Not currently called. Preserved for future re-use.
--- To re-enable: create a kit button, add to layout, call from
--- Update().
--------------------------------------------------------------------------------

local function updateArmorKits(buttons)
    local kitCount = GetItemCount(172347, false, true)
    local kitNow, kitMax, kitTimeLeft = RCC:KitCheck()
    local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

    if kitNow > 0 then
        buttons.kit.statustexture:SetTexture(READY)
        buttons.kit.texture:SetDesaturated(false)

        if kitTimeLeft then
            buttons.kit.timeleft:SetText(kitTimeLeft)
        end
    end

    if kitCount and kitCount > 0 then
        Actions.SetItemMacro(buttons.kit, 172347, 5)
    else
        Actions.Disable(buttons.kit)
    end

    buttons.kit.count:SetFormattedText("%d", kitCount)

    if kitCount and kitCount > 0 and kitNow == 0 then
        setButtonGlow(buttons.kit, true)
    else
        setButtonGlow(buttons.kit, false)
    end
end

--------------------------------------------------------------------------------
--- Update() coordinator
--------------------------------------------------------------------------------

function RCC.consumables:Update()
    self:UpdateReadyCheckAnchor()
    local buttons = self.buttons

    local isWarlockInRaid = F.hasClassInRoster("WARLOCK")

    local NOT_READY = "Interface\\RaidFrame\\ReadyCheck-NotReady"

    for i = 1, #buttons do
        resetButtonState(buttons[i], NOT_READY)
    end

    setButtonShownInLayout(buttons.hs, isWarlockInRaid)

    local now = GetTime()
    local auraState = Auras.ScanPlayer(now)

    applyAuraState(buttons, auraState)

    local eatingRemaining = auraState.eating and auraState.eating.remaining

    if auraState.eating
        and eatingRemaining
        and isPositiveAuraDuration(auraState.eating.duration)
    then
        local cooldownStart = auraState.eating.expiry
                              - auraState.eating.duration
        buttons.food.cooldown:SetCooldown(cooldownStart,
                                          auraState.eating.duration)
        buttons.food.cooldown:Show()
    else
        buttons.food.cooldown:Clear()
    end

    updateFood(buttons, auraState.food and auraState.food.satisfied)
    updateHealthstones(buttons)
    updateFlasks(buttons, auraState.flask and auraState.flask.satisfied)
    updateWeaponEnchants(buttons)
    updateAugments(buttons, auraState.augment and auraState.augment.satisfied)
    updateDamagePotions(buttons)
    updateHealingPotions(buttons)
    updateVantusRune(buttons, auraState.vantus and auraState.vantus.bossName)

    if not InCombatLockdown() then
        Buttons.ApplyLayout(self, buttons)
    end

    Buttons.UpdateOutOverlays(buttons)
end
