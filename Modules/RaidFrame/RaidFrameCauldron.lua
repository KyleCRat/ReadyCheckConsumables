local _, RCC = ...

RCC.RaidFrameCauldron = RCC.RaidFrameCauldron or {}

local Cauldron = RCC.RaidFrameCauldron
local F = RCC.F

local ADDON_PREFIX = "RCC"
local MESSAGE_TYPE = "CAULD"

local KIND_FLASK = RCC.CauldronKind.FLASK
local KIND_POTION = RCC.CauldronKind.POTION

local TRACKED_CAULDRON_TYPES = {
    KIND_FLASK,
    KIND_POTION,
}

local counts = {}
local activeKinds = {
    [KIND_FLASK] = false,
    [KIND_POTION] = false,
}
local activeTargets = {}
local activePickupQuantities = {}
local testFlaskItemID
local testPotionItemID

Cauldron.KIND_FLASK = KIND_FLASK
Cauldron.KIND_POTION = KIND_POTION
Cauldron.TRACKED_CAULDRON_TYPES = TRACKED_CAULDRON_TYPES

C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

local function isEnabled()
    return RCC.GetSetting("raidFrameCauldron_enabled") == true
end

local function refreshFrame()
    local raidFrame = RCC.raidFrame

    if raidFrame and raidFrame.RefreshCauldronTracking then
        raidFrame:RefreshCauldronTracking()
    end
end

local function getOrCreateEntry(playerKey)
    if not playerKey then return end

    counts[playerKey] = counts[playerKey] or {
        flask = 0,
        flaskItemID = nil,
        potion = 0,
        potionItemID = nil,
    }

    return counts[playerKey]
end

local function resetState()
    wipe(counts)

    for i = 1, #TRACKED_CAULDRON_TYPES do
        local kind = TRACKED_CAULDRON_TYPES[i]

        activeKinds[kind] = false
        activeTargets[kind] = nil
        activePickupQuantities[kind] = nil
    end
end

local function isValidKind(kind)
    return kind == KIND_FLASK or kind == KIND_POTION
end

local function getCauldronDataForSpell(spellID)
    return spellID
        and RCC.db.cauldronSpellData
        and RCC.db.cauldronSpellData[spellID]
end

local function getCauldronDataForPickupItem(itemID)
    return itemID
        and RCC.db.cauldronPickupItemData
        and RCC.db.cauldronPickupItemData[itemID]
end

local function getPickupQuantity(kind, cauldronData)
    return activePickupQuantities[kind]
        or (cauldronData and cauldronData.pickupQuantity)
end

local function getCauldronDataForKind(kind)
    return kind
        and RCC.db.cauldronKindData
        and RCC.db.cauldronKindData[kind]
end

local function firstPickupItemID(cauldronData)
    local pickupItemIDs = cauldronData and cauldronData.pickupItemIDs

    return pickupItemIDs and pickupItemIDs[1]
end

local function parseItemID(message)
    if not message then return end

    return tonumber(message:match("item:(%d+)"))
end

local function parseQuantity(message, kind, cauldronData)
    local quantity = message
        and (
            message:match("|h|r[xX](%d+)")
            or message:match("%][xX](%d+)")
            or message:match("[xX](%d+)%s*%.?$")
        )

    quantity = tonumber(quantity)

    if quantity and quantity > 0 then
        return quantity
    end

    return getPickupQuantity(kind, cauldronData)
end

local function stripChatColor(text)
    if not text then return end

    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")

    return text
end

local function trim(text)
    return text and text:match("^%s*(.-)%s*$")
end

local function isSelfName(name)
    return name == "You" or (_G.YOU and name == _G.YOU)
end

local function parseCreatorFromMessage(message)
    if not message then return end

    local creator = message:match("^(.+)%s+creates:")
        or message:match("^(.+)%s+create:")

    creator = trim(stripChatColor(creator))

    if not creator or creator == "" then
        return nil
    end

    if isSelfName(creator) then
        return F.unitFullName("player")
    end

    return F.fullName(creator)
end

local function getPlayerKeyFromLootMessage(message, playerName, guid)
    if guid and not issecretvalue(guid) and guid == UnitGUID("player") then
        return F.unitFullName("player")
    end

    local playerKey = parseCreatorFromMessage(message)

    if playerKey then
        return playerKey
    end

    if playerName and not issecretvalue(playerName) and playerName ~= "" then
        if isSelfName(playerName) then
            return F.unitFullName("player")
        end

        return F.fullName(playerName)
    end
end

local function sendCauldronMessage(kind)
    if not isValidKind(kind) then
        return
    end

    if C_ChatInfo.InChatMessagingLockdown
        and C_ChatInfo.InChatMessagingLockdown()
    then
        return
    end

    local chatType = F.chatType()

    if chatType == "SAY" then
        return
    end

    C_ChatInfo.SendAddonMessage(
        ADDON_PREFIX,
        MESSAGE_TYPE .. "\t" .. kind,
        chatType
    )
end

function Cauldron.IsEnabled()
    return isEnabled()
end

function Cauldron.ShouldShowOutsideReadyCheck()
    return RCC.GetSetting("raidFrameCauldron_showOutsideReadyCheck") == true
end

function Cauldron.GetTarget(kind)
    return activeTargets[kind] or 0
end

function Cauldron.GetCounts()
    return counts
end

function Cauldron.GetEntry(playerKey)
    return playerKey and counts[playerKey]
end

function Cauldron.GetCount(playerKey, kind)
    local entry = Cauldron.GetEntry(playerKey)

    if not entry then return 0 end

    return entry[kind] or 0
end

function Cauldron.GetLastItemID(playerKey, kind)
    local entry = Cauldron.GetEntry(playerKey)

    if not entry then return end

    return entry[kind .. "ItemID"]
end

function Cauldron.IsActive(kind)
    return activeKinds[kind] == true
end

function Cauldron.HasActiveCauldron()
    for i = 1, #TRACKED_CAULDRON_TYPES do
        if activeKinds[TRACKED_CAULDRON_TYPES[i]] then
            return true
        end
    end

    return false
end

function Cauldron.GetActiveKinds()
    local active = {}

    for i = 1, #TRACKED_CAULDRON_TYPES do
        local kind = TRACKED_CAULDRON_TYPES[i]

        if activeKinds[kind] then
            active[#active + 1] = kind
        end
    end

    return active
end

function Cauldron.Refresh()
    refreshFrame()
end

function Cauldron.Activate(kind, cauldronData)
    if InCombatLockdown() or not isEnabled() or not isValidKind(kind) then
        return false
    end

    if not cauldronData or not cauldronData.target then
        cauldronData = getCauldronDataForKind(kind) or cauldronData
    end

    local target = cauldronData
        and tonumber(cauldronData.target)
        or nil

    local pickupQuantity = cauldronData
        and tonumber(cauldronData.pickupQuantity)
        or nil

    if not target or target <= 0
        or not pickupQuantity or pickupQuantity <= 0
    then
        return false
    end

    activeTargets[kind] = target
    activePickupQuantities[kind] = pickupQuantity

    if activeKinds[kind] then
        refreshFrame()

        return true
    end

    activeKinds[kind] = true
    refreshFrame()

    return true
end

function Cauldron.RecordPickup(playerKey, cauldronData, itemID, quantity)
    local kind = cauldronData and cauldronData.kind

    if InCombatLockdown()
        or not isEnabled()
        or not isValidKind(kind)
        or not playerKey
    then
        return false
    end

    quantity = tonumber(quantity) or 0

    if quantity <= 0 then
        quantity = tonumber(getPickupQuantity(kind, cauldronData)) or 0
    end

    if quantity <= 0 then
        return false
    end

    if not Cauldron.Activate(kind, cauldronData) then
        return false
    end

    local entry = getOrCreateEntry(playerKey)

    if not entry then return false end

    entry[kind] = (entry[kind] or 0) + quantity
    entry[kind .. "ItemID"] = itemID

    refreshFrame()

    return true
end

function Cauldron.Reset()
    resetState()
    refreshFrame()
end

function Cauldron.Hide()
    local raidFrame = RCC.raidFrame

    if raidFrame and raidFrame.HideCauldronTracking then
        raidFrame:HideCauldronTracking()
    end
end

function Cauldron.BeginSyntheticTestData()
    if InCombatLockdown() then
        return false
    end

    resetState()

    local flaskCauldron = getCauldronDataForKind(KIND_FLASK)
    local potionCauldron = getCauldronDataForKind(KIND_POTION)

    if not flaskCauldron or not potionCauldron then
        return false
    end

    local flaskTarget = tonumber(flaskCauldron.target)
    local potionTarget = tonumber(potionCauldron.target)
    local flaskPickupQuantity = tonumber(flaskCauldron.pickupQuantity)
    local potionPickupQuantity = tonumber(potionCauldron.pickupQuantity)

    if not flaskTarget or flaskTarget <= 0
        or not potionTarget or potionTarget <= 0
        or not flaskPickupQuantity or flaskPickupQuantity <= 0
        or not potionPickupQuantity or potionPickupQuantity <= 0
    then
        return false
    end

    activeKinds[KIND_FLASK] = true
    activeKinds[KIND_POTION] = true
    activeTargets[KIND_FLASK] = flaskTarget
    activeTargets[KIND_POTION] = potionTarget
    activePickupQuantities[KIND_FLASK] = flaskPickupQuantity
    activePickupQuantities[KIND_POTION] = potionPickupQuantity
    testFlaskItemID = firstPickupItemID(flaskCauldron)
    testPotionItemID = firstPickupItemID(potionCauldron)

    return true
end

function Cauldron.SetSyntheticTestEntry(playerKey, index)
    local entry = getOrCreateEntry(playerKey)

    if not entry then
        return false
    end

    local bucket = index % 3

    if bucket == 1 then
        entry.flask = 1
        entry.potion = 15
    elseif bucket == 2 then
        entry.flask = Cauldron.GetTarget(KIND_FLASK)
        entry.potion = Cauldron.GetTarget(KIND_POTION)
    else
        entry.flask = Cauldron.GetTarget(KIND_FLASK) +
            getPickupQuantity(KIND_FLASK)
        entry.potion = Cauldron.GetTarget(KIND_POTION) +
            getPickupQuantity(KIND_POTION)
    end

    entry.flaskItemID = testFlaskItemID
    entry.potionItemID = testPotionItemID

    return true
end

local function onUnitSpellcastSucceeded(_self, unit, _castGUID, spellID)
    if unit ~= "player" or issecretvalue(spellID) then
        return
    end

    local cauldronData = getCauldronDataForSpell(spellID)

    if not cauldronData or not IsInGroup() then
        return
    end

    if Cauldron.Activate(cauldronData.kind, cauldronData) then
        sendCauldronMessage(cauldronData.kind)
    end
end

local function getCauldronDataFromMessage(field1, field2)
    local spellID = tonumber(field1)

    if spellID then
        local cauldronData = getCauldronDataForSpell(spellID)
            or getCauldronDataForKind(field2)

        return cauldronData or { kind = field2 }
    end

    return getCauldronDataForKind(field1) or { kind = field1 }
end

local function onChatMsgAddon(_self, prefix, message)
    if prefix ~= ADDON_PREFIX then
        return
    end

    if issecretvalue(message) then
        return
    end

    local msgType, field1, field2 = strsplit("\t", message)

    if msgType == MESSAGE_TYPE then
        local cauldronData = getCauldronDataFromMessage(field1, field2)

        if cauldronData and cauldronData.kind then
            Cauldron.Activate(cauldronData.kind, cauldronData)
        end
    end
end

local function onChatMsgLoot(_self, text, playerName, _languageName,
                             _channelName, _playerName2, _specialFlags,
                             _zoneChannelID, _channelIndex, _channelBaseName,
                             _languageID, _lineID, guid)
    if issecretvalue(text) then
        return
    end

    local itemID = parseItemID(text)
    local cauldronData = getCauldronDataForPickupItem(itemID)

    if not cauldronData or not cauldronData.kind then
        return
    end

    local playerKey = getPlayerKeyFromLootMessage(text, playerName, guid)

    if not playerKey then
        return
    end

    Cauldron.RecordPickup(
        playerKey,
        cauldronData,
        itemID,
        parseQuantity(text, cauldronData.kind, cauldronData)
    )
end

local function onGroupRosterUpdate()
    if Cauldron.HasActiveCauldron() then
        refreshFrame()
    end
end

local EVENT_HANDLERS = {
    CHAT_MSG_ADDON           = onChatMsgAddon,
    CHAT_MSG_LOOT            = onChatMsgLoot,
    GROUP_ROSTER_UPDATE      = onGroupRosterUpdate,
    PLAYER_REGEN_DISABLED    = Cauldron.Reset,
    UNIT_SPELLCAST_SUCCEEDED = onUnitSpellcastSucceeded,
}

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    local handler = EVENT_HANDLERS[event]

    if handler then
        handler(self, ...)
    end
end)

eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
