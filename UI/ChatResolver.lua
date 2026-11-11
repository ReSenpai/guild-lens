--[[
Who a chat name menu is about. The menu's context has the name, the chat type and the chat line's id, but no GUID;
the GUID comes with the guild chat message itself, so it is remembered here by line id for the last MAX_LINES lines.
Only names in guild and officer chat count.
]]
local _, ns = ...

local ChatResolver = {}
ns.ChatResolver = ChatResolver

local MAX_LINES = 500
local GUILD_CHATS = {GUILD = true, OFFICER = true}

local guidByLine = {}
local lines = {}

--- The name and, when known, the GUID behind a menu's context; nil when it is not a name in guild chat.
function ChatResolver.Resolve(context)
    if type(context) ~= "table" or not GUILD_CHATS[context.chatType] or type(context.name) ~= "string"
        or context.name == "" then
        return nil
    end
    return context.name, guidByLine[tonumber(context.lineID)]
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_GUILD")
frame:RegisterEvent("CHAT_MSG_OFFICER")
frame:SetScript("OnEvent", function (_, _, _, _, _, _, _, _, _, _, _, _, lineID, guid)
    if type(lineID) ~= "number" or type(guid) ~= "string" then
        return
    end
    guidByLine[lineID] = guid
    table.insert(lines, lineID)
    if #lines > MAX_LINES then
        guidByLine[table.remove(lines, 1)] = nil
    end
end)
