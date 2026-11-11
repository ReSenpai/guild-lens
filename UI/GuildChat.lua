--[[
Guild chat lines start with the sender's class icon and level instead of the channel's name ("[Guild]").

Each chat window's AddMessage is wrapped: in a line with the guild channel's link, the link's text is replaced from the
roster, so it stays clickable (a click starts a reply in guild chat). The sender is read from the line's player link.
Left as they are: lines of other channels (officer chat keeps its name, to tell it apart), senders not in the roster,
and text the client keeps from addons (secret values on modern clients). /glens chat turns it off and on.
]]
local _, ns = ...
local L = ns.L

local GuildChat = {}
ns.GuildChat = GuildChat

local CHANNEL_LINK = "|Hchannel:GUILD|h"

--- The line with the guild channel's name replaced by the sender's icon and level, or the line as it was.
function GuildChat.Rewrite(text)
    local start, finish = text:find(CHANNEL_LINK .. ".-|h")
    if not start then
        return text
    end
    local name = text:match("|Hplayer:([^:|]+)", finish + 1)
    local member = name and ns.Roster.Find(name)
    local tag = member and ns.Lines.ChatTag(member)
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
        if ns.settings.chatIcons and type(text) == "string"
            and not (issecretvalue and issecretvalue(text)) and text:find(CHANNEL_LINK, 1, true) then
            local ok, rewritten = pcall(GuildChat.Rewrite, text)
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

ns.AddCommand("chat", function ()
    ns.settings.chatIcons = not ns.settings.chatIcons
    ns.Print(ns.settings.chatIcons and L.ChatIconsOn or L.ChatIconsOff)
end, L.CommandChat)
