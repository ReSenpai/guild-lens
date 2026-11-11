--[[
Who a name menu is about, when it is about a guild member: a name in guild or officer chat, a member in the guild
window (J), or a name in the guild window's own chat (a community link of the guild's club).

A chat name's menu has the name, the chat type and the chat line's id, but no GUID; the GUID comes with the guild chat
message itself, so it is remembered here by line id for the last MAX_LINES lines. The guild window's menu has the GUID
itself.
]]
local _, ns = ...

local ChatResolver = {}
ns.ChatResolver = ChatResolver

local MAX_LINES = 500
local GUILD_CHATS = {GUILD = true, OFFICER = true}
-- Menus of a member in the guild window: the communities window on Forever, the old guild frame on other clients.
local GUILD_MENUS = {COMMUNITIES_GUILD_MEMBER = true, GUILD = true, GUILD_OFFLINE = true}

local guidByLine = {}
local lines = {}

--- Whether a menu's context comes from the guild's own club: a name in the guild window's chat, whose link is a
--- community link carrying the club's id rather than a chat type.
local function FromGuildClub(context)
    local clubId = context.communityClubID or context.clubId
        or (type(context.clubInfo) == "table" and context.clubInfo.clubId)
    if clubId == nil or not (C_Club and C_Club.GetGuildClubId) then
        return false
    end
    local guildClubId = C_Club.GetGuildClubId()
    return guildClubId ~= nil and tostring(guildClubId) == tostring(clubId)
end

--- The name and, when known, the GUID behind a menu's context; nil when it is not about a guild member.
function ChatResolver.Resolve(context)
    if type(context) ~= "table" or type(context.name) ~= "string" or context.name == "" then
        return nil
    end
    local guid = type(context.guid) == "string" and context.guid or nil
    if GUILD_MENUS[context.which] or FromGuildClub(context) then
        return context.name, guid
    end
    if GUILD_CHATS[context.chatType] then
        return context.name, guid or guidByLine[tonumber(context.lineID)]
    end
    return nil
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
