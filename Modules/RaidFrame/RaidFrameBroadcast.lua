local _, RCC = ...

RCC.RaidFrameBroadcast = RCC.RaidFrameBroadcast or {}
local Broadcast = RCC.RaidFrameBroadcast

local F  = RCC.F
local db = RCC.db

local floor              = floor
local strsplit           = strsplit
local GetItemInfoInstant = C_Item.GetItemInfoInstant
local GetItemIconByID    = C_Item.GetItemIconByID
local GetSpellInfo       = C_Spell.GetSpellInfo

local ADDON_PREFIX = "RCC"
local FOOD_MESSAGE_TYPE = "FOOD"
local FLASK_MESSAGE_TYPE = "FLASK"
-- Keep the legacy "OIL" message type so older RCC clients can still read the
-- remaining time and item ID from the first two payload fields.
local TEMP_WEAPON_ENCHANT_MESSAGE_TYPE = "OIL"
local MAIN_HAND_INVENTORY_SLOT = 16
local OFF_HAND_INVENTORY_SLOT = 17

Broadcast.TempWeaponEnchantStatus = {
    MISSING   = 0,
    NO_WEAPON = -1,
    UNKNOWN   = -2,
}

local TEMP_WEAPON_ENCHANT_STATUS = Broadcast.TempWeaponEnchantStatus

local sharedData = {
    foodData              = {},
    flaskData             = {},
    durabilityData        = {},
    tempWeaponEnchantData = {},
}

C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

function Broadcast.GetReportData()
    return sharedData
end

local function getPlayerMinDurability()
    local minPct = 100

    for slot = 1, 18 do
        local cur, mx = GetInventoryItemDurability(slot)

        if cur and mx and mx > 0 then
            local pct = cur / mx * 100

            if pct < minPct then
                minPct = pct
            end
        end
    end

    return floor(minPct)
end

local function getTempWeaponEnchantData(enchantID)
    if not F.IsSafeNumber(enchantID) or enchantID <= 0 then
        return 0, 0, 0
    end

    local enchantData = db.weaponEnchants[enchantID]
    local itemID = enchantData and enchantData.item or 0
    local spellID = enchantData and enchantData.spellID or 0
    local iconID = enchantData and enchantData.icon

    if not iconID and itemID > 0 then
        iconID = GetItemIconByID(itemID)
    end

    if not iconID and spellID > 0 then
        local spellInfo = GetSpellInfo(spellID)

        iconID = spellInfo and spellInfo.iconID
    end

    return itemID, iconID or 0, spellID
end

local function getTempWeaponEnchantRemaining(expiration)
    if not F.IsSafeNumber(expiration) or expiration <= 0 then
        return TEMP_WEAPON_ENCHANT_STATUS.UNKNOWN
    end

    return expiration / 1000
end

local function getTimedStatusFields(data)
    local has = data and data.has == true
    local time = 0
    local iconID = 0
    local spellID = 0

    if has and F.IsSafeNumber(data.time) then
        time = floor(data.time)
    end

    if data and F.IsSafeNumber(data.iconID) and data.iconID > 0 then
        iconID = data.iconID
    end

    if data and F.IsSafeNumber(data.spellID) and data.spellID > 0 then
        spellID = data.spellID
    end

    return has and 1 or 0, time, iconID, spellID
end

local function createTimedStatus(hasValue, timeValue, iconValue, spellValue)
    local has = tonumber(hasValue) == 1
    local time = tonumber(timeValue) or 0
    local iconID = tonumber(iconValue) or 0
    local spellID = tonumber(spellValue) or 0

    return {
        has     = has,
        time    = time,
        iconID  = iconID > 0 and iconID or nil,
        spellID = spellID > 0 and spellID or nil,
    }
end

local function createTempWeaponEnchantStatus(time, enchantID)
    if not F.IsSafeNumber(enchantID) or enchantID <= 0 then
        enchantID = 0
    end

    local itemID, iconID, spellID = getTempWeaponEnchantData(enchantID)

    return {
        time      = floor(time),
        itemID    = itemID,
        enchantID = enchantID,
        iconID    = iconID,
        spellID   = spellID,
    }
end

local function getPlayerTempWeaponEnchantStatus()
    local mainHandItemID = GetInventoryItemID("player",
                                              MAIN_HAND_INVENTORY_SLOT)

    if not mainHandItemID then
        return createTempWeaponEnchantStatus(
            TEMP_WEAPON_ENCHANT_STATUS.NO_WEAPON,
            0
        )
    end

    local hasMainHandEnchant, mainHandExpiration, _,
          mainHandEnchantID, hasOffHandEnchant, offHandExpiration,
          _, offHandEnchantID = GetWeaponEnchantInfo()

    if not hasMainHandEnchant then
        return createTempWeaponEnchantStatus(
            TEMP_WEAPON_ENCHANT_STATUS.MISSING,
            0
        )
    end

    local lowestTime = getTempWeaponEnchantRemaining(mainHandExpiration)
    local enchantID = 0

    if F.IsSafeNumber(mainHandEnchantID) and mainHandEnchantID > 0 then
        enchantID = mainHandEnchantID
    end

    local offhandItemID = GetInventoryItemID("player",
                                             OFF_HAND_INVENTORY_SLOT)

    if offhandItemID then
        local itemClassID = select(6, GetItemInfoInstant(offhandItemID))

        if itemClassID == 2 then
            if not hasOffHandEnchant then
                return createTempWeaponEnchantStatus(
                    TEMP_WEAPON_ENCHANT_STATUS.MISSING,
                    0
                )
            end

            local ohTime = getTempWeaponEnchantRemaining(offHandExpiration)

            if ohTime < lowestTime then
                lowestTime = ohTime

                if F.IsSafeNumber(offHandEnchantID)
                    and offHandEnchantID > 0
                then
                    enchantID = offHandEnchantID
                else
                    enchantID = 0
                end
            end
        end
    end

    return createTempWeaponEnchantStatus(lowestTime, enchantID)
end

function Broadcast.Create()
    local broadcast = {
        foodData              = sharedData.foodData,
        flaskData             = sharedData.flaskData,
        durabilityData        = sharedData.durabilityData,
        tempWeaponEnchantData = sharedData.tempWeaponEnchantData,
    }

    function broadcast:Reset()
        wipe(self.foodData)
        wipe(self.flaskData)
        wipe(self.durabilityData)
        wipe(self.tempWeaponEnchantData)
    end

    function broadcast:GetFoodData()
        return self.foodData
    end

    function broadcast:GetFlaskData()
        return self.flaskData
    end

    function broadcast:GetDurabilityData()
        return self.durabilityData
    end

    function broadcast:GetTempWeaponEnchantData()
        return self.tempWeaponEnchantData
    end

    function broadcast:SetDurability(playerKey, pct)
        if playerKey and pct ~= nil then
            self.durabilityData[playerKey] = pct
        end
    end

    function broadcast:SetFoodStatus(playerKey, status)
        if playerKey and status ~= nil then
            self.foodData[playerKey] = status
        end
    end

    function broadcast:SetFlaskStatus(playerKey, status)
        if playerKey and status ~= nil then
            self.flaskData[playerKey] = status
        end
    end

    function broadcast:SetTempWeaponEnchantStatus(playerKey, status)
        if playerKey and status ~= nil then
            self.tempWeaponEnchantData[playerKey] = status
        end
    end

    function broadcast:SendDurability()
        local pct = getPlayerMinDurability()
        local playerKey = F.unitFullName("player")

        self:SetDurability(playerKey, pct)

        local chatType = F.chatType()

        if chatType ~= "SAY" then
            C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "DUR\t" .. pct, chatType)
        end
    end

    function broadcast:SendFoodStatus(status, chatType)
        local playerKey = F.unitFullName("player")
        local wellFedHas, wellFedTime, wellFedIconID, wellFedSpellID =
            getTimedStatusFields(status and status.wellFed)
        local eatingHas, eatingTime, eatingIconID, eatingSpellID =
            getTimedStatusFields(status and status.eating)

        status = {
            wellFed = createTimedStatus(
                wellFedHas,
                wellFedTime,
                wellFedIconID,
                wellFedSpellID
            ),
            eating  = createTimedStatus(
                eatingHas,
                eatingTime,
                eatingIconID,
                eatingSpellID
            ),
        }

        self:SetFoodStatus(playerKey, status)

        chatType = chatType or F.chatType()

        if chatType ~= "SAY" then
            C_ChatInfo.SendAddonMessage(
                ADDON_PREFIX,
                FOOD_MESSAGE_TYPE
                    .. "\t" .. wellFedHas
                    .. "\t" .. wellFedTime
                    .. "\t" .. wellFedIconID
                    .. "\t" .. eatingHas
                    .. "\t" .. eatingTime
                    .. "\t" .. eatingIconID
                    .. "\t" .. wellFedSpellID
                    .. "\t" .. eatingSpellID,
                chatType
            )
        end
    end

    function broadcast:SendFlaskStatus(status, chatType)
        local playerKey = F.unitFullName("player")
        local has, time, iconID, spellID = getTimedStatusFields(status)

        status = createTimedStatus(has, time, iconID, spellID)
        self:SetFlaskStatus(playerKey, status)

        chatType = chatType or F.chatType()

        if chatType ~= "SAY" then
            C_ChatInfo.SendAddonMessage(
                ADDON_PREFIX,
                FLASK_MESSAGE_TYPE
                    .. "\t" .. has
                    .. "\t" .. time
                    .. "\t" .. iconID
                    .. "\t" .. spellID,
                chatType
            )
        end
    end

    function broadcast:SendTimedConsumableStatuses(columnData)
        local chatType = F.chatType()

        self:SendFoodStatus(columnData and columnData.food, chatType)
        self:SendFlaskStatus(columnData and columnData.flask, chatType)
    end

    function broadcast:SendTempWeaponEnchantStatus()
        local status = getPlayerTempWeaponEnchantStatus()
        local playerKey = F.unitFullName("player")

        self:SetTempWeaponEnchantStatus(playerKey, status)

        local chatType = F.chatType()

        if chatType ~= "SAY" then
            C_ChatInfo.SendAddonMessage(
                ADDON_PREFIX,
                TEMP_WEAPON_ENCHANT_MESSAGE_TYPE
                    .. "\t" .. status.time
                    .. "\t" .. (status.itemID or 0)
                    .. "\t" .. (status.enchantID or 0)
                    .. "\t" .. (status.iconID or 0)
                    .. "\t" .. (status.spellID or 0),
                chatType
            )
        end
    end

    function broadcast:HandleAddonMessage(prefix, message, sender)
        if prefix == ADDON_PREFIX then
            local msgType, val1, val2, val3, val4, val5, val6, val7, val8 =
                strsplit("\t", message)

            if msgType == "DUR" then
                local pct = tonumber(val1)
                local senderKey = F.fullName(sender)

                if pct and senderKey then
                    self.durabilityData[senderKey] = pct

                    return true
                end
            elseif msgType == FOOD_MESSAGE_TYPE then
                local senderKey = F.fullName(sender)

                if senderKey then
                    self.foodData[senderKey] = {
                        wellFed = createTimedStatus(val1, val2, val3, val7),
                        eating  = createTimedStatus(val4, val5, val6, val8),
                    }

                    return true
                end
            elseif msgType == FLASK_MESSAGE_TYPE then
                local senderKey = F.fullName(sender)

                if senderKey then
                    self.flaskData[senderKey] =
                        createTimedStatus(val1, val2, val3, val4)

                    return true
                end
            elseif msgType == TEMP_WEAPON_ENCHANT_MESSAGE_TYPE then
                local remaining = tonumber(val1)
                local itemID = tonumber(val2) or 0
                local enchantID = tonumber(val3) or 0
                local iconID = tonumber(val4) or 0
                local spellID = tonumber(val5) or 0
                local senderKey = F.fullName(sender)

                if remaining and senderKey then
                    if enchantID > 0 then
                        local enchItemID, enchIconID, enchSpellID =
                            getTempWeaponEnchantData(enchantID)

                        if itemID == 0 then
                            itemID = enchItemID
                        end

                        if iconID == 0 then
                            iconID = enchIconID
                        end

                        if spellID == 0 then
                            spellID = enchSpellID
                        end
                    end

                    if iconID == 0 and itemID > 0 then
                        iconID = GetItemIconByID(itemID) or 0
                    end

                    if iconID == 0 and spellID > 0 then
                        local spellInfo = GetSpellInfo(spellID)

                        iconID = spellInfo and spellInfo.iconID or 0
                    end

                    self.tempWeaponEnchantData[senderKey] = {
                        time      = remaining,
                        itemID    = itemID,
                        enchantID = enchantID,
                        iconID    = iconID,
                        spellID   = spellID,
                    }

                    return true
                end
            end
        elseif F.IsMrtPrefix(prefix) then
            local module, msgType, _, durStr = F.ParseMrtMessage(message)

            if module == "raidcheck" and msgType == "DUR" and durStr then
                local pct = tonumber(durStr)
                local senderKey = F.fullName(sender)

                if pct and senderKey then
                    self.durabilityData[senderKey] = floor(pct)

                    return true
                end
            end
        end

        return false
    end

    return broadcast
end
