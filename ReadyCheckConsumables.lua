local ADDON_NAME, RCC = ...

RCC.db = RCC.db or {}
local L = {}  -- localization table placeholder
local F = RCC.F

local GetTime = GetTime
local IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
local GetSpellInfo = C_Spell.GetSpellInfo
local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
local GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
local GetItemCount = C_Item and C_Item.GetItemCount or GetItemCount
local SendChatMessage = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
local IsEncounterInProgress = C_InstanceEncounter and C_InstanceEncounter.IsEncounterInProgress or IsEncounterInProgress

-------------------------------------------------------------------------------
--- Construct the button frame
-------------------------------------------------------------------------------

-- Size of the icons in the frame
local consumables_size = 48
local FONT = "Interface\\AddOns\\ReadyCheckConsumables\\media\\fonts\\PTSansNarrow-Bold.ttf"

RCC.consumables = CreateFrame("Frame", "RCConsumables", ReadyCheckListenerFrame)
RCC.consumables:SetPoint("BOTTOM", ReadyCheckListenerFrame, "TOP", 0, 5)
RCC.consumables:SetSize(consumables_size * 5, consumables_size)
RCC.consumables:Hide()
RCC.consumables.buttons = {}

RCC.consumables.rlpointer = CreateFrame("Frame", nil, UIParent)
RCC.consumables.rlpointer:SetSize(1, 1)
RCC.consumables.rlpointer:SetPoint("CENTER")
RCC.consumables.rlpointer:Hide()

RCC.consumables.close = CreateFrame("Button", nil, RCC.consumables, "SecureHandlerClickTemplate")
RCC.consumables.close:SetSize(0, 20)
RCC.consumables.close:SetPoint("TOPLEFT", RCC.consumables, "BOTTOMLEFT", 0, -2)
RCC.consumables.close:SetPoint("TOPRIGHT", RCC.consumables, "BOTTOMRIGHT", 0, -2)
RCC.consumables.close:Hide()

-- Dark background
RCC.consumables.close.bg = RCC.consumables.close:CreateTexture(nil, "BACKGROUND")
RCC.consumables.close.bg:SetAllPoints()
RCC.consumables.close.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

-- Border
RCC.consumables.close.border = RCC.consumables.close:CreateTexture(nil, "BORDER")
RCC.consumables.close.border:SetPoint("TOPLEFT", -1, 1)
RCC.consumables.close.border:SetPoint("BOTTOMRIGHT", 1, -1)
RCC.consumables.close.border:SetColorTexture(0, 0, 0, 1)

-- Highlight
RCC.consumables.close.highlight = RCC.consumables.close:CreateTexture(nil, "ARTWORK")
RCC.consumables.close.highlight:SetAllPoints(RCC.consumables.close.bg)
RCC.consumables.close.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
RCC.consumables.close.highlight:SetBlendMode("ADD")
RCC.consumables.close.highlight:Hide() -- Hide by default

-- White text with custom font
RCC.consumables.close.text = RCC.consumables.close:CreateFontString(nil, "OVERLAY")
RCC.consumables.close.text:SetPoint("CENTER")
RCC.consumables.close.text:SetFont(FONT, 12, "OUTLINE")
RCC.consumables.close.text:SetText(CLOSE or 'x')
RCC.consumables.close.text:SetTextColor(1, 1, 1)

-- Add hover functionality
RCC.consumables.close:SetScript("OnEnter", function(self)
    self.highlight:Show()
end)
RCC.consumables.close:SetScript("OnLeave", function(self)
    self.highlight:Hide()
end)

-- Secure click handler for combat
RCC.consumables.close:SetFrameRef("consumables", RCC.consumables)
RCC.consumables.close:SetFrameRef("rlpointer", RCC.consumables.rlpointer)
RCC.consumables.close:SetAttribute("_onclick", [[
    self:GetFrameRef("rlpointer"):Hide()
]])

local function ButtonOnEnter(self)
    self:GetParent():SetAlpha(.7)
end

local function ButtonOnLeave(self)
    self:GetParent():SetAlpha(1)
end

RCC.consumables.state = CreateFrame('Frame', nil, nil, 'SecureHandlerStateTemplate')
RCC.consumables.state:SetAttribute('_onstate-combat', [=[
    for i=2,8 do
        if i ~= 6 then
            if self:GetFrameRef("Button"..i) then
                if newstate == 'hide' then
                    self:GetFrameRef("Button"..i):Hide()
                elseif newstate == 'show' then
                    if self:GetFrameRef("Button"..i).IsON then
                        self:GetFrameRef("Button"..i):Show()
                    end
                end
            end
        end
    end
]=])

RegisterStateDriver(RCC.consumables.state, 'combat', '[combat] hide; [nocombat] show')

local i_food = 1
local i_flask = 2
local i_kit = 3
local i_mh_oil = 4
local i_rune = 5
local i_hs = 6
local i_of_oil = 7
local i_class = 8

for i = 1, 8 do
    local button = CreateFrame("Frame", nil, RCC.consumables)
    RCC.consumables.buttons[i] = button
    button:SetSize(consumables_size,consumables_size)

    if i == 1 then
        button:SetPoint("LEFT", 0, 0)
        else
        button:SetPoint("LEFT", RCC.consumables.buttons[i-1], "RIGHT", 0, 0)
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

    if i == i_flask or i == i_kit or i == i_mh_oil or i == i_rune or i == i_of_oil or i == i_class then
        button.click = CreateFrame("Button", nil, button, "SecureActionButtonTemplate")
        button.click:SetAllPoints()
        button.click:Hide()
        button.click:RegisterForClicks("AnyUp", "AnyDown")
        if i == i_mh_oil or i == i_of_oil then
            button.click:SetAttribute("type", "item")
            button.click:SetAttribute("target-slot", i == i_mh_oil and "16" or "17")
        else
            button.click:SetAttribute("type", "macro")
        end

        button.click:SetScript("OnEnter", ButtonOnEnter)
        button.click:SetScript("OnLeave", ButtonOnLeave)

        RCC.consumables.state:SetFrameRef("Button"..i, button.click)
    end

    if i == i_food then
        -- FOOD (spell-misc-food)
        button.texture:SetTexture(RCC.db.food_icon_id)
        RCC.consumables.buttons.food = button
    elseif i == i_flask then
        -- Flask (Inv_alchemy_90_flask_green)
        button.texture:SetTexture(RCC.db.flask_icon_id)
        RCC.consumables.buttons.flask = button
    elseif i == i_kit then
        -- Armour Kit (Inv_leatherworking_armorpatch_heavy)
        button.texture:SetTexture(RCC.db.armor_kit_icon_id)
        RCC.consumables.buttons.kit = button
    elseif i == i_mh_oil then
        -- Weapon Oil
        button.texture:SetTexture(RCC.db.weapon_enchant_icon_id)
        RCC.consumables.buttons.oil = button
    elseif i == i_rune then
        -- Augment Rune
        button.texture:SetTexture(rune_texture)
        RCC.consumables.buttons.rune = button
    elseif i == i_hs then
        -- Healthstone
        button.texture:SetTexture(RCC.db.healthstone_icon_id)
        RCC.consumables.buttons.hs = button
    elseif i == i_of_oil then
        -- Offhand Oil
        button.texture:SetTexture(RCC.db.weapon_enchant_icon_id)
        RCC.consumables.buttons.oiloh = button
        button:Hide()
    elseif i == i_class then
        -- Class (Lightning Shield)
        button.texture:SetTexture(RCC.db.class_icon_id)
        RCC.consumables.buttons.class = button
        button:Hide()
    end
end

-------------------------------------------------------------------------------
--- Update Function
-------------------------------------------------------------------------------
local isElvUIFix
local lastWeaponEnchantItem

function RCC.consumables:Update()
    local totalButtons = 6

    -- Secret Checking
    if C_Secrets and C_Secrets.ShouldAurasBeSecret() then
        return
    elseif canaccessvalue then
        local accessData = C_UnitAuras.GetAuraDataByIndex("player", 1, "HELPFUL")

        if accessData and not canaccessvalue(accessData.icon) then
            return
        end
    end

    -- Check if UI fix is needed
    if (IsAddOnLoaded("ElvUI") or IsAddOnLoaded("ShestakUI")) and not isElvUIFix then
        self:SetParent(ReadyCheckFrame)
        self:ClearAllPoints()
        self:SetPoint("BOTTOM",ReadyCheckFrame,"TOP",0,5)
        isElvUIFix = true
    end

    -- Check for Warlock to know if we should show healthstones
    local isWarlockInRaid

    for _, name, _, class in F.IterateRoster, F.GetRaidDiffMaxGroup() do
        if class == "WARLOCK" then
            isWarlockInRaid = true
            break
        end
    end

    if not InCombatLockdown() then
        if isWarlockInRaid then
            self.buttons.hs:Show()
        else
            self.buttons.hs:Hide()
            totalButtons = totalButtons - 1
        end

        self.buttons.kit:Hide()
        totalButtons = totalButtons - 1

        self.buttons.oil:ClearAllPoints()
        self.buttons.oil:SetPoint("LEFT", self.buttons.flask, "RIGHT", 0,0)
    end

    for i=1,#self.buttons do
        self.buttons[i].statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        self.buttons[i].timeleft:SetText("")
        self.buttons[i].count:SetText("")
        self.buttons[i].texture:SetDesaturated(true)
    end

    local LCG = LibStub("LibCustomGlow-1.0", true)

    local now = GetTime()

    local isFood, isRune, isFlask
    local isShamanBuff

    for i=1,60 do
        local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not auraData then
            break
        elseif RCC.db.foodBuffIDs[auraData.spellId] or auraData.icon == RCC.db.food_icon_id then
            self.buttons.food.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
            self.buttons.food.texture:SetDesaturated(false)
            self.buttons.food.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES, ceil((auraData.expirationTime-now)/60))
            isFood = true
        elseif RCC.db.flaskBuffIDs[auraData.spellId] then
            self.buttons.flask.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
            self.buttons.flask.texture:SetDesaturated(false)
            self.buttons.flask.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES, ceil((auraData.expirationTime-now)/60))
            self.buttons.flask.texture:SetTexture(auraData.icon)
            isFlask = true
            if auraData.expirationTime - now <= 600 then
                -- if falsk is expiring in less than 5 minutes show it as false
                isFlask = false
            end
        elseif RCC.db.tableRunes[auraData.spellId] then
            self.buttons.rune.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
            self.buttons.rune.texture:SetDesaturated(false)
            self.buttons.rune.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES, ceil((auraData.expirationTime-now)/60))
            isRune = true
        elseif auraData.spellId == 192106 then
            isShamanBuff = format(GARRISON_DURATION_MINUTES,ceil((auraData.expirationTime-now)/60))

            if auraData.expirationTime - now <= 600 then
                isShamanBuff = false
            end
        end
    end

    ---------------------------------------------------------------------------
    --- Start Health Stone Handling
    local hsCount = GetItemCount(RCC.db.healthstone_item_id, false, true)
    local hsLockCount = GetItemCount(224464, false, true) -- Demonic Healthstone

    if hsCount and hsCount > 0 then
        self.buttons.hs.count:SetFormattedText("%d",hsCount)
        self.buttons.hs.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        self.buttons.hs.texture:SetDesaturated(false)

        if self.buttons.hs.texture.isRed then
            self.buttons.hs.texture:SetTexture(RCC.db.healthstone_icon_id)
            self.buttons.hs.texture.isRed = false
        end
    elseif hsLockCount and hsLockCount > 0 then
        self.buttons.hs.count:SetFormattedText("%d",hsLockCount)
        self.buttons.hs.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        self.buttons.hs.texture:SetDesaturated(false)

        if not self.buttons.hs.texture.isRed then
            self.buttons.hs.texture:SetTexture(538744)
            self.buttons.hs.texture.isRed = true
        end
    else
        self.buttons.hs.count:SetText("0")
    end
    --- END Health Stone Handling

    ---------------------------------------------------------------------------
    --- Start Flask Handling
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

    if not isFlask and (flask_count and flask_count > 0) then
        if not InCombatLockdown() then
            local itemID = flask_item_id
            local itemName = GetItemInfo(itemID)

            if itemName then
                self.buttons.flask.click:SetAttribute("macrotext1", format("/stopmacro [combat]\n/use %s", itemName))
                self.buttons.flask.click:Show()
                self.buttons.flask.click.IsON = true

                local texture = select(5, C_Item.GetItemInfoInstant(itemID))
                if texture then
                    self.buttons.flask.texture:SetTexture(texture)
                end
            else
                self.buttons.flask.click:Hide()
                self.buttons.flask.click.IsON = false
            end
        end
    else
        if not InCombatLockdown() then
            self.buttons.flask.click:Hide()
            self.buttons.flask.click.IsON = false
        end
    end

    -- Show stacks on flask
    self.buttons.flask.count:SetFormattedText("%s", flask_count > 0 and flask_count or "")

    if LCG then
        if not isFlask and (flask_count and flask_count > 0) then
            LCG.PixelGlow_Start(self.buttons.flask)
        else
            LCG.PixelGlow_Stop(self.buttons.flask)
        end
    end
    --- End Flask Handling

    ---------------------------------------------------------------------------
    --- Start Armor Kits Handling
    -- Only existed in shadowlands so far so only work if we are in shadowlands
    --
    -- KitCheck not implemented, if kits exist in the future need to re-work
    --
    --
    -- if CURRENT_XPAC == SHADOWLANDS then
    --     local kitCount = GetItemCount(172347, false, true)
    --     local kitNow, kitMax, kitTimeLeft = RCC:KitCheck()

    --     if kitNow > 0 then
    --         self.buttons.kit.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    --         self.buttons.kit.texture:SetDesaturated(false)
    --         if kitTimeLeft then
    --             self.buttons.kit.timeleft:SetText(kitTimeLeft)
    --         end
    --     end

    --     if kitCount and kitCount > 0 then
    --         if not InCombatLockdown() then
    --             local itemName = GetItemInfo(172347)
    --             if itemName then
    --                 self.buttons.kit.click:SetAttribute("macrotext1", format("/stopmacro [combat]\n/use %s\n/use 5", itemName))
    --                 self.buttons.kit.click:Show()
    --                 self.buttons.kit.click.IsON = true
    --                 else
    --                 self.buttons.kit.click:Hide()
    --                 self.buttons.kit.click.IsON = false
    --             end
    --         end
    --     else
    --         if not InCombatLockdown() then
    --             self.buttons.kit.click:Hide()
    --             self.buttons.kit.click.IsON = false
    --         end
    --     end

    --     self.buttons.kit.count:SetFormattedText("%d",kitCount)

    --     if LCG then
    --         if kitCount and kitCount > 0 and kitNow == 0 then
    --             LCG.PixelGlow_Start(self.buttons.kit)
    --         else
    --             LCG.PixelGlow_Stop(self.buttons.kit)
    --         end
    --     end
    -- end
    --- END Armor Kit Handling

    ---------------------------------------------------------------------------
    --- Start Weapon Enchant Handling
    lastWeaponEnchantItem = lastWeaponEnchantItem

    local offhandCanBeEnchanted
    local offhandItemID = GetInventoryItemID("player", 17)

    if offhandItemID then
        local _, _, _, _, _, itemClassID, itemSubClassID = GetItemInfoInstant(offhandItemID)
        if itemClassID == 2 then
            offhandCanBeEnchanted = true
        end
    end

    if not InCombatLockdown() then
        if offhandCanBeEnchanted then
            self.buttons.oiloh:Show()
            totalButtons = totalButtons + 1
            self.buttons.oiloh:ClearAllPoints()
            self.buttons.oiloh:SetPoint("LEFT",self.buttons.oil,"RIGHT",0,0)
            self.buttons.rune:ClearAllPoints()
            self.buttons.rune:SetPoint("LEFT",self.buttons.oiloh,"RIGHT",0,0)
        else
            self.buttons.oiloh:Hide()
            self.buttons.rune:ClearAllPoints()
            self.buttons.rune:SetPoint("LEFT",self.buttons.oil,"RIGHT",0,0)
        end
    end


    local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID = GetWeaponEnchantInfo()

    if hasMainHandEnchant then
        self.buttons.oil.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        self.buttons.oil.texture:SetDesaturated(false)
        self.buttons.oil.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,ceil((mainHandExpiration or 0)/1000/60))

        if RCC.db.wenchants[mainHandEnchantID or 0] then
            lastWeaponEnchantItem = RCC.db.wenchants[mainHandEnchantID].item
        end
    end

    if offhandCanBeEnchanted and hasOffHandEnchant then
        self.buttons.oiloh.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        self.buttons.oiloh.texture:SetDesaturated(false)
        self.buttons.oiloh.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,ceil((offHandExpiration or 0)/1000/60))
    end

    local wenchData

    if lastWeaponEnchantItem and RCC.db.wenchants_items[lastWeaponEnchantItem] then
        wenchData = RCC.db.wenchants_items[lastWeaponEnchantItem]
        self.buttons.oil.texture:SetTexture(wenchData.icon)
        self.buttons.oiloh.texture:SetTexture(wenchData.iconoh or wenchData.icon)
    end

    local oilItemID = lastWeaponEnchantItem

    if oilItemID then
        local oilCount = GetItemCount(oilItemID,false,true)
        self.buttons.oil.count:SetText(oilCount)
        self.buttons.oiloh.count:SetText(oilCount)

        if type(oilItemID) == 'number' and oilItemID < 0 then   --for spell enchants
            if not InCombatLockdown() then
                local spellInfo = GetSpellInfo(-oilItemID)
                local spellName = spellInfo and spellInfo.name
                self.buttons.oil.click:SetAttribute("spell", spellName)
                self.buttons.oil.click:Show()
                self.buttons.oil.click.IsON = true
                self.buttons.oil.click:SetAttribute("type", "spell")
                local spellInfo = GetSpellInfo(oilItemID == -33757 and 318038 or -oilItemID)
                local spellName = spellInfo and spellInfo.name
                self.buttons.oiloh.click:SetAttribute("spell", spellName)
                self.buttons.oiloh.click:Show()
                self.buttons.oiloh.click.IsON = true
                self.buttons.oiloh.click:SetAttribute("type", "spell")
            end

            self.buttons.oil.count:SetText("")
            self.buttons.oiloh.count:SetText("")
        elseif oilCount and oilCount > 0 then
            if not InCombatLockdown() then
                local itemName = GetItemInfo(oilItemID)

                if itemName then
                    self.buttons.oil.click:SetAttribute("item", itemName)
                    self.buttons.oil.click:Show()
                    self.buttons.oil.click.IsON = true
                    if
                        mainHandExpiration and
                        (oilItemID == 171285 or oilItemID == 171286) and
                        offhandItemID and not offhandCanBeEnchanted
                    then
                        self.buttons.oil.click:SetAttribute("type", "cancelaura")
                    else
                        self.buttons.oil.click:SetAttribute("type", "item")
                    end
                    self.buttons.oiloh.click:SetAttribute("item", itemName)
                    self.buttons.oiloh.click:Show()
                    self.buttons.oiloh.click.IsON = true
                else
                    self.buttons.oil.click:Hide()
                    self.buttons.oil.click.IsON = false
                    self.buttons.oiloh.click:Hide()
                    self.buttons.oiloh.click.IsON = false
                end
            end
        else
            if not InCombatLockdown() then
                self.buttons.oil.click:Hide()
                self.buttons.oil.click.IsON = false
                self.buttons.oiloh.click:Hide()
                self.buttons.oiloh.click.IsON = false
            end
        end

        if LCG then
            if oilCount and oilCount > 0 and (not hasMainHandEnchant or (mainHandExpiration and mainHandExpiration <= 300000)) then
                LCG.PixelGlow_Start(self.buttons.oil)
                else
                LCG.PixelGlow_Stop(self.buttons.oil)
            end

            if oilCount and oilCount > 0 and (not hasOffHandEnchant or (offHandExpiration and offHandExpiration <= 300000)) then
                LCG.PixelGlow_Start(self.buttons.oiloh)
                else
                LCG.PixelGlow_Stop(self.buttons.oiloh)
            end
        end
    else
        if LCG then
            LCG.PixelGlow_Stop(self.buttons.oil)
            LCG.PixelGlow_Stop(self.buttons.oiloh)
        end
    end
    -- END Weapon Enchant Handling

    ---------------------------------------------------------------------------
    --- Start Rune Handling
    local rune_item_count = GetItemCount(RCC.db.rune_item_id, false, true)
    local unlimited_rune_item_count = GetItemCount(RCC.db.unlimited_rune_item_id, false, true)

    if unlimited_rune_item_count and unlimited_rune_item_count > 0 then
        self.buttons.rune.count:SetText("")

        if not InCombatLockdown() then
            self.buttons.rune.texture:SetTexture(RCC.db.unlimited_rune_icon_id)
            local itemName = GetItemInfo(RCC.db.unlimited_rune_item_id)

            if itemName then
                self.buttons.rune.click:SetAttribute("macrotext1", format("/stopmacro [combat]\n/use %s", itemName))
                self.buttons.rune.click:Show()
                self.buttons.rune.click.IsON = true
                else
                self.buttons.rune.click:Hide()
                self.buttons.rune.click.IsON = false
            end
        end
    elseif rune_item_count and rune_item_count > 0 then
        self.buttons.rune.count:SetFormattedText("%d", rune_item_count)

        if not InCombatLockdown() then
            self.buttons.rune.texture:SetTexture(RCC.db.rune_icon_id)
            local itemName = GetItemInfo(RCC.db.rune_item_id)

            if itemName then
                self.buttons.rune.click:SetAttribute("macrotext1", format("/stopmacro [combat]\n/use %s", itemName))
                self.buttons.rune.click:Show()
                self.buttons.rune.click.IsON = true
            else
                self.buttons.rune.click:Hide()
                self.buttons.rune.click.IsON = false
            end
        end
    else
        self.buttons.rune.count:SetText("0")

        if not InCombatLockdown() then
            self.buttons.rune.click:Hide()
            self.buttons.rune.click.IsON = false
        end
    end

    if LCG then
        if ((rune_item_count and rune_item_count > 0) or (unlimited_rune_item_count and unlimited_rune_item_count > 0)) and not isRune then
            LCG.PixelGlow_Start(self.buttons.rune)
        else
            LCG.PixelGlow_Stop(self.buttons.rune)
        end
    end
    --- End Rune Handling


    -- Check if player is an enhancement shaman
    local isClassShamanEnh

    if select(2, UnitClass("player")) == "SHAMAN" and GetSpecialization() == 2 then
        isClassShamanEnh = true
    end

    if isClassShamanEnh then
        if isShamanBuff then
            self.buttons.class.texture:SetDesaturated(false)
            self.buttons.class.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
            self.buttons.class.timeleft:SetText(isShamanBuff)
        else
            self.buttons.class.texture:SetDesaturated(true)
        end

        if not InCombatLockdown() then
            local spellInfo = GetSpellInfo(192106).name
            local spellName = spellInfo and spellInfo.name
            self.buttons.class.click:SetAttribute("type", "spell")
            self.buttons.class.click:SetAttribute("spell", spellName)
            self.buttons.class.click:Show()
            self.buttons.class.click.IsON = true
        end
    end

    if not InCombatLockdown() then
        if isClassShamanEnh then
            self.buttons.class.texture:SetTexture(RCC.db.class_icon_id)
            self.buttons.class:Show()
            totalButtons = totalButtons + 1
            self.buttons.class:ClearAllPoints()

            if isWarlockInRaid then
                self.buttons.class:SetPoint("LEFT",self.buttons.hs,"RIGHT",0,0)
            else
                self.buttons.class:SetPoint("LEFT",self.buttons.rune,"RIGHT",0,0)
            end
        else
            self.buttons.class:Hide()
            self.buttons.class.click:Hide()
            self.buttons.class.click.IsON = false
        end
    end

    -- Finalize width of the frame
    if not InCombatLockdown() then
        self:SetWidth(consumables_size * totalButtons)
    end
end -- END Update() Function

function RCC.consumables:Repos(isRL)
    if InCombatLockdown() then
        return
    end

    if isRL then
        self:SetParent(self.rlpointer)
        self:ClearAllPoints()
        self:SetPoint("CENTER",self.rlpointer,"CENTER",0,0)

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
        self:SetPoint("BOTTOM",parent,"TOP",0,5)

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

RCC.consumables:SetScript("OnEvent", function(self, event, unit, time_to_hide)
    if event == "READY_CHECK" then
        self:Update()

        self:RegisterEvent("UNIT_AURA")
        self:RegisterEvent("UNIT_INVENTORY_CHANGED")


        if self.cancelDelay then
            self.cancelDelay:Cancel()
        end

        self.cancelDelay = C_Timer.NewTimer(time_to_hide or 12, function()
            self:UnregisterEvent("UNIT_AURA")
            self:UnregisterEvent("UNIT_INVENTORY_CHANGED")

            if self.isRLpos then
                self.rlpointer:Hide()
            end
        end)

        if unit and UnitIsUnit(unit, "player") then
            self:Repos(true)
        else
            self:Repos()
        end
    elseif event == "READY_CHECK_FINISHED" or event == "PLAYER_REGEN_DISABLED" then
        RCC.consumables:OnHide()

        if self.isRLpos and not InCombatLockdown() then
            self.rlpointer:Hide()
        end
    elseif event == "UNIT_AURA" then
        if unit == "player" then
            self:Update()
        end
    elseif event == "UNIT_INVENTORY_CHANGED" then
        if unit == "player" then
            C_Timer.After(.2, function()
                self:Update()
            end)
        end
    end
end)

RCC.consumables:SetScript("OnHide", function(self)
    RCC.consumables:OnHide()

    if not InCombatLockdown() and self.close:IsShown() then
        self.close:Hide()
    end
end)

RCC.consumables:RegisterEvent("READY_CHECK")
RCC.consumables:RegisterEvent("READY_CHECK_FINISHED")
RCC.consumables:RegisterEvent("PLAYER_REGEN_DISABLED")
RCC.consumables:Show()

-------------------------------------------------------------------------------
--- Slash Commands
-------------------------------------------------------------------------------

SLASH_RCC1 = "/rcc"
SlashCmdList["RCC"] = function(msg)
    msg = strlower(strtrim(msg))

    if msg == "show" then
        local name = UnitName("player")
        RCC.consumables:GetScript("OnEvent")(
            RCC.consumables, "READY_CHECK", name
        )
    elseif msg == "hide" then
        RCC.consumables:GetScript("OnEvent")(
            RCC.consumables, "READY_CHECK_FINISHED", ""
        )
    elseif msg == "report" then
        RCC.chatReport.Test(false)
    elseif msg == "reportchat" then
        RCC.chatReport.Test(true)
    else
        print("|cff00ccffReadyCheckConsumables|r commands:")
        print("  /rcc show - Show the consumable icon frame")
        print("  /rcc hide - Hide the consumable icon frame")
        print("  /rcc report - Print consumable report locally")
        print("  /rcc reportchat - Send consumable report to chat")
    end
end
