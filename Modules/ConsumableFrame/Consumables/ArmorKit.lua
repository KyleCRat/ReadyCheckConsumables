local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.ArmorKit = RCC.Consumables.ArmorKit or {}

local ArmorKit = RCC.Consumables.ArmorKit

local Actions = RCC.ConsumableFrameActions
local ButtonState = RCC.ConsumableFrameButtonState
local ItemCandidates = RCC.ConsumableFrameItemCandidates
local Renderer = RCC.ConsumableFrameRenderer

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
        buttonState.action = Actions.CreateItemMacro(
            ARMOR_KIT_ITEM_ID,
            CHEST_INVENTORY_SLOT
        )
    else
        buttonState.action = Actions.CreateDisabled()
    end

    Renderer.Apply(button, buttonState)
end
