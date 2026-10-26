local _, RCC = ...

RCC.ProfileMigration = {}

-- ---------------------------------------------------------------------------
-- Shared conversion helpers
-- ---------------------------------------------------------------------------
-- Both profile and character migrations use the same preference conversion.

local function migrateChoices(payload)
    if
        payload.consumableItemCache ~= nil
        and type(payload.consumableItemCache) ~= "table"
    then
        error("RCC: invalid legacy preferences; existing data was not replaced")
    end

    if payload.consumablePreferences ~= nil then
        if
            not RCC.ConsumableChoice.ValidateBranches(
                payload.consumablePreferences,
                { limitToCapacity = true }
            )
        then
            error(
                "RCC: invalid consumable preferences; existing data was not replaced"
            )
        end
    else
        local preferences = {}

        for key, itemID in pairs(payload.consumableItemCache or {}) do
            local choice = RCC.ConsumableChoice.Item(itemID)

            if
                type(key) ~= "string"
                or not RCC.ConsumableChoice.IsValid(choice)
            then
                error(
                    "RCC: invalid legacy choice; existing data was not replaced"
                )
            end

            preferences[key] = { [1] = { choice } }
        end

        payload.consumablePreferences = preferences
    end

    payload.consumableItemCache = nil
end

local function migrateInvisibilityPotionPreferences(payload)
    local preferences = payload.consumablePreferences
    local combatPotion = preferences and preferences.combatPotion
    local choices = combatPotion and combatPotion[1]
    local choice = choices and choices[1]

    if
        not choice
        or choice.kind ~= "item"
        or not RCC.db.invisibilityPotionItemData[choice.id]
    then
        return
    end

    local invisibilityPotion = preferences.invisibilityPotion

    if not invisibilityPotion then
        invisibilityPotion = {}
        preferences.invisibilityPotion = invisibilityPotion
    end

    -- Preserve an existing new-category choice, including an explicitly empty
    -- branch. Move the old combat-potion choice only within its owning store.
    if invisibilityPotion[1] == nil then
        invisibilityPotion[1] = CopyTable(choices)
    end

    combatPotion[1] = nil

    if next(combatPotion) == nil then preferences.combatPotion = nil end
end

-- ---------------------------------------------------------------------------
-- Initial profile migration: legacy account settings into Global
-- ---------------------------------------------------------------------------
-- ReadyCheckConsumablesDB.profileStorageVersion records this initial adoption.
-- Later changes to profile contents use the profile-data migrations below.
local INITIAL_PROFILE_MIGRATION_VERSION = 1

local function prepareLegacyPreferences(storage)
    if storage.legacyConsumablePreferences ~= nil then
        if type(storage.legacyConsumablePreferences) ~= "table" then
            error(
                "RCC: invalid legacy preferences; existing data was not replaced"
            )
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
        error(
            "RCC: SavedVariables must be a table; existing data was not replaced"
        )
    end

    local storage

    if saved and saved.profileStorageVersion ~= nil then
        if
            saved.profileStorageVersion ~= INITIAL_PROFILE_MIGRATION_VERSION
            or type(saved.profiles) ~= "table"
        then
            error(
                "RCC: unsupported profile storage; existing data was not replaced"
            )
        end

        storage = saved
    else
        -- Adopt the entire legacy payload, including false values, sparse
        -- visibility overrides, preferences, and movement-provider positions.
        storage = {
            profileStorageVersion = INITIAL_PROFILE_MIGRATION_VERSION,
            profiles = {
                global = saved or {},
            },
        }
    end

    prepareLegacyPreferences(storage)

    return storage
end

-- ---------------------------------------------------------------------------
-- Profile-data migrations: settings stored in every profile
-- ---------------------------------------------------------------------------
-- LibSimpleDBProfiles tracks completed versions and stages every stored profile,
-- including inactive profiles. Add(sourceVersion, callback) advances one version;
-- keep earlier steps and raise this target when adding the next step.
local TARGET_PROFILE_DATA_VERSION = 4

-- Keep the old keys/defaults here: later logins must convert the settings that
-- existed before per-button Enabled switches were removed, not future defaults.
local LEGACY_FRAME_SETTINGS = {
    food = "icon_food",
    flask = "icon_flask",
    consumableStasis = "icon_consumableStasis",
    mainHandTempWeaponEnchant = "icon_mhTempWeaponEnchant",
    offHandTempWeaponEnchant = "icon_ohTempWeaponEnchant",
    lethalPoison = "icon_lethalPoison",
    nonLethalPoison = "icon_nonLethalPoison",
    augment = "icon_augment",
    raidBuff = "icon_raidBuff",
    hs = "icon_healthstone",
    combatpot = "icon_combatPotion",
    healpot = "icon_healPotion",
    invisibilityPotion = "icon_invisibilityPotion",
    glide = "icon_glide",
    recuperate = "icon_recuperate",
    inkyBlackPotion = "icon_inkyBlackPotion",
    repair = "icon_repair",
    vantus = "icon_vantus",
}

local LEGACY_FRAME_DISABLED_DEFAULTS = {
    invisibilityPotion = true,
    glide = true,
    recuperate = true,
    inkyBlackPotion = true,
    repair = true,
}

local LEGACY_FRAME_EVENTS = {
    "readyCheck",
    "instanceEntry",
    "cauldronPickup",
    "breakTimer",
}

local function getVisibilityMigrationTable(parent, key)
    local value = parent[key]

    if value == nil then
        value = {}
        parent[key] = value
    elseif type(value) ~= "table" then
        error(
            "RCC: invalid contextual visibility; existing data was not replaced"
        )
    end

    return value
end

local function migrateFrameButtonVisibility(payload)
    local visibility =
        getVisibilityMigrationTable(payload, "contextualVisibility")
    local frameVisibility =
        getVisibilityMigrationTable(visibility, "consumableFrame")

    for category, settingKey in pairs(LEGACY_FRAME_SETTINGS) do
        local enabled = payload[settingKey]

        if enabled == nil then
            enabled = not LEGACY_FRAME_DISABLED_DEFAULTS[category]
        elseif type(enabled) ~= "boolean" then
            error(
                "RCC: invalid legacy button setting; existing data was not replaced"
            )
        end

        local events = getVisibilityMigrationTable(frameVisibility, category)

        for _, reason in ipairs(LEGACY_FRAME_EVENTS) do
            local allowed = events[reason]

            if allowed ~= nil and type(allowed) ~= "boolean" then
                error(
                    "RCC: invalid open-event setting; existing data was not replaced"
                )
            end

            if not enabled then
                events[reason] = false
            elseif
                allowed == nil and LEGACY_FRAME_DISABLED_DEFAULTS[category]
            then
                -- These optional rows now default off per event. Preserve the
                -- old all-events default only when their old switch was on.
                events[reason] = true
            end
        end

        payload[settingKey] = nil
    end
end

function RCC.ProfileMigration.CreateProfileMigration()
    local migration = LibStub("LibSimpleDBProfiles-1.0"):CreateMigration(
        TARGET_PROFILE_DATA_VERSION
    )
    migration:Add(1, migrateChoices) -- 1 -> 2: normalize saved preferences.
    migration:Add(2, migrateInvisibilityPotionPreferences) -- 2 -> 3: separate invisibility choices.
    migration:Add(3, migrateFrameButtonVisibility) -- 3 -> 4: use only open-event choices.

    return migration
end

-- ---------------------------------------------------------------------------
-- Character-data migrations: character-owned preferences and history
-- ---------------------------------------------------------------------------
-- ReadyCheckConsumablesCharacterDB.preferenceMigrationVersion records completed
-- steps for each character. This target advances separately from profile data.
local TARGET_CHARACTER_DATA_VERSION = 3

local function seedCharacterPreferences(storage, legacyPreferences)
    if
        storage.consumableItemCache == nil
        and storage.consumablePreferences == nil
    then
        storage.consumableItemCache = CopyTable(legacyPreferences)
    end
end

local function migrateCharacterChoices(storage)
    -- Retire the separate marker used by the earlier development build. Its
    -- already-converted choices stay intact within this sequential step.
    if
        storage.consumableChoiceFormatVersion ~= nil
        and storage.consumableChoiceFormatVersion ~= 1
    then
        error("RCC: unsupported choice format; existing data was not replaced")
    end

    migrateChoices(storage)
    storage.consumableChoiceFormatVersion = nil
end

-- Keys are source versions. Each step advances the same character marker:
-- 0 -> 1 seeds ownership once; 1 -> 2 converts the saved choice format.
-- 2 -> 3 moves invisibility choices out of combat-potion preferences.
-- Keep completed steps so later-login characters can run the whole chain.
local CHARACTER_MIGRATIONS = {
    [0] = seedCharacterPreferences,
    [1] = migrateCharacterChoices,
    [2] = migrateInvisibilityPotionPreferences,
}

function RCC.ProfileMigration.PrepareCharacter(saved, legacyPreferences)
    if saved ~= nil and type(saved) ~= "table" then
        error(
            "RCC: character SavedVariables must be a table; existing data was not replaced"
        )
    end

    local storage = saved or {}

    if
        storage.consumableItemCache ~= nil
        and type(storage.consumableItemCache) ~= "table"
    then
        error(
            "RCC: invalid character preferences; existing data was not replaced"
        )
    end

    if
        storage.useProfileConsumablePreferences ~= nil
        and type(storage.useProfileConsumablePreferences) ~= "boolean"
    then
        error(
            "RCC: invalid character preference storage choice; existing data was not replaced"
        )
    end

    if
        storage.consumablePreferences ~= nil
        and not RCC.ConsumableChoice.ValidateBranches(
            storage.consumablePreferences,
            { limitToCapacity = true }
        )
    then
        error(
            "RCC: invalid character preferences; existing data was not replaced"
        )
    end

    if
        storage.consumableHistory ~= nil
        and not RCC.ConsumableChoice.ValidateBranches(storage.consumableHistory)
    then
        error("RCC: invalid consumable history; existing data was not replaced")
    end

    local version = storage.preferenceMigrationVersion

    if version == nil then
        version = 0
    elseif
        type(version) ~= "number"
        or version % 1 ~= 0
        or version < 1
        or version > TARGET_CHARACTER_DATA_VERSION
    then
        error(
            "RCC: unsupported character preference storage; existing data was not replaced"
        )
    end

    if version == TARGET_CHARACTER_DATA_VERSION then return storage end

    -- Publish only the completed copy. A failed step leaves the original
    -- choices, history, storage toggle, and migration marker untouched.
    storage = CopyTable(storage)

    while version < TARGET_CHARACTER_DATA_VERSION do
        CHARACTER_MIGRATIONS[version](storage, legacyPreferences)
        version = version + 1
        storage.preferenceMigrationVersion = version
    end

    return storage
end
