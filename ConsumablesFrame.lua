local ADDON_NAME, RCC = ...

local F = RCC.F
local GetTime            = GetTime
local IsAddOnLoaded      = C_AddOns.IsAddOnLoaded
local       GetSpellInfo = C_Spell.GetSpellInfo
local        GetItemInfo = C_Item.GetItemInfo
local GetItemInfoInstant = C_Item.GetItemInfoInstant
local       GetItemCount = C_Item.GetItemCount
local        GetItemIcon = C_Item.GetItemIconByID

--------------------------------------------------------------------------------
--- Constants
--------------------------------------------------------------------------------

local consumables_size = 48
local FONT = "Interface\\AddOns\\"
    .. "ReadyCheckConsumables\\media\\fonts\\PTSansNarrow-Bold.ttf"

--------------------------------------------------------------------------------
--- Construct the button frame
--------------------------------------------------------------------------------

RCC.consumables = CreateFrame("Frame", "RCConsumables", UIParent)
RCC.consumables:SetPoint("BOTTOM", ReadyCheckListenerFrame, "TOP", 0, 5)
RCC.consumables:SetSize(consumables_size * 5, consumables_size)
RCC.consumables:Hide()
RCC.consumables.buttons = {}

RCC.consumables.anchor = CreateFrame("Frame", nil, UIParent)
RCC.consumables.anchor:SetSize(1, 1)
RCC.consumables.anchor:SetPoint("CENTER")
RCC.consumables.anchor:Hide()

--- Drag handle
RCC.consumables:SetMovable(true)
RCC.consumables:SetClampedToScreen(true)

RCC.consumables.drag = CreateFrame("Frame", nil, RCC.consumables)
RCC.consumables.drag:SetSize(20, 20)
RCC.consumables.drag:SetPoint("TOPLEFT", RCC.consumables, "BOTTOMLEFT", 1, -3)
RCC.consumables.drag:EnableMouse(true)
RCC.consumables.drag:RegisterForDrag("LeftButton")
RCC.consumables.drag:Hide()

RCC.consumables.drag.bg = RCC.consumables.drag:CreateTexture(nil, "BACKGROUND")
RCC.consumables.drag.bg:SetAllPoints()
RCC.consumables.drag.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

RCC.consumables.drag.border = RCC.consumables.drag:CreateTexture(nil, "BORDER")
RCC.consumables.drag.border:SetPoint("TOPLEFT", -1, 1)
RCC.consumables.drag.border:SetPoint("BOTTOMRIGHT", 1, -1)
RCC.consumables.drag.border:SetColorTexture(0, 0, 0, 1)

RCC.consumables.drag.highlight = RCC.consumables.drag:CreateTexture(nil, "ARTWORK")
RCC.consumables.drag.highlight:SetAllPoints(RCC.consumables.drag.bg)
RCC.consumables.drag.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
RCC.consumables.drag.highlight:SetBlendMode("ADD")
RCC.consumables.drag.highlight:Hide()

RCC.consumables.drag.icon = RCC.consumables.drag:CreateTexture(nil, "OVERLAY")
RCC.consumables.drag.icon:SetSize(12, 12)
RCC.consumables.drag.icon:SetPoint("CENTER")
RCC.consumables.drag.icon:SetTexture("Interface\\CURSOR\\UI-Cursor-Move")

RCC.consumables.drag:SetScript("OnEnter", function(self)
    self.highlight:Show()
end)

RCC.consumables.drag:SetScript("OnLeave", function(self)
    self.highlight:Hide()
end)

RCC.consumables.drag:SetScript("OnDragStart", function(self)
    RCC.consumables:StartMoving()
end)

RCC.consumables.drag:SetScript("OnDragStop", function(self)
    RCC.consumables:StopMovingOrSizing()
end)

--- Close button
RCC.consumables.close = CreateFrame("Button", nil, RCC.consumables,
                                    "SecureHandlerClickTemplate")
RCC.consumables.close:SetSize(0, 20)
RCC.consumables.close:SetPoint("TOPLEFT", RCC.consumables.drag, "TOPRIGHT", 3, 0)
RCC.consumables.close:SetPoint("TOPRIGHT", RCC.consumables, "BOTTOMRIGHT", -1, -3)
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
RCC.consumables.close:SetFrameRef("anchor", RCC.consumables.anchor)
RCC.consumables.close:SetAttribute("_onclick", [[
    self:GetFrameRef("consumables"):Hide()
    self:GetFrameRef("anchor"):Hide()
]])

--------------------------------------------------------------------------------
--- Combat state driver
--------------------------------------------------------------------------------

local function ClickButtonOnEnter(self)
    local button = self:GetParent()
    button:SetAlpha(0.7)

    if button.tooltipAuraID then
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(button.tooltipItemID)
        GameTooltip:Show()

        ShoppingTooltip1:SetOwner(GameTooltip, "ANCHOR_NONE")
        ShoppingTooltip1:SetPoint("BOTTOMLEFT", GameTooltip, "TOPLEFT", 0, 4)
        ShoppingTooltip1:SetUnitBuffByAuraInstanceID("player", button.tooltipAuraID)
        ShoppingTooltip1:Show()

        return
    end

    if button.tooltipItemID then
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(button.tooltipItemID)
        GameTooltip:Show()
    end
end

local function ClickButtonOnLeave(self)
    self:GetParent():SetAlpha(1)
    ShoppingTooltip1:Hide()
    GameTooltip:Hide()
end

local function InfoButtonOnEnter(self)
    if self.tooltipAuraID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self.tooltipItemID)
        GameTooltip:Show()

        ShoppingTooltip1:SetOwner(GameTooltip, "ANCHOR_NONE")
        ShoppingTooltip1:SetPoint("BOTTOMLEFT", GameTooltip, "TOPLEFT", 0, 4)
        ShoppingTooltip1:SetUnitBuffByAuraInstanceID("player", self.tooltipAuraID)
        ShoppingTooltip1:Show()

        return
    end

    if self.tooltipItemID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self.tooltipItemID)
        GameTooltip:Show()
    end
end

local function InfoButtonOnLeave()
    ShoppingTooltip1:Hide()
    GameTooltip:Hide()
end

RCC.consumables.state = CreateFrame("Frame", nil, nil,
                                    "SecureHandlerStateTemplate")

RCC.consumables.state:SetAttribute("_onstate-combat", [=[
    for i = 1, 9 do
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

--------------------------------------------------------------------------------
--- Button creation (9 buttons)
--- 1=food  2=flask  3=mh_oil  4=augment  5=hs  6=oh_oil
--- 7=dmg_pot  8=heal_pot  9=vantus
--------------------------------------------------------------------------------

local     i_food = 1
local    i_flask = 2
local   i_mh_oil = 3
local     i_augment = 4
local       i_hs = 5
local   i_oh_oil = 6
local  i_dmg_pot = 7
local i_heal_pot = 8
local   i_vantus = 9

local CLICKABLE_BUTTONS = {
    [i_food]   = true,
    [i_flask]  = true,
    [i_mh_oil] = true,
    [i_augment]   = true,
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

        button.click:SetScript("OnEnter", ClickButtonOnEnter)
        button.click:SetScript("OnLeave", ClickButtonOnLeave)

        RCC.consumables.state:SetFrameRef("Button" .. i, button.click)
    else
        button:EnableMouse(true)
        button:SetScript("OnEnter", InfoButtonOnEnter)
        button:SetScript("OnLeave", InfoButtonOnLeave)
    end

    if i == i_food then
        button.texture:SetTexture(RCC.db.food_icon_id)
        button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        button.cooldown:SetAllPoints()
        button.cooldown:SetDrawEdge(true)
        button.cooldown:SetDrawSwipe(true)
        RCC.consumables.buttons.food = button

    elseif i == i_flask then
        button.texture:SetTexture(RCC.db.flask_icon_id)
        RCC.consumables.buttons.flask = button

    elseif i == i_mh_oil then
        button.texture:SetTexture(RCC.db.weapon_enchant_icon_id)
        RCC.consumables.buttons.oil = button

    elseif i == i_augment then
        button.texture:SetTexture(RCC.db.augment_icon_id)
        RCC.consumables.buttons.augment = button

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

--------------------------------------------------------------------------------
--- Update helper functions
--------------------------------------------------------------------------------

local ITEM_INFO_RETRY_DELAY = 1
RCC.consumables.itemInfoRetryTimer = nil

local function cancelItemInfoRetry()
    if RCC.consumables.itemInfoRetryTimer then
        RCC.consumables.itemInfoRetryTimer:Cancel()
        RCC.consumables.itemInfoRetryTimer = nil
    end
end

local function scheduleItemInfoRetry()
    if RCC.consumables.itemInfoRetryTimer then
        return
    end

    RCC.consumables.itemInfoRetryTimer = C_Timer.NewTimer(ITEM_INFO_RETRY_DELAY, function()
        RCC.consumables.itemInfoRetryTimer = nil

        if RCC.consumables:IsShown() and not InCombatLockdown() then
            RCC.consumables:Update()
        end
    end)
end

local function getItemName(itemID)
    local itemName = itemID and GetItemInfo(itemID)

    if not itemName then
        scheduleItemInfoRetry()
    end

    return itemName
end

local isElvUIFix

local function updateElvUIParent(self)
    if isElvUIFix then return end

    local needsFix = IsAddOnLoaded("ElvUI") or
                     IsAddOnLoaded("ShestakUI")

    if not needsFix then return end

    self:ClearAllPoints()
    self:SetPoint("BOTTOM", ReadyCheckFrame, "TOP", 0, 5)

    isElvUIFix = true
end

local function scanPlayerAuras(buttons, now)
    local isFood, isFlask, isAugment, isVantus
    local isEating, eatingExpiry, eatingDuration, eatingIcon
    local foodExpiry, foodIcon, foodAuraID

    local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

    for i = 1, 60 do
        local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")

        if not auraData then
            break
        end

        if not issecretvalue(auraData.spellId) then
            local sid = auraData.spellId
            local expiry = auraData.expirationTime

            if RCC.db.foodBuffIDs[sid] or RCC.db.foodIconIDs[auraData.icon] then
                if RCC.db.eatingIconIDs[auraData.icon] then
                    isEating = true
                    eatingExpiry = expiry
                    eatingDuration = auraData.duration
                    eatingIcon = auraData.icon
                else
                    isFood = true
                    foodExpiry = expiry
                    foodIcon = auraData.icon
                    foodAuraID = auraData.auraInstanceID
                end

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

            elseif RCC.db.augmentBuffIDs[sid] then
                buttons.augment.statustexture:SetTexture(READY)
                buttons.augment.texture:SetDesaturated(false)
                buttons.augment.texture:SetTexture(auraData.icon)
                buttons.augment.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,
                                                       ceil((expiry - now) / 60))
                isAugment = true

            elseif RCC.db.vantusBuffIDs[sid] then
                local name = auraData.name or ""
                isVantus = name:gsub("^Vantus Rune: ", "")
            end
        end
    end

    if isFood then
        isEating = false
    elseif isEating then
        isFood = true
        foodExpiry = eatingExpiry
        foodIcon = eatingIcon
    end

    if isFood then
        local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"
        buttons.food.statustexture:SetTexture(READY)
        buttons.food.texture:SetDesaturated(false)
        buttons.food.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,
                                               ceil((foodExpiry - now) / 60))

        if foodIcon then
            buttons.food.texture:SetTexture(foodIcon)
        end

        if foodAuraID and not issecretvalue(foodAuraID) then
            buttons.food.tooltipAuraID = foodAuraID
        end
    end

    return isFood, isFlask, isAugment, isVantus, isEating, eatingExpiry, eatingDuration
end

local function updateFood(buttons, isFood, LCG)
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

        if not isFood then
            local texture = select(5, GetItemInfoInstant(food_item_id))

            if texture then
                buttons.food.texture:SetTexture(texture)
            end
        end

        if not InCombatLockdown() then
            local itemName = getItemName(food_item_id)

            if itemName then
                buttons.food.click:SetAttribute("macrotext1",
                    format("/stopmacro [combat]\n/use %s", itemName))

                buttons.food.click:Show()
                buttons.food.click.IsON = true
            else
                buttons.food.click:Hide()
                buttons.food.click.IsON = false
            end
        end
    else
        if not InCombatLockdown() then
            buttons.food.click:Hide()
            buttons.food.click.IsON = false
        end
    end

    buttons.food.count:SetFormattedText(
        "%s", food_count > 0 and food_count or "")

    if not LCG then return end

    if not isFood and food_count > 0 then
        LCG.PixelGlow_Start(buttons.food)
    else
        LCG.PixelGlow_Stop(buttons.food)
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

    if flask_count > 0 then
        buttons.flask.tooltipItemID = flask_item_id

        if not isFlask then
            local texture = select(5, GetItemInfoInstant(flask_item_id))

            if texture then
                buttons.flask.texture:SetTexture(texture)
            end
        end

        if not InCombatLockdown() then
            local itemName = getItemName(flask_item_id)

            if itemName then
                buttons.flask.click:SetAttribute("macrotext1",
                    format("/stopmacro [combat]\n/use %s", itemName))

                buttons.flask.click:Show()
                buttons.flask.click.IsON = true
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
        else
            buttons.oiloh:Hide()
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

        if RCC.db.weaponEnchants[mainHandEnchantID or 0] then
            lastWeaponEnchantItem = RCC.db.weaponEnchants[mainHandEnchantID].item
        end
    end

    if offhandCanBeEnchanted and hasOffHandEnchant then
        buttons.oiloh.statustexture:SetTexture(READY)
        buttons.oiloh.texture:SetDesaturated(false)
        buttons.oiloh.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,
            ceil((offHandExpiration or 0) / 1000 / 60))
    end

    if lastWeaponEnchantItem
        and RCC.db.weaponEnchantItems[lastWeaponEnchantItem]
    then
        local wenchData = RCC.db.weaponEnchantItems[lastWeaponEnchantItem]
        buttons.oil.texture:SetTexture(wenchData.icon)
        buttons.oiloh.texture:SetTexture(wenchData.iconoh or wenchData.icon)
    end

    local oilItemID = lastWeaponEnchantItem

    if not oilItemID then
        local foundItem

        for itemID, data in pairs(RCC.db.weaponEnchantItems) do
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
            local wenchData = RCC.db.weaponEnchantItems[foundItem]

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

    if type(oilItemID) == "number" and oilItemID > 0 then
        buttons.oil.tooltipItemID = oilItemID
        buttons.oiloh.tooltipItemID = oilItemID
    end

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
            local itemName = getItemName(oilItemID)

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

local function updateAugments(buttons, isAugment, LCG)
    local augment_item_count =
        GetItemCount(RCC.db.augment_item_id, false, true)
    local unlimited_augment_item_count =
        GetItemCount(RCC.db.unlimited_augment_item_id, false, true)

    if unlimited_augment_item_count
        and unlimited_augment_item_count > 0
    then
        buttons.augment.count:SetText("")
        buttons.augment.tooltipItemID = RCC.db.unlimited_augment_item_id

        if not isAugment then
            buttons.augment.texture:SetTexture(RCC.db.unlimited_augment_icon_id)
        end

        if not InCombatLockdown() then
            local itemName = getItemName(RCC.db.unlimited_augment_item_id)

            if itemName then
                buttons.augment.click:SetAttribute("macrotext1",
                    format("/stopmacro [combat]\n/use %s", itemName))
                buttons.augment.click:Show()
                buttons.augment.click.IsON = true
            else
                buttons.augment.click:Hide()
                buttons.augment.click.IsON = false
            end
        end
    elseif augment_item_count and augment_item_count > 0 then
        buttons.augment.count:SetFormattedText("%d", augment_item_count)
        buttons.augment.tooltipItemID = RCC.db.augment_item_id

        if not isAugment then
            buttons.augment.texture:SetTexture(RCC.db.augment_icon_id)
        end

        if not InCombatLockdown() then
            local itemName = getItemName(RCC.db.augment_item_id)

            if itemName then
                buttons.augment.click:SetAttribute("macrotext1",
                    format("/stopmacro [combat]\n/use %s", itemName))
                buttons.augment.click:Show()
                buttons.augment.click.IsON = true
            else
                buttons.augment.click:Hide()
                buttons.augment.click.IsON = false
            end
        end
    else
        buttons.augment.count:SetText("0")

        if not InCombatLockdown() then
            buttons.augment.click:Hide()
            buttons.augment.click.IsON = false
        end
    end

    if not LCG then
        return
    end

    local hasAugments = (augment_item_count and augment_item_count > 0) or
        (unlimited_augment_item_count and unlimited_augment_item_count > 0)

    if hasAugments and not isAugment then
        LCG.PixelGlow_Start(buttons.augment)
    else
        LCG.PixelGlow_Stop(buttons.augment)
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
        if not InCombatLockdown() then
            buttons.vantus:Hide()
            buttons.vantus.click:Hide()
            buttons.vantus.click.IsON = false
        end

        return
    end

    if itemID then
        local icon_texture_id = GetItemIcon(itemID)
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
        buttons.vantus.tooltipItemID = itemID

        if not InCombatLockdown() then
            local itemName = getItemName(itemID)

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

--------------------------------------------------------------------------------
--- Dormant: Armor Kit handling
--- Not currently called. Preserved for future re-use.
--- To re-enable: create a kit button, add to layout, call from
--- Update().
--------------------------------------------------------------------------------

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
            local itemName = getItemName(172347)

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

--------------------------------------------------------------------------------
--- Update() coordinator
--------------------------------------------------------------------------------

local ICON_SETTINGS = {
    [i_food]     = "icon_food",
    [i_flask]    = "icon_flask",
    [i_mh_oil]   = "icon_mhOil",
    [i_oh_oil]   = "icon_ohOil",
    [i_hs]       = "icon_healthstone",
    [i_dmg_pot]  = "icon_dmgPotion",
    [i_heal_pot] = "icon_healPotion",
    [i_augment]     = "icon_augment",
    [i_vantus]   = "icon_vantus",
}

local BUTTON_LAYOUT_ORDER = {
    i_food,
    i_flask,
    i_mh_oil,
    i_oh_oil,
    i_augment,
    i_hs,
    i_dmg_pot,
    i_heal_pot,
    i_vantus,
}

local function applyIconVisibilityAndLayout(self, buttons, isWarlockInRaid)
    local available = {
        [i_food]     = true,
        [i_flask]    = true,
        [i_mh_oil]   = true,
        [i_oh_oil]   = buttons.oiloh:IsShown(),
        [i_augment]  = true,
        [i_hs]       = isWarlockInRaid,
        [i_dmg_pot]  = true,
        [i_heal_pot] = true,
        [i_vantus]   = buttons.vantus:IsShown(),
    }

    local previous
    local visibleCount = 0

    for _, idx in ipairs(BUTTON_LAYOUT_ORDER) do
        local button = buttons[idx]
        local shouldShow = available[idx] and RCC.GetSetting(ICON_SETTINGS[idx])

        button:ClearAllPoints()

        if shouldShow then
            if previous then
                button:SetPoint("LEFT", previous, "RIGHT", 0, 0)
            else
                button:SetPoint("LEFT", 0, 0)
            end

            button:Show()
            previous = button
            visibleCount = visibleCount + 1
        else
            button:Hide()
        end
    end

    self:SetWidth(consumables_size * visibleCount)
end

function RCC.consumables:Update()
    updateElvUIParent(self)
    local buttons = self.buttons

    local isWarlockInRaid = F.hasClassInRoster("WARLOCK")

    if not InCombatLockdown() then
        if isWarlockInRaid then
            buttons.hs:Show()
        else
            buttons.hs:Hide()
        end
    end

    local NOT_READY = "Interface\\RaidFrame\\ReadyCheck-NotReady"

    for i = 1, #buttons do
        buttons[i].statustexture:SetTexture(NOT_READY)
        buttons[i].timeleft:SetText("")
        buttons[i].count:SetText("")
        buttons[i].texture:SetDesaturated(true)
        buttons[i].tooltipAuraID = nil
        buttons[i].tooltipItemID = nil
    end

    local LCG = LibStub("LibCustomGlow-1.0", true)
    local now = GetTime()

    local isFood, isFlask, isAugment, isVantus,
          isEating, eatingExpiry, eatingDuration = scanPlayerAuras(buttons, now)

    if isEating and eatingDuration and eatingDuration > 0 then
        buttons.food.cooldown:SetCooldown(eatingExpiry - eatingDuration, eatingDuration)
        buttons.food.cooldown:Show()
    else
        buttons.food.cooldown:Clear()
    end

    updateFood(buttons, isFood, LCG)
    updateHealthstones(buttons)
    updateFlasks(buttons, isFlask, LCG)
    updateWeaponEnchants(buttons, LCG)
    updateAugments(buttons, isAugment, LCG)
    updateDamagePotions(buttons)
    updateHealingPotions(buttons)
    updateVantusRune(buttons, isVantus)

    if not InCombatLockdown() then
        applyIconVisibilityAndLayout(self, buttons, isWarlockInRaid)
    end
end

--------------------------------------------------------------------------------
--- Repos / OnHide
--------------------------------------------------------------------------------

function RCC.consumables:Repos(isInitiator)
    if InCombatLockdown() then
        return
    end

    if isInitiator then
        self:ClearAllPoints()
        self:SetPoint("CENTER", self.anchor, "CENTER", 0, 0)

        self.anchor:Show()
        self.drag:Show()
        self.close:Show()
    else
        local anchor = isElvUIFix and ReadyCheckFrame
                                   or ReadyCheckListenerFrame

        self:ClearAllPoints()
        self:SetPoint("BOTTOM", anchor, "TOP", 0, 5)
    end
end

function RCC.consumables:OnHide()
    cancelItemInfoRetry()

    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
    self:UnregisterEvent("READY_CHECK_CONFIRM")
    self.anchor:Hide()

    if self.cancelDelay then
        self.cancelDelay:Cancel()
        self.cancelDelay = nil
    end
end
