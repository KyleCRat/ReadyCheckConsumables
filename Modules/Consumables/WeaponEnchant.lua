local _, RCC = ...
local WeaponEnchant = {}
RCC.Consumables.WeaponEnchant = WeaponEnchant
local S = RCC.ConsumableSelection
local State = RCC.ConsumableState
local CacheKey = RCC.ConsumableItemCacheKey

local MAIN_HAND_INVENTORY_SLOT = INVSLOT_MAINHAND
local OFF_HAND_INVENTORY_SLOT = INVSLOT_OFFHAND
local MILLISECONDS_PER_SECOND = 1000

WeaponEnchant.Inventory = { map = RCC.db.weaponEnchantItemIDs }

WeaponEnchant.Dependencies = {
    selection = { "inventory", "slotPreference", "slotWeapon", "spells" },
    observation = { "slotWeapon" }, evaluation = { "instance.warningSeconds" },
    expiration = "weapons",
}

WeaponEnchant.MAIN_HAND_INVENTORY_SLOT = MAIN_HAND_INVENTORY_SLOT
WeaponEnchant.OFF_HAND_INVENTORY_SLOT = OFF_HAND_INVENTORY_SLOT

function WeaponEnchant.GetCacheKey(slotID)
    if slotID == MAIN_HAND_INVENTORY_SLOT then
        return CacheKey.MAIN_HAND_TEMP_WEAPON_ENCHANT
    elseif slotID == OFF_HAND_INVENTORY_SLOT then
        return CacheKey.OFF_HAND_TEMP_WEAPON_ENCHANT
    end
end

local function knows(inputs, data)
    local spell = data and data.spellID and inputs.spells[data.spellID]
    return spell and spell.known == true
end

local function matchesRule(inputs, rule)
    for _, enchantID in ipairs(rule.requiresKnownEnchants or {}) do
        if not knows(inputs, RCC.db.weaponEnchants[enchantID]) then return false end
    end
    for _, enchantID in ipairs(rule.blockedByKnownEnchants or {}) do
        if knows(inputs, RCC.db.weaponEnchants[enchantID]) then return false end
    end
    return true
end

local function enchantIcon(inputs, data)
    if not data then return end
    local item = data.item and inputs.inventory[data.item]
    local spell = data.spellID and inputs.spells[data.spellID]
    return data.icon or (item and item.icon) or (spell and spell.icon)
end

local function spellAction(inputs, data, slotID)
    local spell = data and data.spellID and inputs.spells[data.spellID]
    if not spell or not spell.name then return end
    return State.CreateSpellAction(data.spellID, {
        spellName = spell.name,
        available = inputs.weapons[slotID].canBeEnchanted,
        preferenceKey = WeaponEnchant.GetCacheKey(slotID),
    })
end

local function betterItem(a, b)
    local ad, bd = a.data, b.data
    if (ad.xpac or 0) ~= (bd.xpac or 0) then return (ad.xpac or 0) > (bd.xpac or 0) end
    if (ad.q or 0) ~= (bd.q or 0) then return (ad.q or 0) > (bd.q or 0) end
    return a.itemID > b.itemID
end

function WeaponEnchant.Select(inputs, _, slotID)
    local slot = inputs.weapons[slotID]
    local result = {
        applicable = slot.canBeEnchanted,
        slotID = slotID,
        preferenceKey = WeaponEnchant.GetCacheKey(slotID),
        candidates = {},
        spells = {},
    }
    if not result.applicable then return result end

    result.active = slot.hasEnchant and RCC.db.weaponEnchants[slot.enchantID] or nil
    result.activeIcon = enchantIcon(inputs, result.active)
    result.candidates = S.Map(inputs.inventory, RCC.db.weaponEnchantItemIDs)
    table.sort(result.candidates, betterItem)
    for enchantID, data in pairs(RCC.db.weaponEnchants) do
        local rule = data.spellSlots and data.spellSlots[slotID]
        if rule and knows(inputs, data) and matchesRule(inputs, rule) then
            result.spells[#result.spells + 1] = {
                enchantID = enchantID, data = data, priority = rule.priority or 0,
                icon = enchantIcon(inputs, data), action = spellAction(inputs, data, slotID),
            }
        end
    end
    table.sort(result.spells, function(a, b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        return a.enchantID < b.enchantID
    end)

    local spellEnchant = knows(inputs, result.active) and result.active
        or (result.spells[1] and result.spells[1].data)
    if not slot.hasEnchant or knows(inputs, result.active) then
        result.action = spellAction(inputs, spellEnchant, slotID)
        if result.action then
            result.kind = "spell"
            result.spellEnchant = spellEnchant
            result.icon = enchantIcon(inputs, spellEnchant)
            return result
        end
    end

    local preferredID = inputs.preferences[result.preferenceKey]
    local cached = S.CachedMap(inputs.inventory, RCC.db.weaponEnchantItemIDs, preferredID)
    result.candidate = S.Preferred(result.candidates, preferredID, cached)
    result.kind = "item"
    local candidate = result.candidate
    result.unavailable = candidate ~= nil and candidate.itemID == preferredID and candidate.count <= 0
    if candidate then
        result.icon = candidate.icon
        result.action = State.CreateItemAction(candidate.itemID, {
            targetSlot = slotID, available = candidate.count > 0,
            preferenceKey = result.preferenceKey,
        })
    end
    return result
end

-- Compatibility adapter for the group broadcaster, not the personal cache.
-- Keep its millisecond/hasExpirationTime contract while sharing the safe reader.
function WeaponEnchant.GetCurrentSlotState(slotID)
    if slotID ~= MAIN_HAND_INVENTORY_SLOT
        and slotID ~= OFF_HAND_INVENTORY_SLOT
    then
        return
    end
    local now = GetTime()
    local slot = RCC.ConsumableInputs.ReadWeaponSlot(slotID, now)
    slot.remainingTimeMs = slot.expirationTime
        and math.max(0, slot.expirationTime - now) * MILLISECONDS_PER_SECOND
    return slot
end

function WeaponEnchant.GetActionForSlot(slotID)
    local category
    if slotID == MAIN_HAND_INVENTORY_SLOT then
        category = "mainHandTempWeaponEnchant"
    elseif slotID == OFF_HAND_INVENTORY_SLOT then
        category = "offHandTempWeaponEnchant"
    else
        return
    end
    return WeaponEnchant.Select(RCC.ConsumableInputs.ReadSelection(category), true, slotID).action
end

function WeaponEnchant.Observe(inputs, slotID)
    return inputs.weapons[slotID]
end

function WeaponEnchant.Evaluate(selection, observation, inputs, now)
    local remaining = observation.expirationTime and observation.expirationTime - now
    local model = {
        selection = selection, available = observation.available,
        hasEnchant = observation.hasEnchant and (not remaining or remaining > 0),
        remaining = remaining and math.max(0, remaining),
        expiringSoon = remaining ~= nil and remaining <= inputs.instance.warningSeconds,
    }
    RCC.ConsumableEffects.AddDeadline(model, observation.expirationTime, inputs.instance, now)
    return model
end
