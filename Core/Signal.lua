--[[
    AuroraFramework | Core.Signal
    Легковесная реализация сигналов для событийной модели.
]]

local Signal = {}
Signal.__index = Signal

-- Конструктор
function Signal.new()
    local self = setmetatable({}, Signal)
    self._connections = {}
    return self
end

-- Подключение функции-обработчика к сигналу
function Signal:Connect(func)
    if type(func) ~= "function" then
        error("Signal:Connect ожидает функцию.", 2)
    end

    local connection = {
        _func = func,
        _signal = self,
        Connected = true,
    }
    
    -- Добавляем метод Disconnect в саму таблицу соединения
    function connection:Disconnect()
        if not self.Connected then return end
        self.Connected = false
        
        local connections = self._signal._connections
        for i = #connections, 1, -1 do
            if connections[i] == self then
                table.remove(connections, i)
                break
            end
        end
    end

    table.insert(self._connections, connection)
    return connection
end

-- Вызов всех подключенных функций
function Signal:Fire(...)
    local args = {...}
    for _, conn in ipairs(self._connections) do
        if conn.Connected then
            -- Используем coroutine.wrap для изоляции ошибок в обработчиках
            coroutine.wrap(conn._func)(unpack(args))
        end
    end
end

-- Ожидание следующего вызова сигнала
function Signal:Wait()
    local thread = coroutine.running()
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        coroutine.resume(thread, ...)
    end)
    return coroutine.yield()
end

-- Уничтожение сигнала и всех его соединений
function Signal:Destroy()
    for _, conn in ipairs(self._connections) do
        conn.Connected = false
    end
    self._connections = {}
end

return Signal