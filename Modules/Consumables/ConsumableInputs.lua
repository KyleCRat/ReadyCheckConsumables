local _, RCC = ...

-- The only live-query boundary for the personal consumable pipeline. Published
-- inputs contain public values only and are replaced, never edited in place.
-- Selection adapters for macros use these same readers without subscribing to
-- a UI controller (macros must work when both personal surfaces are disabled).
local Inputs = {}
RCC.ConsumableInputs = Inputs

local F = RCC.F
local Preferences = RCC.ConsumablePreferences

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
    local inventory = definition.logic.Inventory
    local ids = {}

    if not inventory then return ids end

    local function addList(list)
        for _, itemID in ipairs(list or {}) do
            ids[itemID] = true
        end
    end

    addList(inventory.list)

    for itemID in pairs(inventory.map or {}) do
        ids[itemID] = true
    end

    for _, list in pairs(inventory.lists or {}) do
        addList(list)
    end

    if inventory.itemID then
        ids[inventory.itemID] = true
    end

    return ids
end

function Inputs.GetCooldownItemIDs(category)
    local definition = RCC.ConsumableCatalog.GetDefinition(category)
    local inventory = definition.logic.Inventory
    local ids = {}

    if not inventory then return ids end

    for _, itemID in ipairs(inventory.cooldownItemIDs or {}) do
        ids[itemID] = true
    end

    return ids
end

function Inputs.GetSpellIDs(category)
    local definition = RCC.ConsumableCatalog.GetDefinition(category)
    local logic = definition.logic
    local ids = {}

    if logic.GetSpellIDs then
        for _, spellID in ipairs(logic.GetSpellIDs(definition)) do
            ids[spellID] = true
        end
    end

    return ids
end

function Inputs.GetPlayerAuraSpellIDs(category)
    local definition = RCC.ConsumableCatalog.GetDefinition(category)
    local logic = definition.logic
    local ids = {}

    if logic.GetPlayerAuraSpellIDs then
        for _, spellID in ipairs(logic.GetPlayerAuraSpellIDs(definition)) do
            ids[spellID] = true
        end
    end

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

function Inputs.ReadPreferences(previous)
    local preferences = Preferences.Read(previous)

    preferences.preferUnlimitedAugment =
        RCC.GetSetting("consumables_preferUnlimitedAugment") == true

    return preferences
end

function Inputs.ReadInstance()
    local _, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
    instanceType = publicString(instanceType)

    return {
        instanceType = instanceType,
        instanceID = publicNumber(instanceID),
        warningSeconds = RCC.ConsumableTiming.GetWarningSeconds(instanceType),
    }
end

function Inputs.ReadLocation()
    return {
        uiMapID = publicNumber(C_Map.GetBestMapForUnit("player")),
    }
end

function Inputs.ReadClassToken()
    local _, classToken = UnitClass("player")

    return publicString(classToken)
end

function Inputs.ReadClass()
    local classToken = Inputs.ReadClassToken()

    return {
        classToken = classToken,
        raidBuff = RCC.RaidBuffStatus.GetInfoByProviderClass(classToken),
    }
end

function Inputs.ReadSpells(spellIDs)
    local spells = {}

    for spellID in pairs(spellIDs) do
        local info = C_Spell.GetSpellInfo(spellID)
        local known = C_SpellBook.IsSpellKnown(spellID)

        spells[spellID] = {
            known = not issecretvalue(known) and known == true,
            name = info and publicString(info.name),
            icon = info and publicNumber(info.iconID),
        }
    end

    return spells
end

-- Targeted player buffs are independent of full player scans. Reuse a fresh
-- scan when conclusive; otherwise ask the existing secret-safe boundary for
-- each requested ID. Callers provide aura IDs, not cast spell IDs.
function Inputs.ReadPlayerSpellAuras(spellIDs, freshPlayerAuras)
    local observations = {}
    local ids = {}
    local scannedAuras = {}
    local AuraScan = RCC.HelpfulAuraScan

    for spellID in pairs(spellIDs) do
        ids[#ids + 1] = spellID
    end

    AuraScan.CacheSpellSecrecy(ids)

    if freshPlayerAuras then
        for _, aura in ipairs(freshPlayerAuras.auras) do
            if spellIDs[aura.spellID] then
                scannedAuras[aura.spellID] = aura
            end
        end
    end

    for _, spellID in ipairs(ids) do
        local aura = scannedAuras[spellID]

        if aura then
            observations[spellID] = { available = true, aura = aura }
        elseif freshPlayerAuras and AuraScan.CanConfirmMissing(freshPlayerAuras, { spellID }) then
            observations[spellID] = { available = true }
        else
            observations[spellID] = AuraScan.FindBySpellID("player", spellID)
        end
    end

    return observations
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

    if enchantID and enchantID <= 0 then
        enchantID = nil
    end

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

function Inputs.ReadCooldowns(inventory, itemIDs, now, displayedItemIDs)
    local cooldowns = {}
    local nextExpiration

    for itemID in pairs(itemIDs) do
        local carried = inventory[itemID] and inventory[itemID].count > 0
        local displayed = displayedItemIDs and displayedItemIDs[itemID]

        -- A prepared combat button can still show an item after its last use.
        -- Query that exact item's timer without scanning every unowned variant.
        if carried or displayed then
            local start, duration = C_Item.GetItemCooldown(itemID)
            start, duration = publicNumber(start), publicNumber(duration)
            local expires = start and duration and start + duration

            if expires and duration > 0 and expires > now then
                cooldowns[itemID] = { start = start, duration = duration }
                nextExpiration = math.min(nextExpiration or expires, expires)
            end
        end
    end

    return cooldowns, nextExpiration
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

function Inputs.ReadGroupAuras(roster, class, previous, units, now, freshPlayerAuras)
    local observations = {}
    local info = class.raidBuff

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

function Inputs.GetDependency(inputs, path, definition)
    if path == "slotPreference" then
        local key = RCC.Consumables.WeaponEnchant.GetPreferenceKey(definition.weaponSlot)

        return inputs.preferences[key]
    elseif path == "slotWeapon" then
        return inputs.weapons[definition.weaponSlot]
    elseif path == "categoryPreference" then
        return inputs.preferences[definition.key]
    elseif path == "categoryHistory" then
        return inputs.history[definition.key]
    end

    local value = inputs

    for key in path:gmatch("[^.]+") do
        value = value[key]
    end

    return value
end

function Inputs.ReadSelection(category)
    local definition = RCC.ConsumableCatalog.GetDefinition(category)
    local logic = definition.logic
    local dependencies = logic.Dependencies.selection
    local needed = {}

    for _, path in ipairs(dependencies or {}) do
        needed[path:match("^[^.]+")] = true
    end

    if logic.GetApplications then
        for _, path in ipairs(logic.Dependencies.observation) do
            needed[path:match("^[^.]+")] = true
        end
    end

    local now = GetTime()
    local inventory = Inputs.ReadInventory(Inputs.GetItemIDs(category))

    local inputs = {
        inventory = inventory,
        preferences = (needed.preferences or needed.slotPreference or needed.categoryPreference)
            and Inputs.ReadPreferences() or nil,
        instance = needed.instance and Inputs.ReadInstance() or nil,
        location = needed.location and Inputs.ReadLocation() or nil,
        class = needed.class and Inputs.ReadClass() or nil,
        spells = needed.spells and Inputs.ReadSpells(Inputs.GetSpellIDs(category)) or nil,
        playerSpellAuras = needed.playerSpellAuras
            and Inputs.ReadPlayerSpellAuras(Inputs.GetPlayerAuraSpellIDs(category)) or nil,
        weapons = needed.slotWeapon and {
            [definition.weaponSlot] = Inputs.ReadWeaponSlot(definition.weaponSlot, now),
        } or nil,
        cooldowns = needed.cooldowns
            and Inputs.ReadCooldowns(inventory, Inputs.GetCooldownItemIDs(category), now) or nil,
    }

    if needed.categoryHistory then
        if RCC.ConsumableHistory.Observe(inputs, definition) then
            RCC.ConsumableStateController.Invalidate("history", { nextFrame = true })
        end

        inputs.history = RCC.ConsumableHistory.Read()
    end

    return inputs
end
