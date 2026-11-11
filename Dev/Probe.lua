--[[
Second reconnaissance: race and sex, professions and Forever's "preferred play settings" of guild members, and the
client's own options panel. /glens probe records into GuildLensDB.probe:

- race: GetPlayerInfoByGUID for the first members of the roster and the character itself;
- club: the guild's club id, its member count and C_Club.GetMemberInfo of the same members (professions live there
  on modern clients);
- tradeSkills: the guild profession list (GetNumGuildTradeSkill, GetGuildTradeSkillInfo);
- preferred: every C_GuildInfo.*PreferredPlay* function but the setter, called without arguments and with a GUID,
  and the events that come within EVENT_WINDOW seconds after (all events are listened to for that long, the ones
  about guilds, clubs or preferences are kept);
- api: which of the functions worth knowing exist.

Development only: this file goes away before the first release. What it records holds guild members' names: it stays
in the saved variables and is dropped by /glens probe reset.
]]
local _, ns = ...

local SAMPLE = 8
local EVENT_WINDOW = 10
local MAX_EVENTS = 40
local MAX_STRING = 200

local API = {
    "GetPlayerInfoByGUID", "C_PlayerInfo", "C_CreatureInfo", "LOCALIZED_CLASS_NAMES_FEMALE", "C_Club",
    "GetNumGuildTradeSkill", "GetGuildTradeSkillInfo", "QueryGuildRecipes", "ExpandGuildTradeSkillHeader",
    "CollapseGuildTradeSkillHeader", "GetGuildRecipeInfoPostQuery", "GetProfessionInfo", "C_TradeSkillUI",
    "Settings", "SettingsPanel", "InterfaceOptions_AddCategory", "GuildControlGetNumRanks", "GuildControlGetRankName"
}
local SETTINGS_API = {"RegisterVerticalLayoutCategory", "RegisterAddOnCategory", "RegisterAddOnSetting",
    "CreateCheckbox", "OpenToCategory"}

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
            return "<frame>"
        end
        if depth >= 2 then
            return "<table>"
        end
        local copy = {}
        for key, inner in pairs(value) do
            copy[tostring(key)] = Describe(inner, depth + 1)
        end
        return copy
    end
    return "<" .. kind .. ">"
end

local function Pack(...)
    local list = {n = select("#", ...)}
    for i = 1, list.n do
        list[i] = Describe((select(i, ...)), 0)
    end
    return list
end

--- Calls a function, keeping what it returned or the error it raised.
local function Try(func, ...)
    local result = Pack(pcall(func, ...))
    if result[1] == true then
        table.remove(result, 1)
        result.n = result.n - 1
        return result
    end
    return {error = result[2]}
end

local function SampleMembers()
    local members = {}
    for index = 1, math.min(GetNumGuildMembers() or 0, SAMPLE) do
        local name, _, _, _, class, _, _, _, _, _, _, _, _, _, _, _, guid = GetGuildRosterInfo(index)
        table.insert(members, {index = index, name = name, class = class, guid = guid})
    end
    local own = UnitGUID and UnitGUID("player")
    if own then
        table.insert(members, {name = UnitName("player"), guid = own, self = true})
    end
    return members
end

local function ProbeClub(data, members)
    if type(C_Club) ~= "table" or type(C_Club.GetGuildClubId) ~= "function" then
        data.club = {error = "no C_Club.GetGuildClubId"}
        return
    end
    local clubId = C_Club.GetGuildClubId()
    local club = {clubId = Describe(clubId, 0), members = {}}
    data.club = club
    if not clubId or type(C_Club.GetClubMembers) ~= "function" then
        return
    end
    local ids = C_Club.GetClubMembers(clubId) or {}
    club.count = #ids
    -- The club's members in its own order: the first SAMPLE, and those of the sampled roster rows by GUID.
    local wanted = {}
    for _, member in ipairs(members) do
        if member.guid then
            wanted[member.guid] = true
        end
    end
    for position, memberId in ipairs(ids) do
        local info = C_Club.GetMemberInfo(clubId, memberId)
        if position <= SAMPLE or (type(info) == "table" and wanted[info.guid]) then
            table.insert(club.members, Describe(info, 0))
        end
    end
end

local function ProbeTradeSkills(data)
    if type(GetNumGuildTradeSkill) ~= "function" then
        return
    end
    if type(QueryGuildRecipes) == "function" then
        pcall(QueryGuildRecipes)
    end
    local rows = {}
    local total = GetNumGuildTradeSkill() or 0
    for index = 1, math.min(total, 60) do
        table.insert(rows, Pack(GetGuildTradeSkillInfo(index)))
    end
    data.tradeSkills = {count = total, rows = rows}
end

local listener = CreateFrame("Frame")
local function Listen(data)
    data.events = {}
    listener:SetScript("OnEvent", function (_, event, ...)
        if #data.events < MAX_EVENTS and (event:find("GUILD") or event:find("CLUB") or event:find("PREFER")) then
            table.insert(data.events, {event = event, args = Pack(...)})
        end
    end)
    if listener.RegisterAllEvents then
        listener:RegisterAllEvents()
        C_Timer.After(EVENT_WINDOW, function ()
            listener:UnregisterAllEvents()
        end)
    end
end

local function ProbePreferred(data, members)
    local preferred = {}
    data.preferred = preferred
    if type(C_GuildInfo) ~= "table" then
        return
    end
    local guid = members[1] and members[1].guid
    for name, func in pairs(C_GuildInfo) do
        if name:find("PreferredPlay") and not name:find("^Set") and type(func) == "function" then
            preferred[name] = {none = Try(func), guid = guid and Try(func, guid) or nil}
        end
    end
end

local function Run(rest)
    if rest == "reset" then
        ns.db.probe = nil
        ns.Print("probe: forgotten")
        return
    end
    local data = {api = {}, settingsApi = {}, race = {}}
    ns.db.probe = data
    for _, name in ipairs(API) do
        data.api[name] = type(_G[name])
    end
    if type(Settings) == "table" then
        for _, name in ipairs(SETTINGS_API) do
            data.settingsApi[name] = type(Settings[name])
        end
    end
    local members = SampleMembers()
    data.members = members
    Listen(data)
    for _, member in ipairs(members) do
        if member.guid and type(GetPlayerInfoByGUID) == "function" then
            table.insert(data.race, {name = member.name, info = Try(GetPlayerInfoByGUID, member.guid)})
        end
    end
    ProbeClub(data, members)
    ProbeTradeSkills(data)
    ProbePreferred(data, members)
    ns.Print(("probe: %d members sampled, club %s, %s guild profession rows. Wait %d s, then /reload."):format(
        #members, tostring(data.club and data.club.count), tostring(data.tradeSkills and data.tradeSkills.count),
        EVENT_WINDOW))
end

ns.AddCommand("probe", Run)
