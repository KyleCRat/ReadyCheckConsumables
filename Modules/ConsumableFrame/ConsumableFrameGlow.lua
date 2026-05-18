local _, RCC = ...

RCC.ConsumableFrameGlow = RCC.ConsumableFrameGlow or {}

local Glow = RCC.ConsumableFrameGlow

local GLOW_KEY = "rcc_consumable"
local GLOW_COLOR = { 0.0, 0.85, 1.0, 1 }
local GLOW_AVAILABLE_COLOR = { 0.0, 1.0, 0.25, 1 }
local GLOW_UNAVAILABLE_COLOR = { 1.0, 0.05, 0.05, 1 }
local GLOW_PARTICLES = 5
local GLOW_FREQUENCY = 0.15
local GLOW_SCALE = 1.4

local function applyButtonGlowPhase(button, glowWasActive)
    if glowWasActive then return end

    local glow = button["_AutoCastGlow" .. GLOW_KEY]

    -- glow.timer is a LibCustomGlow-1.0 internal; guard against library
    -- changes that remove or restructure it.
    if not glow or type(glow.timer) ~= "table" or #glow.timer < 4 then
        return
    end

    if not button.rccGlowPhases then
        button.rccGlowPhases = {}

        for i = 1, 4 do
            button.rccGlowPhases[i] = math.random()
        end
    end

    for i = 1, 4 do
        glow.timer[i] = button.rccGlowPhases[i]
    end

    local onUpdate = glow:GetScript("OnUpdate")

    if onUpdate then
        onUpdate(glow, 0)
    end
end

local function startButtonGlow(button, color)
    if button.rccGlowActiveColor == color then return end

    local LCG = LibStub("LibCustomGlow-1.0", true)

    if not LCG then return end

    local glowWasActive = button["_AutoCastGlow" .. GLOW_KEY] ~= nil

    button.rccGlowActiveColor = color
    LCG.AutoCastGlow_Start(button, color, GLOW_PARTICLES,
                           GLOW_FREQUENCY, GLOW_SCALE, 0, 0, GLOW_KEY)

    applyButtonGlowPhase(button, glowWasActive)
end

local function stopButtonGlow(button)
    button.rccGlowActiveColor = nil

    local LCG = LibStub("LibCustomGlow-1.0", true)

    if not LCG then return end

    LCG.AutoCastGlow_Stop(button, GLOW_KEY)
end

local function isButtonClickable(button)
    return button.click and button.clickEnabled and button.click:IsShown()
end

local function hasUnavailableState(button)
    -- Deferred lookup: breaks circular dependency with ConsumableFrameButtons.
    local Buttons = RCC.ConsumableFrameButtons

    return Buttons and Buttons.GetUnavailableText(button) ~= nil
end

local function shouldUseHoverGlow(button)
    return button.click
           and (button.rccGlowEnabled
                or button.clickEnabled
                or hasUnavailableState(button)
                or not button.hasConsumableBuff)
end

local function resolveGlow(button)
    if button.rccGlowHovered and shouldUseHoverGlow(button) then
        if isButtonClickable(button) then
            startButtonGlow(button, GLOW_AVAILABLE_COLOR)
        else
            startButtonGlow(button, GLOW_UNAVAILABLE_COLOR)
        end
    elseif button.rccGlowEnabled then
        startButtonGlow(button, GLOW_COLOR)
    else
        stopButtonGlow(button)
    end
end

function Glow.Set(button, enabled)
    button.rccGlowEnabled = enabled
    resolveGlow(button)
end

function Glow.SetHovered(button, hovered)
    button.rccGlowHovered = hovered
    resolveGlow(button)
end

function Glow.Stop(button)
    button.rccGlowEnabled = false
    stopButtonGlow(button)
end
