local _, RCC = ...

local TIMED_TEST = false
local PERMANENT_TEST = true
local COMBINED_TEST = { includeCauldrons = true }
local READY_CHECK_ONLY_TEST = { includeCauldrons = false }

local function printMessage(message)
    print("|" .. RCC.color .. "ffReadyCheckConsumables|r: " .. message)
end

local function hideFrames()
    RCC.ReadyCheckTest:Cancel()
    RCC.ConsumableFrameController.HideImmediately()
    RCC.raidFrame:Hide()
    RCC.RaidFrameCauldron.Hide()
end

local function openConsumablesFrame()
    if InCombatLockdown() then
        printMessage("Can't open the Consumables Frame in combat.")

        return
    end

    if not RCC.GetSetting("consumables_enabled") then
        printMessage("The Consumables Frame is disabled.")

        return
    end

    RCC.ConsumableFrameController.OpenManually()
end

local COMMANDS = {
    {
        triggers = { "t", "test" },
        description = "Show a timed combined test",
        run = function()
            RCC.ReadyCheckTest:Start(TIMED_TEST, COMBINED_TEST)
        end,
    },
    {
        triggers = { "tp", "test permanent" },
        description = "Show a permanent combined test",
        run = function()
            RCC.ReadyCheckTest:Start(PERMANENT_TEST, COMBINED_TEST)
        end,
    },
    {
        triggers = { "rt", "ready check test", "readycheck test" },
        description = "Show a timed ready-check-only test",
        run = function()
            RCC.ReadyCheckTest:Start(TIMED_TEST, READY_CHECK_ONLY_TEST)
        end,
    },
    {
        triggers = {
            "rtp",
            "ready check test permanent",
            "readycheck test permanent",
        },
        description = "Show a permanent ready-check-only test",
        run = function()
            RCC.ReadyCheckTest:Start(PERMANENT_TEST, READY_CHECK_ONLY_TEST)
        end,
    },
    {
        triggers = { "ct", "cauldron test" },
        description = "Show the cauldron-only test",
        run = function()
            RCC.RaidFrameTest:StartCauldronOnly()
        end,
    },
    {
        triggers = { "h", "hide" },
        description = "Immediately hide all RCC frames",
        run = hideFrames,
    },
    {
        triggers = { "r", "report" },
        description = "Print the consumable report locally",
        run = function()
            RCC.chatReport.Test(false)
        end,
    },
    {
        triggers = { "rc", "report chat", "reportchat" },
        description = "Send the consumable report to group chat",
        run = function()
            RCC.chatReport.Test(true)
        end,
    },
    {
        triggers = { "c", "consume", "consumables" },
        description = "Open the Consumables Frame",
        run = openConsumablesFrame,
    },
    {
        triggers = { "s", "settings", "options" },
        description = "Open the settings panel",
        run = RCC.OpenSettings,
    },
}

local COMMAND_LOOKUP = {}

for i = 1, #COMMANDS do
    local command = COMMANDS[i]

    for j = 1, #command.triggers do
        COMMAND_LOOKUP[command.triggers[j]] = command.run
    end
end

local function printHelp()
    print("|" .. RCC.color .. "ffReadyCheckConsumables|r commands:")

    for i = 1, #COMMANDS do
        local command = COMMANDS[i]

        print("  /rcc " .. command.triggers[1]
            .. " (" .. command.triggers[2] .. ") - "
            .. command.description)
    end
end

SLASH_RCC1 = "/rcc"
SlashCmdList["RCC"] = function(message)
    local command = COMMAND_LOOKUP[strlower(strtrim(message))]

    if command then
        command()

        return
    end

    printHelp()
end
