local _, RCC = ...

RCC.Profiles = {}

local Profiles = RCC.Profiles
local pages = {}
local runtimeReady = false
local pendingApply = false
local applyScheduled = false
local syncScheduled = false

function Profiles.RegisterSettingsPage(page)
    pages[#pages + 1] = page
end

function Profiles.SyncSettingsPages()
    for _, page in ipairs(pages) do
        page:Sync()
    end
end

local function scheduleSettingsSync()
    if syncScheduled then return end

    syncScheduled = true
    C_Timer.After(0, function()
        syncScheduled = false
        Profiles.SyncSettingsPages()
    end)
end

function Profiles.GetEditBlockReason()
    if InCombatLockdown() then
        return "Profiles cannot be changed in combat"
    end

    if RCC.ConsumableActionBarPosition.IsMoving() then
        return "Close Edit Mode or Unlock Mode before changing profiles"
    end
end

local function applyProfile()
    applyScheduled = false

    if not runtimeReady or not pendingApply then return end
    if Profiles.GetEditBlockReason() then return end

    pendingApply = false

    -- This is a settings refresh, not a new ready check. Each display retains
    -- ownership of its live session, timers, and visibility reasons.
    RCC.ReadyCheckMover.ApplySettings()
    RCC.ConsumableStateController.Invalidate("preferences", { nextFrame = true })
    RCC.ConsumableFrameController.ApplyProfile()
    RCC.ConsumableActionBar.RequestApplySettings()
    RCC.raidFrame:ApplyProfile()
    RCC.ConsumableMacros.ScheduleUpdate()
    Profiles.SyncSettingsPages()
end

function Profiles.ApplyPending()
    applyProfile()
end

local function onProfileDataChanged()
    -- Never apply an old profile's pending coordinate edits to the new one.
    RCC.ConsumableActionBarPosition.DiscardPending()
    RCC.ReadyCheckMover.DiscardPending()
    pendingApply = true

    if runtimeReady and not applyScheduled then
        applyScheduled = true
        C_Timer.After(0, applyProfile)
    end
end

function Profiles.Initialize(defaults, characterDefaults)
    local storage = RCC.ProfileMigration.Prepare(ReadyCheckConsumablesDB)
    local characterStorage = RCC.ProfileMigration.PrepareCharacter(
        ReadyCheckConsumablesCharacterDB,
        storage.legacyConsumablePreferences
    )
    local characterDB = LibStub("LibSimpleDB-2.0"):New(characterStorage, characterDefaults)
    local manager = LibStub("LibSimpleDBProfiles-1.0"):New(
        "ReadyCheckConsumables",
        storage.profiles,
        defaults,
        {
            displayName = "Ready Check Consumables",
            initialProfile = "global",
        }
    )

    -- Publish the new container only after the library accepts the migration.
    ReadyCheckConsumablesDB = storage
    ReadyCheckConsumablesCharacterDB = characterStorage
    RCC.profileManager = manager
    RCC.settingsDB = manager:GetActiveDB()
    RCC.characterDB = characterDB

    RCC.settingsDB:RegisterLifecycleCallback("OnDataChanged", onProfileDataChanged)
    RCC.settingsDB:RegisterLifecycleCallback("OnReset", onProfileDataChanged)

    -- Identity notification precedes an automatic spec-profile switch. Wait
    -- until the library has finished rebinding before reading UI descriptors.
    manager:RegisterLifecycleCallback("OnProfileChanged", scheduleSettingsSync)
    manager:RegisterLifecycleCallback("OnProfileCreated", scheduleSettingsSync)
    manager:RegisterLifecycleCallback("OnProfileCopied", scheduleSettingsSync)
    manager:RegisterLifecycleCallback("OnProfileRenamed", scheduleSettingsSync)
    manager:RegisterLifecycleCallback("OnProfileDeleted", scheduleSettingsSync)
    manager:RegisterLifecycleCallback("OnProfileReset", scheduleSettingsSync)
    manager:RegisterLifecycleCallback("OnCharacterInfoChanged", scheduleSettingsSync)
end

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        runtimeReady = true
        pendingApply = true
    end

    applyProfile()
    Profiles.SyncSettingsPages()
end)
