--[[
Adds the member's lines to the game's own menu of a name in guild chat or of a member in the guild window, after its
items, as titles (not clickable), so none of the game's items move or change. The menu system of the modern client
(Menu.ModifyMenu: chat names open the "FRIEND" menu on Forever, the guild window "COMMUNITIES_GUILD_MEMBER"); clients
without it (Classic Era) get nothing yet.
An error here must not take the menu with it: it is reported and the menu opens as usual.
]]
local _, ns = ...
local L = ns.L

local ContextMenu = {}
ns.ContextMenu = ContextMenu

-- The chat name menu, and the guild window's member menus (the old guild frame's too, where a client has it).
local MENU_TAGS = {
    "MENU_UNIT_FRIEND", "MENU_UNIT_COMMUNITIES_GUILD_MEMBER", "MENU_UNIT_GUILD", "MENU_UNIT_GUILD_OFFLINE"
}

--- Adds the lines for the context's name, when it is a name in guild chat.
function ContextMenu.Modify(_, root, context)
    local name, guid = ns.ChatResolver.Resolve(context)
    if not name then
        return
    end
    ns.Roster.Request()
    local lines = ns.Lines.ForName(name, guid)
    root:CreateDivider()
    root:CreateTitle(L.MenuTitle)
    for _, text in ipairs(lines) do
        root:CreateTitle(text)
    end
end

ns.OnLogin(function ()
    if type(Menu) ~= "table" or type(Menu.ModifyMenu) ~= "function" then
        return
    end
    local function Modify(...)
        local ok, problem = pcall(ContextMenu.Modify, ...)
        if not ok then
            geterrorhandler()(problem)
        end
    end
    for _, tag in ipairs(MENU_TAGS) do
        Menu.ModifyMenu(tag, Modify)
    end
end)
