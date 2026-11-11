--[[
The lines shown about a guild member: class (icon and name) and level, rank, online status (or when last seen), zone and the public
note, each but the first as the options say. A field the roster does not have is left out. Plain text with colour codes, so it can go into a menu, a tooltip
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

-- Class icons: one 256×256 texture of round icons, cut by the client's CLASS_ICON_TCOORDS. The same cuts for the
-- Classic classes in case a client lacks the table.
local CLASS_ICONS = "Interface\\TargetingFrame\\UI-Classes-Circles"
local FALLBACK_TCOORDS = {
    WARRIOR = {0, 0.25, 0, 0.25}, MAGE = {0.25, 0.49609375, 0, 0.25}, ROGUE = {0.49609375, 0.7421875, 0, 0.25},
    DRUID = {0.7421875, 0.98828125, 0, 0.25}, HUNTER = {0, 0.25, 0.25, 0.5}, SHAMAN = {0.25, 0.49609375, 0.25, 0.5},
    PRIEST = {0.49609375, 0.7421875, 0.25, 0.5}, WARLOCK = {0.7421875, 0.98828125, 0.25, 0.5},
    PALADIN = {0, 0.25, 0.5, 0.75}
}

--- The class's icon as an inline texture of the given size (0: the height of the text), or nil.
function Lines.ClassIcon(classFile, size)
    local coords = classFile and ((CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]) or FALLBACK_TCOORDS[classFile])
    if not coords then
        return nil
    end
    local function Pixel(part)
        return math.floor(part * 256 + 0.5)
    end
    return string.format("|T%s:%d:%d:0:0:256:256:%d:%d:%d:%d|t", CLASS_ICONS, size, size,
        Pixel(coords[1]), Pixel(coords[2]), Pixel(coords[3]), Pixel(coords[4]))
end

--- The rank's name in the client's language when it is one of the game's default names, else as the guild set it.
function Lines.RankName(rank)
    return (ns.RankNames and ns.RankNames[rank]) or rank
end

--- What stands for the guild channel in a guild chat line: the parts of the sender asked for in show
--- ({icon, level, zone}) in square brackets, as "[<icon>26, Duskwood]"; nil when none of them is known.
function Lines.ChatTag(member, show)
    local head = ""
    if show.icon then
        head = Lines.ClassIcon(member.classFile, 0) or ""
    end
    if show.level and type(member.level) == "number" and member.level > 0 then
        head = head .. member.level
    end
    local parts = {}
    if head ~= "" then
        table.insert(parts, head)
    end
    if show.zone and Filled(member.zone) then
        table.insert(parts, member.zone)
    end
    if #parts == 0 then
        return nil
    end
    return "[" .. table.concat(parts, ", ") .. "]"
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

--- The member's sex from the roster's class name, which some languages give by sex ("Охотница"): 2 male, 3 female,
--- nil when the class's name is the same for both.
function Lines.SexFromClass(member)
    local male = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[member.classFile]
    local female = LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[member.classFile]
    if not (male and female) or male == female then
        return nil
    elseif member.class == female then
        return 3
    elseif member.class == male then
        return 2
    end
    return nil
end

--- The member's race in the client's language and sex (2 male, 3 female, nil unknown), or nil.
--- The client's own answer when it has met the character (GetPlayerInfoByGUID: the race named by sex); otherwise the
--- race from the guild's club and the sex from the class's name, the race's female name from ns.FemaleRaceNames.
function Lines.Race(member)
    if member.guid and GetPlayerInfoByGUID then
        local _, _, race, _, sex = GetPlayerInfoByGUID(member.guid)
        if Filled(race) then
            return race, (sex == 2 or sex == 3) and sex or nil
        end
    end
    local info = ns.Club.Info(member.guid)
    local raceInfo = info and info.race and C_CreatureInfo and C_CreatureInfo.GetRaceInfo
        and C_CreatureInfo.GetRaceInfo(info.race)
    if not (raceInfo and Filled(raceInfo.raceName)) then
        return nil
    end
    local sex = Lines.SexFromClass(member)
    local female = sex == 3 and ns.FemaleRaceNames and ns.FemaleRaceNames[raceInfo.clientFileString]
    return female or raceInfo.raceName, sex
end

--- The lines about a member found in the roster.
function Lines.ForMember(member)
    local lines = {}
    local first = {}
    if Filled(member.class) then
        local color = ClassColor(member.classFile)
        local icon = ns.settings.menuIcon and Lines.ClassIcon(member.classFile, 14)
        table.insert(first, (icon and icon .. " " or "") .. (color and Color(color, member.class) or member.class))
    end
    if type(member.level) == "number" and member.level > 0 then
        table.insert(first, L.Level:format(member.level))
    end
    if #first > 0 then
        table.insert(lines, table.concat(first, ", "))
    end
    local settings = ns.settings
    if settings.menuRace then
        local race, sex = Lines.Race(member)
        if race then
            local text = sex == 3 and L.RaceFemale or sex == 2 and L.RaceMale or "%s"
            table.insert(lines, L.Race:format(Color(WHITE, text:format(race))))
        end
    end
    if settings.menuRank and Filled(member.rank) then
        table.insert(lines, L.Rank:format(Color(WHITE, Lines.RankName(member.rank))))
    end
    if settings.menuStatus then
        table.insert(lines, L.Status:format(Status(member)))
    end
    if settings.menuZone and Filled(member.zone) then
        table.insert(lines, L.Zone:format(Color(WHITE, member.zone)))
    end
    if settings.menuProfessions then
        local professions = ns.Club.Professions(member.guid)
        if #professions > 0 then
            table.insert(lines, L.Professions:format(Color(WHITE, table.concat(professions, ", "))))
        end
    end
    if settings.menuNote and Filled(member.note) then
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
