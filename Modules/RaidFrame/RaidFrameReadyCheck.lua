local _, RCC = ...

RCC.RaidFrameReadyCheck = RCC.RaidFrameReadyCheck or {}
local ReadyCheck = RCC.RaidFrameReadyCheck

-- Art belongs to the frame; response meanings belong to the shared model.
local Status = RCC.ReadyCheckState.Status

ReadyCheck.TEXTURES = {
    [Status.PENDING]   = "Interface\\RaidFrame\\ReadyCheck-Waiting",
    [Status.READY]     = "Interface\\RaidFrame\\ReadyCheck-Ready",
    [Status.NOT_READY] = "Interface\\RaidFrame\\ReadyCheck-NotReady",
}

ReadyCheck.TITLE_TEXTURES = {
    ready    = ReadyCheck.TEXTURES[Status.READY],
    notReady = ReadyCheck.TEXTURES[Status.NOT_READY],
}
