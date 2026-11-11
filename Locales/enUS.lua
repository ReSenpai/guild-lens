local _, ns = ...
local L = ns.L

-- Slash commands
L.CommandsHeader = "commands:"
L.CommandProbe = "/glens probe — record what this client offers for the guild roster and the chat menu"
L.CommandProbeReset = "/glens probe reset — forget what was recorded"
L.UnknownCommand = "unknown command \"%s\"."

-- Probe (development only)
L.ProbeClient = "client %s (build %s, interface %s), locale %s"
L.ProbeGuild = "guild: %s, members: %s"
L.ProbeNoGuild = "the character is not in a guild"
L.ProbeFunctions = "roster functions: %s"
L.ProbeMissing = "missing: %s"
L.ProbeMenu = "menu: %s"
L.ProbeMenuModern = "Menu.ModifyMenu (hooked %d menus)"
L.ProbeMenuOld = "old drop-down menus"
L.ProbeNext = "Now right-click a name in guild chat, then type /reload: everything is written to the saved variables."
L.ProbeReset = "recorded data forgotten."
