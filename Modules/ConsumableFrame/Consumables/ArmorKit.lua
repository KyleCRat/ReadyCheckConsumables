local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.ArmorKit = RCC.Consumables.ArmorKit or {}

local ArmorKit = RCC.Consumables.ArmorKit

local Actions = RCC.ConsumableFrameActions
local Glow = RCC.ConsumableFrameGlow

local GetItemCount = C_Item.GetItemCount

local setButtonGlow = Glow.Set

local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"
local ARMOR_KIT_ITEM_ID = 172347
local CHEST_INVENTORY_SLOT = 5

--------------------------------------------------------------------------------
--- Dormant: Armor Kit handling
--- Not currently called. Preserved for future reuse.
--- To re-enable: create a kit button, add it to layout, restore or verify
--- RCC:KitCheck(), then call ArmorKit.Update(button).
--------------------------------------------------------------------------------

function ArmorKit.Update(button)
    if not button then return end

    local kitCount = GetItemCount(ARMOR_KIT_ITEM_ID, false, true) or 0
    local kitNow, _, kitTimeLeft = RCC:KitCheck()

    if kitNow > 0 then
        button.statustexture:SetTexture(READY)
        button.texture:SetDesaturated(false)

        if kitTimeLeft then
            button.timeleft:SetText(kitTimeLeft)
        end
    end

    if kitCount > 0 then
        Actions.SetItemMacro(button, ARMOR_KIT_ITEM_ID, CHEST_INVENTORY_SLOT)
    else
        Actions.Disable(button)
    end

    button.count:SetFormattedText("%d", kitCount)

    if kitCount > 0 and kitNow == 0 then
        setButtonGlow(button, true)
    else
        setButtonGlow(button, false)
    end
end
