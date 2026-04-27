local _, RCC = ...

SLASH_RCC1 = "/rcc"
SlashCmdList["RCC"] = function(msg)
    msg = strlower(strtrim(msg))

    if msg == "test" or msg == "t" then
        local name = UnitName("player")
        RCC.consumables:GetScript("OnEvent")(RCC.consumables,
                                             "READY_CHECK",
                                             name, 0)
        RCC.raidFrame:OnTestReadyCheck()

        C_Timer.After(RCC.raidFrameTest.TEST_DURATION, function()
            RCC.consumables:GetScript("OnEvent")(RCC.consumables,
                                                 "READY_CHECK_FINISHED",
                                                 "")
        end)

    elseif msg == "testp" or msg == "tp" then
        local name = UnitName("player")
        RCC.consumables:GetScript("OnEvent")(RCC.consumables,
                                             "READY_CHECK",
                                             name, 0)
        RCC.raidFrame:OnTestReadyCheck(true)

    elseif msg == "hide" or msg == "h" then
        RCC.consumables:GetScript("OnEvent")(RCC.consumables,
                                             "READY_CHECK_FINISHED",
                                             "")
        RCC.raidFrame:Hide()

    elseif msg == "report" or msg == "r" then
        RCC.chatReport.Test(false)

    elseif msg == "reportchat" or msg == "rc" then
        RCC.chatReport.Test(true)

    elseif msg == "settings" or msg == "s"
        or msg == "options" or msg == "o"
    then
        if RCC.settingsCategory then
            Settings.OpenToCategory(RCC.settingsCategory:GetID())
        end

    else
        print("|" .. RCC.color .. "ff" .. "ReadyCheckConsumables|r commands:")
        print("  /rcc test, t - Show a timed test frame (auto-hides)")
        print("  /rcc testp, tp - Show a permanent test frame")
        print("  /rcc hide, h - Immediately hide the consumable icon frame")
        print("  /rcc report, r - Print consumable report locally")
        print("  /rcc reportchat, rc - Send consumable report to chat")
        print("  /rcc settings, s, options, o - Open settings panel")
    end
end
