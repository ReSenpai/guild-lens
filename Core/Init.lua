-- The addon's namespace, its saved variables and the login hook the other files start from.
local addonName, ns = ...

ns.name = addonName

-- Strings by key; a key without a translation shows as itself. Filled in by Locales/.
ns.L = setmetatable({}, {
    __index = function (_, key)
        return key
    end
})

local defaults = {}

-- Read through ns.settings.<name>: the table is replaced once the saved variables are loaded.
ns.settings = setmetatable({}, {__index = defaults})
-- The saved variables table itself (GuildLensDB), for modules that keep data beside the settings.
ns.db = {}

local loginCallbacks = {}

--- Runs a function once the player has logged in, when every addon and saved variable is loaded.
function ns.OnLogin(callback)
    table.insert(loginCallbacks, callback)
end

--- Prints a line to the chat frame, prefixed with the addon's name.
function ns.Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGuildLens|r: " .. tostring(text))
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function (_, event, loaded)
    if event == "ADDON_LOADED" and loaded == addonName then
        GuildLensDB = GuildLensDB or {}
        -- What the development probe recorded before 0.1.0 (names of guild members): no longer needed.
        GuildLensDB.probe = nil
        ns.db = GuildLensDB
        ns.settings = setmetatable(GuildLensDB, {__index = defaults})
    elseif event == "PLAYER_LOGIN" then
        for _, callback in ipairs(loginCallbacks) do
            callback()
        end
    end
end)
