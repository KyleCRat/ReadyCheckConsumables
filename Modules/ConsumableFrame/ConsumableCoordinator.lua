local _, RCC = ...

local Auras = RCC.ConsumableFrameAuras
local F = RCC.F
local Actions = RCC.ConsumableFrameActions
local Buttons = RCC.ConsumableFrameButtons
local Food = RCC.Consumables.Food
local Flask = RCC.Consumables.Flask
local Augment = RCC.Consumables.Augment
local Healthstone = RCC.Consumables.Healthstone
local DamagePotion = RCC.Consumables.DamagePotion
local HealingPotion = RCC.Consumables.HealingPotion
local Vantus = RCC.Consumables.Vantus
local WeaponEnchant = RCC.Consumables.WeaponEnchant
local Glow = RCC.ConsumableFrameGlow

local            GetTime = GetTime
local       GetItemCount = C_Item.GetItemCount

local setButtonGlow = Glow.Set
local setButtonShownInLayout = Buttons.SetShownInLayout
local resetButtonState = Buttons.ResetState

--------------------------------------------------------------------------------
--- Dormant: Armor Kit handling
--- Not currently called. Preserved for future re-use.
--- To re-enable: create a kit button, add to layout, call from
--- Update().
--------------------------------------------------------------------------------

local function updateArmorKits(buttons)
    local kitCount = GetItemCount(172347, false, true)
    local kitNow, kitMax, kitTimeLeft = RCC:KitCheck()
    local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

    if kitNow > 0 then
        buttons.kit.statustexture:SetTexture(READY)
        buttons.kit.texture:SetDesaturated(false)

        if kitTimeLeft then
            buttons.kit.timeleft:SetText(kitTimeLeft)
        end
    end

    if kitCount and kitCount > 0 then
        Actions.SetItemMacro(buttons.kit, 172347, 5)
    else
        Actions.Disable(buttons.kit)
    end

    buttons.kit.count:SetFormattedText("%d", kitCount)

    if kitCount and kitCount > 0 and kitNow == 0 then
        setButtonGlow(buttons.kit, true)
    else
        setButtonGlow(buttons.kit, false)
    end
end

--------------------------------------------------------------------------------
--- Update() coordinator
--------------------------------------------------------------------------------

function RCC.consumables:Update()
    self:UpdateReadyCheckAnchor()
    local buttons = self.buttons

    local isWarlockInRaid = F.hasClassInRoster("WARLOCK")

    local NOT_READY = "Interface\\RaidFrame\\ReadyCheck-NotReady"

    for i = 1, #buttons do
        resetButtonState(buttons[i], NOT_READY)
    end

    setButtonShownInLayout(buttons.hs, isWarlockInRaid)

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
