local _, RCC = ...

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
