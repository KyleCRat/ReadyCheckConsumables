local _, RCC = ...

RCC.ProfileSettings = {}

local ProfileSettings = RCC.ProfileSettings
local Profiles = RCC.Profiles
local NO_PROFILE_SELECTION = ""

local PROFILE_LABELS = {
    global = "Global",
    character = "Character",
    spec = "Specialization",
    class = "Class",
    realm = "Realm",
    faction = "Faction",
}

local ERRORS = {
    INVALID_NAME = "Enter a valid profile name",
    PROFILE_EXISTS = "A profile with that name already exists",
    PROFILE_NOT_FOUND = "That profile no longer exists",
    ACTIVE_PROFILE = "Select another profile before deleting this one",
}

local function reportError(message)
    print("|" .. RCC.color .. "ffReadyCheckConsumables|r: " .. message)
end

local function canEdit()
    local reason = Profiles.GetEditBlockReason()

    if reason then
        reportError(reason)

        return false
    end

    return true
end

local function finishOperation(result, errorCode)
    if not result then
        reportError(ERRORS[errorCode] or "The profile could not be changed")
    end

    Profiles.SyncSettingsPages()

    return result
end

local function getChoiceKey(profile)
    local ref = profile.profileRef

    return ref.kind .. ":" .. (ref.profile or ref.name)
end

local function getProfileLabel(profile)
    local ref = profile.profileRef

    if ref.kind == "user" then
        return "Custom: " .. profile.displayName
    end

    if ref.profile == "global" then return PROFILE_LABELS.global end

    return PROFILE_LABELS[ref.profile] .. ": " .. profile.displayName
end

local function findProfile(choiceKey)
    for _, profile in ipairs(RCC.profileManager:GetProfiles()) do
        if getChoiceKey(profile) == choiceKey then
            return profile
        end
    end
end

local function sameProfile(left, right)
    local leftID, rightID = left.profileID, right.profileID

    return leftID.kind == rightID.kind
        and leftID.profile == rightID.profile
        and leftID.key == rightID.key
        and leftID.name == rightID.name
end

local function canRename(profile)
    return profile.canRename
end

local function canDelete(profile)
    return profile.canDelete
end

local function getChoices(filter, placeholder)
    local choices = {}

    if placeholder then
        choices[1] = { label = placeholder, value = NO_PROFILE_SELECTION }
    end

    for _, profile in ipairs(RCC.profileManager:GetProfiles()) do
        if not filter or filter(profile) then
            choices[#choices + 1] = {
                label = getProfileLabel(profile),
                value = getChoiceKey(profile),
            }
        end
    end

    return choices
end

local function selectProfile(choiceKey)
    if canEdit() then
        local profile = findProfile(choiceKey)

        if profile then
            finishOperation(RCC.profileManager:SetProfile(profile.profileRef))
        else
            reportError(ERRORS.PROFILE_NOT_FOUND)
        end
    end

    Profiles.SyncSettingsPages()
end

-- Dialogs retain detached descriptors. Check their exact identities on accept:
-- a specialization change must not redirect a copy or reset to another profile.
local function validateDialogProfiles(expectedProfiles, activeProfile)
    if not canEdit() then return false end

    if not sameProfile(activeProfile, RCC.profileManager:GetActiveProfile()) then
        reportError("Your active profile changed; please try again")

        return false
    end

    for _, expected in ipairs(expectedProfiles) do
        local current = findProfile(getChoiceKey(expected))

        if not current or not sameProfile(expected, current) then
            reportError("The selected profile changed; please try again")

            return false
        end
    end

    return true
end

local function showNameInput(text, acceptText, expectedProfiles, onAccept)
    if not canEdit() then return end

    local activeProfile = RCC.profileManager:GetActiveProfile()

    StaticPopup_ShowCustomGenericInputBox({
        text = "%s",
        text_arg1 = text,
        acceptText = acceptText,
        maxLetters = 0,
        callback = function(name)
            if validateDialogProfiles(expectedProfiles, activeProfile) then
                onAccept(name)
            end
        end,
    })
end

local function confirmChange(text, acceptText, expectedProfiles, operation)
    if not canEdit() then return end

    local activeProfile = RCC.profileManager:GetActiveProfile()

    StaticPopup_ShowCustomGenericConfirmation({
        text = "%s",
        text_arg1 = text,
        acceptText = acceptText,
        cancelText = CANCEL,
        showAlert = true,
        callback = function()
            if validateDialogProfiles(expectedProfiles, activeProfile) then
                finishOperation(operation())
            end
        end,
    })
end

local function createProfile()
    showNameInput("Enter a name for the new profile.", "Create", {}, function(name)
        local ref = finishOperation(RCC.profileManager:CreateProfile(name))

        if ref then
            finishOperation(RCC.profileManager:SetProfile(ref))
        end
    end)
end

local function copyIntoActiveProfile()
    if not canEdit() then return end

    local target = RCC.profileManager:GetActiveProfile()
    local options = {}

    for _, profile in ipairs(RCC.profileManager:GetProfiles()) do
        if not profile.active then
            options[#options + 1] = {
                text = getProfileLabel(profile),
                value = profile,
            }
        end
    end

    if #options == 0 then
        reportError("There is no other profile to copy")

        return
    end

    StaticPopup_ShowGenericDropdown(
        "Choose a profile to copy into " .. getProfileLabel(target)
            .. ". This replaces its settings and profile-stored item preferences. "
            .. "Character preferences will not change. This cannot be undone.",
        function(source)
            if validateDialogProfiles({ source, target }, target) then
                finishOperation(RCC.profileManager:CopyProfile(source.profileRef, target.profileRef))
            end
        end,
        options,
        true -- Require confirmation before replacing settings.
    )
end

local function resetActiveProfile()
    local target = RCC.profileManager:GetActiveProfile()

    if not target.canReset then return end

    confirmChange(
        "Reset " .. getProfileLabel(target) .. " to RCC's defaults? "
            .. "All settings and profile-stored item preferences will be removed. "
            .. "Character preferences will not change. This cannot be undone.",
        "Reset",
        { target },
        function()
            return RCC.profileManager:ResetProfile(target.profileRef)
        end
    )
end

local function selectRenameProfile(choiceKey)
    if choiceKey == NO_PROFILE_SELECTION then return end

    -- These dropdowns launch actions, not persistent selections. Clear the
    -- displayed choice after the menu finishes handling this click.
    C_Timer.After(0, Profiles.SyncSettingsPages)

    local target = findProfile(choiceKey)

    if not target or not target.canRename then
        reportError("Choose an existing custom profile to rename")

        return
    end

    showNameInput(
        "Enter a new name for " .. getProfileLabel(target) .. ".",
        "Rename",
        { target },
        function(name)
            finishOperation(RCC.profileManager:RenameProfile(target.profileRef, name))
        end
    )
end

local function selectDeleteProfile(choiceKey)
    if choiceKey == NO_PROFILE_SELECTION then return end

    C_Timer.After(0, Profiles.SyncSettingsPages)

    local target = findProfile(choiceKey)

    if not target or not target.canDelete then
        reportError("Choose an inactive custom profile to delete")

        return
    end

    local usage, errorCode = RCC.profileManager:GetProfileUsage(target.profileRef)

    if not usage then
        reportError(ERRORS[errorCode] or "The profile's usage could not be checked")

        return
    end

    local text = "Delete " .. getProfileLabel(target)
        .. "? Its settings and profile-stored item preferences will be removed."

    if usage.selectionCount > 0 then
        text = text .. " " .. usage.selectionCount
            .. " character(s) using this profile will return to Global on their next login."
    end

    confirmChange(
        text .. " Character preferences will not change. This cannot be undone.",
        "Delete",
        { target },
        function()
            return RCC.profileManager:DeleteProfile(target.profileRef)
        end
    )
end

local function addPreferenceScopeControl(flow)
    return flow:AddControl("checkbox", {
        label = "Use profile-specific consumable preferences",
        value = RCC.ConsumableFrameItemCache.UsesProfilePreferences(),
        tooltip = "For this character, use and save consumable item choices in the "
            .. "selected settings profile. When off, item preferences remain "
            .. "character-specific across profile changes. Switching this option "
            .. "does not copy or delete either set of preferences.",
        onChanged = function(checked)
            if canEdit() then
                RCC.ConsumableFrameItemCache.SetUseProfilePreferences(checked)
            end

            Profiles.SyncSettingsPages()
        end,
    })
end

function ProfileSettings.AddSection(frame, flow)
    flow:AddSection("Profiles", { marginTop = 0 })

    local selector = flow:AddControl("dropdown", {
        label = "Active Profile",
        choices = getChoices(),
        value = getChoiceKey(RCC.profileManager:GetActiveProfile()),
        onChanged = selectProfile,
        tooltip = "Choose this character's settings and positions. Global shares "
            .. "one setup across characters; Character keeps an individual setup. "
            .. "Specialization shares by spec and switches automatically with your spec. "
            .. "Unused profiles start with RCC's defaults. Item preferences stay "
            .. "character-specific unless you enable the option below.",
    })

    local buttons = flow:BeginColumns({ count = 3, columnGap = 8, marginTop = 4 })
    local createButton = buttons[1]:AddControl("button", {
        text = "New Profile",
        tooltip = "Create and select a new profile with default settings",
        onClick = createProfile,
    }, { marginBottom = 0 })
    local copyButton = buttons[2]:AddControl("button", {
        text = "Copy Into Active",
        tooltip = "Replace the active profile's settings and profile-stored item "
            .. "preferences with another profile's. Character preferences are not changed.",
        onClick = copyIntoActiveProfile,
    }, { marginBottom = 0 })
    local resetButton = buttons[3]:AddControl("button", {
        text = "Reset Active",
        tooltip = "Restore RCC's default settings and clear profile-stored item "
            .. "preferences. Character preferences are not changed.",
        onClick = resetActiveProfile,
    }, { marginBottom = 0 })
    buttons:Finish({ marginBottom = 4 })

    local actions = flow:BeginColumns()
    local renameSelector = actions.left:AddControl("dropdown", {
        label = "Rename Profile",
        choices = getChoices(canRename, "Choose a profile..."),
        value = NO_PROFILE_SELECTION,
        tooltip = "Choose a custom profile to rename",
        onChanged = selectRenameProfile,
    })
    local deleteSelector = actions.right:AddControl("dropdown", {
        label = "Delete Profile",
        choices = getChoices(canDelete, "Choose a profile..."),
        value = NO_PROFILE_SELECTION,
        tooltip = "Choose an inactive custom profile to delete",
        onChanged = selectDeleteProfile,
    })
    actions:Finish({ marginBottom = 12 })

    local preferenceScope = addPreferenceScopeControl(flow)

    function frame:Sync()
        local active = RCC.profileManager:GetActiveProfile()
        local choices = getChoices()
        local renameChoices = getChoices(canRename, "Choose a profile...")
        local deleteChoices = getChoices(canDelete, "Choose a profile...")
        local reason = Profiles.GetEditBlockReason()
        local enabled = reason == nil

        selector:SetChoices(choices)
        selector:SetValue(getChoiceKey(active))
        selector:SetControlEnabled(enabled, reason)
        createButton:SetControlEnabled(enabled, reason)
        copyButton:SetControlEnabled(
            enabled and #choices > 1,
            reason or "There is no other profile to copy"
        )
        resetButton:SetControlEnabled(enabled and active.canReset, reason)

        renameSelector:SetChoices(renameChoices)
        renameSelector:SetValue(NO_PROFILE_SELECTION)
        renameSelector:SetControlEnabled(
            enabled and #renameChoices > 1,
            reason or "There is no custom profile to rename"
        )

        deleteSelector:SetChoices(deleteChoices)
        deleteSelector:SetValue(NO_PROFILE_SELECTION)
        deleteSelector:SetControlEnabled(
            enabled and #deleteChoices > 1,
            reason or "There is no inactive custom profile to delete"
        )

        preferenceScope:SetValue(RCC.ConsumableFrameItemCache.UsesProfilePreferences())
        preferenceScope:SetControlEnabled(enabled, reason)
    end

    frame.OnRefresh = frame.Sync
    frame:HookScript("OnShow", frame.Sync)
    Profiles.RegisterSettingsPage(frame)
    frame:Sync()
end
