--[[
The guild roster, cached by name and by GUID.

The client sends GUILD_ROSTER_UPDATE very often (about a hundred times in ten minutes on Forever), so an update only
marks the cache stale; it is rebuilt when someone is looked up. Fresh data is asked of the server at login and, at most
every REQUEST_INTERVAL seconds, when a menu is about to show a member.

GetGuildRosterInfo returns (Forever 1.60.1): name, rank, rankIndex, level, class (localized, by gender), zone, note,
officerNote, online, status (0, 1 away, 2 busy), classFile, achievementPoints, achievementRank, isMobile, canSoR,
standing, guid. On Forever names come without a realm (and may have a space: "First Last"); on Classic Era with
"-Realm".
]]
local _, ns = ...

local Roster = {}
ns.Roster = Roster

local REQUEST_INTERVAL = 30

local byName, byGuid = {}, {}
local count, online = 0, 0
local stale = true
local lastRequest

--- The name without a "-Realm" suffix.
local function ShortName(name)
    return (name:gsub("%-[^%-%s]+$", ""))
end

local function Rebuild()
    stale = false
    byName, byGuid = {}, {}
    count, online = 0, 0
    if not (IsInGuild and IsInGuild()) then
        return
    end
    for index = 1, GetNumGuildMembers() or 0 do
        local name, rank, rankIndex, level, class, zone, note, officerNote, isOnline, status, classFile,
            _, _, isMobile, _, _, guid = GetGuildRosterInfo(index)
        if name then
            local member = {
                name = name, rank = rank, rankIndex = rankIndex, level = level, class = class, classFile = classFile,
                zone = zone, note = note, officerNote = officerNote, online = isOnline and true or false,
                status = status, isMobile = isMobile, guid = guid
            }
            if not isOnline and GetGuildRosterLastOnline then
                member.years, member.months, member.days, member.hours = GetGuildRosterLastOnline(index)
            end
            count = count + 1
            if isOnline then
                online = online + 1
            end
            byName[name] = member
            local short = ShortName(name)
            if byName[short] == nil then
                byName[short] = member
            end
            if guid then
                byGuid[guid] = member
            end
        end
    end
end

--- The member by GUID or name (with or without a realm), or nil.
function Roster.Find(name, guid)
    if stale then
        Rebuild()
    end
    return (guid and byGuid[guid]) or (name and (byName[name] or byName[ShortName(name)])) or nil
end

--- Whether the roster has come from the server yet.
function Roster.IsLoaded()
    if stale then
        Rebuild()
    end
    return count > 0
end

--- Members and of them online.
function Roster.Counts()
    if stale then
        Rebuild()
    end
    return count, online
end

--- Asks the server for a fresh roster, unless it was asked recently.
function Roster.Request()
    local now = GetTime()
    if lastRequest and now - lastRequest < REQUEST_INTERVAL then
        return
    end
    lastRequest = now
    if C_GuildInfo and C_GuildInfo.GuildRoster then
        C_GuildInfo.GuildRoster()
    elseif GuildRoster then
        GuildRoster()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_GUILD_UPDATE")
frame:SetScript("OnEvent", function ()
    stale = true
end)

ns.OnLogin(function ()
    if IsInGuild and IsInGuild() then
        Roster.Request()
    end
end)

ns.AddCommand("status", function ()
    if not (IsInGuild and IsInGuild()) then
        ns.Print(ns.L.NoGuild)
        return
    end
    Roster.Request()
    ns.Print(ns.L.RosterStatus:format(Roster.Counts()))
end, ns.L.CommandStatus)
