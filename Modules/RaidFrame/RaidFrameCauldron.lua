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

local function createState()
    return {
        counts = {},
        activeKinds = {
            [KIND_FLASK] = false,
            [KIND_POTION] = false,
        },
        activeTargets = {},
        activePickupQuantities = {},
    }
end

local liveState = createState()
local syntheticState = createState()
local syntheticActive = false
local hasAutoOpenedThisSession = {}
local testFlaskItemID
local testPotionItemID

Cauldron.KIND_FLASK = KIND_FLASK
Cauldron.KIND_POTION = KIND_POTION
Cauldron.TRACKED_CAULDRON_TYPES = TRACKED_CAULDRON_TYPES

C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

local function isEnabled()
    return RCC.GetSetting("raidFrameCauldron_enabled") == true
end

local function refreshFrame(allowAutoShow)
    local raidFrame = RCC.raidFrame

    if raidFrame and raidFrame.RefreshCauldronTracking then
        return raidFrame:RefreshCauldronTracking(allowAutoShow == true)
    end

    return false
end

local function getDisplayState()
    return syntheticActive and syntheticState or liveState
end

local function getOrCreateEntry(state, playerKey)
    if not state or not playerKey then return end

    state.counts[playerKey] = state.counts[playerKey] or {
        flask = 0,
        flaskItemID = nil,
        potion = 0,
        potionItemID = nil,
    }

    return state.counts[playerKey]
end

local function resetState(state)
    if not state then return end

    wipe(state.counts)

    for i = 1, #TRACKED_CAULDRON_TYPES do
        local kind = TRACKED_CAULDRON_TYPES[i]

        state.activeKinds[kind] = false
        state.activeTargets[kind] = nil
        state.activePickupQuantities[kind] = nil
    end
end

local function resetSyntheticState()
    resetState(syntheticState)
    syntheticActive = false
    testFlaskItemID = nil
    testPotionItemID = nil
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

local function getPickupQuantity(state, kind, cauldronData)
    if state and state.activePickupQuantities[kind] then
        return state.activePickupQuantities[kind]
    end

    return cauldronData and cauldronData.pickupQuantity
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

local function parseQuantity(message, kind, cauldronData, state)
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

    return getPickupQuantity(state, kind, cauldronData)
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
    local state = getDisplayState()

    return state.activeTargets[kind] or 0
end

function Cauldron.GetCounts()
    return getDisplayState().counts
end

function Cauldron.GetEntry(playerKey)
    local state = getDisplayState()

    return playerKey and state.counts[playerKey]
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
    local state = getDisplayState()

    return state.activeKinds[kind] == true
end

function Cauldron.HasActiveCauldron()
    local state = getDisplayState()

    for i = 1, #TRACKED_CAULDRON_TYPES do
        if state.activeKinds[TRACKED_CAULDRON_TYPES[i]] then
            return true
        end
    end

    return false
end

function Cauldron.GetActiveKinds()
    local active = {}
    local state = getDisplayState()

    for i = 1, #TRACKED_CAULDRON_TYPES do
        local kind = TRACKED_CAULDRON_TYPES[i]

        if state.activeKinds[kind] then
            active[#active + 1] = kind
        end
    end

    return active
end

function Cauldron.Refresh()
    refreshFrame()
end

local function activateState(state, kind, cauldronData)
    if not state or not isValidKind(kind) then
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

    state.activeTargets[kind] = target
    state.activePickupQuantities[kind] = pickupQuantity

    if state.activeKinds[kind] then
        return true
    end

    state.activeKinds[kind] = true

    return true
end

function Cauldron.Activate(kind, cauldronData)
    if InCombatLockdown() or not isEnabled() then
        return false
    end

    if not activateState(liveState, kind, cauldronData) then
        return false
    end

    if refreshFrame(hasAutoOpenedThisSession[kind] ~= true) then
        hasAutoOpenedThisSession[kind] = true
    end

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
        quantity = tonumber(getPickupQuantity(liveState, kind, cauldronData)) or 0
    end

    if quantity <= 0 then
        return false
    end

    if not Cauldron.Activate(kind, cauldronData) then
        return false
    end

    local entry = getOrCreateEntry(liveState, playerKey)

    if not entry then return false end

    entry[kind] = (entry[kind] or 0) + quantity
    entry[kind .. "ItemID"] = itemID

    refreshFrame()

    return true
end

function Cauldron.Reset()
    resetState(liveState)
    resetSyntheticState()
    wipe(hasAutoOpenedThisSession)
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

    resetSyntheticState()

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

    syntheticState.activeKinds[KIND_FLASK] = true
    syntheticState.activeKinds[KIND_POTION] = true
    syntheticState.activeTargets[KIND_FLASK] = flaskTarget
    syntheticState.activeTargets[KIND_POTION] = potionTarget
    syntheticState.activePickupQuantities[KIND_FLASK] = flaskPickupQuantity
    syntheticState.activePickupQuantities[KIND_POTION] = potionPickupQuantity
    testFlaskItemID = firstPickupItemID(flaskCauldron)
    testPotionItemID = firstPickupItemID(potionCauldron)
    syntheticActive = true

    return true
end

function Cauldron.EndSyntheticTestData(suppressRefresh)
    if not syntheticActive then
        return false
    end

    resetSyntheticState()

    if not suppressRefresh then
        refreshFrame()
    end

    return true
end

function Cauldron.SetSyntheticTestEntry(playerKey, index)
    if not syntheticActive then
        return false
    end

    local entry = getOrCreateEntry(syntheticState, playerKey)

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
            getPickupQuantity(syntheticState, KIND_FLASK)
        entry.potion = Cauldron.GetTarget(KIND_POTION) +
            getPickupQuantity(syntheticState, KIND_POTION)
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
        parseQuantity(text, cauldronData.kind, cauldronData, liveState)
    )

    if playerKey == F.unitFullName("player") then
        local controller = RCC.ConsumableFrameController

        if controller and controller.OpenForCauldronPickup then
            controller.OpenForCauldronPickup()
        end
    end
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
