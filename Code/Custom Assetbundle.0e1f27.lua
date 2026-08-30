local GATE_GUID = "7e8fde"
local MAX_HEIGHT = 5.0
local DELAY_TIME = 1.0
local GATE_SPEED = 2.0

local is_open = false
local gate_obj = nil
local gate_start_pos = nil
local move_coroutine = nil

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
    if gate_obj then
        gate_obj.setLock(true) -- Принудительно морозим для физики
        gate_start_pos = gate_obj.getPosition()
    end
end

function toggleLever()
    if not gate_obj or not gate_start_pos then return end

    if not is_open then
        is_open = true
        self.editButton({index=0, label="Закрыть"})
        self.AssetBundle.playLoopingEffect(0) -- Рычаг ВНИЗ (Сразу!)
    else
        is_open = false
        self.editButton({index=0, label="Открыть"})
        self.AssetBundle.playLoopingEffect(1) -- Рычаг ВВЕРХ (Сразу!)
    end

    -- Убиваем старый мотор, если игрок кликнул дважды быстро
    if move_coroutine then Wait.stop(move_coroutine) end

    -- Задержка 1 секунда, потом старт мотора
    move_coroutine = Wait.time(function()
        startLuaCoroutine(self, "motorCoroutine")
    end, DELAY_TIME)
end

function motorCoroutine()
    local target_y = gate_start_pos.y
    if is_open then target_y = gate_start_pos.y + MAX_HEIGHT end

    while true do
        if not gate_obj then break end
        
        local cur = gate_obj.getPosition()
        local diff = target_y - cur.y

        -- Если доехали
        if math.abs(diff) < 0.02 then
            gate_obj.setPosition({cur.x, target_y, cur.z})
            break
        end

        -- Плавный шаг
        local step = GATE_SPEED * Time.delta_time
        if step > math.abs(diff) then step = math.abs(diff) end

        if diff > 0 then cur.y = cur.y + step
        else cur.y = cur.y - step end
        
        gate_obj.setPosition(cur)
        coroutine.yield(0)
    end
    return 1
end