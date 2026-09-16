-- 2ZWare | Vagrant Survival | Full Script
-- Single LocalScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- ═══════════════════════════════════════════
-- CONFIG SYSTEM
-- ═══════════════════════════════════════════
local DefaultConfig = {
    -- Main
    Aimbot = false,
    AimbotFOV = 150,
    AimbotSmooth = 5,
    AimbotBone = "Head",
    AimbotTeamCheck = true,
    AimbotVisCheck = true,
    AimbotShowFOV = true,
    AimbotKey = "MouseButton2",
    
    AutoAttack = false,
    AutoAttackRange = 15,
    AutoAttackDelay = 0.2,
    
    KillAura = false,
    KillAuraRange = 12,
    KillAuraDelay = 0.15,
    
    SilentAim = false,
    SilentAimFOV = 200,
    SilentAimBone = "Head",
    
    AutoPickup = false,
    AutoPickupRange = 30,
    AutoPickupDelay = 0.3,
    
    AutoHeal = false,
    AutoHealPercent = 50,
    
    -- Movement
    Speed = false,
    SpeedValue = 24,
    Fly = false,
    FlySpeed = 50,
    InfiniteJump = false,
    NoClip = false,
    Teleport = false,
    AutoSprint = false,
    BunnyHop = false,
    BunnyHopPower = 60,
    
    -- Visuals
    ESP = false,
    ESPBox = true,
    ESPName = true,
    ESPHealth = true,
    ESPDistance = true,
    ESPTracers = false,
    ESPTeamCheck = true,
    ESPMaxDistance = 500,
    ESPColor = {255, 0, 85},
    
    Chams = false,
    ChamsColor = {255, 0, 85},
    ChamsFillTransparency = 0.5,
    ChamsOutlineTransparency = 0,
    
    ItemESP = false,
    ItemESPMaxDistance = 200,
    
    Fullbright = false,
    NoFog = false,
    CrosshairEnabled = false,
    CrosshairSize = 6,
    CrosshairColor = {255, 255, 255},
    CrosshairThickness = 2,
    
    -- Settings
    ToggleKey = "RightShift",
    GUITheme = "Dark",
    Notifications = true,
    AutoSave = true,
    StreamerMode = false,
}

local Config = {}
for k, v in pairs(DefaultConfig) do
    if type(v) == "table" then
        Config[k] = {}
        for i, j in pairs(v) do Config[k][i] = j end
    else
        Config[k] = v
    end
end

local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local r = {}
    for k, v in pairs(t) do r[k] = DeepCopy(v) end
    return r
end

local SAVE_KEY = "2ZWare_VagrantSurvival_Config"

local function SaveConfig()
    pcall(function()
        if writefile then
            writefile(SAVE_KEY .. ".json", HttpService:JSONEncode(Config))
        end
    end)
end

local function LoadConfig()
    pcall(function()
        if readfile and isfile and isfile(SAVE_KEY .. ".json") then
            local data = HttpService:JSONDecode(readfile(SAVE_KEY .. ".json"))
            for k, v in pairs(data) do
                Config[k] = v
            end
        end
    end)
end

local function ResetConfig()
    for k, v in pairs(DefaultConfig) do
        if type(v) == "table" then
            Config[k] = {}
            for i, j in pairs(v) do Config[k][i] = j end
        else
            Config[k] = v
        end
    end
    SaveConfig()
end

LoadConfig()

-- ═══════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════
local function Notify(title, text, duration)
    if not Config.Notifications then return end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "2ZWare",
            Text = text or "",
            Duration = duration or 3,
        })
    end)
end

local function GetCharacter(plr)
    return plr and plr.Character
end

local function GetHumanoid(plr)
    local char = GetCharacter(plr)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart(plr)
    local char = GetCharacter(plr)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function IsAlive(plr)
    local hum = GetHumanoid(plr)
    return hum and hum.Health > 0
end

local function GetBone(char, boneName)
    if not char then return nil end
    return char:FindFirstChild(boneName) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function IsTeammate(plr)
    if not Player.Team or not plr.Team then return false end
    return Player.Team == plr.Team
end

local function IsVisible(part)
    if not part then return false end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin)
    local ray = Ray.new(origin, direction)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {Player.Character, Camera})
    return hit == nil or hit:IsDescendantOf(part.Parent)
end

local function WorldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToScreenPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

-- ═══════════════════════════════════════════
-- DESTROY OLD GUI
-- ═══════════════════════════════════════════
if Player.PlayerGui:FindFirstChild("2ZWare") then
    Player.PlayerGui:FindFirstChild("2ZWare"):Destroy()
end

-- ═══════════════════════════════════════════
-- COLOR PALETTE
-- ═══════════════════════════════════════════
local Theme = {
    Background = Color3.fromRGB(12, 12, 18),
    Surface = Color3.fromRGB(18, 18, 28),
    Card = Color3.fromRGB(22, 22, 35),
    CardHover = Color3.fromRGB(28, 28, 42),
    Accent = Color3.fromRGB(255, 0, 85),
    AccentDark = Color3.fromRGB(180, 0, 60),
    AccentGlow = Color3.fromRGB(255, 50, 120),
    Text = Color3.fromRGB(240, 240, 245),
    TextDim = Color3.fromRGB(140, 140, 160),
    TextMuted = Color3.fromRGB(80, 80, 100),
    Border = Color3.fromRGB(40, 40, 60),
    Toggle_On = Color3.fromRGB(255, 0, 85),
    Toggle_Off = Color3.fromRGB(50, 50, 70),
    SliderBg = Color3.fromRGB(35, 35, 55),
    SliderFill = Color3.fromRGB(255, 0, 85),
    Green = Color3.fromRGB(0, 200, 120),
    Red = Color3.fromRGB(255, 60, 60),
    Yellow = Color3.fromRGB(255, 200, 50),
    Blue = Color3.fromRGB(60, 130, 255),
    DropdownBg = Color3.fromRGB(15, 15, 25),
    Shadow = Color3.fromRGB(0, 0, 0),
    GearIcon = Color3.fromRGB(100, 100, 130),
}

-- ═══════════════════════════════════════════
-- GUI CREATION
-- ═══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "2ZWare"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = Player.PlayerGui

-- Toggle Button (Mobile)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleBtn"
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0, 15, 0.5, -25)
ToggleButton.BackgroundColor3 = Theme.Accent
ToggleButton.Text = "⚡"
ToggleButton.TextSize = 22
ToggleButton.TextColor3 = Color3.new(1,1,1)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.ZIndex = 100
ToggleButton.Parent = ScreenGui
ToggleButton.Active = true
ToggleButton.Draggable = true

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(1, 0)
toggleCorner.Parent = ToggleButton

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Theme.AccentGlow
toggleStroke.Thickness = 2
toggleStroke.Transparency = 0.3
toggleStroke.Parent = ToggleButton

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 520)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -260)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 10
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Theme.Border
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.3
mainStroke.Parent = MainFrame

-- Glow effect behind frame
local GlowFrame = Instance.new("ImageLabel")
GlowFrame.Name = "Glow"
GlowFrame.Size = UDim2.new(1, 60, 1, 60)
GlowFrame.Position = UDim2.new(0, -30, 0, -30)
GlowFrame.BackgroundTransparency = 1
GlowFrame.Image = "rbxassetid://5028857084"
GlowFrame.ImageColor3 = Theme.Accent
GlowFrame.ImageTransparency = 0.88
GlowFrame.ZIndex = 9
GlowFrame.Parent = MainFrame

-- ═══════════════════════════════════════════
-- HEADER
-- ═══════════════════════════════════════════
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 55)
Header.BackgroundColor3 = Theme.Surface
Header.BorderSizePixel = 0
Header.ZIndex = 12
Header.Parent = MainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = Header

-- Fix bottom corners
local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 16)
headerFix.Position = UDim2.new(0, 0, 1, -16)
headerFix.BackgroundColor3 = Theme.Surface
headerFix.BorderSizePixel = 0
headerFix.ZIndex = 12
headerFix.Parent = Header

-- Accent line under header
local AccentLine = Instance.new("Frame")
AccentLine.Size = UDim2.new(1, 0, 0, 2)
AccentLine.Position = UDim2.new(0, 0, 1, -2)
AccentLine.BackgroundColor3 = Theme.Accent
AccentLine.BorderSizePixel = 0
AccentLine.ZIndex = 13
AccentLine.Parent = Header

local accentGradient = Instance.new("UIGradient")
accentGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Theme.AccentGlow),
    ColorSequenceKeypoint.new(0.5, Theme.Accent),
    ColorSequenceKeypoint.new(1, Theme.AccentDark),
}
accentGradient.Parent = AccentLine

-- Logo
local Logo = Instance.new("TextLabel")
Logo.Name = "Logo"
Logo.Size = UDim2.new(0, 160, 1, 0)
Logo.Position = UDim2.new(0, 16, 0, 0)
Logo.BackgroundTransparency = 1
Logo.Text = "⚡ 2ZWare"
Logo.TextColor3 = Theme.Text
Logo.TextSize = 20
Logo.Font = Enum.Font.GothamBold
Logo.TextXAlignment = Enum.TextXAlignment.Left
Logo.ZIndex = 14
Logo.Parent = Header

local SubLabel = Instance.new("TextLabel")
SubLabel.Size = UDim2.new(0, 120, 0, 14)
SubLabel.Position = UDim2.new(0, 40, 0, 36)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = "Vagrant Survival"
SubLabel.TextColor3 = Theme.Accent
SubLabel.TextSize = 10
SubLabel.Font = Enum.Font.GothamMedium
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.ZIndex = 14
SubLabel.Parent = Header

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -45, 0, 10)
CloseBtn.BackgroundColor3 = Theme.Card
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Theme.TextDim
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.ZIndex = 14
CloseBtn.Parent = Header

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = CloseBtn

-- ═══════════════════════════════════════════
-- TAB BAR
-- ═══════════════════════════════════════════
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -20, 0, 38)
TabBar.Position = UDim2.new(0, 10, 0, 60)
TabBar.BackgroundColor3 = Theme.Surface
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 12
TabBar.Parent = MainFrame

local tabBarCorner = Instance.new("UICorner")
tabBarCorner.CornerRadius = UDim.new(0, 10)
tabBarCorner.Parent = TabBar

local TabBarLayout = Instance.new("UIListLayout")
TabBarLayout.FillDirection = Enum.FillDirection.Horizontal
TabBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabBarLayout.Padding = UDim.new(0, 4)
TabBarLayout.Parent = TabBar

local TabBarPadding = Instance.new("UIPadding")
TabBarPadding.PaddingLeft = UDim.new(0, 4)
TabBarPadding.PaddingRight = UDim.new(0, 4)
TabBarPadding.PaddingTop = UDim.new(0, 4)
TabBarPadding.PaddingBottom = UDim.new(0, 4)
TabBarPadding.Parent = TabBar

-- Tab indicator (animated underline)
local TabIndicator = Instance.new("Frame")
TabIndicator.Name = "Indicator"
TabIndicator.Size = UDim2.new(0, 80, 0, 3)
TabIndicator.Position = UDim2.new(0, 0, 1, -3)
TabIndicator.BackgroundColor3 = Theme.Accent
TabIndicator.BorderSizePixel = 0
TabIndicator.ZIndex = 14
TabIndicator.Parent = TabBar

local indicatorCorner = Instance.new("UICorner")
indicatorCorner.CornerRadius = UDim.new(1, 0)
indicatorCorner.Parent = TabIndicator

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -20, 1, -110)
ContentArea.Position = UDim2.new(0, 10, 0, 102)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.ZIndex = 11
ContentArea.ClipsDescendants = true
ContentArea.Parent = MainFrame

-- Settings panel (opens on gear click)
local SettingsPanel = Instance.new("Frame")
SettingsPanel.Name = "SettingsPanel"
SettingsPanel.Size = UDim2.new(1, 0, 1, 0)
SettingsPanel.Position = UDim2.new(1, 0, 0, 0)
SettingsPanel.BackgroundColor3 = Theme.Background
SettingsPanel.BorderSizePixel = 0
SettingsPanel.ZIndex = 20
SettingsPanel.ClipsDescendants = true
SettingsPanel.Visible = false
SettingsPanel.Parent = ContentArea

local spCorner = Instance.new("UICorner")
spCorner.CornerRadius = UDim.new(0, 12)
spCorner.Parent = SettingsPanel

local SettingsPanelTitle = Instance.new("TextLabel")
SettingsPanelTitle.Name = "Title"
SettingsPanelTitle.Size = UDim2.new(1, -50, 0, 35)
SettingsPanelTitle.Position = UDim2.new(0, 12, 0, 5)
SettingsPanelTitle.BackgroundTransparency = 1
SettingsPanelTitle.Text = "Settings"
SettingsPanelTitle.TextColor3 = Theme.Text
SettingsPanelTitle.TextSize = 15
SettingsPanelTitle.Font = Enum.Font.GothamBold
SettingsPanelTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingsPanelTitle.ZIndex = 22
SettingsPanelTitle.Parent = SettingsPanel

local SettingsBackBtn = Instance.new("TextButton")
SettingsBackBtn.Name = "BackBtn"
SettingsBackBtn.Size = UDim2.new(0, 30, 0, 30)
SettingsBackBtn.Position = UDim2.new(1, -38, 0, 7)
SettingsBackBtn.BackgroundColor3 = Theme.Card
SettingsBackBtn.Text = "←"
SettingsBackBtn.TextColor3 = Theme.TextDim
SettingsBackBtn.TextSize = 16
SettingsBackBtn.Font = Enum.Font.GothamBold
SettingsBackBtn.ZIndex = 22
SettingsBackBtn.Parent = SettingsPanel

local sbbCorner = Instance.new("UICorner")
sbbCorner.CornerRadius = UDim.new(0, 8)
sbbCorner.Parent = SettingsBackBtn

local SettingsScroll = Instance.new("ScrollingFrame")
SettingsScroll.Name = "Scroll"
SettingsScroll.Size = UDim2.new(1, -10, 1, -45)
SettingsScroll.Position = UDim2.new(0, 5, 0, 40)
SettingsScroll.BackgroundTransparency = 1
SettingsScroll.BorderSizePixel = 0
SettingsScroll.ScrollBarThickness = 3
SettingsScroll.ScrollBarImageColor3 = Theme.Accent
SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SettingsScroll.ZIndex = 22
SettingsScroll.Parent = SettingsPanel

local ssLayout = Instance.new("UIListLayout")
ssLayout.Padding = UDim.new(0, 6)
ssLayout.Parent = SettingsScroll

local ssPadding = Instance.new("UIPadding")
ssPadding.PaddingTop = UDim.new(0, 4)
ssPadding.PaddingLeft = UDim.new(0, 4)
ssPadding.PaddingRight = UDim.new(0, 4)
ssPadding.Parent = SettingsScroll

local settingsPanelOpen = false

local function CloseSettingsPanel()
    if not settingsPanelOpen then return end
    settingsPanelOpen = false
    local tween = TweenService:Create(SettingsPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, 0, 0, 0)})
    tween:Play()
    tween.Completed:Connect(function()
        SettingsPanel.Visible = false
    end)
end

local function OpenSettingsPanel(title, buildFunc)
    -- Clear old
    for _, c in pairs(SettingsScroll:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
            c:Destroy()
        end
    end
    SettingsPanelTitle.Text = "⚙ " .. title
    if buildFunc then buildFunc(SettingsScroll) end
    
    -- Auto canvas size
    task.defer(function()
        task.wait(0.05)
        local layout = SettingsScroll:FindFirstChildOfClass("UIListLayout")
        if layout then
            SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end
    end)
    
    SettingsPanel.Visible = true
    SettingsPanel.Position = UDim2.new(1, 0, 0, 0)
    settingsPanelOpen = true
    TweenService:Create(SettingsPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
end

SettingsBackBtn.MouseButton1Click:Connect(CloseSettingsPanel)

-- ═══════════════════════════════════════════
-- UI COMPONENT BUILDERS
-- ═══════════════════════════════════════════

-- Create Toggle
local function CreateToggle(parent, text, configKey, onChange, hasGear, gearFunc)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.BackgroundColor3 = Theme.Card
    frame.BorderSizePixel = 0
    frame.ZIndex = parent.ZIndex + 1
    frame.Parent = parent
    
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 10)
    fc.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = frame.ZIndex + 1
    label.Parent = frame
    
    -- Toggle switch
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 42, 0, 22)
    toggleBg.Position = UDim2.new(1, hasGear and -90 or -56, 0.5, -11)
    toggleBg.BackgroundColor3 = Config[configKey] and Theme.Toggle_On or Theme.Toggle_Off
    toggleBg.BorderSizePixel = 0
    toggleBg.ZIndex = frame.ZIndex + 1
    toggleBg.Parent = frame
    
    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(1, 0)
    tbCorner.Parent = toggleBg
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.Position = Config[configKey] and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    toggleCircle.BackgroundColor3 = Color3.new(1,1,1)
    toggleCircle.BorderSizePixel = 0
    toggleCircle.ZIndex = frame.ZIndex + 2
    toggleCircle.Parent = toggleBg
    
    local tcCorner = Instance.new("UICorner")
    tcCorner.CornerRadius = UDim.new(1, 0)
    tcCorner.Parent = toggleCircle
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.ZIndex = frame.ZIndex + 3
    toggleBtn.Parent = toggleBg
    
    local function UpdateVisual()
        local on = Config[configKey]
        TweenService:Create(toggleBg, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {BackgroundColor3 = on and Theme.Toggle_On or Theme.Toggle_Off}):Play()
        TweenService:Create(toggleCircle, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Position = on and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}):Play()
    end
    
    toggleBtn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        UpdateVisual()
        if onChange then onChange(Config[configKey]) end
        if Config.AutoSave then SaveConfig() end
    end)
    
    -- Gear button
    if hasGear and gearFunc then
        local gear = Instance.new("TextButton")
        gear.Size = UDim2.new(0, 30, 0, 30)
        gear.Position = UDim2.new(1, -40, 0.5, -15)
        gear.BackgroundColor3 = Theme.CardHover
        gear.Text = "⚙"
        gear.TextColor3 = Theme.GearIcon
        gear.TextSize = 15
        gear.Font = Enum.Font.GothamBold
        gear.ZIndex = frame.ZIndex + 3
        gear.Parent = frame
        
        local gCorner = Instance.new("UICorner")
        gCorner.CornerRadius = UDim.new(0, 8)
        gCorner.Parent = gear
        
        gear.MouseButton1Click:Connect(function()
            OpenSettingsPanel(text, gearFunc)
        end)
    end
    
    return frame, function() UpdateVisual() end
end

-- Create Slider (for settings panel)
local function CreateSlider(parent, text, configKey, min, max, step, onChange)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 55)
    frame.BackgroundColor3 = Theme.Card
    frame.BorderSizePixel = 0
    frame.ZIndex = parent.ZIndex + 1
    frame.Parent = parent
    
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 10)
    fc.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 20)
    label.Position = UDim2.new(0, 12, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = frame.ZIndex + 1
    label.Parent = frame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.35, 0, 0, 20)
    valueLabel.Position = UDim2.new(0.6, 0, 0, 4)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(Config[configKey])
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.TextSize = 12
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = frame.ZIndex + 1
    valueLabel.Parent = frame
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -24, 0, 8)
    sliderBg.Position = UDim2.new(0, 12, 0, 32)
    sliderBg.BackgroundColor3 = Theme.SliderBg
    sliderBg.BorderSizePixel = 0
    sliderBg.ZIndex = frame.ZIndex + 1
    sliderBg.Parent = frame
    
    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(1, 0)
    sbCorner.Parent = sliderBg
    
    local pct = math.clamp((Config[configKey] - min) / (max - min), 0, 1)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(pct, 0, 1, 0)
    sliderFill.BackgroundColor3 = Theme.SliderFill
    sliderFill.BorderSizePixel = 0
    sliderFill.ZIndex = frame.ZIndex + 2
    sliderFill.Parent = sliderBg
    
    local sfCorner = Instance.new("UICorner")
    sfCorner.CornerRadius = UDim.new(1, 0)
    sfCorner.Parent = sliderFill
    
    -- Knob
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(pct, -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.ZIndex = frame.ZIndex + 3
    knob.Parent = sliderBg
    
    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob
    
    local dragging = false
    
    local inputBtn = Instance.new("TextButton")
    inputBtn.Size = UDim2.new(1, 0, 0, 24)
    inputBtn.Position = UDim2.new(0, 0, 0, 26)
    inputBtn.BackgroundTransparency = 1
    inputBtn.Text = ""
    inputBtn.ZIndex = frame.ZIndex + 4
    inputBtn.Parent = frame
    
    local function Update(input)
        local absPos = sliderBg.AbsolutePosition.X
        local absSize = sliderBg.AbsoluteSize.X
        local mouseX = input.Position.X
        local newPct = math.clamp((mouseX - absPos) / absSize, 0, 1)
        
        local rawValue = min + (max - min) * newPct
        if step then
            rawValue = math.floor(rawValue / step + 0.5) * step
        end
        rawValue = math.clamp(rawValue, min, max)
        
        Config[configKey] = rawValue
        local displayPct = (rawValue - min) / (max - min)
        
        sliderFill.Size = UDim2.new(displayPct, 0, 1, 0)
        knob.Position = UDim2.new(displayPct, -8, 0.5, -8)
        valueLabel.Text = tostring(math.floor(rawValue * 100) / 100)
        
        if onChange then onChange(rawValue) end
        if Config.AutoSave then SaveConfig() end
    end
    
    inputBtn.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    inputBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Update(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            Update(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    inputBtn.MouseButton1Click:Connect(function()
        -- Also handle single click
    end)
    
    return frame
end

-- Create Dropdown (for settings panel)
local function CreateDropdown(parent, text, configKey, options, onChange)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.BackgroundColor3 = Theme.Card
    frame.BorderSizePixel = 0
    frame.ZIndex = parent.ZIndex + 1
    frame.ClipsDescendants = false
    frame.Parent = parent
    
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 10)
    fc.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = frame.ZIndex + 1
    label.Parent = frame
    
    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0.42, 0, 0, 28)
    dropBtn.Position = UDim2.new(0.55, 0, 0.5, -14)
    dropBtn.BackgroundColor3 = Theme.CardHover
    dropBtn.Text = tostring(Config[configKey]) .. " ▾"
    dropBtn.TextColor3 = Theme.Accent
    dropBtn.TextSize = 11
    dropBtn.Font = Enum.Font.GothamMedium
    dropBtn.ZIndex = frame.ZIndex + 2
    dropBtn.ClipsDescendants = false
    dropBtn.Parent = frame
    
    local dbCorner = Instance.new("UICorner")
    dbCorner.CornerRadius = UDim.new(0, 8)
    dbCorner.Parent = dropBtn
    
    local dropMenu = Instance.new("Frame")
    dropMenu.Size = UDim2.new(1, 0, 0, #options * 28 + 8)
    dropMenu.Position = UDim2.new(0, 0, 1, 4)
    dropMenu.BackgroundColor3 = Theme.DropdownBg
    dropMenu.BorderSizePixel = 0
    dropMenu.ZIndex = 50
    dropMenu.Visible = false
    dropMenu.ClipsDescendants = true
    dropMenu.Parent = dropBtn
    
    local dmCorner = Instance.new("UICorner")
    dmCorner.CornerRadius = UDim.new(0, 8)
    dmCorner.Parent = dropMenu
    
    local dmStroke = Instance.new("UIStroke")
    dmStroke.Color = Theme.Border
    dmStroke.Thickness = 1
    dmStroke.Parent = dropMenu
    
    local dmLayout = Instance.new("UIListLayout")
    dmLayout.Padding = UDim.new(0, 2)
    dmLayout.Parent = dropMenu
    
    local dmPad = Instance.new("UIPadding")
    dmPad.PaddingTop = UDim.new(0, 4)
    dmPad.PaddingLeft = UDim.new(0, 4)
    dmPad.PaddingRight = UDim.new(0, 4)
    dmPad.Parent = dropMenu
    
    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 26)
        optBtn.BackgroundColor3 = (Config[configKey] == opt) and Theme.Accent or Theme.Card
        optBtn.BackgroundTransparency = (Config[configKey] == opt) and 0.3 or 0
        optBtn.Text = tostring(opt)
        optBtn.TextColor3 = Theme.Text
        optBtn.TextSize = 11
        optBtn.Font = Enum.Font.GothamMedium
        optBtn.ZIndex = 52
        optBtn.Parent = dropMenu
        
        local oCorner = Instance.new("UICorner")
        oCorner.CornerRadius = UDim.new(0, 6)
        oCorner.Parent = optBtn
        
        optBtn.MouseButton1Click:Connect(function()
            Config[configKey] = opt
            dropBtn.Text = tostring(opt) .. " ▾"
            dropMenu.Visible = false
            if onChange then onChange(opt) end
            if Config.AutoSave then SaveConfig() end
            
            -- Update highlight
            for _, child in pairs(dropMenu:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = (child.Text == tostring(opt)) and Theme.Accent or Theme.Card
                    child.BackgroundTransparency = (child.Text == tostring(opt)) and 0.3 or 0
                end
            end
        end)
    end
    
    dropBtn.MouseButton1Click:Connect(function()
        dropMenu.Visible = not dropMenu.Visible
    end)
    
    return frame
end

-- Create Section Label
local function CreateSection(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 24)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.TextMuted
    label.TextSize = 10
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = parent.ZIndex + 1
    label.Parent = parent
    return label
end

-- Create Button (for settings panel)
local function CreateButton(parent, text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = color or Theme.Accent
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = parent.ZIndex + 1
    btn.Parent = parent
    
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 10)
    bc.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    return btn
end

-- Create Toggle for settings panel
local function CreateSettingsToggle(parent, text, configKey, onChange)
    CreateToggle(parent, text, configKey, onChange, false, nil)
end

-- ═══════════════════════════════════════════
-- TAB SYSTEM
-- ═══════════════════════════════════════════
local Tabs = {}
local TabButtons = {}
local ActiveTab = nil

local tabData = {
    {Name = "Main", Icon = "⚔"},
    {Name = "Movement", Icon = "🏃"},
    {Name = "Visuals", Icon = "👁"},
    {Name = "Settings", Icon = "⚙"},
}

for i, data in ipairs(tabData) do
    -- Tab button
    local btn = Instance.new("TextButton")
    btn.Name = data.Name
    btn.Size = UDim2.new(0.24, -3, 1, 0)
    btn.BackgroundColor3 = Theme.Card
    btn.BackgroundTransparency = 0.5
    btn.Text = data.Icon .. " " .. data.Name
    btn.TextColor3 = Theme.TextDim
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamMedium
    btn.ZIndex = 13
    btn.LayoutOrder = i
    btn.Parent = TabBar
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    -- Tab content page
    local page = Instance.new("ScrollingFrame")
    page.Name = data.Name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.ZIndex = 12
    page.Parent = ContentArea
    
    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 6)
    pageLayout.Parent = page
    
    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingTop = UDim.new(0, 4)
    pagePad.PaddingLeft = UDim.new(0, 2)
    pagePad.PaddingRight = UDim.new(0, 2)
    pagePad.PaddingBottom = UDim.new(0, 10)
    pagePad.Parent = page
    
    -- Auto canvas size
    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 20)
    end)
    
    Tabs[data.Name] = page
    TabButtons[data.Name] = btn
    
    btn.MouseButton1Click:Connect(function()
        CloseSettingsPanel()
        -- Switch tab
        for name, p in pairs(Tabs) do
            p.Visible = (name == data.Name)
        end
        for name, b in pairs(TabButtons) do
            TweenService:Create(b, TweenInfo.new(0.2), {
                TextColor3 = (name == data.Name) and Theme.Text or Theme.TextDim,
                BackgroundTransparency = (name == data.Name) and 0 or 0.5,
                BackgroundColor3 = (name == data.Name) and Theme.CardHover or Theme.Card,
            }):Play()
        end
        ActiveTab = data.Name
    end)
end

-- Default tab
TabButtons["Main"].TextColor3 = Theme.Text
TabButtons["Main"].BackgroundTransparency = 0
TabButtons["Main"].BackgroundColor3 = Theme.CardHover
Tabs["Main"].Visible = true
ActiveTab = "Main"

-- ═══════════════════════════════════════════
-- POPULATE: MAIN TAB
-- ═══════════════════════════════════════════
local MainPage = Tabs["Main"]

CreateSection(MainPage, "COMBAT")

CreateToggle(MainPage, "Aimbot", "Aimbot", nil, true, function(scroll)
    CreateSlider(scroll, "FOV Radius", "AimbotFOV", 30, 500, 5)
    CreateSlider(scroll, "Smoothness", "AimbotSmooth", 1, 20, 0.5)
    CreateDropdown(scroll, "Target Bone", "AimbotBone", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"})
    CreateSettingsToggle(scroll, "Team Check", "AimbotTeamCheck")
    CreateSettingsToggle(scroll, "Visibility Check", "AimbotVisCheck")
    CreateSettingsToggle(scroll, "Show FOV Circle", "AimbotShowFOV")
end)

CreateToggle(MainPage, "Silent Aim", "SilentAim", nil, true, function(scroll)
    CreateSlider(scroll, "FOV Radius", "SilentAimFOV", 30, 600, 10)
    CreateDropdown(scroll, "Target Bone", "SilentAimBone", {"Head", "HumanoidRootPart", "UpperTorso"})
end)

CreateToggle(MainPage, "Kill Aura", "KillAura", nil, true, function(scroll)
    CreateSlider(scroll, "Range", "KillAuraRange", 5, 30, 1)
    CreateSlider(scroll, "Delay (sec)", "KillAuraDelay", 0.05, 1, 0.05)
end)

CreateToggle(MainPage, "Auto Attack", "AutoAttack", nil, true, function(scroll)
    CreateSlider(scroll, "Range", "AutoAttackRange", 5, 30, 1)
    CreateSlider(scroll, "Delay (sec)", "AutoAttackDelay", 0.05, 1, 0.05)
end)

CreateSection(MainPage, "UTILITY")

CreateToggle(MainPage, "Auto Pickup", "AutoPickup", nil, true, function(scroll)
    CreateSlider(scroll, "Range", "AutoPickupRange", 5, 80, 5)
    CreateSlider(scroll, "Delay (sec)", "AutoPickupDelay", 0.1, 2, 0.1)
end)

CreateToggle(MainPage, "Auto Heal", "AutoHeal", nil, true, function(scroll)
    CreateSlider(scroll, "Heal Below (%)", "AutoHealPercent", 10, 90, 5)
end)

-- ═══════════════════════════════════════════
-- POPULATE: MOVEMENT TAB
-- ═══════════════════════════════════════════
local MovementPage = Tabs["Movement"]

CreateSection(MovementPage, "LOCOMOTION")

CreateToggle(MovementPage, "Speed Hack", "Speed", nil, true, function(scroll)
    CreateSlider(scroll, "Walk Speed", "SpeedValue", 16, 150, 1)
end)

CreateToggle(MovementPage, "Fly", "Fly", nil, true, function(scroll)
    CreateSlider(scroll, "Fly Speed", "FlySpeed", 10, 200, 5)
end)

CreateToggle(MovementPage, "Infinite Jump", "InfiniteJump", nil, false, nil)

CreateToggle(MovementPage, "NoClip", "NoClip", nil, false, nil)

CreateToggle(MovementPage, "Auto Sprint", "AutoSprint", nil, false, nil)

CreateToggle(MovementPage, "Bunny Hop", "BunnyHop", nil, true, function(scroll)
    CreateSlider(scroll, "Jump Power", "BunnyHopPower", 30, 150, 5)
end)

-- ═══════════════════════════════════════════
-- POPULATE: VISUALS TAB
-- ═══════════════════════════════════════════
local VisualsPage = Tabs["Visuals"]

CreateSection(VisualsPage, "PLAYERS")

CreateToggle(VisualsPage, "ESP (Players)", "ESP", nil, true, function(scroll)
    CreateSettingsToggle(scroll, "Show Box", "ESPBox")
    CreateSettingsToggle(scroll, "Show Name", "ESPName")
    CreateSettingsToggle(scroll, "Show Health", "ESPHealth")
    CreateSettingsToggle(scroll, "Show Distance", "ESPDistance")
    CreateSettingsToggle(scroll, "Show Tracers", "ESPTracers")
    CreateSettingsToggle(scroll, "Team Check", "ESPTeamCheck")
    CreateSlider(scroll, "Max Distance", "ESPMaxDistance", 50, 2000, 50)
end)

CreateToggle(VisualsPage, "Chams (Highlight)", "Chams", nil, true, function(scroll)
    CreateSlider(scroll, "Fill Transparency", "ChamsFillTransparency", 0, 1, 0.05)
    CreateSlider(scroll, "Outline Transparency", "ChamsOutlineTransparency", 0, 1, 0.05)
end)

CreateSection(VisualsPage, "WORLD")

CreateToggle(VisualsPage, "Item ESP", "ItemESP", nil, true, function(scroll)
    CreateSlider(scroll, "Max Distance", "ItemESPMaxDistance", 20, 500, 10)
end)

CreateToggle(VisualsPage, "Fullbright", "Fullbright", nil, false, nil)

CreateToggle(VisualsPage, "No Fog", "NoFog", nil, false, nil)

CreateToggle(VisualsPage, "Crosshair", "CrosshairEnabled", nil, true, function(scroll)
    CreateSlider(scroll, "Size", "CrosshairSize", 2, 20, 1)
    CreateSlider(scroll, "Thickness", "CrosshairThickness", 1, 5, 1)
end)

-- ═══════════════════════════════════════════
-- POPULATE: SETTINGS TAB
-- ═══════════════════════════════════════════
local SettingsPage = Tabs["Settings"]

CreateSection(SettingsPage, "CONFIGURATION")

CreateToggle(SettingsPage, "Auto Save Config", "AutoSave", nil, false, nil)
CreateToggle(SettingsPage, "Notifications", "Notifications", nil, false, nil)
CreateToggle(SettingsPage, "Streamer Mode", "StreamerMode", nil, false, nil)

CreateSection(SettingsPage, "ACTIONS")

CreateButton(SettingsPage, "💾  Save Config", Theme.Green, function()
    SaveConfig()
    Notify("2ZWare", "Config saved!", 2)
end)

CreateButton(SettingsPage, "📂  Load Config", Theme.Blue, function()
    LoadConfig()
    Notify("2ZWare", "Config loaded! Rejoin for full effect.", 3)
end)

CreateButton(SettingsPage, "🔄  Reset Config", Theme.Red, function()
    ResetConfig()
    Notify("2ZWare", "Config reset to defaults!", 2)
end)

CreateButton(SettingsPage, "🗑  Destroy GUI", Theme.Red, function()
    ScreenGui:Destroy()
end)

CreateSection(SettingsPage, "INFO")

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 60)
infoLabel.BackgroundColor3 = Theme.Card
infoLabel.Text = "⚡ 2ZWare v1.0\nVagrant Survival\nby 2Z"
infoLabel.TextColor3 = Theme.TextDim
infoLabel.TextSize = 11
infoLabel.Font = Enum.Font.GothamMedium
infoLabel.ZIndex = SettingsPage.ZIndex + 1
infoLabel.TextWrapped = true
infoLabel.Parent = SettingsPage

local ilCorner = Instance.new("UICorner")
ilCorner.CornerRadius = UDim.new(0, 10)
ilCorner.Parent = infoLabel

-- ═══════════════════════════════════════════
-- GUI TOGGLE LOGIC
-- ═══════════════════════════════════════════
local guiOpen = false

local function ToggleGUI()
    guiOpen = not guiOpen
    if guiOpen then
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 420, 0, 0)
        MainFrame.BackgroundTransparency = 1
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 420, 0, 520),
            BackgroundTransparency = 0,
        }):Play()
    else
        CloseSettingsPanel()
        local tw = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 420, 0, 0),
            BackgroundTransparency = 1,
        })
        tw:Play()
        tw.Completed:Connect(function()
            if not guiOpen then
                MainFrame.Visible = false
            end
        end)
    end
end

ToggleButton.MouseButton1Click:Connect(ToggleGUI)
CloseBtn.MouseButton1Click:Connect(function()
    if guiOpen then ToggleGUI() end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode[Config.ToggleKey] then
        ToggleGUI()
    end
end)

-- ═══════════════════════════════════════════
-- ═══════════════════════════════════════════
-- FUNCTIONAL IMPLEMENTATIONS
-- ═══════════════════════════════════════════
-- ═══════════════════════════════════════════

-- ═══════════════════════════════════════════
-- FOV CIRCLE (for Aimbot)
-- ═══════════════════════════════════════════
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 60
FOVCircle.Radius = Config.AimbotFOV
FOVCircle.Filled = false
FOVCircle.Transparency = 0.7
FOVCircle.Color = Color3.fromRGB(255, 0, 85)

-- ═══════════════════════════════════════════
-- CROSSHAIR
-- ═══════════════════════════════════════════
local CrosshairLines = {}
for i = 1, 4 do
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.new(1,1,1)
    line.Thickness = 2
    line.Transparency = 1
    table.insert(CrosshairLines, line)
end

-- ═══════════════════════════════════════════
-- ESP STORAGE
-- ═══════════════════════════════════════════
local ESPObjects = {}

local function CreateESPForPlayer(plr)
    if plr == Player then return end
    if ESPObjects[plr] then return end
    
    local esp = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Line"),
        HealthBg = Drawing.new("Line"),
        Distance = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
    }
    
    esp.Box.Visible = false
    esp.Box.Thickness = 1.5
    esp.Box.Filled = false
    esp.Box.Color = Color3.fromRGB(Config.ESPColor[1], Config.ESPColor[2], Config.ESPColor[3])
    esp.Box.Transparency = 1
    
    esp.Name.Visible = false
    esp.Name.Size = 13
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.Color = Color3.new(1,1,1)
    esp.Name.Font = 2
    
    esp.HealthBg.Visible = false
    esp.HealthBg.Thickness = 4
    esp.HealthBg.Color = Color3.fromRGB(30, 30, 30)
    esp.HealthBg.Transparency = 1
    
    esp.Health.Visible = false
    esp.Health.Thickness = 2
    esp.Health.Color = Theme.Green
    esp.Health.Transparency = 1
    
    esp.Distance.Visible = false
    esp.Distance.Size = 11
    esp.Distance.Center = true
    esp.Distance.Outline = true
    esp.Distance.Color = Theme.TextDim
    esp.Distance.Font = 2
    
    esp.Tracer.Visible = false
    esp.Tracer.Thickness = 1
    esp.Tracer.Color = Color3.fromRGB(Config.ESPColor[1], Config.ESPColor[2], Config.ESPColor[3])
    esp.Tracer.Transparency = 0.7
    
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

local function HideESP(plr)
    if ESPObjects[plr] then
        for _, obj in pairs(ESPObjects[plr]) do
            pcall(function() obj.Visible = false end)
        end
    end
end

-- ═══════════════════════════════════════════
-- CHAMS STORAGE
-- ═══════════════════════════════════════════
local ChamsObjects = {}

local function UpdateChams()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            local char = GetCharacter(plr)
            if char and Config.Chams then
                if Config.ESPTeamCheck and IsTeammate(plr) then
                    if ChamsObjects[plr] then
                        ChamsObjects[plr]:Destroy()
                        ChamsObjects[plr] = nil
                    end
                    continue
                end
                
                if not ChamsObjects[plr] or not ChamsObjects[plr].Parent then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Color3.fromRGB(Config.ChamsColor[1], Config.ChamsColor[2], Config.ChamsColor[3])
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = Config.ChamsFillTransparency
                    hl.OutlineTransparency = Config.ChamsOutlineTransparency
                    hl.Adornee = char
                    hl.Parent = char
                    ChamsObjects[plr] = hl
                else
                    ChamsObjects[plr].FillTransparency = Config.ChamsFillTransparency
                    ChamsObjects[plr].OutlineTransparency = Config.ChamsOutlineTransparency
                    ChamsObjects[plr].Adornee = char
                end
            else
                if ChamsObjects[plr] then
                    pcall(function() ChamsObjects[plr]:Destroy() end)
                    ChamsObjects[plr] = nil
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════
-- ITEM ESP STORAGE
-- ═══════════════════════════════════════════
local ItemESPObjects = {}

local function ClearItemESP()
    for _, obj in pairs(ItemESPObjects) do
        pcall(function() obj:Remove() end)
    end
    ItemESPObjects = {}
end

-- ═══════════════════════════════════════════
-- FLY SYSTEM
-- ═══════════════════════════════════════════
local flyBV = nil
local flyBG = nil
local flyActive = false

local function StartFly()
    local char = GetCharacter(Player)
    local hrp = GetRootPart(Player)
    local hum = GetHumanoid(Player)
    if not char or not hrp or not hum then return end
    
    flyActive = true
    
    if not flyBV then
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.new(0, 0, 0)
        flyBV.Parent = hrp
    end
    
    if not flyBG then
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBG.D = 200
        flyBG.P = 10000
        flyBG.Parent = hrp
    end
end

local function StopFly()
    flyActive = false
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
end

-- ═══════════════════════════════════════════
-- AIMBOT TARGET FINDER
-- ═══════════════════════════════════════════
local function GetClosestPlayerToMouse(fov, bone, teamCheck, visCheck)
    local closest = nil
    local closestDist = fov
    local myRoot = GetRootPart(Player)
    if not myRoot then return nil end
    
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and IsAlive(plr) then
            if teamCheck and IsTeammate(plr) then continue end
            
            local char = GetCharacter(plr)
            local targetPart = GetBone(char, bone)
            if not targetPart then continue end
            
            local screenPos, onScreen = WorldToScreen(targetPart.Position)
            if not onScreen then continue end
            
            local dist = (screenPos - screenCenter).Magnitude
            if dist < closestDist then
                if visCheck and not IsVisible(targetPart) then continue end
                closestDist = dist
                closest = plr
            end
        end
    end
    
    return closest
end

-- ═══════════════════════════════════════════
-- AIMBOT LOGIC
-- ═══════════════════════════════════════════
local aimbotTarget = nil
local aimHolding = false

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.ButtonL2 then
        aimHolding = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.ButtonL2 then
        aimHolding = false
        aimbotTarget = nil
    end
end)

-- ═══════════════════════════════════════════
-- INFINITE JUMP
-- ═══════════════════════════════════════════
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = GetHumanoid(Player)
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ═══════════════════════════════════════════
-- PLAYER CONNECTIONS
-- ═══════════════════════════════════════════
for _, plr in ipairs(Players:GetPlayers()) do
    CreateESPForPlayer(plr)
end

Players.PlayerAdded:Connect(function(plr)
    CreateESPForPlayer(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
    RemoveESPForPlayer(plr)
    if ChamsObjects[plr] then
        pcall(function() ChamsObjects[plr]:Destroy() end)
        ChamsObjects[plr] = nil
    end
end)

-- ═══════════════════════════════════════════
-- AUTO PICKUP / AUTO HEAL HELPERS
-- ═══════════════════════════════════════════
local lastPickupTime = 0
local lastHealTime = 0
local lastAutoAttackTime = 0
local lastKillAuraTime = 0

local function TryAutoPickup()
    if not Config.AutoPickup then return end
    if tick() - lastPickupTime < Config.AutoPickupDelay then return end
    lastPickupTime = tick()
    
    local hrp = GetRootPart(Player)
    if not hrp then return end
    
    -- Try to find droppable items in workspace
    pcall(function()
        for _, item in pairs(Workspace:GetChildren()) do
            if item:IsA("Model") or item:IsA("Part") or item:IsA("MeshPart") then
                local cd = item:FindFirstChild("ClickDetector") or (item:IsA("Model") and item:FindFirstChildWhichIsA("ClickDetector", true))
                local prox = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                
                local itemPos = item:IsA("Model") and (item:FindFirstChild("HumanoidRootPart") or item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) or item
                if not itemPos then continue end
                local pos = itemPos:IsA("BasePart") and itemPos.Position or (itemPos.Position or Vector3.new(0,0,0))
                
                if typeof(pos) == "Vector3" and (pos - hrp.Position).Magnitude <= Config.AutoPickupRange then
                    if prox then
                        fireproximityprompt(prox)
                    elseif cd then
                        fireclickdetector(cd)
                    end
                end
            end
        end
    end)
end

local function TryAutoHeal()
    if not Config.AutoHeal then return end
    if tick() - lastHealTime < 1 then return end
    lastHealTime = tick()
    
    local hum = GetHumanoid(Player)
    if not hum then return end
    
    local healthPct = (hum.Health / hum.MaxHealth) * 100
    if healthPct > Config.AutoHealPercent then return end
    
    -- Try to use healing items from backpack
    pcall(function()
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return end
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name:find("heal") or name:find("med") or name:find("bandage") or name:find("food") or name:find("potion") or name:find("health") then
                    local char = GetCharacter(Player)
                    if char then
                        tool.Parent = char
                        task.wait(0.1)
                        if tool:FindFirstChild("RemoteEvent") then
                            tool.RemoteEvent:FireServer()
                        end
                        tool:Activate()
                    end
                    break
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════
-- AUTO ATTACK / KILL AURA
-- ═══════════════════════════════════════════
local function TryAutoAttack()
    if not Config.AutoAttack then return end
    if tick() - lastAutoAttackTime < Config.AutoAttackDelay then return end
    
    local hrp = GetRootPart(Player)
    if not hrp then return end
    local char = GetCharacter(Player)
    if not char then return end
    
    local closestDist = Config.AutoAttackRange
    local closestTarget = nil
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and IsAlive(plr) then
            local enemyRoot = GetRootPart(plr)
            if enemyRoot then
                local dist = (enemyRoot.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestTarget = plr
                end
            end
        end
    end
    
    if closestTarget then
        lastAutoAttackTime = tick()
        pcall(function()
            -- Try to activate held tool
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end
            
            -- Virtual click
            local vu = game:GetService("VirtualUser")
            if vu then
                vu:Button1Down(Vector2.new(0,0), Camera.CFrame)
                task.wait(0.05)
                vu:Button1Up(Vector2.new(0,0), Camera.CFrame)
            end
        end)
    end
end

local function TryKillAura()
    if not Config.KillAura then return end
    if tick() - lastKillAuraTime < Config.KillAuraDelay then return end
    
    local hrp = GetRootPart(Player)
    if not hrp then return end
    local char = GetCharacter(Player)
    if not char then return end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and IsAlive(plr) then
            local enemyRoot = GetRootPart(plr)
            if enemyRoot and (enemyRoot.Position - hrp.Position).Magnitude <= Config.KillAuraRange then
                lastKillAuraTime = tick()
                pcall(function()
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        tool:Activate()
                    end
                end)
                break
            end
        end
    end
end

-- ═══════════════════════════════════════════
-- FULLBRIGHT / NO FOG
-- ═══════════════════════════════════════════
local originalAmbient
local originalOutdoor
local originalBrightness
local originalFogEnd
local originalFogStart

pcall(function()
    originalAmbient = game.Lighting.Ambient
    originalOutdoor = game.Lighting.OutdoorAmbient
    originalBrightness = game.Lighting.Brightness
    originalFogEnd = game.Lighting.FogEnd
    originalFogStart = game.Lighting.FogStart
end)

-- ═══════════════════════════════════════════
-- MAIN RENDER LOOP
-- ═══════════════════════════════════════════
RunService.RenderStepped:Connect(function(dt)
    local myRoot = GetRootPart(Player)
    local myHum = GetHumanoid(Player)
    local myChar = GetCharacter(Player)
    
    -- ════════════════════════
    -- FOV Circle
    -- ════════════════════════
    if Config.Aimbot and Config.AimbotShowFOV then
        FOVCircle.Visible = true
        FOVCircle.Radius = Config.AimbotFOV
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    else
        FOVCircle.Visible = false
    end
    
    -- ════════════════════════
    -- Crosshair
    -- ════════════════════════
    if Config.CrosshairEnabled then
        local cx = Camera.ViewportSize.X / 2
        local cy = Camera.ViewportSize.Y / 2
        local s = Config.CrosshairSize
        local gap = 3
        local t = Config.CrosshairThickness
        local col = Color3.fromRGB(Config.CrosshairColor[1], Config.CrosshairColor[2], Config.CrosshairColor[3])
        
        -- Top
        CrosshairLines[1].From = Vector2.new(cx, cy - gap - s)
        CrosshairLines[1].To = Vector2.new(cx, cy - gap)
        -- Bottom
        CrosshairLines[2].From = Vector2.new(cx, cy + gap)
        CrosshairLines[2].To = Vector2.new(cx, cy + gap + s)
        -- Left
        CrosshairLines[3].From = Vector2.new(cx - gap - s, cy)
        CrosshairLines[3].To = Vector2.new(cx - gap, cy)
        -- Right
        CrosshairLines[4].From = Vector2.new(cx + gap, cy)
        CrosshairLines[4].To = Vector2.new(cx + gap + s, cy)
        
        for _, line in ipairs(CrosshairLines) do
            line.Visible = true
            line.Color = col
            line.Thickness = t
        end
    else
        for _, line in ipairs(CrosshairLines) do
            line.Visible = false
        end
    end
    
    -- ════════════════════════
    -- Aimbot
    -- ════════════════════════
    if Config.Aimbot and aimHolding and myRoot then
        if not aimbotTarget or not IsAlive(aimbotTarget) then
            aimbotTarget = GetClosestPlayerToMouse(Config.AimbotFOV, Config.AimbotBone, Config.AimbotTeamCheck, Config.AimbotVisCheck)
        end
        
        if aimbotTarget and IsAlive(aimbotTarget) then
            local targetChar = GetCharacter(aimbotTarget)
            local targetPart = GetBone(targetChar, Config.AimbotBone)
            if targetPart then
                local targetPos = targetPart.Position
                local currentCF = Camera.CFrame
                local targetCF = CFrame.new(currentCF.Position, targetPos)
                
                local smooth = Config.AimbotSmooth
                Camera.CFrame = currentCF:Lerp(targetCF, 1 / smooth)
            end
        end
    end
    
    -- ════════════════════════
    -- Speed
    -- ════════════════════════
    if Config.Speed and myHum then
        myHum.WalkSpeed = Config.SpeedValue
    end
    
    -- ════════════════════════
    -- Auto Sprint
    -- ════════════════════════
    if Config.AutoSprint and myHum then
        if myHum.MoveDirection.Magnitude > 0 then
            myHum.WalkSpeed = math.max(myHum.WalkSpeed, Config.Speed and Config.SpeedValue or 24)
        end
    end
    
    -- ════════════════════════
    -- Fly
    -- ════════════════════════
    if Config.Fly and myRoot then
        if not flyActive then StartFly() end
        if flyBV and flyBG then
            local moveDir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDir = moveDir - Vector3.new(0, 1, 0)
            end
            
            -- Mobile: use humanoid move direction
            if myHum and moveDir.Magnitude < 0.01 then
                local md = myHum.MoveDirection
                if md.Magnitude > 0.01 then
                    moveDir = md
                end
            end
            
            if moveDir.Magnitude > 0.01 then
                flyBV.Velocity = moveDir.Unit * Config.FlySpeed
            else
                flyBV.Velocity = Vector3.new(0, 0, 0)
            end
            flyBG.CFrame = Camera.CFrame
        end
    else
        if flyActive then StopFly() end
    end
    
    -- ════════════════════════
    -- NoClip
    -- ════════════════════════
    if Config.NoClip and myChar then
        for _, part in pairs(myChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    -- ════════════════════════
    -- Bunny Hop
    -- ════════════════════════
    if Config.BunnyHop and myHum then
        if myHum.MoveDirection.Magnitude > 0 and myHum:GetState() ~= Enum.HumanoidStateType.Freefall then
            myHum.JumpPower = Config.BunnyHopPower
            myHum.Jump = true
        end
    end
    
    -- ════════════════════════
    -- ESP Update
    -- ════════════════════════
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == Player then continue end
        
        if not ESPObjects[plr] then
            CreateESPForPlayer(plr)
        end
        
        local esp = ESPObjects[plr]
        if not esp then continue end
        
        if not Config.ESP or not IsAlive(plr) then
            HideESP(plr)
            continue
        end
        
        if Config.ESPTeamCheck and IsTeammate(plr) then
            HideESP(plr)
            continue
        end
        
        local char = GetCharacter(plr)
        local enemyRoot = GetRootPart(plr)
        local enemyHum = GetHumanoid(plr)
        local head = char and char:FindFirstChild("Head")
        
        if not enemyRoot or not enemyHum or not myRoot then
            HideESP(plr)
            continue
        end
        
        local distance = (enemyRoot.Position - myRoot.Position).Magnitude
        if distance > Config.ESPMaxDistance then
            HideESP(plr)
            continue
        end
        
        local rootScreen, rootOnScreen, rootZ = WorldToScreen(enemyRoot.Position)
        
        if not rootOnScreen then
            HideESP(plr)
            continue
        end
        
        -- Calculate box from character bounds
        local headPos = head and head.Position + Vector3.new(0, 1.5, 0) or (enemyRoot.Position + Vector3.new(0, 3, 0))
        local feetPos = enemyRoot.Position - Vector3.new(0, 3, 0)
        
        local topScreen = WorldToScreen(headPos)
        local botScreen = WorldToScreen(feetPos)
        
        local boxHeight = math.abs(botScreen.Y - topScreen.Y)
        local boxWidth = boxHeight * 0.55
        
        local espColor = Color3.fromRGB(Config.ESPColor[1], Config.ESPColor[2], Config.ESPColor[3])
        
        -- Box
        if Config.ESPBox then
            esp.Box.Size = Vector2.new(boxWidth, boxHeight)
            esp.Box.Position = Vector2.new(rootScreen.X - boxWidth / 2, topScreen.Y)
            esp.Box.Color = espColor
            esp.Box.Visible = true
        else
            esp.Box.Visible = false
        end
        
        -- Name
        if Config.ESPName then
            local displayName = Config.StreamerMode and "Player" or plr.DisplayName
            esp.Name.Text = displayName
            esp.Name.Position = Vector2.new(rootScreen.X, topScreen.Y - 16)
            esp.Name.Visible = true
        else
            esp.Name.Visible = false
        end
        
        -- Health bar (left side of box)
        if Config.ESPHealth then
            local healthPct = math.clamp(enemyHum.Health / enemyHum.MaxHealth, 0, 1)
            local barX = rootScreen.X - boxWidth / 2 - 6
            
            esp.HealthBg.From = Vector2.new(barX, topScreen.Y)
            esp.HealthBg.To = Vector2.new(barX, botScreen.Y)
            esp.HealthBg.Visible = true
            
            local barTop = botScreen.Y - (botScreen.Y - topScreen.Y) * healthPct
            esp.Health.From = Vector2.new(barX, barTop)
            esp.Health.To = Vector2.new(barX, botScreen.Y)
            
            -- Color gradient: green -> yellow -> red
            if healthPct > 0.5 then
                esp.Health.Color = Color3.fromRGB(0, 255 * healthPct, 0)
            else
                esp.Health.Color = Color3.fromRGB(255 * (1 - healthPct), 255 * healthPct, 0)
            end
            esp.Health.Visible = true
        else
            esp.HealthBg.Visible = false
            esp.Health.Visible = false
        end
        
        -- Distance
        if Config.ESPDistance then
            esp.Distance.Text = math.floor(distance) .. "m"
            esp.Distance.Position = Vector2.new(rootScreen.X, botScreen.Y + 3)
            esp.Distance.Visible = true
        else
            esp.Distance.Visible = false
        end
        
        -- Tracers
        if Config.ESPTracers then
            esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            esp.Tracer.To = Vector2.new(rootScreen.X, botScreen.Y)
            esp.Tracer.Color = espColor
            esp.Tracer.Visible = true
        else
            esp.Tracer.Visible = false
        end
    end
    
    -- ════════════════════════
    -- Chams
    -- ════════════════════════
    UpdateChams()
    
    -- ════════════════════════
    -- Fullbright
    -- ════════════════════════
    pcall(function()
        if Config.Fullbright then
            game.Lighting.Ambient = Color3.new(1, 1, 1)
            game.Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            game.Lighting.Brightness = 2
        end
    end)
    
    -- ════════════════════════
    -- No Fog
    -- ════════════════════════
    pcall(function()
        if Config.NoFog then
            game.Lighting.FogEnd = 1000000
            game.Lighting.FogStart = 1000000
        end
    end)
    
    -- ════════════════════════
    -- Auto systems
    -- ════════════════════════
    TryAutoPickup()
    TryAutoHeal()
    TryAutoAttack()
    TryKillAura()
end)

-- ═══════════════════════════════════════════
-- ITEM ESP (Heartbeat - less frequent)
-- ═══════════════════════════════════════════
local itemESPUpdate = 0
RunService.Heartbeat:Connect(function()
    itemESPUpdate = itemESPUpdate + 1
    if itemESPUpdate % 30 ~= 0 then return end
    
    ClearItemESP()
    
    if not Config.ItemESP then return end
    
    local myRoot = GetRootPart(Player)
    if not myRoot then return end
    
    pcall(function()
        -- Scan workspace for loot / items / drops
        local searchFolders = {Workspace}
        
        -- Also try common item folders
        for _, name in ipairs({"Drops", "Items", "Loot", "DroppedItems", "Collectibles", "Pickups"}) do
            local folder = Workspace:FindFirstChild(name)
            if folder then table.insert(searchFolders, folder) end
        end
        
        for _, container in ipairs(searchFolders) do
            for _, item in pairs(container:GetChildren()) do
                if item == myRoot.Parent then continue end
                if item:FindFirstChildOfClass("Humanoid") then continue end
                
                local hasPart = item:IsA("BasePart") or (item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart"))
                local hasPrompt = item:FindFirstChildWhichIsA("ProximityPrompt", true) or item:FindFirstChildWhichIsA("ClickDetector", true)
                
                if hasPart and hasPrompt then
                    local pos
                    if item:IsA("BasePart") then
                        pos = item.Position
                    elseif item:IsA("Model") then
                        local p = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                        if p then pos = p.Position end
                    end
                    
                    if pos and (pos - myRoot.Position).Magnitude <= Config.ItemESPMaxDistance then
                        local screenPos, onScreen = WorldToScreen(pos)
                        if onScreen then
                            local txt = Drawing.new("Text")
                            txt.Text = "📦 " .. item.Name
                            txt.Size = 12
                            txt.Center = true
                            txt.Outline = true
                            txt.Position = screenPos
                            txt.Color = Theme.Yellow
                            txt.Visible = true
                            txt.Font = 2
                            table.insert(ItemESPObjects, txt)
                        end
                    end
                end
            end
        end
    end)
end)

-- ═══════════════════════════════════════════
-- SILENT AIM (namecall hook)
-- ═══════════════════════════════════════════
pcall(function()
    if not getrawmetatable then return end
    
    local mt = getrawmetatable(game)
    if not mt then return end
    
    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index
    
    if setreadonly then setreadonly(mt, false) end
    
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if Config.SilentAim and (method == "FireServer" or method == "InvokeServer") then
            local myRoot2 = GetRootPart(Player)
            if myRoot2 then
                local target = GetClosestPlayerToMouse(Config.SilentAimFOV, Config.SilentAimBone, true, false)
                if target then
                    local targetChar = GetCharacter(target)
                    local targetPart = GetBone(targetChar, Config.SilentAimBone)
                    if targetPart then
                        for i, arg in ipairs(args) do
                            if typeof(arg) == "Vector3" then
                                args[i] = targetPart.Position
                            elseif typeof(arg) == "CFrame" then
                                args[i] = targetPart.CFrame
                            end
                        end
                    end
                end
            end
        end
        
        return oldNamecall(self, unpack(args))
    end)
    
    if setreadonly then setreadonly(mt, true) end
end)

-- ═══════════════════════════════════════════
-- CLEANUP ON DESTROY
-- ═══════════════════════════════════════════
ScreenGui.Destroying:Connect(function()
    -- Remove all drawing objects
    pcall(function() FOVCircle:Remove() end)
    for _, line in ipairs(CrosshairLines) do
        pcall(function() line:Remove() end)
    end
    for _, esp in pairs(ESPObjects) do
        for _, obj in pairs(esp) do
            pcall(function() obj:Remove() end)
        end
    end
    ClearItemESP()
    for _, hl in pairs(ChamsObjects) do
        pcall(function() hl:Destroy() end)
    end
    StopFly()
    
    -- Restore lighting
    pcall(function()
        if originalAmbient then game.Lighting.Ambient = originalAmbient end
        if originalOutdoor then game.Lighting.OutdoorAmbient = originalOutdoor end
        if originalBrightness then game.Lighting.Brightness = originalBrightness end
        if originalFogEnd then game.Lighting.FogEnd = originalFogEnd end
        if originalFogStart then game.Lighting.FogStart = originalFogStart end
    end)
end)

-- ═══════════════════════════════════════════
-- AUTO-SAVE LOOP
-- ═══════════════════════════════════════════
task.spawn(function()
    while task.wait(30) do
        if Config.AutoSave then
            SaveConfig()
        end
    end
end)

-- ═══════════════════════════════════════════
-- STARTUP NOTIFICATION
-- ═══════════════════════════════════════════
task.delay(1, function()
    Notify("⚡ 2ZWare", "Loaded successfully! Tap ⚡ to open.", 4)
end)

-- Glow animation on toggle button
task.spawn(function()
    while task.wait(2) do
        if ToggleButton and ToggleButton.Parent then
            TweenService:Create(toggleStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.7}):Play()
            task.wait(1)
            TweenService:Create(toggleStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.1}):Play()
        end
    end
end)
