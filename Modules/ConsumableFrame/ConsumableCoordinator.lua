local _, RCC = ...

local Auras = RCC.ConsumableFrameAuras
local Buttons = RCC.ConsumableFrameButtons
local Food = RCC.Consumables.Food
local Flask = RCC.Consumables.Flask
local Augment = RCC.Consumables.Augment
local Healthstone = RCC.Consumables.Healthstone
local DamagePotion = RCC.Consumables.DamagePotion
local HealingPotion = RCC.Consumables.HealingPotion
local Vantus = RCC.Consumables.Vantus
local WeaponEnchant = RCC.Consumables.WeaponEnchant

local GetTime = GetTime

local resetButtonState = Buttons.ResetState

--------------------------------------------------------------------------------
--- Update() coordinator
--------------------------------------------------------------------------------

function RCC.consumables:Update()
    self:UpdateReadyCheckAnchor()
    local buttons = self.buttons

    local NOT_READY = "Interface\\RaidFrame\\ReadyCheck-NotReady"

    for i = 1, #buttons do
        resetButtonState(buttons[i], NOT_READY)
    end

    local now = GetTime()
    local auraState = Auras.ScanPlayer(now)

    Food.Update(buttons.food, auraState)
    Healthstone.Update(buttons.hs)
    Flask.Update(buttons.flask, auraState)
    WeaponEnchant.Update(buttons)
    Augment.Update(buttons.augment, auraState)
    DamagePotion.Update(buttons.dmgpot)
    HealingPotion.Update(buttons.healpot)
    Vantus.Update(buttons.vantus, auraState)

    if not InCombatLockdown() then
        Buttons.ApplyLayout(self, buttons)
    end

    Buttons.UpdateOutOverlays(buttons)
end
