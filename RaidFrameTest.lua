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
--- Test aura generation
--------------------------------------------------------------------------------

local function randomBool()
    return math.random() > 0.35
end

local function generateTestAuras()
    local numBuffs = #db.raidBuffDefs
    local raidBuff = {}

    for k = 1, numBuffs do
        raidBuff[k] = randomBool() and true or false
    end

    local hasFood  = randomBool()
    local hasFlask = randomBool()
    local hasRune  = randomBool()
    local hasVantus = randomBool()

    return {
        hasFood     = hasFood,
        foodTime    = hasFood and math.random(60, 3600) or 0,
        foodAuraID  = nil,
        foodIconID  = hasFood and db.food_icon_id or nil,
        hasFlask    = hasFlask,
        flaskTime   = hasFlask and math.random(60, 3600) or 0,
        flaskAuraID = nil,
        flaskIconID = hasFlask and db.flask_icon_id or nil,
        hasRune     = hasRune,
        runeAuraID  = nil,
        runeIconID  = hasRune and db.rune_icon_id or nil,
        hasVantus   = hasVantus,
        vantusAuraID = nil,
        vantusIconID = hasVantus and db.vantus_icon_id or nil,
        raidBuff    = raidBuff,
    }
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
                auras      = generateTestAuras(),
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
