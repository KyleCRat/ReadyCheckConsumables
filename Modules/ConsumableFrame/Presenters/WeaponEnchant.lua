local _, RCC = ...

RCC.Consumables = RCC.Consumables or {}
RCC.Consumables.WeaponEnchant = RCC.Consumables.WeaponEnchant or {}

local WeaponEnchant = RCC.Consumables.WeaponEnchant

local ButtonState = RCC.ConsumableFrameButtonState
local F = RCC.F
local Renderer = RCC.ConsumableFrameRenderer

local ActionType = RCC.ConsumableActionType

local OUT_OF_ITEMS = "No Weapon Enchant Items found in Bags"
local OUT_OF_SELECTED_ITEM = "Selected Weapon Enchant Item not found in Bags"
local MAIN_HAND_INVENTORY_SLOT = WeaponEnchant.MAIN_HAND_INVENTORY_SLOT
local OFF_HAND_INVENTORY_SLOT = WeaponEnchant.OFF_HAND_INVENTORY_SLOT

local function addEnchantIconToState(buttonState, enchantData)
    local icon = WeaponEnchant.GetIcon(enchantData)

    if icon then
        buttonState.icon = icon
    end
end

local function addActiveEnchantToState(buttonState, slotID, slotState)
    if not slotState.hasEnchant then return end

    local enchantData = WeaponEnchant.GetData(slotState.enchantID)

    buttonState.statusTexture = ButtonState.READY_TEXTURE
    buttonState.hasConsumableBuff = true
    buttonState.desaturated = false
    buttonState.detailText = F.FormatDuration(
        (slotState.expiration or 0) / 1000
    )

    if slotState.expiration ~= nil then
        buttonState.detailTextIsBad = WeaponEnchant.IsExpiringSoon(slotState)
    end

    if enchantData then
        addEnchantIconToState(buttonState, enchantData)

        if enchantData.item then
            WeaponEnchant.CacheActiveEnchantItem(slotID, enchantData)
            buttonState.tooltipItemID = enchantData.item
        elseif enchantData.spellID then
            buttonState.tooltipSpellID = enchantData.spellID
        end
    end

    return enchantData
end

local function addCachedItemIconToState(buttonState, itemID, activeEnchantData)
    local enchantData = itemID and RCC.db.weaponEnchantItemIDs[itemID]

    if activeEnchantData or not enchantData then return end

    addEnchantIconToState(buttonState, enchantData)
end

local function createSpellFlyoutChoice(enchantData, slotState)
    local action = WeaponEnchant.CreateSpellEnchantAction(enchantData, slotState)

    if not action then return end

    return ButtonState.Create({
        icon = WeaponEnchant.GetIcon(enchantData),
        desaturated = false,
        countText = "",
        tooltipSpellID = enchantData.spellID,
        clickHintSpellID = enchantData.spellID,
        action = action,
    })
end

local function appendSpellFlyoutChoices(choices, slotState, activeEnchantData)
    local spellCandidates =
        WeaponEnchant.CollectKnownSpellEnchantCandidatesForSlot(
            slotState.slotID
        )

    for i = 1, #spellCandidates do
        local enchantData = spellCandidates[i].enchantData

        if enchantData ~= activeEnchantData then
            local choice = createSpellFlyoutChoice(enchantData, slotState)

            if choice then
                choices[#choices + 1] = choice
            end
        end
    end
end

local function appendChoices(choices, additions)
    if not additions then return end

    for i = 1, #additions do
        choices[#choices + 1] = additions[i]
    end
end

local function buildItemPrimaryFlyoutChoices(itemCandidates, itemID, slotState,
                                             activeEnchantData,
                                             outOfCachedItem)
    local choices = {}

    appendSpellFlyoutChoices(choices, slotState, activeEnchantData)
    appendChoices(choices, ButtonState.CreateItemFlyoutChoices(
        itemCandidates,
        itemID,
        ActionType.WEAPON_ENCHANT_ITEM,
        {
            targetSlot = slotState.slotID,
            available = slotState.canBeEnchanted,
            cacheKey = WeaponEnchant.GetCacheKey(slotState.slotID),
            includeSingleChoice = outOfCachedItem,
        }
    ))

    if #choices > 0 then
        return choices
    end
end

local function configureSpellEnchantState(buttonState, resolution, slotState,
                                          itemCandidates)
    local enchantData = resolution and resolution.spellEnchant

    if not enchantData then return false end

    addEnchantIconToState(buttonState, enchantData)

    buttonState.action = resolution.action
    buttonState.countText = ""
    buttonState.tooltipSpellID = enchantData.spellID
    buttonState.clickHintSpellID = enchantData.spellID
    buttonState.glow = slotState.canBeEnchanted
                       and (not slotState.hasEnchant
                            or WeaponEnchant.IsExpiringSoon(slotState))
    buttonState.flyoutChoices = ButtonState.CreateItemFlyoutChoices(
        itemCandidates,
        nil,
        ActionType.WEAPON_ENCHANT_ITEM,
        {
            targetSlot = slotState.slotID,
            available = slotState.canBeEnchanted,
            includeSingleChoice = true,
            cacheKey = WeaponEnchant.GetCacheKey(slotState.slotID),
        }
    )

    return true
end

local function configureMissingItemState(buttonState, showHint)
    if showHint then
        ButtonState.SetUnavailable(buttonState, OUT_OF_ITEMS)
    end

    buttonState.glow = false
end

local function configureItemEnchantState(buttonState, resolution, slotState)
    local candidate = resolution and resolution.itemCandidate
    local itemID = candidate and candidate.itemID
    local count = candidate and candidate.count
    local hasItem = count ~= nil and count > 0

    buttonState.countText = tostring(count or 0)
    buttonState.qualityItemID = itemID
    buttonState.clickHintItemID = itemID

    if not buttonState.tooltipItemID then
        buttonState.tooltipItemID = itemID
    end

    buttonState.action = resolution.action

    buttonState.glow = slotState.canBeEnchanted
                       and hasItem
                       and (not slotState.hasEnchant
                            or WeaponEnchant.IsExpiringSoon(slotState))
end

local function configureItemEnchantForSlot(buttonState, slotState,
                                           activeEnchantData, resolution,
                                           showMissingHint, itemCandidates)
    local candidate = resolution and resolution.itemCandidate
    local itemID = candidate and candidate.itemID
    local outOfCachedItem = resolution and resolution.outOfCachedItem

    if not itemID then
        if not slotState.hasEnchant then
            configureMissingItemState(buttonState, showMissingHint)
        end

        return
    end

    addCachedItemIconToState(buttonState, itemID, activeEnchantData)

    configureItemEnchantState(
        buttonState,
        resolution,
        slotState
    )

    if outOfCachedItem then
        if slotState.hasEnchant then
            ButtonState.SetHoverUnavailable(buttonState, OUT_OF_SELECTED_ITEM)
        else
            ButtonState.SetUnavailable(buttonState, OUT_OF_SELECTED_ITEM)
        end
    end

    buttonState.flyoutChoices = buildItemPrimaryFlyoutChoices(
        itemCandidates,
        itemID,
        slotState,
        activeEnchantData,
        outOfCachedItem
    )
end

local function updateWeaponEnchantSlot(button, slotID, hasEnchant, expiration,
                                       enchantID, showMissingHint,
                                       itemCandidates)
    local slotState = WeaponEnchant.BuildSlotState(
        slotID,
        hasEnchant,
        expiration,
        enchantID
    )
    local buttonState = ButtonState.Create({
        showInLayout = slotState.canBeEnchanted,
        glow = false,
    })

    if not slotState.canBeEnchanted then
        Renderer.Apply(button, buttonState)

        return
    end

    local activeEnchantData = addActiveEnchantToState(
        buttonState,
        slotID,
        slotState
    )
    local resolution = WeaponEnchant.ResolveAction(
        slotState,
        activeEnchantData,
        itemCandidates
    )

    if not resolution
        or resolution.kind ~= "spell"
        or not configureSpellEnchantState(
            buttonState,
            resolution,
            slotState,
            itemCandidates
        )
    then
        configureItemEnchantForSlot(
            buttonState,
            slotState,
            activeEnchantData,
            resolution,
            showMissingHint,
            itemCandidates
        )
    end

    Renderer.Apply(button, buttonState)
end

local function updateWeaponEnchantButton(button, hasEnchant, expiration,
                                         enchantID, showMissingHint,
                                         itemCandidates)
    if not button or not button.weaponSlot then return end

    updateWeaponEnchantSlot(
        button,
        button.weaponSlot,
        hasEnchant,
        expiration,
        enchantID,
        showMissingHint,
        itemCandidates
    )
end

function WeaponEnchant.Update(buttons)
    local hasMainHandEnchant, mainHandExpiration, _, mainHandEnchantID,
          hasOffHandEnchant, offHandExpiration, _, offHandEnchantID =
          GetWeaponEnchantInfo()
    local itemCandidates = WeaponEnchant.CollectItemCandidatesInBags()

    updateWeaponEnchantButton(
        buttons.mainHandTempWeaponEnchant,
        hasMainHandEnchant,
        mainHandExpiration,
        mainHandEnchantID,
        true,
        itemCandidates
    )

    updateWeaponEnchantButton(
        buttons.offHandTempWeaponEnchant,
        hasOffHandEnchant,
        offHandExpiration,
        offHandEnchantID,
        true,
        itemCandidates
    )
end
