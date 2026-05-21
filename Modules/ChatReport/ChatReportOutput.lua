local _, RCC = ...

RCC.ChatReportOutput = RCC.ChatReportOutput or {}
local Output = RCC.ChatReportOutput

local F = RCC.F

local SendChatMessage = SendChatMessage
local format = format

local CHAT_MESSAGE_LIMIT = 220

function Output.ColorName(name, class)
    if not class then
        return name
    end

    local color = RAID_CLASS_COLORS[class]

    if not color then
        return name
    end

    return format("|c%s%s|r", color.colorStr, name)
end

function Output.Send(msg, toChat)
    if not msg or msg == "" then
        return
    end

    if not toChat then
        print(msg)

        return
    end

    local chatType = F.chatType()
    msg = msg:gsub("|c%x%x%x%x%x%x%x%x", "")
    msg = msg:gsub("|r", "")
    SendChatMessage(msg, chatType)
end

function Output.SendChunked(prefix, entries, toChat)
    if not entries or #entries == 0 then
        return
    end

    local line = prefix or ""
    local hasEntry = false

    for i = 1, #entries do
        local entry = entries[i]
        local separator = hasEntry and ", " or ""

        if hasEntry
            and #line + #separator + #entry > CHAT_MESSAGE_LIMIT
        then
            Output.Send(line, toChat)
            line = entry
        else
            line = line .. separator .. entry
        end

        hasEntry = true
    end

    Output.Send(line, toChat)
end
