local _, RCC = ...

RCC.ConsumableSettingsShared = RCC.ConsumableSettingsShared or {}

local Shared = RCC.ConsumableSettingsShared

function Shared.RegisterPage(page)
    RCC.Profiles.RegisterSettingsPage(page)
end

function Shared.SyncPages()
    RCC.Profiles.SyncSettingsPages()
end

function Shared.RefreshAugmentRuneSelection()
    RCC.ConsumableStateController.Invalidate("preferences", { nextFrame = true })
    RCC.ConsumableMacros.ScheduleUpdate()
end

Shared.PreferUnlimitedAugmentSetting = {
    key = "consumables_preferUnlimitedAugment",
    label = "Prefer Unlimited Augment Runes",
    tooltip = "When choosing automatically, prefer a carried unlimited rune "
        .. "over consumable runes, even from a newer expansion. Your explicit "
        .. "item preference takes priority. Cooldowns do not change the selected rune.",
    onChanged = function()
        Shared.RefreshAugmentRuneSelection()
        Shared.SyncPages()
    end,
}

local function setConsumablesFrameEnabled(enabled)
    RCC.SetSettingValue("consumables_enabled", enabled == true)

    if not enabled and not InCombatLockdown() then
        RCC.ConsumableFrameController.HideImmediately()
    end

    Shared.SyncPages()
end

function Shared.CreateConsumablesFrameEnabledCheckbox(frame, flow, placement)
    local checkbox = flow:AddControl("checkbox", {
        label = "Enabled",
        tooltip = "Enable the temporary Consumables Frame.",
        onChanged = function(checked)
            setConsumablesFrameEnabled(checked)
        end,
    }, placement)

    frame.consumablesFrameEnabledControl = checkbox

    return checkbox
end

function Shared.SyncConsumablesFrameEnabled(frame)
    if not frame.consumablesFrameEnabledControl then return end

    frame.consumablesFrameEnabledControl:SetValue(
        RCC.GetSetting("consumables_enabled") == true
    )
end
