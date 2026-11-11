--[[
Adds the member's lines to the game's own menu of a guild member's name, after its items, as titles (not clickable),
so none of the game's items move or change: names in guild chat, in the guild window's member list and in the guild
window's own chat. The menu system of the modern client (Menu.ModifyMenu: chat names open the "FRIEND" menu on
Forever, the guild window's list "COMMUNITIES_GUILD_MEMBER"); clients without it (Classic Era) get nothing yet.
An error here must not take the menu with it: it is reported and the menu opens as usual.

/glens debug records the context of every menu opened here (the last MAX_DEBUG) into GuildLensDB.debugMenus, to see
what a menu that shows nothing carries; it holds players' names, so it is off unless asked for.
]]
local _, ns = ...
local L = ns.L

local ContextMenu = {}
ns.ContextMenu = ContextMenu

-- The chat name menu, the guild window's member menus (the old guild frame's too, where a client has it) and the
-- community member menus a name in the guild window's chat may open.
local MENU_TAGS = {
    "MENU_UNIT_FRIEND", "MENU_UNIT_COMMUNITIES_GUILD_MEMBER", "MENU_UNIT_GUILD", "MENU_UNIT_GUILD_OFFLINE",
    "MENU_UNIT_COMMUNITIES_MEMBER", "MENU_UNIT_COMMUNITIES_WOW_MEMBER"
}
local MAX_DEBUG = 10

--- Adds the lines for the context's name, when it is a guild member's name.
function ContextMenu.Modify(_, root, context)
    local name, guid = ns.ChatResolver.Resolve(context)
    if not name then
        return
    end
    ns.Roster.Request()
    local lines = ns.Lines.ForName(name, guid)
    root:CreateDivider()
    for _, text in ipairs(lines) do
        root:CreateTitle(text)
    end
end

--- The context one level deep, as it can be kept in the saved variables.
local function Describe(context)
    local copy = {}
    if type(context) == "table" then
        for key, value in pairs(context) do
            local kind = type(value)
            copy[tostring(key)] = (kind == "string" or kind == "number" or kind == "boolean") and value or "<" .. kind .. ">"
        end
    end
    return copy
end

local function Record(tag, context)
    local list = ns.db.debugMenus or {}
    ns.db.debugMenus = list
    if #list >= MAX_DEBUG then
        table.remove(list, 1)
    end
    table.insert(list, {tag = tag, resolved = ns.ChatResolver.Resolve(context) ~= nil, context = Describe(context)})
end

ns.OnLogin(function ()
    if type(Menu) ~= "table" or type(Menu.ModifyMenu) ~= "function" then
        return
    end
    for _, tag in ipairs(MENU_TAGS) do
        Menu.ModifyMenu(tag, function (owner, root, context)
            local ok, problem = pcall(function ()
                if ns.settings.debug then
                    Record(tag, context)
                end
                ContextMenu.Modify(owner, root, context)
            end)
            if not ok then
                geterrorhandler()(problem)
            end
        end)
    end
end)

ns.AddCommand("debug", function ()
    ns.settings.debug = not ns.settings.debug
    if not ns.settings.debug then
        ns.db.debugMenus = nil
    end
    ns.Print(ns.settings.debug and L.DebugOn or L.DebugOff)
end, L.CommandDebug)
