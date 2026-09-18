local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Mouse = LP:GetMouse()

local CurrentTheme = {
    Bg = Color3.fromRGB(20, 20, 23),
    Sidebar = Color3.fromRGB(15, 15, 18),
    Element = Color3.fromRGB(25, 25, 28),
    ElementHover = Color3.fromRGB(35, 35, 40),
    Text = Color3.fromRGB(255, 255, 255),
    Subtext = Color3.fromRGB(160, 160, 170),
    Accent = Color3.fromRGB(0, 180, 255),
    Border = Color3.fromRGB(40, 40, 45)
}

local Themes = {
    ["Default"] = {Bg=Color3.fromRGB(20,20,23), Sidebar=Color3.fromRGB(15,15,18), Element=Color3.fromRGB(25,25,28), ElementHover=Color3.fromRGB(35,35,40), Text=Color3.fromRGB(255,255,255), Subtext=Color3.fromRGB(160,160,170), Accent=Color3.fromRGB(0,180,255), Border=Color3.fromRGB(40,40,45)},
    ["Midnight"] = {Bg=Color3.fromRGB(10,15,30), Sidebar=Color3.fromRGB(5,10,20), Element=Color3.fromRGB(15,25,45), ElementHover=Color3.fromRGB(25,35,55), Text=Color3.fromRGB(255,255,255), Subtext=Color3.fromRGB(150,160,200), Accent=Color3.fromRGB(50,100,255), Border=Color3.fromRGB(30,40,60)},
    ["Crimson"] = {Bg=Color3.fromRGB(30,10,10), Sidebar=Color3.fromRGB(20,5,5), Element=Color3.fromRGB(45,15,15), ElementHover=Color3.fromRGB(55,25,25), Text=Color3.fromRGB(255,255,255), Subtext=Color3.fromRGB(200,150,150), Accent=Color3.fromRGB(255,50,50), Border=Color3.fromRGB(60,30,30)},
    ["Forest"] = {Bg=Color3.fromRGB(10,30,15), Sidebar=Color3.fromRGB(5,20,10), Element=Color3.fromRGB(15,45,20), ElementHover=Color3.fromRGB(25,55,30), Text=Color3.fromRGB(255,255,255), Subtext=Color3.fromRGB(150,200,160), Accent=Color3.fromRGB(50,255,100), Border=Color3.fromRGB(30,60,40)},
    ["Amethyst"] = {Bg=Color3.fromRGB(30,10,35), Sidebar=Color3.fromRGB(20,5,25), Element=Color3.fromRGB(45,15,50), ElementHover=Color3.fromRGB(55,25,60), Text=Color3.fromRGB(255,255,255), Subtext=Color3.fromRGB(200,150,210), Accent=Color3.fromRGB(200,100,255), Border=Color3.fromRGB(60,30,65)},
    ["Onyx"] = {Bg=Color3.fromRGB(2,2,2), Sidebar=Color3.fromRGB(0,0,0), Element=Color3.fromRGB(10,10,10), ElementHover=Color3.fromRGB(20,20,20), Text=Color3.fromRGB(255,255,255), Subtext=Color3.fromRGB(130,130,130), Accent=Color3.fromRGB(90,90,90), Border=Color3.fromRGB(25,25,25)},
    ["Candy"] = {Bg=Color3.fromRGB(178,213,229), Sidebar=Color3.fromRGB(150,185,210), Element=Color3.fromRGB(200,225,240), ElementHover=Color3.fromRGB(220,235,250), Text=Color3.fromRGB(30,30,30), Subtext=Color3.fromRGB(70,70,70), Accent=Color3.fromRGB(0,180,255), Border=Color3.fromRGB(140,170,190)}
}

local UI_ElementsToColor = {}
local UI_Strokes = {}
local accentElements = {}
local connections = {}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IshaqClient_Premium"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = CurrentTheme.Bg
MainFrame.BorderSizePixel = 0
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0.6, 0, 0.6, 0)
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local SizeConstraint = Instance.new("UISizeConstraint", MainFrame)
SizeConstraint.MaxSize = Vector2.new(550, 380)
SizeConstraint.MinSize = Vector2.new(300, 250)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = CurrentTheme.Border
MainStroke.Thickness = 1
table.insert(UI_Strokes, MainStroke)

local Sidebar = Instance.new("Frame")
Sidebar.Parent = MainFrame
Sidebar.BackgroundColor3 = CurrentTheme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Size = UDim2.new(0, 150, 1, 0)
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local SideFix = Instance.new("Frame", Sidebar)
SideFix.BackgroundColor3 = CurrentTheme.Sidebar
SideFix.BorderSizePixel = 0
SideFix.Position = UDim2.new(1, -10, 0, 0)
SideFix.Size = UDim2.new(0, 10, 1, 0)

local Title = Instance.new("TextLabel")
Title.Parent = Sidebar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 20, 0, 20)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.RichText = true
Title.Text = "Ishaq<font color='rgb(0, 180, 255)'>Client</font>"
Title.TextColor3 = CurrentTheme.Text
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
table.insert(accentElements, Title)

local TabList = Instance.new("ScrollingFrame")
TabList.Parent = Sidebar
TabList.BackgroundTransparency = 1
TabList.Position = UDim2.new(0, 10, 0, 70)
TabList.Size = UDim2.new(1, -20, 1, -120)
TabList.ScrollBarThickness = 2
TabList.ScrollBarImageColor3 = CurrentTheme.Accent
TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
table.insert(accentElements, TabList)

local TabLayout = Instance.new("UIListLayout", TabList)
TabLayout.Padding = UDim.new(0, 6)
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Top 

local TopBar = Instance.new("Frame")
TopBar.Parent = MainFrame
TopBar.BackgroundTransparency = 1
TopBar.Position = UDim2.new(0, 150, 0, 0)
TopBar.Size = UDim2.new(1, -150, 0, 40)

local BottomDragBar = Instance.new("Frame")
BottomDragBar.Name = "BottomDragBar"
BottomDragBar.Parent = MainFrame
BottomDragBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BottomDragBar.BackgroundTransparency = 0.93
BottomDragBar.BorderSizePixel = 0
BottomDragBar.Position = UDim2.new(0, 0, 1, -8)
BottomDragBar.Size = UDim2.new(1, 0, 0, 8)
BottomDragBar.ZIndex = 10

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TopBar
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
CloseBtn.BackgroundColor3 = CurrentTheme.Element
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = CurrentTheme.Subtext
CloseBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1, 0)
table.insert(UI_ElementsToColor, CloseBtn)

local ContentArea = Instance.new("Frame")
ContentArea.Parent = MainFrame
ContentArea.BackgroundTransparency = 1
ContentArea.Position = UDim2.new(0, 150, 0, 40)
ContentArea.Size = UDim2.new(1, -150, 1, -48)

local ToggleMenuGui = Instance.new("ScreenGui")
ToggleMenuGui.Name = "IshaqClient_ToggleMenu"
ToggleMenuGui.Parent = game.CoreGui
ToggleMenuGui.ResetOnSpawn = false

local ToggleButton = Instance.new("TextButton")
ToggleButton.Parent = ToggleMenuGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
ToggleButton.Position = UDim2.new(0, 20, 0.5, -20)
ToggleButton.Size = UDim2.new(0, 40, 0, 40)
ToggleButton.Text = "I"
ToggleButton.TextColor3 = Color3.fromRGB(0, 180, 255)
ToggleButton.TextSize = 18
ToggleButton.Font = Enum.Font.GothamBold
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 8)
local ToggleStroke = Instance.new("UIStroke", ToggleButton)
ToggleStroke.Color = Color3.fromRGB(40, 40, 45)
ToggleStroke.Thickness = 1

local tDragging, tDragInput, tDragStart, tStartPos
ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        tDragging = true; tDragStart = input.Position; tStartPos = ToggleButton.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then tDragging = false end end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and tDragging then
        local delta = input.Position - tDragStart
        ToggleButton.Position = UDim2.new(tStartPos.X.Scale, tStartPos.X.Offset + delta.X, tStartPos.Y.Scale, tStartPos.Y.Offset + delta.Y)
    end
end)
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

local dragging, dragInput, dragStart, startPos
local function setupDrag(guiElement)
    guiElement.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
end

setupDrag(TopBar)
setupDrag(BottomDragBar)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local function updateAccentColor(newColor)
    CurrentTheme.Accent = newColor
    ToggleButton.TextColor3 = newColor
    for _, item in ipairs(accentElements) do
        if item and item.Parent then
            if item:IsA("TextLabel") and item == Title then
                item.Text = "Ishaq<font color='rgb("..math.floor(newColor.R*255)..","..math.floor(newColor.G*255)..","..math.floor(newColor.B*255)..")'>Client</font>"
            elseif item:IsA("ScrollingFrame") then
                item.ScrollBarImageColor3 = newColor
            elseif item:IsA("Frame") then
                item.BackgroundColor3 = newColor
            end
        end
    end
end

local function createTab(name, parentContainer)
    local targetParent = parentContainer or TabList
    local TabBtn = Instance.new("TextButton")
    TabBtn.Parent = targetParent
    TabBtn.Size = UDim2.new(1, 0, 0, 35)
    TabBtn.BackgroundColor3 = CurrentTheme.Element
    TabBtn.BackgroundTransparency = 1
    TabBtn.Text = "  " .. name
    TabBtn.TextColor3 = CurrentTheme.Subtext
    TabBtn.TextSize = 13
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    TabBtn.AutoButtonColor = false
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)
    table.insert(UI_ElementsToColor, TabBtn)

    local Ind = Instance.new("Frame", TabBtn)
    Ind.BackgroundColor3 = CurrentTheme.Accent
    Ind.Size = UDim2.new(0, 3, 0, 15)
    Ind.Position = UDim2.new(0, 0, 0.5, -7.5)
    Ind.BackgroundTransparency = 1
    Instance.new("UICorner", Ind).CornerRadius = UDim.new(1, 0)
    table.insert(accentElements, Ind)

    TabBtn.MouseEnter:Connect(function() if not TabBtn:GetAttribute("Active") then TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play() end end)
    TabBtn.MouseLeave:Connect(function() if not TabBtn:GetAttribute("Active") then TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play() end end)

    local Page = Instance.new("ScrollingFrame")
    Page.Parent = ContentArea
    Page.BackgroundTransparency = 1
    Page.Size = UDim2.new(1, -20, 1, -10)
    Page.Position = UDim2.new(0, 10, 0, 5)
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = CurrentTheme.Accent
    Page.Visible = false
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    table.insert(accentElements, Page)

    local Layout = Instance.new("UIListLayout", Page)
    Layout.Padding = UDim.new(0, 8)
    Layout.VerticalAlignment = Enum.VerticalAlignment.Top 
    Layout.SortOrder = Enum.SortOrder.LayoutOrder

    local Pad = Instance.new("UIPadding", Page)
    Pad.PaddingLeft = UDim.new(0, 5); Pad.PaddingRight = UDim.new(0, 5); Pad.PaddingTop = UDim.new(0, 5); Pad.PaddingBottom = UDim.new(0, 5)

    return TabBtn, Page, Ind
end

local function switchTab(btn, page, ind)
    for _, c in ipairs(TabList:GetChildren()) do
        if c:IsA("TextButton") then
            c:SetAttribute("Active", false); c.TextColor3 = CurrentTheme.Subtext
            local i = c:FindFirstChild("Frame"); if i then i.BackgroundTransparency = 1 end
            TweenService:Create(c, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        end
    end
    
    local settingsBtn = Sidebar:FindFirstChild("SettingsTabBtn")
    if settingsBtn then
        settingsBtn:SetAttribute("Active", false); settingsBtn.TextColor3 = CurrentTheme.Subtext
        local i = settingsBtn:FindFirstChild("Frame"); if i then i.BackgroundTransparency = 1 end
        TweenService:Create(settingsBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    end

    for _, c in ipairs(ContentArea:GetChildren()) do
        if c:IsA("ScrollingFrame") then c.Visible = false end
    end
    
    btn:SetAttribute("Active", true)
    btn.TextColor3 = CurrentTheme.Text
    if ind then ind.BackgroundTransparency = 0 end
    page.Visible = true
end

local function createToggle(page, text, default, callback)
    local state = default
    local Frame = Instance.new("Frame", page)
    Frame.Size = UDim2.new(1, 0, 0, 40)
    Frame.BackgroundColor3 = CurrentTheme.Element
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
    local Stroke = Instance.new("UIStroke", Frame)
    Stroke.Color = CurrentTheme.Border; Stroke.Thickness = 1
    table.insert(UI_Strokes, Stroke)
    table.insert(UI_ElementsToColor, Frame)

    local Label = Instance.new("TextLabel", Frame)
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Text = text; Label.TextColor3 = CurrentTheme.Text; Label.TextSize = 14
    Label.Font = Enum.Font.GothamMedium; Label.TextXAlignment = Enum.TextXAlignment.Left

    local TBtn = Instance.new("TextButton", Frame)
    TBtn.Size = UDim2.new(0, 40, 0, 20)
    TBtn.Position = UDim2.new(1, -50, 0.5, -10)
    TBtn.BackgroundColor3 = state and CurrentTheme.Accent or Color3.fromRGB(40, 40, 45)
    TBtn.Text = ""
    Instance.new("UICorner", TBtn).CornerRadius = UDim.new(1, 0)
    if state then table.insert(accentElements, TBtn) end

    local Circle = Instance.new("Frame", TBtn)
    Circle.Size = UDim2.new(0, 16, 0, 16)
    Circle.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

    TBtn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(TBtn, TweenInfo.new(0.2), {BackgroundColor3 = state and CurrentTheme.Accent or Color3.fromRGB(40, 40, 45)}):Play()
        TweenService:Create(Circle, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
        callback(state)
    end)
end

local function createButton(page, text, callback)
    local Btn = Instance.new("TextButton", page)
    Btn.Size = UDim2.new(1, 0, 0, 40)
    Btn.BackgroundColor3 = CurrentTheme.Element
    Btn.Text = text; Btn.TextColor3 = CurrentTheme.Text; Btn.TextSize = 14
    Btn.Font = Enum.Font.GothamMedium; Btn.AutoButtonColor = false
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    local Stroke = Instance.new("UIStroke", Btn)
    Stroke.Color = CurrentTheme.Border; Stroke.Thickness = 1
    table.insert(UI_Strokes, Stroke)
    table.insert(UI_ElementsToColor, Btn)
    
    Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = CurrentTheme.ElementHover}):Play() end)
    Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = CurrentTheme.Element}):Play() end)
    Btn.MouseButton1Click:Connect(callback)
end

local function createSlider(page, text, min, max, default, callback)
    local Frame = Instance.new("Frame", page)
    Frame.Size = UDim2.new(1, 0, 0, 55)
    Frame.BackgroundColor3 = CurrentTheme.Element
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
    local Stroke = Instance.new("UIStroke", Frame)
    Stroke.Color = CurrentTheme.Border; Stroke.Thickness = 1
    table.insert(UI_Strokes, Stroke)
    table.insert(UI_ElementsToColor, Frame)

    local Label = Instance.new("TextLabel", Frame)
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 15, 0, 8)
    Label.Size = UDim2.new(1, -100, 0, 20)
    Label.Text = text .. ":"
    Label.TextColor3 = CurrentTheme.Text; Label.TextSize = 14
    Label.Font = Enum.Font.GothamMedium; Label.TextXAlignment = Enum.TextXAlignment.Left

    local ValueBox = Instance.new("TextBox", Frame)
    ValueBox.BackgroundTransparency = 0.8
    ValueBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    ValueBox.Position = UDim2.new(1, -75, 0, 8)
    ValueBox.Size = UDim2.new(0, 60, 0, 22)
    ValueBox.Text = tostring(default)
    ValueBox.TextColor3 = CurrentTheme.Text
    ValueBox.TextSize = 13
    ValueBox.Font = Enum.Font.GothamBold
    Instance.new("UICorner", ValueBox).CornerRadius = UDim.new(0, 4)

    local SliderBar = Instance.new("Frame", Frame)
    SliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    SliderBar.Position = UDim2.new(0, 15, 0, 36)
    SliderBar.Size = UDim2.new(1, -30, 0, 6)
    Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame", SliderBar)
    Fill.BackgroundColor3 = CurrentTheme.Accent
    Fill.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    table.insert(accentElements, Fill)

    local Knob = Instance.new("TextButton", Fill)
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.Position = UDim2.new(1, 0, 0.5, 0)
    Knob.Size = UDim2.new(0, 12, 0, 12)
    Knob.Text = ""
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local function updateValue(val)
        val = math.clamp(val, min, max)
        Fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
        ValueBox.Text = tostring(val)
        callback(val)
    end

    ValueBox.FocusLost:Connect(function()
        local num = tonumber(ValueBox.Text)
        if num then
            updateValue(math.floor(num))
        else
            ValueBox.Text = tostring(min)
            updateValue(min)
        end
    end)

    local draggingSlider = false
    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * pos)
            updateValue(val)
        end
    end)
end

local function createCategory(page, name, order)
    local Header = Instance.new("TextButton")
    Header.Parent = page
    Header.Size = UDim2.new(1, 0, 0, 35)
    Header.BackgroundColor3 = CurrentTheme.Element
    Header.Text = "  " .. name
    Header.TextColor3 = CurrentTheme.Text
    Header.TextSize = 14
    Header.Font = Enum.Font.GothamBold
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.AutoButtonColor = false
    Header.LayoutOrder = order
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)
    local Stroke = Instance.new("UIStroke", Header)
    Stroke.Color = CurrentTheme.Border; Stroke.Thickness = 1
    table.insert(UI_Strokes, Stroke)
    table.insert(UI_ElementsToColor, Header)

    local Arrow = Instance.new("TextLabel", Header)
    Arrow.BackgroundTransparency = 1
    Arrow.Position = UDim2.new(1, -25, 0, 0)
    Arrow.Size = UDim2.new(0, 20, 1, 0)
    Arrow.Text = "▼"; Arrow.TextColor3 = CurrentTheme.Subtext; Arrow.TextSize = 12
    Arrow.Font = Enum.Font.GothamBold

    local Container = Instance.new("Frame")
    Container.Parent = page
    Container.BackgroundTransparency = 1
    Container.Size = UDim2.new(1, 0, 0, 0)
    Container.AutomaticSize = Enum.AutomaticSize.Y
    Container.Visible = false
    Container.LayoutOrder = order + 1
    local CLayout = Instance.new("UIListLayout", Container)
    CLayout.Padding = UDim.new(0, 6)
    CLayout.VerticalAlignment = Enum.VerticalAlignment.Top

    local isOpen = false
    Header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        Container.Visible = isOpen
        TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = isOpen and 180 or 0}):Play()
    end)
    return Container
end

local BtnMain, PageMain, IndMain = createTab("MAIN")
local BtnPlayer, PagePlayer, IndPlayer = createTab("PLAYER")
local BtnVis, PageVis, IndVis = createTab("VISUAL")
local BtnTp, PageTp, IndTp = createTab("TELEPORT")
local BtnFun, PageFun, IndFun = createTab("FUN & TROLL")

local BtnSet, PageSet, IndSet = createTab("SETTINGS", Sidebar)
BtnSet.Name = "SettingsTabBtn"
BtnSet.Position = UDim2.new(0, 10, 1, -45)
BtnSet.Size = UDim2.new(1, -20, 0, 35)

BtnMain.MouseButton1Click:Connect(function() switchTab(BtnMain, PageMain, IndMain) end)
BtnPlayer.MouseButton1Click:Connect(function() switchTab(BtnPlayer, PagePlayer, IndPlayer) end)
BtnVis.MouseButton1Click:Connect(function() switchTab(BtnVis, PageVis, IndVis) end)
BtnTp.MouseButton1Click:Connect(function() switchTab(BtnTp, PageTp, IndTp) end)
BtnFun.MouseButton1Click:Connect(function() switchTab(BtnFun, PageFun, IndFun) end)
BtnSet.MouseButton1Click:Connect(function() switchTab(BtnSet, PageSet, IndSet) end)

-- MAIN Tab Features
local antiFlingEnabled = false
createToggle(PageMain, "Disable Anti Fling System", false, function(v)
    antiFlingEnabled = v
    if v then
        RunService.Heartbeat:Connect(function()
            if not antiFlingEnabled then return end
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                local vel = hrp.Velocity
                local horiz = vel.X*vel.X + vel.Z*vel.Z
                if horiz > (hum.WalkSpeed*1.3)*(hum.WalkSpeed*1.3) then
                    hrp.Velocity = Vector3.new(0, vel.Y, 0)
                    hrp.RotVelocity = Vector3.new()
                end
            end
        end)
    end
end)

createButton(PageMain, "Collect All Credits", function()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and workspace:FindFirstChild("GameObjects") then
        for _, obj in workspace.GameObjects:GetDescendants() do
            if obj.Name == "Credit" or obj:FindFirstChild("TouchInterest") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    firetouchinterest(hrp, part, 0) task.wait()
                    firetouchinterest(hrp, part, 1)
                end
            end
        end
    end
end)

createButton(PageMain, "TeleKill (IT)", function()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, plr in Players:GetPlayers() do
            if plr ~= LP and plr.Character and plr:FindFirstChild("PlayerData") and plr.PlayerData:FindFirstChild("InGame") and plr.PlayerData.InGame.Value then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    hrp.CFrame = root.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.1)
                end
            end
        end
    end
end)

-- PLAYER Tab Features
local noclipConn
createToggle(PagePlayer, "Noclip", false, function(state)
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LP.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect() end
    end
end)

local infJumpConn
createToggle(PagePlayer, "Inf Jump", false, function(state)
    if state then
        infJumpConn = UIS.JumpRequest:Connect(function()
            local char = LP.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if infJumpConn then infJumpConn:Disconnect() end
    end
end)

local speedEnabled = false
local speedVal = 16
createToggle(PagePlayer, "WalkSpeed", false, function(state)
    speedEnabled = state
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = state and speedVal or 16 end
end)
createSlider(PagePlayer, "WalkSpeed Value", 16, 250, 16, function(v)
    speedVal = v
    if speedEnabled then
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = speedVal end
    end
end)

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        if speedEnabled then hum.WalkSpeed = speedVal end
        if jumpEnabled then hum.JumpPower = jumpVal end
    end
end)

local jumpEnabled = false
local jumpVal = 50
createToggle(PagePlayer, "Jump", false, function(state)
    jumpEnabled = state
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = state and jumpVal or 50 end
end)
createSlider(PagePlayer, "Jump Value", 50, 300, 50, function(v)
    jumpVal = v
    if jumpEnabled then
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = jumpVal end
    end
end)

local flyEnabled = false
local flySpeed = 50
local flyConn
createToggle(PagePlayer, "Fly", false, function(state)
    flyEnabled = state
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if state and hrp then
        local bv = Instance.new("BodyVelocity", hrp)
        local bg = Instance.new("BodyGyro", hrp)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyConn = RunService.RenderStepped:Connect(function()
            if not flyEnabled then bv:Destroy(); bg:Destroy(); if flyConn then flyConn:Disconnect() end return end
            local cam = workspace.CurrentCamera
            local dir = Vector3.new()
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CoordinateFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CoordinateFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CoordinateFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CoordinateFrame.RightVector end
            bv.Velocity = dir * flySpeed
            bg.CFrame = cam.CFrame
        end)
    else
        flyEnabled = false
    end
end)
createSlider(PagePlayer, "Fly Speed", 16, 200, 50, function(v) flySpeed = v end)

-- TELEPORT Tab Features
createButton(PageTp, "TP Map", function()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local itSpawn = workspace:FindFirstChild("ItSpawn", true)
    if itSpawn then
        local targetPart = itSpawn:IsA("BasePart") and itSpawn or itSpawn:FindFirstChildWhichIsA("BasePart")
        if targetPart then
            hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
        end
    end
end)

createButton(PageTp, "TP Lobby", function()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local lobby = workspace:FindFirstChild("Lobby", true) or workspace:FindFirstChild("WaitingRoom", true) or workspace:FindFirstChild("SpawnLocation", true)
    if lobby then
        local targetPart = lobby:IsA("BasePart") and lobby or lobby:FindFirstChildWhichIsA("BasePart")
        if targetPart then
            hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
        end
    end
end)

createButton(PageTp, "Tp Random Teleporters", function()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local teleporters = {}
    for _, obj in workspace:GetDescendants() do
        if obj.Name == "Teleporter" then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                table.insert(teleporters, part)
            end
        end
    end
    
    if #teleporters > 0 then
        local randomTp = teleporters[math.random(1, #teleporters)]
        hrp.CFrame = randomTp.CFrame + Vector3.new(0, 3, 0)
    end
end)

local TpPlayerCat = createCategory(PageTp, "TP to Player", 10)

local function updateTpPlayerList()
    for _, child in ipairs(TpPlayerCat:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local btn = Instance.new("TextButton", TpPlayerCat)
            btn.Size = UDim2.new(1, 0, 0, 35)
            btn.BackgroundColor3 = CurrentTheme.Element
            btn.Text = "  " .. plr.Name
            btn.TextColor3 = CurrentTheme.Text
            btn.TextSize = 13
            btn.Font = Enum.Font.GothamMedium
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.AutoButtonColor = false
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
            local stroke = Instance.new("UIStroke", btn)
            stroke.Color = CurrentTheme.Border
            stroke.Thickness = 1
            
            btn.MouseButton1Click:Connect(function()
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    hrp.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                end
            end)
        end
    end
end

Players.PlayerAdded:Connect(updateTpPlayerList)
Players.PlayerRemoving:Connect(updateTpPlayerList)
updateTpPlayerList()

task.spawn(function()
    while true do
        task.wait(10)
        pcall(updateTpPlayerList)
    end
end)

-- VISUAL Tab Features
local ESP_IT_ENABLED = false
local ESP_IT_FOLDER = Instance.new("Folder")
ESP_IT_FOLDER.Name = "ESP_IT"
ESP_IT_FOLDER.Parent = workspace.CurrentCamera

local function createITHighlight(char, name)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = char
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineTransparency = 0
    highlight.Parent = ESP_IT_FOLDER

    local head = char:FindFirstChild("Head")
    if head then
        local bill = Instance.new("BillboardGui")
        bill.Size = UDim2.new(0, 100, 0, 30)
        bill.AlwaysOnTop = true
        bill.Adornee = head
        bill.Parent = ESP_IT_FOLDER

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,0,1,0)
        label.BackgroundTransparency = 1
        label.Text = name.." [IT]"
        label.TextColor3 = Color3.fromRGB(255, 0, 0)
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.new(0,0,0)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.Parent = bill
    end
end

createToggle(PageVis, "ESP IT", false, function(state)
    ESP_IT_ENABLED = state
end)

local ESP_SEEK_ENABLED = false
local ESP_SEEK_FOLDER = Instance.new("Folder")
ESP_SEEK_FOLDER.Name = "ESP_SEEK"
ESP_SEEK_FOLDER.Parent = workspace.CurrentCamera

local function createSeekHighlight(char, name)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = char
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineTransparency = 0
    highlight.Parent = ESP_SEEK_FOLDER

    local head = char:FindFirstChild("Head")
    if head then
        local bill = Instance.new("BillboardGui")
        bill.Size = UDim2.new(0, 100, 0, 30)
        bill.AlwaysOnTop = true
        bill.Adornee = head
        bill.Parent = ESP_SEEK_FOLDER

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,0,1,0)
        label.BackgroundTransparency = 1
        label.Text = name.." [SEEK]"
        label.TextColor3 = Color3.fromRGB(0, 255, 0)
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.new(0,0,0)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.Parent = bill
    end
end

createToggle(PageVis, "ESP SEEK", false, function(state)
    ESP_SEEK_ENABLED = state
end)

local ESP_CREDITS_ENABLED = false
local ESP_CREDITS_FOLDER = Instance.new("Folder")
ESP_CREDITS_FOLDER.Name = "ESP_Credits"
ESP_CREDITS_FOLDER.Parent = workspace.CurrentCamera

createToggle(PageVis, "ESP Credits", false, function(state)
    ESP_CREDITS_ENABLED = state
end)

local FullbrightEnabled = false
createToggle(PageVis, "Fullbright", false, function(state)
    FullbrightEnabled = state
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end
end)

RunService.RenderStepped:Connect(function()
    if ESP_IT_ENABLED then
        ESP_IT_FOLDER:ClearAllChildren()
        for _, plr in Players:GetPlayers() do
            if plr ~= LP and plr.Character then
                local isIt = false
                pcall(function() isIt = plr.PlayerData.It.Value end)
                if isIt then
                    createITHighlight(plr.Character, plr.DisplayName)
                end
            end
        end
    else
        ESP_IT_FOLDER:ClearAllChildren()
    end

    if ESP_SEEK_ENABLED then
        ESP_SEEK_FOLDER:ClearAllChildren()
        for _, plr in Players:GetPlayers() do
            if plr ~= LP and plr.Character then
                local isIt = false
                pcall(function() isIt = plr.PlayerData.It.Value end)
                if not isIt then
                    createSeekHighlight(plr.Character, plr.DisplayName)
                end
            end
        end
    else
        ESP_SEEK_FOLDER:ClearAllChildren()
    end

    if ESP_CREDITS_ENABLED and workspace:FindFirstChild("GameObjects") then
        ESP_CREDITS_FOLDER:ClearAllChildren()
        for _, obj in workspace.GameObjects:GetDescendants() do
            if obj.Name == "Credit" or obj:FindFirstChild("TouchInterest") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    local sphere = Instance.new("CylinderHandleAdornment")
                    sphere.Radius = math.max(part.Size.X, part.Size.Z) * 0.75
                    sphere.Height = 0.1
                    sphere.Color3 = Color3.fromRGB(255, 215, 0)
                    sphere.Transparency = 0.4
                    sphere.AlwaysOnTop = true
                    sphere.ZIndex = 10
                    sphere.Adornee = part
                    sphere.CFrame = CFrame.new(Vector3.new(0, 0, 0)) * CFrame.Angles(math.rad(90), 0, 0)
                    sphere.Parent = ESP_CREDITS_FOLDER

                    local bill = Instance.new("BillboardGui")
                    bill.Size = UDim2.new(0, 80, 0, 25)
                    bill.AlwaysOnTop = true
                    bill.Adornee = part
                    bill.Parent = ESP_CREDITS_FOLDER

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1,0,1,0)
                    label.BackgroundTransparency = 1
                    label.Text = "Credits"
                    label.TextColor3 = Color3.fromRGB(255, 215, 0)
                    label.TextStrokeTransparency = 0
                    label.TextStrokeColor3 = Color3.new(0,0,0)
                    label.Font = Enum.Font.GothamBold
                    label.TextSize = 13
                    label.Parent = bill
                end
            end
        end
    else
        ESP_CREDITS_FOLDER:ClearAllChildren()
    end
end)

-- FUN & TROLL Tab Features
createToggle(PageFun, "Ragdoll", false, function(state)
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if state then
            hum:ChangeState(Enum.HumanoidStateType.FallingDown)
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        else
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end)

-- Spinbot Feature
local spinbotEnabled = false
local spinbotSpeed = 35
createToggle(PageFun, "Spinbot", false, function(state)
    spinbotEnabled = state
end)
createSlider(PageFun, "Spin Speed", 10, 100, 35, function(v)
    spinbotSpeed = v
end)

RunService.RenderStepped:Connect(function()
    if spinbotEnabled then
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinbotSpeed), 0)
        end
    end
end)

-- Auto Taunt Feature (every 3 seconds)
local autoTauntEnabled = false
createToggle(PageFun, "Auto Taunt", false, function(state)
    autoTauntEnabled = state
end)

task.spawn(function()
    while true do
        task.wait(3)
        if autoTauntEnabled then
            pcall(function()
                local char = LP.Character
                if char then
                    for _, obj in pairs(char:GetDescendants()) do
                        if obj:IsA("RemoteEvent") and (string.lower(obj.Name):find("taunt") or string.lower(obj.Name):find("wave")) then
                            obj:FireServer()
                        end
                    end
                    if LP.Backpack then
                        for _, obj in pairs(LP.Backpack:GetDescendants()) do
                            if obj:IsA("RemoteEvent") and (string.lower(obj.Name):find("taunt") or string.lower(obj.Name):find("wave")) then
                                obj:FireServer()
                            end
                        end
                    end
                    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes", true) or game:GetService("ReplicatedStorage"):FindFirstChild("Events", true)
                    if remotes then
                        for _, obj in pairs(remotes:GetDescendants()) do
                            if obj:IsA("RemoteEvent") and (string.lower(obj.Name):find("taunt") or string.lower(obj.Name):find("wave")) then
                                obj:FireServer()
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Orbit Player Feature
local orbitEnabled = false
local orbitTargetName = ""
local orbitAngle = 0
local orbitRadius = 8
local orbitSpeed = 5

local OrbitCat = createCategory(PageFun, "Orbit Player", 10)

local function updateOrbitList()
    for _, child in ipairs(OrbitCat:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local btn = Instance.new("TextButton", OrbitCat)
            btn.Size = UDim2.new(1, 0, 0, 35)
            btn.BackgroundColor3 = (orbitTargetName == plr.Name and orbitEnabled) and CurrentTheme.Accent or CurrentTheme.Element
            btn.Text = "  " .. plr.Name .. ((orbitTargetName == plr.Name and orbitEnabled) and " [ORBITING]" or "")
            btn.TextColor3 = CurrentTheme.Text
            btn.TextSize = 13
            btn.Font = Enum.Font.GothamMedium
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.AutoButtonColor = false
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
            local stroke = Instance.new("UIStroke", btn)
            stroke.Color = CurrentTheme.Border
            stroke.Thickness = 1
            if (orbitTargetName == plr.Name and orbitEnabled) then table.insert(accentElements, btn) end
            
            btn.MouseButton1Click:Connect(function()
                if orbitTargetName == plr.Name and orbitEnabled then
                    orbitEnabled = false
                    orbitTargetName = ""
                else
                    orbitTargetName = plr.Name
                    orbitEnabled = true
                end
                updateOrbitList()
            end)
        end
    end
end

Players.PlayerAdded:Connect(updateOrbitList)
Players.PlayerRemoving:Connect(updateOrbitList)
updateOrbitList()

createSlider(PageFun, "Orbit Radius", 3, 25, 8, function(v) orbitRadius = v end)
createSlider(PageFun, "Orbit Speed", 1, 15, 5, function(v) orbitSpeed = v end)

RunService.RenderStepped:Connect(function(dt)
    if orbitEnabled and orbitTargetName ~= "" then
        local targetPlr = Players:FindFirstChild(orbitTargetName)
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart") and hrp then
            orbitAngle = orbitAngle + (orbitSpeed * dt)
            local targetHrp = targetPlr.Character.HumanoidRootPart
            local offset = Vector3.new(math.cos(orbitAngle) * orbitRadius, 3, math.sin(orbitAngle) * orbitRadius)
            hrp.CFrame = CFrame.new(targetHrp.Position + offset, targetHrp.Position)
        else
            orbitEnabled = false
        end
    end
end)

-- SETTINGS Tab Categories & Color Picker
local CatTheme = createCategory(PageSet, "Theme", 1)
local CatColor = createCategory(PageSet, "Accent Color Picker", 2)
local CatSys = createCategory(PageSet, "System", 3)

local function applyTheme(themeName)
    local t = Themes[themeName]
    if not t then return end
    CurrentTheme = t
    
    MainFrame.BackgroundColor3 = t.Bg
    Sidebar.BackgroundColor3 = t.Sidebar
    SideFix.BackgroundColor3 = t.Sidebar
    
    for _, element in ipairs(UI_ElementsToColor) do
        if element and element.Parent then
            element.BackgroundColor3 = t.Element
            if element:IsA("TextButton") or element:IsA("TextLabel") then
                element.TextColor3 = t.Text
            end
        end
    end
    
    for _, stroke in ipairs(UI_Strokes) do
        if stroke and stroke.Parent then
            stroke.Color = t.Border
        end
    end
    updateAccentColor(t.Accent)
end

createButton(CatTheme, "Default", function() applyTheme("Default") end)
createButton(CatTheme, "Midnight", function() applyTheme("Midnight") end)
createButton(CatTheme, "Crimson", function() applyTheme("Crimson") end)
createButton(CatTheme, "Forest", function() applyTheme("Forest") end)
createButton(CatTheme, "Amethyst", function() applyTheme("Amethyst") end)
createButton(CatTheme, "Onyx", function() applyTheme("Onyx") end)
createButton(CatTheme, "Candy", function() applyTheme("Candy") end)

-- Custom Accent Color Picker Sliders
local customR = math.floor(CurrentTheme.Accent.R * 255)
local customG = math.floor(CurrentTheme.Accent.G * 255)
local customB = math.floor(CurrentTheme.Accent.B * 255)

createSlider(CatColor, "Red", 0, 255, customR, function(v)
    customR = v
    updateAccentColor(Color3.fromRGB(customR, customG, customB))
end)

createSlider(CatColor, "Green", 0, 255, customG, function(v)
    customG = v
    updateAccentColor(Color3.fromRGB(customR, customG, customB))
end)

createSlider(CatColor, "Blue", 0, 255, customB, function(v)
    customB = v
    updateAccentColor(Color3.fromRGB(customR, customG, customB))
end)

-- Panic Button Feature with Draggable Roblox Logo Icon
local panicActive = false
local panicGui = Instance.new("ScreenGui")
panicGui.Name = "IshaqClient_PanicGui"
panicGui.Parent = game.CoreGui
panicGui.ResetOnSpawn = false
panicGui.Enabled = false

local panicBtn = Instance.new("ImageButton", panicGui)
panicBtn.Size = UDim2.new(0, 45, 0, 45)
panicBtn.Position = UDim2.new(0, 80, 0.5, -20)
panicBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
panicBtn.Image = "rbxassetid://6023426915"
Instance.new("UICorner", panicBtn).CornerRadius = UDim.new(1, 0)
local panicStroke = Instance.new("UIStroke", panicBtn)
panicStroke.Color = Color3.fromRGB(100, 100, 110)
panicStroke.Thickness = 1

local pDragging, pDragStart, pStartPos
panicBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        pDragging = true; pDragStart = input.Position; pStartPos = panicBtn.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then pDragging = false end end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and pDragging then
        local delta = input.Position - pDragStart
        panicBtn.Position = UDim2.new(pStartPos.X.Scale, pStartPos.X.Offset + delta.X, pStartPos.Y.Scale, pStartPos.Y.Offset + delta.Y)
    end
end)

local isPanicked = false
panicBtn.MouseButton1Click:Connect(function()
    isPanicked = not isPanicked
    if isPanicked then
        ScreenGui.Enabled = false
        ToggleMenuGui.Enabled = false
        ESP_IT_ENABLED = false
        ESP_SEEK_ENABLED = false
        ESP_CREDITS_ENABLED = false
        spinbotEnabled = false
        orbitEnabled = false
        autoTauntEnabled = false
    else
        ScreenGui.Enabled = true
        ToggleMenuGui.Enabled = true
    end
end)

createToggle(CatSys, "Panic Button", false, function(state)
    panicActive = state
    panicGui.Enabled = state
    if not state then
        isPanicked = false
        ScreenGui.Enabled = true
        ToggleMenuGui.Enabled = true
    end
end)

createButton(CatSys, "Kill Script", function()
    for _, c in pairs(connections) do if c then c:Disconnect() end end
    ScreenGui:Destroy()
    ToggleMenuGui:Destroy()
    panicGui:Destroy()
end)

switchTab(BtnMain, PageMain, IndMain)

CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = Color3.fromRGB(255, 85, 85) end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = CurrentTheme.Subtext end)
CloseBtn.MouseButton1Click:Connect(function() 
    ScreenGui:Destroy() 
    ToggleMenuGui:Destroy()
    panicGui:Destroy()
end)
