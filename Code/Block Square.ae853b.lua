-- Настройки сложности ИМЕННО ЭТОГО объекта
local MY_SPEED = 400     -- Скорость (400 = очень быстро)
local MY_TOLERANCE = 20  -- Ширина красной зоны (15 = очень узкая)

local is_unlocked = false

function onLoad()
    -- Вешаем кнопку на сам объект
    self.createButton({
        click_function = "triggerMinigame",
        function_owner = self,
        label          = "Взломать",
        position       = {0, 1, 0},
        width          = 2000,
        height         = 1000,
        font_size      = 400,
        scale          = {0.2, 0.2, 0.2}
    })
end

function triggerMinigame()
    if is_unlocked then
        print("Уже открыто!")
        return
    end

    -- Отправляем в Global команду открыть интерфейс с нашими настройками!
    Global.call("openQTE", {
        speed = MY_SPEED,
        tolerance = MY_TOLERANCE,
        guid = self.getGUID()
    })
end

-- Эту функцию вызовет Global, если игрок нажал 'K' вовремя
function onQteSuccess()
    is_unlocked = true
    self.editButton({index=0, label="Открыто", color={0,1,0}})
    
    printToAll("Игрок успешно взломал замок!", "Green")
    
    -- ТУТ МОЖЕШЬ ЗАПУСТИТЬ АНИМАЦИЮ ОТКРЫТИЯ (если это AssetBundle)
    -- self.AssetBundle.playLoopingEffect(1) 
end

-- Эту функцию вызовет Global, если игрок промазал
function onQteFail()
    printToAll("Отмычка сломалась...", "Red")
end