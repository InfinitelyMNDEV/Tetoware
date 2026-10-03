-- CatWare - Version 1.0 Beta
-- This script is licensed under GNU GPL and is created by Eclipse Team
-- This is a template not a functioning script, you can lowkey inspect it
-- Also it uses WindUI as the library repo link https://github.com/Footagesus/WindUI
-- Note this is an old verision of the template and is no longer used!

-- services
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

-- config
local SCRIPT_VERSION = "1.0 Beta"
-- some execs here blocks purchase prompts entirely so we always copy the web link as backup
local DONATION_PRODUCT_ID = 3715327753
local GAMEPASS_ID = 1891025004
local GAMEPASS_URL = "https://www.roblox.com/game-pass/" .. GAMEPASS_ID
local SAVE_FOLDER = "CatWare"
local DONATE_FLAG_FILE = SAVE_FOLDER .. "/donate_popup.txt"
local THEME_FILE = SAVE_FOLDER .. "/theme.txt"
local REPO_URL = "https://github.com/InfinitelyMNDEV/catware"
local TOGGLE_KEY = Enum.KeyCode.RightShift

-- stable release first, raw dist as backup (this one for sindui docs)
local WINDUI_URLS = {
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
}

-- touch and no keyboard means phone
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- state stuff
local WindUI = nil
local winduiReady = false
local winduiFailed = false
local window = nil
local popupGui = nil
local popupOpen = false
local purchaseConn = nil

-- forward decls, popup and window call each other
local openMainUI
local showDonationPopup
local unloadAll

-- download windui in the background so the popup never waits on http (its fsster and more reliable)
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

-- works with or without windui
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

-- executor file stuff, not every one ships these
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

-- hidden ui container first, then coregui, then playergui. test rach one
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

-- windui only accepts this exact theme shape, name + color3 values, nothing else
local THEME_LIST = {
    {
        Name = "CatWare",
        Accent = Color3.fromHex("#c75472"),
        Background = Color3.fromHex("#0b0a0e"),
        Outline = Color3.fromHex("#2a2532"),
        Text = Color3.fromHex("#d8d4dc"),
        Placeholder = Color3.fromHex("#6f6a78"),
        Button = Color3.fromHex("#1a1720"),
        Icon = Color3.fromHex("#c7a3b1"),
    },
    {
        Name = "CatWare Midnight",
        Accent = Color3.fromHex("#6c5ec7"),
        Background = Color3.fromHex("#0a0912"),
        Outline = Color3.fromHex("#241f35"),
        Text = Color3.fromHex("#d2d0e2"),
        Placeholder = Color3.fromHex("#6a6880"),
        Button = Color3.fromHex("#16132a"),
        Icon = Color3.fromHex("#9b93cc"),
    },
    {
        Name = "CatWare Ember",
        Accent = Color3.fromHex("#b96f42"),
        Background = Color3.fromHex("#0e0b08"),
        Outline = Color3.fromHex("#2a211a"),
        Text = Color3.fromHex("#dbd3c9"),
        Placeholder = Color3.fromHex("#756e66"),
        Button = Color3.fromHex("#1a1410"),
        Icon = Color3.fromHex("#c3a184"),
    },
    {
        Name = "CatWare Ocean",
        Accent = Color3.fromHex("#4c89ae"),
        Background = Color3.fromHex("#090d11"),
        Outline = Color3.fromHex("#1e2830"),
        Text = Color3.fromHex("#d0dae0"),
        Placeholder = Color3.fromHex("#66717a"),
        Button = Color3.fromHex("#131b21"),
        Icon = Color3.fromHex("#8ab0c4"),
    },
    {
        Name = "CatWare Forest",
        Accent = Color3.fromHex("#4e9162"),
        Background = Color3.fromHex("#080d09"),
        Outline = Color3.fromHex("#1e2a20"),
        Text = Color3.fromHex("#d2dad3"),
        Placeholder = Color3.fromHex("#67736a"),
        Button = Color3.fromHex("#121a14"),
        Icon = Color3.fromHex("#92bc9c"),
    },
}

local THEME_NAMES = {}
for _, t in ipairs(THEME_LIST) do
    table.insert(THEME_NAMES, t.Name)
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

-- popup palette. near black card, green confirm, gray decline
local PALETTE = {
    confirm = Color3.fromHex("#1F7A44"),
    confirmHover = Color3.fromHex("#289457"),
    decline = Color3.fromHex("#26262D"),
    declineHover = Color3.fromHex("#303038"),
    bg = Color3.fromHex("#101013"),
    stroke = Color3.fromHex("#2E2E34"),
    text = Color3.fromHex("#ECEBEF"),
    body = Color3.fromHex("#C7C5CC"),
    subtext = Color3.fromHex("#8B8994"),
    accent = Color3.fromHex("#c75472"),
    red = Color3.fromHex("#FF6B7E"),
}

-- donate popup. flat near black card, no shadow behind it, nothing extra
showDonationPopup = function()
    if popupOpen then return end
    popupOpen = true

    local cam = Workspace.CurrentCamera
    local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
    local uiScale = math.clamp(math.min(vp.X, vp.Y) / 700, 0.8, 1.15)

    local gui = Instance.new("ScreenGui")
    gui.Name = "CatWare_Donate"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = getGuiParent()
    popupGui = gui

    -- if some executor nuked the parent, retry somewhere visible
    task.delay(1, function()
        if not popupOpen then return end
        if gui.Parent == nil or not gui:IsDescendantOf(game) then
            pcall(function()
                gui.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or game:GetService("CoreGui")
            end)
        end
    end)

    -- no fullscreen backdro it blocked the camera. card floats on its own
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
    title.Text = "Support CatWare"
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

    -- checkbox
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

    -- hover, harmless on touch
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

        -- watch for the purchase window closing, bought or not
        pcall(function()
            purchaseConn = MarketplaceService.PromptProductPurchaseFinished:Connect(function(plr, productId)
                if plr == LocalPlayer and productId == DONATION_PRODUCT_ID and popupOpen then
                    closePopup(function() openMainUI() end)
                end
            end)
        end)

        -- try the in game prompt, delta usually blocks this silently
        local prompted = false
        pcall(function()
            MarketplaceService:PromptProductPurchase(LocalPlayer, DONATION_PRODUCT_ID)
            prompted = true
        end)

        -- always hand over the web link too since prompts are unreliable
        if copyToClipboard(GAMEPASS_URL) then
            notify("CatWare", "game pass link copied. if no purchase window opened, buy it in your browser", "heart")
        else
            notify("CatWare", "no clipboard here. donate link: " .. GAMEPASS_URL, "heart")
        end

        if not prompted then
            closePopup(function() openMainUI() end)
            return
        end

        -- failsafe so the ui always opens even if no window ever shows
        task.delay(12, function()
            if popupOpen then
                closePopup(function() openMainUI() end)
            end
        end)
    end)

    -- entrance, slide and scale only. no transparency tweens, nothing can get stuck invisible
    TweenService:Create(scale, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = uiScale }):Play()
    TweenService:Create(holder, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
end

-- nukes everything including the popup
unloadAll = function()
    popupOpen = false
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
    notify("CatWare", "unloaded, thanks for trying it", "power")
end

local function buildWindow()
    if window then return end
    if not WindUI then
        notify("CatWare", "windui didnt load, cant build the window", "info")
        return
    end

    registerThemes()

    -- big enough to tap on phones, small enough to still see the game
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

    local ok, result = pcall(function()
        return WindUI:CreateWindow({
            Title = "CatWare",
            Icon = "cat",
            Author = "v" .. SCRIPT_VERSION .. " - Eclipse Team",
            Folder = SAVE_FOLDER,
            Size = winSize,
            Transparent = false,
            Theme = "CatWare",
            SideBarWidth = 180,
            ToggleKey = TOGGLE_KEY,
            Resizable = not IS_MOBILE,
        })
    end)
    if not ok or type(result) ~= "table" then
        notify("CatWare", "window failed to build: " .. tostring(result), "info")
        return
    end
    window = result

    if IS_MOBILE then
        -- keep notifications out of the jump button's way
        pcall(function() WindUI:SetNotificationLower(true) end)
    end

    -- floating reopen button, mostly for phones
    pcall(function()
        window:EditOpenButton({
            Title = "CatWare",
            Icon = "cat",
            CornerRadius = UDim.new(0, 12),
        })
    end)

    -- saved theme wins over the default
    local savedTheme = loadSavedTheme()
    if savedTheme then
        pcall(function() WindUI:SetTheme(savedTheme) end)
    end

    -- tabs and sections first, elements go in after
    local creditsTab, settingsTab, themeSec, uiSec
    local okTabs, tabErr = pcall(function()
        -- tab section "home" holds both tabs, settings is not separated
        local homeGroup = window:Section({ Title = "Home", Opened = true })
        creditsTab = homeGroup:Tab({ Title = "Credits", Icon = "info" })
        settingsTab = homeGroup:Tab({ Title = "Settings", Icon = "settings" })

        -- credits tab
        local creditsSec = creditsTab:Section({ Title = "Credits", Opened = true })
        creditsSec:Paragraph({
            Title = "CatWare v" .. SCRIPT_VERSION,
            Desc = "Made by Eclipse Team. Main developer: MNDEV. Team members: Bounty and Mahmood.",
        })
        creditsSec:Paragraph({
            Title = "License",
            Desc = "GNU GPL, fully open source.",
        })

        local repoSec = creditsTab:Section({ Title = "Repository", Opened = true })
        repoSec:Paragraph({
            Title = "GitHub",
            Desc = REPO_URL,
        })

        themeSec = settingsTab:Section({ Title = "Theme", Opened = true })
        uiSec = settingsTab:Section({ Title = "Interface", Opened = true })
    end)

    if not okTabs then
        notify("CatWare", "tabs failed to build: " .. tostring(tabErr), "info")
        return
    end

    -- add elements one at a time so a bad one cant kill the rest
    local function tryElement(label, fn)
        local okEl, err = pcall(fn)
        if not okEl then
            notify("CatWare", label .. " failed: " .. tostring(err), "info")
        end
    end

    tryElement("copy button", function()
        repoSec:Button({
            Title = "Copy Repository Link",
            Desc = "puts the url on your clipboard",
            Icon = "copy",
            Callback = function()
                if copyToClipboard(REPO_URL) then
                    notify("CatWare", "repo link copied to clipboard", "check")
                else
                    notify("CatWare", "clipboard not available. " .. REPO_URL, "info")
                end
            end,
        })
    end)

    if themeSec then
        tryElement("theme dropdown", function()
            themeSec:Dropdown({
                Title = "UI Theme",
                Desc = "pick a palette, catware is the default",
                Values = THEME_NAMES,
                Value = savedTheme or "CatWare",
                Callback = function(opt)
                    local name = tostring(opt)
                    pcall(function() WindUI:SetTheme(name) end)
                    saveTheme(name)
                    notify("Theme", "switched to " .. name, "palette")
                end,
            })
        end)
    end

    if uiSec then
        tryElement("controls paragraph", function()
            uiSec:Paragraph({
                Title = "Controls",
                Desc = IS_MOBILE
                    and "Tap the floating CatWare button to reopen the window."
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
                    -- only react to an actual rebind, not every key press
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
                Title = "Unload CatWare",
                Desc = "removes everything",
                Icon = "power",
                Callback = unloadAll,
            })
        end)
    end

    notify("CatWare", "v" .. SCRIPT_VERSION .. " loaded", "cat")
end

openMainUI = function()
    if window then return end
    if winduiReady then
        buildWindow()
        return
    end
    if winduiFailed then
        notify("CatWare", "windui failed to load, cant build the window", "info")
        return
    end
    -- still downloading wait it to complete
    task.spawn(function()
        local waited = 0
        while not winduiReady and not winduiFailed and waited < 30 do
            task.wait(1)
            waited += 1
        end
        if winduiReady and not window then
            buildWindow()
        elseif winduiFailed and not window then
            notify("CatWare", "windui never loaded, check your executor", "info")
        end
    end)
end

-- startup
task.spawn(tryLoadWindUI)

if neverShowSaved() then
    -- they said never again, skip straight to the ui
    openMainUI()
else
    local ok = pcall(showDonationPopup)
    if not ok then
        -- popup blew up, dont leave them with nothing
        if popupGui then
            popupGui:Destroy()
            popupGui = nil
        end
        popupOpen = false
        notify("CatWare", "donate popup failed, opening the ui anyway", "info")
        openMainUI()
    end
end
