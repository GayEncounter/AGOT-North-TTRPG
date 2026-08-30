-- НАСТРОЙКИ СЛОЖНОСТИ ЭТОГО СУНДУКА
local LOCK_TOLERANCE = 10 -- Допуск в градусах (меньше = сложнее)
local PICKS_AMOUNT = 3    -- Сколько отмычек дается на взлом

local is_unlocked = false

function onLoad()
    self.createButton({
        click_function = "startLockpick",
        function_owner = self,
        label          = "Взломать",
        position       = {0, 1.2, 0},
        width          = 1000, height = 350, font_size = 200, scale = {0.1, 0.1, 0.1}
    })
end

function startLockpick()
    if is_unlocked then
        print("Замок уже открыт!")
        return
    end

    print("--- ЗАПРАШИВАЮ МИНИ-ИГРУ U С СЕРВЕРА ---")
    Global.call("openSkyrimLock", {
        tolerance = LOCK_TOLERANCE,
        picks = PICKS_AMOUNT,
        guid = self.getGUID()
    })
end

function onSkyrimSuccess()
    is_unlocked = true
    self.editButton({index=0, label="Открыто", color={0,1,0}})
    printToAll("Сундук успешно открыт!", "Green")
end

function onSkyrimFail()
    printToAll("Все отмычки сломались. Замок заклинило!", "Red")
    self.editButton({index=0, label="Заклинило", color={1,0,0}})
end