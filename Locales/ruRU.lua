local _, ns = ...
if GetLocale() ~= "ruRU" then
    return
end
local L = ns.L

-- Меню имени в чате гильдии
L.MenuTitle = "GuildLens"
L.Level = "уровень %d"
L.Rank = "Ранг: %s"
L.Status = "Статус: %s"
L.Online = "в сети"
L.Away = "нет на месте"
L.Busy = "не беспокоить"
L.Offline = "не в сети"
L.OfflineSince = "не в сети, последний вход %s"
L.YearsAgo = "%d г. назад"
L.MonthsAgo = "%d мес. назад"
L.DaysAgo = "%d д. назад"
L.HoursAgo = "%d ч. назад"
L.JustNow = "меньше часа назад"
L.Zone = "Зона: %s"
L.Note = "Заметка: %s"
L.NotLoaded = "Ростер гильдии ещё не загружен"
L.NotInRoster = "Нет в ростере гильдии"

-- Команды
L.CommandsHeader = "команды:"
L.CommandStatus = "/glens status — сколько участников гильдии известно"
L.UnknownCommand = "неизвестная команда «%s»."
L.NoGuild = "персонаж не в гильдии."
L.RosterStatus = "ростер гильдии: участников %d, в сети %d."
