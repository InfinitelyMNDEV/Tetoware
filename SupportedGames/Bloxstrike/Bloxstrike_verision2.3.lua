-- Tetoware - Blox Strike
-- Verision: 2.3
-- This script is licensed under GNU GPL and is created by Eclipse Team

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    LocalPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

local SCRIPT_VERSION = "2.3"
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
    accent = Color3.fromHex("#D92B2B"),
    red = Color3.fromHex("#FF6B7E"),
}

local scriptActive = true

local highlightFolder = nil
local highlightConns = {}
local terrorState = false
local ctState = false
local highlightMode = "Fixed"
local updateDebounce = false

local TERROR_COLOR = Color3.fromRGB(255, 255, 0)
local CT_COLOR = Color3.fromRGB(0, 0, 139)

local function getCharacterTeam(character)
    local armor = character:FindFirstChild("CharacterArmor")
    if not armor then return nil end
    if armor:FindFirstChild("Balaclava") then
        return "Terrorist"
    end
    if armor:FindFirstChild("Helmet") or armor:FindFirstChild("HeadCover") then
        return "Counter-Terrorist"
    end
    return nil
end

local function resolveTeamName(player, character)
    if character then
        local armorTeam = getCharacterTeam(character)
        if armorTeam then return armorTeam end
    end
    if player then
        local ok, teamName = pcall(function()
            return player.Team and player.Team.Name or nil
        end)
        if ok and teamName then
            if teamName == "Terrorists" or teamName == "Terrorist" then return "Terrorist" end
            if teamName == "Counter-Terrorists" or teamName == "Counter-Terrorist" then return "Counter-Terrorist" end
        end
    end
    if character then
        local attr = character:GetAttribute("Team")
        if attr == "Terrorists" or attr == "Terrorist" then return "Terrorist" end
        if attr == "Counter-Terrorists" or attr == "Counter-Terrorist" then return "Counter-Terrorist" end
        local parent = character.Parent
        local parentName = parent and parent.Name
        if parentName == "Terrorists" or parentName == "Terrorist" then return "Terrorist" end
        if parentName == "Counter-Terrorists" or parentName == "Counter-Terrorist" then return "Counter-Terrorist" end
    end
    return nil
end

local function updateHighlights()
    if not highlightFolder or not highlightFolder.Parent then return end
    for _, character in ipairs(highlightFolder:GetChildren()) do
        if character:IsA("Model") then
            local existing = character:FindFirstChild("TeamHighlight")
            local team = getCharacterTeam(character)
            local wanted = (team == "Terrorist" and terrorState) or (team == "Counter-Terrorist" and ctState)
            if wanted then
                local color = (team == "Terrorist") and TERROR_COLOR or CT_COLOR
                if existing then
                    existing.FillColor = color
                    existing.OutlineColor = color
                else
                    local hl = Instance.new("Highlight")
                    hl.Name = "TeamHighlight"
                    hl.FillColor = color
                    hl.OutlineColor = color
                    hl.FillTransparency = 0.5
                    hl.OutlineTransparency = 0
                    hl.Adornee = character
                    hl.Parent = character
                end
            elseif existing then
                existing:Destroy()
            end
        end
    end
end

local function requestHighlightUpdate()
    if updateDebounce then return end
    updateDebounce = true
    task.delay(0.1, function()
        updateDebounce = false
        updateHighlights()
    end)
end

local function disconnectHighlightWatchers()
    for _, c in ipairs(highlightConns) do
        pcall(function() c:Disconnect() end)
    end
    highlightConns = {}
end

local function watchHighlightFolder(folder)
    if highlightFolder == folder then return end
    highlightFolder = folder
    table.insert(highlightConns, folder.ChildAdded:Connect(requestHighlightUpdate))
    table.insert(highlightConns, folder.ChildRemoved:Connect(requestHighlightUpdate))
    table.insert(highlightConns, folder.DescendantAdded:Connect(requestHighlightUpdate))
end

local function ensureHighlightFolder()
    if highlightFolder and highlightFolder.Parent then return true end
    highlightFolder = nil
    local folder = Workspace:FindFirstChild("Characters")
    if folder then
        watchHighlightFolder(folder)
        return true
    end
    return false
end

local function clearHighlights()
    disconnectHighlightWatchers()
    if highlightFolder and highlightFolder.Parent then
        for _, character in ipairs(highlightFolder:GetChildren()) do
            if character:IsA("Model") then
                local hl = character:FindFirstChild("TeamHighlight")
                if hl then
                    hl:Destroy()
                end
            end
        end
    end
    highlightFolder = nil
end

local espSupported = false
pcall(function()
    espSupported = type(Drawing) == "table" and type(Drawing.new) == "function"
end)

local OUTLINE_COLOR = Color3.fromRGB(15, 15, 15)
local NAME_COLOR = Color3.fromRGB(255, 255, 255)
local DISTANCE_COLOR = Color3.fromRGB(179, 179, 179)
local EXTRA_DEFAULT_COLOR = Color3.fromRGB(235, 235, 235)
local FOV_COLOR = Color3.fromRGB(199, 84, 114)
local HEALTH_GREEN = Color3.fromRGB(50, 205, 50)
local HEALTH_RED = Color3.fromRGB(255, 0, 0)

local boxesState = false
local skeletonsState = false
local namesState = false
local healthState = false
local distanceState = false
local teamCheckState = false
local maxRender = 2500

local espObjects = {}
local boneCache = setmetatable({}, { __mode = "k" })
local projCache = setmetatable({}, { __mode = "k" })
local projFrame = 0

local BONE_MAP_R15 = {
    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
    { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
    { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}

local BONE_MAP_R6 = {
    { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
    { "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}

local function newDrawing(kind, props)
    local ok, obj = pcall(Drawing.new, kind)
    if not ok or not obj then return nil end
    for k, v in pairs(props) do
        pcall(function() obj[k] = v end)
    end
    return obj
end

local function getBones(char)
    local cached = boneCache[char]
    if cached then return cached end
    local isR15 = char:FindFirstChild("UpperTorso") ~= nil
    local map = isR15 and BONE_MAP_R15 or BONE_MAP_R6
    local list = {}
    for _, pair in ipairs(map) do
        local a = char:FindFirstChild(pair[1])
        local b = char:FindFirstChild(pair[2])
        if a and b then
            list[#list + 1] = { a, b }
        end
    end
    if #list > 0 then
        boneCache[char] = list
    end
    return list
end

local function project(camera, part)
    local e = projCache[part]
    if e and e.f == projFrame then return e end
    local pos, vis = camera:WorldToViewportPoint(part.Position)
    if e then
        e.x, e.y, e.v, e.f = pos.X, pos.Y, vis, projFrame
    else
        e = { x = pos.X, y = pos.Y, v = vis, f = projFrame }
        projCache[part] = e
    end
    return e
end

local function hidePlayerESP(o)
    if o.Box then o.Box.Visible = false end
    if o.BoxOutline then o.BoxOutline.Visible = false end
    if o.Name then o.Name.Visible = false end
    if o.Distance then o.Distance.Visible = false end
    if o.Health then o.Health.Visible = false end
    if o.HealthOutline then o.HealthOutline.Visible = false end
    if o.Bones then
        for _, l in ipairs(o.Bones) do
            if l then l.Visible = false end
        end
    end
    o.hidden = true
end

local function hideIfVisible(player)
    local o = espObjects[player]
    if o and not o.hidden then
        hidePlayerESP(o)
    end
end

local function removePlayerESP(player)
    local o = espObjects[player]
    if not o then return end
    for key, obj in pairs(o) do
        if key == "Bones" then
            for _, l in ipairs(obj) do
                if l then pcall(function() l:Remove() end) end
            end
        elseif key ~= "hidden" and key ~= "lastDist" and obj then
            pcall(function() obj:Remove() end)
        end
    end
    espObjects[player] = nil
end

local function extrasOffHide()
    for player in pairs(espObjects) do
        local o = espObjects[player]
        if o and not o.hidden then
            hidePlayerESP(o)
        end
    end
end

local function drawPlayerESP(player, char, root, humanoid, pTeam, camera, camPos)
    local o = espObjects[player]
    if not o then
        o = { hidden = true, lastDist = -1 }
        espObjects[player] = o
    end
    local rootProj = project(camera, root)
    if not rootProj.v then
        if not o.hidden then hidePlayerESP(o) end
        return
    end
    local color = EXTRA_DEFAULT_COLOR
    if teamCheckState then
        if pTeam == "Terrorist" then
            color = TERROR_COLOR
        elseif pTeam == "Counter-Terrorist" then
            color = CT_COLOR
        end
    end
    local needBox = boxesState or namesState or healthState or distanceState
    local rootPos = rootProj
    local boxX, boxY, height
    if needBox then
        local head = char:FindFirstChild("Head")
        local headProj, legProj
        if head then
            headProj = project(camera, head)
            boxY = headProj.y
        else
            local pos, vis = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 2, 0))
            boxY = pos.Y
            headProj = { x = pos.X, y = pos.Y, v = vis }
        end
        legProj = project(camera, root)
        local legWorld = root.Position - Vector3.new(0, 3, 0)
        local legPos, legVis = camera:WorldToViewportPoint(legWorld)
        height = math.abs(headProj.y - legPos.Y)
        boxX = rootPos.x - height / 3.2
    end

    if boxesState then
        if o.Box == nil then
            o.BoxOutline = newDrawing("Square", { Thickness = 2, Filled = false, Transparency = 0.5, Color = OUTLINE_COLOR, Visible = false }) or false
            o.Box = newDrawing("Square", { Thickness = 1, Filled = false, Transparency = 1, Visible = false }) or false
        end
        if o.Box and o.BoxOutline then
            local w = height / 1.6
            o.Box.Size = Vector2.new(w, height)
            o.Box.Position = Vector2.new(boxX, boxY)
            o.Box.Color = color
            o.Box.Visible = true
            o.BoxOutline.Size = Vector2.new(w, height)
            o.BoxOutline.Position = Vector2.new(boxX, boxY)
            o.BoxOutline.Visible = true
        end
    elseif o.Box then
        o.Box.Visible = false
        if o.BoxOutline then o.BoxOutline.Visible = false end
    end

    if skeletonsState then
        local bones = getBones(char)
        if bones and #bones > 0 then
            if o.Bones == nil then
                local lines = {}
                for _ = 1, 15 do
                    local line = newDrawing("Line", { Thickness = 1, Transparency = 1, Visible = false })
                    if line then table.insert(lines, line) end
                end
                o.Bones = lines
            end
            local lines = o.Bones
            for i, pair in ipairs(bones) do
                local line = lines[i]
                if line then
                    local pa = project(camera, pair[1])
                    local pb = project(camera, pair[2])
                    if pa.v and pb.v then
                        line.From = Vector2.new(pa.x, pa.y)
                        line.To = Vector2.new(pb.x, pb.y)
                        line.Color = color
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                end
            end
            for i = #bones + 1, #lines do
                if lines[i] then lines[i].Visible = false end
            end
        end
    elseif o.Bones then
        for _, l in ipairs(o.Bones) do
            if l then l.Visible = false end
        end
    end

    if namesState then
        if o.Name == nil then
            o.Name = newDrawing("Text", { Center = true, Outline = true, Font = 1, Size = 13, Color = NAME_COLOR, Text = player.Name, Visible = false })
        end
        if o.Name then
            o.Name.Position = Vector2.new(rootPos.x, boxY - 15)
            o.Name.Visible = true
        end
    elseif o.Name then
        o.Name.Visible = false
    end

    if distanceState then
        if o.Distance == nil then
            o.Distance = newDrawing("Text", { Center = true, Outline = true, Font = 1, Size = 12, Color = DISTANCE_COLOR, Visible = false })
        end
        if o.Distance then
            local d = math.floor((camPos - root.Position).Magnitude)
            if d ~= o.lastDist then
                o.Distance.Text = tostring(d) .. "m"
                o.lastDist = d
            end
            o.Distance.Position = Vector2.new(rootPos.x, boxY + height + 2)
            o.Distance.Visible = true
        end
    elseif o.Distance then
        o.Distance.Visible = false
    end

    if healthState and humanoid then
        if o.Health == nil then
            o.HealthOutline = newDrawing("Square", { Thickness = 1, Filled = true, Transparency = 0.5, Color = OUTLINE_COLOR, Visible = false }) or false
            o.Health = newDrawing("Square", { Thickness = 1, Filled = true, Transparency = 1, Visible = false }) or false
        end
        if o.Health and o.HealthOutline then
            local pct = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
            local barX = boxX - 6
            local healthHeight = height * pct
            o.Health.Color = HEALTH_GREEN:Lerp(HEALTH_RED, 1 - pct)
            o.HealthOutline.Position = Vector2.new(barX - 1, boxY - 1)
            o.HealthOutline.Size = Vector2.new(4, height + 2)
            o.Health.Position = Vector2.new(barX, boxY + (height - healthHeight))
            o.Health.Size = Vector2.new(2, healthHeight)
            o.Health.Visible = true
            o.HealthOutline.Visible = true
        end
    elseif o.Health then
        o.Health.Visible = false
        if o.HealthOutline then o.HealthOutline.Visible = false end
    end

    o.hidden = false
end

local silentState = false
local silentT = false
local silentCT = false
local wallbangState = false
local hitPartMode = "Head"
local fovShowState = false
local fovRadius = 130
local silentTarget = nil
local fovCircle = nil
local fovVisible = false
local lastFovPos = nil
local hookStarted = false
local hookReady = nil

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
local excludeChar = nil

local function isVisible(target, origin)
    if wallbangState then return true end
    if not target or not target.Parent then return false end
    local char = LocalPlayer.Character
    if char ~= excludeChar then
        excludeChar = char
        rayParams.FilterDescendantsInstances = char and { char } or {}
    end
    local result = Workspace:Raycast(origin, target.Position - origin, rayParams)
    if not result then return true end
    local model = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
    return model and Players:GetPlayerFromCharacter(model) ~= nil
end

local function resolveHitPart(char)
    local mode = hitPartMode
    if mode == "Random" then
        mode = (math.random(2) == 1) and "Head" or "Body"
    end
    local part
    if mode == "Head" then
        part = char:FindFirstChild("Head")
    else
        part = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("LowerTorso")
    end
    return part or char:FindFirstChild("Head") or char.PrimaryPart
end

local function ensureFovCircle()
    if fovCircle or not espSupported then return end
    fovCircle = newDrawing("Circle", { Filled = false, Thickness = 2, NumSides = 64, Color = FOV_COLOR, Transparency = 1, Visible = false })
end

local function ensureSilentHook()
    if hookStarted then return end
    if typeof(hookfunction) ~= "function" or typeof(getgc) ~= "function" then
        hookReady = false
        return
    end
    hookStarted = true
    task.spawn(function()
        local bulletClass = nil
        for _ = 1, 45 do
            if not scriptActive then return end
            pcall(function()
                for _, obj in next, getgc(true) do
                    if type(obj) == "table" and typeof(rawget(obj, "_performRaycast")) == "function" and rawget(obj, "getTrueSpread") ~= nil then
                        bulletClass = obj
                        return
                    end
                end
            end)
            if bulletClass then break end
            task.wait(0.5)
        end
        if not scriptActive then return end
        if not bulletClass then
            hookReady = false
            if silentState then
                notify("Silent Aim", "game hook not found, silent aim wont work here", "info")
            end
            return
        end
        local oldRaycast
        oldRaycast = hookfunction(bulletClass._performRaycast, function(...)
            local returns = table.pack(oldRaycast(...))
            local result = returns[1]
            if silentState and silentTarget and type(result) == "table" then
                pcall(function()
                    local hits = rawget(result, "Hits")
                    if type(hits) ~= "table" or not silentTarget.Parent then return end
                    local aimPos = silentTarget.Position
                    local lastIndex = nil
                    for index, hit in pairs(hits) do
                        if type(hit) == "table" then
                            if lastIndex == nil or index > lastIndex then lastIndex = index end
                        end
                    end
                    local finalHit = lastIndex and hits[lastIndex]
                    if type(finalHit) ~= "table" then return end
                    finalHit.Instance = silentTarget
                    finalHit.Position = aimPos
                    if finalHit.Exit ~= nil then finalHit.Exit = false end
                    local origin = rawget(result, "Origin")
                    if typeof(origin) == "Vector3" then
                        local delta = aimPos - origin
                        local length = delta.Magnitude
                        if length > 0.001 then
                            result.Distance = length
                            result.Direction = delta.Unit
                            local unit = delta.Unit
                            for index, hit in pairs(hits) do
                                if index ~= lastIndex and type(hit) == "table" and typeof(hit.Position) == "Vector3" then
                                    local along = (hit.Position - origin):Dot(unit)
                                    if along > length then
                                        hit.Position = origin + unit * (length * 0.5)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
            return table.unpack(returns, 1, returns.n)
        end)
        hookReady = true
        if silentState then
            notify("Silent Aim", "hook ready, aiming works now", "check")
        end
    end)
end

local connections = {}

table.insert(connections, Players.PlayerRemoving:Connect(removePlayerESP))

local renderConn = RunService.RenderStepped:Connect(function()
    projFrame += 1
    local camera = Workspace.CurrentCamera
    if not camera then
        if fovCircle and fovVisible then
            fovCircle.Visible = false
            fovVisible = false
        end
        return
    end
    if fovCircle then
        if fovShowState then
            local center = camera.ViewportSize / 2
            if not fovVisible or lastFovPos ~= center then
                fovCircle.Position = center
                lastFovPos = center
            end
            if not fovVisible or fovCircle.Radius ~= fovRadius then
                fovCircle.Radius = fovRadius
            end
            if not fovVisible then
                fovCircle.Visible = true
                fovVisible = true
            end
        elseif fovVisible then
            fovCircle.Visible = false
            fovVisible = false
        end
    end
    local anyExtras = boxesState or skeletonsState or namesState or healthState or distanceState
    if not anyExtras and not silentState then return end
    local camPos = camera.CFrame.Position
    local needTeams = silentState or teamCheckState
    local myTeam = nil
    if needTeams then
        myTeam = resolveTeamName(LocalPlayer, LocalPlayer.Character)
    end
    local screenCenter = silentState and (camera.ViewportSize / 2) or nil
    local bestPart = nil
    local closestDist = math.huge
    local players = Players:GetPlayers()
    for i = 1, #players do
        local player = players[i]
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char.Parent and char.Parent.Name ~= "Debris" then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char.PrimaryPart
                local isDead = char:GetAttribute("Dead") == true or (humanoid ~= nil and humanoid.Health <= 0)
                if silentState and not isDead and root then
                    local pTeam = resolveTeamName(player, char)
                    local teamOK
                    if pTeam == "Terrorist" then
                        teamOK = silentT
                    elseif pTeam == "Counter-Terrorist" then
                        teamOK = silentCT
                    else
                        teamOK = silentT and silentCT
                    end
                    if teamOK and char:GetAttribute("Invincible") ~= true then
                        local part = resolveHitPart(char)
                        if part then
                            local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                            if onScreen then
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                                if dist <= fovRadius and dist < closestDist then
                                    if wallbangState or isVisible(part, camPos) then
                                        closestDist = dist
                                        bestPart = part
                                    end
                                end
                            end
                        end
                    end
                end
                if anyExtras then
                    if isDead or not root then
                        hideIfVisible(player)
                    else
                        local pTeam = teamCheckState and resolveTeamName(player, char) or nil
                        local hidden = teamCheckState and myTeam ~= nil and pTeam == myTeam
                        if not hidden and (camPos - root.Position).Magnitude > maxRender then
                            hidden = true
                        end
                        if hidden then
                            hideIfVisible(player)
                        else
                            drawPlayerESP(player, char, root, humanoid, pTeam, camera, camPos)
                        end
                    end
                end
            elseif anyExtras then
                hideIfVisible(player)
            end
        end
    end
    silentTarget = bestPart
end)

table.insert(connections, renderConn)

task.spawn(function()
    local folder = Workspace:WaitForChild("Characters", 10)
    if not scriptActive then return end
    if folder then
        watchHighlightFolder(folder)
        if terrorState or ctState then
            requestHighlightUpdate()
        end
    end
end)

task.spawn(function()
    while scriptActive do
        task.wait(2.5)
        if not scriptActive then break end
        if highlightMode == "Fixed" and (terrorState or ctState) then
            if not highlightFolder or not highlightFolder.Parent then
                disconnectHighlightWatchers()
                highlightFolder = nil
                local folder = Workspace:FindFirstChild("Characters")
                if folder then
                    watchHighlightFolder(folder)
                end
            end
            updateHighlights()
        end
    end
end)

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

unloadAll = function()
    scriptActive = false
    popupOpen = false
    terrorState = false
    ctState = false
    silentState = false
    silentT = false
    silentCT = false
    silentTarget = nil
    boxesState = false
    skeletonsState = false
    namesState = false
    healthState = false
    distanceState = false
    clearHighlights()
    for player in pairs(espObjects) do
        removePlayerESP(player)
    end
    boneCache = setmetatable({}, { __mode = "k" })
    projCache = setmetatable({}, { __mode = "k" })
    if fovCircle then
        pcall(function() fovCircle:Remove() end)
        fovCircle = nil
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

    local creditsTab, settingsTab, repoSec, themeSec, uiSec, miscSec
    local revealSec, highlightSec, extrasSec
    local gunSec, drawSec
    local okTabs, tabErr = pcall(function()
        local homeGroup = window:Section({ Title = "Home", Opened = true })
        creditsTab = homeGroup:Tab({ Title = "Credits", Icon = "info" })
        settingsTab = homeGroup:Tab({ Title = "Settings", Icon = "settings" })

        local localGroup = window:Section({ Title = "LocalPlayer", Opened = true })
        local visualsTab = localGroup:Tab({ Title = "Visuals", Icon = "eye" })

        local weaponGroup = window:Section({ Title = "Local Weapon", Opened = true })
        local weaponTab = weaponGroup:Tab({ Title = "Weapon Settings", Icon = "crosshair" })

        local creditsSec = creditsTab:Section({ Title = "Credits", Opened = true })
        creditsSec:Paragraph({
            Title = "Tetoware v" .. SCRIPT_VERSION,
            Desc = "Made by Eclipse Team. Main developer: MNDEV. Team members: Bounty and Mahmood.",
        })
        creditsSec:Paragraph({
            Title = "License",
            Desc = "GNU GPL, fully open source.",
        })

        repoSec = creditsTab:Section({ Title = "Repository", Opened = true })
        repoSec:Paragraph({
            Title = "GitHub",
            Desc = REPO_URL,
        })

        themeSec = settingsTab:Section({ Title = "Theme", Opened = true })
        uiSec = settingsTab:Section({ Title = "Interface", Opened = true })
        miscSec = settingsTab:Section({ Title = "Misc", Opened = true })

        revealSec = visualsTab:Section({ Title = "Reveal Mode", Icon = "layers", Opened = true })
        highlightSec = visualsTab:Section({ Title = "Highlight", Icon = "highlighter", Opened = true })
        extrasSec = visualsTab:Section({ Title = "Extras", Icon = "boxes", Opened = true })

        gunSec = weaponTab:Section({ Title = "Gun Attachments", Icon = "crosshair", Opened = true })
        drawSec = weaponTab:Section({ Title = "Drawing", Icon = "pen-tool", Opened = true })
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

    tryElement("copy button", function()
        repoSec:Button({
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

    if revealSec then
        tryElement("highlight mode dropdown", function()
            revealSec:Dropdown({
                Title = "Highlight Mode",
                Desc = "fixed rescans and rebinds so nobody gets missed",
                Values = { "Legacy", "Fixed" },
                Value = "Fixed",
                Callback = function(opt)
                    highlightMode = tostring(opt) == "Legacy" and "Legacy" or "Fixed"
                    requestHighlightUpdate()
                end,
            })
        end)
    end

    if highlightSec then
        tryElement("terrorist toggle", function()
            highlightSec:Toggle({
                Title = "Highlight Terrorist",
                Desc = "yellow outline on terrorist team",
                Icon = "bomb",
                Value = false,
                Callback = function(state)
                    terrorState = state
                    if state and not ensureHighlightFolder() then
                        notify("Highlight", "characters folder not found in this game", "info")
                    end
                    requestHighlightUpdate()
                end,
            })
        end)
        tryElement("counter terrorist toggle", function()
            highlightSec:Toggle({
                Title = "Highlight Counter-Terrorist",
                Desc = "blue outline on counter terrorist team",
                Icon = "shield",
                Value = false,
                Callback = function(state)
                    ctState = state
                    if state and not ensureHighlightFolder() then
                        notify("Highlight", "characters folder not found in this game", "info")
                    end
                    requestHighlightUpdate()
                end,
            })
        end)
    end

    if extrasSec then
        tryElement("boxes toggle", function()
            local el
            el = extrasSec:Toggle({
                Title = "Draw Boxes",
                Icon = "box",
                Value = false,
                Callback = function(state)
                    if state and not espSupported then
                        notify("Visuals", "drawing lib not available on this executor", "info")
                        pcall(function() el:Set(false) end)
                        return
                    end
                    boxesState = state
                    extrasOffHide()
                end,
            })
        end)
        tryElement("skeletons toggle", function()
            local el
            el = extrasSec:Toggle({
                Title = "Draw Skeletons",
                Icon = "bone",
                Value = false,
                Callback = function(state)
                    if state and not espSupported then
                        notify("Visuals", "drawing lib not available on this executor", "info")
                        pcall(function() el:Set(false) end)
                        return
                    end
                    skeletonsState = state
                    extrasOffHide()
                end,
            })
        end)
        tryElement("names toggle", function()
            local el
            el = extrasSec:Toggle({
                Title = "Display Names",
                Icon = "type",
                Value = false,
                Callback = function(state)
                    if state and not espSupported then
                        notify("Visuals", "drawing lib not available on this executor", "info")
                        pcall(function() el:Set(false) end)
                        return
                    end
                    namesState = state
                    extrasOffHide()
                end,
            })
        end)
        tryElement("health toggle", function()
            local el
            el = extrasSec:Toggle({
                Title = "Display Health",
                Icon = "heart-pulse",
                Value = false,
                Callback = function(state)
                    if state and not espSupported then
                        notify("Visuals", "drawing lib not available on this executor", "info")
                        pcall(function() el:Set(false) end)
                        return
                    end
                    healthState = state
                    extrasOffHide()
                end,
            })
        end)
        tryElement("distance toggle", function()
            local el
            el = extrasSec:Toggle({
                Title = "Display Distance",
                Icon = "ruler",
                Value = false,
                Callback = function(state)
                    if state and not espSupported then
                        notify("Visuals", "drawing lib not available on this executor", "info")
                        pcall(function() el:Set(false) end)
                        return
                    end
                    distanceState = state
                    extrasOffHide()
                end,
            })
        end)
        tryElement("team check toggle", function()
            extrasSec:Toggle({
                Title = "Team Check",
                Desc = "extras only, hides teammates and colors the rest like the highlight",
                Icon = "users",
                Value = false,
                Callback = function(state)
                    teamCheckState = state
                end,
            })
        end)
        tryElement("max render input", function()
            numberInput(extrasSec, {
                title = "Max Render",
                desc = "extras only, 100 to 5000",
                icon = "gauge",
                default = 2500,
                min = 100,
                max = 5000,
                apply = function(n)
                    maxRender = n
                end,
            })
        end)
    end

    if gunSec then
        tryElement("silent aim toggle", function()
            gunSec:Toggle({
                Title = "Silent Aim",
                Desc = "master switch, pick teams below",
                Icon = "crosshair",
                Value = false,
                Callback = function(state)
                    silentState = state
                    if state then
                        ensureSilentHook()
                        if hookReady == false then
                            notify("Silent Aim", "game hook not found, silent aim wont work here", "info")
                        end
                    end
                end,
            })
        end)
        tryElement("silent aim t toggle", function()
            gunSec:Toggle({
                Title = "Silent Aim - T",
                Desc = "targets terrorists",
                Icon = "bomb",
                Value = false,
                Callback = function(state)
                    silentT = state
                end,
            })
        end)
        tryElement("silent aim ct toggle", function()
            gunSec:Toggle({
                Title = "Silent Aim - CT",
                Desc = "targets counter terrorists",
                Icon = "shield",
                Value = false,
                Callback = function(state)
                    silentCT = state
                end,
            })
        end)
        tryElement("wallbang toggle", function()
            gunSec:Toggle({
                Title = "WallBang",
                Desc = "ignores wall checks when picking targets",
                Icon = "brick-wall",
                Value = false,
                Callback = function(state)
                    wallbangState = state
                end,
            })
        end)
        tryElement("target part dropdown", function()
            gunSec:Dropdown({
                Title = "Target Part",
                Desc = "where silent aim lands",
                Values = { "Head", "Body", "Random" },
                Value = "Head",
                Callback = function(opt)
                    local v = tostring(opt)
                    if v == "Head" or v == "Body" or v == "Random" then
                        hitPartMode = v
                    end
                end,
            })
        end)
    end

    if drawSec then
        tryElement("show fov toggle", function()
            local el
            el = drawSec:Toggle({
                Title = "Show FOV",
                Icon = "target",
                Value = false,
                Callback = function(state)
                    if state and not espSupported then
                        notify("Visuals", "drawing lib not available on this executor", "info")
                        pcall(function() el:Set(false) end)
                        return
                    end
                    if state then
                        ensureFovCircle()
                    end
                    fovShowState = state
                end,
            })
        end)
        tryElement("fov radius input", function()
            numberInput(drawSec, {
                title = "FOV Radius",
                desc = "10 to 500",
                icon = "circle",
                default = 130,
                min = 10,
                max = 500,
                apply = function(n)
                    fovRadius = n
                end,
            })
        end)
    end

    if themeSec then
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
    end

    if miscSec then
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
    end

    if uiSec then
        tryElement("controls paragraph", function()
            uiSec:Paragraph({
                Title = "Controls",
                Desc = IS_MOBILE
                    and "Tap the floating Tetoware button to reopen the window."
                    or "RightShift toggles the window. You can rebind it below.",
            })
        end)

        tryElement("keybind", function()
            uiSec:Keybind({
                Title = "Toggle UI Keybind",
                Desc = "key that shows/hides the window",
                Value = TOGGLE_KEY.Name,
                Callback = function(key)
                    local enum
                    if typeof(key) == "EnumItem" then
                        enum = key
                    else
                        pcall(function() enum = Enum.KeyCode[tostring(key)] end)
                    end
                    if enum and enum ~= TOGGLE_KEY then
                        TOGGLE_KEY = enum
                        pcall(function() window:SetToggleKey(enum) end)
                        notify("Toggle UI Keybind", "bound to " .. enum.Name, "keyboard")
                    end
                end,
            })
        end)

        tryElement("donate button", function()
            uiSec:Button({
                Title = "Show Donation Popup",
                Desc = "run the donate prompt again",
                Icon = "heart",
                Callback = function()
                    if popupOpen then return end
                    pcall(showDonationPopup)
                end,
            })
        end)

        tryElement("unload button", function()
            uiSec:Button({
                Title = "Unload Tetoware",
                Desc = "removes everything",
                Icon = "power",
                Callback = unloadAll,
            })
        end)
    end

    notify("Tetoware", "v" .. SCRIPT_VERSION .. " loaded", "info")
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
