local _, RCC = ...

local TIMED_TEST     = false
local PERMANENT_TEST = true

SLASH_RCC1 = "/rcc"
SlashCmdList["RCC"] = function(msg)
    msg = strlower(strtrim(msg))

    if msg == "test" or msg == "t" then
        RCC.ReadyCheckTest:Start(TIMED_TEST)

    elseif msg == "testp" or msg == "tp" then
        RCC.ReadyCheckTest:Start(PERMANENT_TEST)

    elseif msg == "hide" or msg == "h" then
        RCC.ReadyCheckTest:Cancel()

        if RCC.consumables then
            RCC.consumables:HideImmediately()
        end

        if RCC.raidFrame then
            RCC.raidFrame:Hide()
        end

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
        print("  /rcc hide, h - Immediately hide the frames")
        print("  /rcc report, r - Print consumable report locally")
        print("  /rcc reportchat, rc - Send consumable report to chat")
        print("  /rcc settings, s, options, o - Open settings panel")
    end
end
