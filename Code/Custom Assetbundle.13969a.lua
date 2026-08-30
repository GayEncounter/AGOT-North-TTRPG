local GATE_GUID = "9f28f7"
local DELAY_TIME = 1.0  -- Задержка в секундах перед движением ворот

-- ==========================================
-- НАСТРОЙКА ИНДЕКСОВ (Смотри в Unity -> Looping Effects)
-- ==========================================

-- РЫЧАГ:
local LEVER_ANIM_OPEN = 0   -- Эффект рычага ВНИЗ
local LEVER_ANIM_CLOSE = 1  -- Эффект рычага ВВЕРХ

-- ВОРОТА:
-- Впиши сюда цифры эффектов из Unity для ворот
local GATE_ANIM_OPEN = 1    -- Эффект, где ворота едут ВВЕРХ
local GATE_ANIM_CLOSE = 3   -- Эффект, где ворота едут ВНИЗ

-- ==========================================

local is_open = false
local gate_obj = nil

function onLoad()
    self.createButton({
        click_function = "toggleLever",
        function_owner = self,
        label          = "Открыть",
        position       = {0, 0.3, 0},
        width          = 1400, height = 400, font_size = 200,
        color          = {0.2, 0.2, 0.2, 1}, font_color = {1, 1, 1, 1},
        scale          = {0.1, 0.1, 0.1}
    })

    gate_obj = getObjectFromGUID(GATE_GUID)
    
    -- Костыль для TTS: принудительно ставим всё в закрытое положение при старте
    self.AssetBundle.playLoopingEffect(LEVER_ANIM_CLOSE)
    if gate_obj then 
        gate_obj.AssetBundle.playLoopingEffect(0) -- 0 обычно это Idle (закрытые ворота)
    else
        print("ОШИБКА: Ворота не найдены! Проверь GUID.")
    end
end

function toggleLever()
    if not gate_obj then return end

    if not is_open then
        is_open = true
        self.editButton({index=0, label="Закрыть"})
        
        -- РЫЧАГ: Анимация рычага вниз (Сразу!)
        self.AssetBundle.playLoopingEffect(LEVER_ANIM_OPEN)
        
        -- ВОРОТА: Ждем 1 сек и запускаем анимацию ВВЕРХ
        Wait.time(function()
            if gate_obj then gate_obj.AssetBundle.playLoopingEffect(GATE_ANIM_OPEN) end
        end, DELAY_TIME)

    else
        is_open = false
        self.editButton({index=0, label="Открыть"})
        
        -- РЫЧАГ: Анимация рычага вверх (Сразу!)
        self.AssetBundle.playLoopingEffect(LEVER_ANIM_CLOSE)
        
        -- ВОРОТА: Ждем 1 сек и запускаем анимацию ВНИЗ
        Wait.time(function()
            if gate_obj then gate_obj.AssetBundle.playLoopingEffect(GATE_ANIM_CLOSE) end
        end, DELAY_TIME)
    end
end