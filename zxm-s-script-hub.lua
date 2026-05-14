-- Zxm's Script - Main UI System (v2.0)
-- Enhanced with dark theme and improved shapes panel
-- Place this in StarterPlayerScripts or as a LocalScript

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Color Palette (Dark Monochrome Theme)
local Colors = {
    Background = Color3.fromRGB(18, 18, 22),
    Surface = Color3.fromRGB(28, 28, 34),
    SurfaceLight = Color3.fromRGB(38, 38, 46),
    SurfaceHover = Color3.fromRGB(48, 48, 58),
    Border = Color3.fromRGB(55, 55, 65),
    TextPrimary = Color3.fromRGB(240, 240, 245),
    TextSecondary = Color3.fromRGB(160, 160, 170),
    DarkButton = Color3.fromRGB(45, 45, 55),
    DarkButtonHover = Color3.fromRGB(60, 60, 75),
    ExecuteBtn = Color3.fromRGB(220, 220, 230),
    ExecuteBtnHover = Color3.fromRGB(255, 255, 255),
    StatusProcess = Color3.fromRGB(100, 150, 255),
    StatusSuccess = Color3.fromRGB(80, 200, 120),
    StatusError = Color3.fromRGB(220, 80, 80)
}

-- Utility Functions
local function createUICorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Colors.Border
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

-- Tween Presets
local TweenPresets = {
    Intro = TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Outro = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
    TextFade = TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    SlideUp = TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    SlideDown = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
    ScaleIn = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    ScaleOut = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
    ButtonHover = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    SizeChange = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Expand = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Collapse = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
}

-- Scripts Data
local ScriptsData = {
    {
        name = "Unanchored Manipulator",
        description = "A powerful tool to manipulate unanchored parts in the game. Allows you to control, move, and interact with loose physics objects.",
        url = "https://raw.githubusercontent.com/justzxm/zxm-s-roblox-scripts/TCO-scripts/zxm-unanchored-manipulator-script.lua"
    },
    {
        name = "Infinite Yield",
        description = "Popular admin commands script with over 200+ commands for server management and fun.",
        url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"
    },
    {
        name = "Dex Explorer",
        description = "Advanced game explorer that lets you browse the game's hierarchy and modify properties in real-time.",
        url = "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"
    }
}

-- Shapes Configuration
local ShapesConfig = {
    {
        id = "heart",
        name = "Heart",
        description = "A beautiful heart shape formation",
        sliders = {}
    },
    {
        id = "wall",
        name = "Wall",
        description = "Create a solid wall formation",
        sliders = {
            {name = "Density", min = 1, max = 10, default = 5}
        }
    },
    {
        id = "box",
        name = "Box",
        description = "A cubic box shape",
        sliders = {}
    },
    {
        id = "ring",
        name = "Ring",
        description = "A circular ring formation",
        sliders = {
            {name = "Radius", min = 5, max = 50, default = 20}
        }
    },
    {
        id = "sphere",
        name = "Sphere",
        description = "A perfectly round sphere",
        sliders = {
            {name = "Radius", min = 5, max = 50, default = 20}
        }
    },
    {
        id = "spiral",
        name = "Spiral",
        description = "A rotating spiral pattern",
        sliders = {
            {name = "Tightness", min = 1, max = 10, default = 5},
            {name = "Height", min = 5, max = 50, default = 20}
        }
    },
    {
        id = "star",
        name = "Star",
        description = "A shining star shape",
        sliders = {
            {name = "Points", min = 3, max = 8, default = 5},
            {name = "Radius", min = 5, max = 50, default = 20}
        }
    },
    {
        id = "diamond",
        name = "Diamond",
        description = "A diamond crystal shape",
        sliders = {
            {name = "Size", min = 1, max = 20, default = 10}
        }
    },
    {
        id = "cross",
        name = "Cross",
        description = "A plus/cross shape",
        sliders = {
            {name = "Length", min = 5, max = 50, default = 20}
        }
    },
    {
        id = "wave",
        name = "Wave",
        description = "A wave pattern",
        sliders = {
            {name = "Wavelength", min = 1, max = 20, default = 8},
            {name = "Amplitude", min = 1, max = 20, default = 5},
            {name = "Frequency", min = 0.5, max = 5, default = 2}
        }
    },
    {
        id = "helix",
        name = "Helix",
        description = "A DNA helix shape",
        sliders = {
            {name = "Turns", min = 1, max = 10, default = 4},
            {name = "Height", min = 5, max = 50, default = 20}
        }
    },
    {
        id = "pyramid",
        name = "Pyramid",
        description = "A pyramid structure",
        sliders = {
            {name = "Height", min = 5, max = 50, default = 20}
        }
    },
    {
        id = "grid",
        name = "Grid",
        description = "A grid pattern formation",
        sliders = {
            {name = "Spacing", min = 1, max = 10, default = 2}
        }
    },
    {
        id = "tornado",
        name = "Tornado",
        description = "A tornado vortex formation",
        sliders = {
            {name = "Height", min = 5, max = 50, default = 20},
            {name = "Width", min = 5, max = 30, default = 10}
        }
    },
    {
        id = "flower",
        name = "Flower",
        description = "A flower petal formation",
        sliders = {
            {name = "Petals", min = 3, max = 12, default = 6},
            {name = "Radius", min = 5, max = 50, default = 20}
        }
    }
}

-- Create Intro Screen
local function createIntroScreen()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ZxmIntro"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Colors.Background
    background.BorderSizePixel = 0
    background.Parent = screenGui

    local centerContainer = Instance.new("Frame")
    centerContainer.Name = "CenterContainer"
    centerContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    centerContainer.Position = UDim2.new(0.5, 0, 0.5, 50)
    centerContainer.Size = UDim2.new(0, 400, 0, 100)
    centerContainer.BackgroundTransparency = 1
    centerContainer.Parent = background

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "TitleText"
    textLabel.Size = UDim2.new(1, 0, 0, 60)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "Zxm's Script"
    textLabel.TextColor3 = Colors.TextPrimary
    textLabel.TextSize = 48
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextTransparency = 1
    textLabel.Parent = centerContainer

    local subText = Instance.new("TextLabel")
    subText.Name = "SubText"
    subText.Position = UDim2.new(0, 0, 0, 65)
    subText.Size = UDim2.new(1, 0, 0, 20)
    subText.BackgroundTransparency = 1
    subText.Text = "Loading..."
    subText.TextColor3 = Colors.TextSecondary
    subText.TextSize = 14
    subText.Font = Enum.Font.Gotham
    subText.TextTransparency = 1
    subText.Parent = centerContainer

    local line = Instance.new("Frame")
    line.Name = "Line"
    line.AnchorPoint = Vector2.new(0.5, 0)
    line.Position = UDim2.new(0.5, 0, 0, 90)
    line.Size = UDim2.new(0, 0, 0, 2)
    line.BackgroundColor3 = Colors.TextPrimary
    line.BorderSizePixel = 0
    line.Parent = centerContainer
    createUICorner(line, 1)

    return {
        ScreenGui = screenGui,
        Background = background,
        CenterContainer = centerContainer,
        TextLabel = textLabel,
        SubText = subText,
        Line = line
    }
end

-- Create Main UI
local function createMainUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ZxmMainUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.Size = UDim2.new(0, 500, 0, 400)
    mainFrame.BackgroundColor3 = Colors.Surface
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    createUICorner(mainFrame, 12)
    createStroke(mainFrame, Colors.Border, 1)

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Colors.Background
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    createUICorner(titleBar, 12)

    local titleBarFix = Instance.new("Frame")
    titleBarFix.Name = "Fix"
    titleBarFix.Position = UDim2.new(0, 0, 1, -12)
    titleBarFix.Size = UDim2.new(1, 0, 0, 12)
    titleBarFix.BackgroundColor3 = Colors.Background
    titleBarFix.BorderSizePixel = 0
    titleBarFix.Parent = titleBar

    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.Size = UDim2.new(0, 200, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "Zxm's Script"
    titleText.TextColor3 = Colors.TextPrimary
    titleText.TextSize = 16
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    -- Window Controls
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "Controls"
    controlsFrame.AnchorPoint = Vector2.new(1, 0.5)
    controlsFrame.Position = UDim2.new(1, -10, 0.5, 0)
    controlsFrame.Size = UDim2.new(0, 90, 0, 24)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = titleBar

    local controlsLayout = Instance.new("UIListLayout")
    controlsLayout.FillDirection = Enum.FillDirection.Horizontal
    controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    controlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    controlsLayout.Padding = UDim.new(0, 8)
    controlsLayout.Parent = controlsFrame

    local function createControlButton(name, color, hoverColor, symbol)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 24, 0, 24)
        btn.BackgroundColor3 = color
        btn.Text = symbol
        btn.TextColor3 = Colors.TextPrimary
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.AutoButtonColor = false
        btn.Parent = controlsFrame
        createUICorner(btn, 6)
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenPresets.ButtonHover, {BackgroundColor3 = hoverColor}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenPresets.ButtonHover, {BackgroundColor3 = color}):Play()
        end)
        
        return btn
    end

    local hideBtn = createControlButton("Hide", Colors.DarkButton, Colors.DarkButtonHover, "−")
    local minimizeBtn = createControlButton("Minimize", Colors.DarkButton, Colors.DarkButtonHover, "□")
    local closeBtn = createControlButton("Close", Colors.DarkButton, Colors.DarkButtonHover, "×")

    -- Content Area
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Position = UDim2.new(0, 0, 0, 40)
    contentFrame.Size = UDim2.new(1, 0, 1, -40)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    -- Tab Bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 40)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = contentFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.Parent = tabBar

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingLeft = UDim.new(0, 10)
    tabPadding.PaddingTop = UDim.new(0, 8)
    tabPadding.Parent = tabBar

    -- Create Tabs
    local tabs = {"Scripts", "Shapes", "Settings", "Credits"}
    local tabButtons = {}
    local tabContents = {}
    local dragConnections = {}

    for i, tabName in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tabName .. "Tab"
        tabBtn.Size = UDim2.new(0, 80, 0, 32)
        tabBtn.BackgroundColor3 = i == 1 and Colors.SurfaceLight or Colors.Background
        tabBtn.Text = tabName
        tabBtn.TextColor3 = i == 1 and Colors.TextPrimary or Colors.TextSecondary
        tabBtn.TextSize = 13
        tabBtn.Font = Enum.Font.GothamSemibold
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = tabBar
        createUICorner(tabBtn, 6)
        tabButtons[tabName] = tabBtn

        local tabContent = Instance.new("Frame")
        tabContent.Name = tabName .. "Content"
        tabContent.Position = UDim2.new(0, 0, 0, 45)
        tabContent.Size = UDim2.new(1, 0, 1, -45)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = i == 1
        tabContent.Parent = contentFrame
        tabContents[tabName] = tabContent

        tabBtn.MouseButton1Click:Connect(function()
            for name, btn in pairs(tabButtons) do
                TweenService:Create(btn, TweenPresets.ButtonHover, {
                    BackgroundColor3 = name == tabName and Colors.SurfaceLight or Colors.Background,
                    TextColor3 = name == tabName and Colors.TextPrimary or Colors.TextSecondary
                }):Play()
                tabContents[name].Visible = name == tabName
            end
        end)
    end

    -- ===== SCRIPTS TAB: SCRIPT LIST =====
    local scriptsScroll = Instance.new("ScrollingFrame")
    scriptsScroll.Name = "ScriptList"
    scriptsScroll.Size = UDim2.new(1, 0, 1, 0)
    scriptsScroll.BackgroundTransparency = 1
    scriptsScroll.BorderSizePixel = 0
    scriptsScroll.ScrollBarThickness = 4
    scriptsScroll.ScrollBarImageColor3 = Colors.Border
    scriptsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scriptsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scriptsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scriptsScroll.Parent = tabContents["Scripts"]

    local scriptsScrollPadding = Instance.new("UIPadding")
    scriptsScrollPadding.PaddingLeft = UDim.new(0, 15)
    scriptsScrollPadding.PaddingRight = UDim.new(0, 15)
    scriptsScrollPadding.PaddingTop = UDim.new(0, 15)
    scriptsScrollPadding.PaddingBottom = UDim.new(0, 15)
    scriptsScrollPadding.Parent = scriptsScroll

    local scriptsScrollLayout = Instance.new("UIListLayout")
    scriptsScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scriptsScrollLayout.Padding = UDim.new(0, 10)
    scriptsScrollLayout.Parent = scriptsScroll

    -- Helper to create script item
    local function createScriptItem(data, index)
        local itemContainer = Instance.new("Frame")
        itemContainer.Name = data.name .. "Item"
        itemContainer.Size = UDim2.new(1, 0, 0, 50)
        itemContainer.BackgroundColor3 = Colors.Background
        itemContainer.BorderSizePixel = 0
        itemContainer.LayoutOrder = index
        itemContainer.Parent = scriptsScroll
        createUICorner(itemContainer, 8)
        createStroke(itemContainer, Colors.Border, 1)

        local headerFrame = Instance.new("Frame")
        headerFrame.Name = "Header"
        headerFrame.Size = UDim2.new(1, 0, 0, 50)
        headerFrame.BackgroundTransparency = 1
        headerFrame.Parent = itemContainer

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "ScriptName"
        nameLabel.Position = UDim2.new(0, 15, 0, 0)
        nameLabel.Size = UDim2.new(1, -70, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = data.name
        nameLabel.TextColor3 = Colors.TextPrimary
        nameLabel.TextSize = 15
        nameLabel.Font = Enum.Font.GothamSemibold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = headerFrame

        local arrowBtn = Instance.new("TextButton")
        arrowBtn.Name = "ArrowBtn"
        arrowBtn.AnchorPoint = Vector2.new(1, 0.5)
        arrowBtn.Position = UDim2.new(1, -10, 0.5, 0)
        arrowBtn.Size = UDim2.new(0, 30, 0, 30)
        arrowBtn.BackgroundColor3 = Colors.DarkButton
        arrowBtn.Text = "›"
        arrowBtn.TextColor3 = Colors.TextSecondary
        arrowBtn.TextSize = 20
        arrowBtn.Font = Enum.Font.GothamBold
        arrowBtn.AutoButtonColor = false
        arrowBtn.Parent = headerFrame
        createUICorner(arrowBtn, 6)

        local previewFrame = Instance.new("Frame")
        previewFrame.Name = "Preview"
        previewFrame.Position = UDim2.new(0, 0, 0, 50)
        previewFrame.Size = UDim2.new(1, 0, 0, 0)
        previewFrame.BackgroundColor3 = Colors.SurfaceLight
        previewFrame.BorderSizePixel = 0
        previewFrame.ClipsDescendants = true
        previewFrame.Visible = false
        previewFrame.Parent = itemContainer

        local previewPadding = Instance.new("UIPadding")
        previewPadding.PaddingLeft = UDim.new(0, 15)
        previewPadding.PaddingRight = UDim.new(0, 15)
        previewPadding.PaddingTop = UDim.new(0, 12)
        previewPadding.PaddingBottom = UDim.new(0, 12)
        previewPadding.Parent = previewFrame

        local descLabel = Instance.new("TextLabel")
        descLabel.Name = "Description"
        descLabel.Size = UDim2.new(1, 0, 0, 0)
        descLabel.AutomaticSize = Enum.AutomaticSize.Y
        descLabel.BackgroundTransparency = 1
        descLabel.Text = data.description
        descLabel.TextColor3 = Colors.TextSecondary
        descLabel.TextSize = 13
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextWrapped = true
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = previewFrame

        local bottomBar = Instance.new("Frame")
        bottomBar.Name = "BottomBar"
        bottomBar.Position = UDim2.new(0, 0, 1, -40)
        bottomBar.Size = UDim2.new(1, 0, 0, 40)
        bottomBar.BackgroundTransparency = 1
        bottomBar.Parent = previewFrame

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "Status"
        statusLabel.Position = UDim2.new(0, 0, 0, 0)
        statusLabel.Size = UDim2.new(0.6, -10, 1, 0)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = ""
        statusLabel.TextColor3 = Colors.StatusProcess
        statusLabel.TextSize = 12
        statusLabel.Font = Enum.Font.Gotham
        statusLabel.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
        statusLabel.Parent = bottomBar

        local executeBtn = Instance.new("TextButton")
        executeBtn.Name = "ExecuteBtn"
        executeBtn.AnchorPoint = Vector2.new(1, 0.5)
        executeBtn.Position = UDim2.new(1, 0, 0.5, 0)
        executeBtn.Size = UDim2.new(0, 100, 0, 36)
        executeBtn.BackgroundColor3 = Colors.ExecuteBtn
        executeBtn.Text = "Execute"
        executeBtn.TextColor3 = Colors.Background
        executeBtn.TextSize = 14
        executeBtn.Font = Enum.Font.GothamBold
        executeBtn.AutoButtonColor = false
        executeBtn.Parent = bottomBar
        createUICorner(executeBtn, 8)

        itemContainer.MouseEnter:Connect(function()
            TweenService:Create(itemContainer, TweenPresets.ButtonHover, {BackgroundColor3 = Colors.SurfaceHover}):Play()
        end)
        itemContainer.MouseLeave:Connect(function()
            TweenService:Create(itemContainer, TweenPresets.ButtonHover, {BackgroundColor3 = Colors.Background}):Play()
        end)

        arrowBtn.MouseEnter:Connect(function()
            TweenService:Create(arrowBtn, TweenPresets.ButtonHover, {BackgroundColor3 = Colors.DarkButtonHover}):Play()
        end)
        arrowBtn.MouseLeave:Connect(function()
            TweenService:Create(arrowBtn, TweenPresets.ButtonHover, {BackgroundColor3 = Colors.DarkButton}):Play()
        end)

        executeBtn.MouseEnter:Connect(function()
            TweenService:Create(executeBtn, TweenPresets.ButtonHover, {BackgroundColor3 = Colors.ExecuteBtnHover}):Play()
        end)
        executeBtn.MouseLeave:Connect(function()
            TweenService:Create(executeBtn, TweenPresets.ButtonHover, {BackgroundColor3 = Colors.ExecuteBtn}):Play()
        end)

        local isExpanded = false

        arrowBtn.MouseButton1Click:Connect(function()
            isExpanded = not isExpanded

            if isExpanded then
                previewFrame.Visible = true
                TweenService:Create(arrowBtn, TweenPresets.ButtonHover, {Rotation = 90}):Play()
                TweenService:Create(itemContainer, TweenPresets.Expand, {Size = UDim2.new(1, 0, 0, 180)}):Play()
                TweenService:Create(previewFrame, TweenPresets.Expand, {Size = UDim2.new(1, 0, 0, 130)}):Play()
            else
                TweenService:Create(arrowBtn, TweenPresets.ButtonHover, {Rotation = 0}):Play()
                TweenService:Create(itemContainer, TweenPresets.Collapse, {Size = UDim2.new(1, 0, 0, 50)}):Play()
                TweenService:Create(previewFrame, TweenPresets.Collapse, {Size = UDim2.new(1, 0, 0, 0)}):Play()
                task.wait(0.3)
                previewFrame.Visible = false
            end
        end)

        executeBtn.MouseButton1Click:Connect(function()
            statusLabel.Text = "Executing..."
            statusLabel.TextColor3 = Colors.StatusProcess

            local success, err = pcall(function()
                loadstring(game:HttpGet(data.url))()
            end)

            if success then
                statusLabel.Text = "✓ Executed"
                statusLabel.TextColor3 = Colors.StatusSuccess
                executeBtn.Text = "Executed"
                executeBtn.BackgroundColor3 = Colors.StatusSuccess
                executeBtn.TextColor3 = Colors.TextPrimary
            else
                statusLabel.Text = "✗ Failed"
                statusLabel.TextColor3 = Colors.StatusError
            end
        end)
    end

    for i, scriptData in ipairs(ScriptsData) do
        createScriptItem(scriptData, i)
    end

    -- ===== SHAPES TAB =====
    local shapesScroll = Instance.new("ScrollingFrame")
    shapesScroll.Name = "ShapesList"
    shapesScroll.Size = UDim2.new(1, 0, 1, 0)
    shapesScroll.BackgroundTransparency = 1
    shapesScroll.BorderSizePixel = 0
    shapesScroll.ScrollBarThickness = 4
    shapesScroll.ScrollBarImageColor3 = Colors.Border
    shapesScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    shapesScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    shapesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    shapesScroll.Parent = tabContents["Shapes"]

    local shapesScrollPadding = Instance.new("UIPadding")
    shapesScrollPadding.PaddingLeft = UDim.new(0, 15)
    shapesScrollPadding.PaddingRight = UDim.new(0, 15)
    shapesScrollPadding.PaddingTop = UDim.new(0, 15)
    shapesScrollPadding.PaddingBottom = UDim.new(0, 15)
    shapesScrollPadding.Parent = shapesScroll

    local shapesScrollLayout = Instance.new("UIListLayout")
    shapesScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    shapesScrollLayout.Padding = UDim.new(0, 8)
    shapesScrollLayout.Parent = shapesScroll

    -- Helper to create shape item
    local function createShapeItem(shapeData, index)
        local shapeContainer = Instance.new("Frame")
        shapeContainer.Name = shapeData.name .. "Item"
        shapeContainer.Size = UDim2.new(1, 0, 0, 50)
        shapeContainer.BackgroundColor3 = Colors.Background
        shapeContainer.BorderSizePixel = 0
        shapeContainer.LayoutOrder = index
        shapeContainer.Parent = shapesScroll
        createUICorner(shapeContainer, 8)
        createStroke(shapeContainer, Colors.Border, 1)

        local headerFrame = Instance.new("Frame")
        headerFrame.Name = "Header"
        headerFrame.Size = UDim2.new(1, 0, 0, 50)
        headerFrame.BackgroundTransparency = 1
        headerFrame.Parent = shapeContainer

        local shapeNameLabel = Instance.new("TextLabel")
        shapeNameLabel.Name = "ShapeName"
        shapeNameLabel.Position = UDim2.new(0, 15, 0, 0)
        shapeNameLabel.Size = UDim2.new(1, -70, 1, 0)
        shapeNameLabel.BackgroundTransparency = 1
        shapeNameLabel.Text = shapeData.name
        shapeNameLabel.TextColor3 = Colors.TextPrimary
        shapeNameLabel.TextSize = 15
        shapeNameLabel.Font = Enum.Font.GothamSemibold
        shapeNameLabel.TextXAlignment = Enum.TextXAlignment.Left
        shapeNameLabel.Parent = headerFrame

        local previewArrowBtn = Instance.new("TextButton")
        previewArrowBtn.Name = "PreviewArrow"
        previewArrowBtn.AnchorPoint = Vector2.new(1, 0.5)
        previewArrowBtn.Position = UDim2.new(1, -10, 0.5, 0)
        previewArrowBtn.Size = UDim2.new(0, 30, 0, 30)
        previewArrowBtn.BackgroundColor3 = Colors.DarkButton
        previewArrowBtn.Text = "›"
        previewArrowBtn.TextColor3 = Colors.TextSecondary
        previewArrowBtn.TextSize = 20
        previewArrowBtn.Font = Enum.Font.GothamBold
        previewArrowBtn.AutoButtonColor = false
        previewArrowBtn.Parent = headerFrame
        createUICorner(previewArrowBtn, 6)

        local shapePreviewFrame = Instance.new("Frame")
        shapePreviewFrame.Name = "Preview"
        shapePreviewFrame.Position = UDim2.new(0, 0, 0, 50)
        shapePreviewFrame.Size = UDim2.new(1, 0, 0, 0)
        shapePreviewFrame.BackgroundColor3 = Colors.SurfaceLight
        shapePreviewFrame.BorderSizePixel = 0
        shapePreviewFrame.ClipsDescendants = true
        shapePreviewFrame.Visible = false
        shapePreviewFrame.Parent = shapeContainer

        local shapePreviewPadding = Instance.new("UIPadding")
        shapePreviewPadding.PaddingLeft = UDim.new(0, 15)
        shapePreviewPadding.PaddingRight = UDim.new(0, 15)
        shapePreviewPadding.PaddingTop = UDim.new(0, 12)
        shapePreviewPadding.PaddingBottom = UDim.new(0, 12)
        shapePreviewPadding.Parent = shapePreviewFrame

        local shapeDescLabel = Instance.new("TextLabel")
        shapeDescLabel.Name = "Description"
        shapeDescLabel.Size = UDim2.new(1, 0, 0, 0)
        shapeDescLabel.AutomaticSize = Enum.AutomaticSize.Y
        shapeDescLabel.BackgroundTransparency = 1
        shapeDescLabel.Text = shapeData.description
        shapeDescLabel.TextColor3 = Colors.TextSecondary
        shapeDescLabel.TextSize = 12
        shapeDescLabel.Font = Enum.Font.Gotham
        shapeDescLabel.TextWrapped = true
        shapeDescLabel.TextXAlignment = Enum.TextXAlignment.Left
        shapeDescLabel.Parent = shapePreviewFrame

        -- Sliders Container
        if #shapeData.sliders > 0 then
            local slidersContainer = Instance.new("Frame")
            slidersContainer.Name = "SlidersContainer"
            slidersContainer.Position = UDim2.new(0, 0, 0, 35)
            slidersContainer.Size = UDim2.new(1, 0, 0, 0)
            slidersContainer.AutomaticSize = Enum.AutomaticSize.Y
            slidersContainer.BackgroundTransparency = 1
            slidersContainer.Parent = shapePreviewFrame

            local slidersLayout = Instance.new("UIListLayout")
            slidersLayout.SortOrder = Enum.SortOrder.LayoutOrder
            slidersLayout.Padding = UDim.new(0, 8)
            slidersLayout.Parent = slidersContainer

            for idx, sliderConfig in ipairs(shapeData.sliders) do
                local sliderFrame = Instance.new("Frame")
                sliderFrame.Name = sliderConfig.name .. "Slider"
                sliderFrame.Size = UDim2.new(1, 0, 0, 30)
                sliderFrame.BackgroundTransparency = 1
                sliderFrame.LayoutOrder = idx
                sliderFrame.Parent = slidersContainer

                local sliderLabel = Instance.new("TextLabel")
                sliderLabel.Size = UDim2.new(0, 80, 1, 0)
                sliderLabel.BackgroundTransparency = 1
                sliderLabel.Text = sliderConfig.name
                sliderLabel.TextColor3 = Colors.TextSecondary
                sliderLabel.TextSize = 11
                sliderLabel.Font = Enum.Font.Gotham
                sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                sliderLabel.Parent = sliderFrame

                local valueBox = Instance.new("TextBox")
                valueBox.Size = UDim2.new(0, 50, 0, 22)
                valueBox.Position = UDim2.new(1, -50, 0.5, -11)
                valueBox.BackgroundColor3 = Colors.DarkButton
                valueBox.TextColor3 = Colors.TextPrimary
                valueBox.TextSize = 11
                valueBox.Font = Enum.Font.Gotham
                valueBox.Text = tostring(sliderConfig.default)
                valueBox.Parent = sliderFrame
                createUICorner(valueBox, 4)

                valueBox.FocusLost:Connect(function()
                    local num = tonumber(valueBox.Text)
                    if num then
                        num = math.clamp(num, sliderConfig.min, sliderConfig.max)
                        valueBox.Text = tostring(num)
                    end
                end)
            end
        end

        shapeContainer.MouseEnter:Connect(function()
            TweenService:Create(shapeContainer, TweenPresets.ButtonHover, {BackgroundColor3 = Colors.SurfaceHover}):Play()
        end)
        shapeContainer.MouseLeave:Connect(function()
            TweenService:Create(shapeContainer, TweenPresets.ButtonHover, {BackgroundColor3 = Colors.Background}):Play()
        end)

        previewArrowBtn.MouseEnter:Connect(function()
            TweenService:Create(previewArrowBtn, TweenPresets.ButtonHover, {BackgroundColor3 = Colors.DarkButtonHover}):Play()
        end)
        previewArrowBtn.MouseLeave:Connect(function()
            TweenService:Create(previewArrowBtn, TweenPresets.ButtonHover, {BackgroundColor3 = Colors.DarkButton}):Play()
        end)

        local isShapeExpanded = false

        previewArrowBtn.MouseButton1Click:Connect(function()
            isShapeExpanded = not isShapeExpanded

            if isShapeExpanded then
                shapePreviewFrame.Visible = true
                TweenService:Create(previewArrowBtn, TweenPresets.ButtonHover, {Rotation = 90}):Play()
                
                -- Calculate preview height based on sliders
                local baseHeight = 50
                if #shapeData.sliders > 0 then
                    baseHeight = baseHeight + (#shapeData.sliders * 38) + 20
                else
                    baseHeight = 80
                end
                
                TweenService:Create(shapeContainer, TweenPresets.Expand, {Size = UDim2.new(1, 0, 0, 50 + baseHeight)}):Play()
                TweenService:Create(shapePreviewFrame, TweenPresets.Expand, {Size = UDim2.new(1, 0, 0, baseHeight)}):Play()
            else
                TweenService:Create(previewArrowBtn, TweenPresets.ButtonHover, {Rotation = 0}):Play()
                TweenService:Create(shapeContainer, TweenPresets.Collapse, {Size = UDim2.new(1, 0, 0, 50)}):Play()
                TweenService:Create(shapePreviewFrame, TweenPresets.Collapse, {Size = UDim2.new(1, 0, 0, 0)}):Play()
                task.wait(0.3)
                shapePreviewFrame.Visible = false
            end
        end)
    end

    for i, shapeData in ipairs(ShapesConfig) do
        createShapeItem(shapeData, i)
    end

    -- Settings Tab
    local settingsText = Instance.new("TextLabel")
    settingsText.Size = UDim2.new(1, 0, 1, 0)
    settingsText.BackgroundTransparency = 1
    settingsText.Text = "Settings Panel\n\nComing Soon..."
    settingsText.TextColor3 = Colors.TextSecondary
    settingsText.TextSize = 16
    settingsText.Font = Enum.Font.Gotham
    settingsText.Parent = tabContents["Settings"]

    -- Credits Tab
    local creditsText = Instance.new("TextLabel")
    creditsText.Size = UDim2.new(1, 0, 1, 0)
    creditsText.BackgroundTransparency = 1
    creditsText.Text = "Made by Zxm\n\nThanks for using this script!"
    creditsText.TextColor3 = Colors.TextSecondary
    creditsText.TextSize = 16
    creditsText.Font = Enum.Font.Gotham
    creditsText.Parent = tabContents["Credits"]

    -- Draggable - Fixed to prevent connection leak
    local dragging = false
    local dragStart = nil
    local startPos = nil

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)

    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local dragConnection = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    table.insert(dragConnections, dragConnection)

    -- Toggle Button
    local toggleScreenGui = Instance.new("ScreenGui")
    toggleScreenGui.Name = "ZxmToggle"
    toggleScreenGui.ResetOnSpawn = false
    toggleScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    toggleScreenGui.Parent = playerGui
    toggleScreenGui.Enabled = false

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleButton"
    toggleBtn.AnchorPoint = Vector2.new(1, 0)
    toggleBtn.Position = UDim2.new(1, -20, 0, 20)
    toggleBtn.Size = UDim2.new(0, 50, 0, 50)
    toggleBtn.BackgroundColor3 = Colors.TextPrimary
    toggleBtn.Text = "ZS"
    toggleBtn.TextColor3 = Colors.Background
    toggleBtn.TextSize = 18
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = toggleScreenGui
    createUICorner(toggleBtn, 12)

    toggleBtn.MouseEnter:Connect(function()
        TweenService:Create(toggleBtn, TweenPresets.ButtonHover, {Size = UDim2.new(0, 55, 0, 55)}):Play()
    end)
    toggleBtn.MouseLeave:Connect(function()
        TweenService:Create(toggleBtn, TweenPresets.ButtonHover, {Size = UDim2.new(0, 50, 0, 50)}):Play()
    end)

    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundTransparency = 1

    return {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        ContentFrame = contentFrame,
        MinimizeBtn = minimizeBtn,
        HideBtn = hideBtn,
        CloseBtn = closeBtn,
        ToggleScreenGui = toggleScreenGui,
        ToggleBtn = toggleBtn,
        DragConnections = dragConnections
    }
end

-- Execute Intro Animation
local intro = createIntroScreen()

task.spawn(function()
    intro.Background.BackgroundTransparency = 1
    TweenService:Create(intro.Background, TweenPresets.Intro, {BackgroundTransparency = 0}):Play()
    task.wait(0.3)

    TweenService:Create(intro.Line, TweenPresets.Intro, {Size = UDim2.new(0, 300, 0, 2)}):Play()
    task.wait(0.5)

    TweenService:Create(intro.CenterContainer, TweenPresets.SlideUp, {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
    TweenService:Create(intro.TextLabel, TweenPresets.TextFade, {TextTransparency = 0}):Play()
    task.wait(0.3)
    TweenService:Create(intro.SubText, TweenPresets.TextFade, {TextTransparency = 0}):Play()
    task.wait(1.5)

    TweenService:Create(intro.TextLabel, TweenPresets.Outro, {TextTransparency = 1}):Play()
    TweenService:Create(intro.SubText, TweenPresets.Outro, {TextTransparency = 1}):Play()
    TweenService:Create(intro.Line, TweenPresets.Outro, {Size = UDim2.new(0, 0, 0, 2)}):Play()
    task.wait(0.4)

    TweenService:Create(intro.Background, TweenPresets.Outro, {BackgroundTransparency = 1}):Play()
    task.wait(0.6)

    intro.ScreenGui:Destroy()

    local mainUI = createMainUI()
    
    TweenService:Create(mainUI.MainFrame, TweenPresets.ScaleIn, {
        Size = UDim2.new(0, 500, 0, 400),
        BackgroundTransparency = 0
    }):Play()

    local isMinimized = false
    local isHidden = false
    local originalSize = UDim2.new(0, 500, 0, 400)
    local minimizedSize = UDim2.new(0, 500, 0, 40)

    mainUI.MinimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            TweenService:Create(mainUI.MainFrame, TweenPresets.SizeChange, {Size = minimizedSize}):Play()
            mainUI.ContentFrame.Visible = false
            mainUI.MinimizeBtn.Text = "▭"
        else
            TweenService:Create(mainUI.MainFrame, TweenPresets.SizeChange, {Size = originalSize}):Play()
            mainUI.ContentFrame.Visible = true
            mainUI.MinimizeBtn.Text = "□"
        end
    end)

    mainUI.HideBtn.MouseButton1Click:Connect(function()
        isHidden = not isHidden
        if isHidden then
            TweenService:Create(mainUI.MainFrame, TweenPresets.Outro, {
                Size = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1
            }):Play()
            task.wait(0.5)
            mainUI.ScreenGui.Enabled = false
            
            mainUI.ToggleScreenGui.Enabled = true
            mainUI.ToggleBtn.Size = UDim2.new(0, 0, 0, 0)
            TweenService:Create(mainUI.ToggleBtn, TweenPresets.ScaleIn, {Size = UDim2.new(0, 50, 0, 50)}):Play()
        end
    end)

    mainUI.ToggleBtn.MouseButton1Click:Connect(function()
        isHidden = false
        TweenService:Create(mainUI.ToggleBtn, TweenPresets.ScaleOut, {Size = UDim2.new(0, 0, 0, 0)}):Play()
        task.wait(0.3)
        mainUI.ToggleScreenGui.Enabled = false
        
        mainUI.ScreenGui.Enabled = true
        mainUI.MainFrame.BackgroundTransparency = 0
        TweenService:Create(mainUI.MainFrame, TweenPresets.ScaleIn, {
            Size = isMinimized and minimizedSize or originalSize,
            BackgroundTransparency = 0
        }):Play()
    end)

    mainUI.CloseBtn.MouseButton1Click:Connect(function()
        -- Disconnect drag connection to prevent memory leak
        for _, conn in ipairs(mainUI.DragConnections) do
            conn:Disconnect()
        end
        
        TweenService:Create(mainUI.MainFrame, TweenPresets.ScaleOut, {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.5)
        mainUI.ScreenGui:Destroy()
        mainUI.ToggleScreenGui:Destroy()
    end)
end)
