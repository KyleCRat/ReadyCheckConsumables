local _, RCC = ...

RCC.RaidFrameBroadcast = RCC.RaidFrameBroadcast or {}
local Broadcast = RCC.RaidFrameBroadcast

local F  = RCC.F
local db = RCC.db

local floor              = floor
local strsplit           = strsplit
local GetItemInfoInstant = C_Item.GetItemInfoInstant

local ADDON_PREFIX = "RCC"
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

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

local function getPlayerOilStatus()
    local mainHandItemID = GetInventoryItemID("player", 16)

    if not mainHandItemID then
        return -1, 0
    end

    local hasMainHandEnchant, mainHandExpiration, _,
          mainHandEnchantID, hasOffHandEnchant, offHandExpiration,
          _, offHandEnchantID = GetWeaponEnchantInfo()

    if not hasMainHandEnchant then
        return 0, 0
    end

    local lowestTime = (mainHandExpiration or 0) / 1000
    local enchData = db.weaponEnchants[mainHandEnchantID or 0]
    local itemID = enchData and enchData.item or 0

    local offhandItemID = GetInventoryItemID("player", 17)

    if offhandItemID then
        local itemClassID = select(6, GetItemInfoInstant(offhandItemID))

        if itemClassID == 2 then
            if not hasOffHandEnchant then
                return 0, 0
            end

            local ohTime = (offHandExpiration or 0) / 1000

            if ohTime < lowestTime then
                lowestTime = ohTime
                local ohData = db.weaponEnchants[offHandEnchantID or 0]
                itemID = ohData and ohData.item or 0
            end
        end
    end

    return floor(lowestTime), itemID
end

function Broadcast.Create()
    local broadcast = {
        durabilityData = {},
        oilData        = {},
    }

    function broadcast:Reset()
        wipe(self.durabilityData)
        wipe(self.oilData)
    end

    function broadcast:GetDurabilityData()
        return self.durabilityData
    end

    function broadcast:GetOilData()
        return self.oilData
    end

    function broadcast:SetDurability(playerKey, pct)
        if playerKey and pct ~= nil then
            self.durabilityData[playerKey] = pct
        end
    end

    function broadcast:SetOilStatus(playerKey, oil)
        if playerKey and oil then
            self.oilData[playerKey] = oil
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

    function broadcast:SendOilStatus()
        local oilTime, itemID = getPlayerOilStatus()
        local playerKey = F.unitFullName("player")

        self:SetOilStatus(playerKey, { time = oilTime, item = itemID })

        local chatType = F.chatType()

        if chatType ~= "SAY" then
            C_ChatInfo.SendAddonMessage(
                ADDON_PREFIX,
                "OIL\t" .. oilTime .. "\t" .. (itemID or 0),
                chatType
            )
        end
    end

    function broadcast:HandleAddonMessage(prefix, message, sender)
        if prefix == ADDON_PREFIX then
            local msgType, val1, val2 = strsplit("\t", message)

            if msgType == "DUR" then
                local pct = tonumber(val1)
                local senderKey = F.fullName(sender)

                if pct and senderKey then
                    self.durabilityData[senderKey] = pct

                    return true
                end
            elseif msgType == "OIL" then
                local oilTime = tonumber(val1)
                local itemID = tonumber(val2) or 0
                local senderKey = F.fullName(sender)

                if oilTime and senderKey then
                    self.oilData[senderKey] = {
                        time = oilTime,
                        item = itemID,
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
