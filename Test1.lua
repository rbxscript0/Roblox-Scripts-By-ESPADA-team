--// EspadaWare
--// Single LocalScript
--// Place in StarterPlayer > StarterPlayerScripts
--//
--// SilentAim намеренно НЕ реализован.
--// Остальные функции рассчитаны на использование в собственной игре.

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- CONFIG
--==================================================

local Config = {
    UI = {
        Open = true,
        Keybind = Enum.KeyCode.RightShift,
        Accent = Color3.fromRGB(139, 92, 246),
        Transparency = 0.08,
        Scale = 1,
    },

    Main = {
        AimBot = false,
        AimFOV = 120,
        AimSmoothness = 0.18,
        TeamCheck = true,
        TargetPart = "Head",
        TriggerBot = false,
        TriggerDelay = 0.08,
        TargetHud = true,
    },

    Movement = {
        Speed = false,
        SpeedValue = 24,
        Jump = false,
        JumpValue = 60,
        InfiniteJump = false,
        Fly = false,
        FlySpeed = 55,
        Noclip = false,
    },

    Visuals = {
        ESP = false,
        ESPNames = true,
        ESPDistance = true,
        Fullbright = false,
        Skybox = false,
        SkyboxBrightness = 2,
        FPS = true,
        Ping = true,
    },

    Settings = {
        Music = false,
        MusicVolume = 0.35,
        Notifications = true,
    }
}

local Defaults = {}

local function deepCopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

Defaults = deepCopy(Config)

--==================================================
-- UTILITIES
--==================================================

local function tween(obj, time, props, style, direction)
    local info = TweenInfo.new(
        time,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )

    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function round(n)
    return math.floor(n + 0.5)
end

local function clamp(n, a, b)
    return math.max(a, math.min(b, n))
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function notify(text)
    if not Config.Settings.Notifications then
        return
    end

    local holder = GUI:FindFirstChild("Notifications")
    if not holder then return end

    local item = Instance.new("Frame")
    item.Size = UDim2.new(0, 280, 0, 52)
    item.BackgroundColor3 = Color3.fromRGB(20, 20, 29)
    item.BackgroundTransparency = 0.04
    item.BorderSizePixel = 0
    item.Parent = holder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = item

    local stroke = Instance.new("UIStroke")
    stroke.Color = Config.UI.Accent
    stroke.Transparency = 0.65
    stroke.Parent = item

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -24, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(235, 235, 245)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = item

    item.Position = UDim2.new(1, 20, 0, 0)
    tween(item, .35, {Position = UDim2.new(0, 0, 0, 0)})

    task.delay(2.7, function()
        tween(item, .3, {
            Position = UDim2.new(1, 20, 0, 0)
        })
        task.wait(.35)
        item:Destroy()
    end)
end

--==================================================
-- GUI
--==================================================

local old = LocalPlayer.PlayerGui:FindFirstChild("EspadaWare")
if old then
    old:Destroy()
end

local GUI = Instance.new("ScreenGui")
GUI.Name = "EspadaWare"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = LocalPlayer.PlayerGui

--==================================================
-- NOTIFICATIONS
--==================================================

local Notifications = Instance.new("Frame")
Notifications.Name = "Notifications"
Notifications.AnchorPoint = Vector2.new(1, 0)
Notifications.Position = UDim2.new(1, -20, 0, 20)
Notifications.Size = UDim2.new(0, 280, 1, -40)
Notifications.BackgroundTransparency = 1
Notifications.Parent = GUI

local notifLayout = Instance.new("UIListLayout")
notifLayout.Padding = UDim.new(0, 8)
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
notifLayout.Parent = Notifications

--==================================================
-- MAIN WINDOW
--==================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(.5, .5)
Main.Position = UDim2.fromScale(.5, .5)
Main.Size = UDim2.fromOffset(900, 570)
Main.BackgroundColor3 = Color3.fromRGB(11, 11, 17)
Main.BackgroundTransparency = Config.UI.Transparency
Main.BorderSizePixel = 0
Main.Parent = GUI

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 18)
mainCorner.Parent = Main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(55, 55, 72)
mainStroke.Transparency = .35
mainStroke.Thickness = 1
mainStroke.Parent = Main

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 16, 26)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 10, 15))
})
MainGradient.Rotation = 35
MainGradient.Parent = Main

--==================================================
-- HEADER
--==================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 74)
Header.BackgroundTransparency = 1
Header.Parent = Main

local Logo = Instance.new("Frame")
Logo.Position = UDim2.fromOffset(22, 17)
Logo.Size = UDim2.fromOffset(42, 42)
Logo.BackgroundColor3 = Config.UI.Accent
Logo.BorderSizePixel = 0
Logo.Parent = Header

local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(0, 12)
logoCorner.Parent = Logo

local logoText = Instance.new("TextLabel")
logoText.BackgroundTransparency = 1
logoText.Size = UDim2.fromScale(1, 1)
logoText.Font = Enum.Font.GothamBold
logoText.Text = "E"
logoText.TextSize = 23
logoText.TextColor3 = Color3.new(1, 1, 1)
logoText.Parent = Logo

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(76, 14)
Title.Size = UDim2.fromOffset(300, 28)
Title.Font = Enum.Font.GothamBold
Title.Text = "EspadaWare"
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(245, 245, 250)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.fromOffset(77, 39)
Subtitle.Size = UDim2.fromOffset(300, 20)
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "CONTROL • VISUALS • MOVEMENT"
Subtitle.TextSize = 9
Subtitle.TextColor3 = Color3.fromRGB(125, 125, 145)
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local Close = Instance.new("TextButton")
Close.AnchorPoint = Vector2.new(1, .5)
Close.Position = UDim2.new(1, -18, .5, 0)
Close.Size = UDim2.fromOffset(34, 34)
Close.BackgroundColor3 = Color3.fromRGB(27, 27, 38)
Close.Text = "×"
Close.TextSize = 22
Close.Font = Enum.Font.Gotham
Close.TextColor3 = Color3.fromRGB(180, 180, 195)
Close.BorderSizePixel = 0
Close.Parent = Header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = Close

Close.MouseButton1Click:Connect(function()
    Config.UI.Open = false
    tween(Main, .25, {
        Size = UDim2.fromOffset(860, 530),
        BackgroundTransparency = 1
    })
    task.delay(.26, function()
        Main.Visible = false
    end)
end)

--==================================================
-- SIDEBAR
--==================================================

local Sidebar = Instance.new("Frame")
Sidebar.Position = UDim2.fromOffset(15, 84)
Sidebar.Size = UDim2.fromOffset(175, 470)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
Sidebar.BackgroundTransparency = .18
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 14)
sideCorner.Parent = Sidebar

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 7)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.VerticalAlignment = Enum.VerticalAlignment.Top
SideLayout.Parent = Sidebar

local sidePadding = Instance.new("UIPadding")
sidePadding.PaddingTop = UDim.new(0, 15)
sidePadding.PaddingLeft = UDim.new(0, 10)
sidePadding.PaddingRight = UDim.new(0, 10)
sidePadding.Parent = Sidebar

--==================================================
-- CONTENT
--==================================================

local Content = Instance.new("Frame")
Content.Position = UDim2.fromOffset(205, 84)
Content.Size = UDim2.new(1, -220, 1, -99)
Content.BackgroundTransparency = 1
Content.Parent = Main

local Pages = {}

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Config.UI.Accent
    page.CanvasSize = UDim2.fromOffset(0, 0)
    page.Visible = false
    page.Parent = Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    local padding = Instance.new("UIPadding")
    padding.PaddingRight = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = page

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.fromOffset(
            0,
            layout.AbsoluteContentSize.Y + 15
        )
    end)

    Pages[name] = page
    return page
end

local MainPage = createPage("Main")
local MovementPage = createPage("Movement")
local VisualsPage = createPage("Visuals")
local SettingsPage = createPage("Settings")

--==================================================
-- SIDEBAR BUTTONS
--==================================================

local tabButtons = {}

local function createTab(name, icon)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, 0, 0, 45)
    button.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.AutoButtonColor = false
    button.BorderSizePixel = 0
    button.Parent = Sidebar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 11)
    corner.Parent = button

    local iconLabel = Instance.new("TextLabel")
    iconLabel.BackgroundTransparency = 1
    iconLabel.Position = UDim2.fromOffset(12, 0)
    iconLabel.Size = UDim2.fromOffset(28, 45)
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Text = icon
    iconLabel.TextSize = 15
    iconLabel.TextColor3 = Color3.fromRGB(145, 145, 165)
    iconLabel.Parent = button

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(48, 0)
    label.Size = UDim2.new(1, -55, 1, 0)
    label.Font = Enum.Font.GothamMedium
    label.Text = name
    label.TextSize = 12
    label.TextColor3 = Color3.fromRGB(165, 165, 180)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = button

    tabButtons[name] = button

    return button
end

local tabMain = createTab("Main", "⌂")
local tabMovement = createTab("Movement", "↯")
local tabVisuals = createTab("Visuals", "◉")
local tabSettings = createTab("Settings", "⚙")

local function showPage(name)
    for n, page in pairs(Pages) do
        page.Visible = n == name
    end

    for n, button in pairs(tabButtons) do
        local active = n == name

        tween(button, .18, {
            BackgroundTransparency = active and 0 or 1
        })

        local icon = button:FindFirstChildOfClass("TextLabel")
        local labels = button:GetChildren()

        if icon then
            tween(icon, .18, {
                TextColor3 = active
                    and Config.UI.Accent
                    or Color3.fromRGB(145, 145, 165)
            })
        end

        for _, child in ipairs(labels) do
            if child:IsA("TextLabel") and child ~= icon then
                tween(child, .18, {
                    TextColor3 = active
                        and Color3.fromRGB(240, 240, 250)
                        or Color3.fromRGB(165, 165, 180)
                })
            end
        end
    end
end

tabMain.MouseButton1Click:Connect(function()
    showPage("Main")
end)

tabMovement.MouseButton1Click:Connect(function()
    showPage("Movement")
end)

tabVisuals.MouseButton1Click:Connect(function()
    showPage("Visuals")
end)

tabSettings.MouseButton1Click:Connect(function()
    showPage("Settings")
end)

--==================================================
-- UI COMPONENTS
--==================================================

local function section(parent, title, description)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -5, 0, description and 61 or 42)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 27)
    frame.BackgroundTransparency = .1
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 13)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(15, 8)
    label.Size = UDim2.new(1, -30, 0, 22)
    label.Font = Enum.Font.GothamBold
    label.Text = title
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(235, 235, 245)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    if description then
        local desc = Instance.new("TextLabel")
        desc.BackgroundTransparency = 1
        desc.Position = UDim2.fromOffset(15, 31)
        desc.Size = UDim2.new(1, -30, 0, 20)
        desc.Font = Enum.Font.Gotham
        desc.Text = description
        desc.TextSize = 9
        desc.TextColor3 = Color3.fromRGB(120, 120, 140)
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = frame
    end

    return frame
end

local function card(parent, title, description)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -5, 0, 62)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 27)
    frame.BackgroundTransparency = .08
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 13)
    corner.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.fromOffset(15, 10)
    titleLabel.Size = UDim2.new(1, -150, 0, 20)
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.Text = title
    titleLabel.TextSize = 12
    titleLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame

    if description then
        local desc = Instance.new("TextLabel")
        desc.BackgroundTransparency = 1
        desc.Position = UDim2.fromOffset(15, 32)
        desc.Size = UDim2.new(1, -150, 0, 18)
        desc.Font = Enum.Font.Gotham
        desc.Text = description
        desc.TextSize = 9
        desc.TextColor3 = Color3.fromRGB(115, 115, 135)
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = frame
    end

    return frame
end

local function toggle(parent, title, description, getter, setter)
    local frame = card(parent, title, description)

    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, .5)
    button.Position = UDim2.new(1, -15, .5, 0)
    button.Size = UDim2.fromOffset(48, 26)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
    button.Text = ""
    button.AutoButtonColor = false
    button.BorderSizePixel = 0
    button.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(.5, .5)
    knob.Position = UDim2.new(0, 14, .5, 0)
    knob.Size = UDim2.fromOffset(18, 18)
    knob.BackgroundColor3 = Color3.fromRGB(180, 180, 195)
    knob.BorderSizePixel = 0
    knob.Parent = button

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local function refresh()
        local enabled = getter()

        tween(button, .18, {
            BackgroundColor3 = enabled
                and Config.UI.Accent
                or Color3.fromRGB(40, 40, 52)
        })

        tween(knob, .18, {
            Position = enabled
                and UDim2.new(1, -14, .5, 0)
                or UDim2.new(0, 14, .5, 0),
            BackgroundColor3 = enabled
                and Color3.new(1, 1, 1)
                or Color3.fromRGB(180, 180, 195)
        })
    end

    button.MouseButton1Click:Connect(function()
        setter(not getter())
        refresh()
    end)

    refresh()

    return frame, refresh
end

local function slider(parent, title, description, min, max, getter, setter)
    local frame = card(parent, title, description)
    frame.Size = UDim2.new(1, -5, 0, 76)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, -15, 0, 10)
    valueLabel.Size = UDim2.fromOffset(70, 20)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 11
    valueLabel.TextColor3 = Config.UI.Accent
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame

    local bar = Instance.new("Frame")
    bar.Position = UDim2.fromOffset(15, 55)
    bar.Size = UDim2.new(1, -30, 0, 6)
    bar.BackgroundColor3 = Color3.fromRGB(37, 37, 48)
    bar.BorderSizePixel = 0
    bar.Parent = frame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = Config.UI.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(.5, .5)
    knob.Position = UDim2.new(0, 0, .5, 0)
    knob.Size = UDim2.fromOffset(13, 13)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = bar

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local dragging = false

    local function refresh()
        local value = getter()
        local alpha = clamp((value - min) / (max - min), 0, 1)

        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.new(alpha, 0, .5, 0)
        valueLabel.Text = tostring(round(value))
    end

    local function setFromX(x)
        local alpha = clamp(
            (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
            0,
            1
        )

        local value = min + ((max - min) * alpha)
        setter(value)
        refresh()
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            setFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            setFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    refresh()

    return frame, refresh
end

local function dropdown(parent, title, description, values, getter, setter)
    local frame = card(parent, title, description)

    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, .5)
    button.Position = UDim2.new(1, -15, .5, 0)
    button.Size = UDim2.fromOffset(125, 32)
    button.BackgroundColor3 = Color3.fromRGB(29, 29, 41)
    button.TextColor3 = Color3.fromRGB(210, 210, 225)
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 10
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = button

    local index = 1

    local function refresh()
        local current = getter()

        for i, v in ipairs(values) do
            if v == current then
                index = i
                break
            end
        end

        button.Text = tostring(current) .. "  ▾"
    end

    button.MouseButton1Click:Connect(function()
        index = index + 1

        if index > #values then
            index = 1
        end

        setter(values[index])
        refresh()
    end)

    refresh()

    return frame, refresh
end

local function actionButton(parent, title, description, callback)
    local frame = card(parent, title, description)

    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, .5)
    button.Position = UDim2.new(1, -15, .5, 0)
    button.Size = UDim2.fromOffset(100, 32)
    button.BackgroundColor3 = Config.UI.Accent
    button.Text = "EXECUTE"
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 9
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = button

    button.MouseButton1Click:Connect(callback)

    return frame
end

--==================================================
-- INDIVIDUAL FEATURE SETTINGS
--==================================================

local function gear(parent, callback)
    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, .5)
    button.Position = UDim2.new(1, -75, .5, 0)
    button.Size = UDim2.fromOffset(30, 30)
    button.BackgroundColor3 = Color3.fromRGB(29, 29, 40)
    button.Text = "⚙"
    button.TextColor3 = Color3.fromRGB(150, 150, 170)
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = button

    button.MouseButton1Click:Connect(callback)

    return button
end

local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.fromScale(1, 1)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 1
Overlay.Visible = false
Overlay.ZIndex = 20
Overlay.Parent = GUI

local Popup = Instance.new("Frame")
Popup.AnchorPoint = Vector2.new(.5, .5)
Popup.Position = UDim2.fromScale(.5, .5)
Popup.Size = UDim2.fromOffset(410, 0)
Popup.BackgroundColor3 = Color3.fromRGB(15, 15, 23)
Popup.BorderSizePixel = 0
Popup.ZIndex = 21
Popup.ClipsDescendants = true
Popup.Parent = Overlay

local popCorner = Instance.new("UICorner")
popCorner.CornerRadius = UDim.new(0, 16)
popCorner.Parent = Popup

local popStroke = Instance.new("UIStroke")
popStroke.Color = Config.UI.Accent
popStroke.Transparency = .65
popStroke.Parent = Popup

local popTitle = Instance.new("TextLabel")
popTitle.BackgroundTransparency = 1
popTitle.Position = UDim2.fromOffset(18, 13)
popTitle.Size = UDim2.new(1, -60, 0, 25)
popTitle.Font = Enum.Font.GothamBold
popTitle.TextSize = 14
popTitle.TextColor3 = Color3.fromRGB(240, 240, 250)
popTitle.TextXAlignment = Enum.TextXAlignment.Left
popTitle.ZIndex = 22
popTitle.Parent = Popup

local popClose = Instance.new("TextButton")
popClose.AnchorPoint = Vector2.new(1, 0)
popClose.Position = UDim2.new(1, -12, 0, 10)
popClose.Size = UDim2.fromOffset(30, 30)
popClose.BackgroundTransparency = 1
popClose.Text = "×"
popClose.TextSize = 20
popClose.TextColor3 = Color3.fromRGB(180, 180, 195)
popClose.ZIndex = 22
popClose.Parent = Popup

local popContent = Instance.new("ScrollingFrame")
popContent.Position = UDim2.fromOffset(15, 52)
popContent.Size = UDim2.new(1, -30, 1, -65)
popContent.BackgroundTransparency = 1
popContent.BorderSizePixel = 0
popContent.ScrollBarThickness = 2
popContent.ZIndex = 22
popContent.Parent = Popup

local popLayout = Instance.new("UIListLayout")
popLayout.Padding = UDim.new(0, 8)
popLayout.Parent = popContent

local function clearPopup()
    for _, child in ipairs(popContent:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
end

local function openPopup(title, height, builder)
    clearPopup()

    popTitle.Text = title
    Overlay.Visible = true
    Overlay.BackgroundTransparency = 1

    builder()

    Popup.Size = UDim2.fromOffset(410, 0)

    tween(Overlay, .18, {
        BackgroundTransparency = .35
    })

    tween(Popup, .25, {
        Size = UDim2.fromOffset(410, height)
    })
end

local function closePopup()
    tween(Overlay, .15, {
        BackgroundTransparency = 1
    })

    tween(Popup, .2, {
        Size = UDim2.fromOffset(410, 0)
    })

    task.delay(.21, function()
        Overlay.Visible = false
    end)
end

popClose.MouseButton1Click:Connect(closePopup)
Overlay.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if input.Position.X < Popup.AbsolutePosition.X
            or input.Position.X > Popup.AbsolutePosition.X + Popup.AbsoluteSize.X
            or input.Position.Y < Popup.AbsolutePosition.Y
            or input.Position.Y > Popup.AbsolutePosition.Y + Popup.AbsoluteSize.Y then
            closePopup()
        end
    end
end)

--==================================================
-- MAIN PAGE
--==================================================

section(
    MainPage,
    "Combat",
    "Targeting and interaction controls"
)

local aimCard = card(
    MainPage,
    "AimBot",
    "Automatically tracks a valid target inside the FOV"
)

toggle(MainPage, "AimBot", "Automatically tracks a valid target", 
    function()
        return Config.Main.AimBot
    end,
    function(v)
        Config.Main.AimBot = v
        notify("AimBot " .. (v and "enabled" or "disabled"))
    end
)

gear(MainPage:GetChildren()[#MainPage:GetChildren()], function()
    openPopup("AimBot Settings", 300, function()
        slider(popContent, "FOV", "Target acquisition radius", 20, 500,
            function() return Config.Main.AimFOV end,
            function(v) Config.Main.AimFOV = round(v) end
        )

        slider(popContent, "Smoothness", "Lower = slower tracking", .02, 1,
            function() return Config.Main.AimSmoothness end,
            function(v) Config.Main.AimSmoothness = v end
        )

        dropdown(popContent, "Target Part", "Body part used for targeting",
            {"Head", "HumanoidRootPart", "UpperTorso"},
            function() return Config.Main.TargetPart end,
            function(v) Config.Main.TargetPart = v end
        )
    end)
end)

toggle(MainPage, "SilentAim", "Interface placeholder — mechanics intentionally disabled",
    function()
        return false
    end,
    function()
        notify("SilentAim is intentionally disabled")
    end
)

local trigger = toggle(MainPage, "TriggerBot", "Activates when a valid target is under the crosshair",
    function()
        return Config.Main.TriggerBot
    end,
    function(v)
        Config.Main.TriggerBot = v
    end
)

gear(MainPage:GetChildren()[#MainPage:GetChildren()], function()
    openPopup("TriggerBot Settings", 210, function()
        slider(popContent, "Delay", "Activation delay", .01, .5,
            function() return Config.Main.TriggerDelay end,
            function(v) Config.Main.TriggerDelay = v end
        )
    end)
end)

section(
    MainPage,
    "Interface",
    "Information displayed during gameplay"
)

toggle(MainPage, "Target HUD", "Displays current target information",
    function()
        return Config.Main.TargetHud
    end,
    function(v)
        Config.Main.TargetHud = v
    end
)

--==================================================
-- MOVEMENT PAGE
--==================================================

section(
    MovementPage,
    "Movement",
    "Local movement controls"
)

toggle(MovementPage, "Speed", "Adjust local humanoid WalkSpeed",
    function()
        return Config.Movement.Speed
    end,
    function(v)
        Config.Movement.Speed = v
    end
)

gear(MovementPage:GetChildren()[#MovementPage:GetChildren()], function()
    openPopup("Speed Settings", 210, function()
        slider(popContent, "Speed", "WalkSpeed value", 8, 100,
            function() return Config.Movement.SpeedValue end,
            function(v) Config.Movement.SpeedValue = round(v) end
        )
    end)
end)

toggle(MovementPage, "Jump", "Adjust local jump power",
    function()
        return Config.Movement.Jump
    end,
    function(v)
        Config.Movement.Jump = v
    end
)

gear(MovementPage:GetChildren()[#MovementPage:GetChildren()], function()
    openPopup("Jump Settings", 210, function()
        slider(popContent, "Power", "JumpPower value", 20, 150,
            function() return Config.Movement.JumpValue end,
            function(v) Config.Movement.JumpValue = round(v) end
        )
    end)
end)

toggle(MovementPage, "Infinite Jump", "Jump again while airborne",
    function()
        return Config.Movement.InfiniteJump
    end,
    function(v)
        Config.Movement.InfiniteJump = v
    end
)

toggle(MovementPage, "Fly", "Local flight controller",
    function()
        return Config.Movement.Fly
    end,
    function(v)
        Config.Movement.Fly = v
    end
)

gear(MovementPage:GetChildren()[#MovementPage:GetChildren()], function()
    openPopup("Fly Settings", 210, function()
        slider(popContent, "Fly Speed", "Flight movement speed", 10, 150,
            function() return Config.Movement.FlySpeed end,
            function(v) Config.Movement.FlySpeed = round(v) end
        )
    end)
end)

toggle(MovementPage, "Noclip", "Disable local character collisions",
    function()
        return Config.Movement.Noclip
    end,
    function(v)
        Config.Movement.Noclip = v
    end
)

--==================================================
-- VISUALS PAGE
--==================================================

section(
    VisualsPage,
    "Player Visuals",
    "Information and lighting controls"
)

toggle(VisualsPage, "ESP", "Highlights players in the current game",
    function()
        return Config.Visuals.ESP
    end,
    function(v)
        Config.Visuals.ESP = v
    end
)

gear(VisualsPage:GetChildren()[#VisualsPage:GetChildren()], function()
    openPopup("ESP Settings", 250, function()
        toggle(popContent, "Names", "Display player names",
            function() return Config.Visuals.ESPNames end,
            function(v) Config.Visuals.ESPNames = v end
        )

        toggle(popContent, "Distance", "Display player distance",
            function() return Config.Visuals.ESPDistance end,
            function(v) Config.Visuals.ESPDistance = v end
        )
    end)
end)

toggle(VisualsPage, "Fullbright", "Increase local environment visibility",
    function()
        return Config.Visuals.Fullbright
    end,
    function(v)
        Config.Visuals.Fullbright = v
    end
)

toggle(VisualsPage, "Skybox", "Enhanced local lighting",
    function()
        return Config.Visuals.Skybox
    end,
    function(v)
        Config.Visuals.Skybox = v
    end
)

gear(VisualsPage:GetChildren()[#VisualsPage:GetChildren()], function()
    openPopup("Skybox Settings", 210, function()
        slider(popContent, "Brightness", "Local lighting intensity", 0, 10,
            function() return Config.Visuals.SkyboxBrightness end,
            function(v) Config.Visuals.SkyboxBrightness = v end
        )
    end)
end)

section(
    VisualsPage,
    "Performance",
    "Live client statistics"
)

toggle(VisualsPage, "FPS Counter", "Display current frame rate",
    function()
        return Config.Visuals.FPS
    end,
    function(v)
        Config.Visuals.FPS = v
    end
)

toggle(VisualsPage, "Ping Counter", "Display network latency",
    function()
        return Config.Visuals.Ping
    end,
    function(v)
        Config.Visuals.Ping = v
    end
)

--==================================================
-- SETTINGS PAGE
--==================================================

section(
    SettingsPage,
    "Interface",
    "Configure the EspadaWare interface"
)

toggle(SettingsPage, "Notifications", "Show feature notifications",
    function()
        return Config.Settings.Notifications
    end,
    function(v)
        Config.Settings.Notifications = v
    end
)

toggle(SettingsPage, "Music", "Toggle background audio",
    function()
        return Config.Settings.Music
    end,
    function(v)
        Config.Settings.Music = v
    end
)

gear(SettingsPage:GetChildren()[#SettingsPage:GetChildren()], function()
    openPopup("Music Settings", 210, function()
        slider(popContent, "Volume", "Background music volume", 0, 1,
            function() return Config.Settings.MusicVolume end,
            function(v) Config.Settings.MusicVolume = v end
        )
    end)
end)

section(
    SettingsPage,
    "Configuration",
    "Local session configuration management"
)

actionButton(
    SettingsPage,
    "Save Config",
    "Save the current configuration",
    function()
        -- LocalScript-safe session save.
        -- Persistent DataStore saving must be handled by a server script.
        Defaults = deepCopy(Config)
        notify("Configuration saved for this session")
    end
)

actionButton(
    SettingsPage,
    "Load Config",
    "Load the last saved session state",
    function()
        Config = deepCopy(Defaults)
        notify("Configuration loaded")
    end
)

actionButton(
    SettingsPage,
    "Reset Config",
    "Restore default settings",
    function()
        Config = deepCopy(Defaults)
        notify("Configuration reset")
    end
)

section(
    SettingsPage,
    "Interface Keybind",
    "Press the key below to toggle the interface"
)

local keybindFrame = card(
    SettingsPage,
    "Toggle GUI",
    "Current key: RightShift"
)

local keybindButton = Instance.new("TextButton")
keybindButton.AnchorPoint = Vector2.new(1, .5)
keybindButton.Position = UDim2.new(1, -15, .5, 0)
keybindButton.Size = UDim2.fromOffset(115, 32)
keybindButton.BackgroundColor3 = Color3.fromRGB(29, 29, 41)
keybindButton.Text = "RightShift"
keybindButton.TextColor3 = Color3.fromRGB(220, 220, 230)
keybindButton.Font = Enum.Font.GothamMedium
keybindButton.TextSize = 10
keybindButton.BorderSizePixel = 0
keybindButton.Parent = keybindFrame

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 9)
keyCorner.Parent = keybindButton

local waitingForKey = false

keybindButton.MouseButton1Click:Connect(function()
    waitingForKey = true
    keybindButton.Text = "Press key..."
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if waitingForKey and input.UserInputType == Enum.UserInputType.Keyboard then
        Config.UI.Keybind = input.KeyCode
        keybindButton.Text = input.KeyCode.Name
        waitingForKey = false
    end
end)

--==================================================
-- TARGETING
--==================================================

local function isAlive(player)
    local character = player.Character
    if not character then return false end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function validTarget(player)
    if player == LocalPlayer then
        return false
    end

    if not isAlive(player) then
        return false
    end

    if Config.Main.TeamCheck and player.Team == LocalPlayer.Team then
        return false
    end

    return true
end

local function getTargetPart(character)
    return character:FindFirstChild(Config.Main.TargetPart)
        or character:FindFirstChild("HumanoidRootPart")
end

local function getClosestTarget()
    local closest = nil
    local closestDistance = math.huge

    local viewport = Camera.ViewportSize
    local center = Vector2.new(
        viewport.X / 2,
        viewport.Y / 2
    )

    for _, player in ipairs(Players:GetPlayers()) do
        if validTarget(player) then
            local character = player.Character
            local part = getTargetPart(character)

            if part then
                local screenPos, visible =
                    Camera:WorldToViewportPoint(part.Position)

                if visible and screenPos.Z > 0 then
                    local distance = (
                        Vector2.new(screenPos.X, screenPos.Y) - center
                    ).Magnitude

                    if distance <= Config.Main.AimFOV
                        and distance < closestDistance then

                        closestDistance = distance
                        closest = player
                    end
                end
            end
        end
    end

    return closest
end

--==================================================
-- AIMBOT
--==================================================

local function updateAim()
    if not Config.Main.AimBot then
        return
    end

    local target = getClosestTarget()
    if not target then
        return
    end

    local character = target.Character
    local part = getTargetPart(character)

    if not part then
        return
    end

    local current = Camera.CFrame
    local targetCFrame = CFrame.lookAt(
        current.Position,
        part.Position
    )

    Camera.CFrame = current:Lerp(
        targetCFrame,
        clamp(Config.Main.AimSmoothness, .01, 1)
    )
end

--==================================================
-- TRIGGERBOT
--==================================================

local triggerCooldown = 0

local function updateTriggerBot(dt)
    if not Config.Main.TriggerBot then
        return
    end

    triggerCooldown -= dt

    if triggerCooldown > 0 then
        return
    end

    local viewport = Camera.ViewportSize
    local center = Vector2.new(
        viewport.X / 2,
        viewport.Y / 2
    )

    local ray = Camera:ViewportPointToRay(
        center.X,
        center.Y
    )

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        LocalPlayer.Character
    }

    local result = workspace:Raycast(
        ray.Origin,
        ray.Direction * 1000,
        params
    )

    if result then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if model then
            local player = Players:GetPlayerFromCharacter(model)

            if player and validTarget(player) then
                -- Universal trigger point:
                -- The actual weapon interaction belongs to the game's
                -- weapon system. No arbitrary RemoteEvent is fired here.
                triggerCooldown = Config.Main.TriggerDelay
            end
        end
    end
end

--==================================================
-- ESP
--==================================================

local espObjects = {}

local function removeESP(player)
    local object = espObjects[player]

    if object then
        for _, instance in pairs(object) do
            if typeof(instance) == "Instance" then
                instance:Destroy()
            end
        end

        espObjects[player] = nil
    end
end

local function createESP(player)
    if player == LocalPlayer then
        return
    end

    if espObjects[player] then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "EspadaWareESP"
    highlight.FillColor = Config.UI.Accent
    highlight.FillTransparency = .78
    highlight.OutlineColor = Config.UI.Accent
    highlight.OutlineTransparency = .1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = GUI

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EspadaWareInfo"
    billboard.Size = UDim2.fromOffset(180, 42)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = Config.Visuals.ESPNames
    billboard.Parent = GUI

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = .5
    label.Parent = billboard

    espObjects[player] = {
        highlight = highlight,
        billboard = billboard,
        label = label
    }
end

local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if Config.Visuals.ESP and player ~= LocalPlayer then
            createESP(player)

            local data = espObjects[player]
            local char = player.Character

            if data and char then
                data.highlight.Adornee = char
                data.billboard.Adornee =
                    char:FindFirstChild("Head")

                local root = char:FindFirstChild("HumanoidRootPart")
                local myRoot = getRoot()

                local distanceText = ""

                if Config.Visuals.ESPDistance
                    and root
                    and myRoot then

                    distanceText =
                        "\n" ..
                        tostring(round(
                            (root.Position - myRoot.Position).Magnitude
                        )) ..
                        " studs"
                end

                data.label.Text = player.DisplayName .. distanceText
                data.billboard.Enabled =
                    Config.Visuals.ESPNames
            end
        else
            removeESP(player)
        end
    end
end

Players.PlayerRemoving:Connect(removeESP)

--==================================================
-- FULLBRIGHT / LIGHTING
--==================================================

local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

local function updateLighting()
    if Config.Visuals.Fullbright then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(190, 190, 190)
        Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
    else
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    end
end

--==================================================
-- MOVEMENT
--==================================================

local flyConnection

local function updateMovement()
    local humanoid = getHumanoid()

    if not humanoid then
        return
    end

    if Config.Movement.Speed then
        humanoid.WalkSpeed = Config.Movement.SpeedValue
    end

    if Config.Movement.Jump then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = Config.Movement.JumpValue
    end

    if Config.Movement.Noclip then
        local char = getCharacter()

        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end

local function updateFly()
    local root = getRoot()

    if not root then
        return
    end

    if not Config.Movement.Fly then
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end

        local bv = root:FindFirstChild("EspadaWareFly")
        if bv then
            bv:Destroy()
        end

        return
    end

    local bodyVelocity = root:FindFirstChild("EspadaWareFly")

    if not bodyVelocity then
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "EspadaWareFly"
        bodyVelocity.MaxForce = Vector3.new(
            math.huge,
            math.huge,
            math.huge
        )
        bodyVelocity.Parent = root
    end

    local direction = Vector3.zero

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        direction += Camera.CFrame.LookVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        direction -= Camera.CFrame.LookVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        direction -= Camera.CFrame.RightVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        direction += Camera.CFrame.RightVector
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        direction += Vector3.yAxis
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        direction -= Vector3.yAxis
    end

    if direction.Magnitude > 0 then
        direction = direction.Unit
    end

    bodyVelocity.Velocity =
        direction * Config.Movement.FlySpeed
end

--==================================================
-- INFINITE JUMP
--==================================================

UserInputService.JumpRequest:Connect(function()
    if Config.Movement.InfiniteJump then
        local humanoid = getHumanoid()

        if humanoid then
            humanoid:ChangeState(
                Enum.HumanoidStateType.Jumping
            )
        end
    end
end)

--==================================================
-- TARGET HUD
--==================================================

local TargetHUD = Instance.new("Frame")
TargetHUD.AnchorPoint = Vector2.new(.5, 1)
TargetHUD.Position = UDim2.new(.5, 0, 1, -25)
TargetHUD.Size = UDim2.fromOffset(270, 65)
TargetHUD.BackgroundColor3 = Color3.fromRGB(15, 15, 23)
TargetHUD.BackgroundTransparency = .08
TargetHUD.BorderSizePixel = 0
TargetHUD.Visible = false
TargetHUD.Parent = GUI

local targetCorner = Instance.new("UICorner")
targetCorner.CornerRadius = UDim.new(0, 13)
targetCorner.Parent = TargetHUD

local targetStroke = Instance.new("UIStroke")
targetStroke.Color = Config.UI.Accent
targetStroke.Transparency = .6
targetStroke.Parent = TargetHUD

local targetName = Instance.new("TextLabel")
targetName.BackgroundTransparency = 1
targetName.Position = UDim2.fromOffset(14, 9)
targetName.Size = UDim2.new(1, -28, 0, 20)
targetName.Font = Enum.Font.GothamBold
targetName.TextSize = 12
targetName.TextColor3 = Color3.fromRGB(240, 240, 250)
targetName.TextXAlignment = Enum.TextXAlignment.Left
targetName.Parent = TargetHUD

local targetInfo = Instance.new("TextLabel")
targetInfo.BackgroundTransparency = 1
targetInfo.Position = UDim2.fromOffset(14, 31)
targetInfo.Size = UDim2.new(1, -28, 0, 18)
targetInfo.Font = Enum.Font.Gotham
targetInfo.TextSize = 9
targetInfo.TextColor3 = Color3.fromRGB(135, 135, 155)
targetInfo.TextXAlignment = Enum.TextXAlignment.Left
targetInfo.Parent = TargetHUD

local function updateTargetHUD()
    if not Config.Main.TargetHud then
        TargetHUD.Visible = false
        return
    end

    local target = getClosestTarget()

    if not target then
        TargetHUD.Visible = false
        return
    end

    local char = target.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local myRoot = getRoot()

    if not root or not myRoot then
        TargetHUD.Visible = false
        return
    end

    local distance = round(
        (root.Position - myRoot.Position).Magnitude
    )

    local humanoid =
        char:FindFirstChildOfClass("Humanoid")

    local health = humanoid
        and round(humanoid.Health)
        or 0

    targetName.Text = target.DisplayName
    targetInfo.Text =
        "Distance  " .. distance ..
        " studs    •    HP  " .. health

    TargetHUD.Visible = true
end

--==================================================
-- FPS / PING
--==================================================

local StatsHUD = Instance.new("Frame")
StatsHUD.AnchorPoint = Vector2.new(1, 0)
StatsHUD.Position = UDim2.new(1, -20, 0, 20)
StatsHUD.Size = UDim2.fromOffset(130, 48)
StatsHUD.BackgroundTransparency = 1
StatsHUD.Parent = GUI

local statsLabel = Instance.new("TextLabel")
statsLabel.BackgroundTransparency = 1
statsLabel.Size = UDim2.fromScale(1, 1)
statsLabel.Font = Enum.Font.GothamMedium
statsLabel.TextSize = 10
statsLabel.TextColor3 = Color3.fromRGB(205, 205, 220)
statsLabel.TextXAlignment = Enum.TextXAlignment.Right
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Parent = StatsHUD

local frames = 0
local lastFPSUpdate = os.clock()
local currentFPS = 0

RunService.RenderStepped:Connect(function()
    frames += 1

    local now = os.clock()

    if now - lastFPSUpdate >= 1 then
        currentFPS = frames
        frames = 0
        lastFPSUpdate = now
    end

    local lines = {}

    if Config.Visuals.FPS then
        table.insert(lines, "FPS  " .. tostring(currentFPS))
    end

    if Config.Visuals.Ping then
        local ping = 0

        pcall(function()
            ping = Stats
                :GetNetworkPing()
                * 1000
        end)

        table.insert(
            lines,
            "PING  " .. tostring(round(ping)) .. " ms"
        )
    end

    statsLabel.Text = table.concat(lines, "\n")
end)

--==================================================
-- MUSIC
--==================================================

local Music = Instance.new("Sound")
Music.Name = "EspadaWareMusic"
Music.Looped = true
Music.Volume = Config.Settings.MusicVolume
Music.SoundId = ""
Music.Parent = SoundService

local function updateMusic()
    Music.Volume = Config.Settings.MusicVolume

    -- SoundId intentionally left empty.
    -- Put your own Roblox audio asset ID here if desired.

    if Config.Settings.Music and Music.SoundId ~= "" then
        if not Music.IsPlaying then
            Music:Play()
        end
    else
        if Music.IsPlaying then
            Music:Stop()
        end
    end
end

--==================================================
-- GUI KEYBIND
--==================================================

local function setGUIVisible(state)
    Config.UI.Open = state

    if state then
        Main.Visible = true

        Main.Size = UDim2.fromOffset(850, 530)

        tween(Main, .25, {
            Size = UDim2.fromOffset(900, 570),
            BackgroundTransparency = Config.UI.Transparency
        })
    else
        tween(Main, .22, {
            Size = UDim2.fromOffset(850, 530),
            BackgroundTransparency = 1
        })

        task.delay(.23, function()
            if not Config.UI.Open then
                Main.Visible = false
            end
        end)
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Config.UI.Keybind then
        setGUIVisible(not Config.UI.Open)
    end
end)

--==================================================
-- DRAG WINDOW
--==================================================

local dragging = false
local dragStart
local startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

--==================================================
-- MAIN LOOP
--==================================================

local updateAccumulator = 0

RunService.RenderStepped:Connect(function(dt)
    updateAccumulator += dt

    updateAim()
    updateTriggerBot(dt)
    updateMovement()
    updateFly()
    updateLighting()
    updateMusic()

    if updateAccumulator >= .1 then
        updateAccumulator = 0
        updateESP()
        updateTargetHUD()
    end
end)

--==================================================
-- RESPAWN HANDLING
--==================================================

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(.5)

    local humanoid = getHumanoid()

    if humanoid then
        if Config.Movement.Speed then
            humanoid.WalkSpeed = Config.Movement.SpeedValue
        end

        if Config.Movement.Jump then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = Config.Movement.JumpValue
        end
    end
end)

--==================================================
-- INITIAL STATE
--==================================================

showPage("Main")

task.delay(.5, function()
    notify("EspadaWare initialized")
end)

--==================================================
-- END
--==================================================
