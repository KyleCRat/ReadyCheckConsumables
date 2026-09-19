local _, RCC = ...

RCC.ProfileMigration = {}

local STORAGE_VERSION = 1
local PREFERENCE_MIGRATION_VERSION = 2
local PROFILE_PAYLOAD_VERSION = 2

local function migrateChoices(payload)
    if payload.consumableItemCache ~= nil and type(payload.consumableItemCache) ~= "table" then
        error("RCC: invalid legacy preferences; existing data was not replaced")
    end

    if payload.consumablePreferences ~= nil then
        if not RCC.ConsumableChoice.ValidateBranches(
            payload.consumablePreferences, { limitToCapacity = true }
        ) then
            error("RCC: invalid consumable preferences; existing data was not replaced")
        end
    else
        local preferences = {}

        for key, itemID in pairs(payload.consumableItemCache or {}) do
            local choice = RCC.ConsumableChoice.Item(itemID)

            if type(key) ~= "string" or not RCC.ConsumableChoice.IsValid(choice) then
                error("RCC: invalid legacy choice; existing data was not replaced")
            end

            preferences[key] = { [1] = { choice } }
        end

        payload.consumablePreferences = preferences
    end

    payload.consumableItemCache = nil
end

-- The library stages every payload, including inactive profiles. This version
-- is independent of RCC's original account/character ownership migration.
function RCC.ProfileMigration.CreateProfileMigration()
    local migration = LibStub("LibSimpleDBProfiles-1.0"):CreateMigration(PROFILE_PAYLOAD_VERSION)
    migration:Add(1, migrateChoices)

    return migration
end

local function prepareLegacyPreferences(storage)
    if storage.legacyConsumablePreferences ~= nil then
        if type(storage.legacyConsumablePreferences) ~= "table" then
            error("RCC: invalid legacy preferences; existing data was not replaced")
        end

        return
    end

    local global = storage.profiles.global

    if global ~= nil and type(global) ~= "table" then
        error("RCC: invalid Global profile; existing data was not replaced")
    end

    local preferences = global and global.consumableItemCache

    if preferences ~= nil and type(preferences) ~= "table" then
        error("RCC: invalid legacy preferences; existing data was not replaced")
    end

    -- Later-login characters inherit the original shared choices, not whatever
    -- Global contains by then. Keep this detached from every writable profile.
    storage.legacyConsumablePreferences = CopyTable(preferences or {})
end

function RCC.ProfileMigration.Prepare(saved)
    if saved ~= nil and type(saved) ~= "table" then
        error("RCC: SavedVariables must be a table; existing data was not replaced")
    end

    local storage

    if saved and saved.profileStorageVersion ~= nil then
        if saved.profileStorageVersion ~= STORAGE_VERSION
            or type(saved.profiles) ~= "table"
        then
            error("RCC: unsupported profile storage; existing data was not replaced")
        end

        storage = saved
    else
        -- Adopt the entire legacy payload, including false values, sparse
        -- visibility overrides, preferences, and movement-provider positions.
        storage = {
            profileStorageVersion = STORAGE_VERSION,
            profiles = {
                global = saved or {},
            },
        }
    end

    prepareLegacyPreferences(storage)

    return storage
end

local function seedCharacterPreferences(storage, legacyPreferences)
    if storage.consumableItemCache == nil and storage.consumablePreferences == nil then
        storage.consumableItemCache = CopyTable(legacyPreferences)
    end
end

local function migrateCharacterChoices(storage)
    -- Retire the separate marker used by the earlier development build. Its
    -- already-converted choices stay intact within this sequential step.
    if storage.consumableChoiceFormatVersion ~= nil and storage.consumableChoiceFormatVersion ~= 1 then
        error("RCC: unsupported choice format; existing data was not replaced")
    end

    migrateChoices(storage)
    storage.consumableChoiceFormatVersion = nil
end

-- Keys are source versions. Each step advances the same character marker:
-- 0 -> 1 seeds ownership once; 1 -> 2 converts the saved choice format.
-- Keep completed steps so later-login characters can run the whole chain.
local CHARACTER_MIGRATIONS = {
    [0] = seedCharacterPreferences,
    [1] = migrateCharacterChoices,
}

function RCC.ProfileMigration.PrepareCharacter(saved, legacyPreferences)
    if saved ~= nil and type(saved) ~= "table" then
        error("RCC: character SavedVariables must be a table; existing data was not replaced")
    end

    local storage = saved or {}

    if storage.consumableItemCache ~= nil and type(storage.consumableItemCache) ~= "table" then
        error("RCC: invalid character preferences; existing data was not replaced")
    end

    if storage.useProfileConsumablePreferences ~= nil
        and type(storage.useProfileConsumablePreferences) ~= "boolean"
    then
        error("RCC: invalid character preference storage choice; existing data was not replaced")
    end

    if storage.consumablePreferences ~= nil
        and not RCC.ConsumableChoice.ValidateBranches(
            storage.consumablePreferences, { limitToCapacity = true }
        )
    then
        error("RCC: invalid character preferences; existing data was not replaced")
    end

    if storage.consumableHistory ~= nil
        and not RCC.ConsumableChoice.ValidateBranches(storage.consumableHistory)
    then
        error("RCC: invalid consumable history; existing data was not replaced")
    end

    local version = storage.preferenceMigrationVersion

    if version == nil then
        version = 0
    elseif type(version) ~= "number" or version % 1 ~= 0
        or version < 1 or version > PREFERENCE_MIGRATION_VERSION
    then
        error("RCC: unsupported character preference storage; existing data was not replaced")
    end

    if version == PREFERENCE_MIGRATION_VERSION then return storage end

    -- Publish only the completed copy. A failed step leaves the original
    -- choices, history, storage toggle, and migration marker untouched.
    storage = CopyTable(storage)

    while version < PREFERENCE_MIGRATION_VERSION do
        CHARACTER_MIGRATIONS[version](storage, legacyPreferences)
        version = version + 1
        storage.preferenceMigrationVersion = version
    end

    return storage
end
