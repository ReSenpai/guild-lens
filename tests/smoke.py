"""Loads GuildLens's files in TOC order against stubbed WoW APIs and exercises them, once as a modern client
(Forever: Menu.ModifyMenu, C_GuildInfo) and once as an old one (Classic Era: drop-down menus only).

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
local function NewFrame(kind, name)
    local f = {shown = true, scripts = {}, name = name}
    return setmetatable(f, {__index = function(t, k)
        if not k:match('^%u') then return nil end
        return function(self, ...)
            if k == "RegisterEvent" then
                local event = ...
                if UNKNOWN_EVENTS and UNKNOWN_EVENTS[event] then error("unknown event " .. event) end
                EVENTS[#EVENTS + 1] = {self, event}
            elseif k == "SetScript" then local s, fn = ...; self.scripts[s] = fn
            elseif k == "GetName" then return self.name
            elseif k == "GetObjectType" then return kind
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
GetLocale = function() return LOCALE end
GetTime = function() return 123.456 end
GetRealmName = function() return "Test Realm" end
UnitName = function() return "Tester" end
SlashCmdList = {}
hooksecurefunc = function(name, hook)
    local original = _G[name]
    _G[name] = function(...) local r = {original(...)}; hook(...); return unpack(r) end
end
IsInGuild = function() return true end
GetGuildInfo = function() return "Lens Keepers", "Veteran", 2, nil end
local roster = {
    {"Tester-TestRealm", "Officer", 1, 37, "Hunter", "Ironforge", "", "", true, 0, "HUNTER"},
    {"Alpha-TestRealm", "Veteran", 2, 60, "Mage", "Orgrimmar", "tank", nil, true, 0, "MAGE"},
    {"Beta-TestRealm", "Member", 3, 12, "Rogue", nil, "", nil, false, 0, "ROGUE"},
}
for i = 4, 8 do roster[i] = {"Member" .. i .. "-TestRealm", "Member", 3, i, "Priest", nil, "", nil, i ~= 7, 0, "PRIEST"} end
GetNumGuildMembers = function() return #roster, 6, 6 end
GetGuildRosterInfo = function(i) local r = roster[i]; if r then return unpack(r, 1, 11) end end
GetGuildRosterLastOnline = function(i) return 0, 0, i, 3 end
GetGuildRosterShowOffline = function() return true end
CanViewOfficerNote = function() return false end
ROSTER_REQUESTS = 0
FriendsFrame_ShowDropdown = function(name, connected, lineID, chatType, chatFrame) end
SetItemRef = function(link, text, button, chatFrame) end
if MODERN then
    GetBuildInfo = function() return "1.60.1", "12345", "Nov 1 2026", 16001 end
    C_GuildInfo = {GuildRoster = function() ROSTER_REQUESTS = ROSTER_REQUESTS + 1 end, CanViewOfficerNote = function() return false end}
    MENUS = {}
    Menu = {ModifyMenu = function(tag, callback) MENUS[tag] = callback end}
    UnitPopup_OpenMenu = function(which, contextData) end
    GetNormalizedRealmName = function() return "TestRealm" end
else
    GetBuildInfo = function() return "1.15.9", "54321", "Nov 1 2026", 11509 end
    GuildRoster = function() ROSTER_REQUESTS = ROSTER_REQUESTS + 1 end
    UnitPopup_ShowMenu = function(dropdownMenu, which, unit, name) end
    UNKNOWN_EVENTS = {GUILD_RANKS_UPDATE = true}
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
    for path in addon_files(TOCS[modern]):
        chunk = lua.eval("function(code, name) return assert(loadstring and loadstring(code, name) or load(code, '=' .. name)) end")
        chunk((ROOT / path).read_text(encoding="utf-8"), path)("GuildLens", ns)

    return lua.execute(r"""
        local out = {}
        local function check(condition, message) if not condition then error("smoke: " .. message, 2) end end
        FIRE("ADDON_LOADED", "GuildLens")
        FIRE("PLAYER_LOGIN")
        check(GuildLensDB and GuildLensDB.probe, "GuildLensDB.probe after login")
        local probe = GuildLensDB.probe

        -- Guild chat: the sender is kept, the text is not.
        FIRE("CHAT_MSG_GUILD", "secret words", "Alpha-TestRealm", "", "", "Alpha", "", 0, 0, "", 0, 77, "Player-1-0000")
        check(probe.chat[1].args[2] == "Alpha-TestRealm", "chat sender recorded")
        check(not tostring(probe.chat[1].args[1]):find("secret"), "chat text left out")

        -- The chat name menu
        FriendsFrame_ShowDropdown("Alpha-TestRealm", true, 77, "GUILD", ChatFrame1)
        check(probe.calls[1].func == "FriendsFrame_ShowDropdown", "old menu call recorded")
        check(probe.calls[1].args[5] == "<ScrollingMessageFrame ChatFrame1>", "frames kept as text")
        if MODERN then
            local titles = {}
            local root = {CreateDivider = function() end, CreateTitle = function(_, text) titles[#titles + 1] = text end}
            MENUS.MENU_UNIT_FRIEND(ChatFrame1, root, {name = "Alpha", server = "TestRealm", chatType = "GUILD", lineID = 77, chatTarget = nil})
            check(titles[1] == "GuildLens probe: MENU_UNIT_FRIEND", "title added to the menu")
            check(probe.menus[1].context.chatType == "GUILD", "menu context recorded")
        else
            check(#probe.menus == 0, "no modern menus on an old client")
        end

        -- /glens probe
        SlashCmdList.GUILDLENS("probe")
        local snapshot = probe.snapshot
        check(snapshot, "snapshot taken")
        check(ROSTER_REQUESTS == 1, "roster requested once")
        check(snapshot.inGuild and snapshot.guildInfo[1] == "Lens Keepers", "guild name")
        check(#snapshot.rows == 5, "first five rows")
        check(snapshot.rows[2].info[4] == 60 and snapshot.rows[2].info[11] == "MAGE", "roster row values")
        check(snapshot.rows[3].info[6] == "<nil>" and snapshot.rows[3].info.n == 11, "holes kept")
        check(snapshot.offlineRow and snapshot.offlineRow.index == 7, "first offline row past the five")
        check(snapshot.rows[1].lastOnline[3] == 1, "last online")
        for _, line in ipairs(CHAT) do out[#out + 1] = line end

        SlashCmdList.GUILDLENS("")
        SlashCmdList.GUILDLENS("nope")
        SlashCmdList.GUILDLENS("probe reset")
        check(#GuildLensDB.probe.chat == 0 and GuildLensDB.probe.snapshot == nil, "reset")
        out[#out + 1] = CHAT[#CHAT]
        return table.concat(out, "\n")
    """)


for modern in (True, False):
    print(f"--- {LOCALE}, {'modern client (Forever)' if modern else 'old client (Classic Era)'}")
    print(re.sub(r"\|c\w{8}|\|r", "", run(modern)))
print("smoke: ok")
