-- EspadaWare | Premium Cheat GUI
-- LocalScript (StarterPlayerScripts или вставить через эксплоит)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local Stats = game:GetService("Stats")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- ═══════════════════════════════════════════
-- CONFIG SYSTEM
-- ═══════════════════════════════════════════
local DEFAULT_CONFIG = {
	-- AimBot
	AimBot_Enabled = false,
	AimBot_FOV = 120,
	AimBot_Smoothness = 5,
	AimBot_TargetPart = "Head",
	AimBot_TeamCheck = true,
	AimBot_WallCheck = true,
	AimBot_ShowFOV = true,
	AimBot_KeyBind = "MouseButton2",

	-- Silent Aim
	SilentAim_Enabled = false,
	SilentAim_FOV = 150,
	SilentAim_HitChance = 100,
	SilentAim_TargetPart = "Head",
	SilentAim_TeamCheck = true,
	SilentAim_ShowFOV = false,

	-- TriggerBot
	TriggerBot_Enabled = false,
	TriggerBot_Delay = 0.05,
	TriggerBot_TeamCheck = true,
	TriggerBot_MaxDistance = 500,
	TriggerBot_TargetPart = "Head",

	-- ESP
	ESP_Enabled = false,
	ESP_Boxes = true,
	ESP_Names = true,
	ESP_Health = true,
	ESP_Distance = true,
	ESP_Tracers = false,
	ESP_TeamCheck = true,
	ESP_MaxDistance = 1000,
	ESP_BoxColor = {0, 1, 0.4},
	ESP_TracerOrigin = "Bottom",
	ESP_Chams = false,
	ESP_Skeletons = false,

	-- Noclip
	Noclip_Enabled = false,
	Noclip_KeyBind = "N",

	-- Speed
	Speed_Enabled = false,
	Speed_Value = 32,

	-- Jump
	Jump_Enabled = false,
	Jump_Value = 50,

	-- Infinity Jump
	InfJump_Enabled = false,

	-- Fly
	Fly_Enabled = false,
	Fly_Speed = 50,
	Fly_KeyBind = "F",

	-- Music
	Music_Enabled = false,
	Music_Volume = 0.5,
	Music_CurrentID = "",

	-- Fullbright
	Fullbright_Enabled = false,

	-- Skybox
	Skybox_Enabled = false,
	Skybox_ID = "",

	-- Show FPS
	ShowFPS_Enabled = false,

	-- Show Ping
	ShowPing_Enabled = false,

	-- Target HUD
	TargetHUD_Enabled = false,

	-- Invisibility
	Invisibility_Enabled = false,

	-- Anti AFK
	AntiAFK_Enabled = true,

	-- ClickTP
	ClickTP_Enabled = false,
	ClickTP_KeyBind = "T",

	-- No Fall Damage
	NoFallDamage_Enabled = false,

	-- Low Gravity
	LowGravity_Enabled = false,
	LowGravity_Value = 80,

	-- FOV Changer
	FOVChanger_Enabled = false,
	FOVChanger_Value = 70,

	-- Hitbox Expander
	HitboxExpander_Enabled = false,
	HitboxExpander_Size = 10,

	-- Auto Respawn
	AutoRespawn_Enabled = false,

	-- GUI
	GUI_Scale = 1,
	GUI_ToggleKey = "RightShift",
	GUI_Transparency = 0,
	GUI_Notifications = true,
	GUI_AccentColor = {0, 0.85, 0.4},
}

local Config = {}
for k, v in pairs(DEFAULT_CONFIG) do
	if type(v) == "table" then
		Config[k] = {unpack(v)}
	else
		Config[k] = v
	end
end

local CONFIG_KEY = "EspadaWare_Config_v3"

local function SaveConfig()
	pcall(function()
		if writefile then
			writefile(CONFIG_KEY .. ".json", HttpService:JSONEncode(Config))
		end
	end)
end

local function LoadConfig()
	pcall(function()
		if readfile and isfile and isfile(CONFIG_KEY .. ".json") then
			local data = HttpService:JSONDecode(readfile(CONFIG_KEY .. ".json"))
			for k, v in pairs(data) do
				Config[k] = v
			end
		end
	end)
end

local function ResetConfig()
	for k, v in pairs(DEFAULT_CONFIG) do
		if type(v) == "table" then
			Config[k] = {unpack(v)}
		else
			Config[k] = v
		end
	end
	SaveConfig()
end

LoadConfig()

-- Auto-save every 30 seconds
task.spawn(function()
	while true do
		task.wait(30)
		SaveConfig()
	end
end)

-- ═══════════════════════════════════════════
-- COLOR PALETTE
-- ═══════════════════════════════════════════
local Colors = {
	Background = Color3.fromRGB(12, 12, 16),
	Surface = Color3.fromRGB(18, 18, 24),
	SurfaceLight = Color3.fromRGB(24, 24, 32),
	SurfaceLighter = Color3.fromRGB(32, 32, 42),
	Card = Color3.fromRGB(20, 22, 28),
	CardHover = Color3.fromRGB(26, 28, 36),
	Accent = Color3.fromRGB(0, 220, 100),
	AccentDark = Color3.fromRGB(0, 180, 80),
	AccentGlow = Color3.fromRGB(0, 255, 120),
	AccentSoft = Color3.fromRGB(0, 220, 100),
	Text = Color3.fromRGB(240, 240, 245),
	TextDim = Color3.fromRGB(140, 145, 160),
	TextMuted = Color3.fromRGB(80, 85, 100),
	Danger = Color3.fromRGB(255, 60, 70),
	Warning = Color3.fromRGB(255, 180, 40),
	Success = Color3.fromRGB(0, 220, 100),
	Border = Color3.fromRGB(35, 38, 48),
	Shadow = Color3.fromRGB(0, 0, 0),
	White = Color3.fromRGB(255, 255, 255),
	KeyBG = Color3.fromRGB(8, 10, 14),
}

-- ═══════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════
local function Tween(obj, props, duration, style, direction)
	local tween = TweenService:Create(obj, TweenInfo.new(
		duration or 0.3,
		style or Enum.EasingStyle.Quart,
		direction or Enum.EasingDirection.Out
	), props)
	tween:Play()
	return tween
end

local function CreateShadow(parent, size, transparency)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://6014261993"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = transparency or 0.5
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.Size = UDim2.new(1, size or 40, 1, size or 40)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.ZIndex = parent.ZIndex - 1
	shadow.Parent = parent
	return shadow
end

local function CreateCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function CreateStroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Colors.Border
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function CreatePadding(parent, t, b, l, r)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.PaddingLeft = UDim.new(0, l or 0)
	p.PaddingRight = UDim.new(0, r or 0)
	p.Parent = parent
	return p
end

local function CreateGradient(parent, c1, c2, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1, c2)
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

local function RippleEffect(button)
	local ripple = Instance.new("Frame")
	ripple.Name = "Ripple"
	ripple.BackgroundColor3 = Colors.AccentGlow
	ripple.BackgroundTransparency = 0.7
	ripple.BorderSizePixel = 0
	ripple.ZIndex = button.ZIndex + 5
	ripple.AnchorPoint = Vector2.new(0.5, 0.5)

	local mousePos = UserInputService:GetMouseLocation()
	local relX = mousePos.X - button.AbsolutePosition.X
	local relY = mousePos.Y - button.AbsolutePosition.Y
	ripple.Position = UDim2.new(0, relX, 0, relY)
	ripple.Size = UDim2.new(0, 0, 0, 0)
	CreateCorner(ripple, 200)
	ripple.Parent = button

	local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
	Tween(ripple, {
		Size = UDim2.new(0, maxSize, 0, maxSize),
		BackgroundTransparency = 1
	}, 0.6, Enum.EasingStyle.Quart)

	task.delay(0.6, function()
		ripple:Destroy()
	end)
end

-- ═══════════════════════════════════════════
-- DESTROY OLD GUI
-- ═══════════════════════════════════════════
if Player.PlayerGui:FindFirstChild("EspadaWare") then
	Player.PlayerGui:FindFirstChild("EspadaWare"):Destroy()
end

-- ═══════════════════════════════════════════
-- CREATE MAIN SCREENGUI
-- ═══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EspadaWare"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = Player.PlayerGui

-- ═══════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════
local NotifContainer = Instance.new("Frame")
NotifContainer.Name = "Notifications"
NotifContainer.BackgroundTransparency = 1
NotifContainer.Size = UDim2.new(0, 320, 1, 0)
NotifContainer.Position = UDim2.new(1, -330, 0, 0)
NotifContainer.ZIndex = 100
NotifContainer.Parent = ScreenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Padding = UDim.new(0, 8)
notifLayout.Parent = NotifContainer

CreatePadding(NotifContainer, 0, 20, 0, 0)

local function Notify(title, message, duration, ntype)
	if not Config.GUI_Notifications then return end
	ntype = ntype or "info"
	duration = duration or 3

	local colors = {
		info = Colors.Accent,
		success = Colors.Success,
		warning = Colors.Warning,
		error = Colors.Danger,
	}

	local icons = {
		info = "rbxassetid://7733960981",
		success = "rbxassetid://7733715400",
		warning = "rbxassetid://7734009413",
		error = "rbxassetid://7733658504",
	}

	local notif = Instance.new("Frame")
	notif.Name = "Notification"
	notif.BackgroundColor3 = Colors.Surface
	notif.Size = UDim2.new(1, 0, 0, 72)
	notif.ClipsDescendants = true
	notif.ZIndex = 101
	notif.Parent = NotifContainer
	CreateCorner(notif, 10)
	CreateStroke(notif, colors[ntype] or Colors.Accent, 1, 0.6)
	CreateShadow(notif, 30, 0.6)

	-- Accent bar
	local bar = Instance.new("Frame")
	bar.Name = "AccentBar"
	bar.BackgroundColor3 = colors[ntype] or Colors.Accent
	bar.Size = UDim2.new(0, 3, 1, 0)
	bar.Position = UDim2.new(0, 0, 0, 0)
	bar.BorderSizePixel = 0
	bar.ZIndex = 102
	bar.Parent = notif
	CreateCorner(bar, 2)

	-- Icon
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Image = icons[ntype] or icons.info
	icon.ImageColor3 = colors[ntype] or Colors.Accent
	icon.Size = UDim2.new(0, 22, 0, 22)
	icon.Position = UDim2.new(0, 14, 0, 14)
	icon.ZIndex = 102
	icon.Parent = notif

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 13
	titleLabel.TextColor3 = Colors.Text
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Size = UDim2.new(1, -50, 0, 18)
	titleLabel.Position = UDim2.new(0, 44, 0, 12)
	titleLabel.ZIndex = 102
	titleLabel.Parent = notif

	-- Message
	local msgLabel = Instance.new("TextLabel")
	msgLabel.Name = "Message"
	msgLabel.BackgroundTransparency = 1
	msgLabel.Text = message
	msgLabel.Font = Enum.Font.Gotham
	msgLabel.TextSize = 11
	msgLabel.TextColor3 = Colors.TextDim
	msgLabel.TextXAlignment = Enum.TextXAlignment.Left
	msgLabel.TextWrapped = true
	msgLabel.Size = UDim2.new(1, -50, 0, 30)
	msgLabel.Position = UDim2.new(0, 44, 0, 32)
	msgLabel.ZIndex = 102
	msgLabel.Parent = notif

	-- Progress bar
	local progress = Instance.new("Frame")
	progress.Name = "Progress"
	progress.BackgroundColor3 = colors[ntype] or Colors.Accent
	progress.BackgroundTransparency = 0.6
	progress.Size = UDim2.new(1, 0, 0, 2)
	progress.Position = UDim2.new(0, 0, 1, -2)
	progress.BorderSizePixel = 0
	progress.ZIndex = 102
	progress.Parent = notif

	-- Animate in
	notif.BackgroundTransparency = 1
	titleLabel.TextTransparency = 1
	msgLabel.TextTransparency = 1
	icon.ImageTransparency = 1
	bar.BackgroundTransparency = 1

	Tween(notif, {BackgroundTransparency = 0}, 0.3)
	Tween(titleLabel, {TextTransparency = 0}, 0.3)
	Tween(msgLabel, {TextTransparency = 0}, 0.3)
	Tween(icon, {ImageTransparency = 0}, 0.3)
	Tween(bar, {BackgroundTransparency = 0}, 0.3)

	Tween(progress, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

	task.delay(duration, function()
		Tween(notif, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)}, 0.3)
		Tween(titleLabel, {TextTransparency = 1}, 0.3)
		Tween(msgLabel, {TextTransparency = 1}, 0.3)
		Tween(icon, {ImageTransparency = 1}, 0.3)
		Tween(bar, {BackgroundTransparency = 1}, 0.3)
		task.wait(0.35)
		notif:Destroy()
	end)
end

-- ═══════════════════════════════════════════
-- KEY SYSTEM
-- ═══════════════════════════════════════════
local VALID_KEYS = {"EspadaFreeVersion"}
local keyVerified = false

local KeyFrame = Instance.new("Frame")
KeyFrame.Name = "KeySystem"
KeyFrame.BackgroundColor3 = Colors.KeyBG
KeyFrame.Size = UDim2.new(1, 0, 1, 0)
KeyFrame.ZIndex = 200
KeyFrame.Parent = ScreenGui

-- Animated background particles
local function CreateParticle()
	local p = Instance.new("Frame")
	p.BackgroundColor3 = Colors.Accent
	p.BackgroundTransparency = math.random(85, 95) / 100
	p.BorderSizePixel = 0
	local s = math.random(2, 6)
	p.Size = UDim2.new(0, s, 0, s)
	p.Position = UDim2.new(math.random() * 1, 0, 1.05, 0)
	p.ZIndex = 201
	CreateCorner(p, 100)
	p.Parent = KeyFrame

	local dur = math.random(40, 80) / 10
	Tween(p, {
		Position = UDim2.new(math.random() * 1, 0, -0.05, 0),
		BackgroundTransparency = 1,
		Rotation = math.random(-180, 180)
	}, dur, Enum.EasingStyle.Linear)

	task.delay(dur, function()
		p:Destroy()
	end)
end

task.spawn(function()
	while KeyFrame and KeyFrame.Parent and not keyVerified do
		CreateParticle()
		task.wait(0.15)
	end
end)

-- Key card
local KeyCard = Instance.new("Frame")
KeyCard.Name = "KeyCard"
KeyCard.BackgroundColor3 = Colors.Surface
KeyCard.Size = UDim2.new(0, 420, 0, 340)
KeyCard.Position = UDim2.new(0.5, 0, 0.5, 0)
KeyCard.AnchorPoint = Vector2.new(0.5, 0.5)
KeyCard.ZIndex = 210
KeyCard.Parent = KeyFrame
CreateCorner(KeyCard, 16)
CreateStroke(KeyCard, Colors.Accent, 1, 0.5)
CreateShadow(KeyCard, 60, 0.4)

-- Glow effect behind card
local glow = Instance.new("ImageLabel")
glow.Name = "Glow"
glow.BackgroundTransparency = 1
glow.Image = "rbxassetid://6014261993"
glow.ImageColor3 = Colors.Accent
glow.ImageTransparency = 0.85
glow.ScaleType = Enum.ScaleType.Slice
glow.SliceCenter = Rect.new(49, 49, 450, 450)
glow.Size = UDim2.new(1, 120, 1, 120)
glow.Position = UDim2.new(0.5, 0, 0.5, 0)
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.ZIndex = 209
glow.Parent = KeyCard

-- Pulsing glow
task.spawn(function()
	while KeyCard and KeyCard.Parent and not keyVerified do
		Tween(glow, {ImageTransparency = 0.75}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.wait(1.5)
		Tween(glow, {ImageTransparency = 0.9}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.wait(1.5)
	end
end)

-- Logo icon
local logoIcon = Instance.new("ImageLabel")
logoIcon.Name = "Logo"
logoIcon.BackgroundTransparency = 1
logoIcon.Image = "rbxassetid://7734053495" -- Shield icon
logoIcon.ImageColor3 = Colors.Accent
logoIcon.Size = UDim2.new(0, 48, 0, 48)
logoIcon.Position = UDim2.new(0.5, 0, 0, 35)
logoIcon.AnchorPoint = Vector2.new(0.5, 0)
logoIcon.ZIndex = 211
logoIcon.Parent = KeyCard

-- Title
local keyTitle = Instance.new("TextLabel")
keyTitle.Name = "Title"
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "EspadaWare"
keyTitle.Font = Enum.Font.GothamBlack
keyTitle.TextSize = 28
keyTitle.TextColor3 = Colors.Text
keyTitle.Size = UDim2.new(1, 0, 0, 30)
keyTitle.Position = UDim2.new(0, 0, 0, 92)
keyTitle.ZIndex = 211
keyTitle.Parent = KeyCard

-- Accent under title
local accentLine = Instance.new("Frame")
accentLine.BackgroundColor3 = Colors.Accent
accentLine.Size = UDim2.new(0, 60, 0, 3)
accentLine.Position = UDim2.new(0.5, 0, 0, 128)
accentLine.AnchorPoint = Vector2.new(0.5, 0)
accentLine.BorderSizePixel = 0
accentLine.ZIndex = 211
accentLine.Parent = KeyCard
CreateCorner(accentLine, 2)

-- Subtitle
local keySub = Instance.new("TextLabel")
keySub.Name = "Subtitle"
keySub.BackgroundTransparency = 1
keySub.Text = "Enter your license key to continue"
keySub.Font = Enum.Font.Gotham
keySub.TextSize = 12
keySub.TextColor3 = Colors.TextDim
keySub.Size = UDim2.new(1, 0, 0, 20)
keySub.Position = UDim2.new(0, 0, 0, 140)
keySub.ZIndex = 211
keySub.Parent = KeyCard

-- Input container
local inputBG = Instance.new("Frame")
inputBG.Name = "InputBG"
inputBG.BackgroundColor3 = Colors.SurfaceLight
inputBG.Size = UDim2.new(0, 320, 0, 46)
inputBG.Position = UDim2.new(0.5, 0, 0, 180)
inputBG.AnchorPoint = Vector2.new(0.5, 0)
inputBG.ZIndex = 211
inputBG.Parent = KeyCard
CreateCorner(inputBG, 10)
CreateStroke(inputBG, Colors.Border, 1, 0.3)

-- Lock icon
local lockIcon = Instance.new("ImageLabel")
lockIcon.Name = "LockIcon"
lockIcon.BackgroundTransparency = 1
lockIcon.Image = "rbxassetid://7733658504"
lockIcon.ImageColor3 = Colors.TextMuted
lockIcon.Size = UDim2.new(0, 18, 0, 18)
lockIcon.Position = UDim2.new(0, 14, 0.5, 0)
lockIcon.AnchorPoint = Vector2.new(0, 0.5)
lockIcon.ZIndex = 212
lockIcon.Parent = inputBG

-- TextBox
local keyInput = Instance.new("TextBox")
keyInput.Name = "KeyInput"
keyInput.BackgroundTransparency = 1
keyInput.PlaceholderText = "Enter key..."
keyInput.PlaceholderColor3 = Colors.TextMuted
keyInput.Text = ""
keyInput.Font = Enum.Font.GothamMedium
keyInput.TextSize = 14
keyInput.TextColor3 = Colors.Text
keyInput.ClearTextOnFocus = false
keyInput.Size = UDim2.new(1, -50, 1, 0)
keyInput.Position = UDim2.new(0, 40, 0, 0)
keyInput.ZIndex = 212
keyInput.Parent = inputBG

-- Focus effect
keyInput.Focused:Connect(function()
	local stroke = inputBG:FindFirstChildOfClass("UIStroke")
	if stroke then
		Tween(stroke, {Color = Colors.Accent, Transparency = 0}, 0.2)
	end
end)

keyInput.FocusLost:Connect(function()
	local stroke = inputBG:FindFirstChildOfClass("UIStroke")
	if stroke then
		Tween(stroke, {Color = Colors.Border, Transparency = 0.3}, 0.2)
	end
end)

-- Verify button
local verifyBtn = Instance.new("TextButton")
verifyBtn.Name = "VerifyButton"
verifyBtn.BackgroundColor3 = Colors.Accent
verifyBtn.Size = UDim2.new(0, 320, 0, 46)
verifyBtn.Position = UDim2.new(0.5, 0, 0, 244)
verifyBtn.AnchorPoint = Vector2.new(0.5, 0)
verifyBtn.Text = ""
verifyBtn.ZIndex = 211
verifyBtn.AutoButtonColor = false
verifyBtn.Parent = KeyCard
CreateCorner(verifyBtn, 10)
CreateShadow(verifyBtn, 20, 0.7)

CreateGradient(verifyBtn, Colors.AccentGlow, Colors.AccentDark, 90)

local verifyText = Instance.new("TextLabel")
verifyText.BackgroundTransparency = 1
verifyText.Text = "⚡  Verify Key"
verifyText.Font = Enum.Font.GothamBold
verifyText.TextSize = 15
verifyText.TextColor3 = Colors.Background
verifyText.Size = UDim2.new(1, 0, 1, 0)
verifyText.ZIndex = 212
verifyText.Parent = verifyBtn

-- Error label
local errorLabel = Instance.new("TextLabel")
errorLabel.Name = "Error"
errorLabel.BackgroundTransparency = 1
errorLabel.Text = ""
errorLabel.Font = Enum.Font.Gotham
errorLabel.TextSize = 11
errorLabel.TextColor3 = Colors.Danger
errorLabel.Size = UDim2.new(1, 0, 0, 16)
errorLabel.Position = UDim2.new(0, 0, 0, 296)
errorLabel.ZIndex = 211
errorLabel.Parent = KeyCard

-- Hover effects
verifyBtn.MouseEnter:Connect(function()
	Tween(verifyBtn, {Size = UDim2.new(0, 326, 0, 48)}, 0.15)
end)

verifyBtn.MouseLeave:Connect(function()
	Tween(verifyBtn, {Size = UDim2.new(0, 320, 0, 46)}, 0.15)
end)

-- Verify logic
verifyBtn.MouseButton1Click:Connect(function()
	RippleEffect(verifyBtn)

	local key = keyInput.Text:gsub("%s+", "")
	local valid = false
	for _, k in ipairs(VALID_KEYS) do
		if key == k then valid = true break end
	end

	if valid then
		keyVerified = true
		errorLabel.Text = ""
		verifyText.Text = "✓  Verified!"

		Tween(KeyCard, {BackgroundTransparency = 0}, 0.1)

		-- Success animation
		local successGlow = Instance.new("Frame")
		successGlow.BackgroundColor3 = Colors.AccentGlow
		successGlow.BackgroundTransparency = 0.8
		successGlow.Size = UDim2.new(0, 0, 0, 0)
		successGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
		successGlow.AnchorPoint = Vector2.new(0.5, 0.5)
		successGlow.ZIndex = 220
		successGlow.BorderSizePixel = 0
		CreateCorner(successGlow, 500)
		successGlow.Parent = KeyFrame

		Tween(successGlow, {
			Size = UDim2.new(3, 0, 3, 0),
			BackgroundTransparency = 1
		}, 1, Enum.EasingStyle.Quart)

		task.wait(0.5)
		Tween(KeyFrame, {BackgroundTransparency = 1}, 0.5)
		Tween(KeyCard, {
			Position = UDim2.new(0.5, 0, 0.5, -30),
			BackgroundTransparency = 1
		}, 0.5)

		for _, child in ipairs(KeyCard:GetDescendants()) do
			pcall(function()
				if child:IsA("TextLabel") or child:IsA("TextBox") then
					Tween(child, {TextTransparency = 1}, 0.4)
				elseif child:IsA("ImageLabel") then
					Tween(child, {ImageTransparency = 1}, 0.4)
				elseif child:IsA("Frame") then
					Tween(child, {BackgroundTransparency = 1}, 0.4)
				end
			end)
		end

		task.wait(0.6)
		KeyFrame:Destroy()
		Notify("EspadaWare", "Welcome! GUI loaded successfully.", 4, "success")
	else
		errorLabel.Text = "✗  Invalid key. Please try again."
		Tween(errorLabel, {TextTransparency = 0}, 0.2)

		-- Shake animation
		local orig = KeyCard.Position
		for i = 1, 6 do
			local offset = (i % 2 == 0) and 8 or -8
			Tween(KeyCard, {Position = UDim2.new(0.5, offset, 0.5, 0)}, 0.05, Enum.EasingStyle.Linear)
			task.wait(0.05)
		end
		Tween(KeyCard, {Position = orig}, 0.05, Enum.EasingStyle.Linear)

		Tween(inputBG:FindFirstChildOfClass("UIStroke"), {Color = Colors.Danger}, 0.2)
		task.wait(1)
		pcall(function()
			Tween(inputBG:FindFirstChildOfClass("UIStroke"), {Color = Colors.Border}, 0.3)
		end)
	end
end)

-- ═══════════════════════════════════════════
-- MAIN GUI
-- ═══════════════════════════════════════════
local MainGui = Instance.new("Frame")
MainGui.Name = "MainGUI"
MainGui.BackgroundTransparency = 1
MainGui.Size = UDim2.new(1, 0, 1, 0)
MainGui.Visible = false
MainGui.ZIndex = 1
MainGui.Parent = ScreenGui

-- Wait for key verification
task.spawn(function()
	while not keyVerified do task.wait(0.1) end
	task.wait(0.3)
	MainGui.Visible = true
end)

-- Main window
local Window = Instance.new("Frame")
Window.Name = "Window"
Window.BackgroundColor3 = Colors.Background
Window.Size = UDim2.new(0, 680, 0, 480)
Window.Position = UDim2.new(0.5, 0, 0.5, 0)
Window.AnchorPoint = Vector2.new(0.5, 0.5)
Window.ClipsDescendants = true
Window.ZIndex = 10
Window.Parent = MainGui
CreateCorner(Window, 12)
CreateStroke(Window, Colors.Border, 1, 0.4)
CreateShadow(Window, 80, 0.5)

-- Open animation
Window.Size = UDim2.new(0, 680, 0, 0)
Window.BackgroundTransparency = 1
task.spawn(function()
	while not keyVerified do task.wait(0.1) end
	task.wait(0.4)
	Tween(Window, {Size = UDim2.new(0, 680, 0, 480), BackgroundTransparency = 0}, 0.6, Enum.EasingStyle.Back)
end)

-- ═══════════════════════════════════════════
-- DRAGGING SYSTEM
-- ═══════════════════════════════════════════
local dragging = false
local dragStart, startPos

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.BackgroundColor3 = Colors.Surface
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.ZIndex = 11
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Window

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = TitleBar

-- Fix bottom corners
local titleFix = Instance.new("Frame")
titleFix.BackgroundColor3 = Colors.Surface
titleFix.Size = UDim2.new(1, 0, 0, 14)
titleFix.Position = UDim2.new(0, 0, 1, -14)
titleFix.BorderSizePixel = 0
titleFix.ZIndex = 11
titleFix.Parent = TitleBar

-- Bottom border
local titleBorder = Instance.new("Frame")
titleBorder.BackgroundColor3 = Colors.Border
titleBorder.Size = UDim2.new(1, 0, 0, 1)
titleBorder.Position = UDim2.new(0, 0, 1, 0)
titleBorder.BorderSizePixel = 0
titleBorder.ZIndex = 11
titleBorder.Parent = TitleBar

-- Logo
local titleLogo = Instance.new("ImageLabel")
titleLogo.BackgroundTransparency = 1
titleLogo.Image = "rbxassetid://7734053495"
titleLogo.ImageColor3 = Colors.Accent
titleLogo.Size = UDim2.new(0, 20, 0, 20)
titleLogo.Position = UDim2.new(0, 14, 0.5, 0)
titleLogo.AnchorPoint = Vector2.new(0, 0.5)
titleLogo.ZIndex = 12
titleLogo.Parent = TitleBar

-- Title text
local titleText = Instance.new("TextLabel")
titleText.BackgroundTransparency = 1
titleText.Text = "EspadaWare"
titleText.Font = Enum.Font.GothamBlack
titleText.TextSize = 15
titleText.TextColor3 = Colors.Text
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Size = UDim2.new(0, 120, 1, 0)
titleText.Position = UDim2.new(0, 40, 0, 0)
titleText.ZIndex = 12
titleText.Parent = TitleBar

-- Version badge
local versionBadge = Instance.new("Frame")
versionBadge.BackgroundColor3 = Colors.Accent
versionBadge.BackgroundTransparency = 0.85
versionBadge.Size = UDim2.new(0, 42, 0, 18)
versionBadge.Position = UDim2.new(0, 150, 0.5, 0)
versionBadge.AnchorPoint = Vector2.new(0, 0.5)
versionBadge.ZIndex = 12
versionBadge.Parent = TitleBar
CreateCorner(versionBadge, 4)

local versionText = Instance.new("TextLabel")
versionText.BackgroundTransparency = 1
versionText.Text = "v2.1"
versionText.Font = Enum.Font.GothamBold
versionText.TextSize = 10
versionText.TextColor3 = Colors.Accent
versionText.Size = UDim2.new(1, 0, 1, 0)
versionText.ZIndex = 13
versionText.Parent = versionBadge

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.BackgroundColor3 = Colors.Danger
closeBtn.BackgroundTransparency = 0.9
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.TextColor3 = Colors.TextDim
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 12
closeBtn.Parent = TitleBar
CreateCorner(closeBtn, 6)

closeBtn.MouseEnter:Connect(function()
	Tween(closeBtn, {BackgroundTransparency = 0.3, TextColor3 = Colors.Danger}, 0.15)
end)
closeBtn.MouseLeave:Connect(function()
	Tween(closeBtn, {BackgroundTransparency = 0.9, TextColor3 = Colors.TextDim}, 0.15)
end)

-- Minimize button
local minBtn = Instance.new("TextButton")
minBtn.Name = "Minimize"
minBtn.BackgroundColor3 = Colors.Warning
minBtn.BackgroundTransparency = 0.9
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -68, 0.5, 0)
minBtn.AnchorPoint = Vector2.new(0, 0.5)
minBtn.Text = "—"
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 12
minBtn.TextColor3 = Colors.TextDim
minBtn.AutoButtonColor = false
minBtn.ZIndex = 12
minBtn.Parent = TitleBar
CreateCorner(minBtn, 6)

minBtn.MouseEnter:Connect(function()
	Tween(minBtn, {BackgroundTransparency = 0.3, TextColor3 = Colors.Warning}, 0.15)
end)
minBtn.MouseLeave:Connect(function()
	Tween(minBtn, {BackgroundTransparency = 0.9, TextColor3 = Colors.TextDim}, 0.15)
end)

-- Drag
TitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Window.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- Close/minimize logic
local guiVisible = true
closeBtn.MouseButton1Click:Connect(function()
	RippleEffect(closeBtn)
	Tween(Window, {Size = UDim2.new(0, 680, 0, 0), BackgroundTransparency = 1}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	task.wait(0.45)
	guiVisible = false
	Window.Visible = false
end)

minBtn.MouseButton1Click:Connect(function()
	RippleEffect(minBtn)
	Tween(Window, {Size = UDim2.new(0, 680, 0, 42)}, 0.3, Enum.EasingStyle.Quart)
	task.wait(0.3)
	guiVisible = false
	Window.Visible = false
end)

-- ═══════════════════════════════════════════
-- SIDEBAR
-- ═══════════════════════════════════════════
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.BackgroundColor3 = Colors.Surface
Sidebar.Size = UDim2.new(0, 160, 1, -42)
Sidebar.Position = UDim2.new(0, 0, 0, 42)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 11
Sidebar.Parent = Window

-- Sidebar right border
local sidebarBorder = Instance.new("Frame")
sidebarBorder.BackgroundColor3 = Colors.Border
sidebarBorder.Size = UDim2.new(0, 1, 1, 0)
sidebarBorder.Position = UDim2.new(1, 0, 0, 0)
sidebarBorder.BorderSizePixel = 0
sidebarBorder.ZIndex = 12
sidebarBorder.Parent = Sidebar

CreatePadding(Sidebar, 12, 12, 10, 10)

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Padding = UDim.new(0, 4)
sidebarLayout.Parent = Sidebar

-- Tab data
local TabData = {
	{Name = "Main", Icon = "rbxassetid://7733960981", Order = 1},
	{Name = "Movement", Icon = "rbxassetid://7734053495", Order = 2},
	{Name = "Visuals", Icon = "rbxassetid://7734009413", Order = 3},
	{Name = "Settings", Icon = "rbxassetid://7733715400", Order = 4},
}

local TabButtons = {}
local TabPages = {}
local CurrentTab = "Main"

for _, tab in ipairs(TabData) do
	local btn = Instance.new("TextButton")
	btn.Name = tab.Name .. "Tab"
	btn.BackgroundColor3 = Colors.Accent
	btn.BackgroundTransparency = 1
	btn.Size = UDim2.new(1, 0, 0, 38)
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.LayoutOrder = tab.Order
	btn.ZIndex = 12
	btn.Parent = Sidebar
	CreateCorner(btn, 8)

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Image = tab.Icon
	icon.ImageColor3 = Colors.TextDim
	icon.Size = UDim2.new(0, 18, 0, 18)
	icon.Position = UDim2.new(0, 12, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.ZIndex = 13
	icon.Parent = btn

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Text = tab.Name
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextColor3 = Colors.TextDim
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Size = UDim2.new(1, -40, 1, 0)
	label.Position = UDim2.new(0, 38, 0, 0)
	label.ZIndex = 13
	label.Parent = btn

	-- Active indicator
	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.BackgroundColor3 = Colors.Accent
	indicator.Size = UDim2.new(0, 3, 0, 0)
	indicator.Position = UDim2.new(0, 0, 0.5, 0)
	indicator.AnchorPoint = Vector2.new(0, 0.5)
	indicator.BorderSizePixel = 0
	indicator.ZIndex = 14
	indicator.Parent = btn
	CreateCorner(indicator, 2)

	TabButtons[tab.Name] = btn

	btn.MouseEnter:Connect(function()
		if CurrentTab ~= tab.Name then
			Tween(btn, {BackgroundTransparency = 0.9}, 0.15)
		end
	end)

	btn.MouseLeave:Connect(function()
		if CurrentTab ~= tab.Name then
			Tween(btn, {BackgroundTransparency = 1}, 0.15)
		end
	end)
end

-- ═══════════════════════════════════════════
-- CONTENT AREA
-- ═══════════════════════════════════════════
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.BackgroundTransparency = 1
ContentArea.Size = UDim2.new(1, -161, 1, -42)
ContentArea.Position = UDim2.new(0, 161, 0, 42)
ContentArea.ZIndex = 10
ContentArea.ClipsDescendants = true
ContentArea.Parent = Window

-- Settings panel (overlay)
local SettingsPanel = Instance.new("Frame")
SettingsPanel.Name = "SettingsPanel"
SettingsPanel.BackgroundColor3 = Colors.Background
SettingsPanel.Size = UDim2.new(0, 280, 1, 0)
SettingsPanel.Position = UDim2.new(1, 0, 0, 0)
SettingsPanel.ZIndex = 50
SettingsPanel.ClipsDescendants = true
SettingsPanel.Visible = false
SettingsPanel.Parent = ContentArea
CreateCorner(SettingsPanel, 0)

local settingsBorder = Instance.new("Frame")
settingsBorder.BackgroundColor3 = Colors.Border
settingsBorder.Size = UDim2.new(0, 1, 1, 0)
settingsBorder.Position = UDim2.new(0, 0, 0, 0)
settingsBorder.BorderSizePixel = 0
settingsBorder.ZIndex = 51
settingsBorder.Parent = SettingsPanel

local settingsTitle = Instance.new("TextLabel")
settingsTitle.Name = "Title"
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "Settings"
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextSize = 16
settingsTitle.TextColor3 = Colors.Text
settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
settingsTitle.Size = UDim2.new(1, -60, 0, 40)
settingsTitle.Position = UDim2.new(0, 16, 0, 0)
settingsTitle.ZIndex = 52
settingsTitle.Parent = SettingsPanel

local settingsCloseBtn = Instance.new("TextButton")
settingsCloseBtn.Name = "Close"
settingsCloseBtn.BackgroundTransparency = 1
settingsCloseBtn.Text = "✕"
settingsCloseBtn.Font = Enum.Font.GothamBold
settingsCloseBtn.TextSize = 14
settingsCloseBtn.TextColor3 = Colors.TextDim
settingsCloseBtn.Size = UDim2.new(0, 30, 0, 30)
settingsCloseBtn.Position = UDim2.new(1, -36, 0, 5)
settingsCloseBtn.ZIndex = 52
settingsCloseBtn.Parent = SettingsPanel

local settingsScroll = Instance.new("ScrollingFrame")
settingsScroll.Name = "SettingsContent"
settingsScroll.BackgroundTransparency = 1
settingsScroll.Size = UDim2.new(1, -16, 1, -48)
settingsScroll.Position = UDim2.new(0, 8, 0, 44)
settingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
settingsScroll.ScrollBarThickness = 3
settingsScroll.ScrollBarImageColor3 = Colors.Accent
settingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
settingsScroll.ZIndex = 52
settingsScroll.Parent = SettingsPanel

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Padding = UDim.new(0, 6)
settingsLayout.Parent = settingsScroll

CreatePadding(settingsScroll, 4, 4, 4, 4)

local currentSettingsOpen = nil

local function CloseSettingsPanel()
	Tween(SettingsPanel, {Position = UDim2.new(1, 0, 0, 0)}, 0.3)
	task.wait(0.3)
	SettingsPanel.Visible = false
	currentSettingsOpen = nil
end

local function OpenSettingsPanel(featureName, buildFn)
	-- Clear old
	for _, child in ipairs(settingsScroll:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	settingsTitle.Text = featureName .. " Settings"
	currentSettingsOpen = featureName

	buildFn(settingsScroll)

	SettingsPanel.Visible = true
	SettingsPanel.Position = UDim2.new(1, 0, 0, 0)
	Tween(SettingsPanel, {Position = UDim2.new(1, -280, 0, 0)}, 0.3, Enum.EasingStyle.Quart)
end

settingsCloseBtn.MouseButton1Click:Connect(function()
	CloseSettingsPanel()
end)

-- ═══════════════════════════════════════════
-- UI COMPONENT BUILDERS
-- ═══════════════════════════════════════════

local function CreateSettingToggle(parent, text, configKey, order, callback)
	local frame = Instance.new("Frame")
	frame.Name = text
	frame.BackgroundColor3 = Colors.SurfaceLight
	frame.Size = UDim2.new(1, 0, 0, 36)
	frame.ZIndex = 53
	frame.LayoutOrder = order or 0
	frame.Parent = parent
	CreateCorner(frame, 6)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextColor3 = Colors.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Size = UDim2.new(1, -60, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.ZIndex = 54
	label.Parent = frame

	local toggleBG = Instance.new("TextButton")
	toggleBG.Name = "ToggleBG"
	toggleBG.BackgroundColor3 = Config[configKey] and Colors.Accent or Colors.SurfaceLighter
	toggleBG.Size = UDim2.new(0, 38, 0, 20)
	toggleBG.Position = UDim2.new(1, -48, 0.5, 0)
	toggleBG.AnchorPoint = Vector2.new(0, 0.5)
	toggleBG.Text = ""
	toggleBG.AutoButtonColor = false
	toggleBG.ZIndex = 54
	toggleBG.Parent = frame
	CreateCorner(toggleBG, 10)

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.BackgroundColor3 = Colors.White
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.Position = Config[configKey] and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.ZIndex = 55
	knob.Parent = toggleBG
	CreateCorner(knob, 8)

	toggleBG.MouseButton1Click:Connect(function()
		Config[configKey] = not Config[configKey]
		if Config[configKey] then
			Tween(toggleBG, {BackgroundColor3 = Colors.Accent}, 0.2)
			Tween(knob, {Position = UDim2.new(1, -18, 0.5, 0)}, 0.2)
		else
			Tween(toggleBG, {BackgroundColor3 = Colors.SurfaceLighter}, 0.2)
			Tween(knob, {Position = UDim2.new(0, 2, 0.5, 0)}, 0.2)
		end
		SaveConfig()
		if callback then callback(Config[configKey]) end
	end)

	return frame
end

local function CreateSettingSlider(parent, text, configKey, min, max, order, callback)
	local frame = Instance.new("Frame")
	frame.Name = text
	frame.BackgroundColor3 = Colors.SurfaceLight
	frame.Size = UDim2.new(1, 0, 0, 54)
	frame.ZIndex = 53
	frame.LayoutOrder = order or 0
	frame.Parent = parent
	CreateCorner(frame, 6)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextColor3 = Colors.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Size = UDim2.new(0.6, 0, 0, 20)
	label.Position = UDim2.new(0, 10, 0, 4)
	label.ZIndex = 54
	label.Parent = frame

	local valueLabel = Instance.new("TextLabel")
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(Config[configKey])
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 12
	valueLabel.TextColor3 = Colors.Accent
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Size = UDim2.new(0.4, -10, 0, 20)
	valueLabel.Position = UDim2.new(0.6, 0, 0, 4)
	valueLabel.ZIndex = 54
	valueLabel.Parent = frame

	local sliderBG = Instance.new("Frame")
	sliderBG.BackgroundColor3 = Colors.SurfaceLighter
	sliderBG.Size = UDim2.new(1, -20, 0, 6)
	sliderBG.Position = UDim2.new(0, 10, 0, 36)
	sliderBG.ZIndex = 54
	sliderBG.Parent = frame
	CreateCorner(sliderBG, 3)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Colors.Accent
	local pct = (Config[configKey] - min) / (max - min)
	fill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
	fill.ZIndex = 55
	fill.BorderSizePixel = 0
	fill.Parent = sliderBG
	CreateCorner(fill, 3)

	local knob = Instance.new("Frame")
	knob.BackgroundColor3 = Colors.White
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = UDim2.new(math.clamp(pct, 0, 1), 0, 0.5, 0)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.ZIndex = 56
	knob.Parent = sliderBG
	CreateCorner(knob, 7)
	CreateShadow(knob, 10, 0.6)

	local slideDrag = false

	local function UpdateSlider(inputPos)
		local relX = inputPos.X - sliderBG.AbsolutePosition.X
		local pctNew = math.clamp(relX / sliderBG.AbsoluteSize.X, 0, 1)
		local val = math.floor(min + (max - min) * pctNew)
		Config[configKey] = val
		valueLabel.Text = tostring(val)
		fill.Size = UDim2.new(pctNew, 0, 1, 0)
		knob.Position = UDim2.new(pctNew, 0, 0.5, 0)
		if callback then callback(val) end
	end

	sliderBG.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			slideDrag = true
			UpdateSlider(input.Position)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if slideDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			UpdateSlider(input.Position)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if slideDrag then
				slideDrag = false
				SaveConfig()
			end
		end
	end)

	return frame
end

local function CreateSettingDropdown(parent, text, configKey, options, order, callback)
	local frame = Instance.new("Frame")
	frame.Name = text
	frame.BackgroundColor3 = Colors.SurfaceLight
	frame.Size = UDim2.new(1, 0, 0, 36)
	frame.ZIndex = 53
	frame.LayoutOrder = order or 0
	frame.ClipsDescendants = false
	frame.Parent = parent
	CreateCorner(frame, 6)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextColor3 = Colors.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Size = UDim2.new(0.5, 0, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.ZIndex = 54
	label.Parent = frame

	local dropBtn = Instance.new("TextButton")
	dropBtn.BackgroundColor3 = Colors.SurfaceLighter
	dropBtn.Size = UDim2.new(0.45, -10, 0, 26)
	dropBtn.Position = UDim2.new(0.55, 0, 0.5, 0)
	dropBtn.AnchorPoint = Vector2.new(0, 0.5)
	dropBtn.Text = tostring(Config[configKey])
	dropBtn.Font = Enum.Font.GothamMedium
	dropBtn.TextSize = 11
	dropBtn.TextColor3 = Colors.Accent
	dropBtn.AutoButtonColor = false
	dropBtn.ZIndex = 54
	dropBtn.Parent = frame
	CreateCorner(dropBtn, 5)

	local dropList = Instance.new("Frame")
	dropList.BackgroundColor3 = Colors.Surface
	dropList.Size = UDim2.new(0.45, -10, 0, #options * 26)
	dropList.Position = UDim2.new(0.55, 0, 1, 4)
	dropList.ZIndex = 60
	dropList.Visible = false
	dropList.Parent = frame
	CreateCorner(dropList, 6)
	CreateStroke(dropList, Colors.Border, 1, 0.3)
	CreateShadow(dropList, 20, 0.6)

	local dropLayout = Instance.new("UIListLayout")
	dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
	dropLayout.Parent = dropList

	for i, opt in ipairs(options) do
		local optBtn = Instance.new("TextButton")
		optBtn.BackgroundColor3 = Colors.SurfaceLight
		optBtn.BackgroundTransparency = 1
		optBtn.Size = UDim2.new(1, 0, 0, 26)
		optBtn.Text = tostring(opt)
		optBtn.Font = Enum.Font.Gotham
		optBtn.TextSize = 11
		optBtn.TextColor3 = Colors.Text
		optBtn.AutoButtonColor = false
		optBtn.LayoutOrder = i
		optBtn.ZIndex = 61
		optBtn.Parent = dropList

		optBtn.MouseEnter:Connect(function()
			Tween(optBtn, {BackgroundTransparency = 0.5}, 0.1)
		end)
		optBtn.MouseLeave:Connect(function()
			Tween(optBtn, {BackgroundTransparency = 1}, 0.1)
		end)

		optBtn.MouseButton1Click:Connect(function()
			Config[configKey] = opt
			dropBtn.Text = tostring(opt)
			dropList.Visible = false
			SaveConfig()
			if callback then callback(opt) end
		end)
	end

	dropBtn.MouseButton1Click:Connect(function()
		dropList.Visible = not dropList.Visible
	end)

	return frame
end

-- ═══════════════════════════════════════════
-- FEATURE CARD BUILDER
-- ═══════════════════════════════════════════
local function CreateFeatureCard(parent, name, configKey, iconId, order, settingsBuilder)
	local card = Instance.new("Frame")
	card.Name = name
	card.BackgroundColor3 = Colors.Card
	card.Size = UDim2.new(1, -8, 0, 44)
	card.ZIndex = 20
	card.LayoutOrder = order or 0
	card.Parent = parent
	CreateCorner(card, 8)
	CreateStroke(card, Colors.Border, 1, 0.6)

	-- Hover effect
	card.MouseEnter:Connect(function()
		Tween(card, {BackgroundColor3 = Colors.CardHover}, 0.15)
		local s = card:FindFirstChildOfClass("UIStroke")
		if s then Tween(s, {Color = Colors.Accent, Transparency = 0.4}, 0.15) end
	end)
	card.MouseLeave:Connect(function()
		Tween(card, {BackgroundColor3 = Colors.Card}, 0.15)
		local s = card:FindFirstChildOfClass("UIStroke")
		if s then Tween(s, {Color = Colors.Border, Transparency = 0.6}, 0.15) end
	end)

	-- Status indicator
	local status = Instance.new("Frame")
	status.Name = "Status"
	status.BackgroundColor3 = Config[configKey] and Colors.Accent or Colors.TextMuted
	status.Size = UDim2.new(0, 4, 0, 20)
	status.Position = UDim2.new(0, 8, 0.5, 0)
	status.AnchorPoint = Vector2.new(0, 0.5)
	status.ZIndex = 21
	status.Parent = card
	CreateCorner(status, 2)

	-- Icon
	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = iconId or "rbxassetid://7733960981"
	icon.ImageColor3 = Config[configKey] and Colors.Accent or Colors.TextDim
	icon.Size = UDim2.new(0, 18, 0, 18)
	icon.Position = UDim2.new(0, 20, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.ZIndex = 21
	icon.Parent = card

	-- Name
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = name
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextColor3 = Colors.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Size = UDim2.new(1, -120, 1, 0)
	label.Position = UDim2.new(0, 44, 0, 0)
	label.ZIndex = 21
	label.Parent = card

	-- Toggle button
	local toggleBG = Instance.new("TextButton")
	toggleBG.Name = "ToggleBG"
	toggleBG.BackgroundColor3 = Config[configKey] and Colors.Accent or Colors.SurfaceLighter
	toggleBG.Size = UDim2.new(0, 40, 0, 22)
	toggleBG.Position = UDim2.new(1, -90, 0.5, 0)
	toggleBG.AnchorPoint = Vector2.new(0, 0.5)
	toggleBG.Text = ""
	toggleBG.AutoButtonColor = false
	toggleBG.ZIndex = 21
	toggleBG.Parent = card
	CreateCorner(toggleBG, 11)

	local knob = Instance.new("Frame")
	knob.BackgroundColor3 = Colors.White
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.Position = Config[configKey] and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.ZIndex = 22
	knob.Parent = toggleBG
	CreateCorner(knob, 9)

	-- Gear button
	local gearBtn = Instance.new("TextButton")
	gearBtn.Name = "Gear"
	gearBtn.BackgroundColor3 = Colors.SurfaceLighter
	gearBtn.BackgroundTransparency = 0.5
	gearBtn.Size = UDim2.new(0, 30, 0, 30)
	gearBtn.Position = UDim2.new(1, -40, 0.5, 0)
	gearBtn.AnchorPoint = Vector2.new(0, 0.5)
	gearBtn.Text = "⚙"
	gearBtn.Font = Enum.Font.GothamBold
	gearBtn.TextSize = 16
	gearBtn.TextColor3 = Colors.TextDim
	gearBtn.AutoButtonColor = false
	gearBtn.ZIndex = 21
	gearBtn.Parent = card
	CreateCorner(gearBtn, 6)

	if not settingsBuilder then
		gearBtn.Visible = false
		toggleBG.Position = UDim2.new(1, -52, 0.5, 0)
	end

	gearBtn.MouseEnter:Connect(function()
		Tween(gearBtn, {BackgroundTransparency = 0, TextColor3 = Colors.Accent}, 0.15)
	end)
	gearBtn.MouseLeave:Connect(function()
		Tween(gearBtn, {BackgroundTransparency = 0.5, TextColor3 = Colors.TextDim}, 0.15)
	end)

	gearBtn.MouseButton1Click:Connect(function()
		RippleEffect(gearBtn)
		if currentSettingsOpen == name then
			CloseSettingsPanel()
		else
			OpenSettingsPanel(name, settingsBuilder)
		end
	end)

	local function UpdateVisuals(enabled)
		if enabled then
			Tween(toggleBG, {BackgroundColor3 = Colors.Accent}, 0.2)
			Tween(knob, {Position = UDim2.new(1, -20, 0.5, 0)}, 0.2)
			Tween(status, {BackgroundColor3 = Colors.Accent}, 0.2)
			Tween(icon, {ImageColor3 = Colors.Accent}, 0.2)
		else
			Tween(toggleBG, {BackgroundColor3 = Colors.SurfaceLighter}, 0.2)
			Tween(knob, {Position = UDim2.new(0, 2, 0.5, 0)}, 0.2)
			Tween(status, {BackgroundColor3 = Colors.TextMuted}, 0.2)
			Tween(icon, {ImageColor3 = Colors.TextDim}, 0.2)
		end
	end

	toggleBG.MouseButton1Click:Connect(function()
		Config[configKey] = not Config[configKey]
		UpdateVisuals(Config[configKey])
		SaveConfig()
	end)

	return card, toggleBG
end

-- ═══════════════════════════════════════════
-- TAB PAGES
-- ═══════════════════════════════════════════

for _, tab in ipairs(TabData) do
	local page = Instance.new("ScrollingFrame")
	page.Name = tab.Name .. "Page"
	page.BackgroundTransparency = 1
	page.Size = UDim2.new(1, 0, 1, 0)
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = Colors.Accent
	page.Visible = (tab.Name == "Main")
	page.ZIndex = 15
	page.Parent = ContentArea

	CreatePadding(page, 12, 12, 12, 12)

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = page

	TabPages[tab.Name] = page
end

-- ═══════════════════════════════════════════
-- SECTION HEADER BUILDER
-- ═══════════════════════════════════════════
local function CreateSectionHeader(parent, text, order)
	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 28)
	header.LayoutOrder = order or 0
	header.ZIndex = 20
	header.Parent = parent

	local headerText = Instance.new("TextLabel")
	headerText.BackgroundTransparency = 1
	headerText.Text = string.upper(text)
	headerText.Font = Enum.Font.GothamBold
	headerText.TextSize = 10
	headerText.TextColor3 = Colors.TextMuted
	headerText.TextXAlignment = Enum.TextXAlignment.Left
	headerText.Size = UDim2.new(1, 0, 1, 0)
	headerText.Position = UDim2.new(0, 4, 0, 0)
	headerText.ZIndex = 21
	headerText.Parent = header

	local line = Instance.new("Frame")
	line.BackgroundColor3 = Colors.Border
	line.Size = UDim2.new(1, -80, 0, 1)
	line.Position = UDim2.new(0, 76, 0.5, 0)
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.BorderSizePixel = 0
	line.ZIndex = 20
	line.Parent = header

	return header
end

-- ═══════════════════════════════════════════
-- POPULATE MAIN TAB
-- ═══════════════════════════════════════════
local mainPage = TabPages["Main"]

CreateSectionHeader(mainPage, "⚔  Combat", 1)

-- AimBot
CreateFeatureCard(mainPage, "AimBot", "AimBot_Enabled", "rbxassetid://7734009413", 2, function(scroll)
	CreateSettingSlider(scroll, "FOV Radius", "AimBot_FOV", 10, 500, 1)
	CreateSettingSlider(scroll, "Smoothness", "AimBot_Smoothness", 1, 20, 2)
	CreateSettingDropdown(scroll, "Target Part", "AimBot_TargetPart", {"Head", "HumanoidRootPart", "Torso", "UpperTorso"}, 3)
	CreateSettingToggle(scroll, "Team Check", "AimBot_TeamCheck", 4)
	CreateSettingToggle(scroll, "Wall Check", "AimBot_WallCheck", 5)
	CreateSettingToggle(scroll, "Show FOV Circle", "AimBot_ShowFOV", 6)
	CreateSettingDropdown(scroll, "Key Bind", "AimBot_KeyBind", {"MouseButton2", "MouseButton1", "Q", "E", "X", "C"}, 7)
end)

-- Silent Aim
CreateFeatureCard(mainPage, "Silent Aim", "SilentAim_Enabled", "rbxassetid://7733960981", 3, function(scroll)
	CreateSettingSlider(scroll, "FOV Radius", "SilentAim_FOV", 10, 500, 1)
	CreateSettingSlider(scroll, "Hit Chance (%)", "SilentAim_HitChance", 1, 100, 2)
	CreateSettingDropdown(scroll, "Target Part", "SilentAim_TargetPart", {"Head", "HumanoidRootPart", "Torso", "UpperTorso"}, 3)
	CreateSettingToggle(scroll, "Team Check", "SilentAim_TeamCheck", 4)
	CreateSettingToggle(scroll, "Show FOV Circle", "SilentAim_ShowFOV", 5)
end)

-- TriggerBot
CreateFeatureCard(mainPage, "TriggerBot", "TriggerBot_Enabled", "rbxassetid://7733658504", 4, function(scroll)
	CreateSettingSlider(scroll, "Delay (ms)", "TriggerBot_Delay", 0, 500, 1)
	CreateSettingSlider(scroll, "Max Distance", "TriggerBot_MaxDistance", 50, 2000, 2)
	CreateSettingDropdown(scroll, "Target Part", "TriggerBot_TargetPart", {"Head", "HumanoidRootPart", "Torso", "UpperTorso"}, 3)
	CreateSettingToggle(scroll, "Team Check", "TriggerBot_TeamCheck", 4)
end)

-- Hitbox Expander
CreateFeatureCard(mainPage, "Hitbox Expander", "HitboxExpander_Enabled", "rbxassetid://7734053495", 5, function(scroll)
	CreateSettingSlider(scroll, "Hitbox Size", "HitboxExpander_Size", 1, 50, 1)
end)

CreateSectionHeader(mainPage, "🔧  Utility", 10)

-- Anti AFK
CreateFeatureCard(mainPage, "Anti AFK", "AntiAFK_Enabled", "rbxassetid://7733715400", 11)

-- Auto Respawn
CreateFeatureCard(mainPage, "Auto Respawn", "AutoRespawn_Enabled", "rbxassetid://7733715400", 12)

-- Click TP
CreateFeatureCard(mainPage, "Click Teleport", "ClickTP_Enabled", "rbxassetid://7734053495", 13, function(scroll)
	CreateSettingDropdown(scroll, "Key Bind", "ClickTP_KeyBind", {"T", "G", "Y", "V"}, 1)
end)

-- Invisibility
CreateFeatureCard(mainPage, "Invisibility", "Invisibility_Enabled", "rbxassetid://7733960981", 14)

-- ═══════════════════════════════════════════
-- POPULATE MOVEMENT TAB
-- ═══════════════════════════════════════════
local movPage = TabPages["Movement"]

CreateSectionHeader(movPage, "🏃  Locomotion", 1)

-- Speed
CreateFeatureCard(movPage, "Speed", "Speed_Enabled", "rbxassetid://7734053495", 2, function(scroll)
	CreateSettingSlider(scroll, "Walk Speed", "Speed_Value", 16, 200, 1)
end)

-- Jump
CreateFeatureCard(movPage, "Jump Power", "Jump_Enabled", "rbxassetid://7734053495", 3, function(scroll)
	CreateSettingSlider(scroll, "Jump Power", "Jump_Value", 50, 300, 1)
end)

-- Infinity Jump
CreateFeatureCard(movPage, "Infinite Jump", "InfJump_Enabled", "rbxassetid://7734053495", 4)

-- Fly
CreateFeatureCard(movPage, "Fly", "Fly_Enabled", "rbxassetid://7734053495", 5, function(scroll)
	CreateSettingSlider(scroll, "Fly Speed", "Fly_Speed", 10, 200, 1)
	CreateSettingDropdown(scroll, "Key Bind", "Fly_KeyBind", {"F", "G", "V", "B"}, 2)
end)

-- Noclip
CreateFeatureCard(movPage, "Noclip", "Noclip_Enabled", "rbxassetid://7733960981", 6, function(scroll)
	CreateSettingDropdown(scroll, "Key Bind", "Noclip_KeyBind", {"N", "X", "Z", "C"}, 1)
end)

CreateSectionHeader(movPage, "🌍  Physics", 10)

-- Low Gravity
CreateFeatureCard(movPage, "Low Gravity", "LowGravity_Enabled", "rbxassetid://7734009413", 11, function(scroll)
	CreateSettingSlider(scroll, "Gravity Value", "LowGravity_Value", 10, 196, 1)
end)

-- No Fall Damage
CreateFeatureCard(movPage, "No Fall Damage", "NoFallDamage_Enabled", "rbxassetid://7733715400", 12)

-- ═══════════════════════════════════════════
-- POPULATE VISUALS TAB
-- ═══════════════════════════════════════════
local visPage = TabPages["Visuals"]

CreateSectionHeader(visPage, "👁  Player ESP", 1)

-- ESP
CreateFeatureCard(visPage, "ESP", "ESP_Enabled", "rbxassetid://7734009413", 2, function(scroll)
	CreateSettingToggle(scroll, "Boxes", "ESP_Boxes", 1)
	CreateSettingToggle(scroll, "Names", "ESP_Names", 2)
	CreateSettingToggle(scroll, "Health Bars", "ESP_Health", 3)
	CreateSettingToggle(scroll, "Distance", "ESP_Distance", 4)
	CreateSettingToggle(scroll, "Tracers", "ESP_Tracers", 5)
	CreateSettingToggle(scroll, "Chams", "ESP_Chams", 6)
	CreateSettingToggle(scroll, "Team Check", "ESP_TeamCheck", 7)
	CreateSettingSlider(scroll, "Max Distance", "ESP_MaxDistance", 100, 5000, 8)
	CreateSettingDropdown(scroll, "Tracer Origin", "ESP_TracerOrigin", {"Bottom", "Center", "Top", "Mouse"}, 9)
end)

-- Target HUD
CreateFeatureCard(visPage, "Target HUD", "TargetHUD_Enabled", "rbxassetid://7733960981", 3)

CreateSectionHeader(visPage, "🎨  World", 10)

-- Fullbright
CreateFeatureCard(visPage, "Fullbright", "Fullbright_Enabled", "rbxassetid://7734009413", 11)

-- FOV Changer
CreateFeatureCard(visPage, "FOV Changer", "FOVChanger_Enabled", "rbxassetid://7733960981", 12, function(scroll)
	CreateSettingSlider(scroll, "Field of View", "FOVChanger_Value", 30, 120, 1)
end)

-- Skybox
CreateFeatureCard(visPage, "Custom Skybox", "Skybox_Enabled", "rbxassetid://7734053495", 13)

CreateSectionHeader(visPage, "📊  HUD", 20)

-- Show FPS
CreateFeatureCard(visPage, "Show FPS", "ShowFPS_Enabled", "rbxassetid://7733715400", 21)

-- Show Ping
CreateFeatureCard(visPage, "Show Ping", "ShowPing_Enabled", "rbxassetid://7733715400", 22)

CreateSectionHeader(visPage, "🎵  Audio", 30)

-- Music
CreateFeatureCard(visPage, "Music Player", "Music_Enabled", "rbxassetid://7733960981", 31, function(scroll)
	CreateSettingSlider(scroll, "Volume", "Music_Volume", 0, 100, 1)

	-- Music ID input
	local idFrame = Instance.new("Frame")
	idFrame.BackgroundColor3 = Colors.SurfaceLight
	idFrame.Size = UDim2.new(1, 0, 0, 60)
	idFrame.ZIndex = 53
	idFrame.LayoutOrder = 2
	idFrame.Parent = scroll
	CreateCorner(idFrame, 6)

	local idLabel = Instance.new("TextLabel")
	idLabel.BackgroundTransparency = 1
	idLabel.Text = "Music ID"
	idLabel.Font = Enum.Font.Gotham
	idLabel.TextSize = 12
	idLabel.TextColor3 = Colors.Text
	idLabel.TextXAlignment = Enum.TextXAlignment.Left
	idLabel.Size = UDim2.new(1, 0, 0, 20)
	idLabel.Position = UDim2.new(0, 10, 0, 4)
	idLabel.ZIndex = 54
	idLabel.Parent = idFrame

	local idInput = Instance.new("TextBox")
	idInput.BackgroundColor3 = Colors.SurfaceLighter
	idInput.PlaceholderText = "Enter Sound ID..."
	idInput.PlaceholderColor3 = Colors.TextMuted
	idInput.Text = Config.Music_CurrentID
	idInput.Font = Enum.Font.Gotham
	idInput.TextSize = 12
	idInput.TextColor3 = Colors.Text
	idInput.Size = UDim2.new(1, -20, 0, 28)
	idInput.Position = UDim2.new(0, 10, 0, 26)
	idInput.ZIndex = 54
	idInput.ClearTextOnFocus = false
	idInput.Parent = idFrame
	CreateCorner(idInput, 5)

	idInput.FocusLost:Connect(function()
		Config.Music_CurrentID = idInput.Text
		SaveConfig()
	end)

	-- Preset songs
	local presets = {
		{"Phonk - MURDER IN MY MIND", "6823233710"},
		{"Phonk - CLOSE EYES", "9046862972"},
		{"Playboi Carti - Magnolia", "923605440"},
		{"XXXTentacion - Moonlight", "1845554017"},
		{"Travis Scott - SICKO MODE", "2727778373"},
		{"Eminem - Lose Yourself", "152828706"},
		{"Phonk - HENSONN", "9125790945"},
		{"NF - The Search", "3399722789"},
	}

	local presetLabel = Instance.new("TextLabel")
	presetLabel.BackgroundTransparency = 1
	presetLabel.Text = "PRESETS"
	presetLabel.Font = Enum.Font.GothamBold
	presetLabel.TextSize = 10
	presetLabel.TextColor3 = Colors.TextMuted
	presetLabel.TextXAlignment = Enum.TextXAlignment.Left
	presetLabel.Size = UDim2.new(1, 0, 0, 24)
	presetLabel.ZIndex = 54
	presetLabel.LayoutOrder = 3
	presetLabel.Parent = scroll

	for i, preset in ipairs(presets) do
		local pBtn = Instance.new("TextButton")
		pBtn.BackgroundColor3 = Colors.SurfaceLight
		pBtn.Size = UDim2.new(1, 0, 0, 30)
		pBtn.Text = "  🎵  " .. preset[1]
		pBtn.Font = Enum.Font.Gotham
		pBtn.TextSize = 11
		pBtn.TextColor3 = Colors.Text
		pBtn.TextXAlignment = Enum.TextXAlignment.Left
		pBtn.AutoButtonColor = false
		pBtn.ZIndex = 54
		pBtn.LayoutOrder = 3 + i
		pBtn.Parent = scroll
		CreateCorner(pBtn, 5)

		pBtn.MouseEnter:Connect(function()
			Tween(pBtn, {BackgroundColor3 = Colors.CardHover}, 0.1)
		end)
		pBtn.MouseLeave:Connect(function()
			Tween(pBtn, {BackgroundColor3 = Colors.SurfaceLight}, 0.1)
		end)

		pBtn.MouseButton1Click:Connect(function()
			Config.Music_CurrentID = preset[2]
			idInput.Text = preset[2]
			SaveConfig()
			Notify("Music", "Now playing: " .. preset[1], 3, "info")
		end)
	end
end)

-- ═══════════════════════════════════════════
-- POPULATE SETTINGS TAB
-- ═══════════════════════════════════════════
local setPage = TabPages["Settings"]

CreateSectionHeader(setPage, "⚙  Interface", 1)

-- GUI Toggle Key
CreateFeatureCard(setPage, "GUI Toggle Key", "GUI_ToggleKey", "rbxassetid://7733715400", 2)

-- Notifications
CreateFeatureCard(setPage, "Notifications", "GUI_Notifications", "rbxassetid://7733960981", 3)

CreateSectionHeader(setPage, "💾  Configuration", 10)

-- Config buttons
local configBtns = Instance.new("Frame")
configBtns.BackgroundTransparency = 1
configBtns.Size = UDim2.new(1, -8, 0, 42)
configBtns.LayoutOrder = 11
configBtns.ZIndex = 20
configBtns.Parent = setPage

local configLayout2 = Instance.new("UIListLayout")
configLayout2.FillDirection = Enum.FillDirection.Horizontal
configLayout2.Padding = UDim.new(0, 8)
configLayout2.SortOrder = Enum.SortOrder.LayoutOrder
configLayout2.Parent = configBtns

local function CreateConfigBtn(text, color, order, callback)
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = color
	btn.BackgroundTransparency = 0.85
	btn.Size = UDim2.new(0.32, -6, 1, 0)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = color
	btn.AutoButtonColor = false
	btn.LayoutOrder = order
	btn.ZIndex = 21
	btn.Parent = configBtns
	CreateCorner(btn, 8)
	CreateStroke(btn, color, 1, 0.6)

	btn.MouseEnter:Connect(function()
		Tween(btn, {BackgroundTransparency = 0.6}, 0.15)
	end)
	btn.MouseLeave:Connect(function()
		Tween(btn, {BackgroundTransparency = 0.85}, 0.15)
	end)

	btn.MouseButton1Click:Connect(function()
		RippleEffect(btn)
		callback()
	end)
end

CreateConfigBtn("💾 Save", Colors.Accent, 1, function()
	SaveConfig()
	Notify("Config", "Configuration saved successfully!", 3, "success")
end)

CreateConfigBtn("📂 Load", Colors.Warning, 2, function()
	LoadConfig()
	Notify("Config", "Configuration loaded!", 3, "info")
end)

CreateConfigBtn("🗑 Reset", Colors.Danger, 3, function()
	ResetConfig()
	Notify("Config", "Configuration reset to defaults!", 3, "warning")
end)

CreateSectionHeader(setPage, "ℹ  Info", 20)

-- Info card
local infoCard = Instance.new("Frame")
infoCard.BackgroundColor3 = Colors.Card
infoCard.Size = UDim2.new(1, -8, 0, 100)
infoCard.LayoutOrder = 21
infoCard.ZIndex = 20
infoCard.Parent = setPage
CreateCorner(infoCard, 8)
CreateStroke(infoCard, Colors.Accent, 1, 0.7)

local infoTexts = {
	{y = 12, text = "EspadaWare v2.1 | Premium Edition", font = Enum.Font.GothamBold, size = 14, color = Colors.Accent},
	{y = 34, text = "Player: " .. Player.Name, font = Enum.Font.Gotham, size = 12, color = Colors.Text},
	{y = 52, text = "Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name, font = Enum.Font.Gotham, size = 11, color = Colors.TextDim},
	{y = 70, text = "Toggle GUI: RightShift | Drag to move", font = Enum.Font.Gotham, size = 11, color = Colors.TextMuted},
}

for _, info in ipairs(infoTexts) do
	pcall(function()
		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Text = info.text
		lbl.Font = info.font
		lbl.TextSize = info.size
		lbl.TextColor3 = info.color
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Size = UDim2.new(1, -24, 0, 18)
		lbl.Position = UDim2.new(0, 12, 0, info.y)
		lbl.ZIndex = 21
		lbl.Parent = infoCard
	end)
end

-- ═══════════════════════════════════════════
-- TAB SWITCHING
-- ═══════════════════════════════════════════
local function SwitchTab(tabName)
	if CurrentTab == tabName then return end
	CurrentTab = tabName

	-- Close settings panel
	if currentSettingsOpen then
		CloseSettingsPanel()
	end

	for name, btn in pairs(TabButtons) do
		local icon = btn:FindFirstChild("Icon")
		local label = btn:FindFirstChild("Label")
		local indicator = btn:FindFirstChild("Indicator")

		if name == tabName then
			Tween(btn, {BackgroundTransparency = 0.85}, 0.2)
			if icon then Tween(icon, {ImageColor3 = Colors.Accent}, 0.2) end
			if label then Tween(label, {TextColor3 = Colors.Accent}, 0.2) end
			if indicator then Tween(indicator, {Size = UDim2.new(0, 3, 0, 20)}, 0.2) end
		else
			Tween(btn, {BackgroundTransparency = 1}, 0.2)
			if icon then Tween(icon, {ImageColor3 = Colors.TextDim}, 0.2) end
			if label then Tween(label, {TextColor3 = Colors.TextDim}, 0.2) end
			if indicator then Tween(indicator, {Size = UDim2.new(0, 3, 0, 0)}, 0.2) end
		end
	end

	for name, page in pairs(TabPages) do
		if name == tabName then
			page.Visible = true
			page.BackgroundTransparency = 1
			-- Animate children
			for _, child in ipairs(page:GetChildren()) do
				if child:IsA("Frame") then
					child.Position = child.Position + UDim2.new(0, 0, 0, 15)
					child.BackgroundTransparency = 1
					Tween(child, {
						Position = child.Position - UDim2.new(0, 0, 0, 15),
						BackgroundTransparency = child.Name == "SectionHeader" and 1 or 0
					}, 0.3, Enum.EasingStyle.Quart)
				end
			end
		else
			page.Visible = false
		end
	end
end

-- Set initial tab
SwitchTab("Main")

for name, btn in pairs(TabButtons) do
	btn.MouseButton1Click:Connect(function()
		RippleEffect(btn)
		SwitchTab(name)
	end)
end

-- ═══════════════════════════════════════════
-- TOGGLE BUTTON (floating)
-- ═══════════════════════════════════════════
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.BackgroundColor3 = Colors.Accent
ToggleButton.Size = UDim2.new(0, 46, 0, 46)
ToggleButton.Position = UDim2.new(0, 20, 0.5, 0)
ToggleButton.AnchorPoint = Vector2.new(0, 0.5)
ToggleButton.Text = ""
ToggleButton.AutoButtonColor = false
ToggleButton.ZIndex = 100
ToggleButton.Parent = MainGui
CreateCorner(ToggleButton, 23)
CreateShadow(ToggleButton, 30, 0.5)

local toggleIcon = Instance.new("ImageLabel")
toggleIcon.BackgroundTransparency = 1
toggleIcon.Image = "rbxassetid://7734053495"
toggleIcon.ImageColor3 = Colors.Background
toggleIcon.Size = UDim2.new(0, 24, 0, 24)
toggleIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
toggleIcon.AnchorPoint = Vector2.new(0.5, 0.5)
toggleIcon.ZIndex = 101
toggleIcon.Parent = ToggleButton

-- Pulse animation for toggle
task.spawn(function()
	while ToggleButton and ToggleButton.Parent do
		if not guiVisible then
			Tween(ToggleButton, {Size = UDim2.new(0, 50, 0, 50)}, 1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(1)
			Tween(ToggleButton, {Size = UDim2.new(0, 46, 0, 46)}, 1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(1)
		else
			task.wait(0.5)
		end
	end
end)

-- Toggle button drag
local toggleDragging = false
local toggleDragStart, toggleStartPos

ToggleButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		toggleDragging = true
		toggleDragStart = input.Position
		toggleStartPos = ToggleButton.Position
	end
end)

ToggleButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if toggleDragging then
			local delta = input.Position - toggleDragStart
			if delta.Magnitude < 5 then
				-- It was a click, not a drag
				guiVisible = not guiVisible
				Window.Visible = guiVisible
				if guiVisible then
					Window.Size = UDim2.new(0, 680, 0, 0)
					Window.BackgroundTransparency = 1
					Tween(Window, {Size = UDim2.new(0, 680, 0, 480), BackgroundTransparency = 0}, 0.4, Enum.EasingStyle.Back)
				end
			end
			toggleDragging = false
		end
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if toggleDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - toggleDragStart
		ToggleButton.Position = UDim2.new(
			toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X,
			toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y
		)
	end
end)

-- Keyboard toggle
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode[Config.GUI_ToggleKey] then
		guiVisible = not guiVisible
		Window.Visible = guiVisible
		if guiVisible then
			Window.Size = UDim2.new(0, 680, 0, 0)
			Window.BackgroundTransparency = 1
			Tween(Window, {Size = UDim2.new(0, 680, 0, 480), BackgroundTransparency = 0}, 0.4, Enum.EasingStyle.Back)
		end
	end
end)

-- ═══════════════════════════════════════════
-- FPS / PING DISPLAY
-- ═══════════════════════════════════════════
local StatsFrame = Instance.new("Frame")
StatsFrame.Name = "StatsDisplay"
StatsFrame.BackgroundColor3 = Colors.Surface
StatsFrame.BackgroundTransparency = 0.3
StatsFrame.Size = UDim2.new(0, 180, 0, 50)
StatsFrame.Position = UDim2.new(0, 10, 0, 10)
StatsFrame.ZIndex = 90
StatsFrame.Visible = false
StatsFrame.Parent = MainGui
CreateCorner(StatsFrame, 8)
CreateStroke(StatsFrame, Colors.Accent, 1, 0.7)

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Name = "FPS"
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: --"
fpsLabel.Font = Enum.Font.Code
fpsLabel.TextSize = 13
fpsLabel.TextColor3 = Colors.Accent
fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
fpsLabel.Size = UDim2.new(1, -16, 0, 20)
fpsLabel.Position = UDim2.new(0, 8, 0, 5)
fpsLabel.ZIndex = 91
fpsLabel.Parent = StatsFrame

local pingLabel = Instance.new("TextLabel")
pingLabel.Name = "Ping"
pingLabel.BackgroundTransparency = 1
pingLabel.Text = "Ping: --"
pingLabel.Font = Enum.Font.Code
pingLabel.TextSize = 13
pingLabel.TextColor3 = Colors.AccentGlow
pingLabel.TextXAlignment = Enum.TextXAlignment.Left
pingLabel.Size = UDim2.new(1, -16, 0, 20)
pingLabel.Position = UDim2.new(0, 8, 0, 25)
pingLabel.ZIndex = 91
pingLabel.Parent = StatsFrame

-- ═══════════════════════════════════════════
-- TARGET HUD
-- ═══════════════════════════════════════════
local TargetHUDFrame = Instance.new("Frame")
TargetHUDFrame.Name = "TargetHUD"
TargetHUDFrame.BackgroundColor3 = Colors.Surface
TargetHUDFrame.BackgroundTransparency = 0.15
TargetHUDFrame.Size = UDim2.new(0, 220, 0, 70)
TargetHUDFrame.Position = UDim2.new(0.5, 0, 0, 10)
TargetHUDFrame.AnchorPoint = Vector2.new(0.5, 0)
TargetHUDFrame.ZIndex = 90
TargetHUDFrame.Visible = false
TargetHUDFrame.Parent = MainGui
CreateCorner(TargetHUDFrame, 10)
CreateStroke(TargetHUDFrame, Colors.Accent, 1, 0.5)
CreateShadow(TargetHUDFrame, 30, 0.6)

local targetAvatar = Instance.new("ImageLabel")
targetAvatar.Name = "Avatar"
targetAvatar.BackgroundColor3 = Colors.SurfaceLighter
targetAvatar.Size = UDim2.new(0, 50, 0, 50)
targetAvatar.Position = UDim2.new(0, 10, 0.5, 0)
targetAvatar.AnchorPoint = Vector2.new(0, 0.5)
targetAvatar.ZIndex = 91
targetAvatar.Parent = TargetHUDFrame
CreateCorner(targetAvatar, 25)

local targetName = Instance.new("TextLabel")
targetName.Name = "Name"
targetName.BackgroundTransparency = 1
targetName.Text = "Target"
targetName.Font = Enum.Font.GothamBold
targetName.TextSize = 14
targetName.TextColor3 = Colors.Text
targetName.TextXAlignment = Enum.TextXAlignment.Left
targetName.Size = UDim2.new(1, -80, 0, 20)
targetName.Position = UDim2.new(0, 68, 0, 12)
targetName.ZIndex = 91
targetName.Parent = TargetHUDFrame

local targetHealthBG = Instance.new("Frame")
targetHealthBG.BackgroundColor3 = Colors.SurfaceLighter
targetHealthBG.Size = UDim2.new(1, -80, 0, 8)
targetHealthBG.Position = UDim2.new(0, 68, 0, 36)
targetHealthBG.ZIndex = 91
targetHealthBG.Parent = TargetHUDFrame
CreateCorner(targetHealthBG, 4)

local targetHealthFill = Instance.new("Frame")
targetHealthFill.BackgroundColor3 = Colors.Accent
targetHealthFill.Size = UDim2.new(1, 0, 1, 0)
targetHealthFill.ZIndex = 92
targetHealthFill.Parent = targetHealthBG
CreateCorner(targetHealthFill, 4)

local targetHealthText = Instance.new("TextLabel")
targetHealthText.BackgroundTransparency = 1
targetHealthText.Text = "100/100"
targetHealthText.Font = Enum.Font.Gotham
targetHealthText.TextSize = 10
targetHealthText.TextColor3 = Colors.TextDim
targetHealthText.TextXAlignment = Enum.TextXAlignment.Left
targetHealthText.Size = UDim2.new(1, -80, 0, 14)
targetHealthText.Position = UDim2.new(0, 68, 0, 47)
targetHealthText.ZIndex = 91
targetHealthText.Parent = TargetHUDFrame

-- ═══════════════════════════════════════════
-- FOV CIRCLE
-- ═══════════════════════════════════════════
local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.BackgroundTransparency = 1
FOVCircle.Size = UDim2.new(0, 240, 0, 240)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.ZIndex = 5
FOVCircle.Visible = false
FOVCircle.Parent = MainGui

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Colors.Accent
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.4
fovStroke.Parent = FOVCircle
CreateCorner(FOVCircle, 9999)

-- ═══════════════════════════════════════════
-- ══════════ ACTUAL FUNCTIONALITY ══════════
-- ═══════════════════════════════════════════

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

Player.CharacterAdded:Connect(function(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid")
	RootPart = char:WaitForChild("HumanoidRootPart")

	-- Auto respawn
	if Config.AutoRespawn_Enabled then
		-- Already handled by CharacterAdded
	end
end)

-- ═══════════════════════════════════════════
-- AIMBOT FUNCTIONALITY
-- ═══════════════════════════════════════════
local aimTarget = nil

local function IsTeammate(plr)
	if not plr or not Player then return false end
	if plr.Team and Player.Team and plr.Team == Player.Team then return true end
	return false
end

local function IsAlive(plr)
	if plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character:FindFirstChild("HumanoidRootPart") then
		return plr.Character.Humanoid.Health > 0
	end
	return false
end

local function GetClosestPlayerToMouse(fov, teamCheck, wallCheck)
	local closest = nil
	local closestDist = fov

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= Player and IsAlive(plr) then
			if teamCheck and IsTeammate(plr) then continue end

			local targetPart = plr.Character:FindFirstChild(Config.AimBot_TargetPart) or plr.Character:FindFirstChild("Head")
			if targetPart then
				local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
				if onScreen then
					local mousePos = UserInputService:GetMouseLocation()
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

					if dist < closestDist then
						if wallCheck then
							local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000)
							local hit = workspace:FindPartOnRayWithIgnoreList(ray, {Character, Camera})
							if hit and hit:IsDescendantOf(plr.Character) then
								closest = plr
								closestDist = dist
							end
						else
							closest = plr
							closestDist = dist
						end
					end
				end
			end
		end
	end

	return closest
end

-- AimBot loop
local aimbotActive = false

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if not Config.AimBot_Enabled then return end

	local keybind = Config.AimBot_KeyBind
	local match = false
	if keybind == "MouseButton2" and input.UserInputType == Enum.UserInputType.MouseButton2 then match = true end
	if keybind == "MouseButton1" and input.UserInputType == Enum.UserInputType.MouseButton1 then match = true end
	if input.KeyCode and input.KeyCode.Name == keybind then match = true end

	if match then
		aimbotActive = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	local keybind = Config.AimBot_KeyBind
	local match = false
	if keybind == "MouseButton2" and input.UserInputType == Enum.UserInputType.MouseButton2 then match = true end
	if keybind == "MouseButton1" and input.UserInputType == Enum.UserInputType.MouseButton1 then match = true end
	if input.KeyCode and input.KeyCode.Name == keybind then match = true end

	if match then
		aimbotActive = false
		aimTarget = nil
	end
end)

RunService.RenderStepped:Connect(function()
	if Config.AimBot_Enabled and aimbotActive then
		local target = GetClosestPlayerToMouse(Config.AimBot_FOV, Config.AimBot_TeamCheck, Config.AimBot_WallCheck)
		aimTarget = target

		if target and target.Character then
			local targetPart = target.Character:FindFirstChild(Config.AimBot_TargetPart) or target.Character:FindFirstChild("Head")
			if targetPart then
				local targetPos = targetPart.Position
				local currentCF = Camera.CFrame
				local targetCF = CFrame.lookAt(currentCF.Position, targetPos)
				Camera.CFrame = currentCF:Lerp(targetCF, 1 / Config.AimBot_Smoothness)
			end
		end
	end
end)

-- ═══════════════════════════════════════════
-- SILENT AIM (basic hook via mouse target)
-- ═══════════════════════════════════════════
-- Note: True silent aim requires namecall hooks, this is a visual approximation
local silentTarget = nil

RunService.Heartbeat:Connect(function()
	if Config.SilentAim_Enabled then
		silentTarget = GetClosestPlayerToMouse(Config.SilentAim_FOV, Config.SilentAim_TeamCheck, false)
	else
		silentTarget = nil
	end
end)

-- ═══════════════════════════════════════════
-- TRIGGERBOT
-- ═══════════════════════════════════════════
task.spawn(function()
	while true do
		if Config.TriggerBot_Enabled then
			local target = Mouse.Target
			if target then
				local plr = Players:GetPlayerFromCharacter(target.Parent)
				if not plr then
					plr = Players:GetPlayerFromCharacter(target.Parent and target.Parent.Parent)
				end

				if plr and plr ~= Player and IsAlive(plr) then
					if Config.TriggerBot_TeamCheck and IsTeammate(plr) then
						-- skip
					else
						local dist = (RootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
						if dist <= Config.TriggerBot_MaxDistance then
							task.wait(Config.TriggerBot_Delay / 1000)
							pcall(function()
								mouse1click()
							end)
						end
					end
				end
			end
		end
		task.wait(0.01)
	end
end)

-- ═══════════════════════════════════════════
-- ESP SYSTEM
-- ═══════════════════════════════════════════
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESP"
ESPFolder.Parent = ScreenGui

local espObjects = {}

local function CreateESPForPlayer(plr)
	if plr == Player then return end

	local espData = {}

	-- Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESP_" .. plr.Name
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(4, 0, 5.5, 0)
	billboard.StudsOffset = Vector3.new(0, 1, 0)
	billboard.ZIndex = 5
	billboard.Parent = ESPFolder

	-- Box
	local box = Instance.new("Frame")
	box.Name = "Box"
	box.BackgroundTransparency = 1
	box.Size = UDim2.new(1, 0, 1, 0)
	box.ZIndex = 6
	box.Parent = billboard
	local boxStroke = CreateStroke(box, Colors.Accent, 1.5, 0)

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = plr.DisplayName
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = Colors.Text
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.Position = UDim2.new(0, 0, 0, -20)
	nameLabel.ZIndex = 7
	nameLabel.Parent = billboard

	-- Distance
	local distLabel = Instance.new("TextLabel")
	distLabel.Name = "Distance"
	distLabel.BackgroundTransparency = 1
	distLabel.Text = "0m"
	distLabel.Font = Enum.Font.Gotham
	distLabel.TextSize = 12
	distLabel.TextColor3 = Colors.TextDim
	distLabel.TextStrokeTransparency = 0.5
	distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	distLabel.Size = UDim2.new(1, 0, 0, 14)
	distLabel.Position = UDim2.new(0, 0, 1, 4)
	distLabel.ZIndex = 7
	distLabel.Parent = billboard

	-- Health bar BG
	local healthBG = Instance.new("Frame")
	healthBG.Name = "HealthBG"
	healthBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	healthBG.BackgroundTransparency = 0.3
	healthBG.Size = UDim2.new(0, 4, 1, 0)
	healthBG.Position = UDim2.new(1, 4, 0, 0)
	healthBG.ZIndex = 7
	healthBG.Parent = billboard
	CreateCorner(healthBG, 2)

	local healthFill = Instance.new("Frame")
	healthFill.Name = "HealthFill"
	healthFill.BackgroundColor3 = Colors.Accent
	healthFill.Size = UDim2.new(1, 0, 1, 0)
	healthFill.Position = UDim2.new(0, 0, 0, 0)
	healthFill.AnchorPoint = Vector2.new(0, 0)
	healthFill.ZIndex = 8
	healthFill.Parent = healthBG
	CreateCorner(healthFill, 2)

	espData.Billboard = billboard
	espData.Box = box
	espData.BoxStroke = boxStroke
	espData.NameLabel = nameLabel
	espData.DistLabel = distLabel
	espData.HealthFill = healthFill
	espData.HealthBG = healthBG

	espObjects[plr] = espData
end

local function RemoveESPForPlayer(plr)
	if espObjects[plr] then
		if espObjects[plr].Billboard then
			espObjects[plr].Billboard:Destroy()
		end
		espObjects[plr] = nil
	end
end

-- Create ESP for existing players
for _, plr in ipairs(Players:GetPlayers()) do
	CreateESPForPlayer(plr)
end

Players.PlayerAdded:Connect(CreateESPForPlayer)
Players.PlayerRemoving:Connect(RemoveESPForPlayer)

-- ESP Update loop
RunService.RenderStepped:Connect(function()
	for plr, data in pairs(espObjects) do
		if not Config.ESP_Enabled then
			data.Billboard.Enabled = false
			continue
		end

		if not plr or not plr.Parent then
			RemoveESPForPlayer(plr)
			continue
		end

		if Config.ESP_TeamCheck and IsTeammate(plr) then
			data.Billboard.Enabled = false
			continue
		end

		if not IsAlive(plr) then
			data.Billboard.Enabled = false
			continue
		end

		local char = plr.Character
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChild("Humanoid")

		if not hrp or not hum then
			data.Billboard.Enabled = false
			continue
		end

		local dist = (RootPart.Position - hrp.Position).Magnitude

		if dist > Config.ESP_MaxDistance then
			data.Billboard.Enabled = false
			continue
		end

		data.Billboard.Enabled = true
		data.Billboard.Adornee = hrp

		-- Box
		data.BoxStroke.Transparency = Config.ESP_Boxes and 0 or 1

		-- Name
		data.NameLabel.Visible = Config.ESP_Names
		data.NameLabel.Text = plr.DisplayName

		-- Distance
		data.DistLabel.Visible = Config.ESP_Distance
		data.DistLabel.Text = math.floor(dist) .. "m"

		-- Health
		data.HealthBG.Visible = Config.ESP_Health
		local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		data.HealthFill.Size = UDim2.new(1, 0, healthPct, 0)
		data.HealthFill.Position = UDim2.new(0, 0, 1 - healthPct, 0)

		-- Color health
		if healthPct > 0.6 then
			data.HealthFill.BackgroundColor3 = Colors.Accent
		elseif healthPct > 0.3 then
			data.HealthFill.BackgroundColor3 = Colors.Warning
		else
			data.HealthFill.BackgroundColor3 = Colors.Danger
		end
	end
end)

-- ═══════════════════════════════════════════
-- CHAMS
-- ═══════════════════════════════════════════
RunService.RenderStepped:Connect(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= Player and plr.Character then
			for _, part in ipairs(plr.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					if Config.ESP_Enabled and Config.ESP_Chams then
						local hl = part:FindFirstChild("EspadaCham")
						if not hl then
							hl = Instance.new("Highlight")
							hl.Name = "EspadaCham"
							hl.FillColor = Colors.Accent
							hl.FillTransparency = 0.6
							hl.OutlineColor = Colors.AccentGlow
							hl.OutlineTransparency = 0.3
							hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
							hl.Adornee = plr.Character
							hl.Parent = plr.Character
						end
					else
						if plr.Character:FindFirstChild("EspadaCham") then
							plr.Character:FindFirstChild("EspadaCham"):Destroy()
						end
					end
				end
			end
		end
	end
end)

-- ═══════════════════════════════════════════
-- TRACERS
-- ═══════════════════════════════════════════
local TracerFolder = Instance.new("Folder")
TracerFolder.Name = "Tracers"
TracerFolder.Parent = ScreenGui

-- Using Drawing API fallback with Frame lines
RunService.RenderStepped:Connect(function()
	-- Clean old tracers
	for _, child in ipairs(TracerFolder:GetChildren()) do
		child:Destroy()
	end

	if not Config.ESP_Enabled or not Config.ESP_Tracers then return end

	local viewportSize = Camera.ViewportSize

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= Player and IsAlive(plr) then
			if Config.ESP_TeamCheck and IsTeammate(plr) then continue end

			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end

			local dist = (RootPart.Position - hrp.Position).Magnitude
			if dist > Config.ESP_MaxDistance then continue end

			local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
			if not onScreen then continue end

			local startPos
			if Config.ESP_TracerOrigin == "Bottom" then
				startPos = Vector2.new(viewportSize.X / 2, viewportSize.Y)
			elseif Config.ESP_TracerOrigin == "Top" then
				startPos = Vector2.new(viewportSize.X / 2, 0)
			elseif Config.ESP_TracerOrigin == "Center" then
				startPos = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
			else
				startPos = UserInputService:GetMouseLocation()
			end

			local endPos = Vector2.new(screenPos.X, screenPos.Y)
			local diff = endPos - startPos
			local length = diff.Magnitude
			local angle = math.deg(math.atan2(diff.Y, diff.X))

			local line = Instance.new("Frame")
			line.BackgroundColor3 = Colors.Accent
			line.BackgroundTransparency = 0.4
			line.Size = UDim2.new(0, length, 0, 1)
			line.Position = UDim2.new(0, startPos.X, 0, startPos.Y)
			line.AnchorPoint = Vector2.new(0, 0.5)
			line.Rotation = angle
			line.BorderSizePixel = 0
			line.ZIndex = 4
			line.Parent = TracerFolder
		end
	end
end)

-- ═══════════════════════════════════════════
-- NOCLIP
-- ═══════════════════════════════════════════
RunService.Stepped:Connect(function()
	if Config.Noclip_Enabled and Character then
		for _, part in ipairs(Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode and input.KeyCode.Name == Config.Noclip_KeyBind then
		Config.Noclip_Enabled = not Config.Noclip_Enabled
		SaveConfig()
		Notify("Noclip", Config.Noclip_Enabled and "Enabled" or "Disabled", 2, Config.Noclip_Enabled and "success" or "info")
	end
end)

-- ═══════════════════════════════════════════
-- SPEED
-- ═══════════════════════════════════════════
RunService.Heartbeat:Connect(function()
	if Config.Speed_Enabled and Humanoid then
		Humanoid.WalkSpeed = Config.Speed_Value
	end
end)

-- ═══════════════════════════════════════════
-- JUMP POWER
-- ═══════════════════════════════════════════
RunService.Heartbeat:Connect(function()
	if Config.Jump_Enabled and Humanoid then
		Humanoid.UseJumpPower = true
		Humanoid.JumpPower = Config.Jump_Value
	end
end)

-- ═══════════════════════════════════════════
-- INFINITE JUMP
-- ═══════════════════════════════════════════
UserInputService.JumpRequest:Connect(function()
	if Config.InfJump_Enabled and Humanoid then
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

-- ═══════════════════════════════════════════
-- FLY
-- ═══════════════════════════════════════════
local flying = false
local flyBV = nil
local flyBG = nil

local function StartFly()
	if flying then return end
	flying = true

	local hrp = Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	flyBV.Velocity = Vector3.new(0, 0, 0)
	flyBV.Parent = hrp

	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	flyBG.CFrame = hrp.CFrame
	flyBG.Parent = hrp

	Humanoid.PlatformStand = true
end

local function StopFly()
	if not flying then return end
	flying = false

	if flyBV then flyBV:Destroy() flyBV = nil end
	if flyBG then flyBG:Destroy() flyBG = nil end

	if Humanoid then
		Humanoid.PlatformStand = false
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode and input.KeyCode.Name == Config.Fly_KeyBind then
		if Config.Fly_Enabled then
			if flying then
				StopFly()
				Notify("Fly", "Disabled", 2, "info")
			else
				StartFly()
				Notify("Fly", "Enabled", 2, "success")
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if flying and flyBV and flyBG then
		local hrp = Character:FindFirstChild("HumanoidRootPart")
		if not hrp then StopFly() return end

		flyBG.CFrame = Camera.CFrame
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

		if moveDir.Magnitude > 0 then
			moveDir = moveDir.Unit
		end

		flyBV.Velocity = moveDir * Config.Fly_Speed
	end
end)

-- Disable fly when feature toggled off
task.spawn(function()
	while true do
		if not Config.Fly_Enabled and flying then
			StopFly()
		end
		task.wait(0.5)
	end
end)

-- ═══════════════════════════════════════════
-- MUSIC PLAYER
-- ═══════════════════════════════════════════
local currentSound = nil

local function PlayMusic()
	if currentSound then
		currentSound:Stop()
		currentSound:Destroy()
		currentSound = nil
	end

	if Config.Music_Enabled and Config.Music_CurrentID ~= "" then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. Config.Music_CurrentID
		sound.Volume = Config.Music_Volume / 100
		sound.Looped = true
		sound.Parent = SoundService
		sound:Play()
		currentSound = sound
	end
end

-- Watch for music changes
task.spawn(function()
	local lastID = ""
	local lastEnabled = false
	local lastVolume = 0
	while true do
		if Config.Music_CurrentID ~= lastID or Config.Music_Enabled ~= lastEnabled then
			lastID = Config.Music_CurrentID
			lastEnabled = Config.Music_Enabled
			if Config.Music_Enabled then
				PlayMusic()
			else
				if currentSound then
					currentSound:Stop()
					currentSound:Destroy()
					currentSound = nil
				end
			end
		end

		if currentSound and Config.Music_Volume ~= lastVolume then
			lastVolume = Config.Music_Volume
			currentSound.Volume = Config.Music_Volume / 100
		end

		task.wait(0.5)
	end
end)

-- ═══════════════════════════════════════════
-- FULLBRIGHT
-- ═══════════════════════════════════════════
local originalAmbient = Lighting.Ambient
local originalBrightness = Lighting.Brightness
local originalOutdoor = Lighting.OutdoorAmbient
local originalFog = Lighting.FogEnd

task.spawn(function()
	while true do
		if Config.Fullbright_Enabled then
			Lighting.Ambient = Color3.fromRGB(255, 255, 255)
			Lighting.Brightness = 2
			Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
			Lighting.FogEnd = 1000000
			Lighting.GlobalShadows = false
		else
			-- Restore (only if we had original values)
			pcall(function()
				Lighting.Ambient = originalAmbient
				Lighting.Brightness = originalBrightness
				Lighting.OutdoorAmbient = originalOutdoor
				Lighting.FogEnd = originalFog
				Lighting.GlobalShadows = true
			end)
		end
		task.wait(1)
	end
end)

-- ═══════════════════════════════════════════
-- SKYBOX
-- ═══════════════════════════════════════════
task.spawn(function()
	while true do
		if Config.Skybox_Enabled then
			local sky = Lighting:FindFirstChildOfClass("Sky")
			if not sky then
				sky = Instance.new("Sky")
				sky.Parent = Lighting
			end
			local id = "rbxassetid://1012890" -- galaxy skybox
			sky.SkyboxBk = id
			sky.SkyboxDn = id
			sky.SkyboxFt = id
			sky.SkyboxLf = id
			sky.SkyboxRt = id
			sky.SkyboxUp = id
			sky.StarCount = 5000
		else
			local sky = Lighting:FindFirstChildOfClass("Sky")
			if sky and sky.Name ~= "DefaultSky" then
				-- Don't remove default skies
			end
		end
		task.wait(1)
	end
end)

-- ═══════════════════════════════════════════
-- FOV CHANGER
-- ═══════════════════════════════════════════
RunService.RenderStepped:Connect(function()
	if Config.FOVChanger_Enabled then
		Camera.FieldOfView = Config.FOVChanger_Value
	end
end)

-- ═══════════════════════════════════════════
-- FPS / PING DISPLAY
-- ═══════════════════════════════════════════
local frameCount = 0
local lastTime = tick()

RunService.RenderStepped:Connect(function()
	frameCount = frameCount + 1

	local now = tick()
	if now - lastTime >= 1 then
		local fps = math.floor(frameCount / (now - lastTime))
		fpsLabel.Text = "FPS: " .. fps
		frameCount = 0
		lastTime = now
	end

	local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
	pingLabel.Text = "Ping: " .. ping .. "ms"

	StatsFrame.Visible = Config.ShowFPS_Enabled or Config.ShowPing_Enabled
	fpsLabel.Visible = Config.ShowFPS_Enabled
	pingLabel.Visible = Config.ShowPing_Enabled

	if Config.ShowFPS_Enabled and not Config.ShowPing_Enabled then
		StatsFrame.Size = UDim2.new(0, 180, 0, 30)
	elseif not Config.ShowFPS_Enabled and Config.ShowPing_Enabled then
		StatsFrame.Size = UDim2.new(0, 180, 0, 30)
		pingLabel.Position = UDim2.new(0, 8, 0, 5)
	else
		StatsFrame.Size = UDim2.new(0, 180, 0, 50)
		pingLabel.Position = UDim2.new(0, 8, 0, 25)
	end
end)

-- ═══════════════════════════════════════════
-- TARGET HUD
-- ═══════════════════════════════════════════
RunService.RenderStepped:Connect(function()
	if not Config.TargetHUD_Enabled then
		TargetHUDFrame.Visible = false
		return
	end

	-- Find closest player in front
	local closest = nil
	local closestDist = 200

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= Player and IsAlive(plr) then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (RootPart.Position - hrp.Position).Magnitude
				if dist < closestDist then
					closest = plr
					closestDist = dist
				end
			end
		end
	end

	if closest and closest.Character then
		TargetHUDFrame.Visible = true
		targetName.Text = closest.DisplayName

		pcall(function()
			targetAvatar.Image = Players:GetUserThumbnailAsync(closest.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)

		local hum = closest.Character:FindFirstChild("Humanoid")
		if hum then
			local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
			Tween(targetHealthFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.2)
			targetHealthText.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)

			if pct > 0.6 then
				targetHealthFill.BackgroundColor3 = Colors.Accent
			elseif pct > 0.3 then
				targetHealthFill.BackgroundColor3 = Colors.Warning
			else
				targetHealthFill.BackgroundColor3 = Colors.Danger
			end
		end
	else
		TargetHUDFrame.Visible = false
	end
end)

-- ═══════════════════════════════════════════
-- INVISIBILITY
-- ═══════════════════════════════════════════
task.spawn(function()
	local lastInvis = false
	while true do
		if Config.Invisibility_Enabled ~= lastInvis then
			lastInvis = Config.Invisibility_Enabled
			if Character then
				for _, part in ipairs(Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = lastInvis and 1 or 0
					elseif part:IsA("Decal") or part:IsA("Texture") then
						part.Transparency = lastInvis and 1 or 0
					end
				end
				-- Keep face visible to self
				local head = Character:FindFirstChild("Head")
				if head then
					head.Transparency = lastInvis and 1 or 0
				end
			end
		end
		task.wait(0.5)
	end
end)

-- ═══════════════════════════════════════════
-- ANTI AFK
-- ═══════════════════════════════════════════
task.spawn(function()
	if Config.AntiAFK_Enabled then
		pcall(function()
			local VirtualUser = game:GetService("VirtualUser")
			Player.Idled:Connect(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	end
end)

-- ═══════════════════════════════════════════
-- CLICK TELEPORT
-- ═══════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if Config.ClickTP_Enabled then
		if input.KeyCode and input.KeyCode.Name == Config.ClickTP_KeyBind then
			local mouseHit = Mouse.Hit
			if mouseHit and RootPart then
				RootPart.CFrame = mouseHit + Vector3.new(0, 3, 0)
				Notify("Teleport", "Teleported!", 1.5, "success")
			end
		end
	end
end)

-- ═══════════════════════════════════════════
-- LOW GRAVITY
-- ═══════════════════════════════════════════
local defaultGravity = workspace.Gravity

task.spawn(function()
	while true do
		if Config.LowGravity_Enabled then
			workspace.Gravity = Config.LowGravity_Value
		else
			workspace.Gravity = defaultGravity
		end
		task.wait(0.5)
	end
end)

-- ═══════════════════════════════════════════
-- NO FALL DAMAGE
-- ═══════════════════════════════════════════
task.spawn(function()
	while true do
		if Config.NoFallDamage_Enabled and Humanoid then
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		end
		task.wait(1)
	end
end)

-- ═══════════════════════════════════════════
-- HITBOX EXPANDER
-- ═══════════════════════════════════════════
task.spawn(function()
	while true do
		if Config.HitboxExpander_Enabled then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= Player and plr.Character then
					local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						hrp.Size = Vector3.new(Config.HitboxExpander_Size, Config.HitboxExpander_Size, Config.HitboxExpander_Size)
						hrp.Transparency = 0.7
						hrp.CanCollide = false
					end
				end
			end
		else
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= Player and plr.Character then
					local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						hrp.Size = Vector3.new(2, 2, 1)
						hrp.Transparency = 1
					end
				end
			end
		end
		task.wait(1)
	end
end)

-- ═══════════════════════════════════════════
-- FOV CIRCLE UPDATE
-- ═══════════════════════════════════════════
RunService.RenderStepped:Connect(function()
	local showFOV = (Config.AimBot_Enabled and Config.AimBot_ShowFOV) or (Config.SilentAim_Enabled and Config.SilentAim_ShowFOV)
	FOVCircle.Visible = showFOV

	if showFOV then
		local fov = Config.AimBot_Enabled and Config.AimBot_FOV or Config.SilentAim_FOV
		FOVCircle.Size = UDim2.new(0, fov * 2, 0, fov * 2)

		local mousePos = UserInputService:GetMouseLocation()
		FOVCircle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
	end
end)

-- ═══════════════════════════════════════════
-- AUTO RESPAWN
-- ═══════════════════════════════════════════
Player.CharacterAdded:Connect(function(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid")
	RootPart = char:WaitForChild("HumanoidRootPart")
end)

task.spawn(function()
	while true do
		if Config.AutoRespawn_Enabled then
			if Humanoid and Humanoid.Health <= 0 then
				task.wait(0.5)
				pcall(function()
					-- Try to respawn
					local reloadChar = Player.Character
					if reloadChar then
						Player:LoadCharacter()
					end
				end)
			end
		end
		task.wait(1)
	end
end)

-- ═══════════════════════════════════════════
-- AMBIENT ANIMATIONS (background decorative)
-- ═══════════════════════════════════════════

-- Accent glow line at top of window
local accentBar = Instance.new("Frame")
accentBar.BackgroundColor3 = Colors.Accent
accentBar.Size = UDim2.new(0.3, 0, 0, 2)
accentBar.Position = UDim2.new(0, 161, 0, 42)
accentBar.BorderSizePixel = 0
accentBar.ZIndex = 15
accentBar.Parent = Window

local accentGlow2 = Instance.new("Frame")
accentGlow2.BackgroundColor3 = Colors.AccentGlow
accentGlow2.BackgroundTransparency = 0.7
accentGlow2.Size = UDim2.new(0.3, 0, 0, 4)
accentGlow2.Position = UDim2.new(0, 161, 0, 41)
accentGlow2.BorderSizePixel = 0
accentGlow2.ZIndex = 14
accentGlow2.Parent = Window

-- Animate accent line
task.spawn(function()
	while Window and Window.Parent do
		Tween(accentBar, {Position = UDim2.new(0.7, 0, 0, 42), Size = UDim2.new(0.3, 0, 0, 2)}, 3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		Tween(accentGlow2, {Position = UDim2.new(0.7, 0, 0, 41)}, 3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.wait(3)
		Tween(accentBar, {Position = UDim2.new(0, 161, 0, 42)}, 3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		Tween(accentGlow2, {Position = UDim2.new(0, 161, 0, 41)}, 3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.wait(3)
	end
end)

-- ═══════════════════════════════════════════
-- WATERMARK
-- ═══════════════════════════════════════════
local Watermark = Instance.new("Frame")
Watermark.Name = "Watermark"
Watermark.BackgroundColor3 = Colors.Surface
Watermark.BackgroundTransparency = 0.2
Watermark.Size = UDim2.new(0, 200, 0, 28)
Watermark.Position = UDim2.new(1, -210, 0, 10)
Watermark.ZIndex = 90
Watermark.Parent = MainGui
CreateCorner(Watermark, 6)
CreateStroke(Watermark, Colors.Accent, 1, 0.6)

local wmText = Instance.new("TextLabel")
wmText.BackgroundTransparency = 1
wmText.Text = "EspadaWare | v2.1"
wmText.Font = Enum.Font.GothamBold
wmText.TextSize = 12
wmText.TextColor3 = Colors.Accent
wmText.Size = UDim2.new(1, 0, 1, 0)
wmText.ZIndex = 91
wmText.Parent = Watermark

-- Update watermark with FPS
task.spawn(function()
	while true do
		local fps = math.floor(1 / RunService.RenderStepped:Wait())
		local ping = 0
		pcall(function()
			ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
		end)
		wmText.Text = "EspadaWare | " .. fps .. " FPS | " .. ping .. "ms"
	end
end)

-- ═══════════════════════════════════════════
-- MOBILE SUPPORT - Touch toggle button
-- ═══════════════════════════════════════════
if UserInputService.TouchEnabled then
	ToggleButton.Size = UDim2.new(0, 54, 0, 54)
	Window.Size = UDim2.new(0, 560, 0, 400)
end

-- ═══════════════════════════════════════════
-- INITIAL LOAD
-- ═══════════════════════════════════════════
task.spawn(function()
	while not keyVerified do task.wait(0.1) end
	task.wait(1)
	Notify("EspadaWare", "All modules loaded. Press RightShift to toggle.", 5, "info")
	Notify("Anti AFK", "Anti-AFK is enabled by default.", 3, "success")
end)

print("[EspadaWare] Loaded successfully!")
