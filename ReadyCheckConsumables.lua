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
        self:RegisterEvent("READY_CHECK_CONFIRM")

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
        if not self:IsShown() then
            if self.cancelDelay then
                self.cancelDelay:Cancel()
                self.cancelDelay = nil
            end

            return
        end

        if InCombatLockdown() then
            if self.cancelDelay then
                self.cancelDelay:Cancel()
                self.cancelDelay = nil
            end

            self:Hide()

            return
        end

        if self.cancelDelay then
            return
        end

        if not RCC.GetSetting("consumables_minShow") then
            self:Hide()

            return
        end

        self.drag:Show()
        self.close:Show()

        local minShowTime = RCC.GetSetting("consumables_minShowTime")
        local elapsed = GetTime() - consumablesShowStart
        local delay = max(minShowTime - elapsed, 0)

        self.cancelDelay = C_Timer.NewTimer(delay, function()
            if not InCombatLockdown() then
                RCC.consumables:Hide()
            end
        end)

    elseif event == "PLAYER_REGEN_DISABLED" then
        self:Hide()

    elseif event == "READY_CHECK_CONFIRM" then
        if unit and UnitIsUnit(unit, "player") then
            self:UnregisterEvent("READY_CHECK_CONFIRM")

            if not RCC.GetSetting("consumables_minShow") then
                self:Hide()

                return
            end

            local minShowTime = RCC.GetSetting("consumables_minShowTime")
            local elapsed = GetTime() - consumablesShowStart
            local delay = max(minShowTime - elapsed, 0)

            if delay == 0 then
                self:Hide()

                return
            end

            self.drag:Show()
            self.close:Show()

            self.cancelDelay = C_Timer.NewTimer(delay, function()
                if not InCombatLockdown() then
                    RCC.consumables:Hide()
                end
            end)
        end

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

    if not InCombatLockdown() then
        self.drag:Hide()
        self.close:Hide()
    end
end)

RCC.consumables:RegisterEvent("READY_CHECK")
RCC.consumables:RegisterEvent("READY_CHECK_FINISHED")
RCC.consumables:RegisterEvent("PLAYER_REGEN_DISABLED")
