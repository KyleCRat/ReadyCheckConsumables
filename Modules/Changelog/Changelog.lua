local _, RCC = ...

RCC.Changelog = {}
local Changelog = RCC.Changelog
local contextRevision = 0

local function getContext()
    local active = RCC.profileManager:GetActiveProfile()
    local id = active.profileID
    local identity = table.concat({ id.kind, id.profile or id.name or "", id.key or "", contextRevision }, ":")

    return identity
end

function Changelog.Sync()
    Changelog.controller:Refresh()
end

local function onProfileReplaced()
    contextRevision = contextRevision + 1
    Changelog.Sync()
end

function Changelog.Initialize()
    local storage = ReadyCheckConsumablesDB.changelog
    assert(storage == nil or type(storage) == "table", "RCC: invalid changelog storage")
    storage = storage or {}
    ReadyCheckConsumablesDB.changelog = storage

    -- Account-wide, outside profiles. Copies, resets and character selection
    -- must not change either notification consent or release acknowledgement.
    local db = LibStub("LibSimpleDB-2.0"):New(storage, { autoShow = true })
    local release = CopyTable(RCC.ReleaseNotes)
    local highlights = RCC.ChangelogHighlights[release.version]
    release.highlights = highlights and highlights() or {}

    Changelog.controller = LibStub("LibChangelog-1.0"):Register("ReadyCheckConsumables", {
        displayName = "Ready Check Consumables",
        release = release,
        context = getContext,
        storage = {
            get = function(key) return db:Get(key) end,
            set = function(key, value) db:Set(key, value) end,
        },
    })
    Changelog.db = db

    db:RegisterCallback(RCC.Profiles.SyncSettingsPages, "autoShow")
    RCC.settingsDB:RegisterTreeCallback(Changelog.Sync)
    RCC.settingsDB:RegisterLifecycleCallback("OnDataChanged", onProfileReplaced)
    RCC.settingsDB:RegisterLifecycleCallback("OnReset", onProfileReplaced)
    RCC.Profiles.RegisterSettingsPage(Changelog)
end

function Changelog.CreateSettingsPage(measurementFrame)
    return Changelog.controller:CreateSettingsPage({ measurementFrame = measurementFrame })
end

function Changelog.AddMainSettings(flow)
    flow:AddSection("Update Notices")
    local checkbox = flow:AddControl("checkbox", {
        label = "Show changelog for Ready Check Consumables on login",
        tooltip = "Show highlights when RCC is updated. You can always read them on the Changelog page.",
        value = Changelog.controller:GetAutoShowEnabled(),
        onChanged = function(checked)
            Changelog.controller:SetAutoShowEnabled(checked)
        end,
    })
    flow:AddControl("button", {
        text = "Show update highlights",
        onClick = function()
            local shown, reason = Changelog.controller:Show()

            if not shown then
                local message = reason == "batch-open"
                    and "Close the current update window before opening RCC's highlights"
                    or "Update highlights are available after combat, loading, and ready checks"
                print("|" .. RCC.color .. "ffReadyCheckConsumables|r: " .. message)
            end
        end,
    }, { marginTop = 6 })

    return function()
        checkbox:SetValue(Changelog.controller:GetAutoShowEnabled())
    end
end
