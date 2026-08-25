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

function Shared.CreateActionBarOnlyCheckbox(frame, flow, placement)
    local checkbox = flow:AddControl("checkbox", {
        label = "Action Bar Only",
        tooltip = "Disable the temporary Consumables Frame and use only "
            .. "the permanent Consumables Action Bar. This does not affect "
            .. "the Raid Frame, Chat Report, or managed macros.",
        onChanged = function(checked)
            setConsumablesFrameEnabled(checked ~= true)
        end,
    }, placement)

    frame.actionBarOnlyControl = checkbox

    return checkbox
end

function Shared.SyncActionBarOnly(frame)
    if not frame.actionBarOnlyControl then return end

    frame.actionBarOnlyControl:SetValue(
        RCC.GetSetting("consumables_enabled") ~= true
    )
end
