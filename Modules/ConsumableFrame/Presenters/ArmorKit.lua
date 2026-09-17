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

local ButtonState = RCC.ConsumableState

local ARMOR_KIT_ITEM_ID = 172347
local CHEST_INVENTORY_SLOT = 5

--------------------------------------------------------------------------------
--- Dormant: Armor Kit handling
--- Not currently called.
--- To re-enable: verify RCC:KitCheck(), then implement a category selector,
--- observer and presenter using the shared pipeline. This legacy prototype
--- is retained as reference, not registered with ConsumableRuntime.
--------------------------------------------------------------------------------

function ArmorKit.ResolveState()
    local kitCount = C_Item.GetItemCount(ARMOR_KIT_ITEM_ID, false, false)
    if not RCC.F.IsSafeNumber(kitCount) then kitCount = 0 end
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
        buttonState.detailText = kitTimeLeft
    end

    if kitCount > 0 then
        buttonState.tooltipItemID = ARMOR_KIT_ITEM_ID
        buttonState.qualityItemID = ARMOR_KIT_ITEM_ID
        buttonState.action = ButtonState.CreateItemAction(
            ARMOR_KIT_ITEM_ID,
            {
            targetSlot = CHEST_INVENTORY_SLOT,
            }
        )
    end

    return buttonState
end
