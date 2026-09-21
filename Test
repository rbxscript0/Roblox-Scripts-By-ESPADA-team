--[[
    ESPADAWARE | Mobile-first | One client script | Configuration v1
    No remote loaders or downloaded libraries.

    Compatibility, not promises:
    * Designed for an executor. GUI also uses ordinary Roblox Instances.
    * Persistent configuration needs readfile/writefile. No DataStore is used.
    * SilentAim: ONLY legacy weapons reading LocalPlayer:GetMouse().Hit,
      Target or UnitRay. Needs hookmetamethod/newcclosure/checkcaller.
      Does NOT redirect arbitrary raycasts, projectiles or server weapons.
    * TriggerBot: Tool:Activate() by default; optional virtual mouse input.
    * Server-authoritative movement, streaming and protected assets can limit
      the corresponding features. No anti-cheat bypass is included.
    * Use in your own experience or with the experience owner's permission.
    * Static-reviewed source, not tested inside your executor or your game.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then error("EspadaWare requires a client session") end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Mouse = LocalPlayer:GetMouse()

local ENV = _G
if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)
    if ok and type(result) == "table" then ENV = result end
end
local previous = ENV.__EspadaWareRuntime
if previous and type(previous.Unload) == "function" then pcall(previous.Unload) end

local API = {
    read = readfile, write = writefile, exists = isfile, clipboard = setclipboard,
    hook = hookmetamethod, closure = newcclosure, caller = checkcaller,
}
local FILE = "EspadaWare_config_v1.json"
local BACKUP = "EspadaWare_config_v1.backup.json"
local CAN_SAVE = type(API.write) == "function" and type(API.read) == "function"
local CAN_HOOK = type(API.hook) == "function" and type(API.closure) == "function"
    and type(API.caller) == "function"
local VirtualInput
pcall(function() VirtualInput = game:GetService("VirtualInputManager") end)

local Defaults = {
    Version = 1,
    UI = {Accent = "Violet", Transparency = 0.04, Animations = true,
        Open = true, ButtonX = 0.08, ButtonY = 0.45, Tab = "Main"},
    AimBot = {Enabled = false, FOV = 150, Smoothness = 14, Part = "Head",
        TeamCheck = true, WallCheck = true, MaxDistance = 1500, Mode = "Always"},
    SilentAim = {Enabled = false, Chance = 100},
    TriggerBot = {Enabled = false, Interval = 0.15, Method = "Tool", RequireTarget = true},
    Target = {UserId = 0, Sticky = true, ShowHUD = true, Spectate = false},
    ESP = {Enabled = false, Names = true, Health = true, Distance = true,
        ThroughWalls = true, TeamCheck = false, MaxDistance = 2000},
    Noclip = {Enabled = false},
    Speed = {Enabled = false, Value = 24},
    Jump = {Enabled = false, Power = 65, Height = 12},
    InfinityJump = {Enabled = false},
    Fly = {Enabled = false, Speed = 45, VerticalSpeed = 35},
    Fullbright = {Enabled = false, Brightness = 2, ClockTime = 14, NoFog = true},
    Skybox = {Enabled = false, Preset = "Nebula", Stars = 3000,
        Bk = "", Dn = "", Ft = "", Lf = "", Rt = "", Up = ""},
    Music = {Enabled = false, Id = "", Volume = 0.35, PlaybackSpeed = 1, Loop = true},
    FPS = {Enabled = true}, Ping = {Enabled = true},
    Crosshair = {Enabled = true, Size = 7, Gap = 4},
    FOVCircle = {Enabled = true},
    Camera = {Enabled = false, FOV = 80},
}
local function copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = copy(v) end
    return out
end
local function merge(base, source)
    for k, v in pairs(base) do
        local candidate = source[k]
        if type(v) == "table" and type(candidate) == "table" then merge(v, candidate)
        elseif type(candidate) == type(v) then
            if type(v) ~= "number" or (candidate == candidate and math.abs(candidate) < 1e12) then
                base[k] = candidate
            end
        end
    end
    return base
end
local Config = copy(Defaults)
local function get(path)
    local value = Config
    for key in string.gmatch(path, "[^.]+") do value = value[key] end
    return value
end
local function rawSet(path, value)
    local keys = string.split(path, ".")
    local parent = Config
    for i = 1, #keys - 1 do parent = parent[keys[i]] end
    parent[keys[#keys]] = value
end
local Ranges = {
    ["UI.Transparency"]={0,0.35}, ["UI.ButtonX"]={0,1}, ["UI.ButtonY"]={0,1},
    ["AimBot.FOV"]={30,450}, ["AimBot.Smoothness"]={1,30}, ["AimBot.MaxDistance"]={50,5000},
    ["SilentAim.Chance"]={0,100}, ["TriggerBot.Interval"]={0.05,2},
    ["ESP.MaxDistance"]={50,10000}, ["Speed.Value"]={1,150},
    ["Jump.Power"]={1,200}, ["Jump.Height"]={1,100},
    ["Fly.Speed"]={5,200}, ["Fly.VerticalSpeed"]={5,150},
    ["Fullbright.Brightness"]={0,5}, ["Fullbright.ClockTime"]={0,24},
    ["Skybox.Stars"]={0,10000}, ["Music.Volume"]={0,1},
    ["Music.PlaybackSpeed"]={0.25,2}, ["Crosshair.Size"]={2,20},
    ["Crosshair.Gap"]={0,20}, ["Camera.FOV"]={40,110},
}
local Enums = {
    ["UI.Accent"]={"Violet","Cyan","Crimson","Gold"},
    ["UI.Tab"]={"Main","Movement","Visuals","Settings"},
    ["AimBot.Part"]={"Head","HumanoidRootPart"},
    ["AimBot.Mode"]={"Always","WhileAiming"},
    ["TriggerBot.Method"]={"Tool","VirtualMouse"},
    ["Skybox.Preset"]={"Nebula","Classic","Custom"},
}
local function normalize()
    for path, range in pairs(Ranges) do rawSet(path, math.clamp(get(path), range[1], range[2])) end
    for path, options in pairs(Enums) do
        if not table.find(options, get(path)) then rawSet(path, options[1]) end
    end
    Config.Target.UserId = math.max(0, math.floor(Config.Target.UserId))
    Config.Version = 1
    if not CAN_HOOK then Config.SilentAim.Enabled = false end
    if not VirtualInput then Config.TriggerBot.Method = "Tool" end
end
local loadNotice
if CAN_SAVE then
    local ok, result = pcall(function() return HttpService:JSONDecode(API.read(FILE)) end)
    if ok and type(result) == "table" and (result.Version == nil or result.Version == 1) then
        merge(Config, result)
        loadNotice = "РљРѕРЅС„РёРіСѓСЂР°С†РёСЏ Р·Р°РіСЂСѓР¶РµРЅР°"
    else
        local bakOK, bak = pcall(function() return HttpService:JSONDecode(API.read(BACKUP)) end)
        if bakOK and type(bak) == "table" and bak.Version == 1 then
            merge(Config, bak)
            loadNotice = "Р—Р°РіСЂСѓР¶РµРЅР° СЂРµР·РµСЂРІРЅР°СЏ РєРѕРїРёСЏ РєРѕРЅС„РёРіСѓСЂР°С†РёРё"
        end
    end
end
normalize()

local State = {
    Alive = true, Dirty = false, ChangedAt = 0, Target = nil, Aiming = false,
    FlyUp = false, FlyDown = false, FPS = 0, Ping = nil, Connections = {},
    ESP = {}, Collisions = {}, Humanoid = nil, MovementOriginal = nil,
    FlyObjects = nil, LastTrigger = 0, Sheet = nil, Picker = nil,
    Errors = {}, AccentBindings = {}, Refreshers = {},
}
ENV.__EspadaWareRuntime = State
local function bind(signal, fn)
    local connection = signal:Connect(fn)
    table.insert(State.Connections, connection)
    return connection
end
local function ownedBind(owner, signal, fn)
    local connection=bind(signal,fn)
    owner.Destroying:Once(function() connection:Disconnect() end)
    return connection
end
local function characterParts(player)
    local character = player and player.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    return character, humanoid, root
end
local function new(class, props, parent)
    local object = Instance.new(class)
    for key, value in pairs(props or {}) do object[key] = value end
    object.Parent = parent
    return object
end
local function corner(object, radius)
    return new("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, object)
end
local function stroke(object, color, transparency, thickness)
    return new("UIStroke", {Color = color or Color3.fromRGB(72,77,102),
        Transparency = transparency or 0.5, Thickness = thickness or 1}, object)
end
local Palette = {
    Violet = Color3.fromRGB(161,125,255), Cyan = Color3.fromRGB(66,222,230),
    Crimson = Color3.fromRGB(255,99,135), Gold = Color3.fromRGB(255,199,99),
}
local TEXT = Color3.fromRGB(237,239,250)
local MUTED = Color3.fromRGB(145,153,176)
local PANEL = Color3.fromRGB(24,28,43)
local function accent() return Palette[Config.UI.Accent] or Palette.Violet end
local function accentBind(object, property)
    object[property] = accent()
    table.insert(State.AccentBindings, {object,property})
    return object
end
local function animate(object, properties, duration)
    if not object or not object.Parent then return end
    if Config.UI.Animations then
        TweenService:Create(object, TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out), properties):Play()
    else
        for key, value in pairs(properties) do object[key] = value end
    end
end
local Gui = new("ScreenGui", {Name = "EspadaWare", ResetOnSpawn = false,
    IgnoreGuiInset = true, DisplayOrder = 990, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, PlayerGui)
local hiddenParent
if type(gethui) == "function" then
    local ok, result = pcall(gethui)
    if ok then hiddenParent = result end
end
if hiddenParent then pcall(function() Gui.Parent = hiddenParent end) end

local function label(parent, text, size, color, props)
    local parameters = {BackgroundTransparency = 1, Text = text, TextSize = size or 14,
        TextColor3 = color or TEXT, Font = Enum.Font.Gotham, BorderSizePixel = 0,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center}
    for key, value in pairs(props or {}) do parameters[key] = value end
    return new("TextLabel", parameters, parent)
end
local function button(parent, text, props)
    local parameters = {Text = text or "", TextSize = 14, Font = Enum.Font.GothamMedium,
        TextColor3 = TEXT, BackgroundColor3 = PANEL, AutoButtonColor = false, BorderSizePixel = 0}
    for key, value in pairs(props or {}) do parameters[key] = value end
    local object = new("TextButton", parameters, parent)
    corner(object, 10)
    bind(object.MouseEnter, function() animate(object, {BackgroundColor3 = Color3.fromRGB(42,47,66)}) end)
    bind(object.MouseLeave, function() animate(object, {BackgroundColor3 = parameters.BackgroundColor3}) end)
    return object
end
local ToastArea = new("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5,0),
    Position = UDim2.new(0.5,0,0,16), Size = UDim2.new(0.9,0,0,180), ZIndex = 50}, Gui)
new("UIListLayout", {Padding = UDim.new(0,8), HorizontalAlignment = Enum.HorizontalAlignment.Center}, ToastArea)
new("UISizeConstraint", {MaxSize = Vector2.new(480,180)}, ToastArea)
local toastCount = 0
local function toast(message, bad)
    if not State.Alive then return end
    if toastCount >= 3 then
        for _, child in ipairs(ToastArea:GetChildren()) do
            if child:IsA("Frame") then child:Destroy(); toastCount = math.max(0,toastCount-1); break end
        end
    end
    local box = new("Frame", {Size = UDim2.new(1,0,0,54), BackgroundColor3 = Color3.fromRGB(25,29,44),
        BackgroundTransparency = 0.04, BorderSizePixel = 0, ZIndex = 51}, ToastArea)
    corner(box,14)
    stroke(box, bad and Color3.fromRGB(255,110,130) or accent(), 0.35)
    label(box, message, 12, TEXT, {Position = UDim2.fromOffset(14,5), Size = UDim2.new(1,-28,1,-10),
        TextWrapped = true, ZIndex = 52})
    toastCount = toastCount + 1
    task.delay(4, function()
        if box.Parent then box:Destroy(); toastCount = math.max(0,toastCount-1) end
    end)
end
local function rateError(key, message)
    local time = os.clock()
    if not State.Errors[key] or time-State.Errors[key] > 8 then
        State.Errors[key] = time
        toast(message, true)
    end
end
local function saveConfig(quiet)
    if not CAN_SAVE then
        if not quiet then toast("РќРµС‚ readfile/writefile: РЅР°СЃС‚СЂРѕР№РєРё С…СЂР°РЅСЏС‚СЃСЏ С‚РѕР»СЊРєРѕ РґРѕ Р·Р°РІРµСЂС€РµРЅРёСЏ СЃРєСЂРёРїС‚Р°", true) end
        return false
    end
    local ok, err = pcall(function()
        local encoded = HttpService:JSONEncode(Config)
        local oldOK, oldText = pcall(API.read, FILE)
        if oldOK then
            local valid, old = pcall(function() return HttpService:JSONDecode(oldText) end)
            if valid and type(old) == "table" and old.Version == 1 then API.write(BACKUP, oldText) end
        end
        API.write(FILE, encoded)
    end)
    if ok then
        State.Dirty = false
        if not quiet then toast("РљРѕРЅС„РёРіСѓСЂР°С†РёСЏ СЃРѕС…СЂР°РЅРµРЅР°") end
    else
        rateError("save", "РќРµ СѓРґР°Р»РѕСЃСЊ Р·Р°РїРёСЃР°С‚СЊ РєРѕРЅС„РёРіСѓСЂР°С†РёСЋ. РџСЂРѕРІРµСЂСЊ С„Р°Р№Р»РѕРІС‹Рµ API executor")
        warn("[EspadaWare] Save failed:", err)
    end
    return ok
end
local applyConfig, refreshUI, selectTab, openSettings, closeSettings, rebuildPage, updateTargetOptions
local function set(path, value)
    if path == "SilentAim.Enabled" and value and (not CAN_HOOK or not State.HookReady) then
        toast("SilentAim РЅРµРґРѕСЃС‚СѓРїРµРЅ: РЅРµС‚ СЂР°Р±РѕС‡РµРіРѕ hookmetamethod/newcclosure/checkcaller", true)
        return
    end
    rawSet(path, value)
    normalize()
    State.Dirty = true
    State.ChangedAt = os.clock()
    if applyConfig then applyConfig(path) end
    if refreshUI then refreshUI() end
end

-- Window, navigation and mobile launcher.
local Main = new("Frame", {Name="Window", BackgroundColor3=Color3.fromRGB(15,18,30),
    BackgroundTransparency=Config.UI.Transparency, BorderSizePixel=0, Visible=Config.UI.Open,
    Position=UDim2.fromOffset(30,50), Size=UDim2.fromOffset(780,510), Active=true, ZIndex=5}, Gui)
corner(Main,20)
stroke(Main,Color3.fromRGB(111,119,161),0.6)
new("UIGradient", {Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(165,172,208))}), Rotation=105}, Main)
for i=1,3 do
    local shadow=new("Frame", {Name="Shadow", BackgroundColor3=Color3.new(), BackgroundTransparency=0.87+i*0.025,
        BorderSizePixel=0, Position=UDim2.fromOffset(-i*4,i*3), Size=UDim2.new(1,i*8,1,i*4), ZIndex=4}, Main)
    corner(shadow,20+i*4)
end
local Header = new("Frame", {BackgroundTransparency=1,Size=UDim2.new(1,0,0,70),Active=true,ZIndex=6}, Main)
local Mark = label(Header,"E",27,TEXT,{Position=UDim2.fromOffset(21,17),Size=UDim2.fromOffset(36,36),
    Font=Enum.Font.GothamBlack,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=7})
accentBind(Mark,"TextColor3")
label(Header,"EspadaWare",23,TEXT,{Position=UDim2.fromOffset(68,14),Size=UDim2.new(1,-175,0,28),
    Font=Enum.Font.GothamBold,ZIndex=7})
label(Header,"MOBILE / CLIENT CONTROL",9,MUTED,{Position=UDim2.fromOffset(69,43),Size=UDim2.new(1,-170,0,15),
    Font=Enum.Font.Code,ZIndex=7})
local Minimize = button(Header,"в€’",{Position=UDim2.new(1,-57,0,17),Size=UDim2.fromOffset(38,36),TextSize=25,ZIndex=7})
local TopLine = new("Frame", {BorderSizePixel=0,BackgroundTransparency=0.45,
    Position=UDim2.fromOffset(18,69),Size=UDim2.new(1,-36,0,1),ZIndex=6},Main)
accentBind(TopLine,"BackgroundColor3")
local Nav = new("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(13,84),Size=UDim2.new(0,147,1,-103),ZIndex=6},Main)
new("UIListLayout",{Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder},Nav)
local Content = new("ScrollingFrame",{Name="Content",BackgroundTransparency=1,BorderSizePixel=0,
    Position=UDim2.fromOffset(172,83),Size=UDim2.new(1,-188,1,-102),ScrollBarThickness=3,
    ScrollBarImageColor3=accent(),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=6},Main)
new("UIPadding",{PaddingTop=UDim.new(0,3),PaddingBottom=UDim.new(0,12),PaddingLeft=UDim.new(0,2),PaddingRight=UDim.new(0,5)},Content)
new("UIListLayout",{Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder},Content)
local NavButtons = {}
for order, name in ipairs({"Main","Movement","Visuals","Settings"}) do
    local navButton=button(Nav,name,{Size=UDim2.new(1,0,0,45),LayoutOrder=order,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7})
    new("UIPadding",{PaddingLeft=UDim.new(0,14)},navButton)
    local bar=new("Frame",{BorderSizePixel=0,Size=UDim2.fromOffset(3,20),Position=UDim2.new(0,-4,0.5,-10),ZIndex=8},navButton)
    corner(bar,3); accentBind(bar,"BackgroundColor3")
    NavButtons[name]={Button=navButton,Bar=bar}
    bind(navButton.Activated,function() selectTab(name) end)
end
local Launcher = button(Gui,"E",{Name="OpenEspadaWare",Size=UDim2.fromOffset(52,52),
    Position=UDim2.fromOffset(20,210),TextSize=27,Font=Enum.Font.GothamBlack,
    BackgroundColor3=Color3.fromRGB(20,23,38),ZIndex=30})
corner(Launcher,17); accentBind(stroke(Launcher,accent(),0.15,1.5),"Color")
accentBind(Launcher,"TextColor3")
local LauncherDot=new("Frame",{Size=UDim2.fromOffset(6,6),Position=UDim2.new(1,-11,0,7),
    BackgroundColor3=Color3.fromRGB(106,240,164),BorderSizePixel=0,ZIndex=31},Launcher)
corner(LauncherDot,8)
local function viewport()
    local camera=workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(800,600)
end
local function placeLauncher()
    local v=viewport()
    Launcher.Position=UDim2.fromOffset(math.clamp(Config.UI.ButtonX*(v.X-52),4,math.max(4,v.X-56)),
        math.clamp(Config.UI.ButtonY*(v.Y-52),4,math.max(4,v.Y-56)))
end
local compact=false
local function layout(center)
    local v=viewport()
    local width=math.min(840,math.max(280,v.X-20))
    local height=math.min(545,math.max(230,v.Y-30))
    Main.Size=UDim2.fromOffset(width,height)
    compact=width<580
    local navWidth=compact and 51 or 147
    Nav.Size=UDim2.new(0,navWidth,1,-103)
    Content.Position=UDim2.fromOffset(navWidth+26,83)
    Content.Size=UDim2.new(1,-navWidth-42,1,-102)
    local short={Main="M",Movement="MV",Visuals="V",Settings="S"}
    for name,data in pairs(NavButtons) do
        data.Button.Text=compact and short[name] or name
        data.Button.TextSize=compact and 12 or 14
    end
    if center then Main.Position=UDim2.fromOffset((v.X-width)/2,(v.Y-height)/2)
    else
        Main.Position=UDim2.fromOffset(math.clamp(Main.Position.X.Offset,0,math.max(0,v.X-width)),
            math.clamp(Main.Position.Y.Offset,0,math.max(0,v.Y-height)))
    end
    placeLauncher()
end
local function makeDraggable(handle, object, onClick, onEnd)
    local dragging=false
    local pointer, start, origin, moved, began
    bind(handle.InputBegan,function(input)
        if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        if dragging then return end
        dragging=true; pointer=input; start=Vector2.new(input.Position.X,input.Position.Y)
        origin=Vector2.new(object.Position.X.Offset,object.Position.Y.Offset); moved=false; began=os.clock()
    end)
    bind(UserInputService.InputChanged,function(input)
        if not dragging then return end
        if input~=pointer and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
        if pointer.UserInputType==Enum.UserInputType.Touch and input~=pointer then return end
        local delta=Vector2.new(input.Position.X,input.Position.Y)-start
        if delta.Magnitude>7 then moved=true end
        if moved then
            local v=viewport(); local size=object.AbsoluteSize
            object.Position=UDim2.fromOffset(math.clamp(origin.X+delta.X,0,math.max(0,v.X-size.X)),
                math.clamp(origin.Y+delta.Y,0,math.max(0,v.Y-size.Y)))
        end
    end)
    bind(UserInputService.InputEnded,function(input)
        if not dragging or input~=pointer then return end
        dragging=false
        if moved then if onEnd then onEnd() end
        elseif onClick and os.clock()-began<0.8 then onClick() end
    end)
end
local function toggleWindow() set("UI.Open",not Config.UI.Open) end
makeDraggable(Launcher,Launcher,toggleWindow,function()
    local v=viewport()
    rawSet("UI.ButtonX",Launcher.Position.X.Offset/math.max(1,v.X-52))
    set("UI.ButtonY",Launcher.Position.Y.Offset/math.max(1,v.Y-52))
end)
makeDraggable(Header,Main)
bind(Minimize.Activated,toggleWindow)
layout(true)

-- Runtime overlays. They are independent from the main window.
local Crosshair=new("Frame",{Name="Crosshair",BackgroundTransparency=1,Position=UDim2.fromScale(0.5,0.5),
    Size=UDim2.fromOffset(0,0),ZIndex=2},Gui)
local CrossLines={}
for i=1,4 do
    CrossLines[i]=accentBind(new("Frame",{BorderSizePixel=0,ZIndex=2},Crosshair),"BackgroundColor3")
    corner(CrossLines[i],2)
end
local FOVRing=new("Frame",{Name="FOVCircle",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
    BackgroundTransparency=1,Size=UDim2.fromOffset(Config.AimBot.FOV*2,Config.AimBot.FOV*2),ZIndex=1},Gui)
corner(FOVRing,9999); accentBind(stroke(FOVRing,accent(),0.5,1),"Color")
local Metrics=new("Frame",{BackgroundColor3=Color3.fromRGB(17,21,33),BackgroundTransparency=0.2,
    Position=UDim2.fromOffset(12,10),Size=UDim2.fromOffset(185,29),BorderSizePixel=0,ZIndex=3},Gui)
corner(Metrics,9); stroke(Metrics,nil,0.65)
local MetricsText=label(Metrics,"FPS --   PING --",11,TEXT,{Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-20,1,0),
    Font=Enum.Font.Code,ZIndex=3})
local HUD=new("Frame",{Name="TargetHUD",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-14),
    Size=UDim2.fromOffset(270,74),BackgroundColor3=Color3.fromRGB(17,21,33),BackgroundTransparency=0.08,
    BorderSizePixel=0,ZIndex=3,Visible=false},Gui)
corner(HUD,14); stroke(HUD,nil,0.45)
local HUDName=label(HUD,"NO TARGET",14,TEXT,{Position=UDim2.fromOffset(14,9),Size=UDim2.new(1,-28,0,21),
    Font=Enum.Font.GothamBold,ZIndex=4})
local HUDInfo=label(HUD,"",10,MUTED,{Position=UDim2.fromOffset(14,31),Size=UDim2.new(1,-28,0,16),Font=Enum.Font.Code,ZIndex=4})
local HPBackground=new("Frame",{Position=UDim2.fromOffset(14,56),Size=UDim2.new(1,-28,0,5),
    BackgroundColor3=Color3.fromRGB(44,49,67),BorderSizePixel=0,ZIndex=4},HUD); corner(HPBackground,5)
local HPFill=accentBind(new("Frame",{Size=UDim2.fromScale(1,1),BorderSizePixel=0,ZIndex=5},HPBackground),"BackgroundColor3"); corner(HPFill,5)
local AimHold=button(Gui,"AIM",{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-22,1,-155),
    Size=UDim2.fromOffset(64,50),ZIndex=4,Visible=false})
stroke(AimHold,accent(),0.3)
local FlyPad=new("Frame",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0.5),
    Position=UDim2.new(1,-18,0.5,0),Size=UDim2.fromOffset(58,115),Visible=false,ZIndex=4},Gui)
local Up=button(FlyPad,"в†‘",{Size=UDim2.fromOffset(54,50),TextSize=26,ZIndex=4})
local Down=button(FlyPad,"в†“",{Position=UDim2.fromOffset(0,61),Size=UDim2.fromOffset(54,50),TextSize=26,ZIndex=4})
local function hold(buttonObject, key)
    local activePointers={}
    bind(buttonObject.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            activePointers[input]=true; State[key]=true
        end
    end)
    bind(UserInputService.InputEnded,function(input)
        if activePointers[input] then activePointers[input]=nil; State[key]=next(activePointers)~=nil end
    end)
end
hold(AimHold,"Aiming"); hold(Up,"FlyUp"); hold(Down,"FlyDown")
bind(UserInputService.WindowFocusReleased,function() State.Aiming=false; State.FlyUp=false; State.FlyDown=false end)

-- GUI control factory: toggle, slider, dropdown, textbox and action.
local function refreshRegister(object, fn)
    table.insert(State.Refreshers,{object,fn})
    fn()
end
refreshUI=function()
    for i=#State.Refreshers,1,-1 do
        local item=State.Refreshers[i]
        if item[1].Parent then item[2]() else table.remove(State.Refreshers,i) end
    end
end
local function row(parent, height, order)
    local frame=new("Frame",{Size=UDim2.new(1,-2,0,height),BackgroundColor3=PANEL,BackgroundTransparency=0.12,
        BorderSizePixel=0,LayoutOrder=order or 0,ZIndex=parent.ZIndex+1},parent)
    corner(frame,12); stroke(frame,nil,0.77)
    return frame
end
local function toggle(parent, title, path, subtitle, settingsKey, order)
    local frame=row(parent,subtitle and 70 or 55,order)
    local z=frame.ZIndex+1
    label(frame,title,13,TEXT,{Position=UDim2.fromOffset(13,subtitle and 10 or 0),
        Size=UDim2.new(1,settingsKey and -118 or -82,0,subtitle and 23 or 55),ZIndex=z,
        TextTruncate=Enum.TextTruncate.AtEnd,Font=Enum.Font.GothamMedium})
    if subtitle then label(frame,subtitle,10,MUTED,{Position=UDim2.fromOffset(13,34),
        Size=UDim2.new(1,settingsKey and -112 or -76,0,27),TextWrapped=true,ZIndex=z}) end
    local hit=button(frame,"",{BackgroundTransparency=1,Position=UDim2.new(1,-65,0.5,-23),Size=UDim2.fromOffset(57,46),ZIndex=z})
    local track=new("Frame",{Position=UDim2.fromOffset(6,12),Size=UDim2.fromOffset(42,23),BorderSizePixel=0,ZIndex=z+1},hit); corner(track,20)
    local knob=new("Frame",{Size=UDim2.fromOffset(17,17),Position=UDim2.fromOffset(3,3),
        BackgroundColor3=TEXT,BorderSizePixel=0,ZIndex=z+2},track); corner(knob,20)
    bind(hit.Activated,function() set(path,not get(path)) end)
    refreshRegister(frame,function()
        local enabled=get(path)
        animate(track,{BackgroundColor3=enabled and accent() or Color3.fromRGB(56,61,80)},0.12)
        animate(knob,{Position=UDim2.fromOffset(enabled and 22 or 3,3)},0.12)
    end)
    if settingsKey then
        local gear=button(frame,"вљ™",{Position=UDim2.new(1,-104,0.5,-21),Size=UDim2.fromOffset(36,42),
            TextSize=23,BackgroundTransparency=1,ZIndex=z})
        bind(gear.Activated,function() openSettings(settingsKey) end)
    end
    return frame
end
local function slider(parent,title,path,min,max,step,order)
    local frame=row(parent,83,order)
    local z=frame.ZIndex+1
    label(frame,title,12,TEXT,{Position=UDim2.fromOffset(13,8),Size=UDim2.new(1,-88,0,24),ZIndex=z})
    local number=new("TextBox",{Position=UDim2.new(1,-72,0,8),Size=UDim2.fromOffset(59,25),
        BackgroundColor3=Color3.fromRGB(15,19,31),TextColor3=TEXT,Font=Enum.Font.Code,TextSize=12,
        ClearTextOnFocus=false,BorderSizePixel=0,ZIndex=z},frame); corner(number,6)
    local hit=button(frame,"",{Position=UDim2.fromOffset(14,36),Size=UDim2.new(1,-28,0,40),BackgroundTransparency=1,ZIndex=z})
    local track=new("Frame",{Position=UDim2.new(0,0,0.5,-2),Size=UDim2.new(1,0,0,4),
        BackgroundColor3=Color3.fromRGB(53,59,78),BorderSizePixel=0,ZIndex=z},hit); corner(track,4)
    local fill=accentBind(new("Frame",{Size=UDim2.fromScale(0,1),BorderSizePixel=0,ZIndex=z+1},track),"BackgroundColor3"); corner(fill,4)
    local knob=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(15,15),
        BackgroundColor3=TEXT,BorderSizePixel=0,Position=UDim2.fromScale(0,0.5),ZIndex=z+2},track); corner(knob,12)
    local dragging, pointer=false,nil
    local function quantize(n) return math.clamp(min+math.floor((n-min)/step+0.5)*step,min,max) end
    local function fromX(x)
        local fraction=math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
        set(path,quantize(min+(max-min)*fraction))
    end
    bind(hit.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; pointer=input; fromX(input.Position.X)
            if parent:IsA("ScrollingFrame") then parent.ScrollingEnabled=false end
        end
    end)
    ownedBind(frame,UserInputService.InputChanged,function(input)
        if not frame.Parent or not dragging then return end
        if input==pointer or (pointer.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then fromX(input.Position.X) end
    end)
    ownedBind(frame,UserInputService.InputEnded,function(input)
        if input==pointer then
            dragging=false; pointer=nil
            if parent.Parent and parent:IsA("ScrollingFrame") then parent.ScrollingEnabled=true end
        end
    end)
    bind(number.FocusLost,function()
        local n=tonumber(number.Text)
        if n and n==n then set(path,quantize(n)) else refreshUI() end
    end)
    refreshRegister(frame,function()
        local v=get(path); local fraction=(v-min)/(max-min)
        fill.Size=UDim2.fromScale(fraction,1); knob.Position=UDim2.fromScale(fraction,0.5)
        if not number:IsFocused() then number.Text=step>=1 and tostring(math.floor(v+0.5)) or string.format("%.2f",v) end
    end)
end
local function section(parent,title,order)
    return label(parent,title,11,MUTED,{Size=UDim2.new(1,-4,0,29),LayoutOrder=order or 0,Font=Enum.Font.GothamBold,ZIndex=parent.ZIndex+1})
end
local function note(parent,text,order)
    local object=label(parent,text,11,MUTED,{Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top,LayoutOrder=order or 0,ZIndex=parent.ZIndex+1})
    new("UIPadding",{PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,8)},object)
    return object
end
local function action(parent,title,fn,order,danger)
    local object=button(parent,title,{Size=UDim2.new(1,-2,0,45),LayoutOrder=order or 0,
        TextColor3=danger and Color3.fromRGB(255,135,154) or TEXT,ZIndex=parent.ZIndex+1})
    stroke(object,nil,0.7); bind(object.Activated,fn)
    return object
end
local function closePicker()
    if State.Picker then State.Picker:Destroy(); State.Picker=nil end
end
local function choose(title, options, selected, callback)
    closePicker()
    local backdrop=button(Gui,"",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(),BackgroundTransparency=0.42,ZIndex=42})
    State.Picker=backdrop
    local v=viewport()
    local panel=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromOffset(math.min(355,v.X-28),math.min(420,v.Y-38)),BackgroundColor3=Color3.fromRGB(19,23,37),
        BorderSizePixel=0,ZIndex=43,Active=true},backdrop); corner(panel,16); stroke(panel,accent(),0.5)
    label(panel,title,16,TEXT,{Position=UDim2.fromOffset(16,10),Size=UDim2.new(1,-65,0,38),ZIndex=44,Font=Enum.Font.GothamBold})
    local exit=button(panel,"Г—",{Position=UDim2.new(1,-45,0,12),Size=UDim2.fromOffset(32,32),TextSize=22,ZIndex=44})
    bind(exit.Activated,closePicker)
    bind(backdrop.Activated,closePicker)
    local scroll=new("ScrollingFrame",{Position=UDim2.fromOffset(13,58),Size=UDim2.new(1,-26,1,-71),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.new(),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=44},panel)
    new("UIListLayout",{Padding=UDim.new(0,7)},scroll)
    for _,option in ipairs(options) do
        local value=type(option)=="table" and option.Value or option
        local caption=type(option)=="table" and option.Label or tostring(option)
        local item=button(scroll,(value==selected and "в—Џ  " or "в—‹  ")..caption,
            {Size=UDim2.new(1,-5,0,43),TextSize=12,ZIndex=45,TextTruncate=Enum.TextTruncate.AtEnd})
        if value==selected then item.TextColor3=accent() end
        bind(item.Activated,function() closePicker(); callback(value) end)
    end
end
local function dropdown(parent,title,path,options,order)
    local frame=row(parent,69,order); local z=frame.ZIndex+1
    label(frame,title,11,MUTED,{Position=UDim2.fromOffset(13,7),Size=UDim2.new(1,-25,0,18),ZIndex=z})
    local hit=button(frame,"",{Position=UDim2.fromOffset(10,27),Size=UDim2.new(1,-20,0,34),TextSize=12,ZIndex=z})
    local function list() return type(options)=="function" and options() or options end
    refreshRegister(frame,function()
        local text=tostring(get(path))
        for _,option in ipairs(list()) do
            if type(option)=="table" and option.Value==get(path) then text=option.Label end
        end
        hit.Text=text.."  в–ѕ"
    end)
    bind(hit.Activated,function() choose(title,list(),get(path),function(v) set(path,v) end) end)
end
local function textbox(parent,title,path,placeholder,order)
    local frame=row(parent,77,order); local z=frame.ZIndex+1
    label(frame,title,11,MUTED,{Position=UDim2.fromOffset(13,6),Size=UDim2.new(1,-26,0,22),ZIndex=z})
    local input=new("TextBox",{Position=UDim2.fromOffset(11,33),Size=UDim2.new(1,-22,0,33),
        Text=tostring(get(path)),PlaceholderText=placeholder or "",PlaceholderColor3=MUTED,ClearTextOnFocus=false,
        BackgroundColor3=Color3.fromRGB(14,18,29),TextColor3=TEXT,Font=Enum.Font.Code,TextSize=12,
        BorderSizePixel=0,ZIndex=z},frame); corner(input,7)
    bind(input.FocusLost,function() set(path,string.sub(input.Text,1,128)) end)
    refreshRegister(frame,function() if not input:IsFocused() then input.Text=tostring(get(path)) end end)
end

-- Target selection and a narrowly scoped legacy Mouse adapter.
local function sameTeam(player)
    return not LocalPlayer.Neutral and not player.Neutral and LocalPlayer.Team~=nil and player.Team==LocalPlayer.Team
end
local function aimPart(player)
    local character,humanoid,root=characterParts(player)
    if not humanoid or humanoid.Health<=0 or not root then return nil end
    local part=character:FindFirstChild(Config.AimBot.Part) or root
    if not part:IsA("BasePart") then return nil end
    return part,character,humanoid,root
end
local function candidate(player, useFOV)
    if not player or player==LocalPlayer or player.Parent~=Players then return nil end
    if Config.AimBot.TeamCheck and sameTeam(player) then return nil end
    local part,character,humanoid,root=aimPart(player)
    local camera=workspace.CurrentCamera
    if not part or not camera then return nil end
    local distance=(part.Position-camera.CFrame.Position).Magnitude
    if distance>Config.AimBot.MaxDistance then return nil end
    local point,visible=camera:WorldToViewportPoint(part.Position)
    if not visible or point.Z<=0 then return nil end
    local screenDistance=(Vector2.new(point.X,point.Y)-camera.ViewportSize/2).Magnitude
    if useFOV and screenDistance>Config.AimBot.FOV then return nil end
    if Config.AimBot.WallCheck then
        local parameters=RaycastParams.new()
        parameters.FilterType=Enum.RaycastFilterType.Exclude
        parameters.FilterDescendantsInstances=LocalPlayer.Character and {LocalPlayer.Character} or {}
        parameters.IgnoreWater=true
        local result=workspace:Raycast(camera.CFrame.Position,part.Position-camera.CFrame.Position,parameters)
        if result and not result.Instance:IsDescendantOf(character) then return nil end
    end
    return screenDistance,part
end
local function acquireTarget()
    if Config.Target.UserId~=0 then
        local manual=Players:GetPlayerByUserId(Config.Target.UserId)
        if candidate(manual,true) then return manual end
        return nil
    end
    if Config.Target.Sticky and State.Target and candidate(State.Target,true) then return State.Target end
    local best,bestScore=nil,math.huge
    for _,player in ipairs(Players:GetPlayers()) do
        local score=candidate(player,true)
        if score and score<bestScore then best=player; bestScore=score end
    end
    return best
end
local function targetChoices()
    local options={{Value=0,Label="Auto / Р±Р»РёР¶Р°Р№С€РёР№ Рє РїСЂРёС†РµР»Сѓ"}}
    for _,player in ipairs(Players:GetPlayers()) do
        if player~=LocalPlayer then table.insert(options,{Value=player.UserId,Label=player.DisplayName.." (@"..player.Name..")"}) end
    end
    if Config.Target.UserId~=0 and not Players:GetPlayerByUserId(Config.Target.UserId) then
        table.insert(options,{Value=Config.Target.UserId,Label="РћС„Р»Р°Р№РЅ: "..tostring(Config.Target.UserId)})
    end
    return options
end
local HookRegistry=ENV.__EspadaWareMouseHook
if type(HookRegistry)~="table" then HookRegistry={Installed=false}; ENV.__EspadaWareMouseHook=HookRegistry end
if CAN_HOOK then
    HookRegistry.Resolve=function(object,key)
        if not State.Alive or not Config.SilentAim.Enabled or object~=Mouse then return nil end
        if key~="Hit" and key~="Target" and key~="UnitRay" then return nil end
        if not State.SilentPass then return nil end
        local part=State.Target and aimPart(State.Target)
        local camera=workspace.CurrentCamera
        if not part or not camera then return nil end
        if key=="Hit" then return part.CFrame end
        if key=="Target" then return part end
        local offset=part.Position-camera.CFrame.Position
        if offset.Magnitude<0.01 then return nil end
        return Ray.new(camera.CFrame.Position,offset.Unit)
    end
    if not HookRegistry.Installed then
        local ok,err=pcall(function()
            local old
            old=API.hook(game,"__index",API.closure(function(object,key)
                if not API.caller() and HookRegistry.Resolve then
                    local success,result=pcall(HookRegistry.Resolve,object,key)
                    if success and result~=nil then return result end
                end
                return old(object,key)
            end))
            HookRegistry.Installed=true
        end)
        if not ok then warn("[EspadaWare] Legacy Mouse adapter unavailable:",err) end
    end
    State.HookReady=HookRegistry.Installed
end
if not State.HookReady then Config.SilentAim.Enabled=false end

-- Feature state and restoration.
local LightOriginal,StoredSkies={},{}
local LIGHT_KEYS={"Brightness","ClockTime","Ambient","OutdoorAmbient","GlobalShadows","FogStart","FogEnd"}
local OwnSky
local MusicSound=new("Sound",{Name="EspadaWareMusic",Volume=Config.Music.Volume,Looped=Config.Music.Loop},SoundService)
local musicGeneration=0
local cameraOriginal, spectateOriginal
local function applyLighting()
    if Config.Fullbright.Enabled then
        if not next(LightOriginal) then for _,key in ipairs(LIGHT_KEYS) do LightOriginal[key]=Lighting[key] end end
        Lighting.Brightness=Config.Fullbright.Brightness
        Lighting.ClockTime=Config.Fullbright.ClockTime
        Lighting.Ambient=Color3.fromRGB(200,200,210)
        Lighting.OutdoorAmbient=Color3.fromRGB(200,200,210)
        Lighting.GlobalShadows=false
        if Config.Fullbright.NoFog then Lighting.FogStart=100000; Lighting.FogEnd=100001
        else Lighting.FogStart=LightOriginal.FogStart; Lighting.FogEnd=LightOriginal.FogEnd end
    elseif next(LightOriginal) then
        for key,value in pairs(LightOriginal) do pcall(function() Lighting[key]=value end) end
        LightOriginal={}
    end
end
local SkyPresets={
    Nebula={"159454299","159454296","159454293","159454286","159454300","159454288"},
    Classic={"rbxasset://textures/sky/sky512_bk.tex","rbxasset://textures/sky/sky512_dn.tex",
        "rbxasset://textures/sky/sky512_ft.tex","rbxasset://textures/sky/sky512_lf.tex",
        "rbxasset://textures/sky/sky512_rt.tex","rbxasset://textures/sky/sky512_up.tex"},
}
local function asset(value)
    value=tostring(value or "")
    if value:match("^rbxasset://") then return value end
    local id=value:match("%d+")
    return id and "rbxassetid://"..id or ""
end
local function restoreSky()
    if OwnSky then OwnSky:Destroy(); OwnSky=nil end
    for _,sky in ipairs(StoredSkies) do pcall(function() if sky.Parent==nil then sky.Parent=Lighting end end) end
    StoredSkies={}
end
local function applySky()
    if not Config.Skybox.Enabled then restoreSky(); return end
    if not OwnSky then
        for _,child in ipairs(Lighting:GetChildren()) do
            if child:IsA("Sky") then table.insert(StoredSkies,child); child.Parent=nil end
        end
        OwnSky=new("Sky",{Name="EspadaWareSky"},Lighting)
    end
    local faces={"Bk","Dn","Ft","Lf","Rt","Up"}
    local preset=SkyPresets[Config.Skybox.Preset]
    for i,face in ipairs(faces) do OwnSky["Skybox"..face]=asset(preset and preset[i] or Config.Skybox[face]) end
    OwnSky.StarCount=math.floor(Config.Skybox.Stars)
    OwnSky.CelestialBodiesShown=true
end
local function applyMusic()
    MusicSound.Volume=Config.Music.Volume; MusicSound.PlaybackSpeed=Config.Music.PlaybackSpeed
    MusicSound.Looped=Config.Music.Loop
    local id=asset(Config.Music.Id)
    if MusicSound.SoundId~=id then MusicSound:Stop(); MusicSound.SoundId=id end
    if Config.Music.Enabled and id~="" then
        if not MusicSound.Playing and not State.MusicPaused then MusicSound:Play() end
        musicGeneration=musicGeneration+1
        local generation=musicGeneration
        task.delay(8,function()
            if State.Alive and generation==musicGeneration and Config.Music.Enabled and not MusicSound.IsLoaded then
                rateError("music","РђСѓРґРёРѕ РЅРµ Р·Р°РіСЂСѓР·РёР»РѕСЃСЊ: ID РЅРµРґРѕСЃС‚СѓРїРµРЅ РёР»Рё Сѓ СЌС‚РѕР№ РёРіСЂС‹ РЅРµС‚ РїСЂР°РІ РЅР° РЅРµРіРѕ")
            end
        end)
    else MusicSound:Stop(); State.MusicPaused=false end
end
local function restoreCollisions()
    for part,wasCollidable in pairs(State.Collisions) do
        if part.Parent then pcall(function() part.CanCollide=wasCollidable end) end
    end
    State.Collisions={}
end
local function stopFly()
    local flight=State.FlyObjects
    if not flight then return end
    State.FlyObjects=nil
    for _,object in ipairs(flight.Objects) do pcall(function() object:Destroy() end) end
    if flight.Humanoid.Parent then
        flight.Humanoid.AutoRotate=flight.AutoRotate
        flight.Humanoid.PlatformStand=flight.PlatformStand
        if flight.Humanoid.Health>0 and not flight.PlatformStand then
            flight.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
    State.FlyUp=false; State.FlyDown=false
end
local function startFly(humanoid,root)
    stopFly()
    local attachment=new("Attachment",{Name="EspadaWareFlight"},root)
    local velocity=new("LinearVelocity",{Name="EspadaWareVelocity",Attachment0=attachment,
        RelativeTo=Enum.ActuatorRelativeTo.World,VelocityConstraintMode=Enum.VelocityConstraintMode.Vector,
        VectorVelocity=Vector3.zero,MaxForce=math.huge},root)
    pcall(function() velocity.ForceLimitsEnabled=false end)
    local orientation=new("AlignOrientation",{Name="EspadaWareOrientation",Attachment0=attachment,
        Mode=Enum.OrientationAlignmentMode.OneAttachment,MaxTorque=math.huge,Responsiveness=25,RigidityEnabled=false},root)
    State.FlyObjects={Objects={velocity,orientation,attachment},Velocity=velocity,Orientation=orientation,
        Humanoid=humanoid,Root=root,AutoRotate=humanoid.AutoRotate,PlatformStand=humanoid.PlatformStand}
    humanoid.AutoRotate=false; humanoid.PlatformStand=true
end
local function restoreMovement()
    stopFly(); restoreCollisions()
    local h=State.Humanoid; local original=State.MovementOriginal
    if h and h.Parent and original then
        if original.Speed~=nil then h.WalkSpeed=original.Speed end
        if original.JumpPower~=nil then h.JumpPower=original.JumpPower; h.JumpHeight=original.JumpHeight end
    end
    State.MovementOriginal=nil; State.Humanoid=nil
end
local function movementStep()
    local character,h,root=characterParts(LocalPlayer)
    if State.Humanoid~=h then
        restoreMovement()
        State.Humanoid=h
        State.MovementOriginal={}
    end
    if not h or not root or h.Health<=0 then stopFly(); restoreCollisions(); return end
    local original=State.MovementOriginal
    if Config.Speed.Enabled then
        if original.Speed==nil then original.Speed=h.WalkSpeed end
        h.WalkSpeed=Config.Speed.Value
    elseif original.Speed~=nil then h.WalkSpeed=original.Speed; original.Speed=nil end
    if Config.Jump.Enabled then
        if original.JumpPower==nil then original.JumpPower=h.JumpPower; original.JumpHeight=h.JumpHeight end
        h.JumpPower=Config.Jump.Power; h.JumpHeight=Config.Jump.Height
    elseif original.JumpPower~=nil then
        h.JumpPower=original.JumpPower; h.JumpHeight=original.JumpHeight
        original.JumpPower=nil; original.JumpHeight=nil
    end
    if Config.Noclip.Enabled then
        for _,part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if State.Collisions[part]==nil then State.Collisions[part]=part.CanCollide end
                part.CanCollide=false
            end
        end
    elseif next(State.Collisions) then restoreCollisions() end
    if Config.Fly.Enabled then
        if not State.FlyObjects or State.FlyObjects.Root~=root then startFly(h,root) end
        local camera=workspace.CurrentCamera
        if camera then
            local look=camera.CFrame.LookVector
            local flat=Vector3.new(look.X,0,look.Z)
            if flat.Magnitude<0.01 then flat=Vector3.new(0,0,-1) else flat=flat.Unit end
            local right=Vector3.new(-flat.Z,0,flat.X)
            local move=h.MoveDirection
            -- MoveDirection reads the default mobile thumbstick and desktop WASD.
            local forwardAmount=move:Dot(flat)
            local sideAmount=move:Dot(right)
            local direction=look*forwardAmount+camera.CFrame.RightVector*sideAmount
            if direction.Magnitude>1 then direction=direction.Unit end
            local typing=UserInputService:GetFocusedTextBox()~=nil
            local up=State.FlyUp or (not typing and UserInputService:IsKeyDown(Enum.KeyCode.Space))
            local down=State.FlyDown or (not typing and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl))
            local vertical=(up and 1 or 0)-(down and 1 or 0)
            State.FlyObjects.Velocity.VectorVelocity=direction*Config.Fly.Speed+Vector3.new(0,vertical*Config.Fly.VerticalSpeed,0)
            State.FlyObjects.Orientation.CFrame=CFrame.lookAt(root.Position,root.Position+flat)
        end
    elseif State.FlyObjects then stopFly() end
end
bind(UserInputService.JumpRequest,function()
    if not Config.InfinityJump.Enabled or Config.Fly.Enabled or UserInputService:GetFocusedTextBox() then return end
    local _,h,root=characterParts(LocalPlayer)
    if h and root and h.Health>0 then
        local power=h.UseJumpPower and h.JumpPower or math.sqrt(2*workspace.Gravity*h.JumpHeight)
        h:ChangeState(Enum.HumanoidStateType.Jumping)
        local velocity=root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity=Vector3.new(velocity.X,power,velocity.Z)
    end
end)

-- ESP is created lazily, supports respawns, streaming and player removal.
local ESPFolder=new("Folder",{Name="EspadaWareESP_"..tostring(LocalPlayer.UserId)},workspace)
local function removeESP(player)
    local data=State.ESP[player]
    if data then data.Highlight:Destroy(); data.Billboard:Destroy(); State.ESP[player]=nil end
end
local function espStep()
    local camera=workspace.CurrentCamera
    if not camera then return end
    if not Config.ESP.Enabled then
        for player in pairs(State.ESP) do removeESP(player) end
        return
    end
    for _,player in ipairs(Players:GetPlayers()) do
        if player~=LocalPlayer then
            local character,h,root=characterParts(player)
            local distance=root and (root.Position-camera.CFrame.Position).Magnitude or math.huge
            local eligible=h and h.Health>0 and root and distance<=Config.ESP.MaxDistance
                and (not Config.ESP.TeamCheck or not sameTeam(player))
            if not eligible then removeESP(player)
            else
                local data=State.ESP[player]
                if data and data.Character~=character then removeESP(player); data=nil end
                if not data then
                    local highlight=new("Highlight",{Name="EspadaHighlight",Adornee=character,
                        FillTransparency=0.8,OutlineTransparency=0.08},ESPFolder)
                    local billboard=new("BillboardGui",{Name="EspadaLabel",Adornee=character:FindFirstChild("Head") or root,
                        Size=UDim2.fromOffset(210,54),StudsOffsetWorldSpace=Vector3.new(0,2.8,0),
                        AlwaysOnTop=true,MaxDistance=Config.ESP.MaxDistance},ESPFolder)
                    local text=label(billboard,"",12,TEXT,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,
                        TextStrokeTransparency=0.25,TextStrokeColor3=Color3.new(),Font=Enum.Font.GothamMedium})
                    data={Highlight=highlight,Billboard=billboard,Text=text,Character=character}
                    State.ESP[player]=data
                end
                local color=player==State.Target and Color3.fromRGB(255,114,144) or accent()
                data.Highlight.FillColor=color; data.Highlight.OutlineColor=color
                data.Highlight.DepthMode=Config.ESP.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                data.Billboard.AlwaysOnTop=Config.ESP.ThroughWalls; data.Billboard.MaxDistance=Config.ESP.MaxDistance
                local parts={}
                if Config.ESP.Names then table.insert(parts,player.DisplayName) end
                if Config.ESP.Health then table.insert(parts,string.format("%d / %d HP",math.ceil(h.Health),math.ceil(h.MaxHealth))) end
                if Config.ESP.Distance then table.insert(parts,string.format("%d studs",math.floor(distance))) end
                data.Text.Text=table.concat(parts,"\n"); data.Text.TextColor3=color
            end
        end
    end
end
bind(Players.PlayerRemoving,function(player) removeESP(player); if State.Target==player then State.Target=nil end end)

local function restoreCamera()
    local camera=workspace.CurrentCamera
    if spectateOriginal then
        if spectateOriginal.Camera and spectateOriginal.Camera.Parent then
            local _,h=characterParts(LocalPlayer)
            pcall(function()
                local original=spectateOriginal.Subject
                spectateOriginal.Camera.CameraSubject=(original and original.Parent and original) or h
                spectateOriginal.Camera.CameraType=spectateOriginal.Type
            end)
        end
        spectateOriginal=nil
    end
    if cameraOriginal then
        if cameraOriginal.Camera and cameraOriginal.Camera.Parent then
            pcall(function() cameraOriginal.Camera.FieldOfView=cameraOriginal.FOV end)
        end
        cameraOriginal=nil
    end
end
local function cameraSettings()
    local camera=workspace.CurrentCamera
    if not camera then return end
    if (cameraOriginal and cameraOriginal.Camera~=camera) or
        (spectateOriginal and spectateOriginal.Camera~=camera) then restoreCamera() end
    if Config.Camera.Enabled then
        if not cameraOriginal then cameraOriginal={Camera=camera,FOV=camera.FieldOfView} end
        camera.FieldOfView=Config.Camera.FOV
    elseif cameraOriginal then
        cameraOriginal.Camera.FieldOfView=cameraOriginal.FOV; cameraOriginal=nil
    end
    if Config.Target.Spectate then
        local p=Config.Target.UserId~=0 and Players:GetPlayerByUserId(Config.Target.UserId) or State.Target
        local _,h=characterParts(p)
        if h and h.Health>0 then
            if not spectateOriginal then spectateOriginal={Camera=camera,Subject=camera.CameraSubject,Type=camera.CameraType} end
            camera.CameraSubject=h; camera.CameraType=Enum.CameraType.Custom
        elseif spectateOriginal then
            local _,own=characterParts(LocalPlayer)
            local original=spectateOriginal.Subject
            camera.CameraSubject=(original and original.Parent and original) or own
            camera.CameraType=spectateOriginal.Type
            spectateOriginal=nil
        end
    elseif spectateOriginal then
        local _,own=characterParts(LocalPlayer)
        local original=spectateOriginal.Subject
            camera.CameraSubject=(original and original.Parent and original) or own
            camera.CameraType=spectateOriginal.Type
        spectateOriginal=nil
    end
end
local function updateHUD()
    local p=State.Target
    local _,h,root=characterParts(p)
    HUD.Visible=Config.Target.ShowHUD and p~=nil and h~=nil and root~=nil and h.Health>0
    if not HUD.Visible then return end
    local _,_,own=characterParts(LocalPlayer)
    local distance=own and (root.Position-own.Position).Magnitude or 0
    HUDName.Text=p.DisplayName.."  @"..p.Name
    HUDName.TextTruncate=Enum.TextTruncate.AtEnd
    HUDInfo.Text=string.format("%d / %d HP    %d STUDS",math.ceil(h.Health),math.ceil(h.MaxHealth),math.floor(distance))
    animate(HPFill,{Size=UDim2.fromScale(math.clamp(h.Health/math.max(1,h.MaxHealth),0,1),1)},0.12)
end
local function triggerStep()
    if not Config.TriggerBot.Enabled or not State.Alive or Config.UI.Open or State.Sheet or State.Picker then return end
    if UserInputService:GetFocusedTextBox() then return end
    local camera=workspace.CurrentCamera
    if not camera then return end
    if os.clock()-State.LastTrigger<Config.TriggerBot.Interval then return end
    local ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
    local parameters=RaycastParams.new(); parameters.FilterType=Enum.RaycastFilterType.Exclude
    parameters.FilterDescendantsInstances=LocalPlayer.Character and {LocalPlayer.Character} or {}
    parameters.IgnoreWater=true
    local result=workspace:Raycast(ray.Origin,ray.Direction*Config.AimBot.MaxDistance,parameters)
    if not result then return end
    local model=result.Instance:FindFirstAncestorOfClass("Model")
    local player
    while model do
        player=Players:GetPlayerFromCharacter(model)
        if player then break end
        model=model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
    end
    if not player or player==LocalPlayer or (Config.AimBot.TeamCheck and sameTeam(player)) then return end
    if Config.TriggerBot.RequireTarget and player~=State.Target then return end
    local _,h=characterParts(player)
    if not h or h.Health<=0 then return end
    State.LastTrigger=os.clock()
    if Config.TriggerBot.Method=="Tool" then
        local tool=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
            task.delay(0.03,function() if tool.Parent then pcall(function() tool:Deactivate() end) end end)
        else rateError("triggerTool","TriggerBot: СЌРєРёРїРёСЂСѓР№ Tool. РљР°СЃС‚РѕРјРЅРѕРµ РѕСЂСѓР¶РёРµ РјРѕР¶РµС‚ РЅРµ РїРѕРґРґРµСЂР¶РёРІР°С‚СЊ Activate()") end
    else
        local x,y=camera.ViewportSize.X/2,camera.ViewportSize.Y/2
        local ok=pcall(function() VirtualInput:SendMouseButtonEvent(x,y,0,true,game,0) end)
        -- Always attempt release, including during unload.
        task.delay(0.025,function() pcall(function() VirtualInput:SendMouseButtonEvent(x,y,0,false,game,0) end) end)
        if not ok then
            set("TriggerBot.Enabled",false)
            toast("VirtualMouse Р·Р°РїСЂРµС‰С‘РЅ executor. Р’С‹Р±РµСЂРё TriggerBot в†’ Method в†’ Tool",true)
        end
    end
end

-- Every gear has its own settings schema.
local SettingsBuilders={}
SettingsBuilders.AimBot=function(parent)
    dropdown(parent,"Activation","AimBot.Mode",{{Value="Always",Label="Always / РїРѕСЃС‚РѕСЏРЅРЅРѕ"},{Value="WhileAiming",Label="WhileAiming / СѓРґРµСЂР¶РёРІР°С‚СЊ AIM"}},1)
    dropdown(parent,"Aim part","AimBot.Part",{"Head","HumanoidRootPart"},2)
    slider(parent,"FOV radius (pixels)","AimBot.FOV",30,450,5,3)
    slider(parent,"Response (higher = faster)","AimBot.Smoothness",1,30,1,4)
    slider(parent,"Max distance (studs)","AimBot.MaxDistance",50,5000,50,5)
    toggle(parent,"Team check","AimBot.TeamCheck",nil,nil,6)
    toggle(parent,"Wall check","AimBot.WallCheck",nil,nil,7)
    note(parent,"РќР°РІРµРґРµРЅРёРµ РєР°РјРµСЂРѕР№. Р¤РёР»СЊС‚СЂС‹ С†РµР»Рё РѕР±С‰РёРµ СЃ SilentAim. РџСЂРё РѕС‚РєСЂС‹С‚РѕРј РёРЅС‚РµСЂС„РµР№СЃРµ AimBot РїСЂРёРѕСЃС‚Р°РЅРѕРІР»РµРЅ.",8)
end
SettingsBuilders.SilentAim=function(parent)
    note(parent,"LEGACY MOUSE ONLY. РњРµРЅСЏРµС‚ Mouse.Hit / Target / UnitRay. РќРµ РїРѕРґРґРµСЂР¶РёРІР°РµС‚ РїСЂРѕРёР·РІРѕР»СЊРЅС‹Рµ Raycast, СЃРµСЂРІРµСЂРЅС‹Рµ РІС‹СЃС‚СЂРµР»С‹ Рё СЃРёСЃС‚РµРјС‹ СЃ СЃРѕР±СЃС‚РІРµРЅРЅС‹Рј РїСЂРёС†РµР»РёРІР°РЅРёРµРј. РЁР°РЅСЃ РїРµСЂРµСЃС‡РёС‚С‹РІР°РµС‚СЃСЏ РєР°Р¶РґС‹Рµ 75 РјСЃ, Р° РЅРµ РѕС‚РґРµР»СЊРЅРѕ РґР»СЏ РєР°Р¶РґРѕРіРѕ РІС‹СЃС‚СЂРµР»Р°.",1)
    slider(parent,"Hit chance (%)","SilentAim.Chance",0,100,1,2)
    action(parent,"РћС‚РєСЂС‹С‚СЊ РѕР±С‰РёРµ РЅР°СЃС‚СЂРѕР№РєРё С†РµР»Рё",function() openSettings("AimBot") end,3)
    note(parent,State.HookReady and "Mouse hook СѓСЃС‚Р°РЅРѕРІР»РµРЅ. РЎРѕРІРјРµСЃС‚РёРјРѕСЃС‚СЊ РѕСЂСѓР¶РёСЏ РЅРµ РїРѕРґС‚РІРµСЂР¶РґРµРЅР°." or "API РЅРµРґРѕСЃС‚СѓРїРµРЅ. Р’РєР»СЋС‡РµРЅРёРµ Р·Р°Р±Р»РѕРєРёСЂРѕРІР°РЅРѕ.",4)
end
SettingsBuilders.TriggerBot=function(parent)
    dropdown(parent,"Method","TriggerBot.Method",{"Tool","VirtualMouse"},1)
    slider(parent,"Shot interval (seconds)","TriggerBot.Interval",0.05,2,0.05,2)
    toggle(parent,"Only selected target","TriggerBot.RequireTarget",nil,nil,3)
    note(parent,"РЎСЂР°Р±Р°С‚С‹РІР°РµС‚ РЅР° РёРіСЂРѕРєР° РїРѕРґ С†РµРЅС‚СЂРѕРј СЌРєСЂР°РЅР°. Tool РІС‹Р·С‹РІР°РµС‚ Activate(); VirtualMouse С‚СЂРµР±СѓРµС‚ СЂР°Р·СЂРµС€РµРЅРёСЏ executor. РџСЂРё РѕС‚РєСЂС‹С‚РѕРј GUI РїСЂРёРѕСЃС‚Р°РЅРѕРІР»РµРЅ.",4)
end
SettingsBuilders.Target=function(parent)
    dropdown(parent,"Р¦РµР»СЊ / Target","Target.UserId",targetChoices,1)
    toggle(parent,"Sticky target","Target.Sticky",nil,nil,2)
    toggle(parent,"Target HUD","Target.ShowHUD",nil,nil,3)
    toggle(parent,"Spectate target","Target.Spectate",nil,nil,4)
    action(parent,"РЎРјРµРЅРёС‚СЊ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєСѓСЋ С†РµР»СЊ",function()
        local old=State.Target; local best,score=nil,math.huge
        rawSet("Target.UserId",0)
        for _,p in ipairs(Players:GetPlayers()) do
            local n=candidate(p,true)
            if p~=old and n and n<score then best=p; score=n end
        end
        State.Target=best; set("Target.UserId",best and best.UserId or 0)
        toast(best and "Р¦РµР»СЊ: "..best.DisplayName or "РќРµС‚ РґСЂСѓРіРѕР№ С†РµР»Рё РІ FOV")
    end,5)
    note(parent,"Р СѓС‡РЅРѕР№ РІС‹Р±РѕСЂ С„РёРєСЃРёСЂСѓРµС‚ РёРіСЂРѕРєР°, РЅРѕ AimBot Рё SilentAim РїСЂРѕРґРѕР»Р¶Р°СЋС‚ СѓС‡РёС‚С‹РІР°С‚СЊ FOV, РґРёСЃС‚Р°РЅС†РёСЋ, РєРѕРјР°РЅРґС‹ Рё СЃС‚РµРЅС‹. Spectate СЂР°Р±РѕС‚Р°РµС‚ РѕС‚РґРµР»СЊРЅРѕ.",6)
end
SettingsBuilders.ESP=function(parent)
    toggle(parent,"Player names","ESP.Names",nil,nil,1)
    toggle(parent,"Health","ESP.Health",nil,nil,2)
    toggle(parent,"Distance","ESP.Distance",nil,nil,3)
    toggle(parent,"Through walls","ESP.ThroughWalls",nil,nil,4)
    toggle(parent,"Team check","ESP.TeamCheck",nil,nil,5)
    slider(parent,"Max distance (studs)","ESP.MaxDistance",50,10000,50,6)
    note(parent,"Highlight + РїРѕРґРїРёСЃСЊ. Р”РѕСЃС‚СѓРїРЅС‹ С‚РѕР»СЊРєРѕ РїРµСЂСЃРѕРЅР°Р¶Рё, Р·Р°РіСЂСѓР¶РµРЅРЅС‹Рµ РєР»РёРµРЅС‚РѕРј. StreamingEnabled Рё Р»РёРјРёС‚ Highlight Roblox РјРѕРіСѓС‚ РѕРіСЂР°РЅРёС‡РёРІР°С‚СЊ РѕС‚РѕР±СЂР°Р¶РµРЅРёРµ.",7)
end
SettingsBuilders.Noclip=function(parent)
    note(parent,"Р›РѕРєР°Р»СЊРЅРѕ РѕС‚РєР»СЋС‡Р°РµС‚ CanCollide С‡Р°СЃС‚РµР№ РїРµСЂСЃРѕРЅР°Р¶Р° Рё РІРѕСЃСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ РёСЃС…РѕРґРЅС‹Рµ Р·РЅР°С‡РµРЅРёСЏ РїСЂРё РІС‹РєР»СЋС‡РµРЅРёРё. РЎРµСЂРІРµСЂ РјРѕР¶РµС‚ РІРµСЂРЅСѓС‚СЊ РїРµСЂСЃРѕРЅР°Р¶Р° РЅР°Р·Р°Рґ.",1)
end
SettingsBuilders.Speed=function(parent) slider(parent,"Walk speed","Speed.Value",1,150,1,1) end
SettingsBuilders.Jump=function(parent)
    slider(parent,"JumpPower","Jump.Power",1,200,1,1)
    slider(parent,"JumpHeight","Jump.Height",1,100,1,2)
    note(parent,"РЎРєСЂРёРїС‚ РЅРµ РјРµРЅСЏРµС‚ UseJumpPower: РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ СЂРµР¶РёРј РїСЂС‹Р¶РєР°, СѓСЃС‚Р°РЅРѕРІР»РµРЅРЅС‹Р№ СЃР°РјРѕР№ РёРіСЂРѕР№.",3)
end
SettingsBuilders.InfinityJump=function(parent)
    note(parent,"РќР°Р¶РёРјР°Р№ СЃС‚Р°РЅРґР°СЂС‚РЅСѓСЋ РєРЅРѕРїРєСѓ РїСЂС‹Р¶РєР° РїРѕРІС‚РѕСЂРЅРѕ, РІ С‚РѕРј С‡РёСЃР»Рµ РІ РІРѕР·РґСѓС…Рµ. Р Р°Р±РѕС‚Р°РµС‚ С‡РµСЂРµР· JumpRequest. Р’Рѕ РІСЂРµРјСЏ Fly РїСЂРёРѕСЃС‚Р°РЅРѕРІР»РµРЅРѕ.",1)
end
SettingsBuilders.Fly=function(parent)
    slider(parent,"Flight speed","Fly.Speed",5,200,5,1)
    slider(parent,"Vertical speed","Fly.VerticalSpeed",5,150,5,2)
    note(parent,"РњРѕР±РёР»СЊРЅС‹Р№ РґР¶РѕР№СЃС‚РёРє: РґРІРёР¶РµРЅРёРµ. РљРЅРѕРїРєРё в†‘ / в†“: РІС‹СЃРѕС‚Р°. РќР° РџРљ: WASD, Space Рё LeftCtrl. РСЃРїРѕР»СЊР·СѓСЋС‚СЃСЏ LinearVelocity Рё AlignOrientation.",3)
end
SettingsBuilders.Fullbright=function(parent)
    slider(parent,"Brightness","Fullbright.Brightness",0,5,0.1,1)
    slider(parent,"Clock time","Fullbright.ClockTime",0,24,0.25,2)
    toggle(parent,"Remove classic fog","Fullbright.NoFog",nil,nil,3)
    note(parent,"Atmosphere Рё РїРѕСЃС‚СЌС„С„РµРєС‚С‹ РёРіСЂС‹ РЅРµ СѓРґР°Р»СЏСЋС‚СЃСЏ. РџСЂРё РІС‹РєР»СЋС‡РµРЅРёРё РІРѕСЃСЃС‚Р°РЅР°РІР»РёРІР°СЋС‚СЃСЏ СЃРѕС…СЂР°РЅС‘РЅРЅС‹Рµ СЃРІРѕР№СЃС‚РІР° Lighting.",4)
end
SettingsBuilders.Skybox=function(parent)
    dropdown(parent,"Sky preset","Skybox.Preset",{"Nebula","Classic","Custom"},1)
    slider(parent,"Star count","Skybox.Stars",0,10000,100,2)
    local faces={"Bk","Dn","Ft","Lf","Rt","Up"}
    for i,face in ipairs(faces) do textbox(parent,"Custom / "..face,"Skybox."..face,"Texture ID",i+2) end
    note(parent,"Custom РёСЃРїРѕР»СЊР·СѓРµС‚ С€РµСЃС‚СЊ Texture ID. РћР±Р»Р°С‡РЅС‹Рµ СЃР»РѕРё Рё Atmosphere РјРѕРіСѓС‚ Р·Р°РєСЂС‹РІР°С‚СЊ РЅРµР±Рѕ. Р”РѕСЃС‚СѓРїРЅРѕСЃС‚СЊ РІРЅРµС€РЅРёС… Р°СЃСЃРµС‚РѕРІ Р·Р°РІРёСЃРёС‚ РѕС‚ Roblox.",9)
end
SettingsBuilders.Music=function(parent)
    textbox(parent,"Audio asset ID","Music.Id","РќР°РїСЂРёРјРµСЂ: 123456789",1)
    slider(parent,"Volume","Music.Volume",0,1,0.05,2)
    slider(parent,"Playback speed","Music.PlaybackSpeed",0.25,2,0.05,3)
    toggle(parent,"Loop","Music.Loop",nil,nil,4)
    action(parent,"Pause / Resume",function()
        if not Config.Music.Enabled then toast("РЎРЅР°С‡Р°Р»Р° РІРєР»СЋС‡Рё Music Рё СѓРєР°Р¶Рё Audio ID"); return end
        State.MusicPaused=not State.MusicPaused
        if State.MusicPaused then MusicSound:Pause() else MusicSound:Resume() end
        toast(State.MusicPaused and "РњСѓР·С‹РєР° РЅР° РїР°СѓР·Рµ" or "Р’РѕСЃРїСЂРѕРёР·РІРµРґРµРЅРёРµ РїСЂРѕРґРѕР»Р¶РµРЅРѕ")
    end,5)
    action(parent,"Restart track",function() MusicSound.TimePosition=0; State.MusicPaused=false; applyMusic() end,6)
    note(parent,"РСЃРїРѕР»СЊР·СѓР№ Р°СѓРґРёРѕ, СЂР°Р·СЂРµС€С‘РЅРЅРѕРµ РґР»СЏ СЌС‚РѕР№ РёРіСЂС‹. РЎРєСЂРёРїС‚ РЅРµ РѕР±С…РѕРґРёС‚ РїСЂРёРІР°С‚РЅРѕСЃС‚СЊ Рё РѕРіСЂР°РЅРёС‡РµРЅРёСЏ Roblox Audio.",7)
end
SettingsBuilders.Crosshair=function(parent)
    slider(parent,"Line size","Crosshair.Size",2,20,1,1)
    slider(parent,"Center gap","Crosshair.Gap",0,20,1,2)
end
SettingsBuilders.Camera=function(parent) slider(parent,"Camera field of view","Camera.FOV",40,110,1,1) end
SettingsBuilders.FOVCircle=function(parent) slider(parent,"Aim FOV radius","AimBot.FOV",30,450,5,1) end
SettingsBuilders.FPS=function(parent) note(parent,"Р РµР°Р»СЊРЅС‹Р№ СЃС‡С‘С‚С‡РёРє РєР°РґСЂРѕРІ RenderStepped, СѓСЃСЂРµРґРЅРµРЅРёРµ Р·Р° 0.5 СЃРµРєСѓРЅРґС‹. Р­С‚Рѕ РЅРµ FPS unlocker.",1) end
SettingsBuilders.Ping=function(parent) note(parent,"Р§РёС‚Р°РµС‚ Stats.Network / Data Ping, РµСЃР»Рё РєР»РёРµРЅС‚ СЂР°Р·СЂРµС€Р°РµС‚. РџСЂРё РѕС‚СЃСѓС‚СЃС‚РІРёРё РґРѕСЃС‚СѓРїР° РїРѕРєР°Р·С‹РІР°РµС‚ --, Р±РµР· РІС‹РґСѓРјР°РЅРЅРѕРіРѕ Р·РЅР°С‡РµРЅРёСЏ.",1) end
SettingsBuilders.Interface=function(parent)
    dropdown(parent,"Accent palette","UI.Accent",{"Violet","Cyan","Crimson","Gold"},1)
    slider(parent,"Window transparency","UI.Transparency",0,0.35,0.01,2)
    toggle(parent,"Interface animations","UI.Animations",nil,nil,3)
    action(parent,"Р’РµСЂРЅСѓС‚СЊ РѕРєРЅРѕ Рё РєРЅРѕРїРєСѓ РІ С†РµРЅС‚СЂ",function()
        rawSet("UI.ButtonX",0.08); set("UI.ButtonY",0.45); layout(true)
    end,4)
    note(parent,"E: РѕС‚РєСЂС‹С‚СЊ / СЃРІРµСЂРЅСѓС‚СЊ. РљРЅРѕРїРєСѓ E Рё Р·Р°РіРѕР»РѕРІРѕРє РѕРєРЅР° РјРѕР¶РЅРѕ РїРµСЂРµС‚Р°СЃРєРёРІР°С‚СЊ. RightShift РЅР° РџРљ С‚Р°РєР¶Рµ РїРµСЂРµРєР»СЋС‡Р°РµС‚ РѕРєРЅРѕ.",5)
end
closeSettings=function()
    closePicker()
    if State.Sheet then State.Sheet:Destroy(); State.Sheet=nil end
end
openSettings=function(key)
    closeSettings()
    local builder=SettingsBuilders[key]
    if not builder then return end
    local backdrop=button(Gui,"",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(),BackgroundTransparency=0.38,ZIndex=35})
    State.Sheet=backdrop
    local v=viewport(); local width=math.min(390,v.X-22); local height=math.min(560,v.Y-28)
    local panel=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromOffset(width,height),BackgroundColor3=Color3.fromRGB(17,21,34),BorderSizePixel=0,ZIndex=36,Active=true},backdrop)
    corner(panel,18); stroke(panel,accent(),0.4)
    label(panel,key=="Target" and "Р¦РµР»СЊ / Target" or key,21,TEXT,{Position=UDim2.fromOffset(18,12),Size=UDim2.new(1,-76,0,29),
        Font=Enum.Font.GothamBold,ZIndex=37})
    label(panel,"FEATURE SETTINGS",9,MUTED,{Position=UDim2.fromOffset(19,43),Size=UDim2.new(1,-70,0,16),Font=Enum.Font.Code,ZIndex=37})
    local close=button(panel,"Г—",{Position=UDim2.new(1,-53,0,16),Size=UDim2.fromOffset(36,36),TextSize=25,ZIndex=37})
    bind(close.Activated,closeSettings); bind(backdrop.Activated,closeSettings)
    local scroll=new("ScrollingFrame",{Position=UDim2.fromOffset(13,73),Size=UDim2.new(1,-26,1,-87),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=accent(),
        CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=37},panel)
    new("UIListLayout",{Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
    new("UIPadding",{PaddingRight=UDim.new(0,5),PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,12)},scroll)
    builder(scroll)
    if Config.UI.Animations then
        panel.Position=UDim2.new(0.5,0,0.5,16)
        animate(panel,{Position=UDim2.fromScale(0.5,0.5)},0.23)
    end
end
local function loadConfig()
    if not CAN_SAVE then toast("Р—Р°РіСЂСѓР·РєР° СЃ РґРёСЃРєР° РЅРµРґРѕСЃС‚СѓРїРЅР°: РЅРµС‚ readfile/writefile",true); return end
    local ok,result=pcall(function() return HttpService:JSONDecode(API.read(FILE)) end)
    if not ok or type(result)~="table" or (result.Version and result.Version~=1) then toast("РќРµС‚ РєРѕСЂСЂРµРєС‚РЅРѕРіРѕ С„Р°Р№Р»Р° РєРѕРЅС„РёРіСѓСЂР°С†РёРё v1",true); return end
    Config=merge(copy(Defaults),result); normalize()
    if not State.HookReady then Config.SilentAim.Enabled=false end
    State.Target=nil; State.Dirty=false; State.MusicPaused=false
    applyConfig(); closeSettings(); rebuildPage(); layout(false); refreshUI()
    toast("РљРѕРЅС„РёРіСѓСЂР°С†РёСЏ Р·Р°РіСЂСѓР¶РµРЅР°")
end
local function resetConfig()
    choose("РЎР±СЂРѕСЃРёС‚СЊ РЅР°СЃС‚СЂРѕР№РєРё?",{{Value=false,Label="РћС‚РјРµРЅР°"},{Value=true,Label="Р”Р°, РІРѕСЃСЃС‚Р°РЅРѕРІРёС‚СЊ СЃС‚Р°РЅРґР°СЂС‚РЅС‹Рµ"}},false,function(confirm)
        if not confirm then return end
        Config=copy(Defaults); State.Target=nil; State.MusicPaused=false
        State.Dirty=true; State.ChangedAt=os.clock()
        applyConfig(); closeSettings(); rebuildPage(); layout(true); refreshUI(); saveConfig(true)
        toast("РќР°СЃС‚СЂРѕР№РєРё СЃР±СЂРѕС€РµРЅС‹. Р’СЃРµ С„СѓРЅРєС†РёРё РІРјРµС€Р°С‚РµР»СЊСЃС‚РІР° РІС‹РєР»СЋС‡РµРЅС‹")
    end)
end
local function clearContent()
    for _,child in ipairs(Content:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
end
rebuildPage=function()
    clearContent(); Content.CanvasPosition=Vector2.zero
    local tab=Config.UI.Tab
    for name,data in pairs(NavButtons) do
        data.Bar.Visible=name==tab
        data.Button.TextColor3=name==tab and accent() or MUTED
    end
    if tab=="Main" then
        section(Content,"TARGET / COMBAT",1)
        local targetRow=row(Content,70,2)
        label(targetRow,"Р¦РµР»СЊ / Target",14,TEXT,{Position=UDim2.fromOffset(13,8),Size=UDim2.new(1,-66,0,25),
            Font=Enum.Font.GothamMedium,ZIndex=8})
        local targetText=label(targetRow,"",10,MUTED,{Position=UDim2.fromOffset(13,36),Size=UDim2.new(1,-67,0,22),
            TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=8})
        refreshRegister(targetRow,function()
            local p=Players:GetPlayerByUserId(Config.Target.UserId)
            targetText.Text=Config.Target.UserId==0 and "Auto / closest to crosshair" or (p and "@"..p.Name or "РРіСЂРѕРє РЅРµ РІ СЃРµСЂРІРµСЂРµ")
        end)
        local gear=button(targetRow,"вљ™",{Position=UDim2.new(1,-54,0.5,-21),Size=UDim2.fromOffset(42,42),TextSize=23,ZIndex=8})
        bind(gear.Activated,function() openSettings("Target") end)
        toggle(Content,"AimBot","AimBot.Enabled","Camera aim / mobile hold","AimBot",3)
        toggle(Content,"SilentAim","SilentAim.Enabled",State.HookReady and "Legacy Mouse adapter only" or "Executor API unavailable","SilentAim",4)
        toggle(Content,"TriggerBot","TriggerBot.Enabled","Center-screen activation","TriggerBot",5)
        toggle(Content,"Target HUD","Target.ShowHUD","Name / health / distance","Target",6)
        note(Content,"РћС‚РєСЂРѕР№ вљ™ Сѓ С„СѓРЅРєС†РёРё РґР»СЏ РµС‘ РЅР°СЃС‚СЂРѕРµРє. РќР°С‡РЅРё СЃ РІС‹Р±РѕСЂР° С†РµР»Рё Рё РѕР±С‰РёС… С„РёР»СЊС‚СЂРѕРІ AimBot.",7)
    elseif tab=="Movement" then
        section(Content,"CHARACTER / MOVEMENT",1)
        toggle(Content,"Noclip","Noclip.Enabled","Character collision control","Noclip",2)
        toggle(Content,"Speed","Speed.Enabled","WalkSpeed override","Speed",3)
        toggle(Content,"Jump","Jump.Enabled","JumpPower + JumpHeight","Jump",4)
        toggle(Content,"Infinity Jump","InfinityJump.Enabled","Repeat jump while airborne","InfinityJump",5)
        toggle(Content,"Fly","Fly.Enabled","Thumbstick + vertical controls","Fly",6)
        note(Content,"РџРµСЂСЃРѕРЅР°Р¶ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё РїРµСЂРµРїРѕРґРєР»СЋС‡Р°РµС‚СЃСЏ РїРѕСЃР»Рµ РІРѕР·СЂРѕР¶РґРµРЅРёСЏ. РЎРµСЂРІРµСЂ РјРѕР¶РµС‚ РѕРіСЂР°РЅРёС‡РёРІР°С‚СЊ РєР»РёРµРЅС‚СЃРєРѕРµ РґРІРёР¶РµРЅРёРµ.",7)
    elseif tab=="Visuals" then
        section(Content,"WORLD / OVERLAYS",1)
        toggle(Content,"ESP","ESP.Enabled","Highlight / names / health","ESP",2)
        toggle(Content,"Fullbright","Fullbright.Enabled","Lighting override","Fullbright",3)
        toggle(Content,"Skybox","Skybox.Enabled","Presets + six custom faces","Skybox",4)
        toggle(Content,"Crosshair","Crosshair.Enabled","Custom center crosshair","Crosshair",5)
        toggle(Content,"Aim FOV Circle","FOVCircle.Enabled","Target acquisition radius","FOVCircle",6)
        toggle(Content,"Camera FOV","Camera.Enabled","Adjust camera field of view","Camera",7)
        toggle(Content,"FPS","FPS.Enabled",nil,"FPS",8)
        toggle(Content,"Ping","Ping.Enabled",nil,"Ping",9)
    else
        section(Content,"PERSONALIZATION / CONFIG",1)
        action(Content,"вљ™  Interface settings",function() openSettings("Interface") end,2)
        toggle(Content,"Music","Music.Enabled","Local audio player","Music",3)
        action(Content,"Save configuration",function() saveConfig(false) end,4)
        action(Content,"Load configuration",loadConfig,5)
        action(Content,"Reset configuration",resetConfig,6,true)
        action(Content,"Copy configuration JSON",function()
            if type(API.clipboard)~="function" then toast("setclipboard РЅРµ РїРѕРґРґРµСЂР¶РёРІР°РµС‚СЃСЏ",true); return end
            local ok=pcall(API.clipboard,HttpService:JSONEncode(Config))
            toast(ok and "JSON СЃРєРѕРїРёСЂРѕРІР°РЅ" or "РќРµС‚ РґРѕСЃС‚СѓРїР° Рє Р±СѓС„РµСЂСѓ РѕР±РјРµРЅР°",not ok)
        end,7)
        action(Content,"Disable active features",function()
            for _,name in ipairs({"AimBot","SilentAim","TriggerBot","ESP","Noclip","Speed","Jump","InfinityJump","Fly","Fullbright","Skybox","Music","Camera"}) do Config[name].Enabled=false end
            Config.Target.Spectate=false
            State.Dirty=true; State.ChangedAt=os.clock()
            applyConfig(); refreshUI(); toast("РђРєС‚РёРІРЅС‹Рµ С„СѓРЅРєС†РёРё РІС‹РєР»СЋС‡РµРЅС‹")
        end,8,true)
        action(Content,"Unload EspadaWare",function()
            choose("Р—Р°РІРµСЂС€РёС‚СЊ EspadaWare?",{{Value=false,Label="РћС‚РјРµРЅР°"},{Value=true,Label="Р”Р°, СѓР±СЂР°С‚СЊ GUI Рё РІРѕСЃСЃС‚Р°РЅРѕРІРёС‚СЊ СЃРІРѕР№СЃС‚РІР°"}},false,function(confirm)
                if confirm then State.Unload() end
            end)
        end,9,true)
        note(Content,(CAN_SAVE and "AUTOSAVE: ON / "..FILE or "AUTOSAVE: unavailable / no file APIs").."\nSingle client script вЂў no external libraries",10)
    end
    refreshUI()
end
selectTab=function(name)
    if not table.find(Enums["UI.Tab"],name) then return end
    rawSet("UI.Tab",name); State.Dirty=true; State.ChangedAt=os.clock()
    closeSettings(); rebuildPage()
end

applyConfig=function(path)
    local group=path and path:match("^[^.]+") or nil
    if not group or group=="UI" then
        Main.Visible=Config.UI.Open; Main.BackgroundTransparency=Config.UI.Transparency
        if not Config.UI.Open then closeSettings() end
        Content.ScrollBarImageColor3=accent()
        for i=#State.AccentBindings,1,-1 do
            local item=State.AccentBindings[i]
            if item[1].Parent then item[1][item[2]]=accent() else table.remove(State.AccentBindings,i) end
        end
        for name,data in pairs(NavButtons) do data.Button.TextColor3=name==Config.UI.Tab and accent() or MUTED end
        placeLauncher()
    end
    if not group or group=="Fullbright" then applyLighting() end
    if not group or group=="Skybox" then applySky() end
    if not group or group=="Music" then
        if path=="Music.Enabled" then State.MusicPaused=false end
        applyMusic()
        if Config.Music.Enabled and asset(Config.Music.Id)=="" then toast("Music: СѓРєР°Р¶Рё Audio ID С‡РµСЂРµР· вљ™",true) end
    end
    if not group or group=="Target" then
        State.Target=nil
        if Config.Target.Spectate then toast("Spectate РІРєР»СЋС‡С‘РЅ. РљР°РјРµСЂРЅРѕРµ РЅР°РІРµРґРµРЅРёРµ РІСЂРµРјРµРЅРЅРѕ РїСЂРёРѕСЃС‚Р°РЅРѕРІР»РµРЅРѕ") end
    end
    if not Config.Noclip.Enabled then restoreCollisions() end
    if not Config.Fly.Enabled then stopFly() end
    FlyPad.Visible=Config.Fly.Enabled
    AimHold.Visible=Config.AimBot.Enabled and Config.AimBot.Mode=="WhileAiming"
    Crosshair.Visible=Config.Crosshair.Enabled
    local s,g=Config.Crosshair.Size,Config.Crosshair.Gap
    CrossLines[1].Position=UDim2.fromOffset(-g-s,-1); CrossLines[1].Size=UDim2.fromOffset(s,2)
    CrossLines[2].Position=UDim2.fromOffset(g,-1); CrossLines[2].Size=UDim2.fromOffset(s,2)
    CrossLines[3].Position=UDim2.fromOffset(-1,-g-s); CrossLines[3].Size=UDim2.fromOffset(2,s)
    CrossLines[4].Position=UDim2.fromOffset(-1,g); CrossLines[4].Size=UDim2.fromOffset(2,s)
    FOVRing.Visible=Config.FOVCircle.Enabled
    FOVRing.Size=UDim2.fromOffset(Config.AimBot.FOV*2,Config.AimBot.FOV*2)
    Metrics.Visible=Config.FPS.Enabled or Config.Ping.Enabled
    if not Config.Target.ShowHUD then HUD.Visible=false end
end

-- Central loops. Each subsystem is isolated so one unsupported API does not kill GUI.
local function safe(key,fn,...)
    local ok,err=pcall(fn,...)
    if not ok then
        rateError(key,"РћС€РёР±РєР° РјРѕРґСѓР»СЏ "..key..". РџРѕРґСЂРѕР±РЅРѕСЃС‚Рё РІ РєРѕРЅСЃРѕР»Рё executor")
        local now=os.clock()
        if not State.Errors[key.."Log"] or now-State.Errors[key.."Log"]>8 then
            State.Errors[key.."Log"]=now; warn("[EspadaWare / "..key.."]",err)
        end
    end
end
local targetElapsed,espElapsed,metricsElapsed,lightElapsed=0,0,0,0
local frames,frameElapsed=0,0
local lastViewport=viewport()
bind(RunService.Stepped,function()
    if State.Alive then safe("Movement",movementStep) end
end)
bind(RunService.Heartbeat,function(dt)
    if not State.Alive then return end
    targetElapsed=targetElapsed+dt; espElapsed=espElapsed+dt; metricsElapsed=metricsElapsed+dt; lightElapsed=lightElapsed+dt
    if targetElapsed>=0.075 then
        targetElapsed=0
        safe("Target",function()
            local needed=Config.AimBot.Enabled or Config.SilentAim.Enabled or Config.TriggerBot.Enabled or Config.Target.ShowHUD or Config.Target.Spectate
            State.Target=needed and acquireTarget() or nil
            State.SilentPass=math.random()*100<Config.SilentAim.Chance
            updateHUD()
        end)
    end
    if espElapsed>=0.18 then espElapsed=0; safe("ESP",espStep) end
    if lightElapsed>=0.4 then lightElapsed=0; if Config.Fullbright.Enabled then safe("Lighting",applyLighting) end end
    safe("TriggerBot",triggerStep)
    if metricsElapsed>=0.5 then
        metricsElapsed=0
        -- Purge disconnected/destroyed UI references after rebuilding pages or sheets.
        for i=#State.Connections,1,-1 do
            if not State.Connections[i].Connected then table.remove(State.Connections,i) end
        end
        for i=#State.Refreshers,1,-1 do
            if not State.Refreshers[i][1].Parent then table.remove(State.Refreshers,i) end
        end
        for i=#State.AccentBindings,1,-1 do
            if not State.AccentBindings[i][1].Parent then table.remove(State.AccentBindings,i) end
        end
        if Config.Ping.Enabled then
            local ok,ping=pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
            State.Ping=ok and type(ping)=="number" and ping or nil
        end
        local parts={}
        if Config.FPS.Enabled then table.insert(parts,string.format("%d FPS",State.FPS)) end
        if Config.Ping.Enabled then table.insert(parts,State.Ping and string.format("%d MS",math.floor(State.Ping+0.5)) or "PING --") end
        MetricsText.Text=table.concat(parts,"   |   ")
        local v=viewport()
        if (v-lastViewport).Magnitude>1 then lastViewport=v; layout(false); closeSettings() end
    end
    if State.Dirty and os.clock()-State.ChangedAt>=0.8 and CAN_SAVE then
        State.ChangedAt=os.clock()+4 -- Back off if disk writes fail.
        saveConfig(true)
    end
end)
local RENDER_NAME="EspadaWareCamera_"..tostring(LocalPlayer.UserId)
RunService:BindToRenderStep(RENDER_NAME,Enum.RenderPriority.Camera.Value+1,function(dt)
    if not State.Alive then return end
    frames=frames+1; frameElapsed=frameElapsed+dt
    if frameElapsed>=0.5 then State.FPS=math.floor(frames/frameElapsed+0.5); frames=0; frameElapsed=0 end
    safe("Camera",function()
        cameraSettings()
        if not Config.AimBot.Enabled or Config.UI.Open or State.Sheet or State.Picker or Config.Target.Spectate then return end
        if UserInputService:GetFocusedTextBox() then return end
        local held=State.Aiming or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        if Config.AimBot.Mode=="WhileAiming" and not held then return end
        local target=State.Target
        local part=target and aimPart(target)
        local camera=workspace.CurrentCamera
        if not part or not camera then return end
        if (part.Position-camera.CFrame.Position).Magnitude<0.05 then return end
        local desired=CFrame.lookAt(camera.CFrame.Position,part.Position)
        camera.CFrame=camera.CFrame:Lerp(desired,1-math.exp(-Config.AimBot.Smoothness*dt))
    end)
end)
bind(UserInputService.InputBegan,function(input,processed)
    if not processed and input.KeyCode==Enum.KeyCode.RightShift then toggleWindow() end
end)
State.Unload=function()
    if not State.Alive then return end
    if State.Dirty then saveConfig(true) end
    State.Alive=false
    if HookRegistry then HookRegistry.Resolve=nil end -- Installed wrapper stays inert; avoids damaging another script's hook chain.
    RunService:UnbindFromRenderStep(RENDER_NAME)
    for _,connection in ipairs(State.Connections) do pcall(function() connection:Disconnect() end) end
    State.Connections={}
    pcall(restoreMovement); pcall(restoreCamera); pcall(restoreSky)
    for key,value in pairs(LightOriginal) do pcall(function() Lighting[key]=value end) end
    LightOriginal={}
    for player in pairs(State.ESP) do pcall(removeESP,player) end
    pcall(function() ESPFolder:Destroy() end)
    pcall(function() MusicSound:Stop(); MusicSound:Destroy() end)
    pcall(function() Gui:Destroy() end)
    if ENV.__EspadaWareRuntime==State then ENV.__EspadaWareRuntime=nil end
end
bind(LocalPlayer.CharacterRemoving,function() safe("RespawnCleanup",restoreMovement) end)
applyConfig(); rebuildPage(); refreshUI()
toast("EspadaWare РіРѕС‚РѕРІ. РљРЅРѕРїРєР° E РѕС‚РєСЂС‹РІР°РµС‚ GUI; вљ™ РѕС‚РєСЂС‹РІР°РµС‚ РЅР°СЃС‚СЂРѕР№РєРё")
if loadNotice then task.delay(1,function() if State.Alive then toast(loadNotice) end end) end
if not CAN_SAVE then task.delay(2,function() if State.Alive then toast("Р¤Р°Р№Р»РѕРІС‹Рµ API РѕС‚СЃСѓС‚СЃС‚РІСѓСЋС‚: СЃРѕС…СЂР°РЅРµРЅРёРµ РјРµР¶РґСѓ Р·Р°РїСѓСЃРєР°РјРё РЅРµРґРѕСЃС‚СѓРїРЅРѕ",true) end end) end
if Config.SilentAim.Enabled then task.delay(2,function() if State.Alive then toast("SilentAim: Р°РєС‚РёРІРµРЅ С‚РѕР»СЊРєРѕ Р°РґР°РїС‚РµСЂ Legacy Mouse, РЅРµ СѓРЅРёРІРµСЂСЃР°Р»СЊРЅР°СЏ РїРѕРґРјРµРЅР° РІС‹СЃС‚СЂРµР»РѕРІ") end end) end
