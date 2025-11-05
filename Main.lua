--[[
    AuroraFramework v0.1.3
    Главный загрузчик (Web-версия с исправленным require)
]]

if getgenv().Aurora then
    pcall(getgenv().Aurora.Shutdown)
    warn("Перезагрузка AuroraFramework...")
end

-- --- ГЛОБАЛЬНАЯ СРЕДА ---
local Aurora = {
    _VERSION = "0.1.3",
    _LOADED_MODULES = {},
    _GUI_INSTANCES = {}
}
Aurora._ROOT_URL = string.format("https://raw.githubusercontent.com/%s/%s/%s", 
    "Burstgalaxy", -- Твой ник
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

    -- НОВАЯ, УЛУЧШЕННАЯ ЛОГИКА 'require'
    local module_env = setmetatable({}, {__index = getfenv()})
    
    local function resolve_path(current_path, require_path)
        local path_parts = current_path:split("/")
        table.remove(path_parts) -- убираем имя файла

        local require_parts = require_path:split("/")
        
        for _, part in ipairs(require_parts) do
            if part == ".." then
                table.remove(path_parts)
            else
                table.insert(path_parts, part)
            end
        end
        return table.concat(path_parts, "/")
    end
    
    local fake_script = {
        Parent = { Parent = { Parent = { Core = { Signal = {} } } } }
    }
    setmetatable(fake_script.Parent.Parent.Parent.Core.Signal, {
        __tostring = function() return "Core/Signal.lua" end
    })

    module_env.script = fake_script
    module_env.require = function(path_obj)
        local relative_path = tostring(path_obj)
        local final_path = resolve_path(modulePath, relative_path) .. ".lua"
        return self:LoadModule(final_path)
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
-- Строка 88: теперь 'Window' не должен быть nil
local Window = Aurora:LoadModule("Lib/UI/Window.lua")

local testWindow = Window.new({
    Title = "Aurora Framework v0.1.3 (Fixed)",
    Size = Vector2.new(450, 350)
})
table.insert(Aurora._GUI_INSTANCES, testWindow._gui)

local testLabel = Instance.new("TextLabel")
testLabel.Text = "Загрузчик модулей исправлен!"
testLabel.Size = UDim2.new(1, -20, 0, 30)
testLabel.Position = UDim2.new(0, 10, 0, 10)
testLabel.TextColor3 = Color3.new(1,1,1)
testLabel.Font = Enum.Font.SourceSans
testLabel.TextSize = 16
testLabel.BackgroundTransparency = 1
testWindow:Add(testLabel)

testWindow:Show()

print("AuroraFramework Core Initialized from GitHub (v0.1.3).")
