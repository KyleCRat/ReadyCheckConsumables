local _, RCC = ...

RCC.RaidFrameReadyCheck = RCC.RaidFrameReadyCheck or {}
local ReadyCheck = RCC.RaidFrameReadyCheck
local StatusIcons = RCC.UI.StatusIcons

-- Response-to-icon mapping belongs to the frame; meanings belong to the model.
local Status = RCC.ReadyCheckState.Status

ReadyCheck.ICONS = {
    [Status.PENDING]   = { texture = "Interface\\RaidFrame\\ReadyCheck-Waiting" },
    [Status.READY]     = StatusIcons.READY,
    [Status.NOT_READY] = StatusIcons.NOT_READY,
}

ReadyCheck.TITLE_ICONS = {
    ready    = StatusIcons.READY,
    notReady = StatusIcons.NOT_READY,
}
