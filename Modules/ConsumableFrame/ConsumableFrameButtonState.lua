local _, RCC = ...

RCC.ConsumableFrameButtonState = RCC.ConsumableFrameButtonState or {}

local State = RCC.ConsumableFrameButtonState

State.READY_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Ready"
State.NOT_READY_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-NotReady"

State.ACTION_DISABLE = "disable"
State.ACTION_ITEM_MACRO = "itemMacro"
State.ACTION_SPELL = "spell"
State.ACTION_WEAPON_ENCHANT_ITEM = "weaponEnchantItem"

-- Omitted fields leave the reset/default button value in place. That keeps this
-- safe for incremental migration while modules still mix direct rendering and
-- state-based rendering.
function State.Create(fields)
    local state = {}

    if fields then
        for key, value in pairs(fields) do
            state[key] = value
        end
    end

    return state
end
