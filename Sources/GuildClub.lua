--[[
What the guild's club (the communities system behind the guild window) knows of a member beyond the roster: race
and professions. C_Club.GetMemberInfo(clubId, memberId) gives (Forever 1.60.1): name, guid, level, classID, race
(race id), zone, guildRank, guildRankOrder, memberNote, presence, lastOnline*, profession1ID / profession1Name /
profession1Rank and the same for profession2 (the rank is always 1 there: no skill level), and more.

Members are found by GUID: the GUID → member id map is built from C_Club.GetClubMembers when it is needed after a
change of the guild; the member's info itself is asked fresh on each lookup. Clients without C_Club get nothing.
]]
local _, ns = ...

local Club = {}
ns.Club = Club

local memberIds = {}
local clubId
local stale = true

local function Available()
    return type(C_Club) == "table" and type(C_Club.GetGuildClubId) == "function"
        and type(C_Club.GetClubMembers) == "function" and type(C_Club.GetMemberInfo) == "function"
end

local function Rebuild()
    stale = false
    memberIds = {}
    clubId = C_Club.GetGuildClubId()
    if not clubId then
        return
    end
    for _, memberId in ipairs(C_Club.GetClubMembers(clubId) or {}) do
        local info = C_Club.GetMemberInfo(clubId, memberId)
        if type(info) == "table" and info.guid then
            memberIds[info.guid] = memberId
        end
    end
end

--- The club's info of the member with this GUID, or nil.
function Club.Info(guid)
    if not guid or not Available() then
        return nil
    end
    if stale then
        Rebuild()
    end
    local memberId = memberIds[guid]
    if not (clubId and memberId) then
        return nil
    end
    local info = C_Club.GetMemberInfo(clubId, memberId)
    if type(info) ~= "table" or info.guid ~= guid then
        stale = true
        return nil
    end
    return info
end

--- The member's professions by name, in the club's order (an empty list when it knows none).
function Club.Professions(guid)
    local info = Club.Info(guid)
    local names = {}
    if info then
        for _, key in ipairs({"profession1Name", "profession2Name"}) do
            if type(info[key]) == "string" and info[key] ~= "" then
                table.insert(names, info[key])
            end
        end
    end
    return names
end

local frame = CreateFrame("Frame")
-- Member ids don't change with the roster's frequent updates, only when members come and go.
for _, event in ipairs({"PLAYER_GUILD_UPDATE", "CLUB_MEMBER_ADDED", "CLUB_MEMBER_REMOVED"}) do
    -- The club events exist only on clients with C_Club.
    pcall(frame.RegisterEvent, frame, event)
end
frame:SetScript("OnEvent", function ()
    stale = true
end)
