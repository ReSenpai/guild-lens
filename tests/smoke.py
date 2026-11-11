"""Loads GuildLens's files in TOC order against stubbed WoW APIs and exercises them, once as a modern client
(Forever: Menu.ModifyMenu, C_GuildInfo, names without a realm) and once as an old one (Classic Era: no Menu,
names with "-Realm").

Usage: python tests/smoke.py [enUS|ruRU]
"""
import pathlib
import re
import sys

import lupa

ROOT = pathlib.Path(__file__).resolve().parent.parent
LOCALE = sys.argv[1] if len(sys.argv) > 1 else "enUS"

STUBS = r"""
unpack = table.unpack
EVENTS = {}
CHAT = {}
ERRORS = {}
local function NewFrame(kind, name)
    local f = {shown = true, scripts = {}, name = name}
    return setmetatable(f, {__index = function(t, k)
        if not k:match('^%u') then return nil end
        return function(self, ...)
            if k == "RegisterEvent" then EVENTS[#EVENTS + 1] = {self, (...)}
            elseif k == "SetScript" then local s, fn = ...; self.scripts[s] = fn
            elseif k == "GetName" then return self.name
            end
        end
    end})
end
CreateFrame = function(kind, name) local f = NewFrame(kind, name); if name then _G[name] = f end; return f end
FIRE = function(event, ...)
    for _, e in ipairs(EVENTS) do
        if e[2] == event then e[1].scripts.OnEvent(e[1], event, ...) end
    end
end
DEFAULT_CHAT_FRAME = {AddMessage = function(_, text) CHAT[#CHAT + 1] = text end}
ChatFrame1 = CreateFrame("ScrollingMessageFrame", "ChatFrame1")
ChatFrame1.AddMessage = function(self, text, r, g, b) CHAT_LINE = {text, r, g, b} end
NUM_CHAT_WINDOWS = 1
SECRET = false
issecretvalue = function() return SECRET end
GetLocale = function() return LOCALE end
NOW = 100
GetTime = function() return NOW end
SlashCmdList = {}
geterrorhandler = function() return function(e) ERRORS[#ERRORS + 1] = tostring(e) end end
RAID_CLASS_COLORS = {HUNTER = {r = 0.67, g = 0.83, b = 0.45, colorStr = "ffaad372"}, MAGE = {r = 0.25, g = 0.78, b = 0.92}}
IN_GUILD = true
IsInGuild = function() return IN_GUILD end
local suffix = MODERN and "" or "-Realm"
ROSTER = {}
GetNumGuildMembers = function() local online = 0; for _, r in ipairs(ROSTER) do if r[9] then online = online + 1 end end; return #ROSTER, online end
GetGuildRosterInfo = function(i) local r = ROSTER[i]; if r then return unpack(r, 1, 17) end end
LAST_ONLINE = {}
GetGuildRosterLastOnline = function(i) if not ROSTER[i][9] then return unpack(LAST_ONLINE[i] or {0, 0, 0, 0}) end end
FULL_ROSTER = {
    {"Re Senpai" .. suffix, "Officer", 1, 24, "Huntress", "Redridge Mountains", "", "", true, 0, "HUNTER", -1, 31, false, false, 3, "Player-1-AAA"},
    {"Alpha Beta" .. suffix, "Veteran", 2, 60, "Mage", "Orgrimmar", "main tank of the raid", nil, true, 1, "MAGE", -1, 1, false, false, 3, "Player-2-BBB"},
    {"Gamma" .. suffix, "Initiate", 5, 12, "Rogue", "Dun Morogh", "", "", false, 0, "ROGUE", -1, 1, false, false, 3, "Player-3-CCC"},
    {"Delta" .. suffix, "Initiate", 5, 7, "Priest", "", "", "", false, 0, "PRIEST", -1, 1, false, false, 3, "Player-4-DDD"},
}
LAST_ONLINE[3] = {0, 0, 3, 5}
ROSTER_REQUESTS = 0
local function request() ROSTER_REQUESTS = ROSTER_REQUESTS + 1 end
if MODERN then
    C_GuildInfo = {GuildRoster = request}
    CLASS_ICON_TCOORDS = {MAGE = {0.25, 0.49609375, 0, 0.25}, HUNTER = {0, 0.25, 0.25, 0.5}}
    MENUS = {}
    Menu = {ModifyMenu = function(tag, callback) MENUS[tag] = callback end}
else
    GuildRoster = request
end
"""

TOCS = {True: "GuildLens.toc", False: "GuildLens_Vanilla.toc"}


def addon_files(toc):
    for line in (ROOT / toc).read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            yield line.replace("\\", "/")


def run(modern):
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.globals().LOCALE = LOCALE
    lua.globals().MODERN = modern
    lua.execute(STUBS)
    ns = lua.eval("{}")
    lua.globals().ns = ns
    load = lua.eval("function(code, name) return assert(load(code, '=' .. name)) end")
    for path in addon_files(TOCS[modern]):
        load((ROOT / path).read_text(encoding="utf-8"), path)("GuildLens", ns)

    return lua.execute(r"""
        local out = {}
        local function check(condition, message) if not condition then error("smoke: " .. message, 2) end end
        local function strip(text) return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
        local function menu(context)
            local titles = {}
            local root = {CreateDivider = function() titles[#titles + 1] = "---" end,
                          CreateTitle = function(_, text) titles[#titles + 1] = strip(text) end}
            MENUS.MENU_UNIT_FRIEND(ChatFrame1, root, context)
            return titles
        end
        local function show(title, lines)
            out[#out + 1] = title
            for _, line in ipairs(lines) do out[#out + 1] = "  " .. line end
        end

        GuildLensDB = {probe = {menus = {}}}
        FIRE("ADDON_LOADED", "GuildLens")
        check(GuildLensDB.probe == nil, "probe data dropped")
        FIRE("PLAYER_LOGIN")
        check(ROSTER_REQUESTS == 1, "roster requested at login")

        -- Before the roster arrives
        local lines = ns.Lines.ForName("Alpha Beta")
        check(#lines == 1, "one line before the roster")
        show("before the roster:", lines)

        ROSTER = FULL_ROSTER
        FIRE("GUILD_ROSTER_UPDATE", false)
        local suffix = MODERN and "" or "-Realm"
        check(ns.Roster.Find("Alpha Beta" .. suffix).level == 60, "found by full name")
        check(ns.Roster.Find("Alpha Beta").level == 60, "found without the realm")
        check(ns.Roster.Find(nil, "Player-3-CCC").name == "Gamma" .. suffix, "found by GUID")
        check(ns.Roster.Find("Nobody") == nil, "unknown name")
        check(select(2, ns.Roster.Counts()) == 2, "two online")

        -- The member lines
        show("online, away, with a note:", ns.Lines.ForMember(ns.Roster.Find("Alpha Beta")))
        local gamma = ns.Lines.ForMember(ns.Roster.Find("Gamma"))
        show("offline 3 days:", gamma)
        check(strip(gamma[3]):find("3"), "last seen in days")
        local delta = ns.Lines.ForMember(ns.Roster.Find("Delta"))
        show("offline under an hour, no zone:", delta)
        check(#delta == 3, "empty zone and note left out")

        -- The roster is rebuilt only after an update
        ROSTER = {}
        check(ns.Roster.Find("Alpha Beta"), "cache kept without an update")
        ROSTER = FULL_ROSTER

        -- Rank names: the game's defaults in the client's language, a guild's own as they are
        check(ns.Lines.RankName("Veteran") == (LOCALE == "ruRU" and "Ветеран" or "Veteran"), "default rank translated")
        check(ns.Lines.RankName("Raid Lead") == "Raid Lead", "own rank kept")

        -- Class icons: the mage's cut is 64..127 × 0..64 of the 256 texture, in both tables
        check(ns.Lines.ClassIcon("MAGE", 14) == "|TInterface\\TargetingFrame\\UI-Classes-Circles:14:14:0:0:256:256:64:127:0:64|t", "mage icon")
        check(ns.Lines.ClassIcon("ROGUE", 0) ~= nil, "rogue icon (fallback cuts on the modern stub)")
        check(ns.Lines.ClassIcon("MONK", 14) == nil, "no icon for an unknown class")

        -- Guild chat: [Guild] becomes the sender's icon and level, the link stays
        local GUILD_LINE = "|Hchannel:GUILD|h[Guild]|h |Hplayer:Alpha Beta" .. suffix .. ":5:GUILD:|h[Alpha Beta]|h: hi"
        ChatFrame1:AddMessage(GUILD_LINE, 0.25, 1, 0.25)
        local line = CHAT_LINE[1]
        check(line:find("|Hchannel:GUILD|h|T", 1, true) and line:find("|t60|h |Hplayer:Alpha Beta", 1, true), "guild tag replaced")
        check(not line:find("[Guild]", 1, true) and line:sub(-4) == ": hi" and CHAT_LINE[2] == 0.25, "rest of the line and colour kept")
        out[#out + 1] = "chat: " .. line
        local stranger = "|Hchannel:GUILD|h[Guild]|h |Hplayer:Stranger:6:GUILD:|h[Stranger]|h: hi"
        ChatFrame1:AddMessage(stranger)
        check(CHAT_LINE[1] == stranger, "unknown sender left as is")
        local officer = "|Hchannel:OFFICER|h[Officer]|h |Hplayer:Alpha Beta:7:OFFICER:|h[Alpha Beta]|h: hi"
        ChatFrame1:AddMessage(officer)
        check(CHAT_LINE[1] == officer, "officer chat left as is")
        SECRET = true
        ChatFrame1:AddMessage(GUILD_LINE)
        check(CHAT_LINE[1] == GUILD_LINE, "secret text left alone")
        SECRET = false
        SlashCmdList.GUILDLENS("chat")
        ChatFrame1:AddMessage(GUILD_LINE)
        check(CHAT_LINE[1] == GUILD_LINE and GuildLensDB.chatIcons == false, "turned off and saved")
        SlashCmdList.GUILDLENS("chat")
        ChatFrame1:AddMessage(GUILD_LINE)
        check(CHAT_LINE[1] ~= GUILD_LINE, "turned on again")

        if MODERN then
            -- Guild chat: the GUID of the line comes from the chat message
            FIRE("CHAT_MSG_GUILD", "hello", "Alpha Beta", "", "", "", "", 0, 0, "", 0, 5, "Player-2-BBB")
            NOW = NOW + 60
            local titles = menu({which = "FRIEND", name = "Alpha Beta", chatType = "GUILD", lineID = "5"})
            check(titles[1] == "---" and titles[2] == "GuildLens", "divider and title")
            check(titles[3]:find("60"), "level in the menu")
            check(ROSTER_REQUESTS == 2, "roster requested when the menu opened")
            show("menu, guild chat:", titles)
            menu({which = "FRIEND", name = "Alpha Beta", chatType = "GUILD", lineID = "5"})
            check(ROSTER_REQUESTS == 2, "not requested again within the interval")

            check(#menu({which = "FRIEND", name = "Alpha Beta", chatType = "WHISPER", lineID = "6"}) == 0, "nothing outside guild chat")
            check(#menu({which = "FRIEND", name = "Gamma", chatType = "OFFICER", lineID = "7"}) > 2, "officer chat counts")
            show("menu, someone who left:", menu({which = "FRIEND", name = "Stranger", chatType = "GUILD", lineID = "8"}))

            -- The guild window (J): the menu has the GUID itself
            local function guildMenu(context)
                local titles = {}
                local root = {CreateDivider = function() end, CreateTitle = function(_, text) titles[#titles + 1] = strip(text) end}
                MENUS.MENU_UNIT_COMMUNITIES_GUILD_MEMBER(nil, root, context)
                return titles
            end
            local window = guildMenu({which = "COMMUNITIES_GUILD_MEMBER", name = "Someone Else", guid = "Player-3-CCC", isGuildMember = true})
            check(window[2] and window[2]:find("12"), "guild window member found by GUID")
            show("menu, guild window, offline:", window)
            check(MENUS.MENU_UNIT_GUILD and MENUS.MENU_UNIT_GUILD_OFFLINE, "old guild frame menus hooked too")

            -- A broken lookup is reported, the menu still opens
            local find = ns.Roster.Find
            ns.Roster.Find = function() error("boom") end
            menu({which = "FRIEND", name = "Alpha Beta", chatType = "GUILD", lineID = "5"})
            ns.Roster.Find = find
            check(#ERRORS == 1 and ERRORS[1]:find("boom"), "error reported, not raised")
        else
            check(MENUS == nil, "no menu hook on an old client")
        end

        SlashCmdList.GUILDLENS("status")
        SlashCmdList.GUILDLENS("")
        IN_GUILD = false
        SlashCmdList.GUILDLENS("status")
        for _, line in ipairs(CHAT) do out[#out + 1] = strip(line) end
        return table.concat(out, "\n")
    """)


for modern in (True, False):
    print(f"--- {LOCALE}, {'modern client (Forever)' if modern else 'old client (Classic Era)'}")
    print(run(modern))
print("smoke: ok")
