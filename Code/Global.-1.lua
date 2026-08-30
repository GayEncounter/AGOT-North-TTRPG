local MOVE_SPEED = 1.5 -- Скорость ходьбы
local activeMoves = {}

function onLoad()
    -- Передаем onMoveHotkey без кавычек
    addHotkey("Move Character", onMoveHotkey, false)
    print("Хоткей 'Move Character' готов к настройке!")
end

-- Срабатывает при нажатии назначенной клавиши (X)
function onMoveHotkey(player_color, hovered_object, pointer_position, is_key_up)
    if is_key_up then return end
    
    local player = Player[player_color]
    local selected = player.getSelectedObjects()

    for _, obj in ipairs(selected) do
        if obj.hasTag("NPC") then
            startMove(obj, pointer_position)
        end
    end
end

function startMove(obj, targetPos)
    local guid = obj.getGUID()
    if obj.AssetBundle then 
        obj.AssetBundle.playLoopingEffect(1) -- Включаем Walk
    end

    activeMoves[guid] = {
        obj = obj,
        target = targetPos,
        lastPos = obj.getPosition(),
        stuckTicks = 0
    }
end

function onFixedUpdate()
    for guid, data in pairs(activeMoves) do
        local obj = data.obj
        if obj == nil then
            activeMoves[guid] = nil
        else
            local curPos = obj.getPosition()
            local dx = data.target.x - curPos.x
            local dz = data.target.z - curPos.z
            local dist = math.sqrt(dx*dx + dz*dz)

            -- Дошли до точки назначения (ближе 0.4 юнитов)
            if dist <= 0.4 then
                stopMove(guid)
            else
                -- Плавный поворот к цели
                local angle = math.deg(math.atan2(dx, dz))
                obj.setRotation({0, angle, 0})

                -- Физическое движение
                local vx = (dx / dist) * MOVE_SPEED
                local vz = (dz / dist) * MOVE_SPEED
                obj.setVelocity({vx, obj.getVelocity().y, vz})

                -- Остановка, если уперлись в стену
                local moved = math.sqrt((curPos.x - data.lastPos.x)^2 + (curPos.z - data.lastPos.z)^2)
                if moved < 0.005 then
                    data.stuckTicks = data.stuckTicks + 1
                    if data.stuckTicks > 30 then stopMove(guid) end
                else
                    data.stuckTicks = 0
                end
                data.lastPos = curPos
            end
        end
    end
end

function stopMove(guid)
    local data = activeMoves[guid]
    if data and data.obj then
        data.obj.setVelocity({0, 0, 0})
        if data.obj.AssetBundle then 
            data.obj.AssetBundle.playLoopingEffect(0) -- Включаем Idle
        end
    end
    activeMoves[guid] = nil
end

-- =======================================
-- ЯДРО МИНИ-ИГРЫ (ЛИНЕЙНАЯ ШКАЛА)
-- =======================================
local is_qte_playing = false

-- Настройки полосы
local TRACK_HALF_WIDTH = 150 -- Половина длины полосы (Общая длина 300)
local qte_current_x = -TRACK_HALF_WIDTH
local qte_direction = 1 -- 1 (вправо), -1 (влево)
local qte_target_x = 0

local qte_speed = 300
local qte_tolerance = 20
local qte_caller_guid = nil

function onLoad()
    math.randomseed(os.time())
    addHotkey("Minigame QTE", onQTEPress, false)
    
    Global.UI.setXml([=[
        <Panel id="sky_container" active="false" width="400" height="380" rectAlignment="MiddleCenter" color="#111111F2" outline="#555555" outlineSize="3">
            <Text id="sky_title" text="ВЗЛОМ: 3 ОТМЫЧКИ" rectAlignment="UpperCenter" offsetXY="0 -15" color="#FFFFFF" fontSize="22"/>
            <Text id="sky_status" text="Ищите правильный угол" rectAlignment="UpperCenter" offsetXY="0 -45" color="#AAAAAA" fontSize="14"/>
            
            <Panel width="260" height="260" rectAlignment="MiddleCenter" offsetXY="0 10">
                <Text text="O" fontSize="300" color="#333333" rectAlignment="MiddleCenter" offsetXY="0 -18"/>
                <Text id="sky_hole" text="|" fontSize="80" color="#777777" rectAlignment="MiddleCenter" />
                <Text id="sky_pick" text="O" fontSize="25" color="#FFFFFF" outline="#000000" outlineSize="2" rectAlignment="MiddleCenter" />
            </Panel>
            
            <Button id="btn_left" onClick="movePickLeft" text="ВЛЕВО" rectAlignment="LowerLeft" offsetXY="20 20" width="90" height="40" color="#444444" textColor="#FFFFFF" />
            <Button id="btn_turn" onClick="tryTurnLock" text="ПОВЕРНУТЬ" rectAlignment="LowerCenter" offsetXY="0 20" width="140" height="40" color="#AA7722" textColor="#FFFFFF" />
            <Button id="btn_right" onClick="movePickRight" text="ВПРАВО" rectAlignment="LowerRight" offsetXY="-20 20" width="90" height="40" color="#444444" textColor="#FFFFFF" />
            
            <Button onClick="closeSkyrim" text="X" rectAlignment="UpperRight" width="30" height="30" color="#AA2222" textColor="#FFFFFF"/>
        </Panel>
    ]=])
end

function openQTE(params)
    qte_speed = params.speed or 300
    qte_tolerance = params.tolerance or 20
    qte_caller_guid = params.guid

    is_qte_playing = true
    qte_current_x = -TRACK_HALF_WIDTH -- Начинаем всегда с левого края
    qte_direction = 1                 -- Едем вправо

    -- Идеальная калибровка ширины красной зоны (Толерантность * 2)
    local target_width = qte_tolerance * 2
    Global.UI.setAttribute("qte_target", "width", target_width)

    -- Случайная позиция красной зоны, чтобы она не вылезала за края полосы
    local min_x = -TRACK_HALF_WIDTH + qte_tolerance
    local max_x = TRACK_HALF_WIDTH - qte_tolerance
    qte_target_x = math.random(min_x, max_x)
    
    Global.UI.setAttribute("qte_target", "offsetXY", math.floor(qte_target_x) .. " 15")

    -- Сброс текстов
    Global.UI.setAttribute("qte_title", "text", "ВЗЛОМ ЗАМКА")
    Global.UI.setAttribute("qte_title", "color", "#FFFFFF")
    Global.UI.setAttribute("qte_subtitle", "text", "(Нажмите 'K' в красной зоне)")
    Global.UI.setAttribute("qte_subtitle", "color", "#AAAAAA")
    
    Global.UI.setAttribute("qte_container", "active", "true")
end

function hideQTE()
    is_qte_playing = false
    Global.UI.setAttribute("qte_container", "active", "false")
end

function onUpdate()
    if is_qte_playing then
        -- Двигаем бегунок
        qte_current_x = qte_current_x + (qte_speed * Time.delta_time * qte_direction)
        
        -- Эффект Пинг-Понга (отталкиваемся от краев)
        if qte_current_x >= TRACK_HALF_WIDTH then
            qte_current_x = TRACK_HALF_WIDTH
            qte_direction = -1
        elseif qte_current_x <= -TRACK_HALF_WIDTH then
            qte_current_x = -TRACK_HALF_WIDTH
            qte_direction = 1
        end
        
        Global.UI.setAttribute("qte_pointer", "offsetXY", math.floor(qte_current_x) .. " 15")
    end
end

function onQTEPress(player_color, hovered_object, pointer_position, is_key_up)
    if is_key_up or not is_qte_playing then return end
    is_qte_playing = false -- Останавливаем бегунок
    
    -- Высчитываем разницу в пикселях
    local diff = math.abs(qte_current_x - qte_target_x)
    
    local caller_obj = nil
    if qte_caller_guid then caller_obj = getObjectFromGUID(qte_caller_guid) end

    -- Выводим точность в чат
    printToColor("Сдвиг от центра: " .. math.floor(diff) .. "px (Допуск: " .. qte_tolerance .. "px)", player_color, "Yellow")

    if diff <= qte_tolerance then
        Global.UI.setAttribute("qte_title", "text", "УСПЕХ!")
        Global.UI.setAttribute("qte_title", "color", "#55FF55")
        Global.UI.setAttribute("qte_subtitle", "text", "Вы попали!")
        
        if caller_obj then caller_obj.call("onQteSuccess") end
        Wait.time(hideQTE, 1.5)
    else
        Global.UI.setAttribute("qte_title", "text", "ПРОВАЛ!")
        Global.UI.setAttribute("qte_title", "color", "#FF5555")
        Global.UI.setAttribute("qte_subtitle", "text", "Мимо на " .. math.floor(diff) .. "px")
        
        if caller_obj and caller_obj.getVar("onQteFail") then 
            caller_obj.call("onQteFail") 
        end
        Wait.time(hideQTE, 1.5)
    end
end

-- =======================================
-- СИСТЕМА ВЗЛОМА SKYRIM (НАТЯЖЕНИЕ)
-- =======================================
local is_active = false
local state = "idle" -- "idle", "turning" (крутится), "stuck" (застрял/ломается), "returning" (возврат)

local pick_angle = 0
local sweet_spot = 0
local lock_angle = 0
local max_allowed_turn = 0

local pick_health = 100    -- Здоровье отмычки
local tolerance = 15
local picks_left = 3
local caller_guid = nil
local RADIUS = 120

function dbg(msg)
    print("[SKYRIM DEBUG] " .. msg)
end

function onLoad()
    math.randomseed(os.time())
    Global.UI.setXml([=[
        <Panel id="sky_container" active="false" width="400" height="380" rectAlignment="MiddleCenter" color="#111111F2" outline="#555555" outlineSize="3">
            <Text id="sky_title" text="ВЗЛОМ: 3 ОТМЫЧКИ" rectAlignment="UpperCenter" offsetXY="0 -15" color="#FFFFFF" fontSize="22"/>
            <Text id="sky_status" text="Ищите правильный угол" rectAlignment="UpperCenter" offsetXY="0 -45" color="#AAAAAA" fontSize="14"/>
            
            <Panel width="260" height="260" rectAlignment="MiddleCenter" offsetXY="0 10">
                <Text text="O" fontSize="300" color="#333333" rectAlignment="MiddleCenter" offsetXY="0 -18"/>
                <Text id="sky_hole" text="|" fontSize="80" color="#777777" rectAlignment="MiddleCenter" />
                <Text id="sky_pick" text="O" fontSize="25" color="#FFFFFF" outline="#000000" outlineSize="2" rectAlignment="MiddleCenter" />
            </Panel>
            
            <Button id="btn_left" onClick="movePickLeft" text="ВЛЕВО" rectAlignment="LowerLeft" offsetXY="20 20" width="90" height="40" color="#444444" textColor="#FFFFFF" />
            
            <!-- Кнопка натяжения теперь шире и по центру -->
            <Button id="btn_turn" onClick="toggleTension" text="НАПРЯЧЬ ЗАМОК" rectAlignment="LowerCenter" offsetXY="0 20" width="180" height="40" color="#AA7722" textColor="#FFFFFF" />
            
            <Button id="btn_right" onClick="movePickRight" text="ВПРАВО" rectAlignment="LowerRight" offsetXY="-20 20" width="90" height="40" color="#444444" textColor="#FFFFFF" />
            
            <Button onClick="closeSkyrim" text="X" rectAlignment="UpperRight" width="30" height="30" color="#AA2222" textColor="#FFFFFF"/>
        </Panel>
    ]=])
end

function openSkyrimLock(params)
    tolerance = params.tolerance or 15
    picks_left = params.picks or 3
    caller_guid = params.guid
    
    is_active = true
    state = "idle"
    pick_angle = 0
    lock_angle = 0
    pick_health = 100
    
    sweet_spot = math.random(-80, 80)
    dbg("=== НАЧАТ ВЗЛОМ ===")
    dbg("СЕКРЕТНАЯ ТОЧКА: " .. sweet_spot)
    
    Global.UI.setAttribute("btn_left", "active", "true")
    Global.UI.setAttribute("btn_right", "active", "true")
    Global.UI.setAttribute("btn_turn", "active", "true")
    Global.UI.setAttribute("btn_turn", "text", "НАПРЯЧЬ ЗАМОК")
    Global.UI.setAttribute("btn_turn", "color", "#AA7722")
    
    updateUI()
    Global.UI.setAttribute("sky_container", "active", "true")
end

function closeSkyrim()
    is_active = false
    Global.UI.setAttribute("sky_container", "active", "false")
end

function movePickLeft()
    if state ~= "idle" then return end
    pick_angle = pick_angle - 5
    if pick_angle < -90 then pick_angle = -90 end
    updateUI()
end

function movePickRight()
    if state ~= "idle" then return end
    pick_angle = pick_angle + 5
    if pick_angle > 90 then pick_angle = 90 end
    updateUI()
end

-- ================= УПРАВЛЕНИЕ НАТЯЖЕНИЕМ =================
function toggleTension()
    if state == "idle" then
        -- НАЧИНАЕМ НАТЯЖЕНИЕ
        local diff = math.abs(pick_angle - sweet_spot)
        if diff <= tolerance then
            max_allowed_turn = 90
        else
            local fail_ratio = (diff - tolerance) / 90.0
            max_allowed_turn = 90 - (90 * fail_ratio)
            if max_allowed_turn < 10 then max_allowed_turn = 10 end
            if max_allowed_turn > 85 then max_allowed_turn = 85 end
        end
        
        state = "turning"
        Global.UI.setAttribute("btn_left", "active", "false")
        Global.UI.setAttribute("btn_right", "active", "false")
        Global.UI.setAttribute("btn_turn", "text", "ОТПУСТИТЬ ЗАМОК")
        Global.UI.setAttribute("btn_turn", "color", "#44AA44")
        dbg("НАТЯЖЕНИЕ! Замок крутится до: " .. math.floor(max_allowed_turn))
        
    elseif state == "turning" or state == "stuck" then
        -- ИГРОК ИСПУГАЛСЯ И ОТПУСТИЛ ЗАМОК
        state = "returning"
        Global.UI.setAttribute("btn_turn", "active", "false")
        Global.UI.setAttribute("btn_turn", "color", "#AA7722")
        dbg("ИГРОК ОТПУСТИЛ ЗАМОК. Возврат.")
    end
end

-- ================= ФИЗИКА И АНИМАЦИЯ =================
function onUpdate()
    if not is_active then return end
    
    if state == "turning" then
        lock_angle = lock_angle + (120 * Time.delta_time)
        
        if lock_angle >= max_allowed_turn then
            lock_angle = max_allowed_turn
            if max_allowed_turn >= 90 then
                dbg("УСПЕХ! ЗАМОК ОТКРЫТ!")
                Global.UI.setAttribute("sky_status", "text", "ЗАМОК ОТКРЫТ!")
                Global.UI.setAttribute("sky_status", "color", "#55FF55")
                Global.UI.setAttribute("btn_turn", "active", "false")
                state = "success"
                
                local caller = nil
                if caller_guid then caller = getObjectFromGUID(caller_guid) end
                if caller then caller.call("onSkyrimSuccess") end
                Wait.time(closeSkyrim, 1.5)
            else
                -- Уперлись! Переходим в режим поломки отмычки
                state = "stuck"
                dbg("ЗАМОК УПЕРСЯ! Отмычка начинает ломаться...")
            end
        end
        updateUI()
        
    elseif state == "stuck" then
        -- Отмычка теряет ХП каждую секунду натяжения (сломается за 1.5 секунды)
        pick_health = pick_health - (65 * Time.delta_time)
        
        if pick_health <= 0 then
            -- СЛОМАЛАСЬ!
            dbg("ОТМЫЧКА СЛОМАНА!")
            picks_left = picks_left - 1
            Global.UI.setAttribute("sky_title", "text", "ВЗЛОМ: " .. picks_left .. " ОТМЫЧКИ")
            Global.UI.setAttribute("btn_turn", "active", "false")
            
            state = "returning"
            
            if picks_left <= 0 then
                dbg("ОТМЫЧКИ ЗАКОНЧИЛИСЬ. ПРОВАЛ.")
                local caller = nil
                if caller_guid then caller = getObjectFromGUID(caller_guid) end
                if caller and caller.getVar("onSkyrimFail") then caller.call("onSkyrimFail") end
                Wait.time(closeSkyrim, 1.0)
            end
        end
        updateUI() -- Вызов updateUI здесь запустит визуальную тряску!
        
    elseif state == "returning" then
        lock_angle = lock_angle - (250 * Time.delta_time)
        if lock_angle <= 0 then
            lock_angle = 0
            state = "idle"
            pick_health = 100 -- Сбрасываем ХП отмычки для новой попытки
            Global.UI.setAttribute("btn_left", "active", "true")
            Global.UI.setAttribute("btn_right", "active", "true")
            Global.UI.setAttribute("btn_turn", "active", "true")
            Global.UI.setAttribute("btn_turn", "text", "НАПРЯЧЬ ЗАМОК")
            dbg("Замок в нуле. Можно крутить отмычку.")
        end
        updateUI()
    end
end

function updateUI()
    local hole_x = 0
    local hole_y = 0
    
    -- ТРЯСКА: Если мы застряли, добавляем рандомный сдвиг для серой отмычки (линии)
    if state == "stuck" then
        hole_x = math.random(-4, 4)
        hole_y = math.random(-4, 4)
    end
    
    -- Вращаем серую линию и трясем её
    Global.UI.setAttribute("sky_hole", "rotation", "0 0 " .. (-lock_angle))
    Global.UI.setAttribute("sky_hole", "offsetXY", hole_x .. " " .. hole_y)
    
    -- Позиция белого ползунка-индикатора (крутится вместе с замком)
    local total_angle = pick_angle + lock_angle
    local px = RADIUS * math.sin(math.rad(total_angle))
    local py = RADIUS * math.cos(math.rad(total_angle))
    
    -- Белый ползунок тоже чуть-чуть вибрирует за компанию
    if state == "stuck" then
        px = px + math.random(-2, 2)
        py = py + math.random(-2, 2)
    end
    
    Global.UI.setAttribute("sky_pick", "offsetXY", math.floor(px) .. " " .. math.floor(py))
end