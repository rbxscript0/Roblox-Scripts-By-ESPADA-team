--[[
    EspadaWare v2.0 — Vagrant Survival
    Полный LocalScript с GUI, функционалом, настройками и автосохранением
]]

-- ═══════════════════════════════════════════════════════════════
-- СЕРВИСЫ
-- ═══════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- ═══════════════════════════════════════════════════════════════
-- КОНФИГ СИСТЕМА
-- ═══════════════════════════════════════════════════════════════
local CONFIG_KEY = "EspadaWare_VagrantSurvival_Config"
local DefaultConfig = {
    -- Main
    Aimbot = {Enabled = false, FOV = 120, Smoothness = 5, TargetPart = "Head", ShowFOV = true, TeamCheck = false, AimKey = "MouseButton2"},
    AutoAttack = {Enabled = false, Delay = 0.15, Mode = "Hold"},
    AutoPickup = {Enabled = false, Range = 25, Items = true, Resources = true, Weapons = false},
    KillAura = {Enabled = false, Range = 15, Delay = 0.2},
    -- Movement
    Speed = {Enabled = false, Value = 24, Mode = "WalkSpeed"},
    InfiniteJump = {Enabled = false, Power = 55},
    Noclip = {Enabled = false},
    Fly = {Enabled = false, FlySpeed = 50},
    AutoSprint = {Enabled = false},
    -- Visuals
    ESP = {Enabled = false, ShowNames = true, ShowHealth = true, ShowDistance = true, ShowBox = true, MaxDistance = 500, TeamCheck = false},
    Fullbright = {Enabled = false},
    NoFog = {Enabled = false},
    ItemESP = {Enabled = false, MaxDistance = 300},
    ChamPlayers = {Enabled = false, FillColor = {1, 0.2, 0.2}, OutlineColor = {1, 1, 1}},
    -- Settings
    GuiKeybind = "RightShift",
    Theme = "Dark",
    Notifications = true,
    AutoSave = true,
    ButtonScale = 1,
}

local Config = {}

local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

local function MergeConfig(base, override)
    local result = DeepCopy(base)
    if type(override) ~= "table" then return result end
    for k, v in pairs(override) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = MergeConfig(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

local function SaveConfig()
    pcall(function()
        if writefile then
            writefile(CONFIG_KEY .. ".json", HttpService:JSONEncode(Config))
        end
    end)
end

local function LoadConfig()
    local success, data = pcall(function()
        if readfile and isfile and isfile(CONFIG_KEY .. ".json") then
            return HttpService:JSONDecode(readfile(CONFIG_KEY .. ".json"))
        end
        return nil
    end)
    if success and data then
        Config = MergeConfig(DefaultConfig, data)
    else
        Config = DeepCopy(DefaultConfig)
    end
end

local function ResetConfig()
    Config = DeepCopy(DefaultConfig)
    SaveConfig()
end

LoadConfig()

-- ═══════════════════════════════════════════════════════════════
-- УТИЛИТЫ
-- ═══════════════════════════════════════════════════════════════
local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function CreateInstance(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties or {}) do
        if k ~= "Parent" then
            pcall(function() inst[k] = v end)
        end
    end
    if properties and properties.Parent then
        inst.Parent = properties.Parent
    end
    return inst
end

local function AddCorner(parent, radius)
    return CreateInstance("UICorner", {CornerRadius = UDim.new(0, radius or 8), Parent = parent})
end

local function AddStroke(parent, color, thickness, transparency)
    return CreateInstance("UIStroke", {
        Color = color or Color3.fromRGB(60, 60, 80),
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        Parent = parent
    })
end

local function AddPadding(parent, t, b, l, r)
    return CreateInstance("UIPadding", {
        PaddingTop = UDim.new(0, t or 8),
        PaddingBottom = UDim.new(0, b or 8),
        PaddingLeft = UDim.new(0, l or 8),
        PaddingRight = UDim.new(0, r or 8),
        Parent = parent
    })
end

local function AddGradient(parent, c1, c2, rotation)
    return CreateInstance("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, c1 or Color3.fromRGB(40, 40, 60)),
            ColorSequenceKeypoint.new(1, c2 or Color3.fromRGB(25, 25, 40))
        },
        Rotation = rotation or 90,
        Parent = parent
    })
end

local function AddShadow(parent)
    local shadow = CreateInstance("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.new(0, -15, 0, -15),
        ZIndex = -1,
        Parent = parent
    })
    return shadow
end

local function TweenProperty(obj, props, duration, style, direction)
    local tween = TweenService:Create(obj,
        TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out),
        props
    )
    tween:Play()
    return tween
end

local NotificationQueue = {}

local function Notify(title, text, duration)
    if not Config.Notifications then return end
    -- будет создано после GUI
    table.insert(NotificationQueue, {title = title, text = text, duration = duration or 3})
end

-- ═══════════════════════════════════════════════════════════════
-- ЦВЕТОВАЯ ПАЛИТРА
-- ═══════════════════════════════════════════════════════════════
local Colors = {
    Background = Color3.fromRGB(18, 18, 28),
    BackgroundSecondary = Color3.fromRGB(24, 24, 38),
    Surface = Color3.fromRGB(30, 30, 48),
    SurfaceHover = Color3.fromRGB(38, 38, 58),
    Accent = Color3.fromRGB(120, 80, 255),
    AccentDark = Color3.fromRGB(90, 55, 200),
    AccentLight = Color3.fromRGB(150, 120, 255),
    AccentGlow = Color3.fromRGB(120, 80, 255),
    Red = Color3.fromRGB(255, 70, 80),
    Green = Color3.fromRGB(70, 255, 130),
    Yellow = Color3.fromRGB(255, 210, 60),
    Orange = Color3.fromRGB(255, 150, 50),
    Cyan = Color3.fromRGB(60, 200, 255),
    Text = Color3.fromRGB(230, 230, 240),
    TextDim = Color3.fromRGB(140, 140, 170),
    TextDark = Color3.fromRGB(90, 90, 120),
    Border = Color3.fromRGB(50, 50, 75),
    Transparent = Color3.fromRGB(0, 0, 0),
}

-- ═══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ GUI
-- ═══════════════════════════════════════════════════════════════
-- Удаляем старый
if Player.PlayerGui:FindFirstChild("EspadaWare") then
    Player.PlayerGui:FindFirstChild("EspadaWare"):Destroy()
end

local ScreenGui = CreateInstance("ScreenGui", {
    Name = "EspadaWare",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
    Parent = Player.PlayerGui
})

-- ═══════════════════════════════════════════════════════════════
-- КНОПКА ОТКРЫТИЯ (МОБИЛЬНАЯ)
-- ═══════════════════════════════════════════════════════════════
local ToggleButton = CreateInstance("ImageButton", {
    Name = "ToggleButton",
    Size = UDim2.new(0, 52, 0, 52),
    Position = UDim2.new(0, 16, 0.5, -26),
    BackgroundColor3 = Colors.Accent,
    AutoButtonColor = false,
    Parent = ScreenGui
})
AddCorner(ToggleButton, 26)
AddStroke(ToggleButton, Colors.AccentLight, 2, 0.3)
AddShadow(ToggleButton)

local ToggleIcon = CreateInstance("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "⚔",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 26,
    Font = Enum.Font.GothamBold,
    Parent = ToggleButton
})

AddGradient(ToggleButton, Colors.Accent, Colors.AccentDark, 135)

-- Пульсирующая анимация
local togglePulse = true
task.spawn(function()
    while togglePulse do
        TweenProperty(ToggleButton, {Size = UDim2.new(0, 56, 0, 56), Position = UDim2.new(0, 14, 0.5, -28)}, 1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1)
        TweenProperty(ToggleButton, {Size = UDim2.new(0, 52, 0, 52), Position = UDim2.new(0, 16, 0.5, -26)}, 1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1)
    end
end)

-- Перетаскивание кнопки
local draggingToggle = false
local dragStartToggle, startPosToggle

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingToggle = true
        dragStartToggle = input.Position
        startPosToggle = ToggleButton.Position
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if draggingToggle and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStartToggle
        if delta.Magnitude > 10 then
            ToggleButton.Position = UDim2.new(
                startPosToggle.X.Scale, startPosToggle.X.Offset + delta.X,
                startPosToggle.Y.Scale, startPosToggle.Y.Offset + delta.Y
            )
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingToggle = false
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ГЛАВНОЕ ОКНО
-- ═══════════════════════════════════════════════════════════════
local MainFrame = CreateInstance("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, 420, 0, 520),
    Position = UDim2.new(0.5, -210, 0.5, -260),
    BackgroundColor3 = Colors.Background,
    BackgroundTransparency = 0.02,
    Visible = false,
    ClipsDescendants = true,
    Parent = ScreenGui
})
AddCorner(MainFrame, 14)
AddStroke(MainFrame, Colors.Border, 1.5, 0.4)
AddShadow(MainFrame)

-- Внутренний градиент
AddGradient(MainFrame, Color3.fromRGB(22, 22, 35), Color3.fromRGB(14, 14, 22), 160)

-- Декоративная линия акцента сверху
local AccentLine = CreateInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 3),
    Position = UDim2.new(0, 0, 0, 0),
    BorderSizePixel = 0,
    Parent = MainFrame
})
AddGradient(AccentLine, Colors.Accent, Colors.Cyan, 0)
AddCorner(AccentLine, 2)

-- ═══════════════════════════════════════════════════════════════
-- ЗАГОЛОВОК
-- ═══════════════════════════════════════════════════════════════
local Header = CreateInstance("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 52),
    Position = UDim2.new(0, 0, 0, 3),
    BackgroundTransparency = 1,
    Parent = MainFrame
})

local TitleLabel = CreateInstance("TextLabel", {
    Name = "Title",
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1,
    Text = "⚔ EspadaWare",
    TextColor3 = Colors.Text,
    TextSize = 20,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Header
})

local VersionLabel = CreateInstance("TextLabel", {
    Size = UDim2.new(0, 50, 0, 18),
    Position = UDim2.new(0, 175, 0.5, -9),
    BackgroundColor3 = Colors.Accent,
    BackgroundTransparency = 0.7,
    Text = "v2.0",
    TextColor3 = Colors.AccentLight,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    Parent = Header
})
AddCorner(VersionLabel, 4)

-- Информация
local InfoLabel = CreateInstance("TextLabel", {
    Size = UDim2.new(0, 200, 0, 14),
    Position = UDim2.new(1, -160, 0.5, -7),
    BackgroundTransparency = 1,
    Text = "Vagrant Survival",
    TextColor3 = Colors.TextDim,
    TextSize = 12,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right,
    Parent = Header
})

-- Разделитель
local HeaderDivider = CreateInstance("Frame", {
    Size = UDim2.new(1, -24, 0, 1),
    Position = UDim2.new(0, 12, 1, -1),
    BackgroundColor3 = Colors.Border,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    Parent = Header
})

-- ═══════════════════════════════════════════════════════════════
-- ПАНЕЛЬ ВКЛАДОК
-- ═══════════════════════════════════════════════════════════════
local TabBar = CreateInstance("Frame", {
    Name = "TabBar",
    Size = UDim2.new(1, -24, 0, 38),
    Position = UDim2.new(0, 12, 0, 58),
    BackgroundColor3 = Colors.BackgroundSecondary,
    BackgroundTransparency = 0.3,
    Parent = MainFrame
})
AddCorner(TabBar, 8)
AddStroke(TabBar, Colors.Border, 1, 0.6)

local TabBarLayout = CreateInstance("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 4),
    Parent = TabBar
})
AddPadding(TabBar, 4, 4, 4, 4)

local TabsData = {
    {Name = "Main", Icon = "🎯", Order = 1},
    {Name = "Movement", Icon = "🏃", Order = 2},
    {Name = "Visuals", Icon = "👁", Order = 3},
    {Name = "Settings", Icon = "⚙", Order = 4},
}

local TabButtons = {}
local TabPages = {}
local CurrentTab = "Main"

-- Контейнер страниц
local PageContainer = CreateInstance("Frame", {
    Name = "PageContainer",
    Size = UDim2.new(1, -24, 1, -108),
    Position = UDim2.new(0, 12, 0, 100),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Parent = MainFrame
})

-- Создаем вкладки
for _, tabInfo in ipairs(TabsData) do
    local tabBtn = CreateInstance("TextButton", {
        Name = tabInfo.Name .. "Tab",
        Size = UDim2.new(0.24, -4, 1, 0),
        BackgroundColor3 = Colors.Surface,
        BackgroundTransparency = tabInfo.Name == "Main" and 0.2 or 0.8,
        Text = tabInfo.Icon .. " " .. tabInfo.Name,
        TextColor3 = tabInfo.Name == "Main" and Colors.Text or Colors.TextDim,
        TextSize = 13,
        Font = Enum.Font.GothamSemibold,
        AutoButtonColor = false,
        LayoutOrder = tabInfo.Order,
        Parent = TabBar
    })
    AddCorner(tabBtn, 6)

    if tabInfo.Name == "Main" then
        AddStroke(tabBtn, Colors.Accent, 1, 0.5)
    end

    TabButtons[tabInfo.Name] = tabBtn

    -- Создаем страницу
    local page = CreateInstance("ScrollingFrame", {
        Name = tabInfo.Name .. "Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Colors.Accent,
        ScrollBarImageTransparency = 0.4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = tabInfo.Name == "Main",
        BorderSizePixel = 0,
        Parent = PageContainer
    })

    local pageLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = page
    })
    AddPadding(page, 4, 4, 2, 2)

    TabPages[tabInfo.Name] = page
end

-- Переключение вкладок
local function SwitchTab(tabName)
    if CurrentTab == tabName then return end
    CurrentTab = tabName
    for name, btn in pairs(TabButtons) do
        local isActive = name == tabName
        TweenProperty(btn, {
            BackgroundTransparency = isActive and 0.2 or 0.8,
            TextColor3 = isActive and Colors.Text or Colors.TextDim,
        }, 0.2)
        -- Убираем/добавляем Stroke
        for _, c in pairs(btn:GetChildren()) do
            if c:IsA("UIStroke") then c:Destroy() end
        end
        if isActive then
            AddStroke(btn, Colors.Accent, 1, 0.5)
        end
    end
    for name, page in pairs(TabPages) do
        if name == tabName then
            page.Visible = true
            page.GroupTransparency = 1
            -- Fade in
            for i = 1, 10 do
                page.GroupTransparency = 1 - (i / 10)
                task.wait(0.015)
            end
            page.GroupTransparency = 0
        else
            page.Visible = false
        end
    end
end

for name, btn in pairs(TabButtons) do
    btn.MouseButton1Click:Connect(function()
        SwitchTab(name)
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ОТКРЫТИЕ/ЗАКРЫТИЕ GUI
-- ═══════════════════════════════════════════════════════════════
local guiOpen = false

local function ToggleGUI()
    guiOpen = not guiOpen
    if guiOpen then
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        MainFrame.BackgroundTransparency = 1
        TweenProperty(MainFrame, {
            Size = UDim2.new(0, 420, 0, 520),
            Position = UDim2.new(0.5, -210, 0.5, -260),
            BackgroundTransparency = 0.02
        }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        TweenProperty(ToggleButton, {BackgroundTransparency = 0.5}, 0.3)
    else
        TweenProperty(MainFrame, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1
        }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In).Completed:Connect(function()
            MainFrame.Visible = false
        end)
        TweenProperty(ToggleButton, {BackgroundTransparency = 0}, 0.3)
    end
end

ToggleButton.MouseButton1Click:Connect(function()
    if not draggingToggle or (dragStartToggle and (ToggleButton.Position - UDim2.new(startPosToggle.X.Scale, startPosToggle.X.Offset, startPosToggle.Y.Scale, startPosToggle.Y.Offset)).X.Offset < 10) then
        ToggleGUI()
    end
end)

-- Клавиша
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode[Config.GuiKeybind] then
        ToggleGUI()
    end
end)

-- Перетаскивание главного окна
local draggingMain = false
local dragStartMain, startPosMain

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingMain = true
        dragStartMain = input.Position
        startPosMain = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingMain and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStartMain
        MainFrame.Position = UDim2.new(
            startPosMain.X.Scale, startPosMain.X.Offset + delta.X,
            startPosMain.Y.Scale, startPosMain.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingMain = false
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- СИСТЕМА УВЕДОМЛЕНИЙ
-- ═══════════════════════════════════════════════════════════════
local NotifContainer = CreateInstance("Frame", {
    Name = "Notifications",
    Size = UDim2.new(0, 280, 1, 0),
    Position = UDim2.new(1, -290, 0, 10),
    BackgroundTransparency = 1,
    Parent = ScreenGui
})

local NotifLayout = CreateInstance("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Parent = NotifContainer
})

local function ShowNotification(title, text, duration)
    if not Config.Notifications then return end
    duration = duration or 3

    local notif = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = Colors.Surface,
        BackgroundTransparency = 0.1,
        Parent = NotifContainer
    })
    AddCorner(notif, 8)
    AddStroke(notif, Colors.Accent, 1, 0.5)

    local accentBar = CreateInstance("Frame", {
        Size = UDim2.new(0, 3, 0.7, 0),
        Position = UDim2.new(0, 8, 0.15, 0),
        BackgroundColor3 = Colors.Accent,
        BorderSizePixel = 0,
        Parent = notif
    })
    AddCorner(accentBar, 2)

    CreateInstance("TextLabel", {
        Size = UDim2.new(1, -24, 0, 22),
        Position = UDim2.new(0, 18, 0, 8),
        BackgroundTransparency = 1,
        Text = "⚔ " .. title,
        TextColor3 = Colors.AccentLight,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif
    })

    CreateInstance("TextLabel", {
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.new(0, 18, 0, 30),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Colors.TextDim,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = notif
    })

    -- Анимация появления
    notif.Position = UDim2.new(1, 50, 0, 0)
    TweenProperty(notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Quart)

    task.delay(duration, function()
        TweenProperty(notif, {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1}, 0.4).Completed:Connect(function()
            notif:Destroy()
        end)
    end)
end

-- Обработка очереди
task.spawn(function()
    task.wait(1)
    for _, n in ipairs(NotificationQueue) do
        ShowNotification(n.title, n.text, n.duration)
        task.wait(0.3)
    end
    NotificationQueue = {}
end)

Notify = ShowNotification

-- ═══════════════════════════════════════════════════════════════
-- ПАНЕЛЬ НАСТРОЕК ФУНКЦИЙ (БОКОВАЯ)
-- ═══════════════════════════════════════════════════════════════
local SettingsPanel = CreateInstance("Frame", {
    Name = "SettingsPanel",
    Size = UDim2.new(0, 300, 0, 480),
    Position = UDim2.new(0.5, 230, 0.5, -240),
    BackgroundColor3 = Colors.Background,
    BackgroundTransparency = 0.05,
    Visible = false,
    ClipsDescendants = true,
    Parent = ScreenGui
})
AddCorner(SettingsPanel, 12)
AddStroke(SettingsPanel, Colors.Border, 1.5, 0.4)
AddShadow(SettingsPanel)
AddGradient(SettingsPanel, Color3.fromRGB(22, 22, 35), Color3.fromRGB(14, 14, 22), 160)

-- Линия акцента
local SPAccent = CreateInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 3),
    Position = UDim2.new(0, 0, 0, 0),
    BorderSizePixel = 0,
    Parent = SettingsPanel
})
AddGradient(SPAccent, Colors.Orange, Colors.Accent, 0)
AddCorner(SPAccent, 2)

local SPHeader = CreateInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    Position = UDim2.new(0, 0, 0, 3),
    BackgroundTransparency = 1,
    Parent = SettingsPanel
})

local SPTitle = CreateInstance("TextLabel", {
    Size = UDim2.new(1, -50, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
    Text = "⚙ Settings",
    TextColor3 = Colors.Text,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = SPHeader
})

local SPClose = CreateInstance("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -38, 0.5, -15),
    BackgroundColor3 = Colors.Red,
    BackgroundTransparency = 0.7,
    Text = "✕",
    TextColor3 = Colors.Text,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Parent = SPHeader
})
AddCorner(SPClose, 6)

local SPDivider = CreateInstance("Frame", {
    Size = UDim2.new(1, -20, 0, 1),
    Position = UDim2.new(0, 10, 1, -1),
    BackgroundColor3 = Colors.Border,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    Parent = SPHeader
})

local SPContent = CreateInstance("ScrollingFrame", {
    Name = "SPContent",
    Size = UDim2.new(1, -16, 1, -55),
    Position = UDim2.new(0, 8, 0, 48),
    BackgroundTransparency = 1,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Colors.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    BorderSizePixel = 0,
    Parent = SettingsPanel
})

local SPLayout = CreateInstance("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
    Parent = SPContent
})
AddPadding(SPContent, 4, 4, 4, 4)

local currentOpenSettings = nil

local function CloseSettingsPanel()
    if SettingsPanel.Visible then
        TweenProperty(SettingsPanel, {Position = UDim2.new(0.5, 250, 0.5, -240), BackgroundTransparency = 1}, 0.3).Completed:Connect(function()
            SettingsPanel.Visible = false
            for _, c in pairs(SPContent:GetChildren()) do
                if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
                    c:Destroy()
                end
            end
        end)
    end
    currentOpenSettings = nil
end

local function OpenSettingsPanel(featureName)
    if currentOpenSettings == featureName and SettingsPanel.Visible then
        CloseSettingsPanel()
        return
    end
    -- Очистить
    for _, c in pairs(SPContent:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
            c:Destroy()
        end
    end
    currentOpenSettings = featureName
    SPTitle.Text = "⚙ " .. featureName .. " Settings"
    SettingsPanel.Visible = true
    SettingsPanel.BackgroundTransparency = 1
    SettingsPanel.Position = UDim2.new(0.5, 250, 0.5, -240)
    TweenProperty(SettingsPanel, {Position = UDim2.new(0.5, 230, 0.5, -240), BackgroundTransparency = 0.05}, 0.3, Enum.EasingStyle.Quart)
    return SPContent
end

SPClose.MouseButton1Click:Connect(CloseSettingsPanel)

-- ═══════════════════════════════════════════════════════════════
-- UI КОМПОНЕНТЫ (Toggle, Slider, Dropdown, и т.д.)
-- ═══════════════════════════════════════════════════════════════
local function CreateSettingsToggle(parent, text, default, callback, layoutOrder)
    local frame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Colors.Surface,
        BackgroundTransparency = 0.4,
        LayoutOrder = layoutOrder or 0,
        Parent = parent
    })
    AddCorner(frame, 6)

    local label = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Colors.TextDim,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })

    local toggleBg = CreateInstance("Frame", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = default and Colors.Accent or Color3.fromRGB(50, 50, 70),
        Parent = frame
    })
    AddCorner(toggleBg, 10)

    local toggleCircle = CreateInstance("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Parent = toggleBg
    })
    AddCorner(toggleCircle, 8)

    local state = default
    local btn = CreateInstance("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame
    })

    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenProperty(toggleBg, {BackgroundColor3 = state and Colors.Accent or Color3.fromRGB(50, 50, 70)}, 0.2)
        TweenProperty(toggleCircle, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.2)
        if callback then callback(state) end
    end)

    return {
        Frame = frame,
        SetState = function(s)
            state = s
            TweenProperty(toggleBg, {BackgroundColor3 = state and Colors.Accent or Color3.fromRGB(50, 50, 70)}, 0.2)
            TweenProperty(toggleCircle, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.2)
        end,
        GetState = function() return state end
    }
end

local function CreateSettingsSlider(parent, text, min, max, default, callback, layoutOrder)
    local frame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Colors.Surface,
        BackgroundTransparency = 0.4,
        LayoutOrder = layoutOrder or 0,
        Parent = parent
    })
    AddCorner(frame, 6)

    local label = CreateInstance("TextLabel", {
        Size = UDim2.new(0.6, 0, 0, 20),
        Position = UDim2.new(0, 12, 0, 4),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Colors.TextDim,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })

    local valueLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(0.35, 0, 0, 20),
        Position = UDim2.new(0.65, -12, 0, 4),
        BackgroundTransparency = 1,
        Text = tostring(default),
        TextColor3 = Colors.AccentLight,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = frame
    })

    local sliderBg = CreateInstance("Frame", {
        Size = UDim2.new(1, -24, 0, 6),
        Position = UDim2.new(0, 12, 0, 34),
        BackgroundColor3 = Color3.fromRGB(40, 40, 60),
        Parent = frame
    })
    AddCorner(sliderBg, 3)

    local pct = math.clamp((default - min) / (max - min), 0, 1)
    local sliderFill = CreateInstance("Frame", {
        Size = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = Colors.Accent,
        BorderSizePixel = 0,
        Parent = sliderBg
    })
    AddCorner(sliderFill, 3)
    AddGradient(sliderFill, Colors.Accent, Colors.AccentLight, 0)

    local sliderKnob = CreateInstance("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(pct, -7, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 2,
        Parent = sliderBg
    })
    AddCorner(sliderKnob, 7)
    AddStroke(sliderKnob, Colors.Accent, 2, 0.3)

    local value = default
    local dragging = false

    local function Update(inputPos)
        local rel = math.clamp((inputPos.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * rel + 0.5)
        local p = (value - min) / (max - min)
        sliderFill.Size = UDim2.new(p, 0, 1, 0)
        sliderKnob.Position = UDim2.new(p, -7, 0.5, -7)
        valueLabel.Text = tostring(value)
        if callback then callback(value) end
    end

    local sliderBtn = CreateInstance("TextButton", {
        Size = UDim2.new(1, 0, 1, 12),
        Position = UDim2.new(0, 0, 0, -6),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 3,
        Parent = sliderBg
    })

    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            Update(input.Position)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            Update(input.Position)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return {
        Frame = frame,
        SetValue = function(v)
            value = v
            local p = (v - min) / (max - min)
            sliderFill.Size = UDim2.new(p, 0, 1, 0)
            sliderKnob.Position = UDim2.new(p, -7, 0.5, -7)
            valueLabel.Text = tostring(v)
        end,
        GetValue = function() return value end
    }
end

local function CreateSettingsDropdown(parent, text, options, default, callback, layoutOrder)
    local expanded = false
    local frame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Colors.Surface,
        BackgroundTransparency = 0.4,
        ClipsDescendants = true,
        LayoutOrder = layoutOrder or 0,
        Parent = parent
    })
    AddCorner(frame, 6)

    local label = CreateInstance("TextLabel", {
        Size = UDim2.new(0.45, 0, 0, 36),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Colors.TextDim,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })

    local selectedBtn = CreateInstance("TextButton", {
        Size = UDim2.new(0.5, -12, 0, 26),
        Position = UDim2.new(0.5, 0, 0, 5),
        BackgroundColor3 = Color3.fromRGB(40, 40, 60),
        Text = default .. " ▾",
        TextColor3 = Colors.AccentLight,
        TextSize = 12,
        Font = Enum.Font.GothamSemibold,
        AutoButtonColor = false,
        Parent = frame
    })
    AddCorner(selectedBtn, 5)
    AddStroke(selectedBtn, Colors.Border, 1, 0.5)

    local selected = default

    local optionButtons = {}
    for i, opt in ipairs(options) do
        local optBtn = CreateInstance("TextButton", {
            Size = UDim2.new(0.5, -12, 0, 26),
            Position = UDim2.new(0.5, 0, 0, 5 + i * 30),
            BackgroundColor3 = Color3.fromRGB(35, 35, 55),
            Text = opt,
            TextColor3 = Colors.Text,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            AutoButtonColor = false,
            Visible = false,
            Parent = frame
        })
        AddCorner(optBtn, 5)
        table.insert(optionButtons, optBtn)

        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            selectedBtn.Text = opt .. " ▾"
            expanded = false
            TweenProperty(frame, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
            for _, ob in pairs(optionButtons) do ob.Visible = false end
            if callback then callback(opt) end
        end)

        optBtn.MouseEnter:Connect(function()
            TweenProperty(optBtn, {BackgroundColor3 = Colors.SurfaceHover}, 0.15)
        end)
        optBtn.MouseLeave:Connect(function()
            TweenProperty(optBtn, {BackgroundColor3 = Color3.fromRGB(35, 35, 55)}, 0.15)
        end)
    end

    selectedBtn.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            TweenProperty(frame, {Size = UDim2.new(1, 0, 0, 36 + #options * 30)}, 0.2)
            for _, ob in pairs(optionButtons) do ob.Visible = true end
        else
            TweenProperty(frame, {Size = UDim2.new(1, 0, 0, 36)}, 0.2)
            for _, ob in pairs(optionButtons) do ob.Visible = false end
        end
    end)

    return {
        Frame = frame,
        GetSelected = function() return selected end,
        SetSelected = function(s)
            selected = s
            selectedBtn.Text = s .. " ▾"
        end
    }
end

local function CreateSectionLabel(parent, text, layoutOrder)
    local label = CreateInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Colors.TextDark,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = layoutOrder or 0,
        Parent = parent
    })
    return label
end

-- ═══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ FEATURE КАРТОЧКИ
-- ═══════════════════════════════════════════════════════════════
local function CreateFeatureCard(parent, name, description, icon, configKey, hasSettings, settingsBuilder, layoutOrder)
    local enabled = Config[configKey] and Config[configKey].Enabled or false

    local card = CreateInstance("Frame", {
        Name = name .. "Card",
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = Colors.Surface,
        BackgroundTransparency = 0.3,
        LayoutOrder = layoutOrder or 0,
        Parent = parent
    })
    AddCorner(card, 8)
    AddStroke(card, enabled and Colors.Accent or Colors.Border, 1, enabled and 0.4 or 0.7)

    -- Иконка
    local iconLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(0, 10, 0.5, -16),
        BackgroundColor3 = Colors.Accent,
        BackgroundTransparency = 0.7,
        Text = icon,
        TextColor3 = Colors.AccentLight,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        Parent = card
    })
    AddCorner(iconLabel, 8)

    -- Название
    CreateInstance("TextLabel", {
        Size = UDim2.new(0.55, 0, 0, 18),
        Position = UDim2.new(0, 50, 0, 8),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Colors.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    -- Описание
    CreateInstance("TextLabel", {
        Size = UDim2.new(0.6, 0, 0, 14),
        Position = UDim2.new(0, 50, 0, 28),
        BackgroundTransparency = 1,
        Text = description,
        TextColor3 = Colors.TextDark,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = card
    })

    -- Toggle
    local toggleBg = CreateInstance("Frame", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -96, 0.5, -10),
        BackgroundColor3 = enabled and Colors.Accent or Color3.fromRGB(50, 50, 70),
        Parent = card
    })
    AddCorner(toggleBg, 10)

    local toggleCircle = CreateInstance("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Parent = toggleBg
    })
    AddCorner(toggleCircle, 8)

    -- Кнопка включения
    local toggleBtn = CreateInstance("TextButton", {
        Size = UDim2.new(0, 50, 0, 30),
        Position = UDim2.new(1, -101, 0.5, -15),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 2,
        Parent = card
    })

    -- Шестеренка настроек
    local gearBtn
    if hasSettings then
        gearBtn = CreateInstance("TextButton", {
            Size = UDim2.new(0, 36, 0, 36),
            Position = UDim2.new(1, -46, 0.5, -18),
            BackgroundColor3 = Colors.Surface,
            BackgroundTransparency = 0.3,
            Text = "⚙",
            TextColor3 = Colors.TextDim,
            TextSize = 18,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
            Parent = card
        })
        AddCorner(gearBtn, 8)
        AddStroke(gearBtn, Colors.Border, 1, 0.6)

        gearBtn.MouseEnter:Connect(function()
            TweenProperty(gearBtn, {BackgroundTransparency = 0, TextColor3 = Colors.AccentLight}, 0.15)
        end)
        gearBtn.MouseLeave:Connect(function()
            TweenProperty(gearBtn, {BackgroundTransparency = 0.3, TextColor3 = Colors.TextDim}, 0.15)
        end)

        gearBtn.MouseButton1Click:Connect(function()
            local content = OpenSettingsPanel(name)
            if content and settingsBuilder then
                settingsBuilder(content)
            end
        end)
    else
        -- Сдвигаем toggle вправо если нет шестеренки
        toggleBg.Position = UDim2.new(1, -52, 0.5, -10)
        toggleBtn.Position = UDim2.new(1, -57, 0.5, -15)
    end

    -- Hover effect
    card.MouseEnter:Connect(function()
        TweenProperty(card, {BackgroundTransparency = 0.15}, 0.15)
    end)
    card.MouseLeave:Connect(function()
        TweenProperty(card, {BackgroundTransparency = 0.3}, 0.15)
    end)

    local function SetEnabled(state)
        enabled = state
        if Config[configKey] then Config[configKey].Enabled = state end
        TweenProperty(toggleBg, {BackgroundColor3 = state and Colors.Accent or Color3.fromRGB(50, 50, 70)}, 0.2)
        TweenProperty(toggleCircle, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.2)
        -- Обновить stroke
        for _, c in pairs(card:GetChildren()) do
            if c:IsA("UIStroke") then
                TweenProperty(c, {Color = state and Colors.Accent or Colors.Border, Transparency = state and 0.4 or 0.7}, 0.2)
            end
        end
        if Config.AutoSave then SaveConfig() end
    end

    toggleBtn.MouseButton1Click:Connect(function()
        SetEnabled(not enabled)
        ShowNotification(name, enabled and "Enabled" or "Disabled", 2)
    end)

    return {
        Card = card,
        SetEnabled = SetEnabled,
        IsEnabled = function() return enabled end
    }
end

-- ═══════════════════════════════════════════════════════════════
-- TAB: MAIN - ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════════
local mainPage = TabPages["Main"]

CreateSectionLabel(mainPage, "  ⚔  COMBAT", 1)

-- 1. Aimbot
local AimbotCard = CreateFeatureCard(mainPage, "Aimbot", "Lock aim to nearest enemy", "🎯", "Aimbot", true, function(content)
    CreateSettingsSlider(content, "FOV Radius", 30, 360, Config.Aimbot.FOV, function(v) Config.Aimbot.FOV = v; if Config.AutoSave then SaveConfig() end end, 1)
    CreateSettingsSlider(content, "Smoothness", 1, 20, Config.Aimbot.Smoothness, function(v) Config.Aimbot.Smoothness = v; if Config.AutoSave then SaveConfig() end end, 2)
    CreateSettingsDropdown(content, "Target Part", {"Head", "HumanoidRootPart", "Torso"}, Config.Aimbot.TargetPart, function(v) Config.Aimbot.TargetPart = v; if Config.AutoSave then SaveConfig() end end, 3)
    CreateSettingsToggle(content, "Show FOV Circle", Config.Aimbot.ShowFOV, function(v) Config.Aimbot.ShowFOV = v; if Config.AutoSave then SaveConfig() end end, 4)
    CreateSettingsToggle(content, "Team Check", Config.Aimbot.TeamCheck, function(v) Config.Aimbot.TeamCheck = v; if Config.AutoSave then SaveConfig() end end, 5)
    CreateSettingsDropdown(content, "Aim Key", {"MouseButton2", "MouseButton1", "Q", "E"}, Config.Aimbot.AimKey, function(v) Config.Aimbot.AimKey = v; if Config.AutoSave then SaveConfig() end end, 6)
end, 2)

-- 2. Auto Attack
local AutoAttackCard = CreateFeatureCard(mainPage, "Auto Attack", "Automatically attack enemies", "⚔", "AutoAttack", true, function(content)
    CreateSettingsSlider(content, "Attack Delay", 5, 100, math.floor(Config.AutoAttack.Delay * 100), function(v) Config.AutoAttack.Delay = v / 100; if Config.AutoSave then SaveConfig() end end, 1)
    CreateSettingsDropdown(content, "Mode", {"Hold", "Toggle", "Always"}, Config.AutoAttack.Mode, function(v) Config.AutoAttack.Mode = v; if Config.AutoSave then SaveConfig() end end, 2)
end, 3)

-- 3. Kill Aura
local KillAuraCard = CreateFeatureCard(mainPage, "Kill Aura", "Auto-hit nearby players", "💀", "KillAura", true, function(content)
    CreateSettingsSlider(content, "Range", 5, 30, Config.KillAura.Range, function(v) Config.KillAura.Range = v; if Config.AutoSave then SaveConfig() end end, 1)
    CreateSettingsSlider(content, "Delay (ms)", 50, 500, math.floor(Config.KillAura.Delay * 1000), function(v) Config.KillAura.Delay = v / 1000; if Config.AutoSave then SaveConfig() end end, 2)
end, 4)

-- 4. Auto Pickup
CreateSectionLabel(mainPage, "  📦  UTILITY", 5)

local AutoPickupCard = CreateFeatureCard(mainPage, "Auto Pickup", "Automatically collect items", "📦", "AutoPickup", true, function(content)
    CreateSettingsSlider(content, "Pickup Range", 5, 60, Config.AutoPickup.Range, function(v) Config.AutoPickup.Range = v; if Config.AutoSave then SaveConfig() end end, 1)
    CreateSettingsToggle(content, "Pickup Items", Config.AutoPickup.Items, function(v) Config.AutoPickup.Items = v; if Config.AutoSave then SaveConfig() end end, 2)
    CreateSettingsToggle(content, "Pickup Resources", Config.AutoPickup.Resources, function(v) Config.AutoPickup.Resources = v; if Config.AutoSave then SaveConfig() end end, 3)
    CreateSettingsToggle(content, "Pickup Weapons", Config.AutoPickup.Weapons, function(v) Config.AutoPickup.Weapons = v; if Config.AutoSave then SaveConfig() end end, 4)
end, 6)

-- ═══════════════════════════════════════════════════════════════
-- TAB: MOVEMENT - ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════════
local movePage = TabPages["Movement"]

CreateSectionLabel(movePage, "  🏃  LOCOMOTION", 1)

-- 1. Speed
local SpeedCard = CreateFeatureCard(movePage, "Speed", "Modify movement speed", "🏃", "Speed", true, function(content)
    CreateSettingsSlider(content, "Speed Value", 16, 150, Config.Speed.Value, function(v) Config.Speed.Value = v; if Config.AutoSave then SaveConfig() end end, 1)
    CreateSettingsDropdown(content, "Mode", {"WalkSpeed", "CFrame", "Velocity"}, Config.Speed.Mode, function(v) Config.Speed.Mode = v; if Config.AutoSave then SaveConfig() end end, 2)
end, 2)

-- 2. Infinite Jump
local InfJumpCard = CreateFeatureCard(movePage, "Infinite Jump", "Jump unlimited times", "🦘", "InfiniteJump", true, function(content)
    CreateSettingsSlider(content, "Jump Power", 20, 150, Config.InfiniteJump.Power, function(v) Config.InfiniteJump.Power = v; if Config.AutoSave then SaveConfig() end end, 1)
end, 3)

-- 3. Noclip
local NoclipCard = CreateFeatureCard(movePage, "Noclip", "Walk through walls", "👻", "Noclip", false, nil, 4)

-- 4. Fly
local FlyCard = CreateFeatureCard(movePage, "Fly", "Fly freely in the air", "🕊", "Fly", true, function(content)
    CreateSettingsSlider(content, "Fly Speed", 10, 200, Config.Fly.FlySpeed, function(v) Config.Fly.FlySpeed = v; if Config.AutoSave then SaveConfig() end end, 1)
end, 5)

-- 5. Auto Sprint
CreateSectionLabel(movePage, "  ⚡  AUTOMATION", 6)
local AutoSprintCard = CreateFeatureCard(movePage, "Auto Sprint", "Always sprint when moving", "⚡", "AutoSprint", false, nil, 7)

-- ═══════════════════════════════════════════════════════════════
-- TAB: VISUALS - ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════════
local visPage = TabPages["Visuals"]

CreateSectionLabel(visPage, "  👁  PLAYER ESP", 1)

-- 1. ESP
local ESPCard = CreateFeatureCard(visPage, "Player ESP", "See players through walls", "👁", "ESP", true, function(content)
    CreateSettingsToggle(content, "Show Names", Config.ESP.ShowNames, function(v) Config.ESP.ShowNames = v; if Config.AutoSave then SaveConfig() end end, 1)
    CreateSettingsToggle(content, "Show Health", Config.ESP.ShowHealth, function(v) Config.ESP.ShowHealth = v; if Config.AutoSave then SaveConfig() end end, 2)
    CreateSettingsToggle(content, "Show Distance", Config.ESP.ShowDistance, function(v) Config.ESP.ShowDistance = v; if Config.AutoSave then SaveConfig() end end, 3)
    CreateSettingsToggle(content, "Show Box", Config.ESP.ShowBox, function(v) Config.ESP.ShowBox = v; if Config.AutoSave then SaveConfig() end end, 4)
    CreateSettingsSlider(content, "Max Distance", 50, 2000, Config.ESP.MaxDistance, function(v) Config.ESP.MaxDistance = v; if Config.AutoSave then SaveConfig() end end, 5)
    CreateSettingsToggle(content, "Team Check", Config.ESP.TeamCheck, function(v) Config.ESP.TeamCheck = v; if Config.AutoSave then SaveConfig() end end, 6)
end, 2)

-- 2. Chams
local ChamsCard = CreateFeatureCard(visPage, "Player Chams", "Highlight players with color", "🎨", "ChamPlayers", true, function(content)
    CreateSectionLabel(content, "Fill & Outline colors are preset", 1)
end, 3)

-- 3. Item ESP
local ItemESPCard = CreateFeatureCard(visPage, "Item ESP", "See items through walls", "📍", "ItemESP", true, function(content)
    CreateSettingsSlider(content, "Max Distance", 50, 1000, Config.ItemESP.MaxDistance, function(v) Config.ItemESP.MaxDistance = v; if Config.AutoSave then SaveConfig() end end, 1)
end, 4)

CreateSectionLabel(visPage, "  🌍  WORLD", 5)

-- 4. Fullbright
local FullbrightCard = CreateFeatureCard(visPage, "Fullbright", "Remove darkness and shadows", "☀", "Fullbright", false, nil, 6)

-- 5. No Fog
local NoFogCard = CreateFeatureCard(visPage, "No Fog", "Remove fog effects", "🌫", "NoFog", false, nil, 7)

-- ═══════════════════════════════════════════════════════════════
-- TAB: SETTINGS
-- ═══════════════════════════════════════════════════════════════
local setPage = TabPages["Settings"]

CreateSectionLabel(setPage, "  ⚙  GENERAL", 1)

-- Auto Save Toggle
CreateSettingsToggle(setPage, "Auto Save Config", Config.AutoSave, function(v)
    Config.AutoSave = v
    if v then SaveConfig() end
end, 2)

-- Notifications Toggle
CreateSettingsToggle(setPage, "Notifications", Config.Notifications, function(v)
    Config.Notifications = v
    if Config.AutoSave then SaveConfig() end
end, 3)

CreateSectionLabel(setPage, "  💾  CONFIG MANAGEMENT", 4)

-- Кнопка Save Config
local saveBtn = CreateInstance("TextButton", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = Colors.Accent,
    BackgroundTransparency = 0.3,
    Text = "💾  Save Config",
    TextColor3 = Colors.Text,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    LayoutOrder = 5,
    Parent = setPage
})
AddCorner(saveBtn, 8)
AddStroke(saveBtn, Colors.AccentDark, 1, 0.5)
AddGradient(saveBtn, Colors.Accent, Colors.AccentDark, 135)

saveBtn.MouseButton1Click:Connect(function()
    SaveConfig()
    ShowNotification("Config", "Configuration saved successfully!", 2)
    TweenProperty(saveBtn, {BackgroundTransparency = 0}, 0.1)
    task.delay(0.15, function()
        TweenProperty(saveBtn, {BackgroundTransparency = 0.3}, 0.2)
    end)
end)

-- Кнопка Load Config
local loadBtn = CreateInstance("TextButton", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = Colors.Cyan,
    BackgroundTransparency = 0.3,
    Text = "📂  Load Config",
    TextColor3 = Colors.Text,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    LayoutOrder = 6,
    Parent = setPage
})
AddCorner(loadBtn, 8)
AddStroke(loadBtn, Color3.fromRGB(40, 150, 200), 1, 0.5)

loadBtn.MouseButton1Click:Connect(function()
    LoadConfig()
    ShowNotification("Config", "Configuration loaded!", 2)
end)

-- Кнопка Reset Config
local resetBtn = CreateInstance("TextButton", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = Colors.Red,
    BackgroundTransparency = 0.3,
    Text = "🗑  Reset Config",
    TextColor3 = Colors.Text,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    LayoutOrder = 7,
    Parent = setPage
})
AddCorner(resetBtn, 8)
AddStroke(resetBtn, Color3.fromRGB(200, 50, 60), 1, 0.5)

resetBtn.MouseButton1Click:Connect(function()
    ResetConfig()
    ShowNotification("Config", "Configuration reset to defaults!", 2)
end)

CreateSectionLabel(setPage, "  🎨  UI SETTINGS", 8)

CreateSettingsDropdown(setPage, "GUI Keybind", {"RightShift", "RightControl", "LeftAlt", "F4", "F6"}, Config.GuiKeybind, function(v)
    Config.GuiKeybind = v
    if Config.AutoSave then SaveConfig() end
end, 9)

CreateSectionLabel(setPage, "  ℹ  INFO", 10)

local infoFrame = CreateInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 80),
    BackgroundColor3 = Colors.Surface,
    BackgroundTransparency = 0.4,
    LayoutOrder = 11,
    Parent = setPage
})
AddCorner(infoFrame, 8)

CreateInstance("TextLabel", {
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "⚔ EspadaWare v2.0\nFor: Vagrant Survival\nMobile Optimized\n© 2024 EspadaWare",
    TextColor3 = Colors.TextDim,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    Parent = infoFrame
})

-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════
-- ФУНКЦИОНАЛ (РЕАЛЬНАЯ РАБОТА ФУНКЦИЙ)
-- ═══════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════

-- Утилиты для функционала
local function GetCharacter()
    return Player.Character or Player.CharacterAdded:Wait()
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function IsAlive()
    local hum = GetHumanoid()
    return hum and hum.Health > 0
end

local function GetPlayerDistance(plr)
    local myRoot = GetRootPart()
    if not myRoot then return math.huge end
    local char = plr.Character
    if not char then return math.huge end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return math.huge end
    return (myRoot.Position - root.Position).Magnitude
end

local function IsEnemy(plr)
    if plr == Player then return false end
    if not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if Config.Aimbot.TeamCheck or Config.ESP.TeamCheck then
        if plr.Team and Player.Team and plr.Team == Player.Team then
            return false
        end
    end
    return true
end

local function GetNearestPlayer(maxDist, screenCheck)
    local nearest = nil
    local nearestDist = maxDist or math.huge
    local myRoot = GetRootPart()
    if not myRoot then return nil end

    for _, plr in pairs(Players:GetPlayers()) do
        if IsEnemy(plr) then
            local char = plr.Character
            if char then
                local targetPart = char:FindFirstChild(Config.Aimbot.TargetPart) or char:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    local dist = (myRoot.Position - targetPart.Position).Magnitude
                    if screenCheck then
                        local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
                        if onScreen then
                            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                            local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                            if screenDist <= Config.Aimbot.FOV and dist < nearestDist then
                                nearestDist = dist
                                nearest = plr
                            end
                        end
                    else
                        if dist < nearestDist then
                            nearestDist = dist
                            nearest = plr
                        end
                    end
                end
            end
        end
    end
    return nearest
end

-- ═══════════════════════════════════════════════════════════════
-- AIMBOT
-- ═══════════════════════════════════════════════════════════════
local aimTarget = nil
local aiming = false

-- FOV Визуал
local fovCircle = nil
pcall(function()
    fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(120, 80, 255)
    fovCircle.Thickness = 1.5
    fovCircle.NumSides = 64
    fovCircle.Filled = false
    fovCircle.Transparency = 0.6
    fovCircle.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if Config.Aimbot.Enabled then
        local aimKeyCheck = false
        if Config.Aimbot.AimKey == "MouseButton2" and input.UserInputType == Enum.UserInputType.MouseButton2 then
            aimKeyCheck = true
        elseif Config.Aimbot.AimKey == "MouseButton1" and input.UserInputType == Enum.UserInputType.MouseButton1 then
            aimKeyCheck = true
        elseif input.KeyCode and input.KeyCode.Name == Config.Aimbot.AimKey then
            aimKeyCheck = true
        end
        if aimKeyCheck then
            aiming = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if Config.Aimbot.AimKey == "MouseButton2" and input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    elseif Config.Aimbot.AimKey == "MouseButton1" and input.UserInputType == Enum.UserInputType.MouseButton1 then
        aiming = false
    elseif input.KeyCode and input.KeyCode.Name == Config.Aimbot.AimKey then
        aiming = false
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ESP SYSTEM
-- ═══════════════════════════════════════════════════════════════
local ESPObjects = {}

local function CreateESPForPlayer(plr)
    if plr == Player then return end
    if ESPObjects[plr] then return end

    local esp = {}

    pcall(function()
        -- Name
        esp.Name = Drawing.new("Text")
        esp.Name.Color = Color3.fromRGB(255, 255, 255)
        esp.Name.Size = 14
        esp.Name.Center = true
        esp.Name.Outline = true
        esp.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
        esp.Name.Visible = false
        esp.Name.Font = 2

        -- Health
        esp.Health = Drawing.new("Text")
        esp.Health.Color = Color3.fromRGB(70, 255, 130)
        esp.Health.Size = 12
        esp.Health.Center = true
        esp.Health.Outline = true
        esp.Health.OutlineColor = Color3.fromRGB(0, 0, 0)
        esp.Health.Visible = false
        esp.Health.Font = 2

        -- Distance
        esp.Distance = Drawing.new("Text")
        esp.Distance.Color = Color3.fromRGB(200, 200, 200)
        esp.Distance.Size = 11
        esp.Distance.Center = true
        esp.Distance.Outline = true
        esp.Distance.OutlineColor = Color3.fromRGB(0, 0, 0)
        esp.Distance.Visible = false
        esp.Distance.Font = 2

        -- Box
        esp.BoxTL = Drawing.new("Line")
        esp.BoxTR = Drawing.new("Line")
        esp.BoxBL = Drawing.new("Line")
        esp.BoxBR = Drawing.new("Line")
        esp.BoxTop = Drawing.new("Line")
        esp.BoxBottom = Drawing.new("Line")
        esp.BoxLeft = Drawing.new("Line")
        esp.BoxRight = Drawing.new("Line")

        for _, key in pairs({"BoxTL", "BoxTR", "BoxBL", "BoxBR", "BoxTop", "BoxBottom", "BoxLeft", "BoxRight"}) do
            esp[key].Color = Color3.fromRGB(120, 80, 255)
            esp[key].Thickness = 1.5
            esp[key].Visible = false
        end
    end)

    ESPObjects[plr] = esp
end

local function RemoveESPForPlayer(plr)
    if ESPObjects[plr] then
        for _, obj in pairs(ESPObjects[plr]) do
            pcall(function() obj:Remove() end)
        end
        ESPObjects[plr] = nil
    end
end

local function ClearAllESP()
    for plr, _ in pairs(ESPObjects) do
        RemoveESPForPlayer(plr)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ITEM ESP
-- ═══════════════════════════════════════════════════════════════
local ItemESPObjects = {}

local function ClearItemESP()
    for _, obj in pairs(ItemESPObjects) do
        pcall(function()
            if obj.Billboard then obj.Billboard:Destroy() end
        end)
    end
    ItemESPObjects = {}
end

-- ═══════════════════════════════════════════════════════════════
-- CHAMS
-- ═══════════════════════════════════════════════════════════════
local ChamObjects = {}

local function ApplyChams(plr)
    if plr == Player then return end
    if ChamObjects[plr] then return end
    local char = plr.Character
    if not char then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "EspadaCham"
    highlight.FillColor = Color3.new(Config.ChamPlayers.FillColor[1], Config.ChamPlayers.FillColor[2], Config.ChamPlayers.FillColor[3])
    highlight.OutlineColor = Color3.new(Config.ChamPlayers.OutlineColor[1], Config.ChamPlayers.OutlineColor[2], Config.ChamPlayers.OutlineColor[3])
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = char
    highlight.Parent = char

    ChamObjects[plr] = highlight
end

local function RemoveChams(plr)
    if ChamObjects[plr] then
        pcall(function() ChamObjects[plr]:Destroy() end)
        ChamObjects[plr] = nil
    end
    if plr.Character then
        local h = plr.Character:FindFirstChild("EspadaCham")
        if h then h:Destroy() end
    end
end

local function ClearAllChams()
    for plr, _ in pairs(ChamObjects) do
        RemoveChams(plr)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FULLBRIGHT & NO FOG
-- ═══════════════════════════════════════════════════════════════
local originalLighting = {}
local function SaveLighting()
    originalLighting.Brightness = Lighting.Brightness
    originalLighting.ClockTime = Lighting.ClockTime
    originalLighting.FogEnd = Lighting.FogEnd
    originalLighting.FogStart = Lighting.FogStart
    originalLighting.GlobalShadows = Lighting.GlobalShadows
    originalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
    originalLighting.Ambient = Lighting.Ambient
end
SaveLighting()

-- ═══════════════════════════════════════════════════════════════
-- FLY SYSTEM
-- ═══════════════════════════════════════════════════════════════
local flyBV = nil
local flyBG = nil
local flyActive = false

local function StartFly()
    if flyActive then return end
    local root = GetRootPart()
    local hum = GetHumanoid()
    if not root or not hum then return end

    flyActive = true

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.new(0, 0, 0)
    flyBV.Parent = root

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBG.D = 200
    flyBG.P = 40000
    flyBG.Parent = root
end

local function StopFly()
    flyActive = false
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
end

-- ═══════════════════════════════════════════════════════════════
-- ГЛАВНЫЙ ЦИКЛ (RenderStep)
-- ═══════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function(dt)
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    -- ═══ AIMBOT ═══
    if Config.Aimbot.Enabled and aiming and IsAlive() then
        local target = GetNearestPlayer(math.huge, true)
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild(Config.Aimbot.TargetPart) or target.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local targetPos = targetPart.Position
                local camCF = Camera.CFrame
                local targetCF = CFrame.lookAt(camCF.Position, targetPos)
                Camera.CFrame = camCF:Lerp(targetCF, math.clamp(1 / Config.Aimbot.Smoothness, 0.05, 1))
            end
        end
    end

    -- FOV Circle
    if fovCircle then
        fovCircle.Visible = Config.Aimbot.Enabled and Config.Aimbot.ShowFOV
        if fovCircle.Visible then
            fovCircle.Radius = Config.Aimbot.FOV
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        end
    end

    -- ═══ SPEED ═══
    if Config.Speed.Enabled and hum then
        if Config.Speed.Mode == "WalkSpeed" then
            hum.WalkSpeed = Config.Speed.Value
        elseif Config.Speed.Mode == "CFrame" and root then
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                root.CFrame = root.CFrame + moveDir * (Config.Speed.Value / 60)
            end
        elseif Config.Speed.Mode == "Velocity" and root then
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                root.Velocity = Vector3.new(moveDir.X * Config.Speed.Value, root.Velocity.Y, moveDir.Z * Config.Speed.Value)
            end
        end
    end

    -- ═══ NOCLIP ═══
    if Config.Noclip.Enabled and char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    -- ═══ FLY ═══
    if Config.Fly.Enabled then
        if not flyActive then StartFly() end
        if flyActive and root and flyBV and flyBG then
            local moveDir = hum and hum.MoveDirection or Vector3.zero
            local camCF = Camera.CFrame
            local flySpeed = Config.Fly.FlySpeed

            local direction = Vector3.zero
            if moveDir.Magnitude > 0 then
                direction = (camCF.LookVector * moveDir.Z + camCF.RightVector * moveDir.X).Unit
                -- На мобильном используем MoveDirection
                direction = camCF:VectorToWorldSpace(Vector3.new(moveDir.X, 0, -moveDir.Z))
                if direction.Magnitude > 0 then direction = direction.Unit end
            end

            -- Проверяем нажат ли Jump
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) or (hum and hum.Jump) then
                direction = direction + Vector3.new(0, 0.5, 0)
            end

            flyBV.Velocity = direction * flySpeed
            flyBG.CFrame = camCF
        end
    else
        if flyActive then StopFly() end
    end

    -- ═══ AUTO SPRINT ═══
    if Config.AutoSprint.Enabled and hum then
        if hum.MoveDirection.Magnitude > 0 then
            hum.WalkSpeed = math.max(hum.WalkSpeed, 24)
        end
    end

    -- ═══ FULLBRIGHT ═══
    if Config.Fullbright.Enabled then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
    end

    -- ═══ NO FOG ═══
    if Config.NoFog.Enabled then
        Lighting.FogEnd = 1e10
        Lighting.FogStart = 1e10
    end

    -- ═══ ESP UPDATE ═══
    if Config.ESP.Enabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= Player then
                if not ESPObjects[plr] then
                    CreateESPForPlayer(plr)
                end

                local esp = ESPObjects[plr]
                if esp then
                    local pChar = plr.Character
                    local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
                    local pHum = pChar and pChar:FindFirstChildOfClass("Humanoid")
                    local pHead = pChar and pChar:FindFirstChild("Head")

                    if pRoot and pHum and pHum.Health > 0 and root then
                        local dist = (root.Position - pRoot.Position).Magnitude
                        if dist <= Config.ESP.MaxDistance then
                            local screenPos, onScreen = Camera:WorldToScreenPoint(pRoot.Position)
                            local headScreenPos = Camera:WorldToScreenPoint((pHead or pRoot).Position + Vector3.new(0, 1.5, 0))

                            if onScreen then
                                local factor = 1 / (screenPos.Z * math.tan(math.rad(Camera.FieldOfView / 2)) * 2 / Camera.ViewportSize.Y)
                                local boxHeight = factor * 5.5
                                local boxWidth = boxHeight * 0.55

                                -- Name
                                if esp.Name then
                                    esp.Name.Visible = Config.ESP.ShowNames
                                    esp.Name.Text = plr.DisplayName or plr.Name
                                    esp.Name.Position = Vector2.new(screenPos.X, headScreenPos.Y - 20)
                                end

                                -- Health
                                if esp.Health then
                                    esp.Health.Visible = Config.ESP.ShowHealth
                                    local hp = math.floor(pHum.Health)
                                    local maxHp = math.floor(pHum.MaxHealth)
                                    esp.Health.Text = hp .. "/" .. maxHp
                                    esp.Health.Position = Vector2.new(screenPos.X, headScreenPos.Y - 8)
                                    -- Color based on health
                                    local hpPct = hp / maxHp
                                    esp.Health.Color = Color3.new(1 - hpPct, hpPct, 0.2)
                                end

                                -- Distance
                                if esp.Distance then
                                    esp.Distance.Visible = Config.ESP.ShowDistance
                                    esp.Distance.Text = math.floor(dist) .. "m"
                                    esp.Distance.Position = Vector2.new(screenPos.X, screenPos.Y + boxHeight / 2 + 4)
                                end

                                -- Box
                                if Config.ESP.ShowBox then
                                    local cx, cy = screenPos.X, screenPos.Y
                                    local hw, hh = boxWidth / 2, boxHeight / 2
                                    local cornerLen = math.min(boxWidth, boxHeight) * 0.25

                                    -- Top line
                                    if esp.BoxTop then
                                        esp.BoxTop.Visible = true
                                        esp.BoxTop.From = Vector2.new(cx - hw, cy - hh)
                                        esp.BoxTop.To = Vector2.new(cx + hw, cy - hh)
                                    end
                                    -- Bottom
                                    if esp.BoxBottom then
                                        esp.BoxBottom.Visible = true
                                        esp.BoxBottom.From = Vector2.new(cx - hw, cy + hh)
                                        esp.BoxBottom.To = Vector2.new(cx + hw, cy + hh)
                                    end
                                    -- Left
                                    if esp.BoxLeft then
                                        esp.BoxLeft.Visible = true
                                        esp.BoxLeft.From = Vector2.new(cx - hw, cy - hh)
                                        esp.BoxLeft.To = Vector2.new(cx - hw, cy + hh)
                                    end
                                    -- Right
                                    if esp.BoxRight then
                                        esp.BoxRight.Visible = true
                                        esp.BoxRight.From = Vector2.new(cx + hw, cy - hh)
                                        esp.BoxRight.To = Vector2.new(cx + hw, cy + hh)
                                    end

                                    -- Corner lines (остальные скрываем)
                                    if esp.BoxTL then esp.BoxTL.Visible = false end
                                    if esp.BoxTR then esp.BoxTR.Visible = false end
                                    if esp.BoxBL then esp.BoxBL.Visible = false end
                                    if esp.BoxBR then esp.BoxBR.Visible = false end
                                else
                                    for _, key in pairs({"BoxTL", "BoxTR", "BoxBL", "BoxBR", "BoxTop", "BoxBottom", "BoxLeft", "BoxRight"}) do
                                        if esp[key] then esp[key].Visible = false end
                                    end
                                end
                            else
                                -- Скрыть всё
                                for _, obj in pairs(esp) do
                                    pcall(function() obj.Visible = false end)
                                end
                            end
                        else
                            for _, obj in pairs(esp) do
                                pcall(function() obj.Visible = false end)
                            end
                        end
                    else
                        for _, obj in pairs(esp) do
                            pcall(function() obj.Visible = false end)
                        end
                    end
                end
            end
        end
    else
        -- Скрыть все ESP
        for _, esp in pairs(ESPObjects) do
            for _, obj in pairs(esp) do
                pcall(function() obj.Visible = false end)
            end
        end
    end

    -- ═══ CHAMS ═══
    if Config.ChamPlayers.Enabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= Player and plr.Character then
                if not ChamObjects[plr] then
                    ApplyChams(plr)
                end
            end
        end
    else
        ClearAllChams()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- INFINITE JUMP
-- ═══════════════════════════════════════════════════════════════
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump.Enabled then
        local hum = GetHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            local root = GetRootPart()
            if root then
                root.Velocity = Vector3.new(root.Velocity.X, Config.InfiniteJump.Power, root.Velocity.Z)
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- AUTO ATTACK
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if Config.AutoAttack.Enabled and IsAlive() then
            -- Vagrant Survival: Пытаемся симулировать атаку через Virtual Input или Remote
            pcall(function()
                -- Метод 1: Виртуальный клик
                local viu = game:GetService("VirtualInputManager")
                if viu then
                    viu:SendMouseButtonEvent(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2, 0, true, game, 1)
                    task.wait(0.05)
                    viu:SendMouseButtonEvent(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2, 0, false, game, 1)
                end
            end)

            -- Метод 2: Поиск ремоутов атаки
            pcall(function()
                local char = GetCharacter()
                if char then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        tool:Activate()
                    end
                end
            end)
        end
        task.wait(Config.AutoAttack.Delay)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- KILL AURA
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if Config.KillAura.Enabled and IsAlive() then
            local root = GetRootPart()
            if root then
                for _, plr in pairs(Players:GetPlayers()) do
                    if IsEnemy(plr) then
                        local pChar = plr.Character
                        if pChar then
                            local pRoot = pChar:FindFirstChild("HumanoidRootPart")
                            if pRoot and (root.Position - pRoot.Position).Magnitude <= Config.KillAura.Range then
                                pcall(function()
                                    local char = GetCharacter()
                                    local tool = char:FindFirstChildOfClass("Tool")
                                    if tool then
                                        tool:Activate()
                                    end
                                end)

                                -- Попытка через Remote Events (Vagrant Survival specific)
                                pcall(function()
                                    -- Ищем ремоуты связанные с атакой/повреждением
                                    for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                                        if v:IsA("RemoteEvent") and (v.Name:lower():find("attack") or v.Name:lower():find("hit") or v.Name:lower():find("damage") or v.Name:lower():find("swing")) then
                                            v:FireServer(pChar)
                                            break
                                        end
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end
        task.wait(Config.KillAura.Delay)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- AUTO PICKUP
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if Config.AutoPickup.Enabled and IsAlive() then
            local root = GetRootPart()
            if root then
                -- Ищем предметы в Workspace
                pcall(function()
                    local itemFolders = {
                        Workspace:FindFirstChild("Drops"),
                        Workspace:FindFirstChild("Items"),
                        Workspace:FindFirstChild("DroppedItems"),
                        Workspace:FindFirstChild("Loot"),
                        Workspace:FindFirstChild("Pickups"),
                    }

                    -- Также ищем все модели/части с ClickDetector или ProximityPrompt
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if (obj:IsA("ProximityPrompt")) then
                            local parent = obj.Parent
                            if parent and parent:IsA("BasePart") then
                                local dist = (root.Position - parent.Position).Magnitude
                                if dist <= Config.AutoPickup.Range then
                                    pcall(function()
                                        fireproximityprompt(obj)
                                    end)
                                end
                            elseif parent and parent:IsA("Model") then
                                local primaryPart = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart")
                                if primaryPart then
                                    local dist = (root.Position - primaryPart.Position).Magnitude
                                    if dist <= Config.AutoPickup.Range then
                                        pcall(function()
                                            fireproximityprompt(obj)
                                        end)
                                    end
                                end
                            end
                        elseif obj:IsA("ClickDetector") then
                            local parent = obj.Parent
                            if parent and parent:IsA("BasePart") then
                                local dist = (root.Position - parent.Position).Magnitude
                                if dist <= Config.AutoPickup.Range then
                                    pcall(function()
                                        fireclickdetector(obj)
                                    end)
                                end
                            end
                        end
                    end

                    -- Подбор через ремоуты
                    for _, folder in pairs(itemFolders) do
                        if folder then
                            for _, item in pairs(folder:GetChildren()) do
                                local itemPart = item:IsA("BasePart") and item or (item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")))
                                if itemPart then
                                    local dist = (root.Position - itemPart.Position).Magnitude
                                    if dist <= Config.AutoPickup.Range then
                                        -- Телепорт к предмету
                                        pcall(function()
                                            root.CFrame = CFrame.new(itemPart.Position + Vector3.new(0, 3, 0))
                                        end)
                                        task.wait(0.1)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
        task.wait(0.5)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ITEM ESP (Billboard)
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if Config.ItemESP.Enabled then
            local root = GetRootPart()
            -- Ищем предметы
            pcall(function()
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if (obj:IsA("Tool") or (obj:IsA("Model") and obj:FindFirstChild("Handle"))) or
                       (obj.Parent and (obj.Parent.Name == "Drops" or obj.Parent.Name == "Items" or obj.Parent.Name == "DroppedItems" or obj.Parent.Name == "Loot")) then

                        local part = obj:IsA("BasePart") and obj or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
                        if part and not ItemESPObjects[obj] then
                            if root and (root.Position - part.Position).Magnitude <= Config.ItemESP.MaxDistance then
                                pcall(function()
                                    local bb = Instance.new("BillboardGui")
                                    bb.Name = "EspadaItemESP"
                                    bb.Size = UDim2.new(0, 120, 0, 30)
                                    bb.StudsOffset = Vector3.new(0, 3, 0)
                                    bb.AlwaysOnTop = true
                                    bb.Adornee = part
                                    bb.Parent = game:GetService("CoreGui")

                                    local label = Instance.new("TextLabel", bb)
                                    label.Size = UDim2.new(1, 0, 1, 0)
                                    label.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
                                    label.BackgroundTransparency = 0.3
                                    label.TextColor3 = Color3.fromRGB(255, 210, 60)
                                    label.TextSize = 12
                                    label.Font = Enum.Font.GothamBold
                                    label.Text = "📦 " .. obj.Name
                                    Instance.new("UICorner", label).CornerRadius = UDim.new(0, 4)
                                    Instance.new("UIStroke", label).Color = Color3.fromRGB(255, 210, 60)

                                    ItemESPObjects[obj] = {Billboard = bb}
                                end)
                            end
                        end
                    end
                end

                -- Удаляем ESP мёртвых объектов
                for obj, data in pairs(ItemESPObjects) do
                    if not obj or not obj.Parent then
                        pcall(function() data.Billboard:Destroy() end)
                        ItemESPObjects[obj] = nil
                    end
                end
            end)
        else
            ClearItemESP()
        end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ОБРАБОТКА НОВЫХ/УХОДЯЩИХ ИГРОКОВ
-- ═══════════════════════════════════════════════════════════════
Players.PlayerRemoving:Connect(function(plr)
    RemoveESPForPlayer(plr)
    RemoveChams(plr)
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if Config.ESP.Enabled then
            RemoveESPForPlayer(plr)
            CreateESPForPlayer(plr)
        end
        if Config.ChamPlayers.Enabled then
            RemoveChams(plr)
            ApplyChams(plr)
        end
    end)
end)

-- Для существующих игроков
for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= Player then
        plr.CharacterAdded:Connect(function()
            task.wait(1)
            if Config.ChamPlayers.Enabled then
                RemoveChams(plr)
                ApplyChams(plr)
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- RESPAWN HANDLER
-- ═══════════════════════════════════════════════════════════════
Player.CharacterAdded:Connect(function(char)
    task.wait(1)
    -- Пересоздаём fly если был активен
    if Config.Fly.Enabled then
        StopFly()
        task.wait(0.5)
        StartFly()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- FULLBRIGHT/FOG RESTORE ПРИ ОТКЛЮЧЕНИИ
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    local wasFB = false
    local wasNF = false
    while true do
        if not Config.Fullbright.Enabled and wasFB then
            pcall(function()
                Lighting.Brightness = originalLighting.Brightness
                Lighting.ClockTime = originalLighting.ClockTime
                Lighting.GlobalShadows = originalLighting.GlobalShadows
                Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
                Lighting.Ambient = originalLighting.Ambient
            end)
        end
        wasFB = Config.Fullbright.Enabled

        if not Config.NoFog.Enabled and wasNF then
            pcall(function()
                Lighting.FogEnd = originalLighting.FogEnd
                Lighting.FogStart = originalLighting.FogStart
            end)
        end
        wasNF = Config.NoFog.Enabled

        task.wait(0.5)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- АВТОСОХРАНЕНИЕ
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(30)
        if Config.AutoSave then
            SaveConfig()
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- WATERMARK (статусбар внизу)
-- ═══════════════════════════════════════════════════════════════
local Watermark = CreateInstance("Frame", {
    Size = UDim2.new(0, 240, 0, 28),
    Position = UDim2.new(0.5, -120, 0, 6),
    BackgroundColor3 = Colors.Background,
    BackgroundTransparency = 0.2,
    Parent = ScreenGui
})
AddCorner(Watermark, 6)
AddStroke(Watermark, Colors.Accent, 1, 0.6)

local WatermarkLabel = CreateInstance("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "⚔ EspadaWare | Vagrant Survival | 60 FPS",
    TextColor3 = Colors.TextDim,
    TextSize = 11,
    Font = Enum.Font.GothamSemibold,
    Parent = Watermark
})
AddGradient(Watermark, Color3.fromRGB(20, 20, 32), Color3.fromRGB(12, 12, 20), 0)

-- FPS Counter
task.spawn(function()
    local frames = 0
    local lastTime = tick()
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
    end)
    while true do
        task.wait(1)
        local now = tick()
        local fps = math.floor(frames / (now - lastTime))
        frames = 0
        lastTime = now
        WatermarkLabel.Text = "⚔ EspadaWare | Vagrant Survival | " .. fps .. " FPS"
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ПРИВЕТСТВЕННОЕ УВЕДОМЛЕНИЕ
-- ═══════════════════════════════════════════════════════════════
task.delay(2, function()
    ShowNotification("EspadaWare", "Loaded successfully! Tap ⚔ to open.", 4)
end)

-- ═══════════════════════════════════════════════════════════════
-- КОНЕЦ СКРИПТА
-- ═══════════════════════════════════════════════════════════════
