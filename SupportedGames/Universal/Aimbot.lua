-- Tetoware Universal - Version 1.0 Beta
-- Made by Apogee Team
-- This script is licensed under MIT
-- Coded specifically by Sable

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

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
local TETO_ICON = 125388499892456

local TAB_ICONS = {
    Home = 0,
    Settings = 0,
    Aimbot = 0,
    ESP = 0,
}

local RAYFIELD_URLS = {
    "https://sirius.menu/gen2",
    "https://sirius.menu/gen2-preview",
}

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local Rayfield = nil
local rayfieldReady = false
local rayfieldFailed = false
local window = nil
local popupGui = nil
local popupOpen = false
local purchaseConn = nil

local openMainUI
local showDonationPopup

local function tryLoadRayfield()
    for _, url in ipairs(RAYFIELD_URLS) do
        local ok, lib = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if ok and type(lib) == "table" then
            Rayfield = lib
            rayfieldReady = true
            return
        end
    end
    rayfieldFailed = true
end

local function notify(title, content)
    if window then
        local ok = pcall(function()
            window:Notify({
                title = title,
                content = content,
                icon = TETO_ICON,
                duration = 5,
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
        return name
    end
    return nil
end

local THEME_TABLES = {
    ["Tetoware - Default"] = {
        WindowColor = Color3.fromRGB(18, 13, 14),
        ShadowColor = Color3.fromRGB(0, 0, 0),
        TabColor = Color3.fromRGB(236, 210, 210),
        TabBackground = Color3.fromRGB(217, 43, 43),
        TabStroke = Color3.fromRGB(140, 25, 25),
        CornerRoundness = UDim.new(0, 12),
        PillCornerRadius = UDim.new(0, 10),
        ElementCornerRadius = UDim.new(0, 8),
        SurfaceStroke = Color3.fromRGB(45, 35, 36),
        LiveAnimation = false,
    },
    ["Mikuware"] = {
        WindowColor = Color3.fromRGB(12, 18, 18),
        ShadowColor = Color3.fromRGB(0, 0, 0),
        TabColor = Color3.fromRGB(207, 233, 230),
        TabBackground = Color3.fromRGB(57, 197, 187),
        TabStroke = Color3.fromRGB(25, 95, 90),
        CornerRoundness = UDim.new(0, 12),
        PillCornerRadius = UDim.new(0, 10),
        ElementCornerRadius = UDim.new(0, 8),
        SurfaceStroke = Color3.fromRGB(30, 42, 41),
        LiveAnimation = false,
    },
    ["Neruware"] = {
        WindowColor = Color3.fromRGB(19, 16, 10),
        ShadowColor = Color3.fromRGB(0, 0, 0),
        TabColor = Color3.fromRGB(236, 224, 196),
        TabBackground = Color3.fromRGB(227, 180, 0),
        TabStroke = Color3.fromRGB(120, 95, 10),
        CornerRoundness = UDim.new(0, 12),
        PillCornerRadius = UDim.new(0, 10),
        ElementCornerRadius = UDim.new(0, 8),
        SurfaceStroke = Color3.fromRGB(42, 36, 26),
        LiveAnimation = false,
    },
}

local THEME_NAMES = { "Tetoware - Default", "Mikuware", "Neruware" }

local function applyTheme(name)
    local tbl = THEME_TABLES[name] or THEME_TABLES["Tetoware - Default"]
    if window then
        pcall(function()
            window:ChangeTheme(tbl)
        end)
    end
end

local Aimbot = {
    enabled = false,
    teamCheck = true,
    wallCheck = true,
    aimPart = "Head",
    smoothness = 0.15,
    showFOV = true,
    rainbow = false,
    circleColor = Color3.fromRGB(255, 255, 255),
    radius = 150,
}

local ESP = {
    highlight = false,
    tracers = false,
    boxes = false,
    skeleton = false,
    teamColor = false,
    teamCheck = true,
    customColor = Color3.fromRGB(217, 43, 43),
}

local fovCircle = nil
local drawingOK = false

local function newLine()
    if not drawingOK then return nil end
    local ok, obj = pcall(function()
        local d = Drawing.new("Line")
        d.Thickness = 1
        d.Visible = false
        return d
    end)
    if ok and obj then
        return obj
    end
    return nil
end

local function newSquare()
    if not drawingOK then return nil end
    local ok, obj = pcall(function()
        local d = Drawing.new("Square")
        d.Thickness = 1
        d.Filled = false
        d.Visible = false
        return d
    end)
    if ok and obj then
        return obj
    end
    return nil
end

local aimToggle = nil
local smoothInput = nil
local fovInput = nil

local function toggleAimbot()
    Aimbot.enabled = not Aimbot.enabled
    if aimToggle then
        pcall(function()
            aimToggle:Set(Aimbot.enabled, true)
        end)
    end
    notify("Aimbot", Aimbot.enabled and "enabled" or "disabled")
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function hasLineOfSight(cam, char, part)
    if not Aimbot.wallCheck then return true end
    local filter = {}
    if LocalPlayer.Character then
        filter[#filter + 1] = LocalPlayer.Character
    end
    filter[#filter + 1] = cam
    rayParams.FilterDescendantsInstances = filter
    local origin = cam.CFrame.Position
    local result = Workspace:Raycast(origin, part.Position - origin, rayParams)
    if result then
        return result.Instance:IsDescendantOf(char)
    end
    return true
end

local candidates = {}

local function getTarget(cam, centerX, centerY)
    table.clear(candidates)
    local myTeam = LocalPlayer.Team
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    if not (Aimbot.teamCheck and plr.Team ~= nil and plr.Team == myTeam) then
                        local part = char:FindFirstChild(Aimbot.aimPart) or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
                        if part then
                            local sp, on = cam:WorldToViewportPoint(part.Position)
                            if on then
                                local dx, dy = sp.X - centerX, sp.Y - centerY
                                local dist = math.sqrt(dx * dx + dy * dy)
                                if dist <= Aimbot.radius then
                                    candidates[#candidates + 1] = {char = char, part = part, dist = dist}
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if #candidates == 0 then return nil, nil end
    if #candidates > 1 then
        table.sort(candidates, function(a, b)
            return a.dist < b.dist
        end)
    end
    for i = 1, math.min(#candidates, 3) do
        local c = candidates[i]
        if hasLineOfSight(cam, c.char, c.part) then
            return c.part, c.char
        end
    end
    return nil, nil
end

local R15_BONES = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}

local R6_BONES = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local espPool = {}

local function hideEntry(e)
    if e.tracer and e.tracer.Visible then
        e.tracer.Visible = false
    end
    if e.box and e.box.Visible then
        e.box.Visible = false
    end
    for i = 1, #e.lines do
        local l = e.lines[i]
        if l and l.Visible then
            l.Visible = false
        end
    end
    if e.highlight and e.highlight.Enabled then
        e.highlight.Enabled = false
    end
end

local function destroyEntry(e)
    if e.tracer then
        pcall(function() e.tracer:Remove() end)
        e.tracer = nil
    end
    if e.box then
        pcall(function() e.box:Remove() end)
        e.box = nil
    end
    for i = 1, #e.lines do
        local l = e.lines[i]
        if l then
            pcall(function() l:Remove() end)
        end
        e.lines[i] = nil
    end
    if e.highlight then
        pcall(function() e.highlight:Destroy() end)
        e.highlight = nil
    end
end

local function buildParts(char)
    local bones
    if char:FindFirstChild("UpperTorso") then
        bones = R15_BONES
    else
        bones = R6_BONES
    end
    local list = {}
    for i = 1, #bones do
        local a = char:FindFirstChild(bones[i][1])
        local b = char:FindFirstChild(bones[i][2])
        if a and b then
            list[#list + 1] = {a, b}
        end
    end
    return list
end

local function updatePlayerESP(plr, cam, centerX, centerY, myTeam)
    local e = espPool[plr]
    if not e then
        e = {char = nil, highlight = nil, tracer = nil, box = nil, lines = {}, parts = nil, color = nil}
        espPool[plr] = e
    end

    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum or hum.Health <= 0 or (ESP.teamCheck and plr.Team ~= nil and plr.Team == myTeam) then
        hideEntry(e)
        return
    end

    if e.char ~= char then
        e.char = char
        e.parts = buildParts(char)
        e.color = nil
        if e.highlight then
            pcall(function() e.highlight:Destroy() end)
            e.highlight = nil
        end
    end

    local col
    if ESP.teamColor then
        col = plr.TeamColor.Color
    else
        col = ESP.customColor
    end

    if e.color ~= col then
        e.color = col
        if e.tracer then e.tracer.Color = col end
        if e.box then e.box.Color = col end
        for i = 1, #e.lines do
            local l = e.lines[i]
            if l then
                l.Color = col
            end
        end
    end

    if ESP.highlight then
        local h = e.highlight
        if not h then
            h = Instance.new("Highlight")
            h.FillTransparency = 1
            h.OutlineTransparency = 0
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            e.highlight = h
        end
        if h.Parent ~= char then
            h.Parent = char
        end
        if not h.Enabled then
            h.Enabled = true
        end
        if h.OutlineColor ~= col then
            h.OutlineColor = col
        end
    elseif e.highlight and e.highlight.Enabled then
        e.highlight.Enabled = false
    end

    if ESP.tracers then
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if root then
            local sp, on = cam:WorldToViewportPoint(root.Position)
            if on then
                local t = e.tracer
                if not t then
                    t = newLine()
                    if t then
                        t.Color = col
                        e.tracer = t
                    end
                end
                if t then
                    t.From = Vector2.new(centerX, centerY)
                    t.To = Vector2.new(sp.X, sp.Y)
                    if not t.Visible then
                        t.Visible = true
                    end
                end
            elseif e.tracer and e.tracer.Visible then
                e.tracer.Visible = false
            end
        elseif e.tracer and e.tracer.Visible then
            e.tracer.Visible = false
        end
    elseif e.tracer and e.tracer.Visible then
        e.tracer.Visible = false
    end

    if ESP.boxes then
        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if head and root then
            local hPos, on = cam:WorldToViewportPoint(head.Position)
            if on then
                local fPos = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                local h = math.abs(fPos.Y - hPos.Y)
                if h > 2 then
                    local w = h * 0.55
                    local b = e.box
                    if not b then
                        b = newSquare()
                        if b then
                            b.Color = col
                            e.box = b
                        end
                    end
                    if b then
                        b.Size = Vector2.new(w, h)
                        b.Position = Vector2.new(hPos.X - w * 0.5, hPos.Y)
                        if not b.Visible then
                            b.Visible = true
                        end
                    end
                end
            elseif e.box and e.box.Visible then
                e.box.Visible = false
            end
        elseif e.box and e.box.Visible then
            e.box.Visible = false
        end
    elseif e.box and e.box.Visible then
        e.box.Visible = false
    end

    if ESP.skeleton and e.parts then
        for i = 1, #e.parts do
            local pair = e.parts[i]
            local aPos, aOn = cam:WorldToViewportPoint(pair[1].Position)
            local bPos, bOn = cam:WorldToViewportPoint(pair[2].Position)
            local l = e.lines[i]
            if not l then
                l = newLine()
                if l then
                    l.Color = col
                    e.lines[i] = l
                end
            end
            if l then
                if aOn and bOn then
                    l.From = Vector2.new(aPos.X, aPos.Y)
                    l.To = Vector2.new(bPos.X, bPos.Y)
                    if not l.Visible then
                        l.Visible = true
                    end
                elseif l.Visible then
                    l.Visible = false
                end
            end
        end
        for i = #e.parts + 1, #e.lines do
            local l = e.lines[i]
            if l and l.Visible then
                l.Visible = false
            end
        end
    elseif #e.lines > 0 then
        for i = 1, #e.lines do
            local l = e.lines[i]
            if l and l.Visible then
                l.Visible = false
            end
        end
    end
end

local function updateESP(cam, centerX, centerY)
    local myTeam = LocalPlayer.Team
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            updatePlayerESP(plr, cam, centerX, centerY, myTeam)
        end
    end
end

local renderConn = nil
local espWasOn = false

local function onRenderStep()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local centerX, centerY = vp.X * 0.5, vp.Y * 0.5

    if fovCircle then
        local show = Aimbot.showFOV
        if show then
            fovCircle.Position = Vector2.new(centerX, centerY)
            fovCircle.Radius = Aimbot.radius
            if Aimbot.rainbow then
                fovCircle.Color = Color3.fromHSV((os.clock() * 0.45) % 1, 1, 1)
            else
                fovCircle.Color = Aimbot.circleColor
            end
        end
        if fovCircle.Visible ~= show then
            fovCircle.Visible = show
        end
    end

    if Aimbot.enabled then
        local part = getTarget(cam, centerX, centerY)
        if part then
            cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, part.Position), Aimbot.smoothness)
        end
    end

    if ESP.highlight or ESP.tracers or ESP.boxes or ESP.skeleton then
        espWasOn = true
        updateESP(cam, centerX, centerY)
    elseif espWasOn then
        espWasOn = false
        for _, e in pairs(espPool) do
            hideEntry(e)
        end
    end
end

local toolProto = nil
local toolConn = nil

local function giveTool()
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not bp then return end
    local char = LocalPlayer.Character
    if bp:FindFirstChild("Aimbot") or (char and char:FindFirstChild("Aimbot")) then return end
    local t = toolProto:Clone()
    t.Activated:Connect(function()
        toggleAimbot()
    end)
    t.Parent = bp
end

local removeConn = nil
local featuresReady = false

local function initFeatures()
    if featuresReady then return end
    featuresReady = true

    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1.5
        fovCircle.Color = Aimbot.circleColor
        fovCircle.Filled = false
        fovCircle.Transparency = 0.5
        fovCircle.NumSides = 64
        fovCircle.Visible = false
        drawingOK = true
    end)

    if IS_MOBILE then
        toolProto = Instance.new("Tool")
        toolProto.Name = "Aimbot"
        toolProto.RequiresHandle = false
        toolProto.CanBeDropped = false
        giveTool()
        toolConn = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.3)
            giveTool()
        end)
    end

    removeConn = Players.PlayerRemoving:Connect(function(plr)
        local e = espPool[plr]
        if e then
            destroyEntry(e)
            espPool[plr] = nil
        end
    end)

    renderConn = RunService.RenderStepped:Connect(onRenderStep)
end

local function cleanup()
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
    if toolConn then
        toolConn:Disconnect()
        toolConn = nil
    end
    if removeConn then
        removeConn:Disconnect()
        removeConn = nil
    end
    for _, e in pairs(espPool) do
        destroyEntry(e)
    end
    espPool = {}
    espWasOn = false
    if fovCircle then
        pcall(function() fovCircle:Remove() end)
        fovCircle = nil
    end
    drawingOK = false
    pcall(function()
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then
            local t = bp:FindFirstChild("Aimbot")
            if t then t:Destroy() end
        end
        local ch = LocalPlayer.Character
        if ch then
            local t2 = ch:FindFirstChild("Aimbot")
            if t2 then t2:Destroy() end
        end
    end)
    featuresReady = false
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
    accent = Color3.fromHex("#D92B2B"),
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
            notify("Tetoware", "donation link copied. if no purchase window opened, buy it in your browser")
        else
            notify("Tetoware", "no clipboard here. donation link: " .. GAMEPASS_URL)
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

local function tabProps(name)
    local id = TAB_ICONS[name]
    if type(id) == "number" and id > 0 then
        return { name = name, icon = id }
    end
    return { name = name }
end

local function buildWindow()
    if window then return end
    if not Rayfield then
        notify("Tetoware", "rayfield didnt load, cant build the window")
        return
    end

    local savedTheme = loadSavedTheme()
    local startTheme = THEME_TABLES[savedTheme] and savedTheme or "Tetoware - Default"

    local ok, result = pcall(function()
        return Rayfield:CreateWindow({
            name = "Tetoware",
            subtitle = "By Apogee Team",
            icon = TETO_ICON,
            theme = THEME_TABLES[startTheme],
            sidebarLayout = true,
            profile = "v" .. SCRIPT_VERSION,
            showName = "Tetoware",
            showIcon = TETO_ICON,
            showIconOnly = true,
            configuration = {
                autoSave = true,
                autoLoad = true,
                fileName = "Tetoware",
            },
        })
    end)
    if not ok or type(result) ~= "table" then
        notify("Tetoware", "window failed to build: " .. tostring(result))
        return
    end
    window = result

    local homeTab, settingsTab, aimTab, espTab
    local okTabs, tabErr = pcall(function()
        window:CreateSection({ name = "Information" })
        homeTab = window:CreateTab(tabProps("Home"))
        settingsTab = window:CreateTab(tabProps("Settings"))
        window:CreateSection({ name = "Features" })
        aimTab = window:CreateTab(tabProps("Aimbot"))
        espTab = window:CreateTab(tabProps("ESP"))

        homeTab:CreateSection({ name = "Credits" })
        homeTab:CreateText({
            name = "Tetoware v" .. SCRIPT_VERSION,
            text = "This script is fully developed by InfinitelyMNDEV",
        })

        homeTab:CreateSection({ name = "Apogee Team" })
        homeTab:CreateText({ name = "Member 1", text = "MNDEV" })
        homeTab:CreateText({ name = "Member 2", text = "x0b0unty" })
        homeTab:CreateText({ name = "Member 3", text = "Hero (aka Mahmood)" })

        homeTab:CreateSection({ name = "Githuh" })
        homeTab:CreateText({
            name = "License",
            text = "This script is fully open source and licensed under MIT. You are free to view, modify and redistribute it.",
        })
        homeTab:CreateText({ name = "Github Link", text = REPO_URL })
        homeTab:CreateButton({
            name = "Copy Repository Link",
            description = "puts the url on your clipboard",
            callback = function()
                if copyToClipboard(REPO_URL) then
                    notify("Tetoware", "repo link copied to clipboard")
                else
                    notify("Tetoware", "clipboard not available. " .. REPO_URL)
                end
            end,
        })

        settingsTab:CreateSection({ name = "Themes" })
        settingsTab:CreateDropdown({
            name = "UI Theme",
            description = "red, cyan or yellow",
            options = THEME_NAMES,
            value = startTheme,
            callback = function(selected)
                local name = tostring(selected)
                if not THEME_TABLES[name] then
                    name = "Tetoware - Default"
                end
                applyTheme(name)
                saveTheme(name)
                notify("Theme", "switched to " .. name)
            end,
        })

        settingsTab:CreateSection({ name = "Donation" })
        settingsTab:CreateButton({
            name = "Copy Donation Link",
            description = "grabs the game pass link for your browser",
            callback = function()
                if copyToClipboard(GAMEPASS_URL) then
                    notify("Tetoware", "donation link copied to clipboard")
                else
                    notify("Tetoware", "clipboard not available. " .. GAMEPASS_URL)
                end
            end,
        })

        settingsTab:CreateSection({ name = "Misc" })
        settingsTab:CreateText({
            name = "Menu Keybind",
            text = "The show/hide keybind lives in Rayfield's own settings tab, along with its config system.",
        })
        settingsTab:CreateButton({
            name = "Unload Tetoware",
            description = "removes everything",
            callback = function()
                cleanup()
                pcall(function()
                    window:Unload()
                end)
                window = nil
                notify("Tetoware", "unloaded, thanks for trying it")
            end,
        })
    end)

    if not okTabs or not aimTab or not espTab then
        notify("Tetoware", "tabs failed to build: " .. tostring(tabErr))
        return
    end

    tryElement("aiming section", function()
        aimTab:CreateSection({ name = "Aiming" })
    end)
    tryElement("aimbot toggle", function()
        aimToggle = aimTab:CreateToggle({
            name = "Enable Aimbot",
            value = false,
            flag = "AimbotMaster",
            callback = function(v)
                Aimbot.enabled = v
            end,
        })
    end)
    tryElement("team check toggle", function()
        aimTab:CreateToggle({
            name = "Team Check",
            value = true,
            flag = "AimbotTeamCheck",
            callback = function(v)
                Aimbot.teamCheck = v
            end,
        })
    end)
    tryElement("wall check toggle", function()
        aimTab:CreateToggle({
            name = "Wall Check",
            value = true,
            callback = function(v)
                Aimbot.wallCheck = v
            end,
        })
    end)
    tryElement("aim part dropdown", function()
        aimTab:CreateDropdown({
            name = "Aim Part",
            options = { "Head", "HumanoidRootPart", "Torso", "UpperTorso" },
            value = "Head",
            callback = function(selected)
                Aimbot.aimPart = selected
            end,
        })
    end)
    tryElement("smoothness input", function()
        smoothInput = aimTab:CreateInput({
            name = "Smoothness",
            value = tostring(Aimbot.smoothness),
            numeric = true,
            clearOnFocus = true,
            callback = function(text)
                local n = tonumber(text)
                if n then
                    local clamped = math.clamp(n, 0.01, 1)
                    Aimbot.smoothness = clamped
                    if clamped ~= n and smoothInput then
                        pcall(function()
                            smoothInput:Set(tostring(clamped))
                        end)
                    end
                end
            end,
        })
    end)

    tryElement("fov section", function()
        aimTab:CreateSection({ name = "FOV Circle" })
    end)
    tryElement("fov toggle", function()
        aimTab:CreateToggle({
            name = "Show FOV Circle",
            value = true,
            callback = function(v)
                Aimbot.showFOV = v
            end,
        })
    end)
    tryElement("rainbow toggle", function()
        aimTab:CreateToggle({
            name = "Rainbow FOV Circle",
            value = false,
            callback = function(v)
                Aimbot.rainbow = v
            end,
        })
    end)
    tryElement("circle color picker", function()
        aimTab:CreateColorPicker({
            name = "Circle Color",
            color = Aimbot.circleColor,
            callback = function(c)
                Aimbot.circleColor = c
            end,
        })
    end)
    tryElement("fov size input", function()
        fovInput = aimTab:CreateInput({
            name = "FOV Size",
            value = tostring(Aimbot.radius),
            numeric = true,
            clearOnFocus = true,
            callback = function(text)
                local n = tonumber(text)
                if n then
                    local clamped = math.clamp(n, 20, 800)
                    Aimbot.radius = clamped
                    if clamped ~= n and fovInput then
                        pcall(function()
                            fovInput:Set(tostring(clamped))
                        end)
                    end
                end
            end,
        })
    end)

    tryElement("controls section", function()
        aimTab:CreateSection({ name = "Controls" })
    end)
    tryElement("aimbot keybind", function()
        aimTab:CreateKeybind({
            name = "Toggle Aimbot",
            value = Enum.KeyCode.Q,
            callback = function()
                toggleAimbot()
            end,
            onChanged = function(key)
                local kname = key
                if typeof(key) == "EnumItem" then
                    kname = key.Name
                end
                notify("Aimbot", "keybind set to " .. tostring(kname))
            end,
        })
    end)
    tryElement("controls note", function()
        aimTab:CreateText({
            text = IS_MOBILE
                and "Tap the Aimbot hotbar tool to toggle."
                or "Press the keybind above to toggle.",
        })
    end)

    tryElement("players section", function()
        espTab:CreateSection({ name = "Players" })
    end)
    tryElement("highlight toggle", function()
        espTab:CreateToggle({
            name = "Highlight Players",
            value = false,
            callback = function(v)
                ESP.highlight = v
            end,
        })
    end)
    tryElement("tracer toggle", function()
        espTab:CreateToggle({
            name = "Tracers",
            value = false,
            callback = function(v)
                ESP.tracers = v
            end,
        })
    end)
    tryElement("box toggle", function()
        espTab:CreateToggle({
            name = "Boxes",
            value = false,
            callback = function(v)
                ESP.boxes = v
            end,
        })
    end)
    tryElement("skeleton toggle", function()
        espTab:CreateToggle({
            name = "Skeleton",
            value = false,
            callback = function(v)
                ESP.skeleton = v
            end,
        })
    end)
    tryElement("esp team check toggle", function()
        espTab:CreateToggle({
            name = "Team Check",
            value = true,
            flag = "ESPTeamCheck",
            callback = function(v)
                ESP.teamCheck = v
            end,
        })
    end)

    tryElement("colors section", function()
        espTab:CreateSection({ name = "Colors" })
    end)
    tryElement("team color toggle", function()
        espTab:CreateToggle({
            name = "Team Color",
            value = false,
            callback = function(v)
                ESP.teamColor = v
            end,
        })
    end)
    tryElement("custom color picker", function()
        espTab:CreateColorPicker({
            name = "Custom Color",
            color = ESP.customColor,
            callback = function(c)
                ESP.customColor = c
            end,
        })
    end)

    local okFeat, featErr = pcall(initFeatures)
    if not okFeat then
        notify("Tetoware", "features failed to start: " .. tostring(featErr))
    end

    notify("Tetoware", "v" .. SCRIPT_VERSION .. " loaded" .. (IS_MOBILE and " on mobile" or " on pc"))
end

tryElement = tryElement or function(label, fn)
    local okEl, err = pcall(fn)
    if not okEl then
        notify("Tetoware", label .. " failed: " .. tostring(err))
    end
end

openMainUI = function()
    if window then return end
    if rayfieldReady then
        buildWindow()
        return
    end
    if rayfieldFailed then
        notify("Tetoware", "rayfield failed to load, check your executor")
        return
    end
    task.spawn(function()
        local waited = 0
        while not rayfieldReady and not rayfieldFailed and waited < 30 do
            task.wait(1)
            waited += 1
        end
        if rayfieldReady and not window then
            buildWindow()
        elseif rayfieldFailed and not window then
            notify("Tetoware", "rayfield never loaded, check your executor")
        end
    end)
end

task.spawn(tryLoadRayfield)

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
        notify("Tetoware", "donate popup failed, opening the ui anyway")
        openMainUI()
    end
end
