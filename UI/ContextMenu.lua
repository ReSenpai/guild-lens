--[[
Adds the member's lines to the game's own menu of a name in guild chat, after its items, as titles (not clickable),
so none of the game's items move or change. The menu system of the modern client (Menu.ModifyMenu, the "FRIEND"
menu that chat names open on Forever); clients without it (Classic Era) get nothing yet.
An error here must not take the menu with it: it is reported and the menu opens as usual.
]]
local _, ns = ...
local L = ns.L

local ContextMenu = {}
ns.ContextMenu = ContextMenu

local MENU_TAG = "MENU_UNIT_FRIEND"

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
    Menu.ModifyMenu(MENU_TAG, function (...)
        local ok, problem = pcall(ContextMenu.Modify, ...)
        if not ok then
            geterrorhandler()(problem)
        end
    end)
end)
