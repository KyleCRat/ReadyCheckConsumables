local _, RCC = ...

RCC.ConsumableFrameGlow = RCC.ConsumableFrameGlow or {}

local Glow = RCC.ConsumableFrameGlow
local State = RCC.ConsumableFrameButtonState

local GLOW_KEY = "rcc_consumable"
local GLOW_COLOR = { 0.0, 0.85, 1.0, 1 }
local GLOW_AVAILABLE_COLOR = { 0.0, 1.0, 0.25, 1 }
local GLOW_UNAVAILABLE_COLOR = { 1.0, 0.05, 0.05, 1 }
local GLOW_PARTICLES = 5
local GLOW_FREQUENCY = 0.15
local GLOW_SCALE = 1.4

local function getRenderCache(button)
    button.consumableFrameRenderCache =
        button.consumableFrameRenderCache or {}

    return button.consumableFrameRenderCache
end

local function applyButtonGlowPhase(button, glowWasActive)
    if glowWasActive then return end

    local glow = button["_AutoCastGlow" .. GLOW_KEY]
    local cache = getRenderCache(button)

    -- glow.timer is a LibCustomGlow-1.0 internal; guard against library
    -- changes that remove or restructure it.
    if not glow or type(glow.timer) ~= "table" or #glow.timer < 4 then
        return
    end

    if not cache.glowPhases then
        cache.glowPhases = {}

        for i = 1, 4 do
            cache.glowPhases[i] = math.random()
        end
    end

    for i = 1, 4 do
        glow.timer[i] = cache.glowPhases[i]
    end

    local onUpdate = glow:GetScript("OnUpdate")

    if onUpdate then
        onUpdate(glow, 0)
    end
end

local function startButtonGlow(button, color)
    local cache = getRenderCache(button)

    if cache.glowActiveColor == color then return end

    local LCG = LibStub("LibCustomGlow-1.0", true)

    if not LCG then return end

    local glowWasActive = button["_AutoCastGlow" .. GLOW_KEY] ~= nil

    cache.glowActiveColor = color
    LCG.AutoCastGlow_Start(button, color, GLOW_PARTICLES,
                           GLOW_FREQUENCY, GLOW_SCALE, 0, 0, GLOW_KEY)

    applyButtonGlowPhase(button, glowWasActive)
end

local function stopButtonGlow(button)
    local cache = getRenderCache(button)

    if not cache.glowActiveColor then return end

    cache.glowActiveColor = nil

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

local function hasConsumableBuff(button)
    return State.HasConsumableBuff(button.consumableState)
end

local function shouldUseHoverGlow(button)
    local cache = getRenderCache(button)

    return button.click
           and (cache.glowEnabled
                or button.clickEnabled
                or hasUnavailableState(button)
                or not hasConsumableBuff(button))
end

local function resolveGlow(button)
    local cache = getRenderCache(button)

    if cache.glowHovered and shouldUseHoverGlow(button) then
        if isButtonClickable(button) then
            startButtonGlow(button, GLOW_AVAILABLE_COLOR)
        else
            startButtonGlow(button, GLOW_UNAVAILABLE_COLOR)
        end
    elseif cache.glowEnabled then
        startButtonGlow(button, GLOW_COLOR)
    else
        stopButtonGlow(button)
    end
end

function Glow.Set(button, enabled)
    local cache = getRenderCache(button)

    cache.glowEnabled = enabled
    resolveGlow(button)
end

function Glow.SetHovered(button, hovered)
    local cache = getRenderCache(button)

    cache.glowHovered = hovered
    resolveGlow(button)
end

function Glow.Stop(button)
    local cache = getRenderCache(button)

    cache.glowEnabled = false
    stopButtonGlow(button)
end
