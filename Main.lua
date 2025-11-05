--[[
    AuroraFramework v0.1.2
    Главный загрузчик (Web-версия)
]]

if getgenv().Aurora then
    pcall(getgenv().Aurora.Shutdown) -- Закрываем старую версию, если она есть
    warn("Перезагрузка AuroraFramework...")
end

-- --- ГЛОБАЛЬНАЯ СРЕДА ---
local Aurora = {
    _VERSION = "0.1.2",
    _LOADED_MODULES = {},
    _GUI_INSTANCES = {} -- Для отслеживания всех окон
}
-- URL для загрузки модулей
Aurora._ROOT_URL = string.format("https://raw.githubusercontent.com/%s/%s/%s", 
    "ВАШ_НИКНЕЙМ", -- ЗАМЕНИ НА СВОЙ НИК
    "AuroraFramework",
    "main" -- или 'master'
)
getgenv().Aurora = Aurora


-- --- ЗАГРУЗЧИК МОДУЛЕЙ ---
function Aurora:LoadModule(modulePath)
    if self._LOADED_MODULES[modulePath] then
        return self._LOADED_MODULES[modulePath]
    end

    local fullUrl = self._ROOT_URL .. "/" .. modulePath
    
    local success, code = pcall(game.HttpGet, game, fullUrl)
    if not success or not code then
        error("Не удалось загрузить модуль по URL: " .. fullUrl .. "\nОшибка: " .. tostring(code))
    end
    
    local chunk_name = "@" .. modulePath
    local module_func = loadstring(code, chunk_name)
    
    if not module_func then
        error("Не удалось скомпилировать модуль: " .. modulePath)
    end

    -- Создаем окружение для модуля, чтобы 'require' работал
    local module_env = setmetatable({
        script = { Parent = { Parent = { Parent = {} } } } -- Простая симуляция иерархии
    }, {__index = getfenv()})
    
    module_env.require = function(path_obj)
        -- Эта логика теперь намного проще, так как мы всегда работаем с полными путями
        local path_str
        if tostring(path_obj):find("Signal") then
            path_str = "Core/Signal.lua"
        else
            path_str = "Lib/UI/Window.lua"
        end
        return self:LoadModule(path_str)
    end
    
    setfenv(module_func, module_env)
    
    local success, module = pcall(module_func)
    if not success then
        error("Ошибка при выполнении модуля " .. chunk_name .. ": " .. tostring(module))
    end
    
    self._LOADED_MODULES[modulePath] = module
    return module
end

-- --- УПРАВЛЕНИЕ ЖИЗНЕННЫМ ЦИКЛОМ ---
function Aurora:Shutdown()
    for _, gui in pairs(self._GUI_INSTANCES) do
        if typeof(gui) == "Instance" and gui.Parent then
            gui:Destroy()
        end
    end
    getgenv().Aurora = nil
    print("AuroraFramework выгружен.")
end


-- --- ИНИЦИАЛИЗАЦИЯ ---
local Window = Aurora:LoadModule("Lib/UI/Window.lua")

local testWindow = Window.new({
    Title = "Aurora Framework v0.1.2 (Web)",
    Size = Vector2.new(450, 350)
})

table.insert(Aurora._GUI_INSTANCES, testWindow._gui) -- Регистрируем окно для будущего управления

local testLabel = Instance.new("TextLabel")
testLabel.Text = "Загрузка с GitHub прошла успешно!"
testLabel.Size = UDim2.new(1, -20, 0, 30)
testLabel.Position = UDim2.new(0, 10, 0, 10)
testLabel.TextColor3 = Color3.new(1,1,1)
testLabel.Font = Enum.Font.SourceSans
testLabel.TextSize = 16
testLabel.BackgroundTransparency = 1
testWindow:Add(testLabel)
testWindow:Show()
