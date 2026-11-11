--[[
Guild chat lines can show the sender's class icon, level and zone in place of the channel's name ("[Guild]"), each
turned on by its own setting (chatIcon, chatLevel, chatZone); with none of them, guild chat is as the game shows it.

Each chat window's AddMessage is wrapped: in a line with the guild channel's link, the link's text is replaced from the
roster, so it stays clickable (a click starts a reply in guild chat). The sender is read from the line's player link.
Left as they are: lines of other channels (officer chat keeps its name, to tell it apart), senders not in the roster,
and text the client keeps from addons (secret values on modern clients).
Until the options window (0.2), the settings are set with /glens chat.
]]
local _, ns = ...
local L = ns.L

local GuildChat = {}
ns.GuildChat = GuildChat

local CHANNEL_LINK = "|Hchannel:GUILD|h"

-- /glens chat <part>: the setting behind each part.
local PARTS = {icon = "chatIcon", level = "chatLevel", zone = "chatZone"}
local PART_ORDER = {"icon", "level", "zone"}

local function Shown()
    local settings = ns.settings
    if not (settings.chatIcon or settings.chatLevel or settings.chatZone) then
        return nil
    end
    return {icon = settings.chatIcon, level = settings.chatLevel, zone = settings.chatZone}
end

--- The line with the guild channel's name replaced by the sender's parts in show, or the line as it was.
function GuildChat.Rewrite(text, show)
    local start, finish = text:find(CHANNEL_LINK .. ".-|h")
    if not start then
        return text
    end
    local name = text:match("|Hplayer:([^:|]+)", finish + 1)
    local member = name and ns.Roster.Find(name)
    local tag = member and ns.Lines.ChatTag(member, show)
    if not tag then
        return text
    end
    return text:sub(1, start - 1) .. CHANNEL_LINK .. tag .. "|h" .. text:sub(finish + 1)
end

local function Wrap(frame)
    local original = frame.AddMessage
    if type(original) ~= "function" then
        return
    end
    frame.AddMessage = function (self, text, ...)
        local show = Shown()
        if show and type(text) == "string" and not (issecretvalue and issecretvalue(text))
            and text:find(CHANNEL_LINK, 1, true) then
            local ok, rewritten = pcall(GuildChat.Rewrite, text, show)
            if ok then
                text = rewritten
            end
        end
        return original(self, text, ...)
    end
end

ns.OnLogin(function ()
    for index = 1, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. index]
        if frame then
            Wrap(frame)
        end
    end
end)

local function PrintState()
    local on = {}
    for _, part in ipairs(PART_ORDER) do
        if ns.settings[PARTS[part]] then
            table.insert(on, L["ChatPart_" .. part])
        end
    end
    ns.Print(#on > 0 and L.ChatShows:format(table.concat(on, ", ")) or L.ChatAsGame)
end

ns.AddCommand("chat", function (rest)
    local part = rest:lower()
    if PARTS[part] then
        ns.settings[PARTS[part]] = not ns.settings[PARTS[part]]
    elseif part == "off" then
        for _, setting in pairs(PARTS) do
            ns.settings[setting] = false
        end
    elseif part ~= "" then
        ns.Print(L.UnknownCommand:format("chat " .. rest))
        return
    end
    PrintState()
end, L.CommandChat, L.CommandChatOff)
