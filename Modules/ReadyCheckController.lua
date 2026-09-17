local _, RCC = ...

RCC.ReadyCheckController = {}
local Controller = RCC.ReadyCheckController

local F = RCC.F
local State = RCC.ReadyCheckState
local Status = State.Status
local DEFAULT_DURATION = 30

local eventFrame = CreateFrame("Frame")
local listeners = {}
local currentSession

-- Session lifetime is independent of either consumer's Enabled setting or UI
-- lifetime. Only this controller reads native ready-check responses. Finished
-- results remain current through the report-election window, unless the active
-- roster or gameplay context changes. There is no polling or retry timer.
function Controller.Subscribe(handlers)
    listeners[#listeners + 1] = handlers
end

function Controller.GetCurrent()
    return currentSession
end

local function notify(method, session, change)
    for i = 1, #listeners do
        local handler = listeners[i][method]

        if handler then
            handler(session, change)
        end
    end
end

local function readRoster()
    local roster = {
        members = {},
        groupSize = GetNumGroupMembers(),
        isRaid = IsInRaid(),
    }

    F.ForEachActiveRosterMember(function(name, unit, subgroup, class, online)
        roster.members[#roster.members + 1] = {
            name = name,
            key = name,
            unit = unit,
            subgroup = subgroup,
            class = class,
            online = online,
        }
    end)

    return roster
end

local function readResponses(members)
    local responses = {}

    for i = 1, #members do
        local member = members[i]
        local nativeStatus = GetReadyCheckStatus(member.unit)
        local response = Status.PENDING

        if not issecretvalue(nativeStatus) then
            if nativeStatus == "ready" then
                response = Status.READY
            elseif nativeStatus == "notready" then
                response = Status.NOT_READY
            end
        end

        responses[member.key] = response
    end

    return responses
end

local function cancelSession()
    local cancelled = currentSession
    currentSession = nil

    eventFrame:UnregisterEvent("READY_CHECK_CONFIRM")
    eventFrame:UnregisterEvent("READY_CHECK_FINISHED")
    eventFrame:UnregisterEvent("GROUP_ROSTER_UPDATE")

    if cancelled then
        -- Do not mutate a completed result retained by a fading frame.
        State.Finish(cancelled)
        notify("OnCancelled", cancelled)
    end
end

local function onReadyCheck(initiatorUnit, duration)
    cancelSession()

    if InCombatLockdown() then
        return
    end

    local roster = readRoster()
    roster.responses = readResponses(roster.members)
    roster.duration = F.IsSafeNumber(duration) and duration > 0
        and duration or DEFAULT_DURATION

    -- The initiator does not receive a confirmation event for their own ready
    -- response. Seed it here, alongside the native statuses, for both consumers.
    if not issecretvalue(initiatorUnit) and type(initiatorUnit) == "string" then
        for i = 1, #roster.members do
            local member = roster.members[i]

            if F.UnitIsUnitSafe(member.unit, initiatorUnit) then
                roster.responses[member.key] = Status.READY
                break
            end
        end
    end

    currentSession = State.Create(roster)
    eventFrame:RegisterEvent("READY_CHECK_CONFIRM")
    eventFrame:RegisterEvent("READY_CHECK_FINISHED")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    notify("OnStarted", currentSession)
end

local function onReadyCheckConfirm(unit, isReady)
    if not currentSession or not currentSession.inProgress
        or issecretvalue(unit) or type(unit) ~= "string"
        or issecretvalue(isReady) or type(isReady) ~= "boolean"
    then
        return
    end

    local playerKey = F.unitFullName(unit)
    local response = isReady and Status.READY or Status.NOT_READY

    if playerKey and State.SetResponse(currentSession, playerKey, response) then
        notify("OnUpdated", currentSession, { playerKey = playerKey })
    end
end

local function onReadyCheckFinished(preempted)
    if issecretvalue(preempted) or preempted then
        cancelSession()

        return
    end

    if not currentSession then
        return
    end

    State.Finish(currentSession)
    eventFrame:UnregisterEvent("READY_CHECK_CONFIRM")
    eventFrame:UnregisterEvent("READY_CHECK_FINISHED")
    notify("OnFinished", currentSession)
end

local function sameActiveRoster(session, roster)
    if session.isRaid ~= roster.isRaid
        or session.groupSize ~= roster.groupSize
        or #session.members ~= #roster.members
    then
        return false
    end

    for i = 1, #roster.members do
        local previous = session.members[i]
        local member = roster.members[i]

        if previous.key ~= member.key or previous.unit ~= member.unit then
            return false
        end
    end

    return true
end

local function onGroupRosterUpdate()
    if not currentSession then
        return
    end

    if not IsInGroup() then
        cancelSession()

        return
    end

    local roster = readRoster()

    if not currentSession.inProgress then
        -- Generic roster updates also fire without membership changes. Preserve
        -- early completions, but never send an old result for a different group
        -- or leave the frozen display following reassigned raid unit tokens.
        if not sameActiveRoster(currentSession, roster) then
            cancelSession()
        end

        return
    end

    roster.responses = readResponses(roster.members)
    State.UpdateRoster(currentSession, roster)
    notify("OnUpdated", currentSession, { rosterChanged = true })
end

local EVENT_HANDLERS = {
    READY_CHECK = onReadyCheck,
    READY_CHECK_CONFIRM = onReadyCheckConfirm,
    READY_CHECK_FINISHED = onReadyCheckFinished,
    GROUP_ROSTER_UPDATE = onGroupRosterUpdate,
    GROUP_LEFT = cancelSession,
    PLAYER_REGEN_DISABLED = cancelSession,
    PLAYER_ENTERING_WORLD = cancelSession,
    PLAYER_DIFFICULTY_CHANGED = cancelSession,
}

eventFrame:SetScript("OnEvent", function(_self, event, ...)
    EVENT_HANDLERS[event](...)
end)

eventFrame:RegisterEvent("READY_CHECK")
eventFrame:RegisterEvent("GROUP_LEFT")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
