local _, ns = ...
if GetLocale() ~= "ruRU" then
    return
end
local L = ns.L

-- Команды
L.CommandsHeader = "команды:"
L.CommandProbe = "/glens probe — записать, что этот клиент даёт для ростера гильдии и меню чата"
L.CommandProbeReset = "/glens probe reset — забыть записанное"
L.UnknownCommand = "неизвестная команда «%s»."

-- Разведка (только для разработки)
L.ProbeClient = "клиент %s (сборка %s, интерфейс %s), язык %s"
L.ProbeGuild = "гильдия: %s, участников: %s"
L.ProbeNoGuild = "персонаж не в гильдии"
L.ProbeFunctions = "функции ростера: %s"
L.ProbeMissing = "нет: %s"
L.ProbeMenu = "меню: %s"
L.ProbeMenuModern = "Menu.ModifyMenu (подключено меню: %d)"
L.ProbeMenuOld = "старые выпадающие меню"
L.ProbeNext = "Теперь щёлкни правой кнопкой по имени в чате гильдии и набери /reload: всё запишется в сохранённые переменные."
L.ProbeReset = "записанное забыто."
