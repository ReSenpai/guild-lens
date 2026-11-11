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
L.CommandOptions = "/glens — окно настроек"
L.CommandHelp = "/glens help — этот список"
L.CommandStatus = "/glens status — сколько участников гильдии известно"
L.CommandDebug = "/glens debug — записывать, что приходит в меню имён (для отчёта об ошибке), вкл/выкл"
L.DebugOn = "запись меню имён включена: открой меню, затем /reload; /glens debug ещё раз — выключить и забыть записанное."
L.DebugOff = "запись меню имён выключена, записанное забыто."
L.UnknownCommand = "неизвестная команда «%s»."
L.NoGuild = "персонаж не в гильдии."
L.RosterStatus = "ростер гильдии: участников %d, в сети %d."

-- Настройки
L.OptionsTitle = "GuildLens"
L.OptMenu = "Меню имени участника гильдии"
L.OptMenuHelp = "Правый щелчок по имени в чате гильдии или в окне гильдии: класс и уровень, а под ними то, что отмечено здесь."
L.OptMenuIcon = "Иконка класса"
L.OptMenuIconDesc = "Иконка класса перед его названием."
L.OptMenuRank = "Ранг"
L.OptMenuRankDesc = "Ранг участника в гильдии."
L.OptMenuStatus = "Статус"
L.OptMenuStatusDesc = "В сети, нет на месте или не беспокоить; у тех, кто не в сети, — когда был последний вход."
L.OptMenuZone = "Зона"
L.OptMenuZoneDesc = "Где участник сейчас; у тех, кто не в сети, — где был последним."
L.OptMenuNote = "Заметка"
L.OptMenuNoteDesc = "Публичная заметка участника, если она есть."
L.OptChat = "Чат гильдии"
L.OptChatHelp = "Что показывать об отправителе вместо [Гильдия]. Если ничего не отмечено, чат гильдии как в игре."
L.OptChatIcon = "Иконка класса"
L.OptChatIconDesc = "Иконка класса отправителя."
L.OptChatLevel = "Уровень"
L.OptChatLevelDesc = "Уровень отправителя."
L.OptChatZone = "Зона"
L.OptChatZoneDesc = "Где сейчас отправитель. С длинными названиями зон строка становится длиннее."
