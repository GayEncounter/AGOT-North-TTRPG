local TARGET_VALUE = 6 

function onRandomize(player_color)
    rigTheRoll()
end

function onDrop(player_color)
    rigTheRoll()
end

function rigTheRoll()
    -- 1. Запоминаем ЕГО РОДНУЮ скорость падения в эту миллисекунду
    local vel = self.getVelocity()
    
    -- 2. Ставим грань (в этот момент TTS пытается его заморозить)
    self.setValue(TARGET_VALUE)
    
    -- 3. Возвращаем ему его же скорость, чтобы он продолжил падать как ни в чем не бывало!
    -- Высоту (Position) мы вообще не трогаем.
    self.setVelocity(vel)
    
    -- 4. Оставляем плоское вращение
    local random_spin = math.random(-30, 30)
    self.setAngularVelocity({0, random_spin, 0})
end