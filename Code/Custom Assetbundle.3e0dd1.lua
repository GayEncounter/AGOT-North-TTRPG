local DOOR_LEFT_GUID = "faea72"
local DOOR_RIGHT_GUID = "0447f8"
local DELAY_TIME = 1.0  -- Задержка перед движением дверей

-- ==========================================
-- НАСТРОЙКА ИНДЕКСОВ (Смотри в Unity -> Looping Effects)
-- ==========================================

-- РЫЧАГ:
local LEVER_ANIM_OPEN = 0   -- Эффект рычага ВНИЗ
local LEVER_ANIM_CLOSE = 1  -- Эффект рычага ВВЕРХ

-- ДВЕРИ:
-- Судя по твоему скриншоту, у дверей 4 эффекта (0=idle, 1=open, 2=idle2, 3=close)
local DOOR_ANIM_OPEN = 1    -- Эффект ОТКРЫТИЯ дверей (idle_to_idle2)
local DOOR_ANIM_CLOSE = 3   -- Эффект ЗАКРЫТИЯ дверей (idle2_to_idle1)

-- ==========================================

local is_open = false
local door_L = nil
local door_R = nil

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

    door_L = getObjectFromGUID(DOOR_LEFT_GUID)
    door_R = getObjectFromGUID(DOOR_RIGHT_GUID)
    
    -- Костыль для TTS: принудительно ставим рычаг и двери в закрытое положение при старте
    self.AssetBundle.playLoopingEffect(LEVER_ANIM_CLOSE)
    if door_L then door_L.AssetBundle.playLoopingEffect(0) end -- 0 это Idle
    if door_R then door_R.AssetBundle.playLoopingEffect(0) end
end

function toggleLever()
    if not door_L or not door_R then return end

    if not is_open then
        is_open = true
        self.editButton({index=0, label="Закрыть"})
        
        -- РЫЧАГ: Анимация открытия
        self.AssetBundle.playLoopingEffect(LEVER_ANIM_OPEN)
        
        -- ДВЕРИ: Ждем 1 сек и открываем
        Wait.time(function()
            if door_L then door_L.AssetBundle.playLoopingEffect(DOOR_ANIM_OPEN) end
            if door_R then door_R.AssetBundle.playLoopingEffect(DOOR_ANIM_OPEN) end
        end, DELAY_TIME)

    else
        is_open = false
        self.editButton({index=0, label="Открыть"})
        
        -- РЫЧАГ: Анимация закрытия
        self.AssetBundle.playLoopingEffect(LEVER_ANIM_CLOSE)
        
        -- ДВЕРИ: Ждем 1 сек и закрываем
        Wait.time(function()
            if door_L then door_L.AssetBundle.playLoopingEffect(DOOR_ANIM_CLOSE) end
            if door_R then door_R.AssetBundle.playLoopingEffect(DOOR_ANIM_CLOSE) end
        end, DELAY_TIME)
    end
end