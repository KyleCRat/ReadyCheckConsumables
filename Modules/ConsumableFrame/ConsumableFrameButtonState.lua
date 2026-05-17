local _, RCC = ...

RCC.ConsumableFrameButtonState = RCC.ConsumableFrameButtonState or {}

local State = RCC.ConsumableFrameButtonState

local Actions = RCC.ConsumableFrameActions
local Buttons = RCC.ConsumableFrameButtons
local Glow = RCC.ConsumableFrameGlow

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

local function applyAction(button, action)
    if not action or not action.type then return end

    if action.type == State.ACTION_DISABLE then
        Actions.Disable(button)
    elseif action.type == State.ACTION_ITEM_MACRO and action.itemID then
        Actions.SetItemMacro(button, action.itemID, action.targetSlot)
    elseif action.type == State.ACTION_SPELL and action.spellName then
        Actions.SetSpell(button, action.spellName, action.available)
    elseif action.type == State.ACTION_WEAPON_ENCHANT_ITEM and action.itemID then
        Actions.SetWeaponEnchantItem(button, action.itemID, action.available)
    end
end

function State.Apply(button, state)
    if not button or not state then return end

    button.consumableState = state

    if state.showInLayout ~= nil then
        Buttons.SetShownInLayout(button, state.showInLayout)
    end

    if state.statusTexture then
        button.statustexture:SetTexture(state.statusTexture)
    end

    if state.icon then
        button.texture:SetTexture(state.icon)
    end

    if state.desaturated ~= nil then
        button.texture:SetDesaturated(state.desaturated == true)
    end

    if state.countText ~= nil then
        button.count:SetText(state.countText)
    end

    if state.timeText ~= nil then
        button.timeleft:SetText(state.timeText)
    end

    if state.timeIsBad ~= nil then
        Buttons.SetTimeTextBad(button, state.timeIsBad)
    end

    if state.hasConsumableBuff ~= nil then
        button.hasConsumableBuff = state.hasConsumableBuff == true
    end

    if state.tooltipAuraID ~= nil then
        button.tooltipAuraID = state.tooltipAuraID
    end

    if state.tooltipItemID ~= nil then
        button.tooltipItemID = state.tooltipItemID
    end

    if state.tooltipSpellID ~= nil then
        button.tooltipSpellID = state.tooltipSpellID
    end

    if state.usableItemID ~= nil then
        button.usableItemID = state.usableItemID
    end

    if state.clickHintItemID ~= nil then
        button.clickHintItemID = state.clickHintItemID
    end

    if state.clickHintSpellID ~= nil then
        button.clickHintSpellID = state.clickHintSpellID
    end

    if state.outOfItemsText ~= nil then
        button.outOfItemsText = state.outOfItemsText
    end

    if state.glow ~= nil then
        Glow.Set(button, state.glow == true)
    end

    applyAction(button, state.action)
end
