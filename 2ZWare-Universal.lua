-- EspadaWare | Vagrant Survival | Full Script
-- Single LocalScript — place in StarterPlayerScripts or execute

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

--// Config System
local CONFIG_KEY = "EspadaWare_VagrantSurvival_Config"
local DefaultConfig = {
	-- Main
	Aimbot = false,
	AimbotFOV = 120,
	AimbotSmooth = 5,
	AimbotBone = "Head",
	AimbotShowFOV = true,
	AutoAttack = false,
	AutoAttackDelay = 0.3,
	AutoPickup = false,
	AutoPickupRange = 30,
	KillAura = false,
	KillAuraRange = 15,
	-- Movement
	Speed = false,
	SpeedValue = 24,
	InfiniteJump = false,
	JumpPowerValue = 50,
	NoClip = false,
	Fly = false,
	FlySpeed = 50,
	AutoJump = false,
	-- Visuals
	ESP = false,
	ESPShowName = true,
	ESPShowHealth = true,
	ESPShowDistance = true,
	ESPMaxDistance = 500,
	ESPColor = {255, 50, 50},
	Chams = false,
	ChamsColor = {255, 0, 100},
	ChamsFillTransparency = 0.6,
	FullBright = false,
	NoFog = false,
	FOVChanger = false,
	FOVValue = 90,
	-- Settings
	UIKeybind = "RightShift",
	ConfigName = "Default",
}

local Config = {}
for k, v in pairs(DefaultConfig) do
	if type(v) == "table" then
		Config[k] = {unpack(v)}
	else
		Config[k] = v
	end
end

local function deepCopy(t)
	if type(t) ~= "table" then return t end
	local c = {}
	for k, v in pairs(t) do c[k] = deepCopy(v) end
	return c
end

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
	for k, v in pairs(DefaultConfig) do
		if type(v) == "table" then
			Config[k] = {unpack(v)}
		else
			Config[k] = v
		end
	end
	SaveConfig()
end

LoadConfig()

--// GUI Construction
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EspadaWare"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

pcall(function()
	if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
end)

ScreenGui.Parent = Player:WaitForChild("PlayerGui")

--// Color Palette
local Colors = {
	bg = Color3.fromRGB(12, 12, 18),
	sidebar = Color3.fromRGB(16, 16, 24),
	card = Color3.fromRGB(22, 22, 32),
	cardHover = Color3.fromRGB(28, 28, 40),
	accent = Color3.fromRGB(120, 60, 255),
	accentDark = Color3.fromRGB(90, 40, 200),
	accentLight = Color3.fromRGB(160, 100, 255),
	accentGlow = Color3.fromRGB(140, 80, 255),
	text = Color3.fromRGB(230, 230, 240),
	textDim = Color3.fromRGB(140, 140, 160),
	textMuted = Color3.fromRGB(80, 80, 100),
	toggle_on = Color3.fromRGB(120, 60, 255),
	toggle_off = Color3.fromRGB(50, 50, 65),
	danger = Color3.fromRGB(255, 60, 80),
	success = Color3.fromRGB(60, 220, 140),
	slider_bg = Color3.fromRGB(35, 35, 50),
	slider_fill = Color3.fromRGB(120, 60, 255),
	settings_bg = Color3.fromRGB(18, 18, 26),
	overlay = Color3.fromRGB(0, 0, 0),
	divider = Color3.fromRGB(40, 40, 55),
	dropdown_bg = Color3.fromRGB(28, 28, 40),
	dropdown_hover = Color3.fromRGB(38, 38, 55),
}

--// Utility Functions
local function create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, c in ipairs(children or {}) do
		c.Parent = inst
	end
	return inst
end

local function addCorner(parent, radius)
	return create("UICorner", {CornerRadius = UDim.new(0, radius or 8), Parent = parent})
end

local function addStroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color or Colors.accent,
		Thickness = thickness or 1,
		Transparency = transparency or 0.7,
		Parent = parent
	})
end

local function addPadding(parent, t, b, l, r)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, t or 8),
		PaddingBottom = UDim.new(0, b or 8),
		PaddingLeft = UDim.new(0, l or 8),
		PaddingRight = UDim.new(0, r or 8),
		Parent = parent
	})
end

local function addGradient(parent, c1, c2, rotation)
	return create("UIGradient", {
		Color = ColorSequence.new(c1, c2),
		Rotation = rotation or 90,
		Parent = parent
	})
end

local function addShadow(parent)
	local shadow = create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6015897843",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.5,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Size = UDim2.new(1, 30, 1, 30),
		Position = UDim2.new(0, -15, 0, -15),
		ZIndex = -1,
		Parent = parent
	})
	return shadow
end

local function tween(obj, props, dur, style, dir)
	local ti = TweenInfo.new(dur or 0.3, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, ti, props)
	t:Play()
	return t
end

local function ripple(button)
	local rip = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.7,
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = button
	})
	addCorner(rip, 999)
	rip.ClipsDescendants = true
	local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
	tween(rip, {Size = UDim2.new(0, maxSize, 0, maxSize), BackgroundTransparency = 1}, 0.5)
	task.delay(0.5, function() rip:Destroy() end)
end

--// Toggle Button (floating)
local ToggleBtn = create("TextButton", {
	Name = "ToggleBtn",
	Size = UDim2.new(0, 50, 0, 50),
	Position = UDim2.new(0, 15, 0.5, -25),
	AnchorPoint = Vector2.new(0, 0.5),
	BackgroundColor3 = Colors.accent,
	Text = "",
	AutoButtonColor = false,
	Parent = ScreenGui
})
addCorner(ToggleBtn, 25)
addShadow(ToggleBtn)
addGradient(ToggleBtn, Colors.accent, Colors.accentLight, 135)

local ToggleIcon = create("TextLabel", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "E",
	TextColor3 = Colors.text,
	Font = Enum.Font.GothamBold,
	TextSize = 22,
	Parent = ToggleBtn
})

-- Draggable toggle button (mobile)
local toggleDragging = false
local toggleDragStart, toggleStartPos
ToggleBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		toggleDragging = true
		toggleDragStart = input.Position
		toggleStartPos = ToggleBtn.Position
	end
end)
ToggleBtn.InputChanged:Connect(function(input)
	if toggleDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - toggleDragStart
		ToggleBtn.Position = UDim2.new(
			toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X,
			toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y
		)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		toggleDragging = false
	end
end)

--// Main Frame
local guiVisible = false

local MainFrame = create("Frame", {
	Name = "MainFrame",
	Size = UDim2.new(0, 540, 0, 400),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Colors.bg,
	ClipsDescendants = true,
	Visible = false,
	Parent = ScreenGui
})
addCorner(MainFrame, 14)
addStroke(MainFrame, Colors.accent, 1.5, 0.5)
addShadow(MainFrame)

-- Title Bar
local TitleBar = create("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundColor3 = Colors.sidebar,
	BorderSizePixel = 0,
	Parent = MainFrame
})
addCorner(TitleBar, 14)
-- Bottom corners fix
create("Frame", {
	Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.new(0, 0, 1, -16),
	BackgroundColor3 = Colors.sidebar,
	BorderSizePixel = 0,
	Parent = TitleBar
})

local TitleGlow = create("Frame", {
	Size = UDim2.new(0.3, 0, 0, 2),
	Position = UDim2.new(0, 16, 1, -1),
	BackgroundColor3 = Colors.accent,
	BorderSizePixel = 0,
	Parent = TitleBar
})
addCorner(TitleGlow, 1)

local TitleLabel = create("TextLabel", {
	Size = UDim2.new(0, 200, 1, 0),
	Position = UDim2.new(0, 16, 0, 0),
	BackgroundTransparency = 1,
	Text = "EspadaWare",
	TextColor3 = Colors.text,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = TitleBar
})

local VersionLabel = create("TextLabel", {
	Size = UDim2.new(0, 50, 1, 0),
	Position = UDim2.new(0, 142, 0, 1),
	BackgroundTransparency = 1,
	Text = "v2.0",
	TextColor3 = Colors.accentLight,
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = TitleBar
})

local CloseBtn = create("TextButton", {
	Size = UDim2.new(0, 32, 0, 32),
	Position = UDim2.new(1, -40, 0.5, -16),
	BackgroundColor3 = Colors.danger,
	BackgroundTransparency = 0.8,
	Text = "✕",
	TextColor3 = Colors.danger,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	AutoButtonColor = false,
	Parent = TitleBar
})
addCorner(CloseBtn, 8)

-- Dragging MainFrame
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
	end
end)
TitleBar.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

--// Sidebar (Tabs)
local Sidebar = create("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, 120, 1, -44),
	Position = UDim2.new(0, 0, 0, 44),
	BackgroundColor3 = Colors.sidebar,
	BorderSizePixel = 0,
	Parent = MainFrame
})
create("Frame", {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Colors.divider, BorderSizePixel = 0, Parent = Sidebar})

local SidebarLayout = create("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 4),
	Parent = Sidebar
})
addPadding(Sidebar, 10, 10, 8, 8)

local Tabs = {"Main", "Movement", "Visuals", "Settings"}
local TabIcons = {Main = "⚔", Movement = "🏃", Visuals = "👁", Settings = "⚙"}
local TabButtons = {}
local TabPages = {}
local ActiveTab = "Main"

--// Content Area
local ContentArea = create("Frame", {
	Name = "ContentArea",
	Size = UDim2.new(1, -120, 1, -44),
	Position = UDim2.new(0, 120, 0, 44),
	BackgroundColor3 = Colors.bg,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = MainFrame
})

--// Settings Panel (overlay for gear settings)
local SettingsOverlay = create("Frame", {
	Name = "SettingsOverlay",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Colors.overlay,
	BackgroundTransparency = 0.4,
	Visible = false,
	ZIndex = 50,
	Parent = ContentArea
})

local SettingsPanel = create("Frame", {
	Name = "SettingsPanel",
	Size = UDim2.new(0.85, 0, 0.9, 0),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Colors.settings_bg,
	ZIndex = 51,
	ClipsDescendants = true,
	Parent = SettingsOverlay
})
addCorner(SettingsPanel, 12)
addStroke(SettingsPanel, Colors.accent, 1, 0.6)

local SettingsTitleBar = create("Frame", {
	Size = UDim2.new(1, 0, 0, 38),
	BackgroundColor3 = Colors.card,
	BorderSizePixel = 0,
	ZIndex = 52,
	Parent = SettingsPanel
})
addCorner(SettingsTitleBar, 12)
create("Frame", {Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), BackgroundColor3 = Colors.card, BorderSizePixel = 0, ZIndex = 52, Parent = SettingsTitleBar})

local SettingsTitleLabel = create("TextLabel", {
	Size = UDim2.new(1, -50, 1, 0),
	Position = UDim2.new(0, 14, 0, 0),
	BackgroundTransparency = 1,
	Text = "Settings",
	TextColor3 = Colors.text,
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 53,
	Parent = SettingsTitleBar
})

local SettingsCloseBtn = create("TextButton", {
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(1, -34, 0.5, -14),
	BackgroundColor3 = Colors.danger,
	BackgroundTransparency = 0.8,
	Text = "✕",
	TextColor3 = Colors.danger,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	AutoButtonColor = false,
	ZIndex = 53,
	Parent = SettingsTitleBar
})
addCorner(SettingsCloseBtn, 7)

local SettingsContent = create("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, -42),
	Position = UDim2.new(0, 0, 0, 42),
	BackgroundTransparency = 1,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = Colors.accent,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ZIndex = 52,
	Parent = SettingsPanel
})
create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = SettingsContent})
addPadding(SettingsContent, 8, 8, 12, 12)

local function closeSettingsPanel()
	tween(SettingsPanel, {Position = UDim2.new(0.5, 0, 1.5, 0)}, 0.3)
	tween(SettingsOverlay, {BackgroundTransparency = 1}, 0.3).Completed:Connect(function()
		SettingsOverlay.Visible = false
	end)
end

SettingsCloseBtn.MouseButton1Click:Connect(closeSettingsPanel)
SettingsOverlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		local pos = input.Position
		local panelPos = SettingsPanel.AbsolutePosition
		local panelSize = SettingsPanel.AbsoluteSize
		if pos.X < panelPos.X or pos.X > panelPos.X + panelSize.X or pos.Y < panelPos.Y or pos.Y > panelPos.Y + panelSize.Y then
			closeSettingsPanel()
		end
	end
end)

local function openSettingsPanel(title, buildFunc)
	for _, c in ipairs(SettingsContent:GetChildren()) do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
	end
	SettingsTitleLabel.Text = title .. " Settings"
	buildFunc(SettingsContent)
	SettingsOverlay.Visible = true
	SettingsOverlay.BackgroundTransparency = 1
	SettingsPanel.Position = UDim2.new(0.5, 0, 1.5, 0)
	tween(SettingsOverlay, {BackgroundTransparency = 0.4}, 0.3)
	tween(SettingsPanel, {Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.35, Enum.EasingStyle.Back)
end

--// UI Element Builders (for settings panel)
local function buildToggle(parent, label, configKey, zIndex)
	local zi = zIndex or 52
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Colors.card,
		ZIndex = zi,
		Parent = parent
	})
	addCorner(row, 8)
	local lbl = create("TextLabel", {
		Size = UDim2.new(1, -60, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = Colors.text,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = zi + 1,
		Parent = row
	})
	local toggleBg = create("Frame", {
		Size = UDim2.new(0, 40, 0, 22),
		Position = UDim2.new(1, -52, 0.5, -11),
		BackgroundColor3 = Config[configKey] and Colors.toggle_on or Colors.toggle_off,
		ZIndex = zi + 1,
		Parent = row
	})
	addCorner(toggleBg, 11)
	local toggleCircle = create("Frame", {
		Size = UDim2.new(0, 18, 0, 18),
		Position = Config[configKey] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
		BackgroundColor3 = Colors.text,
		ZIndex = zi + 2,
		Parent = toggleBg
	})
	addCorner(toggleCircle, 9)

	local btn = create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = zi + 3,
		Parent = row
	})
	btn.MouseButton1Click:Connect(function()
		Config[configKey] = not Config[configKey]
		tween(toggleBg, {BackgroundColor3 = Config[configKey] and Colors.toggle_on or Colors.toggle_off}, 0.2)
		tween(toggleCircle, {Position = Config[configKey] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}, 0.2)
		SaveConfig()
	end)
	return row
end

local function buildSlider(parent, label, configKey, min, max, step, zIndex)
	local zi = zIndex or 52
	step = step or 1
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Colors.card,
		ZIndex = zi,
		Parent = parent
	})
	addCorner(row, 8)

	local lbl = create("TextLabel", {
		Size = UDim2.new(1, -70, 0, 22),
		Position = UDim2.new(0, 12, 0, 4),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = Colors.text,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = zi + 1,
		Parent = row
	})
	local valLabel = create("TextLabel", {
		Size = UDim2.new(0, 50, 0, 22),
		Position = UDim2.new(1, -60, 0, 4),
		BackgroundTransparency = 1,
		Text = tostring(Config[configKey]),
		TextColor3 = Colors.accentLight,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = zi + 1,
		Parent = row
	})

	local sliderBg = create("Frame", {
		Size = UDim2.new(1, -24, 0, 8),
		Position = UDim2.new(0, 12, 0, 34),
		BackgroundColor3 = Colors.slider_bg,
		ZIndex = zi + 1,
		Parent = row
	})
	addCorner(sliderBg, 4)

	local pct = math.clamp((Config[configKey] - min) / (max - min), 0, 1)
	local sliderFill = create("Frame", {
		Size = UDim2.new(pct, 0, 1, 0),
		BackgroundColor3 = Colors.slider_fill,
		ZIndex = zi + 2,
		Parent = sliderBg
	})
	addCorner(sliderFill, 4)

	local sliderKnob = create("Frame", {
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(pct, -8, 0.5, -8),
		BackgroundColor3 = Colors.text,
		ZIndex = zi + 3,
		Parent = sliderBg
	})
	addCorner(sliderKnob, 8)

	local sliderBtn = create("TextButton", {
		Size = UDim2.new(1, 10, 0, 26),
		Position = UDim2.new(0, -5, 0, -9),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = zi + 4,
		Parent = sliderBg
	})

	local sliding = false
	local function updateSlider(inputPos)
		local absPos = sliderBg.AbsolutePosition.X
		local absSize = sliderBg.AbsoluteSize.X
		local rel = math.clamp((inputPos.X - absPos) / absSize, 0, 1)
		local raw = min + rel * (max - min)
		local val = math.floor(raw / step + 0.5) * step
		val = math.clamp(val, min, max)
		Config[configKey] = val
		local newPct = (val - min) / (max - min)
		sliderFill.Size = UDim2.new(newPct, 0, 1, 0)
		sliderKnob.Position = UDim2.new(newPct, -8, 0.5, -8)
		valLabel.Text = tostring(val)
	end

	sliderBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = true
			updateSlider(input.Position)
		end
	end)
	sliderBtn.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
			updateSlider(input.Position)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
			sliding = false
			SaveConfig()
		end
	end)

	return row
end

local function buildDropdown(parent, label, configKey, options, zIndex)
	local zi = zIndex or 52
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Colors.card,
		ZIndex = zi,
		ClipsDescendants = false,
		Parent = parent
	})
	addCorner(row, 8)

	create("TextLabel", {
		Size = UDim2.new(0.5, -6, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = Colors.text,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = zi + 1,
		Parent = row
	})

	local dropBtn = create("TextButton", {
		Size = UDim2.new(0.45, 0, 0, 26),
		Position = UDim2.new(0.53, 0, 0.5, -13),
		BackgroundColor3 = Colors.dropdown_bg,
		Text = tostring(Config[configKey]),
		TextColor3 = Colors.accentLight,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		AutoButtonColor = false,
		ZIndex = zi + 2,
		Parent = row
	})
	addCorner(dropBtn, 6)
	addStroke(dropBtn, Colors.accent, 1, 0.7)

	local dropList = create("Frame", {
		Size = UDim2.new(0.45, 0, 0, #options * 28 + 4),
		Position = UDim2.new(0.53, 0, 1, 4),
		BackgroundColor3 = Colors.dropdown_bg,
		Visible = false,
		ZIndex = zi + 10,
		ClipsDescendants = true,
		Parent = row
	})
	addCorner(dropList, 6)
	addStroke(dropList, Colors.accent, 1, 0.6)
	create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = dropList})
	addPadding(dropList, 2, 2, 2, 2)

	for i, opt in ipairs(options) do
		local optBtn = create("TextButton", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = Colors.dropdown_bg,
			Text = tostring(opt),
			TextColor3 = Colors.text,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			AutoButtonColor = false,
			ZIndex = zi + 11,
			Parent = dropList
		})
		addCorner(optBtn, 5)
		optBtn.MouseEnter:Connect(function() tween(optBtn, {BackgroundColor3 = Colors.dropdown_hover}, 0.15) end)
		optBtn.MouseLeave:Connect(function() tween(optBtn, {BackgroundColor3 = Colors.dropdown_bg}, 0.15) end)
		optBtn.MouseButton1Click:Connect(function()
			Config[configKey] = opt
			dropBtn.Text = tostring(opt)
			dropList.Visible = false
			SaveConfig()
		end)
	end

	dropBtn.MouseButton1Click:Connect(function()
		dropList.Visible = not dropList.Visible
	end)

	return row
end

--// Function Card Builder
local function buildFunctionCard(parent, name, configKey, icon, settingsBuilder)
	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = Colors.card,
		Parent = parent
	})
	addCorner(card, 10)

	card.MouseEnter:Connect(function() tween(card, {BackgroundColor3 = Colors.cardHover}, 0.2) end)
	card.MouseLeave:Connect(function() tween(card, {BackgroundColor3 = Colors.card}, 0.2) end)

	local iconLbl = create("TextLabel", {
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(0, 10, 0.5, -15),
		BackgroundTransparency = 1,
		Text = icon or "⚡",
		TextSize = 18,
		Font = Enum.Font.Gotham,
		TextColor3 = Colors.accentLight,
		Parent = card
	})

	local nameLbl = create("TextLabel", {
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.new(0, 44, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Colors.text,
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card
	})

	-- Toggle
	local toggleBg = create("Frame", {
		Size = UDim2.new(0, 40, 0, 22),
		Position = UDim2.new(1, -90, 0.5, -11),
		BackgroundColor3 = Config[configKey] and Colors.toggle_on or Colors.toggle_off,
		Parent = card
	})
	addCorner(toggleBg, 11)
	local toggleCircle = create("Frame", {
		Size = UDim2.new(0, 18, 0, 18),
		Position = Config[configKey] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
		BackgroundColor3 = Colors.text,
		Parent = toggleBg
	})
	addCorner(toggleCircle, 9)

	local toggleBtn = create("TextButton", {
		Size = UDim2.new(0, 44, 0, 44),
		Position = UDim2.new(1, -93, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = card
	})
	toggleBtn.MouseButton1Click:Connect(function()
		Config[configKey] = not Config[configKey]
		tween(toggleBg, {BackgroundColor3 = Config[configKey] and Colors.toggle_on or Colors.toggle_off}, 0.2)
		tween(toggleCircle, {Position = Config[configKey] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}, 0.2)
		SaveConfig()
	end)

	-- Gear button
	if settingsBuilder then
		local gearBtn = create("TextButton", {
			Size = UDim2.new(0, 32, 0, 32),
			Position = UDim2.new(1, -42, 0.5, -16),
			BackgroundColor3 = Colors.card,
			Text = "⚙",
			TextColor3 = Colors.textDim,
			Font = Enum.Font.Gotham,
			TextSize = 16,
			AutoButtonColor = false,
			Parent = card
		})
		addCorner(gearBtn, 8)
		gearBtn.MouseEnter:Connect(function() tween(gearBtn, {TextColor3 = Colors.accentLight}, 0.15) end)
		gearBtn.MouseLeave:Connect(function() tween(gearBtn, {TextColor3 = Colors.textDim}, 0.15) end)
		gearBtn.MouseButton1Click:Connect(function()
			ripple(gearBtn)
			openSettingsPanel(name, settingsBuilder)
		end)
	end

	return card
end

--// Build Tab Pages
for _, tabName in ipairs(Tabs) do
	local page = create("ScrollingFrame", {
		Name = tabName .. "Page",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Colors.accent,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = tabName == ActiveTab,
		Parent = ContentArea
	})
	create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = page})
	addPadding(page, 10, 10, 10, 10)
	TabPages[tabName] = page
end

--// Tab Buttons
for i, tabName in ipairs(Tabs) do
	local tabBtn = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = tabName == ActiveTab and Colors.accent or Colors.sidebar,
		BackgroundTransparency = tabName == ActiveTab and 0.15 or 1,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = i,
		Parent = Sidebar
	})
	addCorner(tabBtn, 8)

	local accent = create("Frame", {
		Size = UDim2.new(0, 3, 0.6, 0),
		Position = UDim2.new(0, 0, 0.2, 0),
		BackgroundColor3 = Colors.accent,
		Visible = tabName == ActiveTab,
		Parent = tabBtn
	})
	addCorner(accent, 2)

	local iconLbl = create("TextLabel", {
		Size = UDim2.new(0, 28, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = TabIcons[tabName],
		TextSize = 15,
		Font = Enum.Font.Gotham,
		TextColor3 = tabName == ActiveTab and Colors.accentLight or Colors.textDim,
		Parent = tabBtn
	})

	local lbl = create("TextLabel", {
		Size = UDim2.new(1, -44, 1, 0),
		Position = UDim2.new(0, 38, 0, 0),
		BackgroundTransparency = 1,
		Text = tabName,
		TextColor3 = tabName == ActiveTab and Colors.text or Colors.textDim,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = tabBtn
	})

	TabButtons[tabName] = {btn = tabBtn, accent = accent, icon = iconLbl, label = lbl}

	tabBtn.MouseButton1Click:Connect(function()
		ripple(tabBtn)
		for name, data in pairs(TabButtons) do
			local isActive = name == tabName
			tween(data.btn, {BackgroundTransparency = isActive and 0.15 or 1}, 0.2)
			data.accent.Visible = isActive
			tween(data.icon, {TextColor3 = isActive and Colors.accentLight or Colors.textDim}, 0.2)
			tween(data.label, {TextColor3 = isActive and Colors.text or Colors.textDim}, 0.2)
			TabPages[name].Visible = isActive
		end
		ActiveTab = tabName
	end)
end

--// ============================================
--// POPULATE TABS WITH FUNCTIONS
--// ============================================

--// MAIN TAB
local mainPage = TabPages["Main"]

-- Section label
local function sectionLabel(parent, text)
	local lbl = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Colors.textMuted,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent
	})
	return lbl
end

sectionLabel(mainPage, "COMBAT")

-- Aimbot
buildFunctionCard(mainPage, "Aimbot", "Aimbot", "🎯", function(container)
	buildSlider(container, "FOV Radius", "AimbotFOV", 30, 500, 5)
	buildSlider(container, "Smoothness", "AimbotSmooth", 1, 20, 1)
	buildDropdown(container, "Target Bone", "AimbotBone", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"})
	buildToggle(container, "Show FOV Circle", "AimbotShowFOV")
end)

-- Kill Aura
buildFunctionCard(mainPage, "Kill Aura", "KillAura", "💀", function(container)
	buildSlider(container, "Range", "KillAuraRange", 5, 50, 1)
end)

-- Auto Attack
buildFunctionCard(mainPage, "Auto Attack", "AutoAttack", "⚔", function(container)
	buildSlider(container, "Delay (s)", "AutoAttackDelay", 0.05, 2, 0.05)
end)

sectionLabel(mainPage, "UTILITY")

-- Auto Pickup
buildFunctionCard(mainPage, "Auto Pickup", "AutoPickup", "🧲", function(container)
	buildSlider(container, "Range", "AutoPickupRange", 10, 100, 5)
end)

--// MOVEMENT TAB
local movePage = TabPages["Movement"]
sectionLabel(movePage, "MOVEMENT")

-- Speed
buildFunctionCard(movePage, "Speed Hack", "Speed", "💨", function(container)
	buildSlider(container, "Walk Speed", "SpeedValue", 16, 200, 1)
end)

-- Infinite Jump
buildFunctionCard(movePage, "Infinite Jump", "InfiniteJump", "🦘", function(container)
	buildSlider(container, "Jump Power", "JumpPowerValue", 20, 200, 5)
end)

-- NoClip
buildFunctionCard(movePage, "NoClip", "NoClip", "👻", nil)

-- Fly
buildFunctionCard(movePage, "Fly", "Fly", "🕊", function(container)
	buildSlider(container, "Fly Speed", "FlySpeed", 10, 200, 5)
end)

-- Auto Jump
buildFunctionCard(movePage, "Auto Jump", "AutoJump", "⬆", nil)

--// VISUALS TAB
local visualsPage = TabPages["Visuals"]
sectionLabel(visualsPage, "PLAYER ESP")

-- ESP
buildFunctionCard(visualsPage, "ESP", "ESP", "👁", function(container)
	buildToggle(container, "Show Name", "ESPShowName")
	buildToggle(container, "Show Health", "ESPShowHealth")
	buildToggle(container, "Show Distance", "ESPShowDistance")
	buildSlider(container, "Max Distance", "ESPMaxDistance", 100, 2000, 50)
end)

-- Chams
buildFunctionCard(visualsPage, "Chams", "Chams", "🔮", function(container)
	buildSlider(container, "Fill Transparency", "ChamsFillTransparency", 0, 1, 0.1)
end)

sectionLabel(visualsPage, "WORLD")

-- FullBright
buildFunctionCard(visualsPage, "Full Bright", "FullBright", "☀", nil)

-- No Fog
buildFunctionCard(visualsPage, "No Fog", "NoFog", "🌫", nil)

-- FOV Changer
buildFunctionCard(visualsPage, "FOV Changer", "FOVChanger", "🔭", function(container)
	buildSlider(container, "Field of View", "FOVValue", 30, 120, 1)
end)

--// SETTINGS TAB
local settingsPage = TabPages["Settings"]
sectionLabel(settingsPage, "CONFIGURATION")

-- Save Config Button
local saveBtn = create("TextButton", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = Colors.accent,
	Text = "💾  Save Config",
	TextColor3 = Colors.text,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	AutoButtonColor = false,
	Parent = settingsPage
})
addCorner(saveBtn, 10)
addGradient(saveBtn, Colors.accent, Colors.accentDark, 90)
saveBtn.MouseButton1Click:Connect(function()
	ripple(saveBtn)
	SaveConfig()
end)

-- Load Config Button
local loadBtn = create("TextButton", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = Colors.card,
	Text = "📂  Load Config",
	TextColor3 = Colors.text,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	AutoButtonColor = false,
	Parent = settingsPage
})
addCorner(loadBtn, 10)
addStroke(loadBtn, Colors.accent, 1, 0.6)
loadBtn.MouseButton1Click:Connect(function()
	ripple(loadBtn)
	LoadConfig()
end)

-- Reset Config Button
local resetBtn = create("TextButton", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = Colors.danger,
	BackgroundTransparency = 0.7,
	Text = "🗑  Reset Config",
	TextColor3 = Colors.danger,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	AutoButtonColor = false,
	Parent = settingsPage
})
addCorner(resetBtn, 10)
resetBtn.MouseButton1Click:Connect(function()
	ripple(resetBtn)
	ResetConfig()
end)

sectionLabel(settingsPage, "INTERFACE")

-- UI Keybind info
create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundTransparency = 1,
	Text = "Toggle UI: Floating Button / RightShift",
	TextColor3 = Colors.textDim,
	Font = Enum.Font.Gotham,
	TextSize = 12,
	Parent = settingsPage
})

sectionLabel(settingsPage, "INFO")

create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 50),
	BackgroundTransparency = 1,
	Text = "EspadaWare v2.0\nVagrant Survival\nMade with ❤",
	TextColor3 = Colors.textMuted,
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextYAlignment = Enum.TextYAlignment.Top,
	Parent = settingsPage
})

--// ============================================
--// GUI Show/Hide Logic
--// ============================================

local function showGUI()
	guiVisible = true
	MainFrame.Visible = true
	MainFrame.Size = UDim2.new(0, 0, 0, 0)
	MainFrame.BackgroundTransparency = 1
	tween(MainFrame, {Size = UDim2.new(0, 540, 0, 400), BackgroundTransparency = 0}, 0.35, Enum.EasingStyle.Back)
end

local function hideGUI()
	guiVisible = false
	local t = tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.25)
	t.Completed:Connect(function()
		if not guiVisible then
			MainFrame.Visible = false
		end
	end)
end

ToggleBtn.MouseButton1Click:Connect(function()
	-- Only toggle if not dragged significantly
	if guiVisible then hideGUI() else showGUI() end
end)

CloseBtn.MouseButton1Click:Connect(hideGUI)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		if guiVisible then hideGUI() else showGUI() end
	end
end)

--// ============================================
--// FUNCTIONAL BACKEND — ALL FEATURES
--// ============================================

--// Utility: get closest player to screen center within FOV
local function getClosestPlayer(fov)
	local closest, closestDist = nil, fov
	local cam = Camera
	local myChar = Player.Character
	if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
	local myPos = myChar.HumanoidRootPart.Position

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= Player and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
			local bone = p.Character:FindFirstChild(Config.AimbotBone) or p.Character:FindFirstChild("Head")
			if bone then
				local screenPos, onScreen = cam:WorldToScreenPoint(bone.Position)
				if onScreen then
					local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
					if dist < closestDist then
						closestDist = dist
						closest = p
					end
				end
			end
		end
	end
	return closest
end

--// FOV Circle for aimbot
local fovCircle = Drawing and Drawing.new("Circle")
if fovCircle then
	fovCircle.Thickness = 1
	fovCircle.Filled = false
	fovCircle.Transparency = 0.7
	fovCircle.Color = Color3.fromRGB(120, 60, 255)
	fovCircle.Visible = false
end

--// AIMBOT
RunService.RenderStepped:Connect(function()
	-- FOV circle
	if fovCircle then
		fovCircle.Visible = Config.Aimbot and Config.AimbotShowFOV
		fovCircle.Radius = Config.AimbotFOV
		fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	end

	if Config.Aimbot then
		local target = getClosestPlayer(Config.AimbotFOV)
		if target and target.Character then
			local bone = target.Character:FindFirstChild(Config.AimbotBone) or target.Character:FindFirstChild("Head")
			if bone then
				local targetCF = CFrame.new(Camera.CFrame.Position, bone.Position)
				Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / Config.AimbotSmooth)
			end
		end
	end
end)

--// SPEED HACK
RunService.Heartbeat:Connect(function()
	if Config.Speed then
		local char = Player.Character
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid.WalkSpeed = Config.SpeedValue
		end
	end
end)

--// INFINITE JUMP
UserInputService.JumpRequest:Connect(function()
	if Config.InfiniteJump then
		local char = Player.Character
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			char.Humanoid.JumpPower = Config.JumpPowerValue
		end
	end
end)

--// NOCLIP
RunService.Stepped:Connect(function()
	if Config.NoClip then
		local char = Player.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
	end
end)

--// FLY
local flyBV = nil
local flyBG = nil

local function startFly()
	local char = Player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local hrp = char.HumanoidRootPart

	if flyBV then flyBV:Destroy() end
	if flyBG then flyBG:Destroy() end

	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	flyBV.Velocity = Vector3.new(0, 0, 0)
	flyBV.Parent = hrp

	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	flyBG.D = 100
	flyBG.P = 10000
	flyBG.Parent = hrp
end

local function stopFly()
	if flyBV then flyBV:Destroy() flyBV = nil end
	if flyBG then flyBG:Destroy() flyBG = nil end
end

local flyActive = false
RunService.RenderStepped:Connect(function()
	if Config.Fly then
		if not flyActive then
			flyActive = true
			startFly()
		end
		local char = Player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and flyBV and flyBG then
			local hrp = char.HumanoidRootPart
			flyBG.CFrame = Camera.CFrame
			local dir = Vector3.new(0, 0, 0)
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

			-- Mobile: use humanoid MoveDirection
			if dir.Magnitude < 0.1 then
				local humanoid = char:FindFirstChild("Humanoid")
				if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
					dir = humanoid.MoveDirection + Vector3.new(0, 0, 0)
				end
			end

			if dir.Magnitude > 0 then
				flyBV.Velocity = dir.Unit * Config.FlySpeed
			else
				flyBV.Velocity = Vector3.new(0, 0, 0)
			end
		end
	else
		if flyActive then
			flyActive = false
			stopFly()
		end
	end
end)

--// AUTO JUMP
RunService.Heartbeat:Connect(function()
	if Config.AutoJump then
		local char = Player.Character
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid.Jump = true
		end
	end
end)

--// AUTO ATTACK
task.spawn(function()
	while true do
		if Config.AutoAttack then
			local char = Player.Character
			if char then
				-- Try to find and activate tool
				for _, tool in ipairs(char:GetChildren()) do
					if tool:IsA("Tool") then
						pcall(function() tool:Activate() end)
					end
				end
				-- Also try ClickDetector or virtual input
				pcall(function()
					local VIM = game:GetService("VirtualInputManager")
					VIM:SendMouseButtonEvent(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2, 0, true, game, 1)
					task.wait(0.03)
					VIM:SendMouseButtonEvent(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2, 0, false, game, 1)
				end)
			end
		end
		task.wait(Config.AutoAttackDelay)
	end
end)

--// KILL AURA
task.spawn(function()
	while true do
		if Config.KillAura then
			local char = Player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local myPos = char.HumanoidRootPart.Position
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
						local dist = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
						if dist <= Config.KillAuraRange then
							-- Activate tools towards target
							for _, tool in ipairs(char:GetChildren()) do
								if tool:IsA("Tool") then
									pcall(function() tool:Activate() end)
								end
							end
							-- Try remote events (game-specific)
							pcall(function()
								local VIM = game:GetService("VirtualInputManager")
								local screenPos = Camera:WorldToScreenPoint(p.Character.HumanoidRootPart.Position)
								VIM:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, game, 1)
								task.wait(0.02)
								VIM:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, game, 1)
							end)
						end
					end
				end
			end
		end
		task.wait(0.2)
	end
end)

--// AUTO PICKUP
task.spawn(function()
	while true do
		if Config.AutoPickup then
			local char = Player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local myPos = char.HumanoidRootPart.Position
				-- Look for dropped items / ClickDetectors / ProximityPrompts
				for _, obj in ipairs(Workspace:GetDescendants()) do
					pcall(function()
						if obj:IsA("ProximityPrompt") then
							local part = obj.Parent
							if part and part:IsA("BasePart") then
								local dist = (part.Position - myPos).Magnitude
								if dist <= Config.AutoPickupRange then
									fireproximityprompt(obj)
								end
							end
						elseif obj:IsA("ClickDetector") then
							local part = obj.Parent
							if part and part:IsA("BasePart") then
								local dist = (part.Position - myPos).Magnitude
								if dist <= Config.AutoPickupRange then
									fireclickdetector(obj)
								end
							end
						elseif obj:IsA("Tool") and obj.Parent == Workspace then
							local handle = obj:FindFirstChild("Handle")
							if handle then
								local dist = (handle.Position - myPos).Magnitude
								if dist <= Config.AutoPickupRange then
									-- Move to pickup
									char.HumanoidRootPart.CFrame = handle.CFrame
								end
							end
						end
					end)
				end
			end
		end
		task.wait(0.5)
	end
end)

--// ESP System
local ESPFolder = Instance.new("Folder", Camera)
ESPFolder.Name = "EspadaESP"

local espCache = {}

local function createESP(plr)
	if plr == Player then return end
	if espCache[plr] then return end

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "ESP_" .. plr.Name
	billboardGui.AlwaysOnTop = true
	billboardGui.Size = UDim2.new(0, 200, 0, 60)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.LightInfluence = 0
	billboardGui.Parent = ESPFolder

	local nameLabel = Instance.new("TextLabel", billboardGui)
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 18)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(Config.ESPColor[1], Config.ESPColor[2], Config.ESPColor[3])
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.Text = plr.Name

	local healthLabel = Instance.new("TextLabel", billboardGui)
	healthLabel.Name = "HealthLabel"
	healthLabel.Size = UDim2.new(1, 0, 0, 14)
	healthLabel.Position = UDim2.new(0, 0, 0, 18)
	healthLabel.BackgroundTransparency = 1
	healthLabel.TextColor3 = Colors.success
	healthLabel.Font = Enum.Font.Gotham
	healthLabel.TextSize = 12
	healthLabel.TextStrokeTransparency = 0.5
	healthLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	healthLabel.Text = "100 HP"

	local distLabel = Instance.new("TextLabel", billboardGui)
	distLabel.Name = "DistLabel"
	distLabel.Size = UDim2.new(1, 0, 0, 14)
	distLabel.Position = UDim2.new(0, 0, 0, 32)
	distLabel.BackgroundTransparency = 1
	distLabel.TextColor3 = Colors.textDim
	distLabel.Font = Enum.Font.Gotham
	distLabel.TextSize = 11
	distLabel.TextStrokeTransparency = 0.5
	distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	distLabel.Text = "0m"

	-- Health bar background
	local healthBarBg = Instance.new("Frame", billboardGui)
	healthBarBg.Name = "HealthBarBg"
	healthBarBg.Size = UDim2.new(0.8, 0, 0, 4)
	healthBarBg.Position = UDim2.new(0.1, 0, 0, 48)
	healthBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	healthBarBg.BorderSizePixel = 0
	Instance.new("UICorner", healthBarBg).CornerRadius = UDim.new(0, 2)

	local healthBarFill = Instance.new("Frame", healthBarBg)
	healthBarFill.Name = "Fill"
	healthBarFill.Size = UDim2.new(1, 0, 1, 0)
	healthBarFill.BackgroundColor3 = Colors.success
	healthBarFill.BorderSizePixel = 0
	Instance.new("UICorner", healthBarFill).CornerRadius = UDim.new(0, 2)

	espCache[plr] = billboardGui
end

local function removeESP(plr)
	if espCache[plr] then
		espCache[plr]:Destroy()
		espCache[plr] = nil
	end
end

-- ESP Chams cache
local chamsCache = {}

local function createChams(plr)
	if plr == Player then return end
	if chamsCache[plr] then return end
	local char = plr.Character
	if not char then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "Chams_" .. plr.Name
	highlight.FillColor = Color3.fromRGB(Config.ChamsColor[1], Config.ChamsColor[2], Config.ChamsColor[3])
	highlight.FillTransparency = Config.ChamsFillTransparency
	highlight.OutlineColor = Color3.fromRGB(Config.ChamsColor[1], Config.ChamsColor[2], Config.ChamsColor[3])
	highlight.OutlineTransparency = 0.3
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = char
	highlight.Parent = ESPFolder
	chamsCache[plr] = highlight
end

local function removeChams(plr)
	if chamsCache[plr] then
		chamsCache[plr]:Destroy()
		chamsCache[plr] = nil
	end
end

-- ESP/Chams Update Loop
RunService.RenderStepped:Connect(function()
	local myChar = Player.Character
	local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar.HumanoidRootPart.Position

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= Player then
			-- ESP
			if Config.ESP then
				if not espCache[plr] then createESP(plr) end
				local gui = espCache[plr]
				if gui then
					local char = plr.Character
					if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
						gui.Adornee = char:FindFirstChild("Head") or char.HumanoidRootPart
						gui.Enabled = true

						local dist = myPos and (char.HumanoidRootPart.Position - myPos).Magnitude or 0
						if dist > Config.ESPMaxDistance then
							gui.Enabled = false
						else
							local nameL = gui:FindFirstChild("NameLabel")
							local healthL = gui:FindFirstChild("HealthLabel")
							local distL = gui:FindFirstChild("DistLabel")
							local healthBarBg = gui:FindFirstChild("HealthBarBg")

							if nameL then
								nameL.Visible = Config.ESPShowName
								nameL.Text = plr.DisplayName or plr.Name
							end
							if healthL then
								healthL.Visible = Config.ESPShowHealth
								local hp = char.Humanoid.Health
								local maxHp = char.Humanoid.MaxHealth
								healthL.Text = math.floor(hp) .. " / " .. math.floor(maxHp) .. " HP"
								local ratio = hp / maxHp
								healthL.TextColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 50)
							end
							if distL then
								distL.Visible = Config.ESPShowDistance
								distL.Text = math.floor(dist) .. "m"
							end
							if healthBarBg then
								healthBarBg.Visible = Config.ESPShowHealth
								local fill = healthBarBg:FindFirstChild("Fill")
								if fill then
									local ratio = char.Humanoid.Health / char.Humanoid.MaxHealth
									fill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
									fill.BackgroundColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 50)
								end
							end
						end
					else
						gui.Enabled = false
					end
				end
			else
				if espCache[plr] then
					espCache[plr].Enabled = false
				end
			end

			-- Chams
			if Config.Chams then
				local char = plr.Character
				if char then
					if not chamsCache[plr] then
						createChams(plr)
					else
						chamsCache[plr].Adornee = char
						chamsCache[plr].Enabled = true
						chamsCache[plr].FillTransparency = Config.ChamsFillTransparency
					end
				end
			else
				if chamsCache[plr] then
					chamsCache[plr].Enabled = false
				end
			end
		end
	end
end)

-- Clean up on player leaving
Players.PlayerRemoving:Connect(function(plr)
	removeESP(plr)
	removeChams(plr)
end)

-- Recreate on respawn
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		task.wait(1)
		if Config.ESP then removeESP(plr); createESP(plr) end
		if Config.Chams then removeChams(plr); createChams(plr) end
	end)
end)
for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= Player then
		plr.CharacterAdded:Connect(function()
			task.wait(1)
			if Config.ESP then removeESP(plr); createESP(plr) end
			if Config.Chams then removeChams(plr); createChams(plr) end
		end)
	end
end

--// FULLBRIGHT
local originalAmbient, originalOutdoor, originalBrightness
local lightingChanged = false

RunService.Heartbeat:Connect(function()
	local lighting = game:GetService("Lighting")
	if Config.FullBright then
		if not lightingChanged then
			originalAmbient = lighting.Ambient
			originalOutdoor = lighting.OutdoorAmbient
			originalBrightness = lighting.Brightness
			lightingChanged = true
		end
		lighting.Ambient = Color3.fromRGB(200, 200, 200)
		lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
		lighting.Brightness = 2
	else
		if lightingChanged then
			lighting.Ambient = originalAmbient
			lighting.OutdoorAmbient = originalOutdoor
			lighting.Brightness = originalBrightness
			lightingChanged = false
		end
	end
end)

--// NO FOG
local originalFogEnd, originalFogStart
local fogChanged = false

RunService.Heartbeat:Connect(function()
	local lighting = game:GetService("Lighting")
	if Config.NoFog then
		if not fogChanged then
			originalFogEnd = lighting.FogEnd
			originalFogStart = lighting.FogStart
			fogChanged = true
		end
		lighting.FogEnd = 1e10
		lighting.FogStart = 1e10
	else
		if fogChanged then
			lighting.FogEnd = originalFogEnd
			lighting.FogStart = originalFogStart
			fogChanged = false
		end
	end
end)

--// FOV CHANGER
local originalFOV = Camera.FieldOfView

RunService.RenderStepped:Connect(function()
	if Config.FOVChanger then
		Camera.FieldOfView = Config.FOVValue
	else
		Camera.FieldOfView = originalFOV
	end
end)

--// Auto-save every 30 seconds
task.spawn(function()
	while true do
		task.wait(30)
		SaveConfig()
	end
end)

--// Initial state
MainFrame.Visible = false
guiVisible = false

print("[EspadaWare] Loaded successfully | Vagrant Survival")
