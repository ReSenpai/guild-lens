--[[
The options window (game options > AddOns, or /glens): what the menu of a guild member's name shows, and what guild
chat shows of the sender in place of "[Guild]". Every option is a setting of ns.settings by the same key.
]]
local addonName, ns = ...
local L = ns.L

local function Toggle(order, key, name, description)
    return {
        order = order,
        type = "toggle",
        width = "full",
        name = name,
        desc = description,
        get = function ()
            return ns.settings[key]
        end,
        set = function (_, value)
            ns.settings[key] = value
        end
    }
end

local function Section(order, name, help, toggles)
    local args = {help = {order = 0, type = "description", fontSize = "medium", name = help .. "\n"}}
    for index, toggle in ipairs(toggles) do
        args[toggle[1]] = Toggle(index, toggle[1], toggle[2], toggle[3])
    end
    return {order = order, type = "group", inline = true, name = name, args = args}
end

ns.options = {
    type = "group",
    name = L.OptionsTitle,
    args = {
        menu = Section(1, L.OptMenu, L.OptMenuHelp, {
            {"menuIcon", L.OptMenuIcon, L.OptMenuIconDesc},
            {"menuRace", L.OptMenuRace, L.OptMenuRaceDesc},
            {"menuRank", L.OptMenuRank, L.OptMenuRankDesc},
            {"menuStatus", L.OptMenuStatus, L.OptMenuStatusDesc},
            {"menuZone", L.OptMenuZone, L.OptMenuZoneDesc},
            {"menuProfessions", L.OptMenuProfessions, L.OptMenuProfessionsDesc},
            {"menuNote", L.OptMenuNote, L.OptMenuNoteDesc}
        }),
        chat = Section(2, L.OptChat, L.OptChatHelp, {
            {"chatIcon", L.OptChatIcon, L.OptChatIconDesc},
            {"chatLevel", L.OptChatLevel, L.OptChatLevelDesc},
            {"chatZone", L.OptChatZone, L.OptChatZoneDesc}
        })
    }
}

ns.OnLogin(function ()
    local ConfigDialog = LibStub("AceConfigDialog-3.0")
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(addonName, ns.options)
    ConfigDialog:AddToBlizOptions(addonName, L.OptionsTitle)
    ns.OpenOptions = function ()
        ConfigDialog:Open(addonName)
    end
end)
