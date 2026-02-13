local ADDON_NAME, RCC = ...

local F = RCC.F

local GetTime = GetTime

local      IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local       GetSpellInfo = C_Spell.GetSpellInfo
local        GetItemInfo = C_Item.GetItemInfo
local GetItemInfoInstant = C_Item.GetItemInfoInstant
local       GetItemCount = C_Item.GetItemCount

-------------------------------------------------------------------------------
--- Constants
-------------------------------------------------------------------------------

local consumables_size = 48
local FONT = "Interface\\AddOns\\"
    .. "ReadyCheckConsumables\\media\\fonts\\PTSansNarrow-Bold.ttf"

-------------------------------------------------------------------------------
--- Construct the button frame
-------------------------------------------------------------------------------

RCC.consumables = CreateFrame("Frame", "RCConsumables", ReadyCheckListenerFrame)
RCC.consumables:SetPoint("BOTTOM", ReadyCheckListenerFrame, "TOP", 0, 5)
RCC.consumables:SetSize(consumables_size * 5, consumables_size)
RCC.consumables:Hide()
RCC.consumables.buttons = {}

RCC.consumables.rlpointer = CreateFrame("Frame", nil, UIParent)
RCC.consumables.rlpointer:SetSize(1, 1)
RCC.consumables.rlpointer:SetPoint("CENTER")
RCC.consumables.rlpointer:Hide()

--- Close button
RCC.consumables.close = CreateFrame("Button", nil, RCC.consumables,
                                    "SecureHandlerClickTemplate")
RCC.consumables.close:SetSize(0, 20)
RCC.consumables.close:SetPoint("TOPLEFT", RCC.consumables, "BOTTOMLEFT", 0, -2)
RCC.consumables.close:SetPoint("TOPRIGHT", RCC.consumables, "BOTTOMRIGHT", 0, -2)
RCC.consumables.close:Hide()

RCC.consumables.close.bg = RCC.consumables.close:CreateTexture(nil, "BACKGROUND")
RCC.consumables.close.bg:SetAllPoints()
RCC.consumables.close.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

RCC.consumables.close.border = RCC.consumables.close:CreateTexture(nil, "BORDER")
RCC.consumables.close.border:SetPoint("TOPLEFT", -1, 1)
RCC.consumables.close.border:SetPoint("BOTTOMRIGHT", 1, -1)
RCC.consumables.close.border:SetColorTexture(0, 0, 0, 1)

RCC.consumables.close.highlight = RCC.consumables.close:CreateTexture(nil, "ARTWORK")
RCC.consumables.close.highlight:SetAllPoints(RCC.consumables.close.bg)
RCC.consumables.close.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
RCC.consumables.close.highlight:SetBlendMode("ADD")
RCC.consumables.close.highlight:Hide()

RCC.consumables.close.text = RCC.consumables.close:CreateFontString(nil, "OVERLAY")
RCC.consumables.close.text:SetPoint("CENTER")
RCC.consumables.close.text:SetFont(FONT, 12, "OUTLINE")
RCC.consumables.close.text:SetText(CLOSE or "x")
RCC.consumables.close.text:SetTextColor(1, 1, 1)

RCC.consumables.close:SetScript("OnEnter", function(self)
    self.highlight:Show()
end)

RCC.consumables.close:SetScript("OnLeave", function(self)
    self.highlight:Hide()
end)

RCC.consumables.close:SetFrameRef("consumables", RCC.consumables)
RCC.consumables.close:SetFrameRef("rlpointer", RCC.consumables.rlpointer)
RCC.consumables.close:SetAttribute("_onclick", [[
    self:GetFrameRef("rlpointer"):Hide()
]])

-------------------------------------------------------------------------------
--- Combat state driver
-------------------------------------------------------------------------------

local function ButtonOnEnter(self)
    self:GetParent():SetAlpha(0.7)
end

local function ButtonOnLeave(self)
    self:GetParent():SetAlpha(1)
end

RCC.consumables.state = CreateFrame("Frame", nil, nil,
                                    "SecureHandlerStateTemplate")

RCC.consumables.state:SetAttribute("_onstate-combat", [=[
    for i = 2, 9 do
        if i ~= 5 and i ~= 7 and i ~= 8 then
            if self:GetFrameRef("Button"..i) then
                if newstate == "hide" then
                    self:GetFrameRef("Button"..i):Hide()
                elseif newstate == "show" then
                    if self:GetFrameRef("Button"..i).IsON then
                        self:GetFrameRef("Button"..i):Show()
                    end
                end
            end
        end
    end
]=])

RegisterStateDriver(RCC.consumables.state, "combat",
                    "[combat] hide; [nocombat] show")

-------------------------------------------------------------------------------
--- Button creation (9 buttons)
--- 1=food  2=flask  3=mh_oil  4=rune  5=hs  6=oh_oil
--- 7=dmg_pot  8=heal_pot  9=vantus
-------------------------------------------------------------------------------

local     i_food = 1
local    i_flask = 2
local   i_mh_oil = 3
local     i_rune = 4
local       i_hs = 5
local   i_oh_oil = 6
local  i_dmg_pot = 7
local i_heal_pot = 8
local   i_vantus = 9

local CLICKABLE_BUTTONS = {
    [i_flask]  = true,
    [i_mh_oil] = true,
    [i_rune]   = true,
    [i_oh_oil] = true,
    [i_vantus] = true,
}

for i = 1, 9 do
    local button = CreateFrame("Frame", nil, RCC.consumables)
    RCC.consumables.buttons[i] = button
    button:SetSize(consumables_size, consumables_size)

    if i == 1 then
        button:SetPoint("LEFT", 0, 0)
    else
        button:SetPoint("LEFT", RCC.consumables.buttons[i - 1], "RIGHT", 0, 0)
    end

    button.texture = button:CreateTexture()
    button.texture:SetAllPoints()

    button.statustexture = button:CreateTexture(nil, "OVERLAY")
    button.statustexture:SetPoint("CENTER")
    button.statustexture:SetSize(consumables_size / 2, consumables_size / 2)

    button.timeleft = button:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    button.timeleft:SetPoint("BOTTOM", button, "TOP", 0, 1)
    button.timeleft:SetFont(FONT, 12, "OUTLINE")

    button.count = button:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.count:SetFont(FONT, 14, "OUTLINE")

    if CLICKABLE_BUTTONS[i] then
        button.click = CreateFrame("Button", nil, button,
                                   "SecureActionButtonTemplate")
        button.click:SetAllPoints()
        button.click:Hide()
        button.click:RegisterForClicks("AnyUp", "AnyDown")

        if i == i_mh_oil or i == i_oh_oil then
            button.click:SetAttribute("type", "item")
            button.click:SetAttribute("target-slot",
                                      i == i_mh_oil and "16" or "17")
        else
            button.click:SetAttribute("type", "macro")
        end

        button.click:SetScript("OnEnter", ButtonOnEnter)
        button.click:SetScript("OnLeave", ButtonOnLeave)

        RCC.consumables.state:SetFrameRef("Button" .. i, button.click)
    end

    if i == i_food then
        button.texture:SetTexture(RCC.db.food_icon_id)
        RCC.consumables.buttons.food = button

    elseif i == i_flask then
        button.texture:SetTexture(RCC.db.flask_icon_id)
        RCC.consumables.buttons.flask = button

    elseif i == i_mh_oil then
        button.texture:SetTexture(RCC.db.weapon_enchant_icon_id)
        RCC.consumables.buttons.oil = button

    elseif i == i_rune then
        button.texture:SetTexture(RCC.db.rune_icon_id)
        RCC.consumables.buttons.rune = button

    elseif i == i_hs then
        button.texture:SetTexture(RCC.db.healthstone_icon_id)
        RCC.consumables.buttons.hs = button

    elseif i == i_oh_oil then
        button.texture:SetTexture(RCC.db.weapon_enchant_icon_id)
        RCC.consumables.buttons.oiloh = button
        button:Hide()

    elseif i == i_dmg_pot then
        button.texture:SetTexture(RCC.db.potion_icon_id)
        RCC.consumables.buttons.dmgpot = button

    elseif i == i_heal_pot then
        button.texture:SetTexture(RCC.db.healing_potion_icon_id)
        RCC.consumables.buttons.healpot = button

    elseif i == i_vantus then
        button.texture:SetTexture(RCC.db.vantus_icon_id)
        RCC.consumables.buttons.vantus = button
        button:Hide()
    end
end

-------------------------------------------------------------------------------
--- Update helper functions
-------------------------------------------------------------------------------

local isElvUIFix

local function updateElvUIParent(self)
    if isElvUIFix then return end

    local needsFix = IsAddOnLoaded("ElvUI") or
                     IsAddOnLoaded("ShestakUI")

    if not needsFix then return end

    self:SetParent(ReadyCheckFrame)
    self:ClearAllPoints()
    self:SetPoint("BOTTOM", ReadyCheckFrame, "TOP", 0, 5)

    isElvUIFix = true
end

local function scanPlayerAuras(buttons, now)
    local isFlask, isRune, isVantus

    for i = 1, 60 do
        local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")

        if not auraData then break end

        local sid = auraData.spellId
        local expiry = auraData.expirationTime
        local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

        if RCC.db.foodBuffIDs[sid] or auraData.icon == RCC.db.food_icon_id then
            buttons.food.statustexture:SetTexture(READY)
            buttons.food.texture:SetDesaturated(false)
            buttons.food.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,
                                                   ceil((expiry - now) / 60))

        elseif RCC.db.flaskBuffIDs[sid] then
            buttons.flask.statustexture:SetTexture(READY)
            buttons.flask.texture:SetDesaturated(false)
            buttons.flask.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,
                                                    ceil((expiry - now) / 60))
            buttons.flask.texture:SetTexture(auraData.icon)
            isFlask = true

            if expiry - now <= 600 then
                isFlask = false
            end

        elseif RCC.db.tableRunes[sid] then
            buttons.rune.statustexture:SetTexture(READY)
            buttons.rune.texture:SetDesaturated(false)
            buttons.rune.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,
                                                   ceil((expiry - now) / 60))
            isRune = true

        elseif RCC.db.vantusBuffIDs[sid] then
            local name = auraData.name or ""
            isVantus = name:gsub("^Vantus Rune: ", "")
        end
    end

    return isFlask, isRune, isVantus
end

local function updateHealthstones(buttons)
    local hsCount = GetItemCount(RCC.db.healthstone_item_id, false, true)
    local hsLockCount = GetItemCount(224464, false, true)
    local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

    if hsCount and hsCount > 0 then
        buttons.hs.count:SetFormattedText("%d", hsCount)
        buttons.hs.statustexture:SetTexture(READY)
        buttons.hs.texture:SetDesaturated(false)

        if buttons.hs.texture.isRed then
            buttons.hs.texture:SetTexture(RCC.db.healthstone_icon_id)
            buttons.hs.texture.isRed = false
        end

    elseif hsLockCount and hsLockCount > 0 then
        buttons.hs.count:SetFormattedText("%d", hsLockCount)
        buttons.hs.statustexture:SetTexture(READY)
        buttons.hs.texture:SetDesaturated(false)

        if not buttons.hs.texture.isRed then
            buttons.hs.texture:SetTexture(538744)
            buttons.hs.texture.isRed = true
        end
    else
        buttons.hs.count:SetText("0")
    end
end

local function updateFlasks(buttons, isFlask, LCG)
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

    if not isFlask and flask_count > 0 then
        if not InCombatLockdown() then
            local itemName = GetItemInfo(flask_item_id)

            if itemName then
                buttons.flask.click:SetAttribute("macrotext1",
                    format("/stopmacro [combat]\n/use %s", itemName))

                buttons.flask.click:Show()
                buttons.flask.click.IsON = true

                local texture = select(5, GetItemInfoInstant(flask_item_id))

                if texture then
                    buttons.flask.texture:SetTexture(texture)
                end
            else
                buttons.flask.click:Hide()
                buttons.flask.click.IsON = false
            end
        end
    else
        if not InCombatLockdown() then
            buttons.flask.click:Hide()
            buttons.flask.click.IsON = false
        end
    end

    buttons.flask.count:SetFormattedText(
        "%s", flask_count > 0 and flask_count or "")

    if not LCG then return end

    if not isFlask and flask_count > 0 then
        LCG.PixelGlow_Start(buttons.flask)
    else
        LCG.PixelGlow_Stop(buttons.flask)
    end
end

local lastWeaponEnchantItem

local function updateWeaponEnchants(buttons, LCG)
    local offhandCanBeEnchanted
    local offhandItemID = GetInventoryItemID("player", 17)

    if offhandItemID then
        local itemClassID = select(6, GetItemInfoInstant(offhandItemID))

        if itemClassID == 2 then
            offhandCanBeEnchanted = true
        end
    end

    if not InCombatLockdown() then
        if offhandCanBeEnchanted then
            buttons.oiloh:Show()
            buttons.oiloh:ClearAllPoints()
            buttons.oiloh:SetPoint("LEFT", buttons.oil, "RIGHT", 0, 0)
            buttons.rune:ClearAllPoints()
            buttons.rune:SetPoint("LEFT", buttons.oiloh, "RIGHT", 0, 0)

        else
            buttons.oiloh:Hide()
            buttons.rune:ClearAllPoints()
            buttons.rune:SetPoint("LEFT", buttons.oil, "RIGHT", 0, 0)
        end
    end

    local hasMainHandEnchant, mainHandExpiration,
          mainHandCharges, mainHandEnchantID,
          hasOffHandEnchant, offHandExpiration,
          offHandCharges, offHandEnchantID = GetWeaponEnchantInfo()

    local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

    if hasMainHandEnchant then
        buttons.oil.statustexture:SetTexture(READY)
        buttons.oil.texture:SetDesaturated(false)
        buttons.oil.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,
            ceil((mainHandExpiration or 0) / 1000 / 60))

        if RCC.db.wenchants[mainHandEnchantID or 0] then
            lastWeaponEnchantItem = RCC.db.wenchants[mainHandEnchantID].item
        end
    end

    if offhandCanBeEnchanted and hasOffHandEnchant then
        buttons.oiloh.statustexture:SetTexture(READY)
        buttons.oiloh.texture:SetDesaturated(false)
        buttons.oiloh.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,
            ceil((offHandExpiration or 0) / 1000 / 60))
    end

    if lastWeaponEnchantItem
        and RCC.db.wenchants_items[lastWeaponEnchantItem]
    then
        local wenchData = RCC.db.wenchants_items[lastWeaponEnchantItem]
        buttons.oil.texture:SetTexture(wenchData.icon)
        buttons.oiloh.texture:SetTexture(wenchData.iconoh or wenchData.icon)
    end

    local oilItemID = lastWeaponEnchantItem

    if not oilItemID then
        local foundItem

        for itemID, data in pairs(RCC.db.wenchants_items) do
            -- Negative itemIDs are spells, not items
            if itemID > 0 and GetItemCount(itemID, false, true) > 0 then
                -- If we find 1 item, we want to store it. If we find a 2nd item
                --
                if foundItem then
                    foundItem = nil

                    break
                end

                foundItem = itemID
            end
        end

        if foundItem then
            oilItemID = foundItem
            local wenchData = RCC.db.wenchants_items[foundItem]

            buttons.oil.texture:SetTexture(wenchData.icon)
            buttons.oiloh.texture:SetTexture(wenchData.iconoh or wenchData.icon)
        end
    end

    if not oilItemID then
        if LCG then
            LCG.PixelGlow_Stop(buttons.oil)
            LCG.PixelGlow_Stop(buttons.oiloh)
        end

        return
    end

    local oilCount = GetItemCount(oilItemID, false, true)
    buttons.oil.count:SetText(oilCount)
    buttons.oiloh.count:SetText(oilCount)

    if type(oilItemID) == "number" and oilItemID < 0 then
        if not InCombatLockdown() then
            local spellInfo = GetSpellInfo(-oilItemID)
            local spellName = spellInfo and spellInfo.name
            buttons.oil.click:SetAttribute("spell", spellName)
            buttons.oil.click:Show()
            buttons.oil.click.IsON = true
            buttons.oil.click:SetAttribute("type", "spell")

            local ohSpellInfo = GetSpellInfo(-oilItemID)
            local ohSpellName = ohSpellInfo and ohSpellInfo.name
            buttons.oiloh.click:SetAttribute("spell", ohSpellName)
            buttons.oiloh.click:Show()
            buttons.oiloh.click.IsON = true
            buttons.oiloh.click:SetAttribute("type", "spell")
        end

        buttons.oil.count:SetText("")
        buttons.oiloh.count:SetText("")
    elseif oilCount and oilCount > 0 then
        if not InCombatLockdown() then
            local itemName = GetItemInfo(oilItemID)

            if itemName then
                buttons.oil.click:SetAttribute("item", itemName)
                buttons.oil.click:Show()
                buttons.oil.click.IsON = true

                if mainHandExpiration
                    and (oilItemID == 171285 or oilItemID == 171286)
                    and offhandItemID
                    and not offhandCanBeEnchanted then

                    buttons.oil.click:SetAttribute("type", "cancelaura")
                else
                    buttons.oil.click:SetAttribute("type", "item")
                end

                buttons.oiloh.click:SetAttribute("item", itemName)
                buttons.oiloh.click:Show()
                buttons.oiloh.click.IsON = true
            else
                buttons.oil.click:Hide()
                buttons.oil.click.IsON = false
                buttons.oiloh.click:Hide()
                buttons.oiloh.click.IsON = false
            end
        end
    else
        if not InCombatLockdown() then
            buttons.oil.click:Hide()
            buttons.oil.click.IsON = false
            buttons.oiloh.click:Hide()
            buttons.oiloh.click.IsON = false
        end
    end

    if not LCG then return end

    local needsMH = oilCount and oilCount > 0 and (not hasMainHandEnchant or
                    (mainHandExpiration and mainHandExpiration <= 300000))

    if needsMH then
        LCG.PixelGlow_Start(buttons.oil)
    else
        LCG.PixelGlow_Stop(buttons.oil)
    end

    local needsOH = oilCount and oilCount > 0 and (not hasOffHandEnchant
                    or (offHandExpiration and offHandExpiration <= 300000))

    if needsOH then
        LCG.PixelGlow_Start(buttons.oiloh)
    else
        LCG.PixelGlow_Stop(buttons.oiloh)
    end
end

local function updateRunes(buttons, isRune, LCG)
    local rune_item_count =
        GetItemCount(RCC.db.rune_item_id, false, true)
    local unlimited_rune_item_count =
        GetItemCount(RCC.db.unlimited_rune_item_id, false, true)

    if unlimited_rune_item_count
        and unlimited_rune_item_count > 0
    then
        buttons.rune.count:SetText("")

        if not InCombatLockdown() then
            buttons.rune.texture:SetTexture(RCC.db.unlimited_rune_icon_id)
            local itemName = GetItemInfo(RCC.db.unlimited_rune_item_id)

            if itemName then
                buttons.rune.click:SetAttribute("macrotext1",
                    format("/stopmacro [combat]\n/use %s", itemName))
                buttons.rune.click:Show()
                buttons.rune.click.IsON = true
            else
                buttons.rune.click:Hide()
                buttons.rune.click.IsON = false
            end
        end
    elseif rune_item_count and rune_item_count > 0 then
        buttons.rune.count:SetFormattedText("%d", rune_item_count)

        if not InCombatLockdown() then
            buttons.rune.texture:SetTexture(RCC.db.rune_icon_id)
            local itemName = GetItemInfo(RCC.db.rune_item_id)

            if itemName then
                buttons.rune.click:SetAttribute("macrotext1",
                    format("/stopmacro [combat]\n/use %s", itemName))
                buttons.rune.click:Show()
                buttons.rune.click.IsON = true
            else
                buttons.rune.click:Hide()
                buttons.rune.click.IsON = false
            end
        end
    else
        buttons.rune.count:SetText("0")

        if not InCombatLockdown() then
            buttons.rune.click:Hide()
            buttons.rune.click.IsON = false
        end
    end

    if not LCG then
        return
    end

    local hasRunes = (rune_item_count and rune_item_count > 0) or
        (unlimited_rune_item_count and unlimited_rune_item_count > 0)

    if hasRunes and not isRune then
        LCG.PixelGlow_Start(buttons.rune)
    else
        LCG.PixelGlow_Stop(buttons.rune)
    end
end

local function updateDamagePotions(buttons)
    local totalCount = 0

    for i = 1, #RCC.db.potionItemIDs do
        local count = GetItemCount(RCC.db.potionItemIDs[i], false, true)

        if count and count > 0 then
            totalCount = totalCount + count
        end
    end

    if totalCount > 0 then
        buttons.dmgpot.count:SetFormattedText("%d", totalCount)
        buttons.dmgpot.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        buttons.dmgpot.texture:SetDesaturated(false)
    else
        buttons.dmgpot.count:SetText("0")
    end
end

local function updateHealingPotions(buttons)
    local totalCount = 0

    for i = 1, #RCC.db.healingPotionItemIDs do
        local count = GetItemCount(RCC.db.healingPotionItemIDs[i], false, true)

        if count and count > 0 then
            totalCount = totalCount + count
        end
    end

    if totalCount > 0 then
        buttons.healpot.count:SetFormattedText("%d", totalCount)
        buttons.healpot.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        buttons.healpot.texture:SetDesaturated(false)
    else
        buttons.healpot.count:SetText("0")
    end
end

local GetInstanceInfo = GetInstanceInfo

local function getVantusForCurrentRaid()
    local instanceID = select(8, GetInstanceInfo())
    print("RCC: InstanceID: " .. instanceID)
    local vantusRuneIDs = RCC.db.vantusItemsByRaid[instanceID]

    -- db.vantusItemsByRaid does not have instance ID, return nils
    if not vantusRuneIDs then
        return nil, nil, 0
    end

    -- Return the first rune we have in our inventory and the count
    for i = 1, #vantusRuneIDs do
        local count = GetItemCount(vantusRuneIDs[i], false, true)

        if count and count > 0 then
            return vantusRuneIDs, vantusRuneIDs[i], count
        end
    end

    -- Return the first rune in the list so we can use the icon
    return vantusRuneIDs, vantusRuneIDs[1], 0
end

local function updateVantusRune(buttons, isVantus)
    local vantusRuneIDs, itemID, count = getVantusForCurrentRaid()
    local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

    -- db.vantusItemsByRaid does not have a entry for instance ID, hide
    if not vantusRuneIDs then
        if not InCombatLockdown() then
            buttons.vantus:Hide()
            buttons.vantus.click:Hide()
            buttons.vantus.click.IsON = false
        end

        return
    end

    if itemID then
        local icon_texture_id = select(10, C_Item.GetItemInfo(itemID))
        buttons.vantus.texture:SetTexture(icon_texture_id)
    end

    if not InCombatLockdown() then
        buttons.vantus:Show()
    end

    if isVantus then
        buttons.vantus.timeleft:SetText(isVantus)
        buttons.vantus.statustexture:SetTexture(READY)
        buttons.vantus.texture:SetDesaturated(false)

        if count > 0 then
            buttons.vantus.count:SetFormattedText("%d", count)
        end

        if not InCombatLockdown() then
            buttons.vantus.click:Hide()
            buttons.vantus.click.IsON = false
        end

        return
    end

    if itemID and count > 0 then
        buttons.vantus.count:SetFormattedText("%d", count)

        if not InCombatLockdown() then
            local itemName = GetItemInfo(itemID)

            if itemName then
                buttons.vantus.click:SetAttribute("macrotext1",
                    format("/stopmacro [combat]\n/use %s", itemName))
                buttons.vantus.click:Show()
                buttons.vantus.click.IsON = true
            else
                buttons.vantus.click:Hide()
                buttons.vantus.click.IsON = false
            end
        end

        return
    end

    buttons.vantus.count:SetText("0")

    if not InCombatLockdown() then
        buttons.vantus.click:Hide()
        buttons.vantus.click.IsON = false
    end
end

local function countVisibleButtons(buttons)
    local count = 0

    for i = 1, #buttons do
        if buttons[i]:IsShown() then
            count = count + 1
        end
    end

    return count
end

-------------------------------------------------------------------------------
--- Dormant: Armor Kit handling
--- Not currently called. Preserved for future re-use.
--- To re-enable: create a kit button, add to layout, call from
--- Update().
-------------------------------------------------------------------------------

local function updateArmorKits(buttons, LCG)
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
        if not InCombatLockdown() then
            local itemName = GetItemInfo(172347)

            if itemName then
                buttons.kit.click:SetAttribute("macrotext1",
                    format("/stopmacro [combat]\n" .. "/use %s\n/use 5", itemName))
                buttons.kit.click:Show()
                buttons.kit.click.IsON = true
            else
                buttons.kit.click:Hide()
                buttons.kit.click.IsON = false
            end
        end
    else
        if not InCombatLockdown() then
            buttons.kit.click:Hide()
            buttons.kit.click.IsON = false
        end
    end

    buttons.kit.count:SetFormattedText("%d", kitCount)

    if not LCG then return end

    if kitCount and kitCount > 0 and kitNow == 0 then
        LCG.PixelGlow_Start(buttons.kit)
    else
        LCG.PixelGlow_Stop(buttons.kit)
    end
end

-------------------------------------------------------------------------------
--- Update() coordinator
-------------------------------------------------------------------------------

function RCC.consumables:Update()
    updateElvUIParent(self)
    local buttons = self.buttons

    local isWarlockInRaid

    for _, _, _, class in
        F.IterateRoster, F.GetRaidDiffMaxGroup()
    do
        if class == "WARLOCK" then
            isWarlockInRaid = true

            break
        end
    end

    if not InCombatLockdown() then
        if isWarlockInRaid then
            buttons.hs:Show()
        else
            buttons.hs:Hide()
        end

        buttons.oil:ClearAllPoints()
        buttons.oil:SetPoint("LEFT", buttons.flask, "RIGHT", 0, 0)
    end

    local NOT_READY = "Interface\\RaidFrame\\ReadyCheck-NotReady"

    for i = 1, #buttons do
        buttons[i].statustexture:SetTexture(NOT_READY)
        buttons[i].timeleft:SetText("")
        buttons[i].count:SetText("")
        buttons[i].texture:SetDesaturated(true)
    end

    local LCG = LibStub("LibCustomGlow-1.0", true)
    local now = GetTime()

    local isFlask, isRune, isVantus = scanPlayerAuras(buttons, now)

    updateHealthstones(buttons)
    updateFlasks(buttons, isFlask, LCG)
    updateWeaponEnchants(buttons, LCG)
    updateRunes(buttons, isRune, LCG)
    updateDamagePotions(buttons)
    updateHealingPotions(buttons)
    updateVantusRune(buttons, isVantus)

    if not InCombatLockdown() then
        -- Chain potion buttons after the last dynamic button.
        -- Rune is always the last in the oil/oiloh/rune chain.
        local anchor = buttons.rune

        if isWarlockInRaid then
            buttons.hs:ClearAllPoints()
            buttons.hs:SetPoint("LEFT", anchor, "RIGHT", 0, 0)
            anchor = buttons.hs
        end

        buttons.dmgpot:ClearAllPoints()
        buttons.dmgpot:SetPoint("LEFT", anchor, "RIGHT", 0, 0)

        buttons.healpot:ClearAllPoints()
        buttons.healpot:SetPoint("LEFT", buttons.dmgpot, "RIGHT", 0, 0)

        if buttons.vantus:IsShown() then
            buttons.vantus:ClearAllPoints()
            buttons.vantus:SetPoint("LEFT", buttons.healpot, "RIGHT", 0, 0)
        end

        self:SetWidth(consumables_size * countVisibleButtons(buttons))
    end
end

-------------------------------------------------------------------------------
--- Repos / OnHide
-------------------------------------------------------------------------------

function RCC.consumables:Repos(isRL)
    if InCombatLockdown() then
        return
    end

    if isRL then
        self:SetParent(self.rlpointer)
        self:ClearAllPoints()
        self:SetPoint("CENTER", self.rlpointer, "CENTER", 0, 0)

        self.rlpointer:Show()
        self.close:Show()

        self.isRLpos = true
    elseif self.isRLpos then
        local parent

        if isElvUIFix then
            parent = ReadyCheckFrame
        else
            parent = ReadyCheckListenerFrame
        end

        self:SetParent(parent)
        self:ClearAllPoints()
        self:SetPoint("BOTTOM", parent, "TOP", 0, 5)

        self.isRLpos = false
    end
end

function RCC.consumables:OnHide()
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("UNIT_INVENTORY_CHANGED")

    if self.cancelDelay then
        self.cancelDelay:Cancel()
        self.cancelDelay = nil
    end
end
