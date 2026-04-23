local ADDON_NAME, RCC = ...

RCC.color = "cff00cc"

RCC.db = RCC.db or {}

-------------------------------------------------------------------------------
--- Event handler
-------------------------------------------------------------------------------

local consumablesShowStart = 0

RCC.consumables:SetScript("OnEvent", function(self, event, unit, time_to_hide)
    if event == "READY_CHECK" then
        if InCombatLockdown() then
            return
        end

        if not RCC.GetSetting("consumables_enabled") then
            self:Hide()

            return
        end

        consumablesShowStart = GetTime()

        self:SetScale(RCC.GetSetting("consumables_scale"))
        self:Show()
        self:Update()
        self:RegisterEvent("UNIT_AURA")
        self:RegisterEvent("UNIT_INVENTORY_CHANGED")

        if self.cancelDelay then
            self.cancelDelay:Cancel()
            self.cancelDelay = nil
        end

        if unit and UnitIsUnit(unit, "player") then
            self:Repos(true)
        else
            self:Repos()
        end

    elseif event == "READY_CHECK_FINISHED" then
        if self.cancelDelay then
            self.cancelDelay:Cancel()
            self.cancelDelay = nil
        end

        if InCombatLockdown() then
            self:Hide()
            self.rlpointer:Hide()

            return
        end

        if not RCC.GetSetting("consumables_minShow") then
            self:Hide()
            self.rlpointer:Hide()

            return
        end

        self.close:Show()

        local minShowTime = RCC.GetSetting("consumables_minShowTime")
        local elapsed = GetTime() - consumablesShowStart
        local delay = max(minShowTime - elapsed, 0)

        self.cancelDelay = C_Timer.NewTimer(delay, function()
            if not InCombatLockdown() then
                RCC.consumables:Hide()
                RCC.consumables.rlpointer:Hide()
            end
        end)

    elseif event == "PLAYER_REGEN_DISABLED" then
        self:Hide()
        self.rlpointer:Hide()

    elseif event == "UNIT_AURA" then
        if unit == "player" then
            self:Update()
        end

    elseif event == "UNIT_INVENTORY_CHANGED" then
        if unit == "player" then
            C_Timer.After(0.2, function() self:Update() end)
        end
    end
end)

RCC.consumables:SetScript("OnHide", function(self)
    RCC.consumables:OnHide()

    if not InCombatLockdown()
        and self.close:IsShown()
    then
        self.close:Hide()
    end
end)

RCC.consumables:RegisterEvent("READY_CHECK")
RCC.consumables:RegisterEvent("READY_CHECK_FINISHED")
RCC.consumables:RegisterEvent("PLAYER_REGEN_DISABLED")

-------------------------------------------------------------------------------
--- Slash Commands
-------------------------------------------------------------------------------

SLASH_RCC1 = "/rcc"
SlashCmdList["RCC"] = function(msg)
    msg = strlower(strtrim(msg))

    if msg == "test" or msg == "t" then
        local name = UnitName("player")
        RCC.consumables:GetScript("OnEvent")(RCC.consumables,
                                             "READY_CHECK",
                                             name, 0)
        RCC.raidFrame:OnTestReadyCheck()

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
        print("  /rcc test, t - Show a test consumable icon frame")
        print("  /rcc hide, h - Immediately hide the consumable icon frame")
        print("  /rcc report, r - Print consumable report locally")
        print("  /rcc reportchat, rc - Send consumable report to chat")
        print("  /rcc settings, s, options, o - Open settings panel")
    end
end
