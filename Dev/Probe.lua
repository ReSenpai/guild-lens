--[[
Technical reconnaissance, stage 1 of the design: what this client offers for the guild roster, the menu of a name in
chat and guild chat itself. Everything is recorded into GuildLensDB.probe, which the game writes to
WTF\Account\<account>\SavedVariables\GuildLens.lua on /reload or logout, so it can be read outside the game.

- From login: which of the candidate menus open (Menu.ModifyMenu, with a "GuildLens probe: <menu>" title line added to
  each, so the right menu can be seen in the game) and with what context; calls of the old menu and chat link
  functions; guild events; who writes in guild chat (the sender's name format, not the text).
- /glens probe: a snapshot of the client, the guild and a few roster rows with every value GetGuildRosterInfo returns.

Development only: this file goes away before the first release.
]]
local _, ns = ...
local L = ns.L

local Probe = {}
ns.Probe = Probe

local MAX_SAMPLES = 15
local MAX_STRING = 200

-- Menu tags of the modern menu system worth watching: the chat name menu is one of them (likely FRIEND).
local MENU_TAGS = {
    "MENU_UNIT_FRIEND", "MENU_UNIT_FRIEND_OFFLINE", "MENU_UNIT_CHAT_ROSTER", "MENU_UNIT_PLAYER", "MENU_UNIT_SELF",
    "MENU_UNIT_TARGET", "MENU_UNIT_PARTY", "MENU_UNIT_RAID_PLAYER", "MENU_UNIT_GUILD", "MENU_UNIT_GUILD_OFFLINE",
    "MENU_UNIT_COMMUNITIES_GUILD_MEMBER", "MENU_UNIT_COMMUNITIES_MEMBER", "MENU_UNIT_COMMUNITIES_WOW_MEMBER",
    "MENU_UNIT_BN_FRIEND"
}

-- Functions whose calls are recorded: the old drop-down menus and chat links.
local HOOKED_FUNCTIONS = {
    "FriendsFrame_ShowDropdown", "FriendsFrame_ShowBNDropdown", "UnitPopup_ShowMenu", "UnitPopup_OpenMenu",
    "ChatFrame_OnHyperlinkShow", "SetItemRef"
}

local EVENTS = {
    "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE", "GUILD_RANKS_UPDATE", "GUILD_MOTD", "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER"
}

-- Globals whose presence answers the open questions of the design.
local GLOBALS = {
    "GetGuildRosterInfo", "GetGuildRosterLastOnline", "GetNumGuildMembers", "GuildRoster", "GetGuildInfo",
    "IsInGuild", "CanViewOfficerNote", "GetGuildRosterShowOffline", "SetGuildRosterShowOffline",
    "GetGuildRosterMOTD", "GetNumGuildTradeSkill", "GetGuildTradeSkillInfo", "C_GuildInfo", "Menu", "MenuUtil",
    "UnitPopup_OpenMenu", "UnitPopup_ShowMenu", "UnitPopupMenus", "UnitPopupButtons", "UnitPopupSharedUtil",
    "FriendsFrame_ShowDropdown", "ChatFrame_OnHyperlinkShow", "ChatFrameUtil", "ChatFrameMixin", "SetItemRef",
    "UIDropDownMenu_AddButton", "EasyMenu", "Ambiguate", "GetNormalizedRealmName", "GetRealmName",
    "C_ClassColor", "RAID_CLASS_COLORS", "WOW_PROJECT_ID", "WOW_PROJECT_MAINLINE", "WOW_PROJECT_CLASSIC"
}

-- This session's data; it becomes GuildLensDB.probe at login (the last session replaces the one before).
local data = {menus = {}, calls = {}, events = {}, chat = {}, hooked = {}}

--- A value as it can be kept in the saved variables: frames and functions as text, tables one level deep.
local function Describe(value, depth)
    local kind = type(value)
    if value == nil then
        return "<nil>"
    elseif kind == "string" then
        return #value > MAX_STRING and value:sub(1, MAX_STRING) .. "..." or value
    elseif kind == "number" or kind == "boolean" then
        return value
    elseif kind == "table" then
        if type(value.GetObjectType) == "function" then
            local ok, name = pcall(value.GetName, value)
            local _, objectType = pcall(value.GetObjectType, value)
            return "<" .. tostring(objectType) .. " " .. tostring(ok and name or "?") .. ">"
        end
        if (depth or 0) >= 1 then
            return "<table>"
        end
        local copy = {}
        for key, inner in pairs(value) do
            copy[tostring(key)] = Describe(inner, (depth or 0) + 1)
        end
        return copy
    end
    return "<" .. kind .. ">"
end

--- Every value a call returned or got, by position, with holes kept as "<nil>".
local function DescribeAll(...)
    local list = {n = select("#", ...)}
    for i = 1, list.n do
        list[i] = Describe((select(i, ...)), 0)
    end
    return list
end

local function Push(list, entry)
    if #list >= MAX_SAMPLES then
        table.remove(list, 1)
    end
    entry.time = math.floor((GetTime and GetTime() or 0) * 10) / 10
    table.insert(list, entry)
end

local function OnMenu(tag)
    return function (owner, rootDescription, contextData)
        Push(data.menus, {tag = tag, owner = Describe(owner), context = Describe(contextData)})
        pcall(function ()
            rootDescription:CreateDivider()
            rootDescription:CreateTitle("GuildLens probe: " .. tag)
        end)
    end
end

local function HookMenus()
    if type(Menu) ~= "table" or type(Menu.ModifyMenu) ~= "function" then
        return
    end
    for _, tag in ipairs(MENU_TAGS) do
        if pcall(Menu.ModifyMenu, tag, OnMenu(tag)) then
            table.insert(data.hooked, tag)
        end
    end
end

local function HookFunctions()
    for _, name in ipairs(HOOKED_FUNCTIONS) do
        if type(_G[name]) == "function" then
            hooksecurefunc(name, function (...)
                Push(data.calls, {func = name, args = DescribeAll(...)})
            end)
            table.insert(data.hooked, name)
        end
    end
end

local frame = CreateFrame("Frame")
for _, event in ipairs(EVENTS) do
    if pcall(frame.RegisterEvent, frame, event) then
        data.events[event] = {count = 0}
    end
end
frame:SetScript("OnEvent", function (_, event, ...)
    local seen = data.events[event]
    seen.count = seen.count + 1
    if event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_OFFICER" then
        -- The text stays out: only its length, and the arguments that say who wrote it.
        local args = DescribeAll(...)
        args[1] = "<text of " .. #(tostring((...))) .. " characters>"
        Push(data.chat, {event = event, args = args})
    else
        seen.last = DescribeAll(...)
    end
end)

-- The snapshot taken by /glens probe.
local function RosterRow(index)
    local row = {index = index, info = DescribeAll(GetGuildRosterInfo(index))}
    if type(GetGuildRosterLastOnline) == "function" then
        row.lastOnline = DescribeAll(GetGuildRosterLastOnline(index))
    end
    return row
end

local function Snapshot()
    local snapshot = {globals = {}, missing = {}}
    snapshot.build = DescribeAll(GetBuildInfo())
    snapshot.locale = GetLocale()
    snapshot.realm = GetRealmName and GetRealmName()
    snapshot.normalizedRealm = GetNormalizedRealmName and GetNormalizedRealmName()
    snapshot.player = UnitName("player")
    for _, name in ipairs(GLOBALS) do
        local value = _G[name]
        if value == nil then
            table.insert(snapshot.missing, name)
        else
            snapshot.globals[name] = type(value)
        end
    end
    if type(C_GuildInfo) == "table" then
        snapshot.C_GuildInfo = {}
        for name in pairs(C_GuildInfo) do
            table.insert(snapshot.C_GuildInfo, name)
        end
        table.sort(snapshot.C_GuildInfo)
    end
    snapshot.inGuild = IsInGuild and IsInGuild()
    if snapshot.inGuild then
        snapshot.guildInfo = DescribeAll(GetGuildInfo("player"))
        snapshot.numMembers = DescribeAll(GetNumGuildMembers())
        snapshot.showOffline = GetGuildRosterShowOffline and GetGuildRosterShowOffline()
        snapshot.canViewOfficerNote = CanViewOfficerNote and CanViewOfficerNote()
        local total = GetNumGuildMembers() or 0
        snapshot.rows = {}
        for index = 1, math.min(total, 5) do
            table.insert(snapshot.rows, RosterRow(index))
        end
        -- The character's own row and the first offline one, wherever they are.
        for index = 6, total do
            local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(index)
            if (name and snapshot.player and name:find(snapshot.player, 1, true) == 1) or (online == false and not snapshot.offlineRow) then
                local row = RosterRow(index)
                if online == false and not snapshot.offlineRow then
                    snapshot.offlineRow = row
                else
                    table.insert(snapshot.rows, row)
                end
            end
        end
    end
    return snapshot
end

local function RequestRoster()
    if type(C_GuildInfo) == "table" and type(C_GuildInfo.GuildRoster) == "function" then
        C_GuildInfo.GuildRoster()
    elseif type(GuildRoster) == "function" then
        GuildRoster()
    end
end

local function Run(rest)
    if rest == "reset" then
        data.menus, data.calls, data.chat, data.snapshot = {}, {}, {}, nil
        for _, seen in pairs(data.events) do
            seen.count, seen.last = 0, nil
        end
        ns.db.probe = data
        ns.Print(L.ProbeReset)
        return
    end
    RequestRoster()
    local snapshot = Snapshot()
    data.snapshot = snapshot
    ns.db.probe = data

    local build = snapshot.build
    ns.Print(L.ProbeClient:format(tostring(build[1]), tostring(build[2]), tostring(build[4]), tostring(snapshot.locale)))
    if snapshot.inGuild then
        ns.Print(L.ProbeGuild:format(tostring(snapshot.guildInfo[1]), tostring(snapshot.numMembers[1])))
    else
        ns.Print(L.ProbeNoGuild)
    end
    local present = {}
    for _, name in ipairs({"GetGuildRosterInfo", "GetGuildRosterLastOnline", "GetNumGuildMembers"}) do
        if snapshot.globals[name] then
            table.insert(present, name)
        end
    end
    ns.Print(L.ProbeFunctions:format(table.concat(present, ", ")))
    if #snapshot.missing > 0 then
        ns.Print(L.ProbeMissing:format(table.concat(snapshot.missing, ", ")))
    end
    local menus = 0
    for _, name in ipairs(data.hooked) do
        if name:find("^MENU_") then
            menus = menus + 1
        end
    end
    ns.Print(L.ProbeMenu:format(menus > 0 and L.ProbeMenuModern:format(menus) or L.ProbeMenuOld))
    ns.Print(L.ProbeNext)
end

ns.OnLogin(function ()
    ns.db.probe = data
    HookMenus()
    HookFunctions()
end)

ns.AddCommand("probe", Run, L.CommandProbe, L.CommandProbeReset)
