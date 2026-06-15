local _, RCC = ...

local TIMED_TEST     = false
local PERMANENT_TEST = true
local COMBINED_TEST = { includeCauldrons = true }
local READY_CHECK_ONLY_TEST = { includeCauldrons = false }

SLASH_RCC1 = "/rcc"
SlashCmdList["RCC"] = function(msg)
    msg = strlower(strtrim(msg))

    if msg == "test" or msg == "t" then
        RCC.ReadyCheckTest:Start(TIMED_TEST, COMBINED_TEST)

    elseif msg == "testp" or msg == "tp" then
        RCC.ReadyCheckTest:Start(PERMANENT_TEST, COMBINED_TEST)

    elseif msg == "readycheck test" or msg == "readycheck t"
        or msg == "ready check test" or msg == "ready check t"
        or msg == "rc test" or msg == "rc t"
    then
        RCC.ReadyCheckTest:Start(TIMED_TEST, READY_CHECK_ONLY_TEST)

    elseif msg == "readycheck testp" or msg == "ready check testp"
        or msg == "rc testp"
    then
        RCC.ReadyCheckTest:Start(PERMANENT_TEST, READY_CHECK_ONLY_TEST)

    elseif msg == "hide" or msg == "h" then
        RCC.ReadyCheckTest:Cancel()

        if RCC.ConsumableFrameController then
            RCC.ConsumableFrameController.HideImmediately()
        end

        if RCC.raidFrame then
            RCC.raidFrame:Hide()
        end

        if RCC.RaidFrameCauldron then
            RCC.RaidFrameCauldron.Hide()
        end

    elseif msg == "report" or msg == "r" then
        RCC.chatReport.Test(false)

    elseif msg == "reportchat" or msg == "rc" then
        RCC.chatReport.Test(true)

    elseif msg == "cauldron test" or msg == "cauldron t"
        or msg == "cauldrons test" or msg == "cauldrons t"
        or msg == "ct test" or msg == "ct t"
    then
        if RCC.RaidFrameTest then
            RCC.RaidFrameTest:StartCauldronOnly()
        end

    elseif msg == "settings" or msg == "s"
        or msg == "options" or msg == "o"
    then
        if RCC.settingsCategory then
            Settings.OpenToCategory(RCC.settingsCategory:GetID())
        end

    else
        print("|" .. RCC.color .. "ff" .. "ReadyCheckConsumables|r commands:")
        print("  /rcc test, t - Show a timed combined test frame (auto-hides)")
        print("  /rcc testp, tp - Show a permanent combined test frame")
        print("  /rcc readycheck test, readycheck t - Show ready-check-only test frame")
        print("  /rcc hide, h - Immediately hide the frames")
        print("  /rcc report, r - Print consumable report locally")
        print("  /rcc reportchat, rc - Send consumable report to chat")
        print("  /rcc cauldron test, cauldron t - Show cauldron-only test frame")
        print("  /rcc settings, s, options, o - Open settings panel")
    end
end
