local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.RaidBuff = RCC.Consumables.RaidBuff or {}

local RaidBuff = RCC.Consumables.RaidBuff

local RaidBuffStatus = RCC.RaidBuffStatus

function RaidBuff.GetPlayerRaidBuffInfo()
    local _, class = UnitClass("player")

    return RaidBuffStatus.GetInfoByProviderClass(class)
end
