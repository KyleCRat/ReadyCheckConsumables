local _, RCC = ...

RCC.RaidFrameFeast = RCC.RaidFrameFeast or {}

local Feast = RCC.RaidFrameFeast
local F = RCC.F

local ADDON_PREFIX = "RCC"
local MESSAGE_TYPE = "FEAST"
local SOURCE_KEY = "feast"

local active = false

C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

local function isEnabled()
    local cauldron = RCC.RaidFrameCauldron

    return cauldron and cauldron.IsEnabled()
end

local function refreshFrame(allowAutoShow)
    return RCC.raidFrame:RefreshProvisionTracking(allowAutoShow == true)
end

local function activateFrameReason()
    return RCC.raidFrame:ActivateDisplayReason(
        RCC.DisplayReason.FEAST_DROP,
        SOURCE_KEY,
        Feast.ShouldShowOutsideReadyCheck()
    )
end

local function sendFeastMessage()
    if C_ChatInfo.InChatMessagingLockdown
        and C_ChatInfo.InChatMessagingLockdown()
    then
        return
    end

    local chatType = F.chatType()

    if chatType == "SAY" then
        return
    end

    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, MESSAGE_TYPE, chatType)
end

function Feast.IsEnabled()
    return isEnabled()
end

function Feast.ShouldShowOutsideReadyCheck()
    local cauldron = RCC.RaidFrameCauldron

    return cauldron and cauldron.ShouldShowOutsideReadyCheck()
end

function Feast.IsActive()
    return active
end

function Feast.Activate()
    if InCombatLockdown() or not isEnabled() then
        return false
    end

    active = true
    activateFrameReason()

    return true
end

function Feast.Refresh()
    refreshFrame()
end

function Feast.Reset()
    active = false
    RCC.raidFrame:ResetDisplayReason(RCC.DisplayReason.FEAST_DROP)
end

local function onUnitSpellcastSucceeded(_self, unit, _castGUID, spellID)
    if issecretvalue(unit) or unit ~= "player"
        or issecretvalue(spellID)
        or not RCC.db.feastPlacementSpellIDs[spellID]
        or not IsInGroup()
    then
        return
    end

    if Feast.Activate() then
        sendFeastMessage()
    end
end

local function onChatMsgAddon(_self, prefix, message)
    if prefix ~= ADDON_PREFIX
        or issecretvalue(message)
        or message ~= MESSAGE_TYPE
    then
        return
    end

    Feast.Activate()
end

local function onGroupRosterUpdate()
    if active then
        refreshFrame()
    end
end

local EVENT_HANDLERS = {
    CHAT_MSG_ADDON           = onChatMsgAddon,
    GROUP_ROSTER_UPDATE      = onGroupRosterUpdate,
    PLAYER_REGEN_DISABLED    = Feast.Reset,
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
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
