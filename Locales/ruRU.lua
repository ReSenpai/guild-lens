local _, ns = ...
if GetLocale() ~= "ruRU" then
    return
end
local L = ns.L

-- Меню имени в чате гильдии
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

-- Стандартные названия рангов, которые игра даёт новой гильдии (если глава их не менял). Свои названия не трогаем.
ns.RankNames = {
    ["Guild Master"] = "Глава гильдии",
    ["Officer"] = "Офицер",
    ["Veteran"] = "Ветеран",
    ["Member"] = "Участник",
    ["Initiate"] = "Новичок"
}

-- Команды
L.CommandsHeader = "команды:"
L.CommandStatus = "/glens status — сколько участников гильдии известно"
L.CommandChat = "/glens chat icon | level | zone — показывать в чате гильдии вместо [Гильдия] или перестать"
L.CommandChatOff = "/glens chat off — чат гильдии как в игре"
L.ChatShows = "чат гильдии: вместо [Гильдия] — %s."
L.ChatAsGame = "чат гильдии как в игре."
L.ChatPart_icon = "иконка класса"
L.ChatPart_level = "уровень"
L.ChatPart_zone = "зона"
L.CommandDebug = "/glens debug — записывать, что приходит в меню имён (для отчёта об ошибке), вкл/выкл"
L.DebugOn = "запись меню имён включена: открой меню, затем /reload; /glens debug ещё раз — выключить и забыть записанное."
L.DebugOff = "запись меню имён выключена, записанное забыто."
L.UnknownCommand = "неизвестная команда «%s»."
L.NoGuild = "персонаж не в гильдии."
L.RosterStatus = "ростер гильдии: участников %d, в сети %d."
