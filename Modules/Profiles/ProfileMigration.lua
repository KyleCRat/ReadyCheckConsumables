local _, RCC = ...

RCC.ProfileMigration = {}

local STORAGE_VERSION = 1
local PREFERENCE_MIGRATION_VERSION = 1

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

    if storage.preferenceMigrationVersion ~= nil then
        if storage.preferenceMigrationVersion ~= PREFERENCE_MIGRATION_VERSION then
            error("RCC: unsupported character preference storage; existing data was not replaced")
        end

        return storage
    end

    storage = CopyTable(storage)

    if storage.consumableItemCache == nil then
        storage.consumableItemCache = CopyTable(legacyPreferences)
    end

    -- Clearing a migrated preference must not restore it on the next login.
    storage.preferenceMigrationVersion = PREFERENCE_MIGRATION_VERSION

    return storage
end
