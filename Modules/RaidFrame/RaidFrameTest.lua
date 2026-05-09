local _, RCC = ...

local db = RCC.db

--------------------------------------------------------------------------------
--- Test data
--------------------------------------------------------------------------------

local ALL_CLASSES = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK",
    "DRUID", "DEMONHUNTER", "EVOKER",
}

local TEST_NAMES = {
    "Thunderclap", "Lightforge", "Windrunner", "Shadowstep", "Faithweaver",
    "Frostmourne", "Tidecaller", "Frostbolt", "Felblood", "Mistwalker",
    "Moonfire", "Havocblade", "Scalewing",
}

--------------------------------------------------------------------------------
--- Test column data generation
--------------------------------------------------------------------------------

local function randomBool()
    return math.random() > 0.35
end

local function generateTestColumnData()
    local numBuffs = #db.raidBuffDefs
    local hasFood     = randomBool()
    local hasFlask    = randomBool()
    local hasAugment  = randomBool()
    local hasVantus   = randomBool()
    local columnData = {
        food = {
            has    = hasFood,
            time   = hasFood and math.random(60, 3600) or 0,
            auraID = nil,
            iconID = hasFood and db.food_icon_id or nil,
        },
        flask = {
            has    = hasFlask,
            time   = hasFlask and math.random(60, 3600) or 0,
            auraID = nil,
            iconID = hasFlask and db.flask_icon_id or nil,
        },
        augment = {
            has    = hasAugment,
            auraID = nil,
            iconID = hasAugment and db.augment_icon_id or nil,
        },
        vantus = {
            has    = hasVantus,
            auraID = nil,
            iconID = hasVantus and db.vantus_icon_id or nil,
        },
    }

    for raidBuffIndex = 1, numBuffs do
        columnData["raidBuff" .. raidBuffIndex] = {
            has    = randomBool(),
            auraID = nil,
        }
    end

    return columnData
end

--------------------------------------------------------------------------------
--- Test member generation
--------------------------------------------------------------------------------

local function generateOilData()
    local roll = math.random()

    if roll < 0.5 then
        return { time = math.random(60, 3600), item = 0 }
    end

    if roll < 0.7 then
        return { time = 0, item = 0 }
    end

    if roll < 0.85 then
        return { time = -1, item = 0 }
    end

    return nil
end

local function generateTestMembers(excludeClass)
    local members = {}

    for i = 1, #ALL_CLASSES do
        if ALL_CLASSES[i] ~= excludeClass then
            members[#members + 1] = {
                name       = TEST_NAMES[i],
                class      = ALL_CLASSES[i],
                online     = math.random() > 0.1,
                isDead     = math.random() > 0.9,
                columnData = generateTestColumnData(),
                durability = math.random(10, 100),
                oil        = generateOilData(),
            }
        end
    end

    return members
end

--------------------------------------------------------------------------------
--- Export
--------------------------------------------------------------------------------

RCC.raidFrameTest = {
    TEST_DURATION       = 15,
    generateTestMembers = generateTestMembers,
}
