--[[
    AuroraFramework | Lib.UI.Window
    Модуль для создания, управления и рендеринга окон.
    Вдохновлен реализацией из Dex.
]]

-- Загружаем зависимости через относительный путь
local Signal = getgenv().Aurora:LoadModule("Core/Signal.lua")

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Утилита для создания UI, чтобы не засорять код
local function create(instanceType, properties)
    local inst = Instance.new(instanceType)
    for prop, value in pairs(properties or {}) do
        inst[prop] = value
    end
    return inst
end

-- Статические переменные для управления ZIndex всех окон
local zManager = {
    base = 500, -- Начальный Z-index
    top = 500
}

local Window = {}
Window.__index = Window

-- Конструктор
function Window.new(options)
    local self = setmetatable({}, Window)

    -- Параметры
    self.Title = options.Title or "Window"
    self.Size = options.Size or Vector2.new(300, 200)
    self.MinSize = options.MinSize or Vector2.new(150, 100)
    self.Draggable = options.Draggable ~= false
    self.Resizable = options.Resizable ~= false
    self.ShowCloseButton = options.ShowCloseButton ~= false
    self.ShowMinimizeButton = options.ShowMinimizeButton ~= false
    
    -- Внутреннее состояние
    self._isDragging = false
    self._isResizing = false
    self._isMinimized = false
    self._gui = nil
    self._elements = {}

    -- Сигналы
    self.OnClose = Signal.new()
    self.OnMinimize = Signal.new()
    self.OnFocus = Signal.new()

    self:_buildGui()
    
    return self
end

-- Приватный метод для сборки UI
function Window:_buildGui()
    zManager.top = zManager.top + 1
    self.zIndex = zManager.top

    self._gui = create("ScreenGui", {
        Name = self.Title,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
    })

    local mainFrame = create("Frame", {
        Name = "MainFrame",
        Size = UDim2.fromOffset(self.Size.X, self.Size.Y),
        Position = UDim2.fromScale(0.5, 0.5) - UDim2.fromOffset(self.Size.X / 2, self.Size.Y / 2),
        BackgroundColor3 = Color3.fromRGB(45, 45, 45),
        BorderSizePixel = 0,
        Active = true,
        ClipsDescendants = true,
        ZIndex = self.zIndex,
        Parent = self._gui
    })
    self._elements.MainFrame = mainFrame

    -- Тень/обводка
    local shadow = create("ImageLabel", {
        Name = "Shadow",
        Image = "rbxassetid://1427967925",
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(6, 6, 25, 25),
        ImageColor3 = Color3.fromRGB(33, 33, 33),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 10, 1, 10),
        Position = UDim2.new(0, -5, 0, -5),
        ZIndex = self.zIndex - 1,
        Parent = mainFrame
    })
    self._elements.Shadow = shadow

    -- Шапка
    local topBar = create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Color3.fromRGB(52, 52, 52),
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    self._elements.TopBar = topBar
    
    local titleLabel = create("TextLabel", {
        Name = "Title",
        Text = self.Title,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Parent = topBar
    })

    -- Кнопка "Закрыть"
    if self.ShowCloseButton then
        local closeButton = create("TextButton", {
            Name = "CloseButton",
            Text = "",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(1, -20, 0, 3),
            BackgroundColor3 = Color3.fromRGB(52, 52, 52),
            Parent = topBar
        })
        create("ImageLabel", { Image = "rbxassetid://5054663650", Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 3, 0, 3), BackgroundTransparency = 1, Parent = closeButton })
        closeButton.MouseButton1Click:Connect(function() self:Close() end)
    end
    
    -- Контентная область
    local content = create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -22),
        Position = UDim2.new(0, 0, 0, 22),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = mainFrame
    })
    self.Content = content
    
    self:_attachHandlers()
end

-- Приватный метод для подключения обработчиков событий
function Window:_attachHandlers()
    local mainFrame = self._elements.MainFrame
    local topBar = self._elements.TopBar
    
    -- Фокус окна
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:Focus()
        end
    end)
    
    -- Перетаскивание
    if self.Draggable then
        topBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self._isDragging = true
                local startPos = UserInputService:GetMouseLocation()
                local frameStartPos = mainFrame.AbsolutePosition
                
                local moveConn, releaseConn
                
                moveConn = UserInputService.InputChanged:Connect(function(moveInput)
                    if moveInput.UserInputType == Enum.UserInputType.MouseMovement then
                        local delta = UserInputService:GetMouseLocation() - startPos
                        mainFrame.Position = UDim2.fromOffset(frameStartPos.X + delta.X, frameStartPos.Y + delta.Y)
                    end
                end)
                
                releaseConn = UserInputService.InputEnded:Connect(function(endInput)
                    if endInput.UserInputType == Enum.UserInputType.MouseButton1 then
                        self._isDragging = false
                        moveConn:Disconnect()
                        releaseConn:Disconnect()
                    end
                end)
            end
        end)
    end
    
    -- Изменение размера
    if self.Resizable then
        -- TODO: Добавить 8 ручек для изменения размера
    end
end

-- Публичные методы
function Window:Show()
    self._gui.Enabled = true
    self:Focus()
end

function Window:Close()
    self.OnClose:Fire()
    self._gui:Destroy()
end

function Window:Add(element)
    if element and element.Parent == nil then
        element.Parent = self.Content
    end
end

function Window:Focus()
    if self.zIndex ~= zManager.top then
        zManager.top = zManager.top + 1
        self.zIndex = zManager.top
        self._elements.MainFrame.ZIndex = self.zIndex
        self._elements.Shadow.ZIndex = self.zIndex - 1
        self.OnFocus:Fire()
    end
end


return Window

