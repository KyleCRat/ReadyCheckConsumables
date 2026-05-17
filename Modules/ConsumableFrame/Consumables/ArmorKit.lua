local _, RCC = ...

--------------------------------------------------------------------------------
--- Intentionally dormant
--- Armor kits have appeared and disappeared across expansions. Keep this module
--- loaded but unwired so the support path is easy to restore if Blizzard brings
--- armor kits back as relevant consumables.
--------------------------------------------------------------------------------

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.ArmorKit = RCC.Consumables.ArmorKit or {}

local ArmorKit = RCC.Consumables.ArmorKit

local ButtonState = RCC.ConsumableFrameButtonState
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType
local ARMOR_KIT_ITEM_ID = 172347
local CHEST_INVENTORY_SLOT = 5

--------------------------------------------------------------------------------
--- Dormant: Armor Kit handling
--- Not currently called.
--- To re-enable: create a kit button, add it to layout, restore or verify
--- RCC:KitCheck(), then call ArmorKit.Update(button).
--------------------------------------------------------------------------------

function ArmorKit.Update(button)
    if not button then return end

    local kitCount = ItemCandidates.GetCount(
        ARMOR_KIT_ITEM_ID,
        ItemCandidates.BAGS_ONLY
    )
    local kitNow, _, kitTimeLeft = RCC:KitCheck()
    kitNow = kitNow or 0
    local buttonState = ButtonState.Create({
        countText = tostring(kitCount),
        glow = kitCount > 0 and kitNow == 0,
    })

    if kitNow > 0 then
        buttonState.statusTexture = ButtonState.READY_TEXTURE
        buttonState.hasConsumableBuff = true
        buttonState.desaturated = false
        buttonState.timeText = kitTimeLeft
    end

    if kitCount > 0 then
        buttonState.tooltipItemID = ARMOR_KIT_ITEM_ID
        buttonState.usableItemID = ARMOR_KIT_ITEM_ID
        buttonState.action = {
            type = ActionType.ITEM_MACRO,
            itemID = ARMOR_KIT_ITEM_ID,
            targetSlot = CHEST_INVENTORY_SLOT,
        }
    end

    Renderer.Apply(button, buttonState)
end
