--[[
The lines shown about a guild member: class and level, rank, online status (or when last seen), zone and the public
note. A field the roster does not have is left out. Plain text with colour codes, so it can go into a menu, a tooltip
or the chat alike. Only characters the game's fonts have: no "·" (the ruRU font draws it as a box).
]]
local _, ns = ...
local L = ns.L

local Lines = {}
ns.Lines = Lines

-- Labels stay in the menu's own gold; values are white, so they stand out from them.
local GREEN, GREY, WHITE = "ff40ff40", "ff9d9d9d", "ffffffff"

local function Color(color, text)
    return "|c" .. color .. text .. "|r"
end

local function ClassColor(classFile)
    local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if not color then
        return nil
    end
    if color.colorStr then
        return color.colorStr
    end
    local function Byte(part)
        return math.floor(part * 255 + 0.5)
    end
    return string.format("ff%02x%02x%02x", Byte(color.r), Byte(color.g), Byte(color.b))
end

local function Filled(value)
    return type(value) == "string" and value ~= ""
end

--- How long ago an offline member was last seen, in the largest unit the roster gives.
function Lines.LastSeen(member)
    if (member.years or 0) > 0 then
        return L.YearsAgo:format(member.years)
    elseif (member.months or 0) > 0 then
        return L.MonthsAgo:format(member.months)
    elseif (member.days or 0) > 0 then
        return L.DaysAgo:format(member.days)
    elseif (member.hours or 0) > 0 then
        return L.HoursAgo:format(member.hours)
    elseif member.years then
        return L.JustNow
    end
    return nil
end

local function Status(member)
    if member.online then
        local text = Color(GREEN, L.Online)
        if member.status == 1 then
            text = text .. ", " .. L.Away
        elseif member.status == 2 then
            text = text .. ", " .. L.Busy
        end
        return text
    end
    local seen = Lines.LastSeen(member)
    return Color(GREY, seen and L.OfflineSince:format(seen) or L.Offline)
end

--- The lines about a member found in the roster.
function Lines.ForMember(member)
    local lines = {}
    local first = {}
    if Filled(member.class) then
        local color = ClassColor(member.classFile)
        table.insert(first, color and Color(color, member.class) or member.class)
    end
    if type(member.level) == "number" and member.level > 0 then
        table.insert(first, L.Level:format(member.level))
    end
    if #first > 0 then
        table.insert(lines, table.concat(first, ", "))
    end
    if Filled(member.rank) then
        table.insert(lines, L.Rank:format(Color(WHITE, member.rank)))
    end
    table.insert(lines, L.Status:format(Status(member)))
    if Filled(member.zone) then
        table.insert(lines, L.Zone:format(Color(WHITE, member.zone)))
    end
    if Filled(member.note) then
        -- The game keeps guild notes short (31 characters), so a note fits on one line as it is.
        table.insert(lines, L.Note:format(Color(WHITE, member.note)))
    end
    return lines
end

--- The lines for a name in a guild menu: the member's, or why there are none.
function Lines.ForName(name, guid)
    local member = ns.Roster.Find(name, guid)
    if member then
        return Lines.ForMember(member)
    elseif not ns.Roster.IsLoaded() then
        return {Color(GREY, L.NotLoaded)}
    end
    return {Color(GREY, L.NotInRoster)}
end
