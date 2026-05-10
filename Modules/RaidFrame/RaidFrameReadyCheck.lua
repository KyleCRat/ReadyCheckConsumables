local _, RCC = ...

RCC.RaidFrameReadyCheck = RCC.RaidFrameReadyCheck or {}
local ReadyCheck = RCC.RaidFrameReadyCheck

ReadyCheck.PENDING   = 0
ReadyCheck.READY     = 1
ReadyCheck.NOT_READY = 2

ReadyCheck.TEXTURES = {
    [ReadyCheck.PENDING]   = "Interface\\RaidFrame\\ReadyCheck-Waiting",
    [ReadyCheck.READY]     = "Interface\\RaidFrame\\ReadyCheck-Ready",
    [ReadyCheck.NOT_READY] = "Interface\\RaidFrame\\ReadyCheck-NotReady",
}

ReadyCheck.TITLE_TEXTURES = {
    ready    = ReadyCheck.TEXTURES[ReadyCheck.READY],
    notReady = ReadyCheck.TEXTURES[ReadyCheck.NOT_READY],
}
