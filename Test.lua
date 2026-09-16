--[[
	VELORA / Interface Lab
	Standalone Roblox Studio LocalScript

	Размещение:
	StarterPlayer > StarterPlayerScripts

	Единственная демонстрационная функция:
	локальный Signal HUD с синтетической анимацией.

	Никаких изменений персонажа, камеры, освещения,
	физики, сетевого состояния или других игроков.

	Настройки сохраняются только на время текущего запуска.
]]

---------------------------------------------------------------------
-- 01. SERVICES / LIFECYCLE
---------------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "VeloraInterfaceLab"

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
	Canvas = Color3.fromRGB(15, 19, 25),
	Sidebar = Color3.fromRGB(18, 23, 30),
	Surface = Color3.fromRGB(23, 29, 37),
	SurfaceRaised = Color3.fromRGB(29, 36, 45),
	Hover = Color3.fromRGB(36, 44, 54),

	Line = Color3.fromRGB(51, 61, 73),
	LineSoft = Color3.fromRGB(37, 46, 57),

	Text = Color3.fromRGB(235, 240, 244),
	Subtext = Color3.fromRGB(153, 168, 184),
	Muted = Color3.fromRGB(101, 119, 137),

	Accent = Color3.fromRGB(143, 231, 209),
	AccentDark = Color3.fromRGB(29, 63, 59),
	AccentInk = Color3.fromRGB(15, 39, 35),

	Gold = Color3.fromRGB(236, 196, 133),
	Red = Color3.fromRGB(243, 139, 145),
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

local defaults = {
	enabled = false,
	palette = "Mint",
	intensity = 80,
	opacity = 90,
	hudScale = 100,
	anchor = "TopRight",

	animated = true,
	motionStyle = "Wave",
	speed = 1,
	amplitude = 70,

	reduceMotion = false,
	notifications = true,
	keybind = Enum.KeyCode.RightShift,
}

local state = {}
for key, value in pairs(defaults) do
	state[key] = value
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

	return names[key] or key.Name
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

-- Один активный tween на объект: hover, reset и быстрые клики
-- не оставляют конкурирующих анимаций.
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
		animate(object, 0.16, {
			BackgroundColor3 = hoverColor,
		})
	end)

	object.MouseLeave:Connect(function()
		hovered = false
		animate(object, 0.18, {
			BackgroundColor3 = normalColor,
		})
	end)

	object.MouseButton1Down:Connect(function()
		animate(object, 0.08, {
			BackgroundColor3 = pressedColor or normalColor,
		})
	end)

	object.MouseButton1Up:Connect(function()
		animate(object, 0.15, {
			BackgroundColor3 = hovered and hoverColor or normalColor,
		})
	end)

	object.SelectionGained:Connect(function()
		animate(object, 0.15, {
			BackgroundColor3 = hoverColor,
		})
	end)

	object.SelectionLost:Connect(function()
		animate(object, 0.15, {
			BackgroundColor3 = normalColor,
		})
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
		for _, point in ipairs({
			{ 0.28, 0.28 },
			{ 0.72, 0.28 },
			{ 0.28, 0.72 },
			{ 0.72, 0.72 },
		}) do
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

local WIDTH = 980
local HEIGHT = 680
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

local windowScale = create("UIScale", {
	Scale = 1,
}, holder)

-- Многослойная мягкая тень без изображений.
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

text(sidebar, "VELORA", 19, C.Text, FONT.Bold, {
	Position = UDim2.fromOffset(70, 28),
	Size = UDim2.fromOffset(118, 23),
})

text(sidebar, "INTERFACE LAB", 9, C.Muted, FONT.Medium, {
	Position = UDim2.fromOffset(71, 53),
	Size = UDim2.fromOffset(125, 14),
})

text(sidebar, "WORKSPACE", 10, C.Muted, FONT.Medium, {
	Position = UDim2.fromOffset(25, 110),
	Size = UDim2.fromOffset(150, 16),
})

local navArea = frame(sidebar, {
	Position = UDim2.fromOffset(14, 141),
	Size = UDim2.new(1, -28, 0, 236),
})
verticalLayout(navArea, 8)

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
	BackgroundColor3 = C.Muted,
	BackgroundTransparency = 0,
})
corner(sidebarDot, 8)

local sidebarStatus = text(sidebarInfo, "DEMO STANDBY", 10, C.Subtext, FONT.Medium, {
	Position = UDim2.fromOffset(28, 10),
	Size = UDim2.fromOffset(130, 19),
})

text(sidebarInfo, "Только ваш интерфейс.\nБез влияния на игру.", 11, C.Muted, FONT.Regular, {
	Position = UDim2.fromOffset(14, 37),
	Size = UDim2.new(1, -28, 0, 36),
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
})

text(sidebar, "V / 01", 11, C.Subtext, FONT.Mono, {
	Position = UDim2.new(0, 24, 1, -40),
	Size = UDim2.fromOffset(70, 18),
})

text(sidebar, "LOCAL BUILD", 9, C.Muted, FONT.Medium, {
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

local eyebrow = text(header, "WORKSPACE / 01", 10, C.Accent, FONT.Medium, {
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

text(sandboxBadge, "•  SANDBOX", 10, C.Accent, FONT.Medium, {
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

local footerLeft = text(content, "01  /  MAIN", 10, C.Muted, FONT.Mono, {
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
-- 06. OVERLAYS / TOOLTIP / NOTIFICATIONS
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

local tooltip = text(screen, "", 11, C.Text, FONT.Medium, {
	Name = "Tooltip",
	BackgroundColor3 = C.SurfaceRaised,
	BackgroundTransparency = 0,
	Size = UDim2.fromOffset(240, 32),
	TextXAlignment = Enum.TextXAlignment.Center,
	Visible = false,
	ZIndex = 90,
})
corner(tooltip, 8)
stroke(tooltip, C.Line, 0.2)

local tooltipScale = create("UIScale", { Scale = 1 }, tooltip)

local function hideTooltip()
	tooltipToken += 1
	tooltip.Visible = false
end

local function addTooltip(object, message)
	object.MouseEnter:Connect(function()
		tooltipToken += 1
		local ticket = tooltipToken

		task.delay(0.55, function()
			if not alive or ticket ~= tooltipToken or not object.Parent then
				return
			end

			local width = 258 * currentScale
			local x = object.AbsolutePosition.X
				+ object.AbsoluteSize.X / 2
				- width / 2
			local y = object.AbsolutePosition.Y
				+ object.AbsoluteSize.Y
				+ 10 * currentScale

			tooltip.Text = message
			tooltip.Size = UDim2.fromOffset(258, 32)
			tooltipScale.Scale = currentScale
			tooltip.Position = UDim2.fromOffset(
				math.clamp(x, 8, math.max(8, viewport.X - width - 8)),
				math.clamp(y, 8, math.max(8, viewport.Y - 40 * currentScale))
			)
			tooltip.Visible = true
		end)
	end)

	object.MouseLeave:Connect(hideTooltip)
	object.Activated:Connect(hideTooltip)
end

addTooltip(closeButton, "Скрыть окно · HUD продолжит работу")

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
	if item.Removing then
		return
	end
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
	if not alive or (not state.notifications and not force) then
		return
	end

	hideTooltip()

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

	local timerLine = frame(group, {
		Position = UDim2.new(0, 0, 1, -2),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.55,
	})

	local hit = button(group, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Selectable = false,
	})

	local item = {
		Group = group,
		Removing = false,
	}

	table.insert(toasts, 1, item)
	arrangeToasts()
	animate(group, 0.25, { GroupTransparency = 0 })

	-- Таймер линейный, независимо от кривой остальных переходов.
	local timerTween = TweenService:Create(
		timerLine,
		TweenInfo.new(4.5, Enum.EasingStyle.Linear),
		{ Size = UDim2.new(0, 0, 0, 2) }
	)
	if not state.reduceMotion then
		timerTween:Play()
	end

	hit.Activated:Connect(function()
		removeToast(item)
	end)

	task.delay(4.5, function()
		if alive and group.Parent then
			removeToast(item)
		end
	end)
end

---------------------------------------------------------------------
-- 07. COMPONENTS
---------------------------------------------------------------------

local function section(parent, title, caption)
	local card = frame(parent, {
		Size = UDim2.new(1, -4, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.Surface,
		BackgroundTransparency = 0,
	})
	corner(card, 14)
	stroke(card, C.LineSoft, 0)
	padding(card, 18, 18, 15, 12)
	verticalLayout(card, 0)

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
		Size = UDim2.new(1, 0, 0, height or 72),
	})

	text(object, title, 13, C.Text, FONT.Medium, {
		Position = UDim2.fromOffset(0, 13),
		Size = UDim2.new(0.59, 0, 0, 20),
	})

	if description then
		text(object, description, 11, C.Muted, FONT.Regular, {
			Position = UDim2.fromOffset(0, 36),
			Size = UDim2.new(0.62, -5, 0, 24),
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
		})
	end

	return object
end

local function toggle(parent, key, title, description)
	local object = row(parent, title, description)

	local track = button(object, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(44, 25),
		BackgroundColor3 = C.Hover,
	})
	corner(track, 99)

	local trackStroke = stroke(track, C.Line, 0.35)

	local thumb = frame(track, {
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.fromOffset(17, 17),
		BackgroundColor3 = C.Subtext,
		BackgroundTransparency = 0,
	})
	corner(thumb, 99)

	local status = text(object, "", 10, C.Muted, FONT.Mono, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -57, 0.5, 0),
		Size = UDim2.fromOffset(33, 18),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	watch(key, function(value)
		animate(track, 0.20, {
			BackgroundColor3 = value and C.Accent or C.Hover,
		})
		animate(thumb, 0.22, {
			Position = UDim2.fromOffset(value and 23 or 4, 4),
			BackgroundColor3 = value and C.AccentInk or C.Subtext,
		})
		animate(trackStroke, 0.20, {
			Transparency = value and 1 or 0.35,
		})
		status.Text = value and "ON" or "OFF"
		status.TextColor3 = value and C.Accent or C.Muted
	end)

	track.Activated:Connect(function()
		setState(key, not state[key])
	end)

	addTooltip(track, title .. " · переключить")

	return object
end

local function slider(parent, key, title, description, minimum, maximum, step, formatter)
	local object = frame(parent, {
		Size = UDim2.new(1, 0, 0, 91),
	})

	text(object, title, 13, C.Text, FONT.Medium, {
		Position = UDim2.fromOffset(0, 12),
		Size = UDim2.new(1, -110, 0, 20),
	})

	text(object, description, 11, C.Muted, FONT.Regular, {
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, -100, 0, 18),
	})

	local valueLabel = text(object, "", 12, C.Accent, FONT.Mono, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 13),
		Size = UDim2.fromOffset(92, 20),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local hit = button(object, {
		Position = UDim2.fromOffset(0, 58),
		Size = UDim2.new(1, 0, 0, 25),
		BackgroundTransparency = 1,
	})

	local track = frame(hit, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = C.Hover,
		BackgroundTransparency = 0,
	})
	corner(track, 99)

	local fill = frame(track, {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0,
	})
	corner(fill, 99)

	local glow = frame(hit, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(25, 25),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 1,
	})
	corner(glow, 99)

	local knob = frame(hit, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = C.Text,
		BackgroundTransparency = 0,
	})
	corner(knob, 99)
	stroke(knob, C.Accent, 0.1, 2)

	local function normalize(value)
		local snapped = minimum + math.round((value - minimum) / step) * step
		return math.clamp(tonumber(string.format("%.4f", snapped)), minimum, maximum)
	end

	local function setFromX(x)
		local width = hit.AbsoluteSize.X
		if width <= 0 then
			return
		end

		local ratio = math.clamp((x - hit.AbsolutePosition.X) / width, 0, 1)
		setState(key, normalize(minimum + (maximum - minimum) * ratio))
	end

	watch(key, function(value)
		local ratio = (value - minimum) / (maximum - minimum)
		local duration = activeDrag and activeDrag.Owner == hit and 0 or 0.16

		animate(fill, duration, {
			Size = UDim2.fromScale(ratio, 1),
		})
		animate(knob, duration, {
			Position = UDim2.fromScale(ratio, 0.5),
		})
		animate(glow, duration, {
			Position = UDim2.fromScale(ratio, 0.5),
		})

		valueLabel.Text = formatter and formatter(value) or tostring(value)
	end)

	hit.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		closePopup()
		hideTooltip()

		activeDrag = {
			Owner = hit,
			Input = input,
			Update = function(position)
				setFromX(position.X)
			end,
			Finish = function()
				animate(glow, 0.18, { BackgroundTransparency = 1 })
				animate(knob, 0.18, { Size = UDim2.fromOffset(12, 12) })
			end,
		}

		animate(glow, 0.12, { BackgroundTransparency = 0.86 })
		animate(knob, 0.12, { Size = UDim2.fromOffset(14, 14) })
		setFromX(input.Position.X)
	end)

	hit.MouseEnter:Connect(function()
		animate(glow, 0.15, { BackgroundTransparency = 0.9 })
	end)

	hit.MouseLeave:Connect(function()
		if not activeDrag or activeDrag.Owner ~= hit then
			animate(glow, 0.15, { BackgroundTransparency = 1 })
		end
	end)

	-- Поддержка клавиатуры при выборе слайдера
	-- через стандартную систему GUI selection Roblox.
	connect(UserInputService.InputBegan, function(input)
		if not windowVisible or capturingKey then
			return
		end

		if GuiService.SelectedObject ~= hit then
			return
		end

		if input.KeyCode == Enum.KeyCode.Left then
			setState(key, normalize(state[key] - step))
		elseif input.KeyCode == Enum.KeyCode.Right then
			setState(key, normalize(state[key] + step))
		end
	end)

	return object
end

local function dropdown(parent, key, title, description, options)
	local object = row(parent, title, description, 77)

	local control = button(object, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(210, 37),
		BackgroundColor3 = C.SurfaceRaised,
	})
	corner(control, 9)
	stroke(control, C.Line, 0.3)
	interaction(control, C.SurfaceRaised, C.Hover, C.Sidebar)

	local selectedText = text(control, "", 12, C.Text, FONT.Medium, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -45, 1, 0),
	})
	icon(control, "chevron", C.Subtext, UDim2.new(1, -27, 0.5, -7), 14)

	watch(key, function(value)
		for _, option in ipairs(options) do
			if option.Value == value then
				selectedText.Text = option.Label
				break
			end
		end
	end)

	control.Activated:Connect(function()
		if popup and popup:GetAttribute("SettingKey") == key then
			closePopup()
			return
		end

		closePopup()
		hideTooltip()

		local designWidth = 230
		local designHeight = #options * 37 + 12
		local absolute = control.AbsolutePosition
		local absoluteSize = control.AbsoluteSize

		local x = absolute.X + absoluteSize.X - designWidth * currentScale
		local y = absolute.Y + absoluteSize.Y + 7 * currentScale

		if y + designHeight * currentScale > viewport.Y - 12 then
			y = absolute.Y - (designHeight + 7) * currentScale
		end

		x = math.clamp(
			x,
			10,
			math.max(10, viewport.X - designWidth * currentScale - 10)
		)
		y = math.clamp(
			y,
			10,
			math.max(10, viewport.Y - designHeight * currentScale - 10)
		)

		popup = create("CanvasGroup", {
			Name = "Dropdown",
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(designWidth, designHeight),
			BackgroundColor3 = C.SurfaceRaised,
			BorderSizePixel = 0,
			GroupTransparency = 1,
			ZIndex = 2,
		}, popupLayer)

		popup:SetAttribute("SettingKey", key)
		corner(popup, 11)
		stroke(popup, C.Line, 0)
		padding(popup, 6, 6, 6, 6)
		verticalLayout(popup, 1)
		create("UIScale", { Scale = currentScale }, popup)

		dismissPopup.Visible = true

		for _, option in ipairs(options) do
			local selected = state[key] == option.Value

			local item = button(popup, {
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = selected and C.AccentDark or C.SurfaceRaised,
			})
			corner(item, 7)

			text(item, option.Label, 12, selected and C.Accent or C.Subtext, FONT.Medium, {
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, -45, 1, 0),
			})

			if selected then
				icon(item, "check", C.Accent, UDim2.new(1, -27, 0.5, -7), 14)
			end

			interaction(
				item,
				selected and C.AccentDark or C.SurfaceRaised,
				C.Hover,
				C.Sidebar
			)

			item.Activated:Connect(function()
				setState(key, option.Value)
				closePopup()
			end)
		end

		animate(popup, 0.16, { GroupTransparency = 0 })
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

local function note(parent, title, description)
	local object = frame(parent, {
		Size = UDim2.new(1, -4, 0, 79),
		BackgroundColor3 = C.AccentDark,
		BackgroundTransparency = 0.60,
	})
	corner(object, 12)
	stroke(object, C.Accent, 0.88)

	icon(object, "spark", C.Accent, UDim2.fromOffset(17, 20), 19)

	text(object, title, 12, C.Accent, FONT.Medium, {
		Position = UDim2.fromOffset(50, 13),
		Size = UDim2.new(1, -65, 0, 21),
	})

	text(object, description, 11, C.Subtext, FONT.Regular, {
		Position = UDim2.fromOffset(50, 38),
		Size = UDim2.new(1, -67, 0, 29),
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	return object
end

---------------------------------------------------------------------
-- 08. SINGLE DEMO FEATURE: SIGNAL HUD
---------------------------------------------------------------------

local visualizers = {}

local function createSignalVisualizer(parent, properties, isPreview)
	local settings = {
		Name = isPreview and "SignalPreview" or "SignalHUD",
		Size = UDim2.fromOffset(264, 150),
		BackgroundColor3 = Color3.fromRGB(15, 27, 31),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
	}

	for key, value in pairs(properties or {}) do
		settings[key] = value
	end

	local object = frame(parent, settings)
	corner(object, 13)

	local outline = stroke(object, C.Accent, 0.73)

	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 255, 249)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 181, 205)),
		}),
		Rotation = 35,
	}, object)

	local dot = frame(object, {
		Position = UDim2.fromOffset(15, 16),
		Size = UDim2.fromOffset(5, 5),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0,
	})
	corner(dot, 99)

	local label = text(object, "SIGNAL / LOCAL", 9, C.Accent, FONT.Medium, {
		Position = UDim2.fromOffset(27, 10),
		Size = UDim2.fromOffset(150, 17),
	})

	local mode = text(object, isPreview and "PREVIEW" or "LIVE", 8, C.Subtext, FONT.Mono, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 11),
		Size = UDim2.fromOffset(64, 15),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local number = text(object, "64", 32, C.Text, FONT.Bold, {
		Position = UDim2.fromOffset(14, 31),
		Size = UDim2.fromOffset(67, 41),
	})

	text(object, "%", 12, C.Muted, FONT.Mono, {
		Position = UDim2.fromOffset(71, 47),
		Size = UDim2.fromOffset(20, 19),
	})

	text(object, "SYNTHETIC\nAMPLITUDE", 8, C.Muted, FONT.Medium, {
		Position = UDim2.fromOffset(108, 37),
		Size = UDim2.fromOffset(136, 30),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	local graph = frame(object, {
		Position = UDim2.fromOffset(15, 82),
		Size = UDim2.new(1, -30, 0, 36),
		ClipsDescendants = true,
	})

	for index = 1, 3 do
		frame(graph, {
			Position = UDim2.fromScale(0, index / 3),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = C.Line,
			BackgroundTransparency = 0.72,
		})
	end

	local bars = {}
	local BAR_COUNT = 26

	for index = 1, BAR_COUNT do
		local bar = frame(graph, {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale((index - 1) / BAR_COUNT, 1),
			Size = UDim2.new(1 / BAR_COUNT, -3, 0.5, 0),
			BackgroundColor3 = C.Accent,
			BackgroundTransparency = 0,
		})
		corner(bar, 2)
		table.insert(bars, bar)
	end

	text(object, "NO GAME DATA", 8, C.Muted, FONT.Mono, {
		Position = UDim2.fromOffset(15, 128),
		Size = UDim2.fromOffset(135, 12),
	})

	local motionLabel = text(object, "WAVE", 8, C.Subtext, FONT.Mono, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 128),
		Size = UDim2.fromOffset(105, 12),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local data = {
		Object = object,
		Outline = outline,
		Dot = dot,
		Label = label,
		Mode = mode,
		Number = number,
		Bars = bars,
		MotionLabel = motionLabel,
		IsPreview = isPreview,
	}

	table.insert(visualizers, data)
	return data
end

local hud = createSignalVisualizer(screen, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -24, 0, 24),
	Visible = false,
	ZIndex = 20,
}, false)

local hudUIScale = create("UIScale", { Scale = 1 }, hud.Object)

local function updateHUDLayout()
	hudUIScale.Scale = currentScale * state.hudScale / 100

	local margin = 22
	local anchor = state.anchor

	if anchor == "TopLeft" then
		hud.Object.AnchorPoint = Vector2.new(0, 0)
		hud.Object.Position = UDim2.fromOffset(margin, margin)
	elseif anchor == "TopRight" then
		hud.Object.AnchorPoint = Vector2.new(1, 0)
		hud.Object.Position = UDim2.new(1, -margin, 0, margin)
	elseif anchor == "BottomLeft" then
		hud.Object.AnchorPoint = Vector2.new(0, 1)
		hud.Object.Position = UDim2.new(0, margin, 1, -margin)
	else
		hud.Object.AnchorPoint = Vector2.new(1, 1)
		hud.Object.Position = UDim2.new(1, -margin, 1, -margin)
	end
end

local function updateVisualizerAppearance()
	local accent = PALETTES[state.palette] or C.Accent

	for _, visualizer in ipairs(visualizers) do
		visualizer.Object.BackgroundColor3 = C.Canvas:Lerp(accent, 0.075)
		visualizer.Object.BackgroundTransparency = 1 - state.opacity / 100
		visualizer.Outline.Color = accent
		visualizer.Label.TextColor3 = accent
		visualizer.Dot.BackgroundColor3 = accent
	end
end

watch("enabled", function(value)
	hud.Object.Visible = value
	sidebarStatus.Text = value and "DEMO RUNNING" or "DEMO STANDBY"
	sidebarStatus.TextColor3 = value and C.Accent or C.Subtext
	animate(sidebarDot, 0.18, {
		BackgroundColor3 = value and C.Accent or C.Muted,
	})
end)

watch("anchor", updateHUDLayout)
watch("hudScale", updateHUDLayout)
watch("palette", updateVisualizerAppearance)
watch("opacity", updateVisualizerAppearance)

---------------------------------------------------------------------
-- 09. TABS / ROUTER
---------------------------------------------------------------------

local tabDefinitions = {
	{
		Name = "Main",
		Icon = "main",
		Description = "Один локальный эксперимент. Все элементы — настоящие.",
	},
	{
		Name = "Visuals",
		Icon = "visuals",
		Description = "Палитра, контраст и размещение демонстрационного HUD.",
	},
	{
		Name = "Movement",
		Icon = "movement",
		Description = "Хореография сигнала — не движение персонажа.",
	},
	{
		Name = "Settings",
		Icon = "settings",
		Description = "Поведение интерфейса, доступность и горячая клавиша.",
	},
}

local pages = {}
local navigation = {}
local currentTab = nil

for index, definition in ipairs(tabDefinitions) do
	local page = create("ScrollingFrame", {
		Name = definition.Name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.Accent,
		ScrollBarImageTransparency = 0.65,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		Visible = false,
	}, pagesContainer)
	padding(page, 1, 7, 2, 10)
	verticalLayout(page, 14)

	page:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		closePopup()
		hideTooltip()
	end)

	pages[definition.Name] = page

	local nav = button(navArea, {
		Size = UDim2.new(1, 0, 0, 47),
		BackgroundColor3 = C.Sidebar,
		LayoutOrder = index,
	})
	corner(nav, 10)

	local outline = stroke(nav, C.Accent, 1)
	local navIcon = icon(nav, definition.Icon, C.Muted, UDim2.fromOffset(14, 14), 19)

	local label = text(nav, definition.Name, 13, C.Subtext, FONT.Medium, {
		Position = UDim2.fromOffset(46, 0),
		Size = UDim2.new(1, -82, 1, 0),
	})

	local count = text(nav, string.format("%02d", index), 9, C.Muted, FONT.Mono, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -13, 0, 0),
		Size = UDim2.fromOffset(23, 47),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local indicator = frame(nav, {
		Position = UDim2.fromOffset(0, 16),
		Size = UDim2.fromOffset(3, 15),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 1,
	})
	corner(indicator, 4)

	navigation[definition.Name] = {
		Button = nav,
		Outline = outline,
		Icon = navIcon,
		Label = label,
		Count = count,
		Indicator = indicator,
		Index = index,
		Definition = definition,
	}

	nav.MouseEnter:Connect(function()
		if currentTab ~= definition.Name then
			animate(nav, 0.15, { BackgroundColor3 = C.Surface })
		end
	end)

	nav.MouseLeave:Connect(function()
		if currentTab ~= definition.Name then
			animate(nav, 0.18, { BackgroundColor3 = C.Sidebar })
		end
	end)
end

local function selectTab(name)
	if currentTab == name then
		return
	end

	closePopup()
	hideTooltip()
	currentTab = name

	for tabName, data in pairs(navigation) do
		local selected = tabName == name
		pages[tabName].Visible = selected

		animate(data.Button, 0.20, {
			BackgroundColor3 = selected and C.AccentDark or C.Sidebar,
		})
		animate(data.Outline, 0.20, {
			Transparency = selected and 0.76 or 1,
		})
		animate(data.Indicator, 0.20, {
			BackgroundTransparency = selected and 0 or 1,
		})
		animate(data.Label, 0.20, {
			TextColor3 = selected and C.Text or C.Subtext,
		})
		animate(data.Count, 0.20, {
			TextColor3 = selected and C.Accent or C.Muted,
		})
		data.Icon.SetColor(selected and C.Accent or C.Muted)
	end

	local data = navigation[name]
	eyebrow.Text = string.format("WORKSPACE / %02d", data.Index)
	pageTitle.Text = name
	pageDescription.Text = data.Definition.Description
	footerLeft.Text = string.format("%02d  /  %s", data.Index, string.upper(name))

	local page = pages[name]
	page.Position = UDim2.fromOffset(state.reduceMotion and 0 or 10, 0)
	animate(page, 0.24, { Position = UDim2.fromOffset(0, 0) })
end

for name, data in pairs(navigation) do
	data.Button.Activated:Connect(function()
		selectTab(name)
	end)
end

---------------------------------------------------------------------
-- 10. MAIN PAGE
---------------------------------------------------------------------

do
	local page = pages.Main

	local hero = frame(page, {
		Size = UDim2.new(1, -4, 0, 182),
		BackgroundColor3 = Color3.fromRGB(27, 43, 47),
		BackgroundTransparency = 0,
		ClipsDescendants = true,
	})
	corner(hero, 15)
	stroke(hero, C.Accent, 0.79)

	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(229, 255, 243)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(107, 137, 162)),
		}),
		Rotation = 20,
	}, hero)

	-- Декоративная координатная сетка.
	for index = 1, 9 do
		frame(hero, {
			Position = UDim2.new(0.53 + index * 0.055, 0, 0, 0),
			Size = UDim2.new(0, 1, 1, 0),
			BackgroundColor3 = C.Accent,
			BackgroundTransparency = 0.95,
		})
	end

	for index = 1, 5 do
		frame(hero, {
			Position = UDim2.new(0.52, 0, index / 5, 0),
			Size = UDim2.new(0.48, 0, 0, 1),
			BackgroundColor3 = C.Accent,
			BackgroundTransparency = 0.95,
		})
	end

	text(hero, "EXPERIMENT 001", 9, C.Accent, FONT.Medium, {
		Position = UDim2.fromOffset(22, 19),
		Size = UDim2.fromOffset(240, 17),
	})

	text(hero, "A quieter kind\nof control.", 27, C.Text, FONT.Bold, {
		Position = UDim2.fromOffset(21, 43),
		Size = UDim2.fromOffset(360, 69),
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	text(hero, "Signal HUD / синтетический сигнал", 11, C.Subtext, FONT.Regular, {
		Position = UDim2.fromOffset(23, 122),
		Size = UDim2.fromOffset(350, 20),
	})

	text(hero, "DESIGNED TO FEEL DIFFERENT", 8, C.Muted, FONT.Medium, {
		Position = UDim2.fromOffset(23, 151),
		Size = UDim2.fromOffset(340, 14),
	})

	createSignalVisualizer(hero, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -17, 0.5, 0),
	}, true)

	local controls = section(
		page,
		"Signal HUD",
		"Живое превью выше работает и при выключенном внешнем HUD."
	)

	toggle(
		controls,
		"enabled",
		"Показать локальный HUD",
		"Отдельная панель поверх вашего экрана."
	)

	divider(controls)

	dropdown(
		controls,
		"anchor",
		"Размещение",
		"Положение внешней панели на экране.",
		{
			{ Value = "TopRight", Label = "Справа сверху" },
			{ Value = "TopLeft", Label = "Слева сверху" },
			{ Value = "BottomRight", Label = "Справа снизу" },
			{ Value = "BottomLeft", Label = "Слева снизу" },
		}
	)

	local actions = frame(controls, {
		Size = UDim2.new(1, 0, 0, 54),
	})

	actionButton(actions, "Открыть Visuals", true, function()
		selectTab("Visuals")
	end, {
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.fromOffset(173, 36),
	})

	actionButton(actions, "Смотреть отдельно", false, function()
		setState("enabled", true)
		-- Обработчик показа/скрытия будет подключён после сборки UI.
		screen:SetAttribute("RequestHide", os.clock())
	end, {
		Position = UDim2.fromOffset(183, 8),
		Size = UDim2.fromOffset(177, 36),
	})

	local metrics = frame(page, {
		Size = UDim2.new(1, -4, 0, 73),
	})

	local metricData = {
		{ Value = "01", Label = "SAFE DEMO", Accent = C.Accent },
		{ Value = "04", Label = "WORKSPACES", Accent = C.Text },
		{ Value = "100%", Label = "CLIENT-SIDE", Accent = C.Gold },
	}

	for index, metric in ipairs(metricData) do
		local cell = frame(metrics, {
			Position = UDim2.new((index - 1) / 3, index == 1 and 0 or 4, 0, 0),
			Size = UDim2.new(1 / 3, -8, 1, 0),
			BackgroundColor3 = C.Surface,
			BackgroundTransparency = 0,
		})
		corner(cell, 11)
		stroke(cell, C.LineSoft, 0.15)

		text(cell, metric.Value, 22, metric.Accent, FONT.Medium, {
			Position = UDim2.fromOffset(15, 11),
			Size = UDim2.new(1, -30, 0, 28),
		})
		text(cell, metric.Label, 8, C.Muted, FONT.Medium, {
			Position = UDim2.fromOffset(16, 45),
			Size = UDim2.new(1, -30, 0, 15),
		})
	end
end

---------------------------------------------------------------------
-- 11. VISUALS PAGE
---------------------------------------------------------------------

do
	local page = pages.Visuals
	local appearance = section(page, "Appearance", "Изменения сразу применяются к HUD и его превью.")

	local paletteRow = frame(appearance, {
		Size = UDim2.new(1, 0, 0, 91),
	})

	text(paletteRow, "Цвет сигнала", 13, C.Text, FONT.Medium, {
		Position = UDim2.fromOffset(0, 9),
		Size = UDim2.fromOffset(260, 20),
	})

	local paletteName = text(paletteRow, "", 11, C.Subtext, FONT.Mono, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 11),
		Size = UDim2.fromOffset(150, 19),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local colorButtons = {}

	for index, name in ipairs({ "Mint", "Iris", "Glacier", "Amber", "Rose" }) do
		local swatch = button(paletteRow, {
			Position = UDim2.fromOffset((index - 1) * 46, 43),
			Size = UDim2.fromOffset(34, 30),
			BackgroundColor3 = PALETTES[name],
		})
		corner(swatch, 8)

		local selectionStroke = stroke(swatch, C.Text, 1, 2)
		local checkIcon = icon(swatch, "check", C.AccentInk, UDim2.fromOffset(9, 7), 16)

		colorButtons[name] = {
			Stroke = selectionStroke,
			Check = checkIcon.Object,
			Button = swatch,
		}

		swatch.Activated:Connect(function()
			setState("palette", name)
		end)

		addTooltip(swatch, name .. " · цвет Signal HUD")
	end

	watch("palette", function(value)
		paletteName.Text = string.upper(value)
		for name, data in pairs(colorButtons) do
			data.Check.Visible = name == value
			animate(data.Stroke, 0.18, {
				Transparency = name == value and 0.1 or 1,
			})
			animate(data.Button, 0.18, {
				BackgroundTransparency = name == value and 0 or 0.35,
			})
		end
	end)

	divider(appearance)

	slider(
		appearance,
		"intensity",
		"Интенсивность",
		"Яркость столбцов относительно фона.",
		15, 100, 1,
		function(value)
			return value .. "%"
		end
	)

	divider(appearance)

	slider(
		appearance,
		"opacity",
		"Плотность фона",
		"Прозрачность поверхности HUD.",
		30, 100, 1,
		function(value)
			return value .. "%"
		end
	)

	local placement = section(page, "Viewport", "Эти параметры относятся только к внешней панели.")

	slider(
		placement,
		"hudScale",
		"Размер HUD",
		"Масштаб без изменения основного окна.",
		75, 130, 5,
		function(value)
			return value .. "%"
		end
	)

	note(
		page,
		"Самостоятельная визуальная система",
		"Палитра сигнала не меняет акцент навигации: интерфейс остаётся цельным."
	)
end

---------------------------------------------------------------------
-- 12. MOVEMENT PAGE
---------------------------------------------------------------------

do
	local page = pages.Movement

	note(
		page,
		"Только движение графики",
		"Здесь нет настроек скорости игрока, прыжка, телепортации или камеры."
	)

	local motion = section(page, "Motion engine", "Управление синтетической анимацией Signal HUD.")

	toggle(
		motion,
		"animated",
		"Воспроизведение",
		"Выключение фиксирует текущую фазу сигнала."
	)

	divider(motion)

	dropdown(
		motion,
		"motionStyle",
		"Характер движения",
		"Три варианта одной визуализации.",
		{
			{ Value = "Wave", Label = "Wave / волна" },
			{ Value = "Pulse", Label = "Pulse / пульсация" },
			{ Value = "Cascade", Label = "Cascade / каскад" },
		}
	)

	divider(motion)

	slider(
		motion,
		"speed",
		"Темп",
		"Скорость прохождения анимационной фазы.",
		0.25, 2, 0.05,
		function(value)
			return string.format("%.2f×", value)
		end
	)

	divider(motion)

	slider(
		motion,
		"amplitude",
		"Амплитуда",
		"Высота синтетического сигнала.",
		15, 100, 1,
		function(value)
			return value .. "%"
		end
	)

	local motionStatus = text(page, "", 11, C.Muted, FONT.Regular, {
		Size = UDim2.new(1, -8, 0, 35),
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	local function refreshMotionStatus()
		if state.reduceMotion then
			motionStatus.Text = "Пауза: в Settings включён режим «Меньше движения»."
			motionStatus.TextColor3 = C.Gold
		elseif not state.animated then
			motionStatus.Text = "Сигнал зафиксирован. Включите воспроизведение, чтобы продолжить."
			motionStatus.TextColor3 = C.Subtext
		else
			motionStatus.Text = "Анимация активна. Данные генерируются локально и не описывают состояние игры."
			motionStatus.TextColor3 = C.Muted
		end
	end

	watch("reduceMotion", refreshMotionStatus)
	watch("animated", refreshMotionStatus)
end

---------------------------------------------------------------------
-- 13. SETTINGS PAGE
---------------------------------------------------------------------

local keybindButton
local keybindText
local resetButton
local resetArmed = false
local resetToken = 0

local function refreshKeybindDisplay()
	if not keybindText then
		return
	end

	keybindText.Text = capturingKey and "Нажмите клавишу…" or keyName(state.keybind)
	keybindText.TextColor3 = capturingKey and C.Accent or C.Text
end

local function cancelKeyCapture()
	capturingKey = false
	refreshKeybindDisplay()
end

do
	local page = pages.Settings

	local interface = section(page, "Interface", "Настройки текущей сессии, без внешнего хранилища.")

	local keyRow = row(
		interface,
		"Показать / скрыть",
		"Нажмите справа, затем выберите клавишу.",
		76
	)

	keybindButton = button(keyRow, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(185, 37),
		BackgroundColor3 = C.SurfaceRaised,
	})
	corner(keybindButton, 9)
	stroke(keybindButton, C.Line, 0.3)
	interaction(keybindButton, C.SurfaceRaised, C.Hover, C.Sidebar)

	keybindText = text(keybindButton, "", 12, C.Text, FONT.Mono, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	keybindButton.Activated:Connect(function()
		closePopup()
		capturingKey = not capturingKey
		refreshKeybindDisplay()

		if capturingKey then
			notify("Новая горячая клавиша", "Нажмите клавишу. Escape — отмена.")
		end
	end)

	addTooltip(keybindButton, "Переназначить · Escape отменяет ввод")

	divider(interface)

	toggle(
		interface,
		"reduceMotion",
		"Меньше движения",
		"Мгновенные переходы и неподвижный сигнал."
	)

	divider(interface)

	toggle(
		interface,
		"notifications",
		"Уведомления",
		"Небольшие сообщения о действиях интерфейса."
	)

	local utilities = section(page, "Session", "Сброс требует повторного нажатия.")

	local utilityActions = frame(utilities, {
		Size = UDim2.new(1, 0, 0, 51),
	})

	actionButton(utilityActions, "Проверить уведомление", false, function()
		if state.notifications then
			notify(
				"Everything is in place",
				"Плавный вход, очередь и автоматическое закрытие."
			)
		else
			notify(
				"Тестовое уведомление",
				"Обычные уведомления сейчас отключены.",
				"warning",
				true
			)
		end
	end, {
		Position = UDim2.fromOffset(0, 5),
		Size = UDim2.fromOffset(225, 38),
	})

	resetButton = actionButton(utilityActions, "Сбросить настройки", false, function()
		if not resetArmed then
			resetArmed = true
			resetToken += 1

			local ticket = resetToken
			resetButton.Text = "Подтвердить сброс"
			resetButton.TextColor3 = C.Gold

			task.delay(3.5, function()
				if alive and ticket == resetToken then
					resetArmed = false
					resetButton.Text = "Сбросить настройки"
					resetButton.TextColor3 = C.Text
				end
			end)
			return
		end

		resetToken += 1
		resetArmed = false
		closePopup()
		cancelKeyCapture()

		-- Сначала возвращаем стандартное поведение анимаций.
		setState("reduceMotion", defaults.reduceMotion)

		for key, value in pairs(defaults) do
			setState(key, value)
		end

		resetButton.Text = "Сбросить настройки"
		resetButton.TextColor3 = C.Text

		notify("Настройки восстановлены", "Возвращены исходные параметры VELORA.")
	end, {
		Position = UDim2.fromOffset(237, 5),
		Size = UDim2.fromOffset(213, 38),
	})

	note(
		page,
		"Built for a local sandbox",
		"Без HTTP, сторонних модулей и игровых изменений. После перезапуска настройки сбрасываются."
	)

	text(page, "VELORA  /  INTERFACE LAB                                EDITION 01", 9, C.Muted, FONT.Mono, {
		Size = UDim2.new(1, -8, 0, 23),
	})
end

---------------------------------------------------------------------
-- 14. WINDOW VISIBILITY / LAUNCHER
---------------------------------------------------------------------

local launcher = button(screen, {
	Name = "Reopen",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 22, 1, -22),
	Size = UDim2.fromOffset(208, 45),
	BackgroundColor3 = C.Sidebar,
	Visible = false,
	ZIndex = 70,
})
corner(launcher, 12)
stroke(launcher, C.Line, 0)
interaction(launcher, C.Sidebar, C.SurfaceRaised, C.Canvas)

local launcherScale = create("UIScale", { Scale = 1 }, launcher)

local launcherMark = frame(launcher, {
	Position = UDim2.fromOffset(10, 9),
	Size = UDim2.fromOffset(27, 27),
	BackgroundColor3 = C.Accent,
	BackgroundTransparency = 0,
})
corner(launcherMark, 8)
icon(launcherMark, "spark", C.AccentInk, UDim2.fromOffset(6, 6), 15)

local launcherLabel = text(launcher, "", 11, C.Text, FONT.Medium, {
	Position = UDim2.fromOffset(48, 0),
	Size = UDim2.new(1, -57, 1, 0),
})

local function finishDrag()
	if activeDrag then
		if activeDrag.Finish then
			activeDrag.Finish()
		end
		activeDrag = nil
	end
end

local function setWindowVisible(value)
	visibilityToken += 1
	local ticket = visibilityToken

	windowVisible = value
	closePopup()
	hideTooltip()
	cancelKeyCapture()
	finishDrag()

	if not value then
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(holder) then
			GuiService.SelectedObject = nil
		end
	end

	if value then
		holder.Visible = true
		launcher.Visible = false
		animate(window, 0.25, { GroupTransparency = 0 })
	else
		launcher.Visible = true
		animate(window, 0.18, { GroupTransparency = 1 })

		task.delay(state.reduceMotion and 0 or 0.19, function()
			if alive and ticket == visibilityToken and not windowVisible then
				holder.Visible = false
			end
		end)
	end
end

closeButton.Activated:Connect(function()
	setWindowVisible(false)
end)

launcher.Activated:Connect(function()
	setWindowVisible(true)
end)

screen:GetAttributeChangedSignal("RequestHide"):Connect(function()
	setWindowVisible(false)
	notify("Signal HUD активен", "Вернуть окно можно кнопкой VELORA или горячей клавишей.")
end)

watch("keybind", function(value)
	refreshKeybindDisplay()
	footerRight.Text = keyName(value) .. " — скрыть окно   /   LOCAL ONLY"
	launcherLabel.Text = "VELORA  ·  " .. keyName(value)
end)

---------------------------------------------------------------------
-- 15. RESPONSIVE SCALE / DRAGGING
---------------------------------------------------------------------

local function clampWindowPosition(position)
	local halfWidth = WIDTH * currentScale / 2
	local halfHeight = HEIGHT * currentScale / 2
	local margin = 12

	local minX = halfWidth + margin
	local maxX = viewport.X - halfWidth - margin
	local minY = halfHeight + margin
	local maxY = viewport.Y - halfHeight - margin

	return Vector2.new(
		maxX >= minX and math.clamp(position.X, minX, maxX) or viewport.X / 2,
		maxY >= minY and math.clamp(position.Y, minY, maxY) or viewport.Y / 2
	)
end

local function applyWindowPosition()
	windowCenter = clampWindowPosition(windowCenter)
	holder.Position = UDim2.fromOffset(windowCenter.X, windowCenter.Y)
end

local function refreshViewport()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local size = camera.ViewportSize
	if size.X < 1 or size.Y < 1 then
		return
	end

	local oldViewport = viewport
	viewport = size

	currentScale = math.max(
		0.05,
		math.min(
			1,
			(viewport.X - 34) / WIDTH,
			(viewport.Y - 70) / HEIGHT
		)
	)

	windowScale.Scale = currentScale
	toastScale.Scale = currentScale
	launcherScale.Scale = currentScale

	if manuallyPositioned and oldViewport.X > 0 and oldViewport.Y > 0 then
		windowCenter = Vector2.new(
			windowCenter.X / oldViewport.X * viewport.X,
			windowCenter.Y / oldViewport.Y * viewport.Y
		)
	else
		windowCenter = viewport / 2
	end

	closePopup()
	hideTooltip()
	finishDrag()
	applyWindowPosition()
	updateHUDLayout()
end

local cameraViewportConnection = nil

local function bindCamera()
	if cameraViewportConnection then
		cameraViewportConnection:Disconnect()
		cameraViewportConnection = nil
	end

	local camera = workspace.CurrentCamera
	if camera then
		cameraViewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(
			refreshViewport
		)
	end

	refreshViewport()
end

connect(workspace:GetPropertyChangedSignal("CurrentCamera"), bindCamera)

local function beginWindowDrag(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	if not windowVisible then
		return
	end

	-- Область кнопки закрытия не запускает перенос.
	local point = Vector2.new(input.Position.X, input.Position.Y)
	local closePos = closeButton.AbsolutePosition
	local closeSize = closeButton.AbsoluteSize

	if point.X >= closePos.X - 8
		and point.X <= closePos.X + closeSize.X + 8
		and point.Y >= closePos.Y - 8
		and point.Y <= closePos.Y + closeSize.Y + 8 then
		return
	end

	closePopup()
	hideTooltip()

	local startPointer = point
	local startCenter = windowCenter

	activeDrag = {
		Owner = header,
		Input = input,
		Update = function(position)
			local newPointer = Vector2.new(position.X, position.Y)
			local delta = newPointer - startPointer

			if delta.Magnitude > 2 then
				manuallyPositioned = true
			end

			windowCenter = startCenter + delta
			applyWindowPosition()
		end,
	}
end

header.InputBegan:Connect(beginWindowDrag)

-- Вторая зона переноса: бренд в сайдбаре.
local brandDrag = frame(sidebar, {
	Position = UDim2.fromOffset(15, 17),
	Size = UDim2.fromOffset(179, 65),
	Active = true,
	ZIndex = 5,
})
brandDrag.InputBegan:Connect(beginWindowDrag)

connect(UserInputService.InputChanged, function(input)
	if not activeDrag then
		return
	end

	local original = activeDrag.Input

	if original.UserInputType == Enum.UserInputType.Touch then
		if input == original then
			activeDrag.Update(input.Position)
		end
	elseif input.UserInputType == Enum.UserInputType.MouseMovement then
		activeDrag.Update(input.Position)
	end
end)

connect(UserInputService.InputEnded, function(input)
	if not activeDrag then
		return
	end

	local original = activeDrag.Input

	if input == original
		or (
			original.UserInputType == Enum.UserInputType.MouseButton1
			and input.UserInputType == Enum.UserInputType.MouseButton1
		) then
		finishDrag()
	end
end)

connect(UserInputService.WindowFocusReleased, function()
	finishDrag()
	cancelKeyCapture()
	closePopup()
end)

---------------------------------------------------------------------
-- 16. KEYBOARD ROUTING
---------------------------------------------------------------------

connect(UserInputService.InputBegan, function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	if capturingKey then
		if input.KeyCode == Enum.KeyCode.Escape then
			cancelKeyCapture()
			notify("Изменение отменено", "Предыдущая горячая клавиша сохранена.")
			return
		end

		if input.KeyCode == Enum.KeyCode.Unknown then
			return
		end

		capturingKey = false
		setState("keybind", input.KeyCode)
		refreshKeybindDisplay()

		notify("Горячая клавиша обновлена", keyName(input.KeyCode) .. " — показать или скрыть окно.")
		return
	end

	if UserInputService:GetFocusedTextBox() then
		return
	end

	if input.KeyCode == Enum.KeyCode.Escape and popup then
		closePopup()
		return
	end

	if gameProcessed then
		return
	end

	if input.KeyCode == state.keybind then
		setWindowVisible(not windowVisible)
	end
end)

---------------------------------------------------------------------
-- 17. DEMO RENDERER
---------------------------------------------------------------------

local phase = 0.8
local accumulator = 0
local FRAME_INTERVAL = 1 / 30

local function signalValue(index)
	local value

	if state.motionStyle == "Pulse" then
		local pulse = (math.sin(phase * 2.6) + 1) / 2
		local profile = 0.55 + 0.45 * math.sin(index * 0.23 + 0.2) ^ 2
		value = 0.13 + pulse * profile * 0.87
	elseif state.motionStyle == "Cascade" then
		local cycle = (phase * 0.48 - index / 32) % 1
		local peak = math.max(0, 1 - math.abs(cycle - 0.5) * 3.3)
		value = 0.12 + peak * 0.88
	else
		local a = math.sin(phase * 2.1 - index * 0.34)
		local b = math.sin(phase * 1.15 + index * 0.19)
		value = 0.16 + ((a * 0.67 + b * 0.33 + 1) / 2) * 0.84
	end

	return math.clamp(value * state.amplitude / 100, 0.035, 1)
end

connect(RunService.RenderStepped, function(deltaTime)
	-- В скрытом состоянии без внешнего HUD обновление не требуется.
	if not windowVisible and not state.enabled then
		return
	end

	-- На других вкладках скрытое превью также не тратит ресурсы.
	local previewVisible = windowVisible and currentTab == "Main"
	if not state.enabled and not previewVisible then
		return
	end

	if state.animated and not state.reduceMotion then
		phase += math.min(deltaTime, 0.1) * state.speed
	end

	accumulator += deltaTime
	if accumulator < FRAME_INTERVAL then
		return
	end
	accumulator = accumulator % FRAME_INTERVAL

	local accent = PALETTES[state.palette] or C.Accent
	local intensity = state.intensity / 100
	local paused = not state.animated or state.reduceMotion

	local values = {}
	local sum = 0

	for index = 1, 26 do
		local value = signalValue(index)
		values[index] = value
		sum += value
	end

	local displayValue = math.floor(sum / 26 * 100 + 0.5)

	for _, visualizer in ipairs(visualizers) do
		local visible = visualizer.IsPreview and previewVisible
			or not visualizer.IsPreview and state.enabled

		if visible then
			visualizer.Number.Text = string.format("%02d", displayValue)
			visualizer.MotionLabel.Text = paused and "PAUSED" or string.upper(state.motionStyle)
			visualizer.Mode.Text = visualizer.IsPreview and "PREVIEW" or (paused and "HOLD" or "LIVE")
			visualizer.Dot.BackgroundTransparency = paused and 0.50 or 0.08

			for index, bar in ipairs(visualizer.Bars) do
				local value = values[index]

				bar.Size = UDim2.new(1 / 26, -3, value, 0)
				bar.BackgroundColor3 = C.SurfaceRaised:Lerp(
					accent,
					math.clamp((0.40 + value * 0.60) * intensity, 0, 1)
				)
				bar.BackgroundTransparency = 0.06 + (1 - intensity) * 0.26
			end
		end
	end
end)

---------------------------------------------------------------------
-- 18. FINAL BINDINGS / CLEANUP / START
---------------------------------------------------------------------

-- Инициализация внешнего превью после создания всех visualizer-объектов.
updateVisualizerAppearance()

watch("reduceMotion", function(value)
	if value then
		-- Прекращаем уже запущенные переходы.
		for object, tween in pairs(runningTweens) do
			tween:Cancel()
			runningTweens[object] = nil
		end

		-- Восстанавливаем однозначное состояние основного окна.
		window.GroupTransparency = windowVisible and 0 or 1

		-- Завершаем положение страниц без остаточного смещения.
		for _, page in pairs(pages) do
			page.Position = UDim2.fromOffset(0, 0)
		end
	end
end)

screen.Destroying:Connect(function()
	if not alive then
		return
	end

	alive = false
	tooltipToken += 1
	visibilityToken += 1
	resetToken += 1

	activeDrag = nil
	capturingKey = false

	if cameraViewportConnection then
		cameraViewportConnection:Disconnect()
		cameraViewportConnection = nil
	end

	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)

	for object, tween in pairs(runningTweens) do
		tween:Cancel()
		runningTweens[object] = nil
	end

	table.clear(observers)
	table.clear(visualizers)
	table.clear(toasts)
end)

bindCamera()
selectTab("Main")
setWindowVisible(true)

task.delay(0.65, function()
	if alive then
		notify(
			"Добро пожаловать в VELORA",
			"Перетаскивайте окно за заголовок. Начните с Signal HUD."
		)
	end
end)
