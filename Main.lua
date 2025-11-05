--[[
    AuroraFramework v0.1.4
    Главный загрузчик (Web-версия с упрощенным require)
]]

if getgenv().Aurora then
    pcall(getgenv().Aurora.Shutdown)
    warn("Перезагрузка AuroraFramework...")
end

-- --- ГЛОБАЛЬНАЯ СРЕДА ---
local Aurora = {
    _VERSION = "0.1.4",
    _LOADED_MODULES = {},
    _GUI_INSTANCES = {}
}
Aurora._ROOT_URL = string.format("https://raw.githubusercontent.com/%s/%s/%s", 
    "Burstgalaxy",
    "AuroraFramework",
    "main"
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
    local module_func, compile_err = loadstring(code, chunk_name)
    
    if not module_func then
        error("Не удалось скомпилировать модуль: " .. modulePath .. "\nОшибка: " .. tostring(compile_err))
    end
    
    -- Просто выполняем код. Модуль сам позаботится о своих зависимостях.
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

-- Проверка, что модуль загрузился
if not Window then
    error("Критическая ошибка: Модуль Window не был загружен. Проверьте URL и код.")
end

local testWindow = Window.new({
    Title = "Aurora Framework v0.1.4 (Simplified)",
    Size = Vector2.new(450, 350)
})
table.insert(Aurora._GUI_INSTANCES, testWindow._gui)

local testLabel = Instance.new("TextLabel")
testLabel.Text = "Упрощенный загрузчик работает!"
testLabel.Size = UDim2.new(1, -20, 0, 30)
testLabel.Position = UDim2.new(0, 10, 0, 10)
testLabel.TextColor3 = Color3.new(1,1,1)
testLabel.Font = Enum.Font.SourceSans
testLabel.TextSize = 16
testLabel.BackgroundTransparency = 1
testWindow:Add(testLabel)

testWindow:Show()

print("AuroraFramework Core Initialized from GitHub (v0.1.4).")
