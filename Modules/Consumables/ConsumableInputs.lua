local _, RCC = ...

-- The only live-query boundary for the personal consumable pipeline. Published
-- inputs contain public values only and are replaced, never edited in place.
-- Selection adapters for macros use these same readers without subscribing to
-- a UI controller (macros must work when both personal surfaces are disabled).
local Inputs = {}
RCC.ConsumableInputs = Inputs

local F = RCC.F
local Cache = RCC.ConsumableFrameItemCache

local MAIN_HAND_INVENTORY_SLOT = INVSLOT_MAINHAND
local OFF_HAND_INVENTORY_SLOT = INVSLOT_OFFHAND
local MILLISECONDS_PER_SECOND = 1000
local WEAPON_INVENTORY_SLOTS = {
    MAIN_HAND_INVENTORY_SLOT,
    OFF_HAND_INVENTORY_SLOT,
}

function Inputs.Equal(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for key, value in pairs(a) do
        if not Inputs.Equal(value, b[key]) then return false end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end

local function publicNumber(value)
    if F.IsSafeNumber(value) then return value end
end

local function publicString(value)
    if not issecretvalue(value) and type(value) == "string" then
        return value
    end
end

function Inputs.GetItemIDs(category)
    local definition = RCC.ConsumableCatalog.GetDefinition(category)
    local inventory = RCC.Consumables[definition.domain].Inventory
    local ids = {}
    if not inventory then return ids end
    local function addList(list)
        for _, itemID in ipairs(list or {}) do ids[itemID] = true end
    end
    addList(inventory.list)
    for itemID in pairs(inventory.map or {}) do ids[itemID] = true end
    for _, list in pairs(inventory.lists or {}) do addList(list) end
    if inventory.itemID then ids[inventory.itemID] = true end
    return ids
end

function Inputs.ReadInventory(itemIDs, previous, changedIDs)
    local inventory = {}
    for itemID in pairs(itemIDs) do
        local old = previous and previous[itemID]
        if old and changedIDs and not changedIDs[itemID] then
            inventory[itemID] = old
        else
            local count = publicNumber(C_Item.GetItemCount(itemID, false, false)) or 0
            local metadata = old
            if not metadata or not metadata.metadataLoaded then
                local quality = C_TradeSkillUI.GetItemReagentQualityInfo(itemID)
                local loaded = C_Item.IsItemDataCachedByID(itemID)
                metadata = {
                    icon = publicNumber(C_Item.GetItemIconByID(itemID)),
                    qualityAtlas = quality and publicString(quality.iconSmall),
                    metadataLoaded = not issecretvalue(loaded) and loaded == true,
                }
            end
            inventory[itemID] = {
                count = count,
                uses = RCC.db.healthstoneItemIDs[itemID]
                    and (publicNumber(C_Item.GetItemCount(itemID, false, true)) or 0) or count,
                icon = metadata.icon,
                qualityAtlas = metadata.qualityAtlas,
                metadataLoaded = metadata.metadataLoaded,
            }
        end
    end
    return inventory
end

function Inputs.ReadPreferences()
    local preferences = {}
    for _, cacheKey in pairs(RCC.ConsumableItemCacheKey) do
        preferences[cacheKey] = Cache.Get(cacheKey)
    end
    preferences.preferUnlimitedAugment =
        RCC.GetSetting("consumables_preferUnlimitedAugment") == true
    return preferences
end

function Inputs.ReadContext()
    local _, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
    local _, class = UnitClass("player")
    instanceType = publicString(instanceType)
    class = publicString(class)
    return {
        instanceType = instanceType,
        instanceID = publicNumber(instanceID),
        uiMapID = publicNumber(C_Map.GetBestMapForUnit("player")),
        class = class,
        warningSeconds = RCC.ConsumableTiming.GetWarningSeconds(instanceType),
        raidBuff = RCC.RaidBuffStatus.GetInfoByProviderClass(class),
    }
end

function Inputs.ReadSpells()
    local spells = {}
    for _, data in pairs(RCC.db.weaponEnchants) do
        if data.spellID then
            local info = C_Spell.GetSpellInfo(data.spellID)
            local known = C_SpellBook.IsSpellKnown(data.spellID)
            spells[data.spellID] = {
                known = not issecretvalue(known) and known == true,
                name = info and publicString(info.name),
                icon = info and publicNumber(info.iconID),
            }
        end
    end
    return spells
end

function Inputs.ReadWeaponSlot(slotID, now)
    local itemID = publicNumber(GetInventoryItemID("player", slotID))
    local itemClass = itemID and publicNumber(select(6, C_Item.GetItemInfoInstant(itemID)))
    local info = C_PaperDollInfo.GetTemporaryEnchantmentInfo(slotID)
    local readable = not issecretvalue(info)
    local hasEnchant = readable and type(info) == "table"
    local function field(key)
        if hasEnchant and not issecretvalue(info[key]) then return info[key] end
    end
    local remaining = publicNumber(field("remainingTimeMs"))
    local enchantID = publicNumber(field("enchantID"))
    if enchantID and enchantID <= 0 then enchantID = nil end
    local expires = field("hasExpirationTime") == true
    return {
        slotID = slotID,
        itemID = itemID,
        canBeEnchanted = itemClass == Enum.ItemClass.Weapon,
        available = readable,
        hasEnchant = itemClass == Enum.ItemClass.Weapon and hasEnchant,
        hasExpirationTime = expires,
        enchantID = enchantID,
        chargesRemaining = publicNumber(field("chargesRemaining")),
        expirationTime = expires and remaining
            and now + remaining / MILLISECONDS_PER_SECOND or nil,
    }
end

function Inputs.ReadWeapons(now, requestedSlots)
    local weapons = {}
    for _, slotID in ipairs(WEAPON_INVENTORY_SLOTS) do
        if not requestedSlots or requestedSlots[slotID] then
            weapons[slotID] = Inputs.ReadWeaponSlot(slotID, now)
        end
    end
    return weapons
end

function Inputs.RememberAppliedEnchants(weapons)
    -- An explicit, idempotent domain side effect, before selection. Rendering
    -- and macro resolution must never silently change a saved preference.
    for slotID, slot in pairs(weapons) do
        local data = slot.hasEnchant and RCC.db.weaponEnchants[slot.enchantID]
        if data and data.item then
            Cache.Set(RCC.Consumables.WeaponEnchant.GetCacheKey(slotID), data.item)
        end
    end
end

function Inputs.ReadCooldowns(inventory, now)
    local cooldowns = {}
    for _, itemID in ipairs(RCC.db.repairItemIDs) do
        if inventory[itemID] and inventory[itemID].count > 0 then
            local start, duration = C_Item.GetItemCooldown(itemID)
            start, duration = publicNumber(start), publicNumber(duration)
            if start and duration and duration > 0 and start + duration > now then
                cooldowns[itemID] = { start = start, duration = duration }
            end
        end
    end
    return cooldowns
end

function Inputs.ReadLifeState(unit)
    local dead = UnitIsDeadOrGhost(unit)
    if not issecretvalue(dead) then return not dead end
end

function Inputs.ReadRoster()
    local roster = { units = {}, hasWarlock = false }
    F.ForEachActiveRosterMember(function(name, unit, _, class, online)
        roster.hasWarlock = roster.hasWarlock or class == "WARLOCK"
        local alive = Inputs.ReadLifeState(unit)
        roster.units[unit] = {
            name = name,
            alive = alive,
            eligible = not issecretvalue(online) and online == true and alive ~= false,
        }
    end)
    return roster
end

function Inputs.ReadGroupAuras(roster, context, previous, units, now, freshPlayerAuras)
    local observations = {}
    local info = context.raidBuff
    if not info then return observations end
    for unit, member in pairs(roster.units) do
        if member.eligible then
            if previous and units and not units[unit] and previous[unit] then
                observations[unit] = previous[unit]
            else
                local status

                if freshPlayerAuras and F.UnitIsUnitSafe(unit, "player") then
                    -- The shared resolver reuses conclusive scan data and
                    -- queries accepted spell IDs only if still unresolved.
                    status = RCC.RaidBuffStatus.GetStatusFromScan(unit, freshPlayerAuras, info.index, now)
                else
                    status = RCC.RaidBuffStatus.GetUnitStatus(unit, info.index, now)
                end

                observations[unit] = {
                    available = status.available,
                    has = status.has,
                    expirationTime = status.expirationTime,
                }
            end
        end
    end
    return observations
end

function Inputs.ReadSelection(category)
    local definition = RCC.ConsumableCatalog.GetDefinition(category)
    local dependencies = RCC.Consumables[definition.domain].Dependencies.selection
    local needed = {}
    for _, path in ipairs(dependencies or {}) do needed[path:match("^[^.]+")] = true end
    local now = GetTime()
    local inventory = Inputs.ReadInventory(Inputs.GetItemIDs(category))
    return {
        inventory = inventory,
        preferences = (needed.preferences or needed.slotPreference) and Inputs.ReadPreferences() or nil,
        context = needed.context and Inputs.ReadContext() or nil,
        spells = needed.spells and Inputs.ReadSpells() or nil,
        weapons = needed.slotWeapon and {
            [definition.weaponSlot] = Inputs.ReadWeaponSlot(definition.weaponSlot, now),
        } or nil,
        cooldowns = needed.cooldowns and Inputs.ReadCooldowns(inventory, now) or nil,
    }
end
