local _, RCC = ...

RCC.ConsumableActionBinder = RCC.ConsumableActionBinder or {}

local Binder = RCC.ConsumableActionBinder
local ActionKind = RCC.ConsumableActionKind
local Preferences = RCC.ConsumablePreferences
local Tooltips = RCC.ConsumableTooltips

Binder.Capabilities = {
    TEMPORARY = {
        allowCombat = false,
        allowSelectionItemUse = false,
    },
    ACTION_BAR = {
        allowCombat = true,
        allowSelectionItemUse = true,
    },
}

local function toggleClickedPreference(self, mouseButton)
    if mouseButton ~= "RightButton" or InCombatLockdown() then return end

    local preference = self.rccPreference

    if not preference then return end

    Preferences.Toggle(preference.key, preference.capacity, preference.choice)

    Tooltips.Refresh(self:GetParent())
end

local function setPreference(click, preference)
    click.rccPreference = preference

    if preference then
        click:SetScript("PreClick", toggleClickedPreference)
    else
        click:SetScript("PreClick", nil)
    end
end

local function clearLeftClickAction(click)
    click:SetAttribute("type1", nil)
    click:SetAttribute("item1", nil)
    click:SetAttribute("spell1", nil)
    click:SetAttribute("macrotext1", nil)
end

local function setClickShown(button, shown)
    button.clickEnabled = shown == true

    if not button.click then return end

    button.click:SetShown(shown == true)
end

local function disable(button)
    if not button or not button.click or InCombatLockdown() then
        return false
    end

    button.click.rccActionSignature = nil
    clearLeftClickAction(button.click)
    setPreference(button.click)
    setClickShown(button, false)

    return true
end

local function getItemMacro(itemID, targetSlot, allowCombat)
    local prefix = allowCombat and "" or "/stopmacro [combat]\n"

    if targetSlot then
        return prefix .. format(
            "/use item:%d\n/use %d",
            itemID,
            targetSlot
        )
    end

    return prefix .. format("/use item:%d", itemID)
end

local function setItemAction(button, action, capabilities)
    local click = button.click
    local preferenceKey = action.preferenceKey
    local selectionOnly = action.selectionOnly == true
    local allowUse = not selectionOnly
        or capabilities.allowSelectionItemUse == true
    local available = action.available ~= false

    if not allowUse then
        local signature = table.concat({
            "preference",
            tostring(action.itemID),
            tostring(preferenceKey or ""),
        }, "|")

        if click.rccActionSignature ~= signature then
            clearLeftClickAction(click)
            click.rccActionSignature = signature
        end

        setClickShown(button, preferenceKey ~= nil)

        return
    end

    local useMacro = action.targetSlot ~= nil
        or capabilities.allowCombat ~= true
    local signature = table.concat({
        useMacro and "itemMacro" or "item",
        tostring(action.itemID),
        tostring(action.targetSlot or ""),
        tostring(preferenceKey or ""),
        tostring(capabilities.allowCombat == true),
    }, "|")

    if click.rccActionSignature ~= signature then
        clearLeftClickAction(click)

        if useMacro then
            click:SetAttribute("type1", "macro")
            click:SetAttribute(
                "macrotext1",
                getItemMacro(
                    action.itemID,
                    action.targetSlot,
                    capabilities.allowCombat == true
                )
            )
        else
            click:SetAttribute("type1", "item")
            click:SetAttribute("item1", "item:" .. action.itemID)
        end

        click.rccActionSignature = signature
    end

    setClickShown(button, available)
end

local function setSpellAction(button, action)
    local spell = action.spellID or action.spellName

    if not spell then
        disable(button)

        return
    end

    local click = button.click
    local signature = "spell|" .. tostring(spell)

    if click.rccActionSignature ~= signature then
        clearLeftClickAction(click)
        setPreference(click)
        click:SetAttribute("type1", "spell")
        click:SetAttribute("spell1", spell)
        click.rccActionSignature = signature
    end

    setClickShown(button, action.available == true)
end

local function setSpellSequenceAction(button, action, capabilities)
    local prefix = capabilities.allowCombat and "" or "/stopmacro [combat]\n"
    local macro = prefix .. "/castsequence reset=combat " .. table.concat(action.spellNames, ", ")
    local click = button.click

    if click.rccActionSignature ~= macro then
        clearLeftClickAction(click)
        click:SetAttribute("type1", "macro")
        click:SetAttribute("macrotext1", macro)
        click.rccActionSignature = macro
    end

    setClickShown(button, true)
end

function Binder.Bind(button, action, capabilities, preference)
    if not button or not button.click then return true end
    if InCombatLockdown() then return false end

    capabilities = capabilities or Binder.Capabilities.TEMPORARY

    if not action or not action.kind then
        disable(button)
    elseif action.kind == ActionKind.ITEM and action.itemID then
        setItemAction(button, action, capabilities)
    elseif action.kind == ActionKind.SPELL then
        setSpellAction(button, action)
    elseif action.kind == ActionKind.SPELL_SEQUENCE then
        setSpellSequenceAction(button, action, capabilities)
    else
        disable(button)
    end

    setPreference(button.click, preference)

    if preference then
        -- Clearing an unavailable preference is still a valid right-click
        -- action; its missing item must never acquire a fallback left click.
        setClickShown(button, true)
    end

    Tooltips.Refresh(button)

    return true
end

function Binder.Disable(button)
    return disable(button)
end
