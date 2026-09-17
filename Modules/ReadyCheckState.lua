local _, RCC = ...

RCC.ReadyCheckState = {}
local State = RCC.ReadyCheckState

State.Status = {
    PENDING   = 0,
    READY     = 1,
    NOT_READY = 2,
}
local Status = State.Status

--------------------------------------------------------------------------------
--- Ready-button response contract
--- The live controller is the only writer of a real ready-check session. UI and
--- chat consumers read the same members, responses, and summary. These responses
--- are independent of consumable/aura readiness, RCC presence, and frame visibility.
--- Only the active roster participates; bench responses do not affect its counts.
--- Every active member must be READY for allReady, including offline members.
--- Pending/unreadable responses are not ready. An empty roster is never all-ready.
--- A finished session retains its last observed result; expired native responses
--- must not overwrite it. Consumers may retain it for presentation after closure.
--- Synthetic previews use separate instances of this model, never the live owner.
--------------------------------------------------------------------------------

local function updateSummary(session)
    local readyCount = 0
    local notReadyCount = 0

    for i = 1, #session.members do
        local response = session.responses[session.members[i].key]

        if response == Status.READY then
            readyCount = readyCount + 1
        elseif response == Status.NOT_READY then
            notReadyCount = notReadyCount + 1
        end
    end

    local activeCount = #session.members
    local respondedCount = readyCount + notReadyCount

    session.summary = {
        activeCount = activeCount,
        readyCount = readyCount,
        notReadyCount = notReadyCount,
        pendingCount = activeCount - respondedCount,
        respondedCount = respondedCount,
        allResponded = activeCount > 0 and respondedCount == activeCount,
        allReady = activeCount > 0 and readyCount == activeCount,
        hasBench = session.isRaid and session.groupSize > activeCount,
    }
end

function State.UpdateRoster(session, roster)
    if not session.inProgress then
        return
    end

    local responses = {}

    for i = 1, #roster.members do
        local key = roster.members[i].key

        responses[key] = roster.responses[key] or Status.PENDING
    end

    session.members = roster.members
    session.responses = responses
    session.groupSize = roster.groupSize
    session.isRaid = roster.isRaid
    updateSummary(session)
end

function State.Create(options)
    local session = {
        duration = options.duration,
        synthetic = options.synthetic == true,
        inProgress = true,
    }

    State.UpdateRoster(session, options)

    return session
end

function State.GetResponse(session, playerKey)
    return session and session.responses[playerKey] or Status.PENDING
end

function State.SetResponse(session, playerKey, response)
    if not session.inProgress
        or session.responses[playerKey] == nil
        or session.responses[playerKey] == response
    then
        return false
    end

    session.responses[playerKey] = response
    updateSummary(session)

    return true
end

function State.Finish(session)
    session.inProgress = false
end
