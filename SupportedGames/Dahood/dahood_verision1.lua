-- Tetoware - Version 1.0 Beta
-- This script is licensed under GNU GPL and is created by Eclipse Team

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    LocalPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

local SCRIPT_VERSION = "1.0 Beta"
local DONATION_PRODUCT_ID = 3715327753
local GAMEPASS_ID = 1891025004
local GAMEPASS_URL = "https://www.roblox.com/game-pass/" .. GAMEPASS_ID
local SAVE_FOLDER = "Tetoware"
local DONATE_FLAG_FILE = SAVE_FOLDER .. "/donate_popup.txt"
local THEME_FILE = SAVE_FOLDER .. "/theme.txt"
local REPO_URL = "https://github.com/InfinitelyMNDEV/catware"
local TOGGLE_KEY = Enum.KeyCode.RightShift
local WINDOW_ICON = "rbxassetid://125388499892456"
local BG_TRANSPARENCY = 0.5
local ACCENT = Color3.fromHex("#d92b2b")

local WINDUI_URLS = {
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
}

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local WindUI = nil
local winduiReady = false
local winduiFailed = false
local window = nil
local popupGui = nil
local popupOpen = false
local purchaseConn = nil
local bgEnabled = true
local scriptActive = true

local openMainUI
local showDonationPopup
local unloadAll

local function tryLoadWindUI()
    for _, url in ipairs(WINDUI_URLS) do
        local ok, lib = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if ok and type(lib) == "table" then
            WindUI = lib
            winduiReady = true
            return
        end
    end
    winduiFailed = true
end

local function notify(title, content, icon)
    if WindUI then
        local ok = pcall(function()
            WindUI:Notify({
                Title = title,
                Content = content,
                Icon = icon or "info",
                Duration = 5,
            })
        end)
        if ok then return end
    end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = content,
            Duration = 5,
        })
    end)
end

local function copyToClipboard(text)
    if type(setclipboard) == "function" then
        if pcall(setclipboard, text) then return true end
    end
    if type(toclipboard) == "function" then
        if pcall(toclipboard, text) then return true end
    end
    return false
end

local function round(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
end

local function ensureFolder()
    if type(makefolder) ~= "function" or type(isfolder) ~= "function" then return end
    pcall(function()
        if not isfolder(SAVE_FOLDER) then
            makefolder(SAVE_FOLDER)
        end
    end)
end

local function saveNeverShow()
    if type(writefile) ~= "function" then return end
    pcall(function()
        ensureFolder()
        writefile(DONATE_FLAG_FILE, "1")
    end)
end

local function neverShowSaved()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return false end
    local ok, saved = pcall(function()
        return isfile(DONATE_FLAG_FILE) and readfile(DONATE_FLAG_FILE) == "1"
    end)
    return ok and saved == true
end

local function getGuiParent()
    local candidates = {}
    if type(gethui) == "function" then
        local ok, ui = pcall(gethui)
        if ok and ui then table.insert(candidates, ui) end
    end
    pcall(function() table.insert(candidates, game:GetService("CoreGui")) end)
    pcall(function() table.insert(candidates, LocalPlayer:FindFirstChildOfClass("PlayerGui")) end)
    for _, parent in ipairs(candidates) do
        local probe = Instance.new("Folder")
        local ok = pcall(function() probe.Parent = parent end)
        probe:Destroy()
        if ok then return parent end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local THEME_LIST = {
    {
        Name = "Tetoware - Default",
        BackgroundImage = "rbxassetid://80972127695198",
        Accent = Color3.fromHex("#d92b2b"),
        Background = Color3.fromHex("#0b0a0a"),
        Outline = Color3.fromHex("#2a2222"),
        Text = Color3.fromHex("#ecd2d2"),
        Placeholder = Color3.fromHex("#7d6b6b"),
        Button = Color3.fromHex("#1a1515"),
        Icon = Color3.fromHex("#e06666"),
    },
    {
        Name = "Mikuware",
        BackgroundImage = "rbxassetid://70765001618542",
        Accent = Color3.fromHex("#39c5bb"),
        Background = Color3.fromHex("#080d0d"),
        Outline = Color3.fromHex("#1e2a29"),
        Text = Color3.fromHex("#cfe9e6"),
        Placeholder = Color3.fromHex("#6a7d7b"),
        Button = Color3.fromHex("#121a19"),
        Icon = Color3.fromHex("#7fd0c9"),
    },
    {
        Name = "Neruware",
        BackgroundImage = "rbxassetid://71612740868945",
        Accent = Color3.fromHex("#e3b400"),
        Background = Color3.fromHex("#0d0b08"),
        Outline = Color3.fromHex("#2a241a"),
        Text = Color3.fromHex("#ece0c4"),
        Placeholder = Color3.fromHex("#7d7466"),
        Button = Color3.fromHex("#1a1710"),
        Icon = Color3.fromHex("#d6bf7c"),
    },
}

local THEME_NAMES = {}
local THEME_IMAGES = {}
for _, t in ipairs(THEME_LIST) do
    table.insert(THEME_NAMES, t.Name)
    THEME_IMAGES[t.Name] = t.BackgroundImage
end

local function registerThemes()
    if not WindUI then return end
    for _, tbl in ipairs(THEME_LIST) do
        pcall(function()
            WindUI:AddTheme(tbl)
        end)
    end
end

local function saveTheme(name)
    if type(writefile) ~= "function" then return end
    pcall(function()
        ensureFolder()
        writefile(THEME_FILE, name)
    end)
end

local function loadSavedTheme()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return nil end
    local ok, name = pcall(function()
        if isfile(THEME_FILE) then
            return readfile(THEME_FILE)
        end
        return nil
    end)
    if ok and type(name) == "string" then
        for _, t in ipairs(THEME_LIST) do
            if t.Name == name then return name end
        end
    end
    return nil
end

local function applyBackground(themeName)
    local img = THEME_IMAGES[themeName] or THEME_IMAGES["Tetoware - Default"]
    if window and img then
        pcall(function()
            window:SetBackgroundImage(img)
            window:SetBackgroundImageTransparency(bgEnabled and BG_TRANSPARENCY or 1)
        end)
    end
end

local PALETTE = {
    confirm = Color3.fromHex("#1F7A44"),
    confirmHover = Color3.fromHex("#289457"),
    decline = Color3.fromHex("#26262D"),
    declineHover = Color3.fromHex("#303038"),
    bg = Color3.fromHex("#101013"),
    stroke = Color3.fromHex("#33272B"),
    text = Color3.fromHex("#ECEBEF"),
    body = Color3.fromHex("#C7C5CC"),
    subtext = Color3.fromHex("#8B8994"),
    accent = ACCENT,
    red = Color3.fromHex("#FF6B7E"),
}

showDonationPopup = function()
    if popupOpen then return end
    popupOpen = true

    local cam = Workspace.CurrentCamera
    local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
    local uiScale = math.clamp(math.min(vp.X, vp.Y) / 700, 0.8, 1.15)

    local gui = Instance.new("ScreenGui")
    gui.Name = "Tetoware_Donate"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = getGuiParent()
    popupGui = gui

    task.delay(1, function()
        if not popupOpen then return end
        if gui.Parent == nil or not gui:IsDescendantOf(game) then
            pcall(function()
                gui.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or game:GetService("CoreGui")
            end)
        end
    end)

    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = UDim2.new(0.5, 0, 0.5, 8)
    holder.Size = UDim2.fromOffset(360, 244)
    holder.BackgroundTransparency = 1
    holder.Parent = gui

    local scale = Instance.new("UIScale")
    scale.Scale = uiScale * 0.96
    scale.Parent = holder

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.fromOffset(360, 244)
    card.BackgroundColor3 = PALETTE.bg
    card.BorderSizePixel = 0
    card.Parent = holder

    round(card, 10)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = PALETTE.stroke
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(24, 20)
    title.Size = UDim2.fromOffset(240, 20)
    title.Font = Enum.Font.GothamBold
    title.Text = "Support Tetoware"
    title.TextSize = 16
    title.TextColor3 = PALETTE.text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card

    local message = Instance.new("TextLabel")
    message.BackgroundTransparency = 1
    message.Position = UDim2.fromOffset(24, 46)
    message.Size = UDim2.new(1, -48, 0, 70)
    message.Font = Enum.Font.Gotham
    message.Text = "Hey! This script is an open source meaning we won't make that much of an income of it so if possible please consider donating to us to support us!"
    message.TextSize = 13
    message.TextColor3 = PALETTE.body
    message.TextWrapped = true
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextYAlignment = Enum.TextYAlignment.Top
    message.Parent = card

    local checkBtn = Instance.new("TextButton")
    checkBtn.BackgroundTransparency = 1
    checkBtn.Position = UDim2.fromOffset(24, 124)
    checkBtn.Size = UDim2.fromOffset(280, 24)
    checkBtn.Text = ""
    checkBtn.AutoButtonColor = false
    checkBtn.Parent = card

    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(18, 18)
    box.Position = UDim2.fromOffset(0, 3)
    box.BackgroundColor3 = PALETTE.bg
    box.BorderSizePixel = 0
    round(box, 5)
    box.Parent = checkBtn

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = PALETTE.stroke
    boxStroke.Thickness = 1.5
    boxStroke.Parent = box

    local tickA = Instance.new("Frame")
    tickA.Size = UDim2.fromOffset(2, 5)
    tickA.Position = UDim2.fromOffset(4, 9)
    tickA.Rotation = -45
    tickA.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tickA.BorderSizePixel = 0
    tickA.BackgroundTransparency = 1
    tickA.Parent = box

    local tickB = Instance.new("Frame")
    tickB.Size = UDim2.fromOffset(2, 9)
    tickB.Position = UDim2.fromOffset(9, 4)
    tickB.Rotation = 45
    tickB.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tickB.BorderSizePixel = 0
    tickB.BackgroundTransparency = 1
    tickB.Parent = box

    local checkLabel = Instance.new("TextLabel")
    checkLabel.BackgroundTransparency = 1
    checkLabel.Position = UDim2.fromOffset(27, 0)
    checkLabel.Size = UDim2.fromOffset(240, 24)
    checkLabel.Font = Enum.Font.Gotham
    checkLabel.Text = "Never show this again"
    checkLabel.TextSize = 13
    checkLabel.TextColor3 = PALETTE.body
    checkLabel.TextXAlignment = Enum.TextXAlignment.Left
    checkLabel.Parent = checkBtn

    local warnBase = UDim2.fromOffset(24, 152)
    local warnLabel = Instance.new("TextLabel")
    warnLabel.BackgroundTransparency = 1
    warnLabel.Position = warnBase + UDim2.fromOffset(0, 5)
    warnLabel.Size = UDim2.new(1, -48, 0, 14)
    warnLabel.Font = Enum.Font.Gotham
    warnLabel.Text = "Are you sure? You can always donate later"
    warnLabel.TextSize = 12
    warnLabel.TextColor3 = PALETTE.red
    warnLabel.TextTransparency = 1
    warnLabel.TextXAlignment = Enum.TextXAlignment.Left
    warnLabel.Parent = card

    local nahBtn = Instance.new("TextButton")
    nahBtn.AnchorPoint = Vector2.new(0, 1)
    nahBtn.Position = UDim2.new(0, 24, 1, -20)
    nahBtn.Size = UDim2.fromOffset(130, 34)
    nahBtn.BackgroundColor3 = PALETTE.decline
    nahBtn.Text = "Nah am good"
    nahBtn.Font = Enum.Font.Gotham
    nahBtn.TextSize = 13
    nahBtn.TextColor3 = PALETTE.body
    nahBtn.AutoButtonColor = false
    round(nahBtn, 8)
    nahBtn.Parent = card

    local sureBtn = Instance.new("TextButton")
    sureBtn.AnchorPoint = Vector2.new(1, 1)
    sureBtn.Position = UDim2.new(1, -24, 1, -20)
    sureBtn.Size = UDim2.fromOffset(100, 34)
    sureBtn.BackgroundColor3 = PALETTE.confirm
    sureBtn.Text = "Sure!"
    sureBtn.Font = Enum.Font.GothamBold
    sureBtn.TextSize = 14
    sureBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sureBtn.AutoButtonColor = false
    round(sureBtn, 8)
    sureBtn.Parent = card

    sureBtn.MouseEnter:Connect(function()
        TweenService:Create(sureBtn, TweenInfo.new(0.1), { BackgroundColor3 = PALETTE.confirmHover }):Play()
    end)
    sureBtn.MouseLeave:Connect(function()
        TweenService:Create(sureBtn, TweenInfo.new(0.1), { BackgroundColor3 = PALETTE.confirm }):Play()
    end)
    nahBtn.MouseEnter:Connect(function()
        TweenService:Create(nahBtn, TweenInfo.new(0.1), { BackgroundColor3 = PALETTE.declineHover }):Play()
    end)
    nahBtn.MouseLeave:Connect(function()
        TweenService:Create(nahBtn, TweenInfo.new(0.1), { BackgroundColor3 = PALETTE.decline }):Play()
    end)

    local checked = false
    local closing = false
    local warnTween = nil

    local function setWarnVisible(show)
        if warnTween then warnTween:Cancel() end
        local goal = show
            and { TextTransparency = 0, Position = warnBase }
            or { TextTransparency = 1, Position = warnBase + UDim2.fromOffset(0, 5) }
        warnTween = TweenService:Create(warnLabel, TweenInfo.new(show and 0.25 or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
        warnTween:Play()
    end

    checkBtn.Activated:Connect(function()
        checked = not checked
        local t = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(box, t, { BackgroundColor3 = checked and PALETTE.accent or PALETTE.bg }):Play()
        TweenService:Create(boxStroke, t, { Color = checked and PALETTE.accent or PALETTE.stroke }):Play()
        TweenService:Create(tickA, t, { BackgroundTransparency = checked and 0 or 1 }):Play()
        TweenService:Create(tickB, t, { BackgroundTransparency = checked and 0 or 1 }):Play()
        setWarnVisible(checked)
    end)

    local function closePopup(onClosed)
        if closing then return end
        closing = true
        popupOpen = false
        if purchaseConn then
            purchaseConn:Disconnect()
            purchaseConn = nil
        end
        task.spawn(function()
            pcall(function()
                TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = uiScale * 0.96 }):Play()
            end)
            task.wait(0.13)
            gui:Destroy()
            if popupGui == gui then popupGui = nil end
            if onClosed then onClosed() end
        end)
    end

    nahBtn.Activated:Connect(function()
        if closing then return end
        if checked then saveNeverShow() end
        closePopup(function() openMainUI() end)
    end)

    sureBtn.Activated:Connect(function()
        if closing then return end
        if checked then saveNeverShow() end

        pcall(function()
            purchaseConn = MarketplaceService.PromptProductPurchaseFinished:Connect(function(plr, productId)
                if plr == LocalPlayer and productId == DONATION_PRODUCT_ID and popupOpen then
                    closePopup(function() openMainUI() end)
                end
            end)
        end)

        local prompted = false
        pcall(function()
            MarketplaceService:PromptProductPurchase(LocalPlayer, DONATION_PRODUCT_ID)
            prompted = true
        end)

        if copyToClipboard(GAMEPASS_URL) then
            notify("Tetoware", "donation link copied. if no purchase window opened, buy it in your browser", "heart")
        else
            notify("Tetoware", "no clipboard here. donation link: " .. GAMEPASS_URL, "heart")
        end

        if not prompted then
            closePopup(function() openMainUI() end)
            return
        end

        task.delay(12, function()
            if popupOpen then
                closePopup(function() openMainUI() end)
            end
        end)
    end)

    TweenService:Create(scale, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = uiScale }):Play()
    TweenService:Create(holder, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
end

local espSupported = false
pcall(function()
    espSupported = type(Drawing) == "table" and type(Drawing.new) == "function"
end)

local pingValue = 0
task.spawn(function()
    while scriptActive do
        pcall(function()
            local s = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
            pingValue = tonumber(string.split(s, " ")[1]) or 0
        end)
        task.wait(0.5)
    end
end)

local AUTO_PRED = {
    { 20, 0.12588 }, { 30, 0.11911 }, { 40, 0.12471 }, { 50, 0.12766 }, { 60, 0.12731 },
    { 70, 0.12951 }, { 80, 0.13181 }, { 90, 0.13573 }, { 100, 0.13334 }, { 110, 0.14552 },
    { 120, 0.14376 }, { 130, 0.15669 }, { 140, 0.12234 }, { 150, 0.15214 }, { 160, 0.16262 },
    { 170, 0.19231 }, { 180, 0.19284 }, { 190, 0.16594 }, { 200, 0.16942 },
}

local function autoPredFor()
    for _, e in ipairs(AUTO_PRED) do
        if pingValue < e[1] then return e[2] end
    end
    return 0.16942
end

local function rangePredFor(dist)
    if dist < 25 then return 0.121 end
    if dist < 60 then return 0.127 end
    if dist < 115 then return 0.131 end
    return 0.134
end

local WEAPON_FOV = {
    ["double-barrel sg"] = 22.5, ["doublebarrel"] = 22.5, revolver = 27.5, shotgun = 35,
    tacticalshotgun = 35, smg = 25, silencer = 32.5, ak47 = 12.5, ar = 12.5,
    rifle = 12, p90 = 40.2, drumgun = 60,
}

local function equippedWeaponFov()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildWhichIsA("Tool")
    if tool and string.find(tool.Name, "[", 1, true) then
        local inner = string.match(tool.Name, "%[(.-)%]")
        if inner then
            local key = string.lower(string.gsub(inner, "%s+", ""))
            return WEAPON_FOV[key]
        end
    end
    return nil
end

local function cursorPos()
    if IS_MOBILE then
        local cam = Workspace.CurrentCamera
        if cam then
            return Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        end
        return Vector2.new(0, 0)
    end
    local m = LocalPlayer:GetMouse()
    return Vector2.new(m.X, m.Y)
end

local function getMyRoot()
    local char = LocalPlayer.Character
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso"))
end

local function getMyHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local losParams = RaycastParams.new()
losParams.FilterType = Enum.RaycastFilterType.Exclude
losParams.IgnoreWater = true

local function hasLOS(pos, targetChar)
    local cam = Workspace.CurrentCamera
    if not cam then return false end
    local myChar = LocalPlayer.Character
    local list = targetChar and { targetChar } or {}
    if myChar then table.insert(list, myChar) end
    losParams.FilterDescendantsInstances = list
    local hit = Workspace:Raycast(cam.CFrame.Position, pos - cam.CFrame.Position, losParams)
    return hit == nil
end

local function isKO(char)
    if not char then return false end
    local ok, res = pcall(function()
        local fx = char:FindFirstChild("BodyEffects")
        if fx then
            local ko = fx:FindFirstChild("K.O")
            if ko and ko.Value == true then return true end
        end
        if char:FindFirstChild("GRABBING_CONSTRAINT") then return true end
        return false
    end)
    if ok and res then return true end
    return false
end

local function findTarget(fov, opts)
    opts = opts or {}
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local cur = cursorPos()
    local myTeam = LocalPlayer.Team
    local best = nil
    local bestDist = fov
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso"))
            if char and hum and root and hum.Health > 0 then
                local teamSkip = opts.team and myTeam ~= nil and plr.Team == myTeam
                if not teamSkip and not (opts.ko and isKO(char)) then
                    local pos, onScreen = cam:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local d = (Vector2.new(pos.X, pos.Y) - cur).Magnitude
                        if d < bestDist then
                            if not opts.wall or hasLOS(root.Position, char) then
                                best = plr
                                bestDist = d
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function nearestPartToCursor(char)
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local cur = cursorPos()
    local best = nil
    local bd = math.huge
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") and not string.find(p.Name, "Gun") then
            local pos, on = cam:WorldToViewportPoint(p.Position)
            if on then
                local d = (Vector2.new(pos.X, pos.Y) - cur).Magnitude
                if d < bd then
                    bd = d
                    best = p
                end
            end
        end
    end
    return best
end

local function clampToPart(part, pos)
    local half = part.Size * 0.5
    local lp = part.CFrame:PointToObjectSpace(pos)
    lp = Vector3.new(
        math.clamp(lp.X, -half.X, half.X),
        math.clamp(lp.Y, -half.Y, half.Y),
        math.clamp(lp.Z, -half.Z, half.Z)
    )
    return part.CFrame * lp
end

local ghostCircle = nil
local gazeCircle = nil
local tracerLine = nil

local function ensureCircle(ref)
    if not espSupported then return nil end
    if ref then return ref end
    local c = Drawing.new("Circle")
    c.Filled = false
    c.Thickness = 2
    c.NumSides = 100
    c.Transparency = 0.8
    c.Color = ACCENT
    c.Visible = false
    return c
end

local function ensureTracer()
    if not espSupported then return nil end
    if tracerLine then return tracerLine end
    tracerLine = Drawing.new("Line")
    tracerLine.Thickness = 1
    tracerLine.Transparency = 1
    tracerLine.Color = ACCENT
    tracerLine.Visible = false
    return tracerLine
end

local markerPart = nil
local markerStyle = "Dot"
local markerColor = ACCENT

local function ensureMarker()
    if markerPart or not scriptActive then return end
    markerPart = Instance.new("Part")
    markerPart.Name = "TetowareMarker"
    markerPart.Anchored = true
    markerPart.CanCollide = false
    markerPart.CastShadow = false
    markerPart.Material = Enum.Material.Neon
    markerPart.CFrame = CFrame.new(0, 9999, 0)
    markerPart.Parent = Workspace
end

local function applyMarkerStyle()
    if not markerPart then return end
    if markerStyle == "Box" then
        markerPart.Shape = Enum.PartType.Block
        markerPart.Size = Vector3.new(3.4, 3.6, 2.8)
        markerPart.Transparency = 0.7
    else
        markerPart.Shape = Enum.PartType.Ball
        markerPart.Size = Vector3.new(8, 8, 8)
        markerPart.Transparency = 0.75
    end
    markerPart.Color = markerColor
end

local lockEnabled = false
local lockActive = false
local lockTarget = nil
local lockPart = "HumanoidRootPart"
local lockPred = 0.13
local lockAuto = true
local lockTeam = false
local lockDeath = true
local lockAir = true
local lockResolver = true
local lockGround = true
local markerOn = true
local tracerOn = false
local rangeProfiles = false
local weaponProfiles = false
local lockFov = 300
local lockTool = nil
local lockKey = Enum.KeyCode.Q
local remoteArg = "UpdateMousePos"

local function getLockPart(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local part = char:FindFirstChild(lockPart) or char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if lockAir and hum then
        if hum.FloorMaterial == Enum.Material.Air or hum:GetState() == Enum.HumanoidStateType.Freefall then
            part = char:FindFirstChild("RightFoot") or char:FindFirstChild("LeftFoot") or part
        end
    end
    return part
end

local function lockPredictedPos(char)
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
    local part = getLockPart(char)
    if not part then return nil end
    local v = part.AssemblyLinearVelocity
    local pred = lockPred
    local dist = 0
    local myRoot = getMyRoot()
    if myRoot then dist = (part.Position - myRoot.Position).Magnitude end
    if lockAuto then
        pred = autoPredFor()
    elseif rangeProfiles then
        pred = rangePredFor(dist)
    end
    if lockResolver then
        if root and root.Anchored then
            pred = 0
        elseif Vector3.new(v.X, 0, v.Z).Magnitude > 70 then
            v = Vector3.new(v.X, 0, v.Z)
        end
    end
    if lockGround and v.Y < -40 then
        v = Vector3.new(v.X, 0, v.Z)
    end
    return part.Position + v * pred
end

local function effectiveLockFov()
    if weaponProfiles then
        local wf = equippedWeaponFov()
        if wf then return wf end
    end
    return lockFov
end

local function lockDeactivate(silent)
    lockActive = false
    lockTarget = nil
    if markerPart then
        markerPart.CFrame = CFrame.new(0, 9999, 0)
    end
    if tracerLine then
        tracerLine.Visible = false
    end
    if not silent then
        notify("Nerve Lock", "unlocked", "lock")
    end
end

local function lockToggle()
    if not lockEnabled then
        notify("Nerve Lock", "enable the lock core first", "info")
        return
    end
    if lockActive then
        lockDeactivate(false)
        return
    end
    local t = findTarget(effectiveLockFov(), { team = lockTeam, ko = lockDeath })
    if t then
        lockActive = true
        lockTarget = t
        notify("Nerve Lock", "locked onto " .. t.Name, "lock")
    else
        notify("Nerve Lock", "no target nearby", "info")
    end
end

local function setLockTool(on)
    if on then
        if not lockTool then
            lockTool = Instance.new("Tool")
            lockTool.Name = "Nerve Lock"
            lockTool.RequiresHandle = false
            lockTool.CanBeDropped = false
            lockTool.Activated:Connect(function()
                lockToggle()
            end)
            lockTool.Parent = LocalPlayer:FindFirstChildOfClass("Backpack")
        end
    elseif lockTool then
        lockTool:Destroy()
        lockTool = nil
    end
end

local ghostOn = false
local ghostPred = 0.13
local ghostAuto = false
local ghostChance = 100
local ghostNearest = false
local ghostPoint = false
local ghostWall = true
local ghostKO = true
local ghostTeam = false
local ghostAir = true
local ghostGround = true
local ghostFovShow = false
local ghostFov = 90
local ghostPartName = "UpperTorso"
local ghostTargetPart = nil
local ghostKey = Enum.KeyCode.T
local ghostHookReady = false

local function updateGhostTarget()
    local t = findTarget(ghostFov, { wall = ghostWall, ko = ghostKO, team = ghostTeam })
    if not t then
        ghostTargetPart = nil
        return
    end
    local char = t.Character
    local part
    if ghostNearest then
        part = nearestPartToCursor(char)
    end
    if not part then
        part = char:FindFirstChild(ghostPartName) or char:FindFirstChild("HumanoidRootPart")
    end
    if not part then
        ghostTargetPart = nil
        return
    end
    if ghostAir then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and (hum.FloorMaterial == Enum.Material.Air or hum:GetState() == Enum.HumanoidStateType.Freefall) then
            part = char:FindFirstChild("RightFoot") or char:FindFirstChild("LeftFoot") or part
        end
    end
    if ghostChance < 100 and math.random(0, 99) >= ghostChance then
        ghostTargetPart = nil
        return
    end
    ghostTargetPart = part
end

local function ghostPredictedCFrame()
    if not ghostTargetPart or not ghostTargetPart.Parent then return nil end
    local v = ghostTargetPart.AssemblyLinearVelocity
    if ghostGround and v.Y < -40 then
        v = Vector3.new(v.X, 0, v.Z)
    end
    local pred = ghostAuto and autoPredFor() or ghostPred
    local base = ghostTargetPart.Position
    if ghostPoint then
        local cam = Workspace.CurrentCamera
        local myRoot = getMyRoot()
        if cam and myRoot then
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { LocalPlayer.Character, ghostTargetPart.Parent }
            local hit = Workspace:Raycast(cam.CFrame.Position, base - cam.CFrame.Position, params)
            local aimPos = hit and hit.Position or base
            base = clampToPart(ghostTargetPart, aimPos).Position
        end
    end
    return CFrame.new(base + v * pred)
end

local function ensureGhostHook()
    if ghostHookReady then return true end
    if typeof(hookmetamethod) ~= "function" or typeof(newcclosure) ~= "function" then
        return false
    end
    ghostHookReady = true
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, k)
        if scriptActive and ghostOn and ghostTargetPart and self:IsA("Mouse") and (k == "Hit" or k == "Target") then
            local ok, res = pcall(function()
                if k == "Target" then
                    return ghostTargetPart
                end
                return ghostPredictedCFrame()
            end)
            if ok and res ~= nil then
                return res
            end
        end
        return oldIndex(self, k)
    end))
    return true
end

local gazeEnabled = false
local gazeActive = false
local gazeTarget = nil
local gazePart = "HumanoidRootPart"
local gazePred = 0.13
local gazeAuto = false
local gazeSmooth = false
local gazeAmount = 0.05
local gazeAirSmooth = true
local gazeAirAmount = 0.08
local gazeShake = false
local gazeShakePower = 5
local gazeDeath = true
local gazeWall = true
local gazeHold = false
local gazeFovShow = false
local gazeFov = 55
local gazeLook = false
local gazeSpectate = false
local gazeStrafe = false
local gazeStrafeDist = 8
local gazeKey = Enum.KeyCode.C
local gazePrevSubject = nil
local gazeStrafeAngle = 0

local function gazeDeactivate(silent)
    gazeActive = false
    gazeTarget = nil
    local cam = Workspace.CurrentCamera
    if cam and gazePrevSubject then
        pcall(function()
            cam.CameraSubject = gazePrevSubject
        end)
    end
    gazePrevSubject = nil
    if not silent then
        notify("Gaze Lock", "unlocked", "eye")
    end
end

local function gazeActivate()
    local t = findTarget(gazeFov, { wall = gazeWall, ko = gazeDeath })
    if not t then
        notify("Gaze Lock", "no target nearby", "info")
        return
    end
    gazeActive = true
    gazeTarget = t
    local cam = Workspace.CurrentCamera
    if gazeSpectate and cam then
        gazePrevSubject = cam.CameraSubject
        local hum = t.Character and t.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                cam.CameraSubject = hum
            end)
        end
    end
    notify("Gaze Lock", "locked onto " .. t.Name, "eye")
end

local function gazeToggle()
    if not gazeEnabled then
        notify("Gaze Lock", "enable the gaze core first", "info")
        return
    end
    if gazeActive then
        gazeDeactivate(false)
    else
        gazeActivate()
    end
end

local triggerOn = false
local triggerDelay = 0.25
local triggerHold = false
local triggerRequireLock = true
local triggerAcc = 0
local triggerWarned = false

local function fireClick()
    if not IS_MOBILE then
        if type(mouse1click) == "function" then
            pcall(mouse1click)
        end
        return
    end
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local cam = Workspace.CurrentCamera
        local vp = cam.ViewportSize
        vim:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, true, game, 0)
        task.wait()
        vim:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, false, game, 0)
    end)
end

local namecallReady = false
local remoteShield = false
local groupSpoof = false

local SHIELD_SET = {
    TeleportDetect = true, CHECKER = true, CHECKER_1 = true, GUI_CHECK = true,
    BANREMOTE = true, PERMAIDBAN = true, KICKREMOTE = true, BR_KICKPC = true,
    BR_KICKMOBILE = true, OneMoreTime = true, checkingSPEED = true, JJARC = true,
    BreathingHAMON = true, TakePoisonDamage = true, FORCEFIELD = true,
    Christmas_Sock = true, VirusCough = true, Symbiote = true, Symbioted = true,
}

local function ensureNamecall()
    if namecallReady then return true end
    if typeof(getrawmetatable) ~= "function" or typeof(newcclosure) ~= "function" or typeof(getnamecallmethod) ~= "function" then
        return false
    end
    namecallReady = true
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(...)
        local method = getnamecallmethod()
        local args = { ... }
        if scriptActive then
            if remoteShield and method == "FireServer" and type(args[1]) == "string" and SHIELD_SET[args[1]] then
                return nil
            end
            if groupSpoof and method == "IsInGroup" then
                return true
            end
            if lockActive and lockTarget and method == "FireServer" and args[2] == remoteArg then
                local char = lockTarget.Character
                if char then
                    local pos = lockPredictedPos(char)
                    if pos then
                        args[3] = pos
                        return old(table.unpack(args, 1, #args))
                    end
                end
            end
        end
        return old(...)
    end)
    setreadonly(mt, true)
    return true
end

local flyOn = false
local flySpeed = 50
local flyBV = nil
local flyBG = nil
local flyUpHeld = false

local function flyCleanup()
    if flyBV then
        pcall(function() flyBV:Destroy() end)
        flyBV = nil
    end
    if flyBG then
        pcall(function() flyBG:Destroy() end)
        flyBG = nil
    end
end

local function startFly()
    if flyBV then return end
    local root = getMyRoot()
    if not root then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = root
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBG.P = 9e4
    flyBG.CFrame = root.CFrame
    flyBG.Parent = root
    flyUpHeld = false
end

local function setFly(on)
    flyOn = on
    if on then
        startFly()
    else
        flyCleanup()
    end
end

local sprintOn = false
local sprintSpeed = 60
local sprintHold = true

local macroOn = false
local macroPower = 30
local macroKey = Enum.KeyCode.X
local macroTool = nil

local function macroStop()
    macroOn = false
end

local function macroToggle()
    if not macroOn then
        macroOn = true
        notify("Fake Macro", "macro on", "zap")
    else
        macroStop()
        notify("Fake Macro", "macro off", "zap")
    end
end

local function setMacroTool(on)
    if on then
        if not macroTool then
            macroTool = Instance.new("Tool")
            macroTool.Name = "Fake Macro"
            macroTool.RequiresHandle = false
            macroTool.CanBeDropped = false
            macroTool.Activated:Connect(function()
                macroToggle()
            end)
            macroTool.Parent = LocalPlayer:FindFirstChildOfClass("Backpack")
        end
    elseif macroTool then
        macroTool:Destroy()
        macroTool = nil
    end
end

local whirlOn = false
local whirlSpeed = 500
local whirlKey = Enum.KeyCode.B

local phaseOn = false
local phaseKey = Enum.KeyCode.V

local sinkOn = false
local sinkDepth = -35
local sinkHipSaved = nil
local sinkKey = Enum.KeyCode.N

local noclipOn = false

local infJumpOn = false

local clickTpOn = false

local lowGravOn = false
local gravSaved = nil

local vanishOn = false
local vanishSaved = nil
local vanishSeat = nil

local flingGuardOn = false
local stompGuardOn = false
local stompUsed = false
local antiSlowOn = false
local antiSlowSpeed = 16
local jumpSpamOn = false
local lastGoodPos = nil
local guardAcc = 0

local weaponGlowOn = false
local weaponGlowColor = ACCENT
local bodyGlowOn = false
local bodyGlowColor = ACCENT
local ghostLegOn = false
local headVanishOn = false
local glowOrig = setmetatable({}, { __mode = "k" })
local lastGlowTool = nil

local function recordOrig(inst, prop, value)
    if glowOrig[inst] == nil then
        glowOrig[inst] = {}
    end
    if glowOrig[inst][prop] == nil then
        glowOrig[inst][prop] = value
    end
end

local function restoreGlow()
    for inst, props in pairs(glowOrig) do
        if inst and inst.Parent then
            pcall(function()
                if props.Transparency ~= nil then inst.Transparency = props.Transparency end
                if props.Material ~= nil then inst.Material = props.Material end
                if props.Color ~= nil then inst.Color = props.Color end
            end)
        end
    end
    glowOrig = setmetatable({}, { __mode = "k" })
    lastGlowTool = nil
end

local function glowParts(container, color)
    for _, p in ipairs(container:GetChildren()) do
        if p:IsA("BasePart") then
            recordOrig(p, "Material", p.Material)
            recordOrig(p, "Color", p.Color)
            pcall(function()
                p.Material = Enum.Material.ForceField
                p.Color = color
            end)
        end
    end
end

local function applyBodyGlow()
    local char = LocalPlayer.Character
    if char then
        glowParts(char, bodyGlowColor)
    end
end

local function applyWeaponGlow()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildWhichIsA("Tool")
    if tool and tool ~= lastGlowTool then
        if lastGlowTool and lastGlowTool.Parent then
            for _, p in ipairs(lastGlowTool:GetChildren()) do
                if p:IsA("BasePart") and glowOrig[p] then
                    pcall(function()
                        if glowOrig[p].Material then p.Material = glowOrig[p].Material end
                        if glowOrig[p].Color then p.Color = glowOrig[p].Color end
                    end)
                    glowOrig[p] = nil
                end
            end
        end
        glowParts(tool, weaponGlowColor)
        lastGlowTool = tool
    end
end

local FACE_IDS = {
    ["Playful Vampire"] = 2409281591,
    ["Red Beastmode"] = 127959433,
    ["Yum"] = 26018945,
    ["Super Happy"] = 494290547,
    ["Prankster"] = 20052028,
    ["Trouble Maker"] = 22920500,
    ["Meanie"] = 508490451,
    ["Stitch Face"] = 8329438,
    ["Madness"] = 129900258,
}

local origFace = nil

local function applyFace(name)
    local char = LocalPlayer.Character
    local head = char and char:FindFirstChild("Head")
    local face = head and (head:FindFirstChild("face") or head:FindFirstChild("Face"))
    if not face then
        notify("Face Swap", "no face found on this rig", "info")
        return
    end
    if origFace == nil then
        origFace = face.Texture
    end
    local id = FACE_IDS[name]
    if id then
        face.Texture = "rbxassetid://" .. id
        notify("Face Swap", name, "smile")
    else
        face.Texture = origFace
        notify("Face Swap", "original face restored", "smile")
    end
end

local EMOTES = {
    Lay = 3152378852,
    Greet = 3189777795,
    Speed = 11710541744,
    Sturdy = 11710529975,
    Griddy = 11710529975,
}

local function playEmote(name)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator") or hum
    local ok = pcall(function()
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. EMOTES[name]
        local track = animator:LoadAnimation(anim)
        track:Play()
    end)
    if ok then
        notify("Emotes", name, "person-standing")
    end
end

local function rejoin()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end

local function serverScout()
    local ok, err = pcall(function()
        local raw = game:HttpGet("https://games.roproxy.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local data = HttpService:JSONDecode(raw)
        local best = nil
        local bestPing = math.huge
        for _, s in ipairs(data.data or {}) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers and (s.ping or 9999) < bestPing then
                bestPing = s.ping
                best = s
            end
        end
        if best then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, LocalPlayer)
        else
            notify("Server Scout", "no better server found", "server")
        end
    end)
    if not ok then
        notify("Server Scout", "scan failed: " .. tostring(err), "info")
    end
end

local spooferMem = false
local spooferPing = false
local memMin = 900
local memMax = 990
local pingMin = 20
local pingMax = 35
local oldMemFunc = nil
local oldMemTagFunc = nil
local oldPingGet = nil
local oldPingGetStr = nil

local function setMemoryMask(on)
    if on then
        if typeof(hookfunction) ~= "function" then
            notify("Memory Mask", "hookfunction not available here", "info")
            return false
        end
        pcall(function()
            local Stats = game:GetService("Stats")
            if not oldMemFunc then
                oldMemFunc = hookfunction(Stats.GetTotalMemoryUsageMb, function()
                    return math.random(memMin, memMax)
                end)
            end
            if not oldMemTagFunc then
                oldMemTagFunc = hookfunction(Stats.GetMemoryUsageMbForTag, function()
                    return math.random(memMin, memMax)
                end)
            end
        end)
        return true
    else
        pcall(function()
            local Stats = game:GetService("Stats")
            if oldMemFunc then hookfunction(Stats.GetTotalMemoryUsageMb, oldMemFunc) end
            if oldMemTagFunc then hookfunction(Stats.GetMemoryUsageMbForTag, oldMemTagFunc) end
        end)
        oldMemFunc = nil
        oldMemTagFunc = nil
        return false
    end
end

local function setPingMask(on)
    if on then
        if typeof(hookfunction) ~= "function" then
            notify("Ping Mask", "hookfunction not available here", "info")
            return false
        end
        pcall(function()
            local item = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
            if not oldPingGet then
                oldPingGet = hookfunction(item.GetValue, function()
                    return math.random(pingMin, pingMax)
                end)
            end
            if not oldPingGetStr then
                oldPingGetStr = hookfunction(item.GetValueString, function()
                    return tostring(math.random(pingMin, pingMax)) .. " ms"
                end)
            end
        end)
        return true
    else
        pcall(function()
            local item = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
            if oldPingGet then hookfunction(item.GetValue, oldPingGet) end
            if oldPingGetStr then hookfunction(item.GetValueString, oldPingGetStr) end
        end)
        oldPingGet = nil
        oldPingGetStr = nil
        return false
    end
end

local zoomLocked = false
local zoomSaved = nil

local function setZoomLock(on)
    local cam = Workspace.CurrentCamera
    local char = LocalPlayer.Character
    if on then
        if cam and char and char:FindFirstChild("Head") then
            local dist = (cam.CFrame.Position - char.Head.Position).Magnitude
            zoomSaved = { min = LocalPlayer.CameraMinZoomDistance, max = LocalPlayer.CameraMaxZoomDistance }
            LocalPlayer.CameraMinZoomDistance = dist
            LocalPlayer.CameraMaxZoomDistance = dist
        end
    else
        if zoomSaved then
            LocalPlayer.CameraMinZoomDistance = zoomSaved.min
            LocalPlayer.CameraMaxZoomDistance = zoomSaved.max
            zoomSaved = nil
        end
    end
end

local function gearSort(listStr)
    local order = {}
    for name in string.gmatch(listStr, "[^,]+") do
        local trimmed = string.match(name, "^%s*(.-)%s*$")
        if trimmed ~= "" then
            table.insert(order, string.lower(trimmed))
        end
    end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not bp then return end
    local moved = 0
    for _, want in ipairs(order) do
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and string.find(string.lower(t.Name), want, 1, true) then
                t.Parent = game
                t.Parent = bp
                moved += 1
                task.wait(0.05)
                break
            end
        end
    end
    notify("Gear Sort", moved .. " tool(s) moved to front", "check")
end

local chatCmdsOn = false

local function panic()
    lockDeactivate(true)
    ghostOn = false
    gazeDeactivate(true)
    triggerOn = false
    macroStop()
    phaseOn = false
    sinkOn = false
    if sinkHipSaved then
        local hum = getMyHumanoid()
        if hum then hum.HipHeight = sinkHipSaved end
        sinkHipSaved = nil
    end
    whirlOn = false
    if ghostCircle then ghostCircle.Visible = false end
    if gazeCircle then gazeCircle.Visible = false end
    notify("Panic", "everything combat related is off", "alert-triangle")
end

UserInputService.JumpRequest:Connect(function()
    if flyOn then
        flyUpHeld = true
    end
    if infJumpOn then
        local hum = getMyHumanoid()
        if hum then
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not scriptActive then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local k = input.KeyCode
        if k == lockKey then
            lockToggle()
        elseif k == ghostKey then
            if ghostOn then
                ghostOn = false
                ghostTargetPart = nil
                notify("Ghost Aim", "off", "ghost")
            else
                ghostOn = true
                notify("Ghost Aim", "on", "ghost")
            end
        elseif k == gazeKey then
            if gazeHold then
                if not gazeActive then gazeActivate() end
            else
                gazeToggle()
            end
        elseif k == macroKey and not IS_MOBILE then
            macroToggle()
        elseif k == whirlKey then
            whirlOn = not whirlOn
        elseif k == phaseKey then
            phaseOn = not phaseOn
        elseif k == sinkKey then
            if sinkOn then
                sinkOn = false
                local hum = getMyHumanoid()
                if hum and sinkHipSaved then hum.HipHeight = sinkHipSaved end
                sinkHipSaved = nil
            else
                local hum = getMyHumanoid()
                if hum then
                    sinkHipSaved = hum.HipHeight
                    sinkOn = true
                end
            end
        elseif k == Enum.KeyCode.P and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            return
        end
    elseif clickTpOn then
        local char = LocalPlayer.Character
        if not char then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local m = LocalPlayer:GetMouse()
            if m.Hit then
                char:PivotTo(CFrame.new(m.Hit.Position + Vector3.new(0, 3, 0)))
            end
        elseif input.UserInputType == Enum.UserInputType.Touch then
            local cam = Workspace.CurrentCamera
            if cam then
                local unitRay = cam:ViewportPointToRay(input.Position.X, input.Position.Y)
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = { char }
                local hit = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, params)
                if hit then
                    char:PivotTo(CFrame.new(hit.Position + Vector3.new(0, 3, 0)))
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gazeHold and input.KeyCode == gazeKey and gazeActive then
        gazeDeactivate(false)
    end
end)

local mainConn
mainConn = RunService.RenderStepped:Connect(function(dt)
    if not scriptActive then return end

    if ghostCircle then
        if ghostFovShow and ghostOn then
            local c = cursorPos()
            ghostCircle.Position = c
            ghostCircle.Radius = ghostFov
            ghostCircle.Visible = true
        else
            ghostCircle.Visible = false
        end
    end
    if gazeCircle then
        if gazeFovShow and gazeEnabled then
            local c = cursorPos()
            gazeCircle.Position = c
            gazeCircle.Radius = gazeFov
            gazeCircle.Visible = true
        else
            gazeCircle.Visible = false
        end
    end

    if ghostOn then
        updateGhostTarget()
    else
        ghostTargetPart = nil
    end

    if lockActive then
        local char = lockTarget and lockTarget.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health <= 2 or (lockDeath and isKO(char)) then
            lockDeactivate(false)
        end
    end

    if lockActive and lockTarget then
        local char = lockTarget.Character
        local part = char and getLockPart(char)
        if part then
            if markerOn then
                ensureMarker()
                applyMarkerStyle()
                local pos = lockPredictedPos(char) or part.Position
                markerPart.CFrame = CFrame.new(pos)
            elseif markerPart then
                markerPart.CFrame = CFrame.new(0, 9999, 0)
            end
            if tracerOn and espSupported then
                local cam = Workspace.CurrentCamera
                local sp, on = cam:WorldToViewportPoint(part.Position)
                local c = cursorPos()
                local line = ensureTracer()
                if on then
                    line.From = c
                    line.To = Vector2.new(sp.X, sp.Y)
                    line.Color = ACCENT
                    line.Visible = true
                else
                    line.Visible = false
                end
            elseif tracerLine then
                tracerLine.Visible = false
            end
        end
    else
        if markerPart then
            markerPart.CFrame = CFrame.new(0, 9999, 0)
        end
        if tracerLine then
            tracerLine.Visible = false
        end
    end

    if gazeEnabled and gazeActive and gazeTarget then
        local char = gazeTarget.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local myHum = getMyHumanoid()
        if not char or not hum or hum.Health <= 2 or (gazeDeath and myHum and myHum.Health <= 2) or (gazeDeath and isKO(char)) then
            gazeDeactivate(false)
        else
            local part = char:FindFirstChild(gazePart) or char:FindFirstChild("HumanoidRootPart")
            local cam = Workspace.CurrentCamera
            if part and cam then
                if gazeWall and not hasLOS(part.Position, char) then
                    gazeDeactivate(false)
                else
                    local v = part.AssemblyLinearVelocity
                    local pred = gazeAuto and autoPredFor() or gazePred
                    if Vector3.new(v.X, 0, v.Z).Magnitude > 70 then
                        v = Vector3.new(v.X, 0, v.Z)
                    end
                    if v.Y < -40 then
                        v = Vector3.new(v.X, 0, v.Z)
                    end
                    local aim = part.Position + v * pred
                    if gazeShake then
                        local p = gazeShakePower
                        aim += Vector3.new(math.random(-p, p), math.random(-p, p), math.random(-p, p)) * 0.1
                    end
                    local root = getMyRoot()
                    if gazeStrafe and root then
                        gazeStrafeAngle += dt * 2
                        local tPos = part.Position
                        local offset = Vector3.new(math.sin(gazeStrafeAngle), 0, math.cos(gazeStrafeAngle)) * gazeStrafeDist
                        root.CFrame = CFrame.new(tPos + offset)
                    end
                    local smooth = gazeSmooth and gazeAmount or gazeAirAmount
                    if gazeAirSmooth then
                        local th = char:FindFirstChildOfClass("Humanoid")
                        if th and (th.FloorMaterial == Enum.Material.Air or th:GetState() == Enum.HumanoidStateType.Freefall) then
                            smooth = gazeAirAmount
                        elseif gazeSmooth then
                            smooth = gazeAmount
                        end
                    end
                    local main = CFrame.new(cam.CFrame.Position, aim)
                    cam.CFrame = cam.CFrame:Lerp(main, smooth, Enum.EasingStyle.Elastic, Enum.EasingDirection.InOut)
                    if gazeLook and root then
                        local flat = Vector3.new(part.Position.X, root.Position.Y, part.Position.Z)
                        root.CFrame = CFrame.new(root.Position, flat)
                    end
                end
            end
        end
    end

    if triggerOn then
        triggerAcc += dt
        if triggerAcc >= triggerDelay then
            triggerAcc = 0
            local shouldFire = false
            if triggerRequireLock then
                shouldFire = lockActive and lockTarget ~= nil
            else
                shouldFire = findTarget(effectiveLockFov(), { wall = true, ko = true }) ~= nil
            end
            if shouldFire and not (triggerHold and not IS_MOBILE and not UserInputService:IsKeyDown(Enum.UserInputType.MouseButton1)) then
                local ok = pcall(fireClick)
                if not ok and IS_MOBILE and not triggerWarned then
                    triggerWarned = true
                    triggerOn = false
                    notify("Quick Draw", "virtual input blocked on this executor, disabled", "info")
                end
            end
        end
    end

    if flyOn then
        local root = getMyRoot()
        local hum = getMyHumanoid()
        if root and hum and flyBV and flyBV.Parent then
            local dir = hum.MoveDirection
            local v = dir * flySpeed
            if IS_MOBILE then
                if flyUpHeld then
                    v += Vector3.new(0, flySpeed, 0)
                end
            else
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    v += Vector3.new(0, flySpeed, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    v -= Vector3.new(0, flySpeed, 0)
                end
            end
            flyBV.Velocity = v
            local cam = Workspace.CurrentCamera
            if cam then
                flyBG.CFrame = CFrame.new(root.Position, root.Position + cam.CFrame.LookVector)
            end
        end
        flyUpHeld = false
    end

    if sprintOn then
        local root = getMyRoot()
        local hum = getMyHumanoid()
        if root and hum and hum.MoveDirection.Magnitude > 0 then
            local go = true
            if sprintHold and not IS_MOBILE then
                go = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
            end
            if go then
                root.AssemblyLinearVelocity = hum.MoveDirection * sprintSpeed
            end
        end
    end

    if macroOn then
        local root = getMyRoot()
        if root then
            if IS_MOBILE then
                root.AssemblyLinearVelocity = root.CFrame.LookVector * macroPower
            end
        end
    end

    if whirlOn then
        local root = getMyRoot()
        if root then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(whirlSpeed) * dt, 0)
        end
    end

    if sinkOn then
        local root = getMyRoot()
        if root then
            local v = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(v.X, sinkDepth, v.Z)
        end
    end

    if weaponGlowOn then
        applyWeaponGlow()
    end
end)

RunService.Stepped:Connect(function()
    if not scriptActive then return end
    if noclipOn then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if not scriptActive then return end

    if phaseOn then
        local root = getMyRoot()
        if root and root.Parent then
            local savedCF = root.CFrame
            local savedVel = root.AssemblyLinearVelocity
            local r = 180
            local spoof = savedCF * CFrame.Angles(math.rad(math.random(-r, r)), math.rad(math.random(-r, r)), math.rad(math.random(-r, r)))
            root.CFrame = spoof
            root.AssemblyLinearVelocity = Vector3.new(1, 1, 1) * 16384
            RunService.RenderStepped:Wait()
            if scriptActive and root.Parent then
                root.CFrame = savedCF
                root.AssemblyLinearVelocity = savedVel
            end
        end
    end

    guardAcc += dt
    if guardAcc < 0.12 then return end
    guardAcc = 0

    local char = LocalPlayer.Character
    local myRoot = getMyRoot()
    local hum = getMyHumanoid()

    if flingGuardOn and myRoot then
        if myRoot.AssemblyLinearVelocity.Magnitude > 250 or myRoot.AssemblyAngularVelocity.Magnitude > 250 then
            myRoot.AssemblyAngularVelocity = Vector3.zero
            myRoot.AssemblyLinearVelocity = Vector3.zero
            if lastGoodPos then
                myRoot.CFrame = lastGoodPos
            end
        else
            lastGoodPos = myRoot.CFrame
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local c = plr.Character
                local r = c and c:FindFirstChild("HumanoidRootPart")
                if r and r.AssemblyLinearVelocity.Magnitude > 100 then
                    pcall(function()
                        for _, d in ipairs(c:GetDescendants()) do
                            if d:IsA("BasePart") then
                                d.CanCollide = false
                                d.AssemblyAngularVelocity = Vector3.zero
                                d.AssemblyLinearVelocity = Vector3.zero
                            end
                        end
                    end)
                end
            end
        end
    end

    if stompGuardOn and hum and char and not stompUsed and hum.Health <= 15 and hum.Health > 0 then
        stompUsed = true
        pcall(function()
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") then
                    d:Destroy()
                end
            end
        end)
        notify("Stomp Guard", "triggered, parts dropped", "shield")
    end

    if antiSlowOn and hum then
        if hum.WalkSpeed < antiSlowSpeed and hum.WalkSpeed > 0 then
            hum.WalkSpeed = antiSlowSpeed
        end
    end

    if jumpSpamOn and hum then
        pcall(function()
            hum.UseJumpPower = true
            if hum.JumpPower < 50 then
                hum.JumpPower = 50
            end
        end)
    end

    if bodyGlowOn and char then
        applyBodyGlow()
    end
end)

local connections = {}
table.insert(connections, Players.PlayerRemoving:Connect(function(plr)
    if lockTarget == plr then
        lockDeactivate(true)
    end
    if gazeTarget == plr then
        gazeDeactivate(true)
    end
end))

table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(char)
    stompUsed = false
    flyCleanup()
    lockDeactivate(true)
    gazeDeactivate(true)
    setLockTool(lockTool ~= nil or false)
    task.delay(0.5, function()
        if not scriptActive then return end
        if lockTool or (lockEnabled and IS_MOBILE) then
            setLockTool(true)
        end
        if macroTool or (macroOn and IS_MOBILE) then
            setMacroTool(true)
        end
        if flyOn then
            startFly()
        end
        if bodyGlowOn then
            applyBodyGlow()
        end
        if ghostLegOn then
            for _, n in ipairs({ "RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg" }) do
                local p = char:FindFirstChild(n)
                if p then
                    recordOrig(p, "Transparency", p.Transparency)
                    p.Transparency = 1
                end
            end
        end
        if headVanishOn then
            local head = char:FindFirstChild("Head")
            if head then
                recordOrig(head, "Transparency", head.Transparency)
                head.Transparency = 1
            end
        end
    end)
end))

LocalPlayer.Chatted:Connect(function(msg)
    if not scriptActive or not chatCmdsOn then return end
    local lower = string.lower(msg)
    local n = tonumber(string.match(lower, "!pred%s+([%d%.]+)"))
    if n then
        lockPred = math.clamp(n, 0, 2)
        notify("Chat Command", "lock prediction set to " .. lockPred, "check")
        return
    end
    n = tonumber(string.match(lower, "!fov%s+([%d%.]+)"))
    if n then
        lockFov = math.clamp(n, 10, 1000)
        notify("Chat Command", "lock fov set to " .. lockFov, "check")
        return
    end
    if lower == "!lock" then
        lockToggle()
    elseif lower == "!unlock" then
        lockDeactivate(false)
    elseif lower == "!rejoin" then
        rejoin()
    end
end)

unloadAll = function()
    scriptActive = false
    popupOpen = false
    lockEnabled = false
    lockDeactivate(true)
    ghostOn = false
    ghostTargetPart = nil
    gazeEnabled = false
    gazeDeactivate(true)
    triggerOn = false
    macroOn = false
    flyOn = false
    flyCleanup()
    sprintOn = false
    whirlOn = false
    phaseOn = false
    sinkOn = false
    noclipOn = false
    infJumpOn = false
    clickTpOn = false
    vanishOn = false
    flingGuardOn = false
    stompGuardOn = false
    antiSlowOn = false
    jumpSpamOn = false
    weaponGlowOn = false
    bodyGlowOn = false
    ghostLegOn = false
    headVanishOn = false
    if spooferMem then spooferMem = setMemoryMask(false) end
    if spooferPing then spooferPing = setPingMask(false) end
    setZoomLock(false)
    if gravSaved then
        Workspace.Gravity = gravSaved
        gravSaved = nil
    end
    if sinkHipSaved then
        local hum = getMyHumanoid()
        if hum then hum.HipHeight = sinkHipSaved end
        sinkHipSaved = nil
    end
    restoreGlow()
    if origFace then
        local char = LocalPlayer.Character
        local head = char and char:FindFirstChild("Head")
        local face = head and head:FindFirstChild("face")
        if face then
            pcall(function() face.Texture = origFace end)
        end
    end
    setLockTool(false)
    setMacroTool(false)
    if markerPart then
        pcall(function() markerPart:Destroy() end)
        markerPart = nil
    end
    if ghostCircle then
        pcall(function() ghostCircle:Remove() end)
        ghostCircle = nil
    end
    if gazeCircle then
        pcall(function() gazeCircle:Remove() end)
        gazeCircle = nil
    end
    if tracerLine then
        pcall(function() tracerLine:Remove() end)
        tracerLine = nil
    end
    if mainConn then
        pcall(function() mainConn:Disconnect() end)
    end
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    connections = {}
    if purchaseConn then
        purchaseConn:Disconnect()
        purchaseConn = nil
    end
    if popupGui then
        popupGui:Destroy()
        popupGui = nil
    end
    if window then
        pcall(function() window:Destroy() end)
        window = nil
    end
    notify("Tetoware", "unloaded, thanks for trying it", "power")
end

local function numberInput(section, cfg)
    local element
    local last = cfg.default
    element = section:Input({
        Title = cfg.title,
        Desc = cfg.desc,
        Icon = cfg.icon,
        Placeholder = tostring(cfg.default),
        Callback = function(text)
            local n = tonumber(text)
            if not n then
                if element and element.Set then
                    pcall(function() element:Set(tostring(last)) end)
                end
                return
            end
            n = math.clamp(n, cfg.min, cfg.max)
            if element and element.Set and tonumber(text) ~= n then
                pcall(function() element:Set(tostring(n)) end)
            end
            last = n
            cfg.apply(n)
            notify(cfg.title, "set to " .. n, cfg.icon or "check")
        end,
    })
end

local function buildWindow()
    if window then return end
    if not WindUI then
        notify("Tetoware", "windui didnt load, cant build the window", "info")
        return
    end

    registerThemes()

    local cam = Workspace.CurrentCamera
    local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
    local winSize
    if IS_MOBILE then
        local w = math.clamp(vp.X * 0.52, 340, 560)
        local h = math.clamp(vp.Y * 0.6, 280, 440)
        winSize = UDim2.fromOffset(math.floor(w), math.floor(h))
    else
        winSize = UDim2.fromOffset(560, 400)
    end

    local savedTheme = loadSavedTheme()
    local startTheme = savedTheme or "Tetoware - Default"

    local ok, result = pcall(function()
        return WindUI:CreateWindow({
            Title = "Tetoware",
            Icon = WINDOW_ICON,
            Author = "By Eclipse Team",
            Folder = SAVE_FOLDER,
            Size = winSize,
            Transparent = false,
            Theme = startTheme,
            Background = THEME_IMAGES[startTheme],
            BackgroundImageTransparency = BG_TRANSPARENCY,
            SideBarWidth = 180,
            ToggleKey = TOGGLE_KEY,
            Resizable = not IS_MOBILE,
        })
    end)
    if not ok or type(result) ~= "table" then
        notify("Tetoware", "window failed to build: " .. tostring(result), "info")
        return
    end
    window = result

    if IS_MOBILE then
        pcall(function() WindUI:SetNotificationLower(true) end)
    end

    pcall(function()
        window:EditOpenButton({
            Title = "Tetoware",
            Icon = WINDOW_ICON,
            CornerRadius = UDim.new(0, 12),
        })
    end)

    pcall(function()
        window:OnDestroy(function()
            popupOpen = false
            if purchaseConn then
                purchaseConn:Disconnect()
                purchaseConn = nil
            end
            if popupGui then
                popupGui:Destroy()
                popupGui = nil
            end
        end)
    end)

    local homeTab, settingsTab, githuhSec, themeSec, donationSec, miscSec
    local lockTab, ghostTab, gazeTab, drawTab, panicTab
    local hoverTab, rushTab, roamTab, whirlTab, phaseTab, sinkTab
    local guardTab
    local bodyTab, faceTab, emoteTab
    local serverTab, spoofTab
    local okTabs, tabErr = pcall(function()
        local infoGroup = window:Section({ Title = "Information", Opened = true })
        homeTab = infoGroup:Tab({ Title = "Home", Icon = "info" })
        settingsTab = infoGroup:Tab({ Title = "Settings", Icon = "settings" })

        local combatGroup = window:Section({ Title = "Combat", Opened = true })
        lockTab = combatGroup:Tab({ Title = "Nerve Lock", Icon = "lock" })
        ghostTab = combatGroup:Tab({ Title = "Ghost Aim", Icon = "ghost" })
        gazeTab = combatGroup:Tab({ Title = "Gaze Lock", Icon = "eye" })
        drawTab = combatGroup:Tab({ Title = "Quick Draw", Icon = "mouse-pointer-click" })
        panicTab = combatGroup:Tab({ Title = "Panic", Icon = "alert-triangle" })

        local moveGroup = window:Section({ Title = "Movement", Opened = true })
        hoverTab = moveGroup:Tab({ Title = "Hover", Icon = "feather" })
        rushTab = moveGroup:Tab({ Title = "Rush", Icon = "wind" })
        roamTab = moveGroup:Tab({ Title = "Free Roam", Icon = "map" })
        whirlTab = moveGroup:Tab({ Title = "Whirl", Icon = "refresh-cw" })
        phaseTab = moveGroup:Tab({ Title = "Phase", Icon = "shuffle" })
        sinkTab = moveGroup:Tab({ Title = "Sink", Icon = "chevrons-down" })

        local defGroup = window:Section({ Title = "Defense", Opened = true })
        guardTab = defGroup:Tab({ Title = "Guard", Icon = "shield" })

        local charGroup = window:Section({ Title = "Character", Opened = true })
        bodyTab = charGroup:Tab({ Title = "Body Mods", Icon = "sparkles" })
        faceTab = charGroup:Tab({ Title = "Face Swap", Icon = "smile" })
        emoteTab = charGroup:Tab({ Title = "Emotes", Icon = "user" })

        local utilGroup = window:Section({ Title = "Utility", Opened = true })
        serverTab = utilGroup:Tab({ Title = "Server", Icon = "server" })
        spoofTab = utilGroup:Tab({ Title = "Spoofers", Icon = "eye-off" })

        local devSec = homeTab:Section({ Title = "Credits", Icon = "user", Opened = true })
        devSec:Paragraph({
            Title = "Tetoware v" .. SCRIPT_VERSION,
            Desc = "This script is fully developed by InfinitelyMNDEV",
        })

        local teamSec = homeTab:Section({ Title = "Eclipse Team", Icon = "users", Opened = true })
        teamSec:Paragraph({ Title = "Member 1", Desc = "MNDEV" })
        teamSec:Paragraph({ Title = "Member 2", Desc = "x0b0unty" })
        teamSec:Paragraph({ Title = "Member 3", Desc = "Hero (aka Mahmood)" })

        githuhSec = homeTab:Section({ Title = "Githuh", Icon = "link", Opened = true })
        githuhSec:Paragraph({
            Title = "License",
            Desc = "This script is fully open source and licensed under the GNU GPL. You are free to view, modify and redistribute it.",
        })
        githuhSec:Paragraph({
            Title = "Github Link",
            Desc = REPO_URL,
        })

        themeSec = settingsTab:Section({ Title = "Themes", Icon = "palette", Opened = true })
        donationSec = settingsTab:Section({ Title = "Donation", Icon = "heart", Opened = true })
        miscSec = settingsTab:Section({ Title = "Misc", Icon = "wrench", Opened = true })
    end)

    if not okTabs then
        notify("Tetoware", "tabs failed to build: " .. tostring(tabErr), "info")
        return
    end

    local function tryElement(label, fn)
        local okEl, err = pcall(fn)
        if not okEl then
            notify("Tetoware", label .. " failed: " .. tostring(err), "info")
        end
    end

    tryElement("copy repo button", function()
        githuhSec:Button({
            Title = "Copy Repository Link",
            Desc = "puts the url on your clipboard",
            Icon = "copy",
            Callback = function()
                if copyToClipboard(REPO_URL) then
                    notify("Tetoware", "repo link copied to clipboard", "check")
                else
                    notify("Tetoware", "clipboard not available. " .. REPO_URL, "info")
                end
            end,
        })
    end)

    if lockTab then
        local coreSec = lockTab:Section({ Title = "Lock Core", Icon = "lock", Opened = true })
        tryElement("lock core", function()
            coreSec:Toggle({
                Title = "Enable Lock",
                Desc = "master switch, then Q or the hotbar tool to lock",
                Icon = "lock",
                Value = false,
                Callback = function(state)
                    lockEnabled = state
                    if state then
                        if not ensureNamecall() then
                            notify("Nerve Lock", "metatable hooks unavailable on this executor", "info")
                        end
                    else
                        lockDeactivate(true)
                    end
                end,
            })
        end)
        tryElement("lock keybind", function()
            coreSec:Keybind({
                Title = "Lock Toggle Key",
                Desc = "pc only, mobile uses the hotbar tool",
                Value = lockKey.Name,
                Callback = function(key)
                    if typeof(key) == "EnumItem" then
                        lockKey = key
                    else
                        pcall(function() lockKey = Enum.KeyCode[tostring(key)] end)
                    end
                end,
            })
        end)
        tryElement("lock tool toggle", function()
            coreSec:Toggle({
                Title = "Hotbar Tool",
                Desc = "gives a Nerve Lock tool, tap it to lock or unlock",
                Icon = "wrench",
                Value = IS_MOBILE,
                Callback = function(state)
                    setLockTool(state)
                end,
            })
        end)
        tryElement("lock part dropdown", function()
            coreSec:Dropdown({
                Title = "Aim Part",
                Values = { "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso" },
                Value = "HumanoidRootPart",
                Callback = function(opt)
                    lockPart = tostring(opt)
                end,
            })
        end)
        tryElement("lock pred input", function()
            numberInput(coreSec, {
                title = "Prediction",
                desc = "0.05 to 0.3",
                icon = "gauge",
                default = 0.13,
                min = 0.05,
                max = 0.3,
                apply = function(n)
                    lockPred = n
                    lockAuto = false
                end,
            })
        end)
        tryElement("lock auto pred", function()
            coreSec:Toggle({
                Title = "Auto Prediction",
                Desc = "ping based, overrides the manual value",
                Icon = "activity",
                Value = true,
                Callback = function(state)
                    lockAuto = state
                end,
            })
        end)
        tryElement("lock team check", function()
            coreSec:Toggle({
                Title = "Team Check",
                Desc = "wont lock onto your team",
                Icon = "users",
                Value = false,
                Callback = function(state)
                    lockTeam = state
                end,
            })
        end)
        tryElement("lock death unlock", function()
            coreSec:Toggle({
                Title = "Unlock On Death",
                Desc = "drops the target when knocked or dead",
                Icon = "skull",
                Value = true,
                Callback = function(state)
                    lockDeath = state
                end,
            })
        end)
        tryElement("lock fov input", function()
            numberInput(coreSec, {
                title = "Lock Range",
                desc = "max cursor distance, 10 to 1000",
                icon = "target",
                default = 300,
                min = 10,
                max = 1000,
                apply = function(n)
                    lockFov = n
                end,
            })
        end)

        local airSec = lockTab:Section({ Title = "Air Handler", Icon = "wind", Opened = true })
        tryElement("lock airshot", function()
            airSec:Toggle({
                Title = "Airshot",
                Desc = "aims at the feet while the target is airborne",
                Icon = "arrow-up",
                Value = true,
                Callback = function(state)
                    lockAir = state
                end,
            })
        end)
        tryElement("lock resolver", function()
            airSec:Toggle({
                Title = "Resolver",
                Desc = "handles anchored targets and speed exploits",
                Icon = "activity",
                Value = true,
                Callback = function(state)
                    lockResolver = state
                end,
            })
        end)
        tryElement("lock ground shield", function()
            airSec:Toggle({
                Title = "Ground Shield",
                Desc = "stops shots from landing underground",
                Icon = "chevrons-down",
                Value = true,
                Callback = function(state)
                    lockGround = state
                end,
            })
        end)

        local markSec = lockTab:Section({ Title = "Marker", Icon = "box", Opened = true })
        tryElement("marker toggle", function()
            markSec:Toggle({
                Title = "Show Marker",
                Desc = "highlights the locked target",
                Icon = "box",
                Value = true,
                Callback = function(state)
                    markerOn = state
                    if markerPart then
                        markerPart.Transparency = state and (markerStyle == "Box" and 0.7 or 0.75) or 1
                    end
                end,
            })
        end)
        tryElement("marker style", function()
            markSec:Dropdown({
                Title = "Marker Style",
                Values = { "Dot", "Box" },
                Value = "Dot",
                Callback = function(opt)
                    markerStyle = tostring(opt)
                    applyMarkerStyle()
                end,
            })
        end)
        tryElement("marker color", function()
            markSec:Colorpicker({
                Title = "Marker Color",
                Default = markerColor,
                Callback = function(color)
                    markerColor = color
                    applyMarkerStyle()
                end,
            })
        end)
        tryElement("tracer toggle", function()
            markSec:Toggle({
                Title = "Show Tracer",
                Desc = "line from your cursor to the target",
                Icon = "spline",
                Value = false,
                Callback = function(state)
                    tracerOn = state
                    if state and not espSupported then
                        notify("Nerve Lock", "drawing lib not available here", "info")
                    end
                end,
            })
        end)

        local profSec = lockTab:Section({ Title = "Profiles", Icon = "sliders", Opened = true })
        tryElement("range profiles", function()
            profSec:Toggle({
                Title = "Range Profiles",
                Desc = "prediction adjusts with target distance",
                Icon = "ruler",
                Value = false,
                Callback = function(state)
                    rangeProfiles = state
                end,
            })
        end)
        tryElement("weapon profiles", function()
            profSec:Toggle({
                Title = "Weapon Profiles",
                Desc = "lock range adjusts per equipped weapon",
                Icon = "crosshair",
                Value = false,
                Callback = function(state)
                    weaponProfiles = state
                end,
            })
        end)
        tryElement("remote arg input", function()
            profSec:Input({
                Title = "Remote Argument",
                Desc = "the mouse position arg this game uses",
                Placeholder = "UpdateMousePos",
                Callback = function(text)
                    if text and text ~= "" then
                        remoteArg = text
                    end
                end,
            })
        end)
    end

    if ghostTab then
        local coreSec = ghostTab:Section({ Title = "Silent Core", Icon = "ghost", Opened = true })
        tryElement("ghost toggle", function()
            coreSec:Toggle({
                Title = "Enable Ghost Aim",
                Desc = "client silent aim, toggled here or with T",
                Icon = "ghost",
                Value = false,
                Callback = function(state)
                    if state then
                        if ensureGhostHook() then
                            ghostOn = true
                        else
                            notify("Ghost Aim", "hookmetamethod not available on this executor", "info")
                        end
                    else
                        ghostOn = false
                        ghostTargetPart = nil
                    end
                end,
            })
        end)
        tryElement("ghost keybind", function()
            coreSec:Keybind({
                Title = "Ghost Aim Key",
                Desc = "quick toggle",
                Value = ghostKey.Name,
                Callback = function(key)
                    if typeof(key) == "EnumItem" then
                        ghostKey = key
                    else
                        pcall(function() ghostKey = Enum.KeyCode[tostring(key)] end)
                    end
                end,
            })
        end)
        tryElement("ghost part dropdown", function()
            coreSec:Dropdown({
                Title = "Aim Part",
                Values = { "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso" },
                Value = "UpperTorso",
                Callback = function(opt)
                    ghostPartName = tostring(opt)
                end,
            })
        end)
        tryElement("ghost pred input", function()
            numberInput(coreSec, {
                title = "Prediction",
                desc = "0.05 to 0.3",
                icon = "gauge",
                default = 0.13,
                min = 0.05,
                max = 0.3,
                apply = function(n)
                    ghostPred = n
                    ghostAuto = false
                end,
            })
        end)
        tryElement("ghost auto pred", function()
            coreSec:Toggle({
                Title = "Auto Prediction",
                Desc = "ping based",
                Icon = "activity",
                Value = false,
                Callback = function(state)
                    ghostAuto = state
                end,
            })
        end)
        tryElement("ghost chance input", function()
            numberInput(coreSec, {
                title = "Hit Chance",
                desc = "percent, 1 to 100",
                icon = "percent",
                default = 100,
                min = 1,
                max = 100,
                apply = function(n)
                    ghostChance = n
                end,
            })
        end)
        tryElement("ghost nearest part", function()
            coreSec:Toggle({
                Title = "Nearest Part",
                Desc = "targets whatever body part is closest to your cursor",
                Icon = "scan",
                Value = false,
                Callback = function(state)
                    ghostNearest = state
                end,
            })
        end)
        tryElement("ghost nearest point", function()
            coreSec:Toggle({
                Title = "Nearest Point",
                Desc = "snaps hits onto the part surface",
                Icon = "crosshair",
                Value = false,
                Callback = function(state)
                    ghostPoint = state
                end,
            })
        end)

        local checkSec = ghostTab:Section({ Title = "Checks", Icon = "shield", Opened = true })
        tryElement("ghost wall", function()
            checkSec:Toggle({
                Title = "Wall Check",
                Icon = "brick-wall",
                Value = true,
                Callback = function(state)
                    ghostWall = state
                end,
            })
        end)
        tryElement("ghost ko", function()
            checkSec:Toggle({
                Title = "Knocked Check",
                Icon = "skull",
                Value = true,
                Callback = function(state)
                    ghostKO = state
                end,
            })
        end)
        tryElement("ghost team", function()
            checkSec:Toggle({
                Title = "Team Check",
                Icon = "users",
                Value = false,
                Callback = function(state)
                    ghostTeam = state
                end,
            })
        end)
        tryElement("ghost airshot", function()
            checkSec:Toggle({
                Title = "Airshot",
                Desc = "aims at the feet when the target jumps",
                Icon = "arrow-up",
                Value = true,
                Callback = function(state)
                    ghostAir = state
                end,
            })
        end)
        tryElement("ghost ground", function()
            checkSec:Toggle({
                Title = "Ground Shield",
                Icon = "chevrons-down",
                Value = true,
                Callback = function(state)
                    ghostGround = state
                end,
            })
        end)

        local fovSec = ghostTab:Section({ Title = "Field", Icon = "target", Opened = true })
        tryElement("ghost fov show", function()
            fovSec:Toggle({
                Title = "Show FOV Circle",
                Icon = "circle",
                Value = false,
                Callback = function(state)
                    if state and not espSupported then
                        notify("Ghost Aim", "drawing lib not available here", "info")
                        return
                    end
                    if state then
                        ghostCircle = ensureCircle(ghostCircle)
                    end
                    ghostFovShow = state
                end,
            })
        end)
        tryElement("ghost fov input", function()
            numberInput(fovSec, {
                title = "FOV Radius",
                desc = "10 to 500",
                icon = "circle",
                default = 90,
                min = 10,
                max = 500,
                apply = function(n)
                    ghostFov = n
                end,
            })
        end)
    end

    if gazeTab then
        local coreSec = gazeTab:Section({ Title = "Gaze Core", Icon = "eye", Opened = true })
        tryElement("gaze toggle", function()
            coreSec:Toggle({
                Title = "Enable Gaze Lock",
                Desc = "camera lock, activate with the key below",
                Icon = "eye",
                Value = false,
                Callback = function(state)
                    gazeEnabled = state
                    if not state then
                        gazeDeactivate(true)
                    end
                end,
            })
        end)
        tryElement("gaze keybind", function()
            coreSec:Keybind({
                Title = "Gaze Key",
                Desc = "taps to lock, again to unlock",
                Value = gazeKey.Name,
                Callback = function(key)
                    if typeof(key) == "EnumItem" then
                        gazeKey = key
                    else
                        pcall(function() gazeKey = Enum.KeyCode[tostring(key)] end)
                    end
                end,
            })
        end)
        tryElement("gaze hold", function()
            coreSec:Toggle({
                Title = "Hold Mode",
                Desc = "only locked while the key is held",
                Icon = "hand",
                Value = false,
                Callback = function(state)
                    gazeHold = state
                end,
            })
        end)
        tryElement("gaze part dropdown", function()
            coreSec:Dropdown({
                Title = "Aim Part",
                Values = { "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso" },
                Value = "HumanoidRootPart",
                Callback = function(opt)
                    gazePart = tostring(opt)
                end,
            })
        end)
        tryElement("gaze pred input", function()
            numberInput(coreSec, {
                title = "Prediction",
                desc = "0.05 to 0.3",
                icon = "gauge",
                default = 0.13,
                min = 0.05,
                max = 0.3,
                apply = function(n)
                    gazePred = n
                    gazeAuto = false
                end,
            })
        end)
        tryElement("gaze auto pred", function()
            coreSec:Toggle({
                Title = "Auto Prediction",
                Icon = "activity",
                Value = false,
                Callback = function(state)
                    gazeAuto = state
                end,
            })
        end)

        local feelSec = gazeTab:Section({ Title = "Feel", Icon = "sliders", Opened = true })
        tryElement("gaze smooth", function()
            feelSec:Toggle({
                Title = "Smoothness",
                Icon = "waves",
                Value = false,
                Callback = function(state)
                    gazeSmooth = state
                end,
            })
        end)
        tryElement("gaze smooth amount", function()
            numberInput(feelSec, {
                title = "Smoothness Amount",
                desc = "0.01 to 0.5",
                icon = "gauge",
                default = 0.05,
                min = 0.01,
                max = 0.5,
                apply = function(n)
                    gazeAmount = n
                end,
            })
        end)
        tryElement("gaze air smooth", function()
            feelSec:Toggle({
                Title = "Air Smoothness",
                Desc = "different feel when the target is airborne",
                Icon = "wind",
                Value = true,
                Callback = function(state)
                    gazeAirSmooth = state
                end,
            })
        end)
        tryElement("gaze air amount", function()
            numberInput(feelSec, {
                title = "Air Amount",
                desc = "0.01 to 0.5",
                icon = "gauge",
                default = 0.08,
                min = 0.01,
                max = 0.5,
                apply = function(n)
                    gazeAirAmount = n
                end,
            })
        end)
        tryElement("gaze shake", function()
            feelSec:Toggle({
                Title = "Shake",
                Icon = "activity",
                Value = false,
                Callback = function(state)
                    gazeShake = state
                end,
            })
        end)
        tryElement("gaze shake power", function()
            numberInput(feelSec, {
                title = "Shake Power",
                desc = "1 to 20",
                icon = "gauge",
                default = 5,
                min = 1,
                max = 20,
                apply = function(n)
                    gazeShakePower = n
                end,
            })
        end)

        local safeSec = gazeTab:Section({ Title = "Safety", Icon = "shield", Opened = true })
        tryElement("gaze death", function()
            safeSec:Toggle({
                Title = "Unlock On Death",
                Desc = "yours or the targets",
                Icon = "skull",
                Value = true,
                Callback = function(state)
                    gazeDeath = state
                end,
            })
        end)
        tryElement("gaze wall", function()
            safeSec:Toggle({
                Title = "Wall Check",
                Desc = "unlocks when the target breaks line of sight",
                Icon = "brick-wall",
                Value = true,
                Callback = function(state)
                    gazeWall = state
                end,
            })
        end)
        tryElement("gaze fov show", function()
            safeSec:Toggle({
                Title = "Show FOV Circle",
                Icon = "circle",
                Value = false,
                Callback = function(state)
                    if state and not espSupported then
                        notify("Gaze Lock", "drawing lib not available here", "info")
                        return
                    end
                    if state then
                        gazeCircle = ensureCircle(gazeCircle)
                    end
                    gazeFovShow = state
                end,
            })
        end)
        tryElement("gaze fov input", function()
            numberInput(safeSec, {
                title = "FOV Radius",
                desc = "10 to 500",
                icon = "circle",
                default = 55,
                min = 10,
                max = 500,
                apply = function(n)
                    gazeFov = n
                end,
            })
        end)

        local extraSec = gazeTab:Section({ Title = "Extras", Icon = "sparkles", Opened = true })
        tryElement("gaze lookat", function()
            extraSec:Toggle({
                Title = "Look At",
                Desc = "your character faces the target",
                Icon = "eye",
                Value = false,
                Callback = function(state)
                    gazeLook = state
                end,
            })
        end)
        tryElement("gaze spectate", function()
            extraSec:Toggle({
                Title = "Spectate Target",
                Desc = "camera follows the target while locked",
                Icon = "video",
                Value = false,
                Callback = function(state)
                    gazeSpectate = state
                end,
            })
        end)
        tryElement("gaze strafe", function()
            extraSec:Toggle({
                Title = "Target Strafe",
                Desc = "orbits the target while locked",
                Icon = "rotate-cw",
                Value = false,
                Callback = function(state)
                    gazeStrafe = state
                end,
            })
        end)
        tryElement("gaze strafe dist", function()
            numberInput(extraSec, {
                title = "Strafe Distance",
                desc = "studs, 2 to 40",
                icon = "ruler",
                default = 8,
                min = 2,
                max = 40,
                apply = function(n)
                    gazeStrafeDist = n
                end,
            })
        end)
    end

    if drawTab then
        local qdSec = drawTab:Section({ Title = "Trigger Bot", Icon = "mouse-pointer-click", Opened = true })
        tryElement("trigger toggle", function()
            qdSec:Toggle({
                Title = "Enable Quick Draw",
                Desc = "auto fires when a target is picked up",
                Icon = "zap",
                Value = false,
                Callback = function(state)
                    triggerOn = state
                end,
            })
        end)
        tryElement("trigger delay", function()
            numberInput(qdSec, {
                title = "Fire Delay",
                desc = "seconds between shots, 0.05 to 2",
                icon = "timer",
                default = 0.25,
                min = 0.05,
                max = 2,
                apply = function(n)
                    triggerDelay = n
                end,
            })
        end)
        tryElement("trigger require lock", function()
            qdSec:Toggle({
                Title = "Only When Locked",
                Desc = "fires only while nerve lock has a target",
                Icon = "lock",
                Value = true,
                Callback = function(state)
                    triggerRequireLock = state
                end,
            })
        end)
        qdSec:Paragraph({
            Title = "Note",
            Desc = "On pc it clicks for you. On mobile it needs virtual input support from your executor.",
        })
    end

    if panicTab then
        local pSec = panicTab:Section({ Title = "Panic", Icon = "alert-triangle", Opened = true })
        pSec:Paragraph({
            Title = "What it does",
            Desc = "kills every combat feature and restores your camera in one tap.",
        })
        tryElement("panic button", function()
            pSec:Button({
                Title = "PANIC",
                Desc = "turn everything off right now",
                Icon = "power",
                Callback = panic,
            })
        end)
    end

    if hoverTab then
        local flySec = hoverTab:Section({ Title = "Hover", Icon = "feather", Opened = true })
        tryElement("fly toggle", function()
            flySec:Toggle({
                Title = "Enable Hover",
                Desc = "mobile joystick or wasd to move, jump to rise, ctrl to sink on pc",
                Icon = "feather",
                Value = false,
                Callback = function(state)
                    setFly(state)
                end,
            })
        end)
        tryElement("fly speed", function()
            numberInput(flySec, {
                title = "Speed",
                desc = "10 to 500",
                icon = "gauge",
                default = 50,
                min = 10,
                max = 500,
                apply = function(n)
                    flySpeed = n
                end,
            })
        end)
    end

    if rushTab then
        local sprintSec = rushTab:Section({ Title = "Sprint", Icon = "wind", Opened = true })
        tryElement("sprint toggle", function()
            sprintSec:Toggle({
                Title = "Enable Rush",
                Desc = "speed boost while moving",
                Icon = "wind",
                Value = false,
                Callback = function(state)
                    sprintOn = state
                end,
            })
        end)
        tryElement("sprint speed", function()
            numberInput(sprintSec, {
                title = "Rush Speed",
                desc = "20 to 300",
                icon = "gauge",
                default = 60,
                min = 20,
                max = 300,
                apply = function(n)
                    sprintSpeed = n
                end,
            })
        end)
        tryElement("sprint hold", function()
            sprintSec:Toggle({
                Title = "Hold Shift On Pc",
                Desc = "pc only, mobile always runs while enabled",
                Icon = "keyboard",
                Value = true,
                Callback = function(state)
                    sprintHold = state
                end,
            })
        end)

        local macroSec = rushTab:Section({ Title = "Fake Macro", Icon = "zap", Opened = true })
        tryElement("macro pc keybind", function()
            macroSec:Keybind({
                Title = "Macro Key",
                Desc = "pc only, toggles the speed glitch",
                Value = macroKey.Name,
                Callback = function(key)
                    if typeof(key) == "EnumItem" then
                        macroKey = key
                    else
                        pcall(function() macroKey = Enum.KeyCode[tostring(key)] end)
                    end
                end,
            })
        end)
        tryElement("macro tool toggle", function()
            macroSec:Toggle({
                Title = "Give Fake Macro Tool",
                Desc = "mobile users get a hotbar tool to toggle the macro",
                Icon = "wrench",
                Value = IS_MOBILE,
                Callback = function(state)
                    setMacroTool(state)
                end,
            })
        end)
        tryElement("macro power", function()
            numberInput(macroSec, {
                title = "Macro Power",
                desc = "velocity strength, 10 to 100",
                icon = "gauge",
                default = 30,
                min = 10,
                max = 100,
                apply = function(n)
                    macroPower = n
                end,
            })
        end)
    end

    if roamTab then
        local ncSec = roamTab:Section({ Title = "Pass Through", Icon = "wind", Opened = true })
        tryElement("noclip toggle", function()
            ncSec:Toggle({
                Title = "Noclip",
                Icon = "wind",
                Value = false,
                Callback = function(state)
                    noclipOn = state
                    if not state then
                        local char = LocalPlayer.Character
                        if char then
                            for _, p in ipairs(char:GetChildren()) do
                                if p:IsA("BasePart") then
                                    p.CanCollide = true
                                end
                            end
                        end
                    end
                end,
            })
        end)
        tryElement("inf jump toggle", function()
            ncSec:Toggle({
                Title = "Infinite Jump",
                Icon = "arrow-up",
                Value = false,
                Callback = function(state)
                    infJumpOn = state
                end,
            })
        end)
        tryElement("click tp toggle", function()
            ncSec:Toggle({
                Title = "Tap Teleport",
                Desc = "click or tap a spot to teleport there",
                Icon = "mouse-pointer",
                Value = false,
                Callback = function(state)
                    clickTpOn = state
                end,
            })
        end)
        local wSec = roamTab:Section({ Title = "World", Icon = "globe", Opened = true })
        tryElement("low grav toggle", function()
            wSec:Toggle({
                Title = "Low Gravity",
                Icon = "moon",
                Value = false,
                Callback = function(state)
                    lowGravOn = state
                    if state then
                        gravSaved = Workspace.Gravity
                        Workspace.Gravity = 60
                    elseif gravSaved then
                        Workspace.Gravity = gravSaved
                        gravSaved = nil
                    end
                end,
            })
        end)
        tryElement("vanish toggle", function()
            wSec:Toggle({
                Title = "Vanish",
                Desc = "seat method invisibility",
                Icon = "ghost",
                Value = false,
                Callback = function(state)
                    if state == vanishOn then return end
                    vanishOn = state
                    local char = LocalPlayer.Character
                    if state and char then
                        local root = char:FindFirstChild("HumanoidRootPart")
                        local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
                        if root and torso then
                            vanishSaved = root.CFrame
                            recordOrigForVanish = nil
                            char:PivotTo(CFrame.new(root.Position + Vector3.new(0, 1000, 0)))
                            task.wait(0.15)
                            local seat = Instance.new("Seat")
                            seat.Name = "TetowareSeat"
                            seat.Anchored = false
                            seat.CanCollide = false
                            seat.Transparency = 1
                            seat.CFrame = CFrame.new(root.Position + Vector3.new(0, 1000, 0))
                            seat.Parent = Workspace
                            local weld = Instance.new("Weld")
                            weld.Part0 = seat
                            weld.Part1 = torso
                            weld.Parent = seat
                            task.wait()
                            seat.CFrame = vanishSaved
                            for _, d in ipairs(char:GetDescendants()) do
                                if d:IsA("BasePart") or d:IsA("Decal") then
                                    recordOrig(d, "Transparency", d.Transparency)
                                    d.Transparency = 1
                                end
                            end
                            vanishSeat = seat
                        end
                    elseif not state then
                        if vanishSeat then
                            pcall(function() vanishSeat:Destroy() end)
                            vanishSeat = nil
                        end
                        local hum = getMyHumanoid()
                        if hum then hum.Sit = false end
                        local c = LocalPlayer.Character
                        if c then
                            for inst, props in pairs(glowOrig) do
                                if props.Transparency ~= nil and inst.Parent then
                                    pcall(function() inst.Transparency = props.Transparency end)
                                end
                            end
                            if vanishSaved then
                                c:PivotTo(vanishSaved)
                            end
                        end
                    end
                end,
            })
        end)
    end

    if whirlTab then
        local wSec = whirlTab:Section({ Title = "Whirl", Icon = "refresh-cw", Opened = true })
        tryElement("whirl keybind", function()
            wSec:Keybind({
                Title = "Whirl Key",
                Desc = "toggles the spin",
                Value = whirlKey.Name,
                Callback = function(key)
                    if typeof(key) == "EnumItem" then
                        whirlKey = key
                    else
                        pcall(function() whirlKey = Enum.KeyCode[tostring(key)] end)
                    end
                end,
            })
        end)
        tryElement("whirl speed", function()
            numberInput(wSec, {
                title = "Spin Speed",
                desc = "degrees per second, 100 to 5000",
                icon = "gauge",
                default = 500,
                min = 100,
                max = 5000,
                apply = function(n)
                    whirlSpeed = n
                end,
            })
        end)
    end

    if phaseTab then
        local pSec = phaseTab:Section({ Title = "Phase", Icon = "shuffle", Opened = true })
        tryElement("phase keybind", function()
            pSec:Keybind({
                Title = "Phase Key",
                Desc = "toggles the desync",
                Value = phaseKey.Name,
                Callback = function(key)
                    if typeof(key) == "EnumItem" then
                        phaseKey = key
                    else
                        pcall(function() phaseKey = Enum.KeyCode[tostring(key)] end)
                    end
                end,
            })
        end)
        pSec:Paragraph({
            Title = "Note",
            Desc = "while on, your position desyncs from the server every frame. heavy feature, use in short bursts.",
        })
    end

    if sinkTab then
        local sSec = sinkTab:Section({ Title = "Sink", Icon = "chevrons-down", Opened = true })
        tryElement("sink keybind", function()
            sSec:Keybind({
                Title = "Sink Key",
                Desc = "toggles going under the map",
                Value = sinkKey.Name,
                Callback = function(key)
                    if typeof(key) == "EnumItem" then
                        sinkKey = key
                    else
                        pcall(function() sinkKey = Enum.KeyCode[tostring(key)] end)
                    end
                end,
            })
        end)
        tryElement("sink depth", function()
            numberInput(sSec, {
                title = "Sink Depth",
                desc = "downward velocity, -10 to -80",
                icon = "chevrons-down",
                default = -35,
                min = -80,
                max = -10,
                apply = function(n)
                    sinkDepth = n
                end,
            })
        end)
    end

    if guardTab then
        local gSec = guardTab:Section({ Title = "Guard", Icon = "shield", Opened = true })
        tryElement("fling guard", function()
            gSec:Toggle({
                Title = "Fling Guard",
                Desc = "neutralizes velocity spikes on you and flags flingers",
                Icon = "shield",
                Value = false,
                Callback = function(state)
                    flingGuardOn = state
                    lastGoodPos = nil
                end,
            })
        end)
        tryElement("stomp guard", function()
            gSec:Toggle({
                Title = "Stomp Guard",
                Desc = "drops your parts before a stomp can land, once per life",
                Icon = "skull",
                Value = false,
                Callback = function(state)
                    stompGuardOn = state
                end,
            })
        end)
        tryElement("anti slow", function()
            gSec:Toggle({
                Title = "Debuff Shield",
                Desc = "keeps your walkspeed from being lowered",
                Icon = "shield-check",
                Value = false,
                Callback = function(state)
                    antiSlowOn = state
                    if state then
                        local hum = getMyHumanoid()
                        if hum then
                            antiSlowSpeed = math.max(hum.WalkSpeed, antiSlowSpeed)
                        end
                    end
                end,
            })
        end)
        tryElement("anti slow speed", function()
            numberInput(gSec, {
                title = "Protected Speed",
                desc = "the walkspeed the shield holds, 8 to 200",
                icon = "gauge",
                default = 16,
                min = 8,
                max = 200,
                apply = function(n)
                    antiSlowSpeed = n
                end,
            })
        end)
        tryElement("jump spam", function()
            gSec:Toggle({
                Title = "Jump Spam",
                Desc = "blocks jump cooldown and power nerfs",
                Icon = "arrow-up",
                Value = false,
                Callback = function(state)
                    jumpSpamOn = state
                end,
            })
        end)
    end

    if bodyTab then
        local glowSec = bodyTab:Section({ Title = "Glow", Icon = "sparkles", Opened = true })
        tryElement("weapon glow", function()
            glowSec:Toggle({
                Title = "Weapon Glow",
                Icon = "crosshair",
                Value = false,
                Callback = function(state)
                    weaponGlowOn = state
                    if not state and lastGlowTool then
                        restoreGlow()
                    end
                end,
            })
        end)
        tryElement("weapon glow color", function()
            glowSec:Colorpicker({
                Title = "Weapon Color",
                Default = weaponGlowColor,
                Callback = function(color)
                    weaponGlowColor = color
                end,
            })
        end)
        tryElement("body glow", function()
            glowSec:Toggle({
                Title = "Body Glow",
                Icon = "user",
                Value = false,
                Callback = function(state)
                    bodyGlowOn = state
                    if not state then
                        restoreGlow()
                    end
                end,
            })
        end)
        tryElement("body glow color", function()
            glowSec:Colorpicker({
                Title = "Body Color",
                Default = bodyGlowColor,
                Callback = function(color)
                    bodyGlowColor = color
                end,
            })
        end)
        local shapeSec = bodyTab:Section({ Title = "Shape", Icon = "scissors", Opened = true })
        tryElement("ghost leg", function()
            shapeSec:Toggle({
                Title = "Ghost Leg",
                Desc = "right leg goes invisible",
                Icon = "scissors",
                Value = false,
                Callback = function(state)
                    ghostLegOn = state
                    local char = LocalPlayer.Character
                    if char then
                        for _, n in ipairs({ "RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg" }) do
                            local p = char:FindFirstChild(n)
                            if p then
                                if state then
                                    recordOrig(p, "Transparency", p.Transparency)
                                    p.Transparency = 1
                                elseif glowOrig[p] and glowOrig[p].Transparency ~= nil then
                                    p.Transparency = glowOrig[p].Transparency
                                end
                            end
                        end
                    end
                end,
            })
        end)
        tryElement("head vanish", function()
            shapeSec:Toggle({
                Title = "Head Vanish",
                Desc = "head goes invisible",
                Icon = "user-x",
                Value = false,
                Callback = function(state)
                    headVanishOn = state
                    local char = LocalPlayer.Character
                    local head = char and char:FindFirstChild("Head")
                    if head then
                        if state then
                            recordOrig(head, "Transparency", head.Transparency)
                            head.Transparency = 1
                        elseif glowOrig[head] and glowOrig[head].Transparency ~= nil then
                            head.Transparency = glowOrig[head].Transparency
                        end
                    end
                end,
            })
        end)
    end

    if faceTab then
        local fSec = faceTab:Section({ Title = "Face Swap", Icon = "smile", Opened = true })
        tryElement("face dropdown", function()
            local names = { "Original" }
            for name in pairs(FACE_IDS) do
                table.insert(names, name)
            end
            fSec:Dropdown({
                Title = "Face",
                Desc = "swaps your face texture client side",
                Values = names,
                Value = "Original",
                Callback = function(opt)
                    applyFace(tostring(opt))
                end,
            })
        end)
    end

    if emoteTab then
        local eSec = emoteTab:Section({ Title = "Emotes", Icon = "user", Opened = true })
        for name in pairs(EMOTES) do
            tryElement("emote " .. name, function()
                eSec:Button({
                    Title = name,
                    Icon = "play",
                    Callback = function()
                        playEmote(name)
                    end,
                })
            end)
        end
    end

    if serverTab then
        local sSec = serverTab:Section({ Title = "Server", Icon = "server", Opened = true })
        tryElement("rejoin", function()
            sSec:Button({
                Title = "Rejoin",
                Desc = "back into this same server",
                Icon = "rotate-cw",
                Callback = rejoin,
            })
        end)
        tryElement("server scout", function()
            sSec:Button({
                Title = "Server Scout",
                Desc = "hops to the lowest ping server with room",
                Icon = "radar",
                Callback = serverScout,
            })
        end)
        tryElement("remote shield", function()
            sSec:Toggle({
                Title = "Remote Shield",
                Desc = "drops known kick and ban remotes",
                Icon = "shield",
                Value = false,
                Callback = function(state)
                    remoteShield = state
                    if state and not ensureNamecall() then
                        notify("Remote Shield", "metatable hooks unavailable here", "info")
                    end
                end,
            })
        end)
        tryElement("group spoof", function()
            sSec:Toggle({
                Title = "Group Spoof",
                Desc = "every group check returns true",
                Icon = "users",
                Value = false,
                Callback = function(state)
                    groupSpoof = state
                    if state and not ensureNamecall() then
                        notify("Group Spoof", "metatable hooks unavailable here", "info")
                    end
                end,
            })
        end)
        tryElement("zoom lock", function()
            sSec:Toggle({
                Title = "Lock Zoom",
                Desc = "freezes the camera scroll distance",
                Icon = "search",
                Value = false,
                Callback = function(state)
                    zoomLocked = state
                    setZoomLock(state)
                end,
            })
        end)
        local sortSec = serverTab:Section({ Title = "Gear Sort", Icon = "package", Opened = true })
        local sortList = "[Double-Barrel SG],[Revolver],[TacticalShotgun],[Shotgun],[SMG]"
        tryElement("gear list input", function()
            sortSec:Input({
                Title = "Tool Names",
                Desc = "comma separated, front of backpack first",
                Placeholder = sortList,
                Callback = function(text)
                    if text and text ~= "" then
                        sortList = text
                    end
                end,
            })
        end)
        tryElement("gear sort button", function()
            sortSec:Button({
                Title = "Sort Now",
                Icon = "check",
                Callback = function()
                    gearSort(sortList)
                end,
            })
        end)
        local chatSec = serverTab:Section({ Title = "Chat Commands", Icon = "message-square", Opened = true })
        tryElement("chat cmds toggle", function()
            chatSec:Toggle({
                Title = "Enable Chat Commands",
                Desc = "!pred 0.13 | !fov 300 | !lock | !unlock | !rejoin",
                Icon = "message-square",
                Value = false,
                Callback = function(state)
                    chatCmdsOn = state
                end,
            })
        end)
    end

    if spoofTab then
        local memSec = spoofTab:Section({ Title = "Memory Mask", Icon = "cpu", Opened = true })
        tryElement("mem toggle", function()
            memSec:Toggle({
                Title = "Enable Memory Mask",
                Icon = "cpu",
                Value = false,
                Callback = function(state)
                    local ok = setMemoryMask(state)
                    spooferMem = (state and ok) or (not state and false) or spooferMem
                    if state then
                        spooferMem = ok
                    end
                end,
            })
        end)
        tryElement("mem min", function()
            numberInput(memSec, {
                title = "Minimum MB",
                desc = "100 to 4000",
                icon = "gauge",
                default = 900,
                min = 100,
                max = 4000,
                apply = function(n)
                    memMin = n
                end,
            })
        end)
        tryElement("mem max", function()
            numberInput(memSec, {
                title = "Maximum MB",
                desc = "100 to 4000",
                icon = "gauge",
                default = 990,
                min = 100,
                max = 4000,
                apply = function(n)
                    memMax = n
                end,
            })
        end)
        local pingSec = spoofTab:Section({ Title = "Ping Mask", Icon = "activity", Opened = true })
        tryElement("ping toggle", function()
            pingSec:Toggle({
                Title = "Enable Ping Mask",
                Icon = "activity",
                Value = false,
                Callback = function(state)
                    local ok = setPingMask(state)
                    spooferPing = ok
                end,
            })
        end)
        tryElement("ping min", function()
            numberInput(pingSec, {
                title = "Minimum Ping",
                desc = "5 to 300",
                icon = "gauge",
                default = 20,
                min = 5,
                max = 300,
                apply = function(n)
                    pingMin = n
                end,
            })
        end)
        tryElement("ping max", function()
            numberInput(pingSec, {
                title = "Maximum Ping",
                desc = "5 to 300",
                icon = "gauge",
                default = 35,
                min = 5,
                max = 300,
                apply = function(n)
                    pingMax = n
                end,
            })
        end)
    end

    tryElement("theme dropdown", function()
        themeSec:Dropdown({
            Title = "UI Theme",
            Desc = "each theme comes with its own background",
            Values = THEME_NAMES,
            Value = startTheme,
            Callback = function(opt)
                local name = tostring(opt)
                pcall(function() WindUI:SetTheme(name) end)
                applyBackground(name)
                saveTheme(name)
                notify("Theme", "switched to " .. name, "palette")
            end,
        })
    end)

    tryElement("copy donation button", function()
        donationSec:Button({
            Title = "Copy Donation Link",
            Desc = "grabs the game pass link for your browser",
            Icon = "copy",
            Callback = function()
                if copyToClipboard(GAMEPASS_URL) then
                    notify("Tetoware", "donation link copied to clipboard", "check")
                else
                    notify("Tetoware", "clipboard not available. " .. GAMEPASS_URL, "info")
                end
            end,
        })
    end)

    tryElement("image background toggle", function()
        miscSec:Toggle({
            Title = "Turn off image background",
            Desc = "untick to hide the themed background image",
            Icon = "image",
            Value = true,
            Callback = function(state)
                bgEnabled = state
                if window then
                    pcall(function()
                        window:SetBackgroundImageTransparency(state and BG_TRANSPARENCY or 1)
                    end)
                end
            end,
        })
    end)

    notify("Tetoware", "v" .. SCRIPT_VERSION .. " loaded" .. (IS_MOBILE and " on mobile" or " on pc"), "info")
end

openMainUI = function()
    if window then return end
    if winduiReady then
        buildWindow()
        return
    end
    if winduiFailed then
        notify("Tetoware", "windui failed to load, cant build the window", "info")
        return
    end
    task.spawn(function()
        local waited = 0
        while not winduiReady and not winduiFailed and waited < 30 do
            task.wait(1)
            waited += 1
        end
        if winduiReady and not window then
            buildWindow()
        elseif winduiFailed and not window then
            notify("Tetoware", "windui never loaded, check your executor", "info")
        end
    end)
end

task.spawn(tryLoadWindUI)

if neverShowSaved() then
    openMainUI()
else
    local ok = pcall(showDonationPopup)
    if not ok then
        if popupGui then
            popupGui:Destroy()
            popupGui = nil
        end
        popupOpen = false
        notify("Tetoware", "donate popup failed, opening the ui anyway", "info")
        openMainUI()
    end
end
