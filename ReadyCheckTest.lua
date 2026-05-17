local _, RCC = ...

RCC.ReadyCheckTest = RCC.ReadyCheckTest or {}
local Test = RCC.ReadyCheckTest

local TEST_DURATION = 15

local function cancelFinishTimer(self)
    if self.finishTimer then
        self.finishTimer:Cancel()
        self.finishTimer = nil
    end
end

local function finish(self, runID)
    if self.runID ~= runID or not self.active then
        return
    end

    self.active = false
    cancelFinishTimer(self)

    if RCC.RaidFrameTest then
        RCC.RaidFrameTest:Finish()
    end

    if RCC.ConsumableFrameController then
        RCC.ConsumableFrameController.FinishReadyCheck()
    end
end

function Test:Cancel()
    self.runID = (self.runID or 0) + 1
    self.active = false
    cancelFinishTimer(self)

    if RCC.RaidFrameTest then
        RCC.RaidFrameTest:Cancel()
    end
end

function Test:Stop()
    local wasActive = self.active

    self:Cancel()

    if wasActive then
        if RCC.ConsumableFrameController then
            RCC.ConsumableFrameController.FinishReadyCheck()
        end

        if RCC.RaidFrameTest then
            RCC.RaidFrameTest:Stop()
        end
    end

    return wasActive
end

function Test:Start(permanent)
    if InCombatLockdown() then
        return false
    end

    self:Cancel()
    self.active = true

    local runID = self.runID

    if RCC.ConsumableFrameController then
        RCC.ConsumableFrameController.StartReadyCheck("player")
    end

    if RCC.RaidFrameTest then
        RCC.RaidFrameTest:Start(permanent or false, TEST_DURATION)
    end

    if not permanent then
        self.finishTimer = C_Timer.NewTimer(TEST_DURATION, function()
            finish(self, runID)
        end)
    end

    return true
end
