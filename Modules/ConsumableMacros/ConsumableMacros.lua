local _, RCC = ...

RCC.ConsumableMacros = RCC.ConsumableMacros or {}

local Macros = RCC.ConsumableMacros

local ActionKind = RCC.ConsumableActionKind
local Consumables = RCC.Consumables
local Inputs = RCC.ConsumableInputs
local GetItemIcon = C_Item.GetItemIconByID
local GetSpellInfo = C_Spell.GetSpellInfo

local UPDATE_DELAY = 0.2
local DEFAULT_MACRO_ICON = 134400
local MAX_MACRO_LENGTH = 255 -- Blizzard_MacroUI's macro editor limit
local MARKER_PATTERN = "^%s*#RCC%s*:%s*([%w_%-]+)%s*$"
local INLINE_MARKER_LINE_PATTERN = "^%s*#RCCI%s*:%s*([%w_%-]+)%s*(.-)%s*$"
local INLINE_USE_LINE_PATTERN = "^%s*/use%s+(.-)%s*item:%d+%s*;?%s*#RCCI%s*:%s*([%w_%-]+)%s*(.-)%s*$"
local INLINE_CONTINUATION_PATTERN = "^%s*/use%s+.-item:%d+%s+#RCCI%+%s*$"
local AUTOMATED_COMMENT = "#Automated by RCC: use '/rcc s' for settings"
local HEALING_POTION_RECUPERATE_MACRO = "healingPotionRecuperateMacro"
local updateScheduled = false
local updatePendingCombat = false
local updatingMacros = false
local macroLengthWarnings = {}
local eventFrame = CreateFrame("Frame")

local function normalizeToken(token)
    return token and token:lower():gsub("[%s_%-]", "")
end

local function trim(text)
    return text and text:match("^%s*(.-)%s*$") or ""
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

local function selectMacroAction(category, options)
    options = options or {}

    local definition = RCC.ConsumableCatalog.GetDefinition(category)
    local domain = Consumables[definition.domain]
    local inputs = Inputs.ReadSelection(category)
    local selection = domain.Select(inputs, definition)

    if selection.action and selection.action.kind == ActionKind.SPELL then
        return selection.action, getSpellIcon(selection.action.spellID)
    end

    local candidates = RCC.ConsumableSelection.GetAvailableCandidates(selection)
    local primary = candidates[1]

    if not primary then return end

    local action = {
        kind = ActionKind.ITEM,
        itemID = primary.itemID,
        itemIDs = { primary.itemID },
        targetSlot = definition.weaponSlot,
    }

    -- The selector already ordered overrides, the available preference, and
    -- compatible fallbacks. A backup, when allowed, uses that same ordering
    -- without editing inputs or selecting under a different preference policy.
    local fallback = candidates[2]

    if fallback and options.includeBackup ~= false then
        action.itemIDs[#action.itemIDs + 1] = fallback.itemID
    end

    return action, primary.icon or getItemIcon(primary.itemID)
end

local function foodAction()
    return selectMacroAction("food")
end

local function flaskAction()
    return selectMacroAction("flask")
end

local function augmentAction()
    -- Augment macros attempt one rune only. A cooling-down unlimited rune must
    -- fail normally, never fall through to a consumable or another rune.
    return selectMacroAction("augment", { includeBackup = false })
end

local function vantusAction()
    return selectMacroAction("vantus")
end

local function combatPotionAction()
    return selectMacroAction("combatpot")
end

local function healingPotionItemAction()
    return selectMacroAction("healpot")
end

local function healingPotionAction()
    local action, icon = healingPotionItemAction()
    local spellName = getSpellName(RCC.db.recuperateSpellID)

    if not spellName then return action, icon end

    return {
        type = HEALING_POTION_RECUPERATE_MACRO,
        itemID = action and action.itemID,
        itemIDs = action and action.itemIDs,
        spellID = RCC.db.recuperateSpellID,
        spellName = spellName,
    }, DEFAULT_MACRO_ICON
end

local function healthstoneAction()
    return selectMacroAction("hs")
end

local function raidBuffAction()
    local info = Consumables.RaidBuff.GetPlayerRaidBuffInfo()

    if not info or not info.spellID then return end

    return {
        kind = ActionKind.SPELL,
        spellID = info.spellID,
        spellName = getSpellName(info.spellID),
    }, info.iconID or getSpellIcon(info.spellID)
end

local function mainHandEnchantAction()
    return selectMacroAction("mainHandTempWeaponEnchant")
end

local function offHandEnchantAction()
    return selectMacroAction("offHandTempWeaponEnchant")
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
        description = "Uses the preferred augment rune when available, otherwise selects one automatically. Includes no backup and never switches runes because of a cooldown.",
        getAction = augmentAction,
        aliases = { "aug" },
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
        description = "Uses matching fleeting potions before the preferred item, with fallbacks limited to the same potion type (or family for utility potions).",
        getAction = combatPotionAction,
        inlineGetAction = combatPotionAction,
        aliases = { "combatpotion", "cp" },
        defaultIcon = function() return RCC.db.combatPotionIconID end,
    },
    {
        key = "healpot",
        label = "Healing Potion",
        macroName = "RCC Heal Pot",
        description = "Casts Recuperate out of combat and uses the selected healing potion with one backup in combat. Inside the Brawler's Guild, its potion becomes the primary when carried, with the normal potion as backup.",
        getAction = healingPotionAction,
        inlineGetAction = healingPotionItemAction,
        aliases = { "healingpotion", "hp" },
        defaultIcon = function() return RCC.db.healingPotionIconID end,
    },
    {
        key = "healthstone",
        label = "Healthstone",
        macroName = "RCC Healthstone",
        description = "Uses a carried Demonic Healthstone before a normal Healthstone, without a saved preference.",
        getAction = healthstoneAction,
        inlineGetAction = healthstoneAction,
        aliases = { "hs" },
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
        aliases = { "mhen" },
        defaultIcon = function() return RCC.db.weaponEnchantIconID end,
    },
    {
        key = "ohenchant",
        label = "Off-hand Enchant",
        macroName = "RCC OH Enchant",
        description = "Uses your selected off-hand weapon enchant item or spell.",
        getAction = offHandEnchantAction,
        aliases = { "ohen" },
        defaultIcon = function() return RCC.db.weaponEnchantIconID end,
    },
}

local MACRO_TYPES = {}
local INLINE_MACRO_TYPES = {}

local function registerMacroType(map, key, definition)
    local normalizedKey = normalizeToken(key)

    if normalizedKey then
        map[normalizedKey] = definition
    end
end

for i = 1, #MACRO_DEFINITIONS do
    local definition = MACRO_DEFINITIONS[i]
    local aliases = definition.aliases

    registerMacroType(MACRO_TYPES, definition.key, definition)

    if definition.inlineGetAction then
        registerMacroType(INLINE_MACRO_TYPES, definition.key, definition)
    end

    if aliases then
        for aliasIndex = 1, #aliases do
            local alias = aliases[aliasIndex]

            registerMacroType(MACRO_TYPES, alias, definition)

            if definition.inlineGetAction then
                registerMacroType(INLINE_MACRO_TYPES, alias, definition)
            end
        end
    end
end

function Macros.GetDefinitions()
    return MACRO_DEFINITIONS
end

local function getMacroType(token)
    return MACRO_TYPES[normalizeToken(token)]
end

local function getInlineMacroType(token)
    return INLINE_MACRO_TYPES[normalizeToken(token)]
end

local function printMessage(message)
    print("|" .. RCC.color .. "ffReadyCheckConsumables|r: " .. message)
end

local function canSaveMacro(name, body)
    if #body <= MAX_MACRO_LENGTH then
        macroLengthWarnings[name] = nil

        return true
    end

    if not macroLengthWarnings[name] then
        printMessage("Could not update " .. name .. ": the generated macro exceeds "
            .. MAX_MACRO_LENGTH .. " characters. Shorten the macro to make room "
            .. "for its item choices; it has been left unchanged.")
        macroLengthWarnings[name] = true
    end

    return false
end

local function getMacroLimits()
    return Constants.MacroConsts.MAX_ACCOUNT_MACROS,
           Constants.MacroConsts.MAX_CHARACTER_MACROS
end

local function getMacroRange(characterSpecific)
    if not GetNumMacros then return end

    local numAccountMacros, numCharacterMacros = GetNumMacros()
    local maxAccountMacros = getMacroLimits()

    if characterSpecific then
        return maxAccountMacros + 1, maxAccountMacros + numCharacterMacros
    end

    return 1, numAccountMacros
end

local function findManagedMacroIndex(key, characterSpecific)
    if not GetMacroInfo then return end

    local firstIndex, lastIndex = getMacroRange(characterSpecific)

    if not firstIndex then return end

    local macroType = getMacroType(key)

    if not macroType then return end

    for index = firstIndex, lastIndex do
        local _, _, body = GetMacroInfo(index)
        local token = findMarker(body)

        if getMacroType(token) == macroType then
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

local function itemUseLine(itemID, selectors)
    if selectors and selectors ~= "" then
        return "/use " .. selectors .. " item:" .. itemID
    end

    return "/use item:" .. itemID
end

local function appendItemUseLines(lines, action, selectors)
    for _, itemID in ipairs(action.itemIDs) do
        lines[#lines + 1] = itemUseLine(itemID, selectors)

        if action.targetSlot then
            lines[#lines + 1] = "/use " .. action.targetSlot
        end
    end
end

local function appendItemMacroLines(lines, action)
    lines[#lines + 1] = "#showtooltip item:" .. action.itemID
    appendItemUseLines(lines, action)
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
        lines[#lines + 1] = "/stopcasting [combat]"
        appendItemUseLines(lines, action, "[combat]")
    end
end

local function buildMacroBody(markerLine, action)
    local lines = { markerLine, AUTOMATED_COMMENT }

    if not action then
        lines[#lines + 1] = "#showtooltip"

        return table.concat(lines, "\n")
    end

    if action.kind == ActionKind.ITEM and action.itemID then
        appendItemMacroLines(lines, action)
    elseif action.kind == ActionKind.SPELL then
        appendSpellMacroLines(lines, action)
    elseif action.type == HEALING_POTION_RECUPERATE_MACRO then
        appendHealingPotionMacroLines(lines, action)
    end

    if #lines == 2 then
        lines[#lines + 1] = "#showtooltip"
    end

    local body = table.concat(lines, "\n")

    if #body > MAX_MACRO_LENGTH then
        -- The explanatory comment is optional; never truncate action lines.
        table.remove(lines, 2)
        body = table.concat(lines, "\n")
    end

    return body
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

local function resolveInlineMacro(token)
    local macroType = getInlineMacroType(token)

    if not macroType then return nil, nil, false end

    local action = macroType.inlineGetAction()

    return action, normalizeToken(token), true
end

local function normalizeInlineSelectors(selectors)
    local remaining = trim(selectors)
    local groups = {}

    if remaining == "" then
        return ""
    end

    while remaining ~= "" do
        remaining = remaining:gsub("^%s+", "")

        local group = remaining:match("^(%[[^%[%]\r\n;]*%])")

        if not group then return end

        groups[#groups + 1] = group
        remaining = remaining:sub(#group + 1)
    end

    return table.concat(groups, "")
end

local function parseInlineMacroLine(line)
    local useSelectors, useToken, markerSelectors =
        line:match(INLINE_USE_LINE_PATTERN)

    if useToken then
        useSelectors = normalizeInlineSelectors(useSelectors)
        markerSelectors = normalizeInlineSelectors(markerSelectors)

        if useSelectors == nil or markerSelectors == nil then return end

        if useSelectors ~= "" then
            return useToken, useSelectors
        end

        return useToken, markerSelectors
    end

    local markerToken, selectors = line:match(INLINE_MARKER_LINE_PATTERN)

    if not markerToken then return end

    selectors = normalizeInlineSelectors(selectors)

    if selectors == nil then return end

    return markerToken, selectors
end

local function buildInlineMacroLines(markerKey, selectors, action)
    local marker = "#RCCI:" .. markerKey

    if action then
        local lines = {}

        for index, itemID in ipairs(action.itemIDs) do
            local lineMarker = index == 1 and marker or "#RCCI+"
            lines[#lines + 1] = itemUseLine(itemID, selectors) .. " " .. lineMarker
        end

        return table.concat(lines, "\n")
    end

    if selectors and selectors ~= "" then
        return marker .. " " .. selectors
    end

    return marker
end

local function rewriteInlineMacroBody(body)
    local sourceLines = {}
    local lines = {}

    for line in (body .. "\n"):gmatch("([^\n]*)\n") do
        sourceLines[#sourceLines + 1] = line:gsub("\r", "")
    end

    local index = 1
    local foundMarker = false

    while index <= #sourceLines do
        local line = sourceLines[index]
        local token, selectors = parseInlineMacroLine(line)

        if token then
            local action, markerKey, recognized = resolveInlineMacro(token)

            if recognized then
                foundMarker = true
                lines[#lines + 1] = buildInlineMacroLines(
                    markerKey,
                    selectors,
                    action
                )

                -- Only adjacent #RCCI+ lines belong to this marker. Replace
                -- them together so repeated updates cannot accumulate backups
                -- or keep an old choice after the marker's conditions change.
                while sourceLines[index + 1]
                    and sourceLines[index + 1]:match(INLINE_CONTINUATION_PATTERN)
                do
                    index = index + 1
                end
            else
                lines[#lines + 1] = line
            end
        else
            lines[#lines + 1] = line
        end

        index = index + 1
    end

    local nextBody = table.concat(lines, "\n")

    if foundMarker and nextBody ~= body then
        return nextBody
    end
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

    if not canSaveMacro(macroType.macroName, body) then return false end

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

    if token then
        local action, resolvedIcon, recognized = resolveMacro(token)

        if markerLine and recognized then
            local nextBody = buildMacroBody(markerLine, action)
            local nextIcon = resolvedIcon or icon

            if not canSaveMacro(name, nextBody) then return end

            if nextBody ~= body or nextIcon ~= icon then
                EditMacro(index, nil, nextIcon, nextBody)
            end

            return
        end
    end

    local nextBody = rewriteInlineMacroBody(body)

    if nextBody and canSaveMacro(name, nextBody) then
        EditMacro(index, nil, nil, nextBody)
    end
end

function Macros.UpdateAll()
    if InCombatLockdown() then
        updatePendingCombat = true

        return
    end

    if not GetNumMacros or not GetMacroInfo or not EditMacro then return end

    local numAccountMacros, numCharacterMacros = GetNumMacros()
    local maxAccountMacros = getMacroLimits()

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
eventFrame:RegisterEvent("WEAPON_ENCHANT_CHANGED")
eventFrame:RegisterEvent("WEAPON_SLOT_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("UPDATE_MACROS")

-- Venue changes can happen between floors without leaving the instance.
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
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
