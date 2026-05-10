local _, RCC = ...

RCC.FrameAnimations = RCC.FrameAnimations or {}
local FrameAnimations = RCC.FrameAnimations

function FrameAnimations.CreateFadeOut(frame, options)
    options = options or {}

    local controller = {
        frame = frame,
        isFadingOut = false,
    }
    local fromAlpha = options.fromAlpha or 1
    local toAlpha = options.toAlpha or 0
    local resetAlpha = options.resetAlpha or 1
    local hideInCombat = options.hideInCombat
    local isCancelling = false

    if hideInCombat == nil then
        hideInCombat = true
    end

    controller.group = frame:CreateAnimationGroup()

    local alpha = controller.group:CreateAnimation("Alpha")
    alpha:SetFromAlpha(fromAlpha)
    alpha:SetToAlpha(toAlpha)
    alpha:SetDuration(options.duration or 0.5)

    controller.group:SetScript("OnFinished", function()
        if isCancelling then
            return
        end

        controller.isFadingOut = false
        frame:Hide()
        frame:SetAlpha(resetAlpha)
    end)

    function controller:Cancel()
        isCancelling = true

        if self.group:IsPlaying() then
            self.group:Stop()
        end

        isCancelling = false
        self.isFadingOut = false
        frame:SetAlpha(resetAlpha)
    end

    function controller:Hide()
        if not frame:IsShown() then
            return
        end

        if hideInCombat and InCombatLockdown() then
            frame:Hide()

            return
        end

        if self.isFadingOut then
            return
        end

        self.isFadingOut = true
        frame:SetAlpha(fromAlpha)
        self.group:Play()
    end

    return controller
end
