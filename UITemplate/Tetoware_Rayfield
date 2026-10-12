-- Tetoware - Version 1.0 Beta
-- This script is licensed under GNU GPL and is created by Eclipse Team

local Players = game:GetService("Players")
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
            subtitle = "By Eclipse Team",
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

    local homeTab, settingsTab
    local okTabs, tabErr = pcall(function()
        window:CreateSection({ name = "Information" })
        homeTab = window:CreateTab(tabProps("Home"))
        settingsTab = window:CreateTab(tabProps("Settings"))

        homeTab:CreateSection({ name = "Credits" })
        homeTab:CreateText({
            name = "Tetoware v" .. SCRIPT_VERSION,
            text = "This script is fully developed by InfinitelyMNDEV",
        })

        homeTab:CreateSection({ name = "Eclipse Team" })
        homeTab:CreateText({ name = "Member 1", text = "MNDEV" })
        homeTab:CreateText({ name = "Member 2", text = "x0b0unty" })
        homeTab:CreateText({ name = "Member 3", text = "Hero (aka Mahmood)" })

        homeTab:CreateSection({ name = "Githuh" })
        homeTab:CreateText({
            name = "License",
            text = "This script is fully open source and licensed under the GNU GPL. You are free to view, modify and redistribute it.",
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
                pcall(function()
                    window:Unload()
                end)
                window = nil
                notify("Tetoware", "unloaded, thanks for trying it")
            end,
        })
    end)

    if not okTabs then
        notify("Tetoware", "tabs failed to build: " .. tostring(tabErr))
        return
    end

    notify("Tetoware", "v" .. SCRIPT_VERSION .. " loaded" .. (IS_MOBILE and " on mobile" or " on pc"))
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
