local _, RCC = ...

RCC.ConsumableMacros = RCC.ConsumableMacros or {}

local Macros = RCC.ConsumableMacros

local ActionType = RCC.ConsumableActionType
local CacheKey = RCC.ConsumableItemCacheKey
local Consumables = RCC.Consumables
local GetItemIcon = C_Item.GetItemIconByID
local GetSpellInfo = C_Spell.GetSpellInfo

local MAIN_HAND_INVENTORY_SLOT = 16
local OFF_HAND_INVENTORY_SLOT = 17
local RECUPERATE_SPELL_ID = 1231411
local UPDATE_DELAY = 0.2
local DEFAULT_MAX_ACCOUNT_MACROS = 120
local DEFAULT_MAX_CHARACTER_MACROS = 30
local DEFAULT_MACRO_ICON = 134400
local MARKER_PATTERN = "^%s*#RCC%s*:%s*([%w_%-]+)%s*$"
local AUTOMATED_COMMENT = "#Automated by RCC: use '/rcc s' for settings"
local HEALING_POTION_RECUPERATE_MACRO = "healingPotionRecuperateMacro"
local updateScheduled = false
local updatePendingCombat = false
local updatingMacros = false
local eventFrame = CreateFrame("Frame")

local function normalizeToken(token)
    return token and token:lower():gsub("[%s_%-]", "")
end

local function findMarker(body)
    if not body then return end

    for line in (body .. "\n"):gmatch("([^\n]*)\n") do
        line = line:gsub("\r", "")

        local token = line:match(MARKER_PATTERN)

        if token then
            return token, line
        end
    end
end

local function getSpellName(spellID)
    if not spellID then return end

    local spellInfo = GetSpellInfo(spellID)

    return spellInfo and spellInfo.name
end

local function getSpellIcon(spellID)
    if not spellID then return end

    local spellInfo = GetSpellInfo(spellID)

    return spellInfo and spellInfo.iconID
end

local function getItemIcon(itemID)
    return itemID and GetItemIcon(itemID)
end

local function itemAction(candidate, cacheKey)
    if not candidate or not candidate.itemID then return end

    return {
        type = ActionType.ITEM_MACRO,
        itemID = candidate.itemID,
        cacheKey = cacheKey,
    }, candidate.icon or getItemIcon(candidate.itemID)
end

local function foodAction()
    return itemAction(
        Consumables.Food.GetItemCandidate(true),
        CacheKey.FOOD
    )
end

local function flaskAction()
    return itemAction(
        Consumables.Flask.GetItemCandidate(),
        CacheKey.FLASK
    )
end

local function augmentAction()
    return itemAction(
        Consumables.Augment.GetItemCandidate(true),
        CacheKey.AUGMENT
    )
end

local function vantusAction()
    local runeIDs = Consumables.Vantus.GetRuneIDsForCurrentRaid()

    if not runeIDs then return end

    return itemAction(
        Consumables.Vantus.GetItemCandidate(runeIDs, true),
        CacheKey.VANTUS
    )
end

local function combatPotionAction()
    return itemAction(
        Consumables.CombatPotion.GetItemCandidate(),
        CacheKey.COMBAT_POTION
    )
end

local function healingPotionAction()
    local candidate = Consumables.HealingPotion.GetItemCandidate()
    local spellName = getSpellName(RECUPERATE_SPELL_ID)

    if not spellName then
        return itemAction(candidate, CacheKey.HEALING_POTION)
    end

    local action = {
        type = HEALING_POTION_RECUPERATE_MACRO,
        itemID = candidate and candidate.itemID,
        spellID = RECUPERATE_SPELL_ID,
        spellName = spellName,
    }

    return action, DEFAULT_MACRO_ICON
end

local function healthstoneAction()
    return itemAction(Consumables.Healthstone.GetItemCandidate())
end

local function raidBuffAction()
    local info = Consumables.RaidBuff.GetPlayerRaidBuffInfo()

    if not info or not info.spellID then return end

    return {
        type = ActionType.SPELL,
        spellID = info.spellID,
        spellName = getSpellName(info.spellID),
    }, info.iconID or getSpellIcon(info.spellID)
end

local function weaponEnchantAction(slotID)
    local action = Consumables.WeaponEnchant.GetActionForSlot(slotID)

    if not action then return end

    local icon

    if action.itemID then
        icon = getItemIcon(action.itemID)
    elseif action.spellID then
        icon = getSpellIcon(action.spellID)
    end

    return action, icon
end

local function mainHandEnchantAction()
    return weaponEnchantAction(MAIN_HAND_INVENTORY_SLOT)
end

local function offHandEnchantAction()
    return weaponEnchantAction(OFF_HAND_INVENTORY_SLOT)
end

local MACRO_DEFINITIONS = {
    {
        key = "food",
        label = "Food",
        macroName = "RCC Food",
        description = "Uses the preferred food item when available, otherwise the best available food.",
        getAction = foodAction,
        defaultIcon = function() return RCC.db.foodIconID end,
    },
    {
        key = "flask",
        label = "Flask",
        macroName = "RCC Flask",
        description = "Uses the preferred flask family when available, otherwise the best available flask.",
        getAction = flaskAction,
        defaultIcon = function() return RCC.db.flaskIconID end,
    },
    {
        key = "augment",
        label = "Augment Rune",
        macroName = "RCC Augment",
        description = "Uses the preferred augment rune when available, otherwise the best available augment rune.",
        getAction = augmentAction,
        defaultIcon = function() return RCC.db.augmentIconID end,
    },
    {
        key = "vantus",
        label = "Vantus Rune",
        macroName = "RCC Vantus",
        description = "Uses the preferred Vantus rune for the current raid when available, otherwise the best available current-raid rune.",
        getAction = vantusAction,
        defaultIcon = function() return RCC.db.vantusIconID end,
    },
    {
        key = "combatpot",
        label = "Combat Potion",
        macroName = "RCC Combat Pot",
        description = "Uses the preferred combat potion when available, otherwise the best available combat potion.",
        getAction = combatPotionAction,
        defaultIcon = function() return RCC.db.combatPotionIconID end,
    },
    {
        key = "healpot",
        label = "Healing Potion",
        macroName = "RCC Heal Pot",
        description = "Casts Recuperate out of combat and uses the preferred healing potion in combat when available, otherwise the best available healing potion.",
        getAction = healingPotionAction,
        defaultIcon = function() return RCC.db.healingPotionIconID end,
    },
    {
        key = "hs",
        label = "Healthstone",
        macroName = "RCC Healthstone",
        description = "Uses the best available healthstone variant.",
        getAction = healthstoneAction,
        defaultIcon = function() return RCC.db.healthstoneIconID end,
    },
    {
        key = "raidbuff",
        label = "Raid Buff",
        macroName = "RCC Raid Buff",
        description = "Casts the raid buff provided by your current class.",
        getAction = raidBuffAction,
        defaultIcon = function() return RCC.db.raidBuffIconID end,
    },
    {
        key = "mhenchant",
        label = "Main-hand Enchant",
        macroName = "RCC MH Enchant",
        description = "Uses your selected main-hand weapon enchant item or spell.",
        getAction = mainHandEnchantAction,
        defaultIcon = function() return RCC.db.weaponEnchantIconID end,
    },
    {
        key = "ohenchant",
        label = "Off-hand Enchant",
        macroName = "RCC OH Enchant",
        description = "Uses your selected off-hand weapon enchant item or spell.",
        getAction = offHandEnchantAction,
        defaultIcon = function() return RCC.db.weaponEnchantIconID end,
    },
}

local MACRO_TYPES = {}

for i = 1, #MACRO_DEFINITIONS do
    local definition = MACRO_DEFINITIONS[i]

    MACRO_TYPES[definition.key] = definition
end

function Macros.GetDefinitions()
    return MACRO_DEFINITIONS
end

local function getMacroType(token)
    return MACRO_TYPES[normalizeToken(token)]
end

local function printMessage(message)
    print("|" .. RCC.color .. "ffReadyCheckConsumables|r: " .. message)
end

local function getMacroLimits()
    return MAX_ACCOUNT_MACROS or DEFAULT_MAX_ACCOUNT_MACROS,
           MAX_CHARACTER_MACROS or DEFAULT_MAX_CHARACTER_MACROS
end

local function getMacroRange(characterSpecific)
    if not GetNumMacros then return end

    local numAccountMacros, numCharacterMacros = GetNumMacros()
    local maxAccountMacros = MAX_ACCOUNT_MACROS
        or DEFAULT_MAX_ACCOUNT_MACROS

    if characterSpecific then
        return maxAccountMacros + 1, maxAccountMacros + numCharacterMacros
    end

    return 1, numAccountMacros
end

local function findManagedMacroIndex(key, characterSpecific)
    if not GetMacroInfo then return end

    local firstIndex, lastIndex = getMacroRange(characterSpecific)

    if not firstIndex then return end

    local normalizedKey = normalizeToken(key)

    for index = firstIndex, lastIndex do
        local _, _, body = GetMacroInfo(index)
        local token = findMarker(body)

        if normalizeToken(token) == normalizedKey then
            return index
        end
    end
end

function Macros.CanCreateManagedMacro(characterSpecific)
    if not GetNumMacros or not CreateMacro then return false end

    local numAccountMacros, numCharacterMacros = GetNumMacros()
    local maxAccountMacros, maxCharacterMacros = getMacroLimits()

    if characterSpecific then
        return numCharacterMacros < maxCharacterMacros
    end

    return numAccountMacros < maxAccountMacros
end

local function appendItemMacroLines(lines, itemID, targetSlot)
    lines[#lines + 1] = "#showtooltip item:" .. itemID
    lines[#lines + 1] = "/use item:" .. itemID

    if targetSlot then
        lines[#lines + 1] = "/use " .. targetSlot
    end
end

local function appendSpellMacroLines(lines, action)
    local spellName = action.spellName or getSpellName(action.spellID)

    if not spellName then return end

    lines[#lines + 1] = "#showtooltip " .. spellName
    lines[#lines + 1] = "/cast " .. spellName
end

local function appendHealingPotionMacroLines(lines, action)
    local spellName = action.spellName or getSpellName(action.spellID)
    local itemID = action.itemID

    if not spellName then return end

    if itemID then
        lines[#lines + 1] = "#showtooltip [nocombat] "
            .. spellName .. "; [combat] item:" .. itemID
    else
        lines[#lines + 1] = "#showtooltip [nocombat] " .. spellName
    end

    lines[#lines + 1] = "/cast [nocombat] " .. spellName

    if itemID then
        lines[#lines + 1] = "/use [combat] item:" .. itemID
    end
end

local function buildMacroBody(markerLine, action)
    local lines = { markerLine, AUTOMATED_COMMENT }

    if not action then
        lines[#lines + 1] = "#showtooltip"

        return table.concat(lines, "\n")
    end

    if action.type == ActionType.ITEM_MACRO and action.itemID then
        appendItemMacroLines(lines, action.itemID, action.targetSlot)
    elseif action.type == ActionType.WEAPON_ENCHANT_ITEM and action.itemID then
        appendItemMacroLines(lines, action.itemID, action.targetSlot)
    elseif action.type == ActionType.SPELL then
        appendSpellMacroLines(lines, action)
    elseif action.type == HEALING_POTION_RECUPERATE_MACRO then
        appendHealingPotionMacroLines(lines, action)
    end

    if #lines == 2 then
        lines[#lines + 1] = "#showtooltip"
    end

    return table.concat(lines, "\n")
end

local function resolveMacro(token)
    local macroType = getMacroType(token)

    if not macroType then return nil, nil, false end

    local action, icon = macroType.getAction()

    if not icon and macroType.defaultIcon then
        icon = macroType.defaultIcon()
    end

    return action, icon, true
end

function Macros.CreateManagedMacro(key, characterSpecific)
    local macroType = getMacroType(key)

    if not macroType then return false end

    if InCombatLockdown() then
        printMessage("Macros cannot be created or updated during combat.")

        return false
    end

    if not CreateMacro or not EditMacro or not GetNumMacros
        or not GetMacroInfo
    then
        printMessage("Macro APIs are not available.")

        return false
    end

    local action, icon = macroType.getAction()

    if not icon and macroType.defaultIcon then
        icon = macroType.defaultIcon()
    end

    local body = buildMacroBody("#RCC:" .. macroType.key, action)
    local macroIcon = icon or DEFAULT_MACRO_ICON
    local existingIndex = findManagedMacroIndex(
        macroType.key,
        characterSpecific
    )

    if existingIndex then
        local editedIndex = EditMacro(existingIndex, nil, macroIcon, body)

        if not editedIndex then
            printMessage("Could not update " .. macroType.label .. " macro.")

            return false
        end

        printMessage("Updated " .. macroType.label .. " macro.")
        Macros.ScheduleUpdate()

        return true
    end

    if not Macros.CanCreateManagedMacro(characterSpecific) then
        local macroTypeName = characterSpecific and "character" or "shared"

        printMessage("No " .. macroTypeName .. " macro slots are available.")

        return false
    end

    local macroIndex = CreateMacro(
        macroType.macroName,
        macroIcon,
        body,
        characterSpecific == true
    )

    if not macroIndex then
        printMessage("Could not create " .. macroType.label .. " macro.")

        return false
    end

    printMessage("Created " .. macroType.label .. " macro.")
    Macros.ScheduleUpdate()

    return true
end

local function updateMacro(index)
    local name, icon, body = GetMacroInfo(index)

    if not name or not body then return end

    local token, markerLine = findMarker(body)

    if not token then return end

    local action, resolvedIcon, recognized = resolveMacro(token)

    if not markerLine or not recognized then return end

    local nextBody = buildMacroBody(markerLine, action)
    local nextIcon = resolvedIcon or icon

    if nextBody ~= body or nextIcon ~= icon then
        EditMacro(index, nil, nextIcon, nextBody)
    end
end

function Macros.UpdateAll()
    if InCombatLockdown() then
        updatePendingCombat = true

        return
    end

    if not GetNumMacros or not GetMacroInfo or not EditMacro then return end

    local numAccountMacros, numCharacterMacros = GetNumMacros()
    local maxAccountMacros = MAX_ACCOUNT_MACROS
        or DEFAULT_MAX_ACCOUNT_MACROS

    updatingMacros = true

    for index = 1, numAccountMacros do
        updateMacro(index)
    end

    for index = maxAccountMacros + 1,
                maxAccountMacros + numCharacterMacros
    do
        updateMacro(index)
    end

    updatingMacros = false
end

function Macros.ScheduleUpdate()
    if updateScheduled then return end

    updateScheduled = true

    C_Timer.After(UPDATE_DELAY, function()
        updateScheduled = false
        Macros.UpdateAll()
    end)
end

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("UPDATE_MACROS")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "UPDATE_MACROS" and updatingMacros then return end

    if event == "PLAYER_REGEN_ENABLED" then
        if updatePendingCombat then
            updatePendingCombat = false
            Macros.ScheduleUpdate()
        end

        return
    end

    Macros.ScheduleUpdate()
end)
