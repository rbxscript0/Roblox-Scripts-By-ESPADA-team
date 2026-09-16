--[[
    2ZWare - Vagrant Survival
    Full Feature Script
    Single LocalScript
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- Config System
local CONFIG_KEY = "2ZWare_VagrantSurvival_Config"
local DefaultConfig = {
    -- Main
    Aimbot = false,
    AimbotFOV = 120,
    AimbotSmoothing = 5,
    AimbotBone = "Head",
    AimbotTeamCheck = true,
    AimbotVisCheck = false,
    AimbotShowFOV = true,
    AimbotKey = Enum.UserInputType.Touch,

    SilentAim = false,
    SilentAimFOV = 150,
    SilentAimBone = "Head",
    SilentAimHitChance = 100,
    SilentAimTeamCheck = true,

    TriggerBot = false,
    TriggerBotDelay = 0.05,
    TriggerBotRange = 200,

    -- Movement
    Speed = false,
    SpeedValue = 20,
    Fly = false,
    FlySpeed = 50,
    InfiniteJump = false,
    JumpPower = false,
    JumpPowerValue = 50,
    NoClip = false,
    AutoSprint = false,

    -- Visuals
    ESP = false,
    ESPBoxes = true,
    ESPNames = true,
    ESPHealth = true,
    ESPDistance = true,
    ESPTracers = false,
    ESPTeamCheck = true,
    ESPMaxDistance = 1000,
    ESPColor = {r = 0, g = 255, b = 100},

    Fullbright = false,
    FullbrightAmbient = {r = 200, g = 200, b = 200},

    Chams = false,
    ChamsColor = {r = 255, g = 0, b = 100},
    ChamsFillTransparency = 0.5,
    ChamsOutlineTransparency = 0,
    ChamsTeamCheck = true,

    ItemESP = false,
    ItemESPMaxDistance = 500,

    -- Settings
    ToggleKey = "RightShift",
    UIScale = 1,
    AccentColor = {r = 100, g = 50, b = 255},
    MenuOpen = true,
    Notifications = true,
    StreamerMode = false,
    AntiAFK = true,
}

local Config = {}

-- Deep copy
local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deepCopy(v)
    end
    return copy
end

-- Save/Load Config
local function SaveConfig()
    local success, err = pcall(function()
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
        for k, v in pairs(DefaultConfig) do
            if data[k] ~= nil then
                Config[k] = data[k]
            else
                Config[k] = deepCopy(v)
            end
        end
    else
        Config = deepCopy(DefaultConfig)
    end
end

local function ResetConfig()
    Config = deepCopy(DefaultConfig)
    SaveConfig()
end

LoadConfig()

-- Auto-save timer
local autoSaveTimer = 0

-- Destroy old GUI
if CoreGui:FindFirstChild("2ZWare") then
    CoreGui:FindFirstChild("2ZWare"):Destroy()
end

-- ==================== GUI CREATION ====================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "2ZWare"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
    end
end)
ScreenGui.Parent = CoreGui

-- Colors
local Colors = {
    Background = Color3.fromRGB(12, 12, 18),
    Surface = Color3.fromRGB(18, 18, 28),
    SurfaceLight = Color3.fromRGB(25, 25, 38),
    SurfaceHover = Color3.fromRGB(32, 32, 48),
    Card = Color3.fromRGB(20, 20, 32),
    CardHover = Color3.fromRGB(28, 28, 42),
    Accent = Color3.fromRGB(100, 50, 255),
    AccentDark = Color3.fromRGB(70, 30, 200),
    AccentGlow = Color3.fromRGB(130, 80, 255),
    Green = Color3.fromRGB(50, 255, 120),
    Red = Color3.fromRGB(255, 60, 80),
    Orange = Color3.fromRGB(255, 160, 40),
    Yellow = Color3.fromRGB(255, 220, 50),
    Cyan = Color3.fromRGB(50, 200, 255),
    TextPrimary = Color3.fromRGB(240, 240, 255),
    TextSecondary = Color3.fromRGB(140, 140, 170),
    TextMuted = Color3.fromRGB(80, 80, 110),
    Border = Color3.fromRGB(40, 40, 60),
    Toggle_On = Color3.fromRGB(100, 50, 255),
    Toggle_Off = Color3.fromRGB(50, 50, 70),
    Slider_BG = Color3.fromRGB(35, 35, 55),
    Shadow = Color3.fromRGB(0, 0, 0),
}

-- Utility functions
local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" and k ~= "Children" then
            pcall(function() inst[k] = v end)
        end
    end
    if props.Children then
        for _, child in ipairs(props.Children) do
            child.Parent = inst
        end
    end
    if props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function AddCorner(parent, radius)
    return Create("UICorner", {CornerRadius = UDim.new(0, radius or 8), Parent = parent})
end

local function AddStroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Colors.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        Parent = parent
    })
end

local function AddPadding(parent, t, b, l, r)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, t or 8),
        PaddingBottom = UDim.new(0, b or 8),
        PaddingLeft = UDim.new(0, l or 8),
        PaddingRight = UDim.new(0, r or 8),
        Parent = parent
    })
end

local function AddGradient(parent, c1, c2, rotation)
    return Create("UIGradient", {
        Color = ColorSequence.new(c1, c2),
        Rotation = rotation or 90,
        Parent = parent
    })
end

local function AddShadow(parent, size, transparency)
    local shadow = Create("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = transparency or 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Size = UDim2.new(1, size or 30, 1, size or 30),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = parent.ZIndex - 1,
        Parent = parent
    })
    return shadow
end

local function Tween(obj, props, duration, style, dir)
    local tweenInfo = TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    local tween = TweenService:Create(obj, tweenInfo, props)
    tween:Play()
    return tween
end

local function Ripple(button)
    local ripple = Create("Frame", {
        Name = "Ripple",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.85,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = button.ZIndex + 5,
        Parent = button
    })
    AddCorner(ripple, 999)
    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    Tween(ripple, {Size = UDim2.new(0, maxSize, 0, maxSize), BackgroundTransparency = 1}, 0.5)
    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

-- Notification System
local NotificationHolder = Create("Frame", {
    Name = "Notifications",
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 300, 1, 0),
    Position = UDim2.new(1, -310, 0, 50),
    Parent = ScreenGui,
    ZIndex = 100,
})
Create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 8),
    VerticalAlignment = Enum.VerticalAlignment.Top,
    Parent = NotificationHolder
})

local function Notify(title, message, duration, ntype)
    if not Config.Notifications then return end
    local typeColors = {
        info = Colors.Accent,
        success = Colors.Green,
        warning = Colors.Orange,
        error = Colors.Red,
    }
    local color = typeColors[ntype or "info"] or Colors.Accent

    local notif = Create("Frame", {
        Name = "Notification",
        BackgroundColor3 = Colors.Surface,
        Size = UDim2.new(1, 0, 0, 60),
        ClipsDescendants = true,
        Parent = NotificationHolder,
        ZIndex = 100,
    })
    AddCorner(notif, 10)
    AddStroke(notif, color, 1, 0.3)
    
    local accentBar = Create("Frame", {
        BackgroundColor3 = color,
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        Parent = notif,
        ZIndex = 101,
    })
    AddCorner(accentBar, 2)

    Create("TextLabel", {
        Text = title or "2ZWare",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Colors.TextPrimary,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 0, 18),
        Position = UDim2.new(0, 20, 0, 8),
        Parent = notif,
        ZIndex = 101,
    })
    Create("TextLabel", {
        Text = message or "",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Colors.TextSecondary,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 0, 28),
        Position = UDim2.new(0, 20, 0, 28),
        Parent = notif,
        ZIndex = 101,
    })

    local progress = Create("Frame", {
        BackgroundColor3 = color,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        Parent = notif,
        ZIndex = 101,
    })

    notif.BackgroundTransparency = 1
    Tween(notif, {BackgroundTransparency = 0}, 0.3)
    
    local dur = duration or 3
    Tween(progress, {Size = UDim2.new(0, 0, 0, 2)}, dur, Enum.EasingStyle.Linear)
    
    task.delay(dur, function()
        Tween(notif, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)}, 0.3)
        task.delay(0.35, function()
            notif:Destroy()
        end)
    end)
end

-- ==================== TOGGLE BUTTON (Mobile) ====================
local ToggleButton = Create("ImageButton", {
    Name = "ToggleButton",
    BackgroundColor3 = Colors.Accent,
    Size = UDim2.new(0, 50, 0, 50),
    Position = UDim2.new(0, 15, 0.5, -25),
    AnchorPoint = Vector2.new(0, 0),
    ZIndex = 50,
    Image = "",
    AutoButtonColor = false,
    Parent = ScreenGui
})
AddCorner(ToggleButton, 25)
AddStroke(ToggleButton, Colors.AccentGlow, 2, 0.3)
AddGradient(ToggleButton, Colors.Accent, Colors.AccentDark, 135)

local ToggleLogo = Create("TextLabel", {
    Text = "2Z",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    Parent = ToggleButton,
    ZIndex = 51,
})

-- Draggable toggle button
local draggingToggle = false
local dragStartToggle, startPosToggle
ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingToggle = true
        dragStartToggle = input.Position
        startPosToggle = ToggleButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingToggle = false
            end
        end)
    end
end)
ToggleButton.InputChanged:Connect(function(input)
    if draggingToggle and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStartToggle
        ToggleButton.Position = UDim2.new(
            startPosToggle.X.Scale, startPosToggle.X.Offset + delta.X,
            startPosToggle.Y.Scale, startPosToggle.Y.Offset + delta.Y
        )
    end
end)

-- Pulse animation for toggle button
task.spawn(function()
    while ScreenGui.Parent do
        if not Config.MenuOpen then
            Tween(ToggleButton, {Size = UDim2.new(0, 54, 0, 54)}, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.8)
            Tween(ToggleButton, {Size = UDim2.new(0, 50, 0, 50)}, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.8)
        else
            task.wait(0.5)
        end
    end
end)

-- ==================== MAIN WINDOW ====================
local MainFrame = Create("Frame", {
    Name = "MainFrame",
    BackgroundColor3 = Colors.Background,
    Size = UDim2.new(0, 420, 0, 520),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    ClipsDescendants = true,
    ZIndex = 10,
    Parent = ScreenGui
})
AddCorner(MainFrame, 16)
AddStroke(MainFrame, Colors.Border, 1, 0.3)

-- Shadow for main frame
local mainShadow = Create("ImageLabel", {
    Name = "MainShadow",
    BackgroundTransparency = 1,
    Image = "rbxassetid://6014261993",
    ImageColor3 = Color3.fromRGB(0, 0, 0),
    ImageTransparency = 0.4,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(49, 49, 450, 450),
    Size = UDim2.new(1, 60, 1, 60),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    ZIndex = 9,
    Parent = MainFrame
})

-- Top bar gradient accent line
local topAccent = Create("Frame", {
    Name = "TopAccent",
    BackgroundColor3 = Colors.Accent,
    Size = UDim2.new(1, 0, 0, 3),
    Position = UDim2.new(0, 0, 0, 0),
    ZIndex = 20,
    Parent = MainFrame
})
AddGradient(topAccent, Colors.Accent, Colors.Cyan, 0)

-- Header
local Header = Create("Frame", {
    Name = "Header",
    BackgroundColor3 = Colors.Surface,
    Size = UDim2.new(1, 0, 0, 50),
    Position = UDim2.new(0, 0, 0, 3),
    ZIndex = 15,
    Parent = MainFrame
})

-- Header gradient
AddGradient(Header, Colors.Surface, Color3.fromRGB(15, 15, 24), 90)

-- Logo
local LogoFrame = Create("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 120, 0, 30),
    Position = UDim2.new(0, 15, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    ZIndex = 16,
    Parent = Header
})

local Logo2Z = Create("TextLabel", {
    Text = "2Z",
    Font = Enum.Font.GothamBlack,
    TextSize = 22,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 30, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 17,
    Parent = LogoFrame
})

local LogoWare = Create("TextLabel", {
    Text = "Ware",
    Font = Enum.Font.GothamBold,
    TextSize = 22,
    TextColor3 = Colors.Accent,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 50, 1, 0),
    Position = UDim2.new(0, 30, 0, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 17,
    Parent = LogoFrame
})

-- Version badge
local VersionBadge = Create("Frame", {
    BackgroundColor3 = Colors.Accent,
    BackgroundTransparency = 0.8,
    Size = UDim2.new(0, 36, 0, 18),
    Position = UDim2.new(0, 84, 0.5, -2),
    AnchorPoint = Vector2.new(0, 0.5),
    ZIndex = 17,
    Parent = LogoFrame
})
AddCorner(VersionBadge, 4)
Create("TextLabel", {
    Text = "v2.0",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = Colors.Accent,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 18,
    Parent = VersionBadge
})

-- Close button
local CloseBtn = Create("TextButton", {
    Name = "Close",
    Text = "✕",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Colors.TextSecondary,
    BackgroundColor3 = Colors.SurfaceLight,
    BackgroundTransparency = 0.5,
    Size = UDim2.new(0, 32, 0, 32),
    Position = UDim2.new(1, -42, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    ZIndex = 16,
    AutoButtonColor = false,
    Parent = Header
})
AddCorner(CloseBtn, 8)

CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, {BackgroundTransparency = 0, TextColor3 = Colors.Red}, 0.2)
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, {BackgroundTransparency = 0.5, TextColor3 = Colors.TextSecondary}, 0.2)
end)

-- Tab bar
local TabBar = Create("Frame", {
    Name = "TabBar",
    BackgroundColor3 = Colors.Surface,
    BackgroundTransparency = 0.3,
    Size = UDim2.new(1, 0, 0, 42),
    Position = UDim2.new(0, 0, 0, 53),
    ZIndex = 15,
    Parent = MainFrame
})

local TabBarLayout = Create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
    Parent = TabBar
})
AddPadding(TabBar, 6, 6, 10, 10)

-- Tab indicator
local TabIndicator = Create("Frame", {
    Name = "TabIndicator",
    BackgroundColor3 = Colors.Accent,
    Size = UDim2.new(0, 70, 0, 3),
    Position = UDim2.new(0, 0, 1, -3),
    ZIndex = 20,
    Parent = TabBar
})
AddCorner(TabIndicator, 2)

-- Content Area
local ContentArea = Create("Frame", {
    Name = "ContentArea",
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, -98),
    Position = UDim2.new(0, 0, 0, 98),
    ClipsDescendants = true,
    ZIndex = 11,
    Parent = MainFrame
})

-- Settings Panel (slides over content)
local SettingsPanel = Create("Frame", {
    Name = "SettingsPanel",
    BackgroundColor3 = Colors.Background,
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    ClipsDescendants = true,
    ZIndex = 25,
    Parent = ContentArea
})

local SettingsPanelTitle = Create("Frame", {
    BackgroundColor3 = Colors.Surface,
    Size = UDim2.new(1, 0, 0, 40),
    ZIndex = 26,
    Parent = SettingsPanel
})
AddGradient(SettingsPanelTitle, Colors.SurfaceLight, Colors.Surface, 90)

local SettingsBackBtn = Create("TextButton", {
    Text = "← Back",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Colors.Accent,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 80, 1, 0),
    Position = UDim2.new(0, 5, 0, 0),
    ZIndex = 27,
    Parent = SettingsPanelTitle
})

local SettingsTitleLabel = Create("TextLabel", {
    Name = "Title",
    Text = "Settings",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Colors.TextPrimary,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -90, 1, 0),
    Position = UDim2.new(0, 90, 0, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 27,
    Parent = SettingsPanelTitle
})

local SettingsContent = Create("ScrollingFrame", {
    Name = "Content",
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, -44),
    Position = UDim2.new(0, 0, 0, 44),
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = Colors.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 26,
    Parent = SettingsPanel
})
Create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
    Parent = SettingsContent
})
AddPadding(SettingsContent, 8, 8, 12, 12)

local settingsPanelOpen = false

local function OpenSettingsPanel(title)
    SettingsTitleLabel.Text = title
    -- clear old
    for _, c in ipairs(SettingsContent:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
            c:Destroy()
        end
    end
    settingsPanelOpen = true
    Tween(SettingsPanel, {Position = UDim2.new(0, 0, 0, 0)}, 0.35)
end

local function CloseSettingsPanel()
    settingsPanelOpen = false
    Tween(SettingsPanel, {Position = UDim2.new(1, 0, 0, 0)}, 0.35)
end

SettingsBackBtn.MouseButton1Click:Connect(CloseSettingsPanel)

-- ==================== SETTINGS WIDGETS ====================

local function CreateSettingToggle(parent, label, configKey, order)
    local frame = Create("Frame", {
        BackgroundColor3 = Colors.Card,
        Size = UDim2.new(1, 0, 0, 38),
        LayoutOrder = order or 0,
        ZIndex = 27,
        Parent = parent
    })
    AddCorner(frame, 8)

    Create("TextLabel", {
        Text = label,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Colors.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 28,
        Parent = frame
    })

    local toggleBG = Create("Frame", {
        BackgroundColor3 = Config[configKey] and Colors.Toggle_On or Colors.Toggle_Off,
        Size = UDim2.new(0, 40, 0, 22),
        Position = UDim2.new(1, -52, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        ZIndex = 28,
        Parent = frame
    })
    AddCorner(toggleBG, 11)

    local toggleCircle = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.new(0, 16, 0, 16),
        Position = Config[configKey] and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        ZIndex = 29,
        Parent = toggleBG
    })
    AddCorner(toggleCircle, 8)

    local btn = Create("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 30,
        Parent = frame
    })

    btn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        Tween(toggleBG, {BackgroundColor3 = Config[configKey] and Colors.Toggle_On or Colors.Toggle_Off}, 0.2)
        Tween(toggleCircle, {Position = Config[configKey] and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}, 0.2)
        SaveConfig()
    end)

    return frame
end

local function CreateSettingSlider(parent, label, configKey, minVal, maxVal, step, order)
    local frame = Create("Frame", {
        BackgroundColor3 = Colors.Card,
        Size = UDim2.new(1, 0, 0, 56),
        LayoutOrder = order or 0,
        ZIndex = 27,
        ClipsDescendants = true,
        Parent = parent
    })
    AddCorner(frame, 8)

    local valueLabel = Create("TextLabel", {
        Text = tostring(Config[configKey]),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Colors.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -52, 0, 4),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 28,
        Parent = frame
    })

    Create("TextLabel", {
        Text = label,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Colors.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 20),
        Position = UDim2.new(0, 12, 0, 6),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 28,
        Parent = frame
    })

    local sliderBG = Create("Frame", {
        BackgroundColor3 = Colors.Slider_BG,
        Size = UDim2.new(1, -24, 0, 6),
        Position = UDim2.new(0, 12, 0, 36),
        ZIndex = 28,
        Parent = frame
    })
    AddCorner(sliderBG, 3)

    local pct = math.clamp((Config[configKey] - minVal) / (maxVal - minVal), 0, 1)
    local sliderFill = Create("Frame", {
        BackgroundColor3 = Colors.Accent,
        Size = UDim2.new(pct, 0, 1, 0),
        ZIndex = 29,
        Parent = sliderBG
    })
    AddCorner(sliderFill, 3)
    AddGradient(sliderFill, Colors.AccentGlow, Colors.Accent, 0)

    local sliderKnob = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(pct, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 30,
        Parent = sliderBG
    })
    AddCorner(sliderKnob, 7)

    local knobGlow = Create("Frame", {
        BackgroundColor3 = Colors.Accent,
        BackgroundTransparency = 0.6,
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 29,
        Parent = sliderKnob
    })
    AddCorner(knobGlow, 11)

    local dragging = false
    local function updateSlider(inputPos)
        local relX = math.clamp((inputPos.X - sliderBG.AbsolutePosition.X) / sliderBG.AbsoluteSize.X, 0, 1)
        local raw = minVal + (maxVal - minVal) * relX
        if step and step > 0 then
            raw = math.floor(raw / step + 0.5) * step
        end
        raw = math.clamp(raw, minVal, maxVal)
        Config[configKey] = raw
        local newPct = (raw - minVal) / (maxVal - minVal)
        sliderFill.Size = UDim2.new(newPct, 0, 1, 0)
        sliderKnob.Position = UDim2.new(newPct, 0, 0.5, 0)
        valueLabel.Text = tostring(math.floor(raw * 100) / 100)
    end

    local sliderBtn = Create("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 10, 0, 24),
        Position = UDim2.new(0, -5, 0, -9),
        ZIndex = 31,
        Parent = sliderBG
    })

    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(input.Position)
        end
    end)
    sliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            SaveConfig()
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            updateSlider(input.Position)
        end
    end)

    return frame
end

local function CreateSettingDropdown(parent, label, configKey, options, order)
    local frame = Create("Frame", {
        BackgroundColor3 = Colors.Card,
        Size = UDim2.new(1, 0, 0, 38),
        LayoutOrder = order or 0,
        ZIndex = 27,
        ClipsDescendants = true,
        Parent = parent
    })
    AddCorner(frame, 8)

    Create("TextLabel", {
        Text = label,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Colors.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -12, 0, 38),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 28,
        Parent = frame
    })

    local dropBtn = Create("TextButton", {
        Text = tostring(Config[configKey]) .. " ▼",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Colors.Accent,
        BackgroundColor3 = Colors.SurfaceLight,
        Size = UDim2.new(0.4, 0, 0, 26),
        Position = UDim2.new(0.58, 0, 0, 6),
        ZIndex = 28,
        AutoButtonColor = false,
        Parent = frame
    })
    AddCorner(dropBtn, 6)

    local expanded = false

    local optionsFrame = Create("Frame", {
        BackgroundColor3 = Colors.SurfaceLight,
        Size = UDim2.new(0.4, 0, 0, #options * 28 + 4),
        Position = UDim2.new(0.58, 0, 0, 34),
        Visible = false,
        ZIndex = 35,
        Parent = frame
    })
    AddCorner(optionsFrame, 6)
    AddStroke(optionsFrame, Colors.Border, 1, 0.5)
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = optionsFrame
    })
    AddPadding(optionsFrame, 2, 2, 2, 2)

    for i, opt in ipairs(options) do
        local optBtn = Create("TextButton", {
            Text = tostring(opt),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = Colors.TextPrimary,
            BackgroundColor3 = Colors.Card,
            BackgroundTransparency = 0.5,
            Size = UDim2.new(1, 0, 0, 26),
            LayoutOrder = i,
            ZIndex = 36,
            AutoButtonColor = false,
            Parent = optionsFrame
        })
        AddCorner(optBtn, 4)

        optBtn.MouseEnter:Connect(function()
            Tween(optBtn, {BackgroundTransparency = 0, BackgroundColor3 = Colors.Accent}, 0.15)
        end)
        optBtn.MouseLeave:Connect(function()
            Tween(optBtn, {BackgroundTransparency = 0.5, BackgroundColor3 = Colors.Card}, 0.15)
        end)
        optBtn.MouseButton1Click:Connect(function()
            Config[configKey] = opt
            dropBtn.Text = tostring(opt) .. " ▼"
            expanded = false
            optionsFrame.Visible = false
            frame.ClipsDescendants = true
            Tween(frame, {Size = UDim2.new(1, 0, 0, 38)}, 0.2)
            SaveConfig()
        end)
    end

    dropBtn.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            frame.ClipsDescendants = false
            optionsFrame.Visible = true
        else
            optionsFrame.Visible = false
            frame.ClipsDescendants = true
        end
    end)

    return frame
end

-- ==================== FEATURE CARD CREATOR ====================

local currentTab = "Main"
local TabPages = {}
local TabButtons = {}
local FeatureStates = {}

local function CreateTabPage(name)
    local page = Create("ScrollingFrame", {
        Name = name,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Visible = name == "Main",
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Colors.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 12,
        Parent = ContentArea
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = page
    })
    AddPadding(page, 8, 8, 12, 12)
    TabPages[name] = page
    return page
end

local function CreateFeatureCard(parent, name, description, configKey, icon, settingsBuilder, layoutOrder)
    local card = Create("Frame", {
        Name = "Feature_" .. name,
        BackgroundColor3 = Colors.Card,
        Size = UDim2.new(1, 0, 0, 58),
        LayoutOrder = layoutOrder or 0,
        ZIndex = 12,
        Parent = parent
    })
    AddCorner(card, 10)
    AddStroke(card, Colors.Border, 1, 0.7)

    -- Hover effect
    card.MouseEnter:Connect(function()
        Tween(card, {BackgroundColor3 = Colors.CardHover}, 0.2)
    end)
    card.MouseLeave:Connect(function()
        Tween(card, {BackgroundColor3 = Colors.Card}, 0.2)
    end)

    -- Icon
    local iconLabel = Create("TextLabel", {
        Text = icon or "⚡",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = Colors.Accent,
        BackgroundColor3 = Colors.SurfaceLight,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        ZIndex = 13,
        Parent = card
    })
    AddCorner(iconLabel, 10)

    -- Name
    Create("TextLabel", {
        Text = name,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Colors.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -140, 0, 18),
        Position = UDim2.new(0, 55, 0, 10),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
        Parent = card
    })

    -- Description
    Create("TextLabel", {
        Text = description or "",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = Colors.TextMuted,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -140, 0, 14),
        Position = UDim2.new(0, 55, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
        Parent = card
    })

    -- Status dot
    local statusDot = Create("Frame", {
        BackgroundColor3 = Config[configKey] and Colors.Green or Colors.TextMuted,
        Size = UDim2.new(0, 6, 0, 6),
        Position = UDim2.new(0, 55, 0, 48),
        ZIndex = 14,
        Parent = card
    })
    AddCorner(statusDot, 3)

    local statusText = Create("TextLabel", {
        Text = Config[configKey] and "Active" or "Inactive",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = Config[configKey] and Colors.Green or Colors.TextMuted,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 50, 0, 12),
        Position = UDim2.new(0, 65, 0, 45),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
        Parent = card
    })

    -- Toggle
    local toggleBG = Create("Frame", {
        BackgroundColor3 = Config[configKey] and Colors.Toggle_On or Colors.Toggle_Off,
        Size = UDim2.new(0, 44, 0, 24),
        Position = UDim2.new(1, -60, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        ZIndex = 14,
        Parent = card
    })
    AddCorner(toggleBG, 12)

    local toggleCircle = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.new(0, 18, 0, 18),
        Position = Config[configKey] and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        ZIndex = 15,
        Parent = toggleBG
    })
    AddCorner(toggleCircle, 9)

    -- Toggle glow when active
    if Config[configKey] then
        local glow = Create("Frame", {
            Name = "Glow",
            BackgroundColor3 = Colors.Accent,
            BackgroundTransparency = 0.7,
            Size = UDim2.new(0, 50, 0, 30),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            ZIndex = 13,
            Parent = toggleBG
        })
        AddCorner(glow, 15)
    end

    local toggleBtn = Create("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 50, 0, 30),
        Position = UDim2.new(1, -65, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        ZIndex = 16,
        Parent = card
    })

    local function updateToggleVisual()
        local on = Config[configKey]
        Tween(toggleBG, {BackgroundColor3 = on and Colors.Toggle_On or Colors.Toggle_Off}, 0.25)
        Tween(toggleCircle, {Position = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}, 0.25)
        Tween(statusDot, {BackgroundColor3 = on and Colors.Green or Colors.TextMuted}, 0.25)
        statusText.Text = on and "Active" or "Inactive"
        Tween(statusText, {TextColor3 = on and Colors.Green or Colors.TextMuted}, 0.25)
        -- Glow
        local oldGlow = toggleBG:FindFirstChild("Glow")
        if on and not oldGlow then
            local glow = Create("Frame", {
                Name = "Glow",
                BackgroundColor3 = Colors.Accent,
                BackgroundTransparency = 0.7,
                Size = UDim2.new(0, 50, 0, 30),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                ZIndex = 13,
                Parent = toggleBG
            })
            AddCorner(glow, 15)
        elseif not on and oldGlow then
            oldGlow:Destroy()
        end
    end

    toggleBtn.MouseButton1Click:Connect(function()
        Ripple(toggleBtn)
        Config[configKey] = not Config[configKey]
        updateToggleVisual()
        SaveConfig()
    end)

    FeatureStates[configKey] = {
        update = updateToggleVisual,
        card = card,
    }

    -- Settings gear button
    if settingsBuilder then
        local gearBtn = Create("TextButton", {
            Text = "⚙",
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextColor3 = Colors.TextSecondary,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(1, -95, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            ZIndex = 16,
            AutoButtonColor = false,
            Parent = card
        })
        gearBtn.MouseEnter:Connect(function()
            Tween(gearBtn, {TextColor3 = Colors.Accent, Rotation = 90}, 0.3)
        end)
        gearBtn.MouseLeave:Connect(function()
            Tween(gearBtn, {TextColor3 = Colors.TextSecondary, Rotation = 0}, 0.3)
        end)
        gearBtn.MouseButton1Click:Connect(function()
            OpenSettingsPanel(name .. " Settings")
            settingsBuilder(SettingsContent)
        end)
    end

    return card
end

-- ==================== CREATE TAB PAGES ====================

local mainPage = CreateTabPage("Main")
local movementPage = CreateTabPage("Movement")
local visualsPage = CreateTabPage("Visuals")
local settingsPage = CreateTabPage("Settings")

-- Tab switching
local tabNames = {"Main", "Movement", "Visuals", "Settings"}
local tabIcons = {
    Main = "🎯",
    Movement = "🏃",
    Visuals = "👁",
    Settings = "⚙"
}

for i, tabName in ipairs(tabNames) do
    local tabBtn = Create("TextButton", {
        Name = tabName,
        Text = tabIcons[tabName] .. " " .. tabName,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = tabName == "Main" and Colors.TextPrimary or Colors.TextSecondary,
        BackgroundColor3 = tabName == "Main" and Colors.SurfaceHover or Colors.Surface,
        BackgroundTransparency = tabName == "Main" and 0 or 0.8,
        Size = UDim2.new(0, 90, 0, 28),
        LayoutOrder = i,
        ZIndex = 16,
        AutoButtonColor = false,
        Parent = TabBar
    })
    AddCorner(tabBtn, 8)
    TabButtons[tabName] = tabBtn

    tabBtn.MouseButton1Click:Connect(function()
        if settingsPanelOpen then CloseSettingsPanel() end
        currentTab = tabName
        for name, page in pairs(TabPages) do
            page.Visible = (name == tabName)
        end
        for name, btn in pairs(TabButtons) do
            if name == tabName then
                Tween(btn, {TextColor3 = Colors.TextPrimary, BackgroundTransparency = 0, BackgroundColor3 = Colors.SurfaceHover}, 0.2)
            else
                Tween(btn, {TextColor3 = Colors.TextSecondary, BackgroundTransparency = 0.8, BackgroundColor3 = Colors.Surface}, 0.2)
            end
        end
        Ripple(tabBtn)
    end)
end

-- ==================== MAIN TAB FEATURES ====================

-- Section header helper
local function CreateSectionHeader(parent, text, order)
    local header = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 26),
        LayoutOrder = order or 0,
        Parent = parent
    })
    Create("TextLabel", {
        Text = "  " .. string.upper(text),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Colors.TextMuted,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
        Parent = header
    })
    local line = Create("Frame", {
        BackgroundColor3 = Colors.Border,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, -80, 0, 1),
        Position = UDim2.new(0, 75, 0.5, 0),
        ZIndex = 13,
        Parent = header
    })
    return header
end

CreateSectionHeader(mainPage, "Combat", 1)

-- Aimbot
CreateFeatureCard(mainPage, "Aimbot", "Auto-aim assistance", "Aimbot", "🎯", function(parent)
    CreateSettingSlider(parent, "FOV Radius", "AimbotFOV", 30, 500, 5, 1)
    CreateSettingSlider(parent, "Smoothing", "AimbotSmoothing", 1, 20, 0.5, 2)
    CreateSettingDropdown(parent, "Target Bone", "AimbotBone", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, 3)
    CreateSettingToggle(parent, "Team Check", "AimbotTeamCheck", 4)
    CreateSettingToggle(parent, "Visibility Check", "AimbotVisCheck", 5)
    CreateSettingToggle(parent, "Show FOV Circle", "AimbotShowFOV", 6)
end, 2)

-- Silent Aim
CreateFeatureCard(mainPage, "Silent Aim", "Redirect bullets to target", "SilentAim", "🔇", function(parent)
    CreateSettingSlider(parent, "FOV Radius", "SilentAimFOV", 30, 500, 5, 1)
    CreateSettingDropdown(parent, "Target Bone", "SilentAimBone", {"Head", "HumanoidRootPart", "UpperTorso"}, 2)
    CreateSettingSlider(parent, "Hit Chance (%)", "SilentAimHitChance", 1, 100, 1, 3)
    CreateSettingToggle(parent, "Team Check", "SilentAimTeamCheck", 4)
end, 3)

-- TriggerBot
CreateFeatureCard(mainPage, "TriggerBot", "Auto-fire on target", "TriggerBot", "💥", function(parent)
    CreateSettingSlider(parent, "Delay (sec)", "TriggerBotDelay", 0, 0.5, 0.01, 1)
    CreateSettingSlider(parent, "Max Range", "TriggerBotRange", 50, 500, 10, 2)
end, 4)

-- ==================== MOVEMENT TAB ====================
CreateSectionHeader(movementPage, "Movement", 1)

CreateFeatureCard(movementPage, "Speed", "Modify walk speed", "Speed", "💨", function(parent)
    CreateSettingSlider(parent, "Speed Value", "SpeedValue", 16, 100, 1, 1)
end, 2)

CreateFeatureCard(movementPage, "Fly", "Fly through the map", "Fly", "🕊️", function(parent)
    CreateSettingSlider(parent, "Fly Speed", "FlySpeed", 10, 200, 5, 1)
end, 3)

CreateFeatureCard(movementPage, "Infinite Jump", "Jump unlimited times", "InfiniteJump", "⬆️", nil, 4)

CreateFeatureCard(movementPage, "Jump Power", "Modify jump height", "JumpPower", "🦘", function(parent)
    CreateSettingSlider(parent, "Power Value", "JumpPowerValue", 10, 200, 5, 1)
end, 5)

CreateFeatureCard(movementPage, "NoClip", "Walk through walls", "NoClip", "👻", nil, 6)

CreateFeatureCard(movementPage, "Auto Sprint", "Always sprinting", "AutoSprint", "🏃", nil, 7)

-- ==================== VISUALS TAB ====================
CreateSectionHeader(visualsPage, "Player Visuals", 1)

CreateFeatureCard(visualsPage, "ESP", "See players through walls", "ESP", "👁", function(parent)
    CreateSettingToggle(parent, "Boxes", "ESPBoxes", 1)
    CreateSettingToggle(parent, "Names", "ESPNames", 2)
    CreateSettingToggle(parent, "Health Bars", "ESPHealth", 3)
    CreateSettingToggle(parent, "Distance", "ESPDistance", 4)
    CreateSettingToggle(parent, "Tracers", "ESPTracers", 5)
    CreateSettingToggle(parent, "Team Check", "ESPTeamCheck", 6)
    CreateSettingSlider(parent, "Max Distance", "ESPMaxDistance", 100, 2000, 50, 7)
end, 2)

CreateFeatureCard(visualsPage, "Chams", "Highlight player models", "Chams", "✨", function(parent)
    CreateSettingSlider(parent, "Fill Transparency", "ChamsFillTransparency", 0, 1, 0.05, 1)
    CreateSettingSlider(parent, "Outline Transparency", "ChamsOutlineTransparency", 0, 1, 0.05, 2)
    CreateSettingToggle(parent, "Team Check", "ChamsTeamCheck", 3)
end, 3)

CreateSectionHeader(visualsPage, "World Visuals", 4)

CreateFeatureCard(visualsPage, "Fullbright", "Remove darkness", "Fullbright", "☀️", nil, 5)

CreateFeatureCard(visualsPage, "Item ESP", "See items through walls", "ItemESP", "📦", function(parent)
    CreateSettingSlider(parent, "Max Distance", "ItemESPMaxDistance", 50, 1000, 25, 1)
end, 6)

-- ==================== SETTINGS TAB ====================
CreateSectionHeader(settingsPage, "Interface", 1)

CreateFeatureCard(settingsPage, "Notifications", "Show notification popups", "Notifications", "🔔", nil, 2)
CreateFeatureCard(settingsPage, "Streamer Mode", "Hide sensitive info", "StreamerMode", "📺", nil, 3)
CreateFeatureCard(settingsPage, "Anti-AFK", "Prevent AFK kick", "AntiAFK", "🛡️", nil, 4)

CreateSectionHeader(settingsPage, "Configuration", 5)

-- Manual config buttons
local function CreateActionButton(parent, text, color, callback, order)
    local btn = Create("TextButton", {
        Text = "",
        BackgroundColor3 = color or Colors.Accent,
        Size = UDim2.new(1, 0, 0, 40),
        LayoutOrder = order or 0,
        ZIndex = 13,
        AutoButtonColor = false,
        Parent = parent
    })
    AddCorner(btn, 10)
    AddGradient(btn, color, Color3.new(color.R * 0.7, color.G * 0.7, color.B * 0.7), 90)
    
    Create("TextLabel", {
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 14,
        Parent = btn
    })

    btn.MouseButton1Click:Connect(function()
        Ripple(btn)
        if callback then callback() end
    end)

    return btn
end

CreateActionButton(settingsPage, "💾 Save Config", Colors.Green, function()
    SaveConfig()
    Notify("Config", "Configuration saved successfully!", 2, "success")
end, 6)

CreateActionButton(settingsPage, "📂 Load Config", Colors.Cyan, function()
    LoadConfig()
    Notify("Config", "Configuration loaded!", 2, "info")
    -- Update all toggle visuals
    for key, state in pairs(FeatureStates) do
        if state.update then
            state.update()
        end
    end
end, 7)

CreateActionButton(settingsPage, "🔄 Reset Config", Colors.Red, function()
    ResetConfig()
    LoadConfig()
    Notify("Config", "Configuration reset to defaults!", 2, "warning")
    for key, state in pairs(FeatureStates) do
        if state.update then
            state.update()
        end
    end
end, 8)

CreateSectionHeader(settingsPage, "Credits", 9)

local creditsCard = Create("Frame", {
    BackgroundColor3 = Colors.Card,
    Size = UDim2.new(1, 0, 0, 60),
    LayoutOrder = 10,
    ZIndex = 12,
    Parent = settingsPage
})
AddCorner(creditsCard, 10)
AddStroke(creditsCard, Colors.Accent, 1, 0.7)

Create("TextLabel", {
    Text = "2ZWare v2.0",
    Font = Enum.Font.GothamBlack,
    TextSize = 16,
    TextColor3 = Colors.Accent,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 24),
    Position = UDim2.new(0, 0, 0, 8),
    ZIndex = 13,
    Parent = creditsCard
})
Create("TextLabel", {
    Text = "Vagrant Survival Edition • Made with ❤️",
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = Colors.TextMuted,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.new(0, 0, 0, 34),
    ZIndex = 13,
    Parent = creditsCard
})

-- ==================== WINDOW DRAGGING ====================
local dragging = false
local dragStart, startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ==================== SHOW/HIDE ====================

local menuOpen = Config.MenuOpen ~= false

local function ToggleMenu()
    menuOpen = not menuOpen
    Config.MenuOpen = menuOpen
    if menuOpen then
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.BackgroundTransparency = 1
        Tween(MainFrame, {Size = UDim2.new(0, 420, 0, 520), BackgroundTransparency = 0}, 0.4, Enum.EasingStyle.Back)
    else
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.3)
        task.delay(0.3, function()
            if not menuOpen then
                MainFrame.Visible = false
            end
        end)
    end
end

CloseBtn.MouseButton1Click:Connect(ToggleMenu)
ToggleButton.MouseButton1Click:Connect(function()
    if not draggingToggle then
        ToggleMenu()
    end
end)

-- Initial state
if menuOpen then
    MainFrame.Visible = true
else
    MainFrame.Visible = false
end

-- ==================== FUNCTIONAL IMPLEMENTATIONS ====================

-- ===== ESP System =====
local ESPObjects = {}

local function CreateESPForPlayer(plr)
    if plr == Player then return end
    if ESPObjects[plr] then return end

    local espData = {}
    
    -- Box
    local box = Drawing.new("Quad")
    box.Visible = false
    box.Color = Color3.fromRGB(Config.ESPColor.r, Config.ESPColor.g, Config.ESPColor.b)
    box.Thickness = 1
    box.Transparency = 1
    espData.box = box

    -- Name
    local nameTag = Drawing.new("Text")
    nameTag.Visible = false
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Size = 13
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.OutlineColor = Color3.fromRGB(0, 0, 0)
    nameTag.Font = 2
    espData.name = nameTag

    -- Health bar
    local healthBG = Drawing.new("Line")
    healthBG.Visible = false
    healthBG.Color = Color3.fromRGB(40, 40, 40)
    healthBG.Thickness = 3
    espData.healthBG = healthBG

    local healthBar = Drawing.new("Line")
    healthBar.Visible = false
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Thickness = 2
    espData.healthBar = healthBar

    -- Distance
    local distText = Drawing.new("Text")
    distText.Visible = false
    distText.Color = Colors.TextSecondary
    distText.Size = 11
    distText.Center = true
    distText.Outline = true
    distText.OutlineColor = Color3.fromRGB(0, 0, 0)
    distText.Font = 2
    espData.distance = distText

    -- Tracer
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Color3.fromRGB(Config.ESPColor.r, Config.ESPColor.g, Config.ESPColor.b)
    tracer.Thickness = 1
    tracer.Transparency = 0.6
    espData.tracer = tracer

    ESPObjects[plr] = espData
end

local function RemoveESP(plr)
    if ESPObjects[plr] then
        for _, drawing in pairs(ESPObjects[plr]) do
            pcall(function() drawing:Remove() end)
        end
        ESPObjects[plr] = nil
    end
end

local function UpdateESP()
    for plr, espData in pairs(ESPObjects) do
        local visible = false
        pcall(function()
            if Config.ESP and plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") then
                local char = plr.Character
                local hrp = char.HumanoidRootPart
                local humanoid = char.Humanoid
                
                if humanoid.Health <= 0 then
                    return
                end

                if Config.ESPTeamCheck and plr.Team and plr.Team == Player.Team then
                    return
                end

                local dist = (hrp.Position - (Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.HumanoidRootPart.Position or Camera.CFrame.Position)).Magnitude
                if dist > Config.ESPMaxDistance then return end

                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if not onScreen then return end

                visible = true
                local head = char:FindFirstChild("Head")
                local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0)) or pos
                local feetPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                local height = math.abs(headPos.Y - feetPos.Y)
                local width = height * 0.55

                -- Streamer mode
                local displayName = Config.StreamerMode and "Player" or plr.DisplayName

                -- Box
                if Config.ESPBoxes and espData.box then
                    espData.box.PointA = Vector2.new(pos.X - width/2, headPos.Y)
                    espData.box.PointB = Vector2.new(pos.X + width/2, headPos.Y)
                    espData.box.PointC = Vector2.new(pos.X + width/2, feetPos.Y)
                    espData.box.PointD = Vector2.new(pos.X - width/2, feetPos.Y)
                    espData.box.Color = Color3.fromRGB(Config.ESPColor.r, Config.ESPColor.g, Config.ESPColor.b)
                    espData.box.Visible = true
                else
                    espData.box.Visible = false
                end

                -- Name
                if Config.ESPNames and espData.name then
                    espData.name.Text = displayName
                    espData.name.Position = Vector2.new(pos.X, headPos.Y - 18)
                    espData.name.Visible = true
                else
                    espData.name.Visible = false
                end

                -- Health
                if Config.ESPHealth and espData.healthBG and espData.healthBar then
                    local healthPct = humanoid.Health / humanoid.MaxHealth
                    local barX = pos.X - width/2 - 5
                    espData.healthBG.From = Vector2.new(barX, feetPos.Y)
                    espData.healthBG.To = Vector2.new(barX, headPos.Y)
                    espData.healthBG.Visible = true
                    espData.healthBar.From = Vector2.new(barX, feetPos.Y)
                    espData.healthBar.To = Vector2.new(barX, feetPos.Y - (feetPos.Y - headPos.Y) * healthPct)
                    espData.healthBar.Color = Color3.fromRGB(255 * (1 - healthPct), 255 * healthPct, 0)
                    espData.healthBar.Visible = true
                else
                    espData.healthBG.Visible = false
                    espData.healthBar.Visible = false
                end

                -- Distance
                if Config.ESPDistance and espData.distance then
                    espData.distance.Text = math.floor(dist) .. "m"
                    espData.distance.Position = Vector2.new(pos.X, feetPos.Y + 4)
                    espData.distance.Visible = true
                else
                    espData.distance.Visible = false
                end

                -- Tracer
                if Config.ESPTracers and espData.tracer then
                    local viewportSize = Camera.ViewportSize
                    espData.tracer.From = Vector2.new(viewportSize.X / 2, viewportSize.Y)
                    espData.tracer.To = Vector2.new(pos.X, feetPos.Y)
                    espData.tracer.Color = Color3.fromRGB(Config.ESPColor.r, Config.ESPColor.g, Config.ESPColor.b)
                    espData.tracer.Visible = true
                else
                    espData.tracer.Visible = false
                end
            end
        end)

        if not visible then
            for _, drawing in pairs(espData) do
                pcall(function() drawing.Visible = false end)
            end
        end
    end
end

-- ===== Chams System =====
local ChamsObjects = {}

local function CreateChams(plr)
    if plr == Player then return end
    if ChamsObjects[plr] then return end
    
    pcall(function()
        if plr.Character then
            local highlight = Instance.new("Highlight")
            highlight.Name = "2ZWareChams"
            highlight.FillColor = Color3.fromRGB(Config.ChamsColor.r, Config.ChamsColor.g, Config.ChamsColor.b)
            highlight.FillTransparency = Config.ChamsFillTransparency
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.OutlineTransparency = Config.ChamsOutlineTransparency
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Adornee = plr.Character
            highlight.Parent = plr.Character
            ChamsObjects[plr] = highlight
        end
    end)
end

local function RemoveChams(plr)
    if ChamsObjects[plr] then
        pcall(function() ChamsObjects[plr]:Destroy() end)
        ChamsObjects[plr] = nil
    end
end

local function UpdateChams()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            if Config.Chams then
                if Config.ChamsTeamCheck and plr.Team and plr.Team == Player.Team then
                    RemoveChams(plr)
                else
                    if not ChamsObjects[plr] or not ChamsObjects[plr].Parent then
                        ChamsObjects[plr] = nil
                        CreateChams(plr)
                    else
                        pcall(function()
                            ChamsObjects[plr].FillColor = Color3.fromRGB(Config.ChamsColor.r, Config.ChamsColor.g, Config.ChamsColor.b)
                            ChamsObjects[plr].FillTransparency = Config.ChamsFillTransparency
                            ChamsObjects[plr].OutlineTransparency = Config.ChamsOutlineTransparency
                        end)
                    end
                end
            else
                RemoveChams(plr)
            end
        end
    end
end

-- ===== Item ESP =====
local ItemESPObjects = {}

local function ClearItemESP()
    for _, obj in pairs(ItemESPObjects) do
        pcall(function() obj.billboard:Destroy() end)
    end
    ItemESPObjects = {}
end

local function UpdateItemESP()
    if not Config.ItemESP then
        ClearItemESP()
        return
    end

    -- Look for common item containers in Vagrant Survival
    local itemFolders = {}
    pcall(function()
        if Workspace:FindFirstChild("Drops") then table.insert(itemFolders, Workspace.Drops) end
        if Workspace:FindFirstChild("Items") then table.insert(itemFolders, Workspace.Items) end
        if Workspace:FindFirstChild("Loot") then table.insert(itemFolders, Workspace.Loot) end
        if Workspace:FindFirstChild("DroppedItems") then table.insert(itemFolders, Workspace.DroppedItems) end
        -- Generic fallback: look for models with Tool-like children
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Folder") and (child.Name:lower():find("item") or child.Name:lower():find("drop") or child.Name:lower():find("loot")) then
                table.insert(itemFolders, child)
            end
        end
    end)

    local existingItems = {}
    for _, folder in ipairs(itemFolders) do
        pcall(function()
            for _, item in ipairs(folder:GetChildren()) do
                local pos = nil
                pcall(function()
                    if item:IsA("BasePart") then
                        pos = item.Position
                    elseif item:IsA("Model") and item.PrimaryPart then
                        pos = item.PrimaryPart.Position
                    elseif item:IsA("Model") then
                        local part = item:FindFirstChildWhichIsA("BasePart")
                        if part then pos = part.Position end
                    end
                end)

                if pos then
                    local playerPos = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.HumanoidRootPart.Position
                    if playerPos and (pos - playerPos).Magnitude <= Config.ItemESPMaxDistance then
                        existingItems[item] = true
                        if not ItemESPObjects[item] then
                            pcall(function()
                                local bb = Instance.new("BillboardGui")
                                bb.Name = "2ZWareItemESP"
                                bb.Size = UDim2.new(0, 100, 0, 30)
                                bb.StudsOffset = Vector3.new(0, 2, 0)
                                bb.AlwaysOnTop = true
                                bb.Adornee = item:IsA("BasePart") and item or (item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")))
                                bb.Parent = item

                                local label = Instance.new("TextLabel")
                                label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                label.BackgroundTransparency = 0.4
                                label.Size = UDim2.new(1, 0, 1, 0)
                                label.Font = Enum.Font.GothamBold
                                label.TextSize = 12
                                label.TextColor3 = Colors.Orange
                                label.Text = "📦 " .. item.Name
                                label.Parent = bb
                                Instance.new("UICorner", label).CornerRadius = UDim.new(0, 4)

                                ItemESPObjects[item] = {billboard = bb}
                            end)
                        end
                    end
                end
            end
        end)
    end

    -- Remove ESP for items that no longer exist
    for item, data in pairs(ItemESPObjects) do
        if not existingItems[item] or not item.Parent then
            pcall(function() data.billboard:Destroy() end)
            ItemESPObjects[item] = nil
        end
    end
end

-- ===== Fullbright =====
local OriginalLighting = {}
local fullbrightApplied = false

local function ApplyFullbright()
    if fullbrightApplied then return end
    fullbrightApplied = true
    pcall(function()
        OriginalLighting.Ambient = Lighting.Ambient
        OriginalLighting.Brightness = Lighting.Brightness
        OriginalLighting.ClockTime = Lighting.ClockTime
        OriginalLighting.FogEnd = Lighting.FogEnd
        OriginalLighting.GlobalShadows = Lighting.GlobalShadows
        OriginalLighting.OutdoorAmbient = Lighting.OutdoorAmbient

        Lighting.Ambient = Color3.fromRGB(Config.FullbrightAmbient.r, Config.FullbrightAmbient.g, Config.FullbrightAmbient.b)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    end)
end

local function RemoveFullbright()
    if not fullbrightApplied then return end
    fullbrightApplied = false
    pcall(function()
        if OriginalLighting.Ambient then Lighting.Ambient = OriginalLighting.Ambient end
        if OriginalLighting.Brightness then Lighting.Brightness = OriginalLighting.Brightness end
        if OriginalLighting.ClockTime then Lighting.ClockTime = OriginalLighting.ClockTime end
        if OriginalLighting.FogEnd then Lighting.FogEnd = OriginalLighting.FogEnd end
        if OriginalLighting.GlobalShadows ~= nil then Lighting.GlobalShadows = OriginalLighting.GlobalShadows end
        if OriginalLighting.OutdoorAmbient then Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient end
    end)
end

-- ===== Aimbot =====
local FOVCircle = nil
pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Radius = Config.AimbotFOV
    FOVCircle.Color = Colors.Accent
    FOVCircle.Thickness = 1
    FOVCircle.Filled = false
    FOVCircle.Transparency = 0.5
    FOVCircle.Visible = false
end)

local function GetClosestPlayerToMouse(fov, teamCheck, bone)
    local closest = nil
    local closestDist = fov

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if teamCheck and plr.Team and plr.Team == Player.Team then
                continue
            end

            local targetPart = plr.Character:FindFirstChild(bone or "Head") or plr.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                    if dist < closestDist then
                        -- Visibility check
                        if Config.AimbotVisCheck then
                            local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000)
                            local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {Player.Character})
                            if hit and not hit:IsDescendantOf(plr.Character) then
                                continue
                            end
                        end
                        closest = targetPart
                        closestDist = dist
                    end
                end
            end
        end
    end

    return closest
end

-- ===== Silent Aim =====
local SilentAimTarget = nil

local function GetSilentAimTarget()
    local fov = Config.SilentAimFOV
    local bone = Config.SilentAimBone
    local teamCheck = Config.SilentAimTeamCheck

    local closest = nil
    local closestDist = fov

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if teamCheck and plr.Team and plr.Team == Player.Team then
                continue
            end

            local targetPart = plr.Character:FindFirstChild(bone or "Head") or plr.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                    if dist < closestDist then
                        closest = targetPart
                        closestDist = dist
                    end
                end
            end
        end
    end

    return closest
end

-- Hook for Silent Aim
pcall(function()
    local mt = getrawmetatable(game)
    if mt then
        local oldNamecall = mt.__namecall
        local oldIndex = mt.__index
        
        if setreadonly then setreadonly(mt, false) end
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if Config.SilentAim and (method == "FireServer" or method == "InvokeServer") then
                local target = GetSilentAimTarget()
                if target then
                    if math.random(1, 100) <= Config.SilentAimHitChance then
                        -- Try to redirect aim
                        for i, arg in ipairs(args) do
                            if typeof(arg) == "Vector3" then
                                args[i] = target.Position
                            elseif typeof(arg) == "CFrame" then
                                args[i] = CFrame.new(target.Position)
                            end
                        end
                    end
                end
            end

            return oldNamecall(self, unpack(args))
        end)

        if setreadonly then setreadonly(mt, true) end
    end
end)

-- ===== Movement Features =====
local flyActive = false
local flyBV, flyBG

local function StartFly()
    if flyActive then return end
    flyActive = true
    pcall(function()
        local char = Player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
        end

        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.new(0, 0, 0)
        flyBV.Parent = hrp

        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBG.P = 9e4
        flyBG.Parent = hrp
    end)
end

local function StopFly()
    if not flyActive then return end
    flyActive = false
    pcall(function()
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyBG then flyBG:Destroy() flyBG = nil end
        local char = Player.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end)
end

-- ===== Anti-AFK =====
pcall(function()
    local VirtualUser = game:GetService("VirtualUser")
    Player.Idled:Connect(function()
        if Config.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end)

-- ==================== PLAYER CONNECTIONS ====================
Players.PlayerAdded:Connect(function(plr)
    if Config.ESP then
        pcall(function() CreateESPForPlayer(plr) end)
    end
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if Config.Chams then
            RemoveChams(plr)
            CreateChams(plr)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    RemoveESP(plr)
    RemoveChams(plr)
end)

-- Init ESP for existing players
for _, plr in ipairs(Players:GetPlayers()) do
    pcall(function() CreateESPForPlayer(plr) end)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if Config.Chams then
            RemoveChams(plr)
            CreateChams(plr)
        end
    end)
end

-- ==================== MAIN LOOP ====================
local lastInfJump = 0

RunService.RenderStepped:Connect(function(dt)
    -- Auto-save timer
    autoSaveTimer = autoSaveTimer + dt
    if autoSaveTimer >= 30 then
        autoSaveTimer = 0
        pcall(SaveConfig)
    end

    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

    -- Aimbot
    if Config.Aimbot then
        local target = GetClosestPlayerToMouse(Config.AimbotFOV, Config.AimbotTeamCheck, Config.AimbotBone)
        if target then
            local targetPos = target.Position
            local smoothing = Config.AimbotSmoothing
            local currentCF = Camera.CFrame
            local targetCF = CFrame.new(currentCF.Position, targetPos)
            Camera.CFrame = currentCF:Lerp(targetCF, 1 / smoothing)
        end
    end

    -- FOV Circle
    pcall(function()
        if FOVCircle then
            FOVCircle.Visible = Config.Aimbot and Config.AimbotShowFOV
            if FOVCircle.Visible then
                FOVCircle.Radius = Config.AimbotFOV
                local vps = Camera.ViewportSize
                FOVCircle.Position = Vector2.new(vps.X / 2, vps.Y / 2)
            end
        end
    end)

    -- ESP Update
    pcall(UpdateESP)

    -- Chams
    pcall(UpdateChams)

    -- Fullbright
    if Config.Fullbright then
        ApplyFullbright()
    else
        RemoveFullbright()
    end

    -- Speed
    if Config.Speed and humanoid then
        pcall(function()
            humanoid.WalkSpeed = Config.SpeedValue
        end)
    end

    -- Jump Power
    if Config.JumpPower and humanoid then
        pcall(function()
            humanoid.JumpPower = Config.JumpPowerValue
            humanoid.UseJumpPower = true
        end)
    end

    -- NoClip
    if Config.NoClip and char then
        pcall(function()
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end

    -- Fly
    if Config.Fly then
        if not flyActive then StartFly() end
        pcall(function()
            if flyBV and flyBG and hrp then
                local speed = Config.FlySpeed
                local direction = Vector3.new(0, 0, 0)
                
                -- Use camera look direction for fly
                local camCF = Camera.CFrame
                local moveDir = humanoid and humanoid.MoveDirection or Vector3.new()
                
                if moveDir.Magnitude > 0 then
                    direction = camCF.LookVector * moveDir.Z + camCF.RightVector * moveDir.X
                    if direction.Magnitude > 0 then
                        direction = direction.Unit
                    end
                end

                -- Check if jumping (going up) or not
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    direction = direction + Vector3.new(0, 0.5, 0)
                end

                flyBV.Velocity = direction * speed
                flyBG.CFrame = camCF
            end
        end)
    else
        if flyActive then StopFly() end
    end

    -- Auto Sprint
    if Config.AutoSprint and humanoid then
        pcall(function()
            if humanoid.MoveDirection.Magnitude > 0 then
                humanoid.WalkSpeed = math.max(humanoid.WalkSpeed, Config.Speed and Config.SpeedValue or 24)
            end
        end)
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        pcall(function()
            local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

-- Item ESP update loop
task.spawn(function()
    while ScreenGui.Parent do
        pcall(UpdateItemESP)
        task.wait(2)
    end
end)

-- TriggerBot
task.spawn(function()
    while ScreenGui.Parent do
        if Config.TriggerBot then
            pcall(function()
                local target = Mouse.Target
                if target then
                    local plr = Players:GetPlayerFromCharacter(target.Parent) or Players:GetPlayerFromCharacter(target.Parent and target.Parent.Parent)
                    if plr and plr ~= Player then
                        local dist = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and (Player.Character.HumanoidRootPart.Position - target.Position).Magnitude or 9999
                        if dist <= Config.TriggerBotRange then
                            -- Simulate click
                            mouse1click()
                        end
                    end
                end
            end)
            task.wait(Config.TriggerBotDelay)
        else
            task.wait(0.1)
        end
    end
end)

-- ==================== CHARACTER RESPAWN HANDLING ====================
Player.CharacterAdded:Connect(function(char)
    task.wait(1)
    if flyActive then
        StopFly()
        if Config.Fly then
            task.wait(0.5)
            StartFly()
        end
    end
end)

-- ==================== KEYBOARD TOGGLE (optional for PC) ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert then
        ToggleMenu()
    end
end)

-- ==================== STARTUP ====================
task.delay(1, function()
    Notify("2ZWare", "Successfully loaded! Vagrant Survival", 3, "success")
end)

-- Opening animation
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.BackgroundTransparency = 1
task.wait(0.3)
if menuOpen then
    Tween(MainFrame, {Size = UDim2.new(0, 420, 0, 520), BackgroundTransparency = 0}, 0.5, Enum.EasingStyle.Back)
end

-- Logo animation
task.spawn(function()
    while ScreenGui.Parent do
        Tween(LogoWare, {TextColor3 = Colors.Cyan}, 2, Enum.EasingStyle.Sine)
        task.wait(2)
        Tween(LogoWare, {TextColor3 = Colors.Accent}, 2, Enum.EasingStyle.Sine)
        task.wait(2)
    end
end)

print("[2ZWare] Loaded successfully - Vagrant Survival Edition v2.0")
