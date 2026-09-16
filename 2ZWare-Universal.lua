--[[
	2ZWare / Vagrant Survival Premium Edition
	Разработано специально для мобильных и ПК платформ.
	Полностью рабочий функционал.
]]

---------------------------------------------------------------------
-- 01. SERVICES / LIFECYCLE
---------------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "2ZWareVagrantSurvival"

local previous = playerGui:FindFirstChild(GUI_NAME)
if previous then
	previous:Destroy()
end

local alive = true
local connections = {}
local observers = {}
local activeDrag = nil
local popup = nil
local tooltipToken = 0
local visibilityToken = 0
local capturingKey = false
local windowVisible = true

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

---------------------------------------------------------------------
-- 02. DESIGN TOKENS / SETTINGS
---------------------------------------------------------------------

local C = {
	Canvas = Color3.fromRGB(12, 16, 22),
	Sidebar = Color3.fromRGB(15, 20, 27),
	Surface = Color3.fromRGB(20, 26, 35),
	SurfaceRaised = Color3.fromRGB(25, 32, 42),
	Hover = Color3.fromRGB(32, 41, 53),

	Line = Color3.fromRGB(45, 55, 68),
	LineSoft = Color3.fromRGB(32, 41, 52),

	Text = Color3.fromRGB(240, 244, 248),
	Subtext = Color3.fromRGB(160, 174, 192),
	Muted = Color3.fromRGB(105, 120, 140),

	Accent = Color3.fromRGB(143, 231, 209), -- Mint
	AccentDark = Color3.fromRGB(24, 58, 54),
	AccentInk = Color3.fromRGB(12, 33, 30),

	Gold = Color3.fromRGB(244, 194, 120),
	Red = Color3.fromRGB(242, 115, 122),
	White = Color3.fromRGB(255, 255, 255),
	Black = Color3.fromRGB(0, 0, 0),
}

local FONT = {
	Regular = Enum.Font.Gotham,
	Medium = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold,
	Mono = Enum.Font.Code,
}

local PALETTES = {
	Mint = Color3.fromRGB(143, 231, 209),
	Iris = Color3.fromRGB(184, 166, 248),
	Glacier = Color3.fromRGB(130, 195, 247),
	Amber = Color3.fromRGB(244, 194, 120),
	Rose = Color3.fromRGB(241, 157, 186),
}

-- Изначальные дефолтные настройки
local defaults = {
	-- Aimbot
	aimbot_Enabled = false,
	aimbot_FOV = 120,
	aimbot_Smooth = 4,
	aimbot_Part = "Head",
	aimbot_Players = true,
	aimbot_NPCs = true,
	aimbot_ShowFOV = true,

	-- Silent Aim
	silent_Enabled = false,
	silent_Chance = 100,
	silent_Part = "Head",

	-- Movement
	speed_Enabled = false,
	speed_Value = 24,
	infJump_Enabled = false,

	-- Visuals
	esp_Enabled = false,
	esp_Boxes = true,
	esp_Names = true,
	esp_Distance = true,
	esp_Health = true,
	esp_Tracers = false,
	esp_MaxDist = 600,
	fullbright_Enabled = false,

	-- UI / Settings
	palette = "Mint",
	reduceMotion = false,
	notifications = true,
	keybind = Enum.KeyCode.RightShift,
	autoSave = true,
}

local state = {}
for key, value in pairs(defaults) do
	state[key] = value
end

-- Автосохранение
local CONFIG_FILE = "2zware_vagrant_config.json"

local function saveConfig()
	local success, err = pcall(function()
		if writefile then
			local data = {}
			for k, v in pairs(state) do
				if typeof(v) == "EnumItem" then
					data[k] = {__type = "EnumItem", Name = v.Name, Type = tostring(v.EnumType)}
				else
					data[k] = v
				end
			end
			writefile(CONFIG_FILE, HttpService:JSONEncode(data))
		end
	end)
	return success
end

local function loadConfig()
	local success, err = pcall(function()
		if readfile and isfile and isfile(CONFIG_FILE) then
			local raw = readfile(CONFIG_FILE)
			local decoded = HttpService:JSONDecode(raw)
			for k, v in pairs(decoded) do
				if type(v) == "table" and v.__type == "EnumItem" then
					state[k] = Enum[v.Type][v.Name]
				else
					state[k] = v
				end
			end
		end
	end)
	return success
end

local function setState(key, value)
	if state[key] == value then
		return
	end
	state[key] = value

	local list = observers[key]
	if list then
		for _, callback in ipairs(list) do
			callback(value)
		end
	end

	if state.autoSave then
		saveConfig()
	end
end

local function watch(key, callback)
	observers[key] = observers[key] or {}
	table.insert(observers[key], callback)
	callback(state[key])
end

local function keyName(key)
	local names = {
		[Enum.KeyCode.RightShift] = "RShift",
		[Enum.KeyCode.LeftShift] = "LShift",
		[Enum.KeyCode.RightControl] = "RCtrl",
		[Enum.KeyCode.LeftControl] = "LCtrl",
		[Enum.KeyCode.RightAlt] = "RAlt",
		[Enum.KeyCode.LeftAlt] = "LAlt",
		[Enum.KeyCode.Space] = "Space",
		[Enum.KeyCode.Backquote] = "`",
	}
	return names[key] or (key and key.Name) or "None"
end

---------------------------------------------------------------------
-- 03. BASE UI / ANIMATION HELPERS
---------------------------------------------------------------------

local function create(className, properties, parent)
	local object = Instance.new(className)
	for property, value in pairs(properties or {}) do
		object[property] = value
	end
	if parent then
		object.Parent = parent
	end
	return object
end

local function corner(object, radius)
	return create("UICorner", {
		CornerRadius = UDim.new(0, radius or 12),
	}, object)
end

local function stroke(object, color, transparency, thickness)
	return create("UIStroke", {
		Color = color or C.Line,
		Transparency = transparency or 0,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, object)
end

local function padding(object, left, right, top, bottom)
	return create("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
	}, object)
end

local function verticalLayout(object, gap)
	return create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, gap or 0),
	}, object)
end

local function text(parent, content, size, color, font, properties)
	local settings = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = content,
		TextSize = size or 14,
		TextColor3 = color or C.Text,
		Font = font or FONT.Regular,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.new(1, 0, 0, 20),
	}
	for key, value in pairs(properties or {}) do
		settings[key] = value
	end
	return create("TextLabel", settings, parent)
end

local function frame(parent, properties)
	local settings = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}
	for key, value in pairs(properties or {}) do
		settings[key] = value
	end
	return create("Frame", settings, parent)
end

local runningTweens = setmetatable({}, { __mode = "k" })

local function animate(object, duration, goal)
	local previousTween = runningTweens[object]
	if previousTween then
		previousTween:Cancel()
		runningTweens[object] = nil
	end

	if state.reduceMotion or duration <= 0 then
		for property, value in pairs(goal) do
			object[property] = value
		end
		return
	end

	local tween = TweenService:Create(
		object,
		TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		goal
	)
	runningTweens[object] = tween
	tween:Play()
end

local function button(parent, properties)
	local settings = {
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Text = "",
		BackgroundColor3 = C.SurfaceRaised,
		Font = FONT.Medium,
		TextSize = 13,
		TextColor3 = C.Text,
		Selectable = true,
	}
	for key, value in pairs(properties or {}) do
		settings[key] = value
	end
	return create("TextButton", settings, parent)
end

local function interaction(object, normalColor, hoverColor, pressedColor)
	local hovered = false

	object.MouseEnter:Connect(function()
		hovered = true
		animate(object, 0.16, { BackgroundColor3 = hoverColor })
	end)

	object.MouseLeave:Connect(function()
		hovered = false
		animate(object, 0.18, { BackgroundColor3 = normalColor })
	end)

	object.MouseButton1Down:Connect(function()
		animate(object, 0.08, { BackgroundColor3 = pressedColor or normalColor })
	end)

	object.MouseButton1Up:Connect(function()
		animate(object, 0.15, { BackgroundColor3 = hovered and hoverColor or normalColor })
	end)
end

---------------------------------------------------------------------
-- 04. VECTOR ICONS — NO ASSETS
---------------------------------------------------------------------

local function icon(parent, name, color, position, size)
	local container = frame(parent, {
		Position = position or UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(size or 20, size or 20),
	})

	local parts = {}

	local function line(x, y, width, height, rotation)
		local part = frame(container, {
			BackgroundColor3 = color,
			BackgroundTransparency = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromScale(width, height),
			Rotation = rotation or 0,
		})
		corner(part, 8)
		table.insert(parts, part)
		return part
	end

	local function ring(x, y, diameter, thickness)
		local part = frame(container, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromScale(diameter, diameter),
		})
		corner(part, 99)
		local outline = stroke(part, color, 0, thickness or 1.5)
		table.insert(parts, outline)
		return part
	end

	if name == "main" then
		for _, point in ipairs({{ 0.28, 0.28 }, { 0.72, 0.28 }, { 0.28, 0.72 }, { 0.72, 0.72 }}) do
			line(point[1], point[2], 0.28, 0.28)
		end
	elseif name == "visuals" then
		ring(0.5, 0.5, 0.76, 1.5)
		line(0.5, 0.5, 0.25, 0.25)
	elseif name == "movement" then
		line(0.34, 0.25, 0.52, 0.10)
		line(0.52, 0.50, 0.70, 0.10)
		line(0.67, 0.75, 0.40, 0.10)
	elseif name == "settings" then
		for index, x in ipairs({ 0.22, 0.50, 0.78 }) do
			line(x, 0.50, 0.08, 0.78)
			line(x, index == 2 and 0.66 or 0.34, 0.23, 0.17)
		end
	elseif name == "gear" then
		ring(0.5, 0.5, 0.5, 1.8)
		for i = 0, 7 do
			local angle = i * 45
			local rad = math.rad(angle)
			local x = 0.5 + math.cos(rad) * 0.3
			local y = 0.5 + math.sin(rad) * 0.3
			line(x, y, 0.12, 0.12, angle)
		end
	elseif name == "close" then
		line(0.5, 0.5, 0.72, 0.08, 45)
		line(0.5, 0.5, 0.72, 0.08, -45)
	elseif name == "chevron" then
		line(0.35, 0.51, 0.40, 0.09, 45)
		line(0.64, 0.51, 0.40, 0.09, -45)
	elseif name == "check" then
		line(0.31, 0.57, 0.34, 0.10, 45)
		line(0.61, 0.47, 0.59, 0.10, -45)
	elseif name == "arrow" then
		line(0.48, 0.5, 0.72, 0.08)
		line(0.69, 0.35, 0.40, 0.08, 45)
		line(0.69, 0.65, 0.40, 0.08, -45)
	elseif name == "spark" then
		line(0.5, 0.5, 0.10, 0.82)
		line(0.5, 0.5, 0.82, 0.10)
		line(0.5, 0.5, 0.09, 0.52, 45)
		line(0.5, 0.5, 0.09, 0.52, -45)
	end

	return {
		Object = container,
		SetColor = function(newColor)
			for _, part in ipairs(parts) do
				if part:IsA("UIStroke") then
					animate(part, 0.18, { Color = newColor })
				else
					animate(part, 0.18, { BackgroundColor3 = newColor })
				end
			end
		end,
	}
end

---------------------------------------------------------------------
-- 05. ROOT / WINDOW
---------------------------------------------------------------------

local screen = create("ScreenGui", {
	Name = GUI_NAME,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 30,
}, playerGui)

local WIDTH = 900
local HEIGHT = 600
local SIDEBAR = 208

local currentScale = 1
local viewport = Vector2.new(1280, 720)
local windowCenter = viewport / 2
local manuallyPositioned = false

local holder = frame(screen, {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(windowCenter.X, windowCenter.Y),
	Size = UDim2.fromOffset(WIDTH, HEIGHT),
	ZIndex = 10,
	Visible = false,
})

local windowScale = create("UIScale", { Scale = 1 }, holder)

-- Качественные тени
for index = 5, 1, -1 do
	local expansion = index * 7
	local shadow = frame(holder, {
		Name = "Shadow_" .. index,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 8 + index),
		Size = UDim2.new(1, expansion * 2, 1, expansion * 2),
		BackgroundColor3 = C.Black,
		BackgroundTransparency = 0.965 - (5 - index) * 0.008,
		ZIndex = 1,
	})
	corner(shadow, 22 + expansion)
end

local window = create("CanvasGroup", {
	Name = "Surface",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.Canvas,
	BorderSizePixel = 0,
	GroupTransparency = 1,
	ZIndex = 5,
}, holder)
corner(window, 20)
stroke(window, C.Line, 0.16)

local sidebar = frame(window, {
	Size = UDim2.new(0, SIDEBAR, 1, 0),
	BackgroundColor3 = C.Sidebar,
	BackgroundTransparency = 0,
})

frame(sidebar, {
	Position = UDim2.new(1, -1, 0, 0),
	Size = UDim2.new(0, 1, 1, 0),
	BackgroundColor3 = C.LineSoft,
	BackgroundTransparency = 0,
})

local brandMark = frame(sidebar, {
	Position = UDim2.fromOffset(24, 29),
	Size = UDim2.fromOffset(34, 34),
	BackgroundColor3 = C.Accent,
	BackgroundTransparency = 0,
	Rotation = -6,
})
corner(brandMark, 10)
icon(brandMark, "spark", C.AccentInk, UDim2.fromOffset(8, 8), 18)

-- Заголовок по дизайну с RichText: "2Z" белым, "Ware" акцентным
local brandTitle = text(sidebar, "", 19, C.Text, FONT.Bold, {
	Position = UDim2.fromOffset(70, 28),
	Size = UDim2.fromOffset(118, 23),
	RichText = true,
})
brandTitle.Text = '<font color="#FFFFFF">2Z</font><font color="#8FE7D1">Ware</font>'

text(sidebar, "VAGRANT SURVIVAL", 9, C.Muted, FONT.Medium, {
	Position = UDim2.fromOffset(71, 53),
	Size = UDim2.fromOffset(125, 14),
})

text(sidebar, "НАВИГАЦИЯ", 10, C.Muted, FONT.Medium, {
	Position = UDim2.fromOffset(25, 110),
	Size = UDim2.fromOffset(150, 16),
})

local navArea = frame(sidebar, {
	Position = UDim2.fromOffset(14, 141),
	Size = UDim2.new(1, -28, 0, 236),
})
verticalLayout(navArea, 8)

-- Статус бар
local sidebarInfo = frame(sidebar, {
	Position = UDim2.new(0, 16, 1, -154),
	Size = UDim2.new(1, -32, 0, 91),
	BackgroundColor3 = C.Surface,
	BackgroundTransparency = 0,
})
corner(sidebarInfo, 12)
stroke(sidebarInfo, C.LineSoft, 0.1)

local sidebarDot = frame(sidebarInfo, {
	Position = UDim2.fromOffset(14, 16),
	Size = UDim2.fromOffset(6, 6),
	BackgroundColor3 = C.Accent,
	BackgroundTransparency = 0,
})
corner(sidebarDot, 8)

local sidebarStatus = text(sidebarInfo, "ACTIVE CLIENT", 10, C.Subtext, FONT.Medium, {
	Position = UDim2.fromOffset(28, 10),
	Size = UDim2.fromOffset(130, 19),
})

text(sidebarInfo, "Автосохранение работает.\nКонфиг стабилен.", 11, C.Muted, FONT.Regular, {
	Position = UDim2.fromOffset(14, 37),
	Size = UDim2.new(1, -28, 0, 36),
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
})

text(sidebar, "V / 2.0", 11, C.Subtext, FONT.Mono, {
	Position = UDim2.new(0, 24, 1, -40),
	Size = UDim2.fromOffset(70, 18),
})

text(sidebar, "MOBILE BUILD", 9, C.Muted, FONT.Medium, {
	Position = UDim2.new(1, -109, 1, -39),
	Size = UDim2.fromOffset(87, 16),
	TextXAlignment = Enum.TextXAlignment.Right,
})

local content = frame(window, {
	Position = UDim2.fromOffset(SIDEBAR + 28, 0),
	Size = UDim2.new(1, -SIDEBAR - 52, 1, 0),
})

local header = frame(content, {
	Size = UDim2.new(1, 0, 0, 113),
	Active = true,
})

local eyebrow = text(header, "ВКЛАДКА / 01", 10, C.Accent, FONT.Medium, {
	Position = UDim2.fromOffset(0, 25),
	Size = UDim2.fromOffset(280, 15),
})

local pageTitle = text(header, "Main", 30, C.Text, FONT.Bold, {
	Position = UDim2.fromOffset(0, 44),
	Size = UDim2.new(1, -205, 0, 39),
})

local pageDescription = text(header, "", 12, C.Subtext, FONT.Regular, {
	Position = UDim2.fromOffset(1, 89),
	Size = UDim2.new(1, -4, 0, 18),
})

local sandboxBadge = frame(header, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -47, 0, 28),
	Size = UDim2.fromOffset(98, 25),
	BackgroundColor3 = C.AccentDark,
	BackgroundTransparency = 0.22,
})
corner(sandboxBadge, 7)

text(sandboxBadge, "• EXPLOIT", 10, C.Accent, FONT.Medium, {
	Size = UDim2.fromScale(1, 1),
	TextXAlignment = Enum.TextXAlignment.Center,
})

local closeButton = button(header, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 24),
	Size = UDim2.fromOffset(33, 33),
	BackgroundColor3 = C.Surface,
})
corner(closeButton, 9)
icon(closeButton, "close", C.Subtext, UDim2.fromOffset(9, 9), 15)
interaction(closeButton, C.Surface, C.Hover, C.Sidebar)

local pagesContainer = frame(content, {
	Position = UDim2.fromOffset(0, 126),
	Size = UDim2.new(1, 0, 1, -178),
	ClipsDescendants = true,
})

frame(content, {
	Position = UDim2.new(0, 0, 1, -41),
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = C.LineSoft,
	BackgroundTransparency = 0,
})

local footerLeft = text(content, "01 / MAIN", 10, C.Muted, FONT.Mono, {
	Position = UDim2.new(0, 0, 1, -29),
	Size = UDim2.fromOffset(260, 17),
})

local footerRight = text(content, "", 10, C.Subtext, FONT.Regular, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 1, -29),
	Size = UDim2.fromOffset(330, 17),
	TextXAlignment = Enum.TextXAlignment.Right,
})

---------------------------------------------------------------------
-- 06. OVERLAYS / NOTIFICATIONS
---------------------------------------------------------------------

local popupLayer = frame(screen, {
	Name = "PopupLayer",
	Size = UDim2.fromScale(1, 1),
	ZIndex = 50,
})

local dismissPopup = button(popupLayer, {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Visible = false,
	Selectable = false,
	ZIndex = 1,
})

local function closePopup()
	if popup then
		popup:Destroy()
		popup = nil
	end
	dismissPopup.Visible = false
end

dismissPopup.Activated:Connect(closePopup)

local toastArea = frame(screen, {
	Name = "Notifications",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -22, 1, -22),
	Size = UDim2.fromOffset(330, 330),
	ZIndex = 80,
})

local toastScale = create("UIScale", { Scale = 1 }, toastArea)
local toasts = {}

local function arrangeToasts()
	for index, item in ipairs(toasts) do
		animate(item.Group, 0.23, {
			Position = UDim2.new(0, 0, 1, -index * 83),
		})
	end
end

local function removeToast(item)
	if item.Removing then return end
	item.Removing = true
	for index, candidate in ipairs(toasts) do
		if candidate == item then
			table.remove(toasts, index)
			break
		end
	end
	if item.Group.Parent then
		animate(item.Group, 0.18, {
			GroupTransparency = 1,
			Position = item.Group.Position + UDim2.fromOffset(22, 0),
		})
	end
	arrangeToasts()
	task.delay(0.2, function()
		if item.Group.Parent then
			item.Group:Destroy()
		end
	end)
end

local function notify(title, message, tone, force)
	if not alive or (not state.notifications and not force) then return end
	if #toasts >= 3 then
		removeToast(toasts[#toasts])
	end
	local accent = tone == "warning" and C.Gold or C.Accent
	local group = create("CanvasGroup", {
		Position = UDim2.new(0, 22, 1, -83),
		Size = UDim2.fromOffset(330, 73),
		BackgroundColor3 = C.SurfaceRaised,
		BorderSizePixel = 0,
		GroupTransparency = 1,
	}, toastArea)
	corner(group, 12)
	stroke(group, C.Line, 0.05)

	frame(group, {
		Position = UDim2.fromOffset(0, 13),
		Size = UDim2.fromOffset(3, 45),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0,
	})

	local mark = frame(group, {
		Position = UDim2.fromOffset(14, 18),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.88,
	})
	corner(mark, 9)
	icon(mark, "check", accent, UDim2.fromOffset(7, 7), 14)

	text(group, title, 12, C.Text, FONT.Medium, {
		Position = UDim2.fromOffset(53, 12),
		Size = UDim2.fromOffset(246, 18),
	})

	text(group, message, 11, C.Subtext, FONT.Regular, {
		Position = UDim2.fromOffset(53, 33),
		Size = UDim2.fromOffset(246, 29),
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	local item = { Group = group, Removing = false }
	table.insert(toasts, 1, item)
	arrangeToasts()
	animate(group, 0.25, { GroupTransparency = 0 })

	task.delay(4.5, function()
		if alive and group.Parent then
			removeToast(item)
		end
	end)
end

---------------------------------------------------------------------
-- 07. DYNAMIC EXPANDABLE SECTION BUILDERS
---------------------------------------------------------------------

local function section(parent, title, caption)
	local card = frame(parent, {
		Size = UDim2.new(1, -4, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.Surface,
		BackgroundTransparency = 0,
	})
	corner(card, 14)
	stroke(card, C.LineSoft, 0.5)
	padding(card, 18, 18, 15, 12)
	verticalLayout(card, 8)

	local heading = frame(card, {
		Size = UDim2.new(1, 0, 0, caption and 55 or 35),
	})
	text(heading, title, 14, C.Text, FONT.Medium, {
		Size = UDim2.new(1, 0, 0, 21),
	})
	if caption then
		text(heading, caption, 11, C.Muted, FONT.Regular, {
			Position = UDim2.fromOffset(0, 25),
			Size = UDim2.new(1, 0, 0, 18),
		})
	end
	return card
end

local function divider(parent)
	return frame(parent, {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = C.LineSoft,
		BackgroundTransparency = 0,
	})
end

local function row(parent, title, description, height)
	local object = frame(parent, {
		Size = UDim2.new(1, 0, 0, height or 64),
	})
	text(object, title, 13, C.Text, FONT.Medium, {
		Position = UDim2.fromOffset(0, 10),
		Size = UDim2.new(0.6, 0, 0, 20),
	})
	if description then
		text(object, description, 11, C.Muted, FONT.Regular, {
			Position = UDim2.fromOffset(0, 30),
			Size = UDim2.new(0.6, -5, 0, 24),
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
		})
	end
	return object
end

local function buildToggle(parent, key, title, description, hasGear, gearBuilder)
	local container = frame(parent, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	verticalLayout(container, 4)

	local mainRow = row(container, title, description, 54)

	-- Тоггл
	local track = button(mainRow, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, hasGear and -38 or 0, 0.5, 0),
		Size = UDim2.fromOffset(44, 25),
		BackgroundColor3 = C.Hover,
	})
	corner(track, 99)
	local trackStroke = stroke(track, C.Line, 0.35)

	local thumb = frame(track, {
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.fromOffset(17, 17),
		BackgroundColor3 = C.Subtext,
	})
	corner(thumb, 99)

	watch(key, function(value)
		animate(track, 0.20, { BackgroundColor3 = value and C.Accent or C.Hover })
		animate(thumb, 0.22, {
			Position = UDim2.fromOffset(value and 23 or 4, 4),
			BackgroundColor3 = value and C.AccentInk or C.Subtext,
		})
		animate(trackStroke, 0.20, { Transparency = value and 1 or 0.35 })
	end)

	track.Activated:Connect(function()
		setState(key, not state[key])
	end)

	-- Логика раскрывающейся шестеренки
	if hasGear and gearBuilder then
		local gearBtn = button(mainRow, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = C.SurfaceRaised,
		})
		corner(gearBtn, 8)
		local gearIcon = icon(gearBtn, "gear", C.Subtext, UDim2.fromOffset(5, 5), 20)
		interaction(gearBtn, C.SurfaceRaised, C.Hover, C.Sidebar)

		local settingsPanel = frame(container, {
			Size = UDim2.new(1, 0, 0, 0),
			ClipsDescendants = true,
			Visible = false,
		})
		local panelLayout = verticalLayout(settingsPanel, 6)
		padding(settingsPanel, 10, 10, 8, 8)
		settingsPanel.BackgroundColor3 = C.SurfaceRaised
		corner(settingsPanel, 10)
		stroke(settingsPanel, C.LineSoft, 0.3)

		gearBuilder(settingsPanel)

		local panelOpen = false
		gearBtn.Activated:Connect(function()
			panelOpen = not panelOpen
			settingsPanel.Visible = true
			local targetHeight = panelOpen and (panelLayout.AbsoluteContentSize.Y + 16) or 0
			animate(settingsPanel, 0.25, { Size = UDim2.new(1, 0, 0, targetHeight) })
			animate(gearIcon.Object, 0.25, { Rotation = panelOpen and 90 or 0 })
			task.delay(0.25, function()
				if not panelOpen then settingsPanel.Visible = false end
			end)
		end)
	end

	return container
end

local function buildSlider(parent, key, title, min, max, step, formatter)
	local object = frame(parent, {
		Size = UDim2.new(1, 0, 0, 45),
	})
	text(object, title, 12, C.Subtext, FONT.Medium, {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(0.6, 0, 0, 18),
	})

	local valText = text(object, "", 12, C.Accent, FONT.Mono, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(80, 18),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local hit = button(object, {
		Position = UDim2.fromOffset(0, 22),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
	})

	local track = frame(hit, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = C.Hover,
	})
	corner(track, 99)

	local fill = frame(track, {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.Accent,
	})
	corner(fill, 99)

	local knob = frame(hit, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = C.White,
	})
	corner(knob, 99)

	local function normalize(value)
		local snapped = min + math.round((value - min) / step) * step
		return math.clamp(tonumber(string.format("%.4f", snapped)), min, max)
	end

	local function setFromX(x)
		local ratio = math.clamp((x - hit.AbsolutePosition.X) / hit.AbsoluteSize.X, 0, 1)
		setState(key, normalize(min + (max - min) * ratio))
	end

	watch(key, function(value)
		local ratio = (value - min) / (max - min)
		animate(fill, 0.1, { Size = UDim2.fromScale(ratio, 1) })
		animate(knob, 0.1, { Position = UDim2.fromScale(ratio, 0.5) })
		valText.Text = formatter and formatter(value) or tostring(value)
	end)

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			activeDrag = {
				Owner = hit,
				Input = input,
				Update = function(pos) setFromX(pos.X) end,
			}
			setFromX(input.Position.X)
		end
	end)

	return object
end

local function buildDropdown(parent, key, title, options)
	local object = frame(parent, {
		Size = UDim2.new(1, 0, 0, 40),
	})
	text(object, title, 12, C.Subtext, FONT.Medium, {
		Position = UDim2.fromOffset(0, 11),
		Size = UDim2.new(0.4, 0, 0, 18),
	})

	local control = button(object, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(180, 28),
		BackgroundColor3 = C.Canvas,
	})
	corner(control, 6)
	stroke(control, C.Line, 0.3)
	interaction(control, C.Canvas, C.Hover, C.Sidebar)

	local selText = text(control, "", 11, C.Text, FONT.Medium, {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -30, 1, 0),
	})
	icon(control, "chevron", C.Subtext, UDim2.new(1, -20, 0.5, -5), 10)

	watch(key, function(value)
		for _, opt in ipairs(options) do
			if opt.Value == value then
				selText.Text = opt.Label
				break
			end
		end
	end)

	control.Activated:Connect(function()
		if popup then closePopup() return end
		local designWidth = 180
		local designHeight = #options * 32 + 8
		local abs = control.AbsolutePosition

		popup = create("CanvasGroup", {
			Position = UDim2.fromOffset(abs.X, abs.Y + 32),
			Size = UDim2.fromOffset(designWidth, designHeight),
			BackgroundColor3 = C.SurfaceRaised,
			ZIndex = 99,
		}, popupLayer)
		corner(popup, 8)
		stroke(popup, C.Line, 0)
		padding(popup, 4, 4, 4, 4)
		verticalLayout(popup, 1)

		dismissPopup.Visible = true

		for _, opt in ipairs(options) do
			local selected = state[key] == opt.Value
			local item = button(popup, {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = selected and C.AccentDark or C.SurfaceRaised,
			})
			corner(item, 6)
			text(item, opt.Label, 11, selected and C.Accent or C.Subtext, FONT.Medium, {
				Position = UDim2.fromOffset(8, 0),
			})
			item.Activated:Connect(function()
				setState(key, opt.Value)
				closePopup()
			end)
		end
	end)

	return object
end

local function actionButton(parent, title, primary, callback, properties)
	local base = primary and C.Accent or C.SurfaceRaised
	local hover = primary and Color3.fromRGB(174, 244, 225) or C.Hover
	local press = primary and Color3.fromRGB(116, 204, 183) or C.Sidebar

	local settings = {
		Size = UDim2.fromOffset(175, 38),
		BackgroundColor3 = base,
		Text = title,
		TextColor3 = primary and C.AccentInk or C.Text,
		Font = FONT.Medium,
		TextSize = 12,
	}
	for key, value in pairs(properties or {}) do
		settings[key] = value
	end
	local object = button(parent, settings)
	corner(object, 9)
	if not primary then
		stroke(object, C.Line, 0.3)
	end
	interaction(object, base, hover, press)
	object.Activated:Connect(callback)
	return object
end

---------------------------------------------------------------------
-- 08. TAB CONFIGURATION
---------------------------------------------------------------------

local tabDefinitions = {
	{ Name = "Main", Icon = "main", Description = "Боевые механики Vagrant Survival. Aim & Silent Aim." },
	{ Name = "Movement", Icon = "movement", Description = "Настройки обхода физики и скорости передвижения." },
	{ Name = "Visuals", Icon = "visuals", Description = "Полная отрисовка окружения, игроков и бродяг." },
	{ Name = "Settings", Icon = "settings", Description = "Конфигурация сессии, автосохранение и управление интерфейсом." },
}

local pages = {}
local navigation = {}
local currentTab = nil

for index, def in ipairs(tabDefinitions) do
	local page = create("ScrollingFrame", {
		Name = def.Name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = C.Accent,
		Visible = false,
	}, pagesContainer)
	padding(page, 1, 7, 2, 10)
	verticalLayout(page, 12)
	pages[def.Name] = page

	local nav = button(navArea, {
		Size = UDim2.new(1, 0, 0, 47),
		BackgroundColor3 = C.Sidebar,
		LayoutOrder = index,
	})
	corner(nav, 10)

	local outline = stroke(nav, C.Accent, 1)
	local navIcon = icon(nav, def.Icon, C.Muted, UDim2.fromOffset(14, 14), 19)
	local label = text(nav, def.Name, 13, C.Subtext, FONT.Medium, {
		Position = UDim2.fromOffset(46, 0),
	})

	local indicator = frame(nav, {
		Position = UDim2.fromOffset(0, 16),
		Size = UDim2.fromOffset(3, 15),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 1,
	})
	corner(indicator, 4)

	navigation[def.Name] = {
		Button = nav,
		Outline = outline,
		Icon = navIcon,
		Label = label,
		Indicator = indicator,
		Index = index,
		Definition = def,
	}

	nav.Activated:Connect(function()
		if currentTab == def.Name then return end
		closePopup()
		currentTab = def.Name
		for tabName, data in pairs(navigation) do
			local selected = tabName == def.Name
			pages[tabName].Visible = selected
			animate(data.Button, 0.2, { BackgroundColor3 = selected and C.AccentDark or C.Sidebar })
			animate(data.Outline, 0.2, { Transparency = selected and 0.76 or 1 })
			animate(data.Indicator, 0.2, { BackgroundTransparency = selected and 0 or 1 })
			animate(data.Label, 0.2, { TextColor3 = selected and C.Text or C.Subtext })
			data.Icon.SetColor(selected and C.Accent or C.Muted)
		end
		eyebrow.Text = string.format("ВКЛАДКА / %02d", index)
		pageTitle.Text = def.Name
		pageDescription.Text = def.Description
		footerLeft.Text = string.format("%02d / %s", index, string.upper(def.Name))
	end)
end

---------------------------------------------------------------------
-- 09. FILL PAGES WITH ELEMENTS
---------------------------------------------------------------------

-- MAIN PAGE
do
	local page = pages.Main
	local combat = section(page, "Combat Systems", "Автоматические системы поражения целей.")

	-- AIMBOT + GEAR
	buildToggle(combat, "aimbot_Enabled", "Использовать AimBot", "Плавное ведение прицела на цель.", true, function(p)
		buildSlider(p, "aimbot_FOV", "Радиус захвата (FOV)", 30, 400, 5, function(v) return v .. "px" end)
		buildSlider(p, "aimbot_Smooth", "Плавность доводки", 1, 15, 0.5)
		buildDropdown(p, "aimbot_Part", "Часть тела", {
			{Value = "Head", Label = "Голова"},
			{Value = "Torso", Label = "Торс"},
			{Value = "HumanoidRootPart", Label = "Центр массы"}
		})
		buildToggle(p, "aimbot_ShowFOV", "Отрисовывать FOV", "Показывать круг прицела.")
	end)

	divider(combat)

	-- SILENT AIM + GEAR
	buildToggle(combat, "silent_Enabled", "Использовать Silent Aim", "Прямой урон без движения камеры.", true, function(p)
		buildSlider(p, "silent_Chance", "Шанс попадания", 10, 100, 5, function(v) return v .. "%" end)
		buildDropdown(p, "silent_Part", "Приоритет кости", {
			{Value = "Head", Label = "Голова"},
			{Value = "Torso", Label = "Торс"}
		})
	end)

	local filterSection = section(page, "Target Filtering", "Фильтры детекции существ.")
	buildToggle(filterSection, "aimbot_Players", "Целиться во враждебных Игроков", "Включает игроков в приоритет.")
	buildToggle(filterSection, "aimbot_NPCs", "Целиться в Бродяг (NPC)", "Помогает фармить мобов на карте.")
end

-- MOVEMENT PAGE
do
	local page = pages.Movement
	local physical = section(page, "Physical Modifiers", "Влияние на гравитацию и базовую скорость.")

	buildToggle(physical, "speed_Enabled", "Модификатор скорости", "Принудительное ускорение.", true, function(p)
		buildSlider(p, "speed_Value", "Скорость бега", 16, 120, 2)
	end)

	divider(physical)

	buildToggle(physical, "infJump_Enabled", "Бесконечные прыжки", "Снимает ограничение на повторный прыжок в воздухе.")
end

-- VISUALS PAGE
do
	local page = pages.Visuals
	local rendering = section(page, "Rendering Settings", "Отрисовка окружения и существ.")

	buildToggle(rendering, "esp_Enabled", "Активировать ESP", "Подсветка игроков и бродяг.", true, function(p)
		buildToggle(p, "esp_Boxes", "2D Квадраты", "Обрисовка рамок персонажей.")
		buildToggle(p, "esp_Names", "Имена целей", "Отображение ника.")
		buildToggle(p, "esp_Distance", "Отрисовка дистанции", "Дистанция до цели.")
		buildToggle(p, "esp_Health", "Полоса здоровья", "Индикатор HP.")
		buildToggle(p, "esp_Tracers", "Трейсеры (Линии)", "Показывает вектор движения.")
		buildSlider(p, "esp_MaxDist", "Макс. Дистанция", 100, 1500, 50, function(v) return v .. "м" end)
	end)

	divider(rendering)

	buildToggle(rendering, "fullbright_Enabled", "Режим Fullbright (Подсветка карты)", "Полностью убирает темноту ночи.")
end

-- SETTINGS PAGE
do
	local page = pages.Settings
	local configSec = section(page, "Конфигурация", "Сохранение и загрузка параметров.")

	local rowButtons = frame(configSec, {
		Size = UDim2.new(1, 0, 0, 42),
	})
	verticalLayout(rowButtons, 8)
	rowButtons.UIListLayout.FillDirection = Enum.FillDirection.Horizontal

	actionButton(rowButtons, "Сохранить", true, function()
		if saveConfig() then
			notify("Успех", "Конфиг сохранен в файлы игры!")
		else
			notify("Ошибка", "Ваш инжектор не поддерживает файлы.", "warning")
		end
	end, { Size = UDim2.new(0.31, 0, 1, 0) })

	actionButton(rowButtons, "Загрузить", false, function()
		if loadConfig() then
			notify("Успех", "Конфиг успешно загружен!")
		else
			notify("Ошибка", "Файл конфига не найден.", "warning")
		end
	end, { Size = UDim2.new(0.31, 0, 1, 0) })

	actionButton(rowButtons, "Сбросить", false, function()
		for k, v in pairs(defaults) do
			setState(k, v)
		end
		notify("Внимание", "Настройки сброшены по умолчанию.")
	end, { Size = UDim2.new(0.31, 0, 1, 0) })

	divider(configSec)

	buildToggle(configSec, "autoSave", "Автосохранение", "Сохранять при любых изменениях тогглов.")
	buildToggle(configSec, "notifications", "Уведомления", "Показывать всплывающие подсказки справа.")
end

---------------------------------------------------------------------
-- 10. DRAGGABLE FLOATING TOGGLE BUTTON (MOBILE FRIENDLY)
---------------------------------------------------------------------

local mobileToggle = create("TextButton", {
	Name = "MobileToggle",
	Size = UDim2.fromOffset(50, 50),
	Position = UDim2.new(0.05, 0, 0.15, 0),
	BackgroundColor3 = C.Sidebar,
	Text = "",
	ZIndex = 999,
}, screen)
corner(mobileToggle, 99)
stroke(mobileToggle, C.Accent, 0.2, 2)
icon(mobileToggle, "spark", C.Accent, UDim2.fromOffset(15, 15), 20)

-- Реализация плавного затягивания на мобилке при зажатии
local dragStart, startPos
local dragging = false

mobileToggle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mobileToggle.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		mobileToggle.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

---------------------------------------------------------------------
-- 11. GAMEPLAY CHEATS FUNCTIONAL REALIZATION (100% WORKING)
---------------------------------------------------------------------

-- FOV Circle
local FOVCircle = create("ImageLabel", {
	Name = "FOVCircle",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(state.aimbot_FOV * 2, state.aimbot_FOV * 2),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1,
	Image = "rbxassetid://1234567", -- Заглушка, сделаем отрисовку через frame/круги
	Visible = false,
}, screen)

local visualCircle = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = C.Accent,
	BackgroundTransparency = 0.95,
	Parent = screen,
})
corner(visualCircle, 999)
stroke(visualCircle, C.Accent, 0.5, 1)

watch("aimbot_ShowFOV", function(v)
	visualCircle.Visible = v and state.aimbot_Enabled
end)

watch("aimbot_FOV", function(v)
	visualCircle.Size = UDim2.fromOffset(v * 2, v * 2)
end)

-- Поиск валидной цели в Vagrant Survival
local function getClosestTarget()
	local closest = nil
	local shortestDistance = math.huge
	local mousePos = UserInputService:GetMouseLocation()

	for _, obj in ipairs(workspace:GetDescendants()) do
		local isPlayer = Players:GetPlayerFromCharacter(obj) ~= nil
		local isVagrantNPC = obj:FindFirstChild("Humanoid") and obj:FindFirstChild("Head") and not isPlayer

		local shouldCheck = false
		if isPlayer and state.aimbot_Players and obj ~= player.Character then
			shouldCheck = true
		elseif isVagrantNPC and state.aimbot_NPCs then
			shouldCheck = true
		end

		if shouldCheck then
			local root = obj:FindFirstChild(state.aimbot_Part) or obj:FindFirstChild("HumanoidRootPart")
			if root then
				local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
				if onScreen then
					local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
					if distance < shortestDistance and distance <= state.aimbot_FOV then
						shortestDistance = distance
						closest = obj
					end
				end
			end
		end
	end
	return closest
end

-- Fullbright Регулировщик
local originalLightSettings = {
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	Brightness = Lighting.Brightness,
	GlobalShadows = Lighting.GlobalShadows,
}

watch("fullbright_Enabled", function(v)
	if v then
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		Lighting.Brightness = 3
		Lighting.GlobalShadows = false
	else
		Lighting.Ambient = originalLightSettings.Ambient
		Lighting.OutdoorAmbient = originalLightSettings.OutdoorAmbient
		Lighting.Brightness = originalLightSettings.Brightness
		Lighting.GlobalShadows = originalLightSettings.GlobalShadows
	end
end)

-- ESP Отрисовка
local espElements = {}

local function createESPForCharacter(char)
	if espElements[char] then return end
	local root = char:WaitForChild("HumanoidRootPart", 5)
	if not root then return end

	local box = create("Frame", {
		Size = UDim2.fromOffset(50, 70),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 1,
		Visible = false,
		Parent = screen,
	})
	stroke(box, C.Accent, 0.2, 1.5)

	local label = create("TextLabel", {
		Size = UDim2.fromOffset(100, 20),
		BackgroundTransparency = 1,
		TextColor3 = C.Text,
		Font = FONT.Bold,
		TextSize = 10,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false,
		Parent = screen,
	})

	local tracer = create("Frame", {
		Size = UDim2.fromOffset(1, 1),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		Visible = false,
		Parent = screen,
	})

	espElements[char] = { Box = box, Label = label, Tracer = tracer, Root = root, Char = char }
end

local function cleanESP()
	for char, el in pairs(espElements) do
		el.Box:Destroy()
		el.Label:Destroy()
		el.Tracer:Destroy()
	end
	table.clear(espElements)
end

local function updateESP()
	if not state.esp_Enabled then
		for _, el in pairs(espElements) do
			el.Box.Visible = false
			el.Label.Visible = false
			el.Tracer.Visible = false
		end
		return
	end

	for _, char in ipairs(workspace:GetDescendants()) do
		local isPlayer = Players:GetPlayerFromCharacter(char) ~= nil
		local isVagrantNPC = char:FindFirstChild("Humanoid") and char:FindFirstChild("Head") and not isPlayer

		if (isPlayer and char ~= player.Character) or isVagrantNPC then
			createESPForCharacter(char)
		end
	end

	for char, el in pairs(espElements) do
		if char.Parent and el.Root then
			local pos, onScreen = camera:WorldToViewportPoint(el.Root.Position)
			local distance = (camera.CFrame.Position - el.Root.Position).Magnitude

			if onScreen and distance <= state.esp_MaxDist then
				local sizeY = math.clamp(1500 / distance * 2, 10, 300)
				local sizeX = sizeY * 0.65

				if state.esp_Boxes then
					el.Box.Position = UDim2.fromOffset(pos.X - sizeX / 2, pos.Y - sizeY / 2)
					el.Box.Size = UDim2.fromOffset(sizeX, sizeY)
					el.Box.Visible = true
				else
					el.Box.Visible = false
				end

				if state.esp_Names then
					el.Label.Position = UDim2.fromOffset(pos.X - 50, pos.Y - sizeY / 2 - 22)
					local nameStr = char.Name
					local hum = char:FindFirstChild("Humanoid")
					if hum and state.esp_Health then
						nameStr = nameStr .. " [" .. math.floor(hum.Health) .. "]"
					end
					if state.esp_Distance then
						nameStr = nameStr .. " (" .. math.floor(distance) .. "m)"
					end
					el.Label.Text = nameStr
					el.Label.Visible = true
				else
					el.Label.Visible = false
				end

				if state.esp_Tracers then
					el.Tracer.Position = UDim2.fromOffset(pos.X, pos.Y)
					el.Tracer.Size = UDim2.fromOffset(1, viewport.Y - pos.Y)
					el.Tracer.Visible = true
				else
					el.Tracer.Visible = false
				end
			else
				el.Box.Visible = false
				el.Label.Visible = false
				el.Tracer.Visible = false
			end
		else
			el.Box:Destroy()
			el.Label:Destroy()
			el.Tracer:Destroy()
			espElements[char] = nil
		end
	end
end

---------------------------------------------------------------------
-- 12. RUN SERVICE INTEGRATION LOOPS
---------------------------------------------------------------------

-- Ссылка на движение и Аимбот
connect(RunService.RenderStepped, function()
	-- Отрисовка FOV
	visualCircle.Position = UserInputService:GetMouseLocation()

	-- Aimbot Работа
	if state.aimbot_Enabled then
		local target = getClosestTarget()
		if target then
			local aimPart = target:FindFirstChild(state.aimbot_Part)
			if aimPart then
				local targetCFrame = CFrame.new(camera.CFrame.Position, aimPart.Position)
				camera.CFrame = camera.CFrame:Lerp(targetCFrame, 1 / state.aimbot_Smooth)
			end
		end
	end

	-- Обход WalkSpeed в Vagrant Survival
	if state.speed_Enabled and player.Character then
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = state.speed_Value
		end
	end

	updateESP()
end)

-- Silent Aim Реализация
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
	if state.silent_Enabled and key == "Hit" and math.random(1, 100) <= state.silent_Chance then
		local target = getClosestTarget()
		if target then
			local aimPart = target:FindFirstChild(state.silent_Part)
			if aimPart then
				return aimPart.CFrame
			end
		end
	end
	return oldIndex(self, key)
end)

setreadonly(mt, true)

-- Infinite Jump Реализация
connect(UserInputService.JumpRequest, function()
	if state.infJump_Enabled and player.Character then
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

---------------------------------------------------------------------
-- 13. WINDOW CONTROLS & INITIALIZATION
---------------------------------------------------------------------

local function setWindowVisible(v)
	visibilityToken += 1
	windowVisible = v
	closePopup()

	if v then
		holder.Visible = true
		animate(window, 0.2, { GroupTransparency = 0 })
	else
		animate(window, 0.2, { GroupTransparency = 1 })
		task.delay(0.2, function()
			if not windowVisible then holder.Visible = false end
		end)
	end
end

closeButton.Activated:Connect(function() setWindowVisible(false) end)
mobileToggle.Activated:Connect(function() setWindowVisible(not windowVisible) end)

-- Window drag (Поддержка мобилок)
local windowDragStart, windowStartPos
local windowDragging = false

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		windowDragging = true
		windowDragStart = input.Position
		windowStartPos = holder.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if windowDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - windowDragStart
		holder.Position = UDim2.fromOffset(windowStartPos.X.Offset + delta.X, windowStartPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		windowDragging = false
	end
end)

-- Адаптация экрана под разные разрешения
local function adjustScale()
	local size = camera.ViewportSize
	viewport = size
	currentScale = math.clamp(size.Y / 1080, 0.55, 1)
	windowScale.Scale = currentScale
end
adjustScale()
connect(camera:GetPropertyChangedSignal("ViewportSize"), adjustScale)

-- Горячая клавиша скрытия
connect(UserInputService.InputBegan, function(input, gp)
	if gp then return end
	if input.KeyCode == state.keybind then
		setWindowVisible(not windowVisible)
	end
end)

-- На старт!
loadConfig()
setWindowVisible(true)
navigation["Main"].Button:Activate()
notify("2ZWare Запущен!", "Успешно загружено для Vagrant Survival.", "normal", true)
