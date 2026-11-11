--[[
Slash commands: /guildlens and /glens. A module adds a command with ns.AddCommand(name, handler, help...);
the handler gets the rest of the line. /glens alone opens the options window, /glens help lists the commands, and
so does an unknown one.
]]
local _, ns = ...
local L = ns.L

local commands = {}
local order = {L.CommandOptions, L.CommandHelp}

--- Adds a slash subcommand. help is one or more lines (already localized) for the list of commands.
function ns.AddCommand(name, handler, ...)
    commands[name] = handler
    for i = 1, select("#", ...) do
        table.insert(order, (select(i, ...)))
    end
end

local function PrintHelp()
    ns.Print(L.CommandsHeader)
    for _, line in ipairs(order) do
        DEFAULT_CHAT_FRAME:AddMessage("  " .. line)
    end
end

ns.OnLogin(function ()
    SLASH_GUILDLENS1 = "/guildlens"
    SLASH_GUILDLENS2 = "/glens"
    SlashCmdList.GUILDLENS = function (line)
        local name, rest = (line or ""):match("^%s*(%S*)%s*(.-)%s*$")
        if name == "" and ns.OpenOptions then
            ns.OpenOptions()
        elseif name == "" or name:lower() == "help" then
            PrintHelp()
        elseif commands[name:lower()] then
            commands[name:lower()](rest)
        else
            ns.Print(L.UnknownCommand:format(name))
            PrintHelp()
        end
    end
end)
