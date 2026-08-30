function onRandomize(player_color)
    rollRandomFlat()
end

function onDrop(player_color)
    rollRandomFlat()
end

function rollRandomFlat()
    -- 1. Запоминаем скорость, с которой игрок швырнул кубик
    local vel = self.getVelocity()
    
    -- 2. Ставим ЧЕСТНУЮ СЛУЧАЙНУЮ грань от 1 до 6
    self.setValue(math.random(1, 20))
    
    -- 3. Возвращаем инерцию, чтобы он не замерзал в воздухе
    self.setVelocity(vel)
    
    -- 4. Плоское вращение. Он будет крутиться как фрисби и 100% упадет на ту случайную грань, которую выбрал скрипт
    local random_spin = math.random(-30, 30)
    self.setAngularVelocity({0, random_spin, 0})
end