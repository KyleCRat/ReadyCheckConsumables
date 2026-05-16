local ADDON_NAME, RCC = ...

local Auras = RCC.ConsumableFrameAuras
local F = RCC.F
local Actions = RCC.ConsumableFrameActions
local Buttons = RCC.ConsumableFrameButtons
local Food = RCC.Consumables.Food
local Flask = RCC.Consumables.Flask
local Healthstone = RCC.Consumables.Healthstone
local DamagePotion = RCC.Consumables.DamagePotion
local HealingPotion = RCC.Consumables.HealingPotion
local Glow = RCC.ConsumableFrameGlow

local            GetTime = GetTime
local       GetSpellInfo = C_Spell.GetSpellInfo
local GetItemInfoInstant = C_Item.GetItemInfoInstant
local       GetItemCount = C_Item.GetItemCount
local        GetItemIcon = C_Item.GetItemIconByID

local setButtonGlow = Glow.Set
local setButtonShownInLayout = Buttons.SetShownInLayout
local resetButtonState = Buttons.ResetState

--------------------------------------------------------------------------------
--- Update helper functions
--------------------------------------------------------------------------------

local function applyAuraState(buttons, state)
    local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

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

    Food.Update(buttons.food, auraState)
    Healthstone.Update(buttons.hs)
    Flask.Update(buttons.flask, auraState)
    updateWeaponEnchants(buttons)
    updateAugments(buttons, auraState.augment and auraState.augment.satisfied)
    DamagePotion.Update(buttons.dmgpot)
    HealingPotion.Update(buttons.healpot)
    updateVantusRune(buttons, auraState.vantus and auraState.vantus.bossName)

    if not InCombatLockdown() then
        Buttons.ApplyLayout(self, buttons)
    end

    Buttons.UpdateOutOverlays(buttons)
end
