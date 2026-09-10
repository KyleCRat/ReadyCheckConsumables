local _, RCC = ...

RCC.ConsumableSettingsShared = RCC.ConsumableSettingsShared or {}

local Shared = RCC.ConsumableSettingsShared

local pages = {}

function Shared.RegisterPage(page)
    pages[#pages + 1] = page
end

function Shared.SyncPages()
    for i = 1, #pages do
        local page = pages[i]

        if page.Sync then
            page:Sync()
        end
    end
end

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
