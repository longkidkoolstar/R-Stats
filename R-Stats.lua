-- Discord-Inspired Stats GUI by Claude
-- Features: Smooth animations, username display, resizable interface
-- Fully interactive with Discord-like aesthetics

-- Configuration
local config = {
    initialPosition = UDim2.new(0, 20, 0, 20),
    initialSize = UDim2.new(0, 250, 0, 180),
    minSize = Vector2.new(200, 150),
    maxSize = Vector2.new(400, 300),
    backgroundColor = Color3.fromRGB(47, 49, 54), -- Discord dark theme
    textColor = Color3.fromRGB(220, 221, 222), -- Discord text color
    accentColor = Color3.fromRGB(114, 137, 218), -- Discord blurple
    cornerRadius = 8,
    transparency = 0.1,
    titleBarHeight = 32,
    updateInterval = 0.5, -- Update frequency in seconds
    font = Enum.Font.GothamSemibold,
    animationSpeed = 0.2, -- Animation duration in seconds
    resizeHandleSize = 15
}

-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local startTime = os.time()
local frameRates = {}
local isPinned = false
local isDragging = false
local isResizing = false
local dragOffset = nil
local resizeStartSize = nil
local resizeStartPos = nil

-- Animation settings
local animationInfo = TweenInfo.new(
    config.animationSpeed,
    Enum.EasingStyle.Quart,
    Enum.EasingDirection.Out
)

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DiscordStatsGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = config.initialSize
MainFrame.Position = config.initialPosition
MainFrame.BackgroundColor3 = config.backgroundColor
MainFrame.BackgroundTransparency = config.transparency
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

-- Corner Rounding
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, config.cornerRadius)
UICorner.Parent = MainFrame

-- Add shadow effect
local DropShadow = Instance.new("ImageLabel")
DropShadow.Name = "DropShadow"
DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
DropShadow.BackgroundTransparency = 1
DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
DropShadow.Size = UDim2.new(1, 24, 1, 24)
DropShadow.ZIndex = -1
DropShadow.Image = "rbxassetid://6014261993"
DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
DropShadow.ImageTransparency = 0.5
DropShadow.ScaleType = Enum.ScaleType.Slice
DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
DropShadow.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, config.titleBarHeight)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(32, 34, 37) -- Discord darker gray
TitleBar.BackgroundTransparency = 0
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

-- Title Bar Gradient
local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 34, 37)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(41, 43, 47))
})
TitleGradient.Rotation = 90
TitleGradient.Parent = TitleBar

-- Title Corner Rounding
local TitleUICorner = Instance.new("UICorner")
TitleUICorner.CornerRadius = UDim.new(0, config.cornerRadius)
TitleUICorner.Parent = TitleBar

-- Discord-like Icon
local Icon = Instance.new("Frame")
Icon.Name = "Icon"
Icon.Size = UDim2.new(0, 20, 0, 20)
Icon.Position = UDim2.new(0, 10, 0, 6)
Icon.BackgroundColor3 = config.accentColor
Icon.BorderSizePixel = 0
Icon.Parent = TitleBar

-- Icon Corner Rounding
local IconUICorner = Instance.new("UICorner")
IconUICorner.CornerRadius = UDim.new(1, 0) -- Make it circular
IconUICorner.Parent = Icon

-- Title Text
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0, 40, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = config.font
Title.Text = "Stats Dashboard"
Title.TextColor3 = config.textColor
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Pin Button
local PinButton = Instance.new("ImageButton")
PinButton.Name = "PinButton"
PinButton.Size = UDim2.new(0, 25, 0, 25)
PinButton.Position = UDim2.new(1, -90, 0, 4)
PinButton.BackgroundTransparency = 1
PinButton.Image = "rbxassetid://3926307971"
PinButton.ImageRectOffset = Vector2.new(404, 284)
PinButton.ImageRectSize = Vector2.new(36, 36)
PinButton.ImageColor3 = Color3.fromRGB(185, 187, 190) -- Discord icon color
PinButton.Parent = TitleBar

-- Minimize Button
local MinimizeButton = Instance.new("ImageButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 25, 0, 25)
MinimizeButton.Position = UDim2.new(1, -60, 0, 4)
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.Image = "rbxassetid://3926307971"
MinimizeButton.ImageRectOffset = Vector2.new(884, 284)
MinimizeButton.ImageRectSize = Vector2.new(36, 36)
MinimizeButton.ImageColor3 = Color3.fromRGB(185, 187, 190) -- Discord icon color
MinimizeButton.Parent = TitleBar

-- Close Button
local CloseButton = Instance.new("ImageButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Position = UDim2.new(1, -30, 0, 4)
CloseButton.BackgroundTransparency = 1
CloseButton.Image = "rbxassetid://3926305904"
CloseButton.ImageRectOffset = Vector2.new(284, 4)
CloseButton.ImageRectSize = Vector2.new(24, 24)
CloseButton.ImageColor3 = Color3.fromRGB(185, 187, 190) -- Discord icon color
CloseButton.Parent = TitleBar

-- Stats Container
local StatsContainer = Instance.new("Frame")
StatsContainer.Name = "StatsContainer"
StatsContainer.Size = UDim2.new(1, -20, 1, -(config.titleBarHeight + 10))
StatsContainer.Position = UDim2.new(0, 10, 0, config.titleBarHeight + 5)
StatsContainer.BackgroundTransparency = 1
StatsContainer.BorderSizePixel = 0
StatsContainer.Parent = MainFrame

-- Add this after the existing StatsContainer creation

-- Create Tabs Container
local TabsContainer = Instance.new("Frame")
TabsContainer.Name = "TabsContainer"
TabsContainer.Size = UDim2.new(1, -20, 0, 30)
TabsContainer.Position = UDim2.new(0, 10, 0, config.titleBarHeight + 5)
TabsContainer.BackgroundTransparency = 1
TabsContainer.BorderSizePixel = 0
TabsContainer.Parent = MainFrame

-- Stats Tab Button
local StatsTabButton = Instance.new("TextButton")
StatsTabButton.Name = "StatsTabButton"
StatsTabButton.Size = UDim2.new(0.4, 0, 1, 0)
StatsTabButton.Position = UDim2.new(0, 0, 0, 0)
StatsTabButton.BackgroundColor3 = config.accentColor
StatsTabButton.BackgroundTransparency = 0.5
StatsTabButton.Text = "Stats"
StatsTabButton.TextColor3 = config.textColor
StatsTabButton.TextSize = 14
StatsTabButton.Font = config.font
StatsTabButton.Parent = TabsContainer

-- Cheats Tab Button
local CheatsTabButton = Instance.new("TextButton")
CheatsTabButton.Name = "CheatsTabButton"
CheatsTabButton.Size = UDim2.new(0.4, 0, 1, 0)
CheatsTabButton.Position = UDim2.new(0.6, 0, 0, 0)
CheatsTabButton.BackgroundColor3 = config.accentColor
CheatsTabButton.BackgroundTransparency = 0.8
CheatsTabButton.Text = "Cheats"
CheatsTabButton.TextColor3 = config.textColor
CheatsTabButton.TextSize = 14
CheatsTabButton.Font = config.font
CheatsTabButton.Parent = TabsContainer

-- Corner Rounding for Tabs
local TabUICorner = Instance.new("UICorner")
TabUICorner.CornerRadius = UDim.new(0, 4)
TabUICorner.Parent = StatsTabButton
TabUICorner:Clone().Parent = CheatsTabButton

-- Create Cheats Container
local CheatsContainer = Instance.new("Frame")
CheatsContainer.Name = "CheatsContainer"
CheatsContainer.Size = UDim2.new(1, -20, 1, -(config.titleBarHeight + 40))
CheatsContainer.Position = UDim2.new(0, 10, 0, config.titleBarHeight + 40)
CheatsContainer.BackgroundTransparency = 1
CheatsContainer.BorderSizePixel = 0
CheatsContainer.Visible = false -- Initially hidden
CheatsContainer.Parent = MainFrame

-- Function to create cheat buttons
local function createCheatButton(name, yPos, callback)
    local Button = Instance.new("TextButton")
    Button.Name = name .. "Button"
    Button.Size = UDim2.new(1, 0, 0, 30)
    Button.Position = UDim2.new(0, 0, 0, yPos)
    Button.BackgroundColor3 = Color3.fromRGB(64, 68, 75) -- Discord mention background
    Button.BackgroundTransparency = 0.9
    Button.Text = name
    Button.TextColor3 = config.textColor
    Button.TextSize = 14
    Button.Font = config.font
    Button.Parent = CheatsContainer

    -- Corner Rounding
    local ButtonUICorner = Instance.new("UICorner")
    ButtonUICorner.CornerRadius = UDim.new(0, 4)
    ButtonUICorner.Parent = Button

    -- Hover effect
    Button.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(Button, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.8
        })
        hoverTween:Play()
    end)

    Button.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(Button, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.9
        })
        leaveTween:Play()
    end)

    -- Click event
    Button.MouseButton1Click:Connect(callback)
end

-- Fly Cheat
local isFlying = false
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyConnection = nil

createCheatButton("Fly", 0, function()
    isFlying = not isFlying

    if isFlying then
        -- Enable Fly
        local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge) -- Set proper max force
        flyBodyVelocity.Parent = humanoidRootPart

        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge) -- Set proper max torque
        flyBodyGyro.P = 10000
        flyBodyGyro.D = 100
        flyBodyGyro.CFrame = humanoidRootPart.CFrame
        flyBodyGyro.Parent = humanoidRootPart

        -- Enable controls
        local userInputService = game:GetService("UserInputService")
        local camera = workspace.CurrentCamera

        -- Disconnect previous connection if it exists
        if flyConnection then flyConnection:Disconnect() end
        
        flyConnection = RunService.Heartbeat:Connect(function()
            if not isFlying or not humanoidRootPart or not humanoidRootPart.Parent then 
                if flyConnection then flyConnection:Disconnect() end
                return 
            end

            local direction = Vector3.new()
            if userInputService:IsKeyDown(Enum.KeyCode.W) then
                direction = direction + camera.CFrame.LookVector
            end
            if userInputService:IsKeyDown(Enum.KeyCode.S) then
                direction = direction - camera.CFrame.LookVector
            end
            if userInputService:IsKeyDown(Enum.KeyCode.A) then
                direction = direction - camera.CFrame.RightVector
            end
            if userInputService:IsKeyDown(Enum.KeyCode.D) then
                direction = direction + camera.CFrame.RightVector
            end
            if userInputService:IsKeyDown(Enum.KeyCode.Space) then
                direction = direction + Vector3.new(0, 1, 0)
            end
            if userInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                direction = direction - Vector3.new(0, 1, 0)
            end

            if direction.Magnitude > 0 then
                direction = direction.Unit * 50
            end

            flyBodyVelocity.Velocity = direction
            flyBodyGyro.CFrame = CFrame.lookAt(humanoidRootPart.Position, humanoidRootPart.Position + camera.CFrame.LookVector)
        end)
    else
        -- Disable Fly
        if flyConnection then 
            flyConnection:Disconnect() 
            flyConnection = nil
        end
        
        if flyBodyVelocity then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end
        
        if flyBodyGyro then
            flyBodyGyro:Destroy()
            flyBodyGyro = nil
        end
    end
end)

-- ESP Cheat
local isESPEnabled = false
local espBoxes = {}

createCheatButton("ESP", 35, function()
    isESPEnabled = not isESPEnabled

    if isESPEnabled then
        -- Enable ESP
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local character = player.Character
                local box = Instance.new("BoxHandleAdornment")
                box.Size = character:GetExtentsSize()
                box.Adornee = character
                box.AlwaysOnTop = true
                box.ZIndex = 10
                box.Transparency = 0.5
                box.Color3 = Color3.new(1, 0, 0)
                box.Parent = character

                espBoxes[player] = box
            end
        end

        -- Listen for new players
        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(character)
                if isESPEnabled then
                    local box = Instance.new("BoxHandleAdornment")
                    box.Size = character:GetExtentsSize()
                    box.Adornee = character
                    box.AlwaysOnTop = true
                    box.ZIndex = 10
                    box.Transparency = 0.5
                    box.Color3 = Color3.new(1, 0, 0)
                    box.Parent = character

                    espBoxes[player] = box
                end
            end)
        end)
    else
        -- Disable ESP
        for player, box in pairs(espBoxes) do
            box:Destroy()
        end
        espBoxes = {}
    end
end)

local bToolsEnabled = false
local bTools = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Global hover SelectionBox
local hoverBox = Instance.new("SelectionBox")
hoverBox.LineThickness = 0.05
hoverBox.Color3 = Color3.fromRGB(255, 255, 0)
hoverBox.Parent = workspace
hoverBox.Adornee = nil

-- Updates hover highlight
RunService.RenderStepped:Connect(function()
    if bToolsEnabled then
        local target = Mouse.Target
        if target and target:IsA("BasePart") then
            hoverBox.Adornee = target
        else
            hoverBox.Adornee = nil
        end
    else
        hoverBox.Adornee = nil
    end
end)

createCheatButton("B-Tools", 70, function()
    bToolsEnabled = not bToolsEnabled

    if bToolsEnabled then
        -- 🛠 Hammer Tool
        local hammer = Instance.new("Tool")
        hammer.Name = "Hammer"
        hammer.RequiresHandle = false

        hammer.Activated:Connect(function()
            local target = Mouse.Target
            if target then
                target:Destroy()
            end
        end)

        hammer.Parent = LocalPlayer.Backpack
        table.insert(bTools, hammer)

        -- 🧱 Clone Tool
        local clone = Instance.new("Tool")
        clone.Name = "Clone"
        clone.RequiresHandle = false

        clone.Activated:Connect(function()
            local target = Mouse.Target
            if target and target:IsA("BasePart") then
                local newPart = target:Clone()
                newPart.Parent = target.Parent
                newPart.Position = target.Position + Vector3.new(0, target.Size.Y, 0)
            end
        end)

        clone.Parent = LocalPlayer.Backpack
        table.insert(bTools, clone)

        -- ✋ Grab Tool
        local grab = Instance.new("Tool")
        grab.Name = "Grab"
        grab.RequiresHandle = false

        local selectedPart = nil
        local selectionBox = Instance.new("SelectionBox")
        selectionBox.LineThickness = 0.05
        selectionBox.Color3 = Color3.fromRGB(0, 170, 255)
        selectionBox.Parent = workspace

        local moveConn = nil

        grab.Activated:Connect(function()
            local target = Mouse.Target
            if target and target:IsA("BasePart") and not selectedPart then
                selectedPart = target
                selectionBox.Adornee = selectedPart

                moveConn = RunService.RenderStepped:Connect(function()
                    if selectedPart and grab.Enabled then
                        local ray = workspace.CurrentCamera:ScreenPointToRay(Mouse.X, Mouse.Y)
                        local targetPos = ray.Origin + ray.Direction * 25
                        selectedPart.Position = targetPos
                    end
                end)
            else
                selectedPart = nil
                selectionBox.Adornee = nil
                if moveConn then moveConn:Disconnect() end
            end
        end)

        grab.Deactivated:Connect(function()
            selectedPart = nil
            selectionBox.Adornee = nil
            if moveConn then moveConn:Disconnect() end
        end)

        grab.Parent = LocalPlayer.Backpack
        table.insert(bTools, grab)
    else
        for _, tool in pairs(bTools) do
            tool:Destroy()
        end
        bTools = {}
        hoverBox.Adornee = nil
    end
end)

-- Tab Switching Logic
StatsTabButton.MouseButton1Click:Connect(function()
    StatsContainer.Visible = true
    CheatsContainer.Visible = false
    StatsTabButton.BackgroundTransparency = 0.5
    CheatsTabButton.BackgroundTransparency = 0.8
end)

CheatsTabButton.MouseButton1Click:Connect(function()
    StatsContainer.Visible = false
    CheatsContainer.Visible = true
    StatsTabButton.BackgroundTransparency = 0.8
    CheatsTabButton.BackgroundTransparency = 0.5
end)

-- Initialize with Stats tab open
StatsTabButton.BackgroundTransparency = 0.5
CheatsTabButton.BackgroundTransparency = 0.8
-- Username Display with Discord-like mention box
local UsernameContainer = Instance.new("Frame")
UsernameContainer.Name = "UsernameContainer"
UsernameContainer.Size = UDim2.new(1, 0, 0, 30)
UsernameContainer.Position = UDim2.new(0, 0, 0, 0)
UsernameContainer.BackgroundTransparency = 0.9
UsernameContainer.BackgroundColor3 = Color3.fromRGB(64, 68, 75) -- Discord mention background
UsernameContainer.BorderSizePixel = 0
UsernameContainer.Parent = StatsContainer

-- Username Container Corner Rounding
local UsernameUICorner = Instance.new("UICorner")
UsernameUICorner.CornerRadius = UDim.new(0, 4)
UsernameUICorner.Parent = UsernameContainer

-- Username Symbol
local UserSymbol = Instance.new("TextLabel")
UserSymbol.Name = "UserSymbol"
UserSymbol.Size = UDim2.new(0, 20, 0, 20)
UserSymbol.Position = UDim2.new(0, 5, 0, 5)
UserSymbol.BackgroundTransparency = 1
UserSymbol.Font = Enum.Font.SourceSansBold
UserSymbol.Text = "@"
UserSymbol.TextColor3 = config.accentColor
UserSymbol.TextSize = 18
UserSymbol.Parent = UsernameContainer

-- Username Label
local UsernameLabel = Instance.new("TextLabel")
UsernameLabel.Name = "UsernameLabel"
UsernameLabel.Size = UDim2.new(1, -30, 1, 0)
UsernameLabel.Position = UDim2.new(0, 25, 0, 0)
UsernameLabel.BackgroundTransparency = 1
UsernameLabel.Font = config.font
UsernameLabel.Text = LocalPlayer.Name
UsernameLabel.TextColor3 = config.accentColor
UsernameLabel.TextSize = 16
UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
UsernameLabel.Parent = UsernameContainer

-- Create Stat Item (with Discord style)
local function createStatItem(name, yPos, icon)
    local Container = Instance.new("Frame")
    Container.Name = name .. "Container"
    Container.Size = UDim2.new(1, 0, 0, 28)
    Container.Position = UDim2.new(0, 0, 0, yPos)
    Container.BackgroundTransparency = 0.9
    Container.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
    Container.BorderSizePixel = 0
    Container.Parent = StatsContainer
    
    -- Container Corner Rounding
    local ContainerUICorner = Instance.new("UICorner")
    ContainerUICorner.CornerRadius = UDim.new(0, 4)
    ContainerUICorner.Parent = Container
    
    -- Icon
    local IconLabel = Instance.new("ImageLabel")
    IconLabel.Name = "Icon"
    IconLabel.Size = UDim2.new(0, 18, 0, 18)
    IconLabel.Position = UDim2.new(0, 5, 0, 5)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Image = icon.image
    if icon.isRectImage then
        IconLabel.ImageRectOffset = icon.offset
        IconLabel.ImageRectSize = icon.size
    end
    IconLabel.ImageColor3 = Color3.fromRGB(185, 187, 190)
    IconLabel.Parent = Container
    
    -- Label
    local Label = Instance.new("TextLabel")
    Label.Name = name .. "Label"
    Label.Size = UDim2.new(0.4, 0, 1, 0)
    Label.Position = UDim2.new(0, 30, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Font = config.font
    Label.Text = name .. ":"
    Label.TextColor3 = Color3.fromRGB(185, 187, 190)
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container
    
    -- Value
    local Value = Instance.new("TextLabel")
    Value.Name = name .. "Value"
    Value.Size = UDim2.new(0.55, 0, 1, 0)
    Value.Position = UDim2.new(0.45, 0, 0, 0)
    Value.BackgroundTransparency = 1
    Value.Font = config.font
    Value.Text = "Calculating..."
    Value.TextColor3 = config.textColor
    Value.TextSize = 14
    Value.TextXAlignment = Enum.TextXAlignment.Left
    Value.Parent = Container
    
    return Value
end

-- Create stat items with icons
local FPSValue = createStatItem("FPS", 35, {
    image = "rbxassetid://3926305904", 
    isRectImage = true,
    offset = Vector2.new(4, 444),
    size = Vector2.new(36, 36)
})

local PingValue = createStatItem("Ping", 68, {
    image = "rbxassetid://3926307971", 
    isRectImage = true,
    offset = Vector2.new(324, 124),
    size = Vector2.new(36, 36)
})

local PlaytimeValue = createStatItem("Playtime", 101, {
    image = "rbxassetid://3926307971", 
    isRectImage = true,
    offset = Vector2.new(804, 124),
    size = Vector2.new(36, 36)
})

local MemoryValue = createStatItem("Memory", 134, {
    image = "rbxassetid://3926305904", 
    isRectImage = true,
    offset = Vector2.new(984, 204),
    size = Vector2.new(36, 36)
})

-- Resize handle
local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Name = "ResizeHandle"
ResizeHandle.Size = UDim2.new(0, config.resizeHandleSize, 0, config.resizeHandleSize)
ResizeHandle.Position = UDim2.new(1, -config.resizeHandleSize, 1, -config.resizeHandleSize)
ResizeHandle.BackgroundTransparency = 1
ResizeHandle.Text = ""
ResizeHandle.ZIndex = 10
ResizeHandle.Parent = MainFrame

-- Resize Handle Icon
local ResizeIcon = Instance.new("ImageLabel")
ResizeIcon.Name = "ResizeIcon"
ResizeIcon.Size = UDim2.new(1, 0, 1, 0)
ResizeIcon.BackgroundTransparency = 1
ResizeIcon.Image = "rbxassetid://3926307971"
ResizeIcon.ImageRectOffset = Vector2.new(324, 524)
ResizeIcon.ImageRectSize = Vector2.new(36, 36)
ResizeIcon.ImageColor3 = Color3.fromRGB(114, 118, 125)
ResizeIcon.ImageTransparency = 0.3
ResizeIcon.Parent = ResizeHandle

-- Collapsed state elements
local isCollapsed = false
local collapsedSize = UDim2.new(0, config.initialSize.X.Offset, 0, config.titleBarHeight)
local expandedSize = config.initialSize

-- Functions
local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function updateStats()
    -- Calculate FPS
    local fps = #frameRates
    FPSValue.Text = fps .. " fps"
    
    -- Set text color based on FPS
    if fps > 45 then
        FPSValue.TextColor3 = Color3.fromRGB(87, 242, 135) -- Green
    elseif fps > 30 then
        FPSValue.TextColor3 = Color3.fromRGB(255, 184, 108) -- Orange
    else
        FPSValue.TextColor3 = Color3.fromRGB(255, 118, 118) -- Red
    end
    
    -- Update ping
    local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
    PingValue.Text = ping .. " ms"
    
    -- Set text color based on ping
    if ping < 100 then
        PingValue.TextColor3 = Color3.fromRGB(87, 242, 135) -- Green
    elseif ping < 200 then
        PingValue.TextColor3 = Color3.fromRGB(255, 184, 108) -- Orange
    else
        PingValue.TextColor3 = Color3.fromRGB(255, 118, 118) -- Red
    end
    
    -- Update playtime
    local currentPlaytime = os.time() - startTime
    PlaytimeValue.Text = formatTime(currentPlaytime)
    
    -- Update memory usage
    local memoryUsageMB = math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb())
    MemoryValue.Text = memoryUsageMB .. " MB"
end

-- Animation functions
local function collapsePanel()
    isCollapsed = true
    ResizeHandle.Visible = false
    
    -- Animate collapse
    local collapseTween = TweenService:Create(MainFrame, animationInfo, {
        Size = collapsedSize
    })
    collapseTween:Play()
    
    -- Update visibility after animation
    collapseTween.Completed:Connect(function()
        StatsContainer.Visible = false
    end)
end

local function expandPanel()
    isCollapsed = false
    StatsContainer.Visible = true
    
    -- Animate expand
    local expandTween = TweenService:Create(MainFrame, animationInfo, {
        Size = expandedSize
    })
    expandTween:Play()
    
    -- Show resize handle after animation
    expandTween.Completed:Connect(function()
        ResizeHandle.Visible = true
    end)
end

-- Replace the TitleBar.InputBegan and TitleBar.InputEnded connections with these:

-- Dragging functionality for the title bar
-- Replace the TitleBar.InputBegan connection with this:
TitleBar.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or 
        input.UserInputType == Enum.UserInputType.Touch) and not isPinned then
        
        -- Calculate the offset from the cursor to the top-left of the MainFrame
        local mousePos = UserInputService:GetMouseLocation()
        dragOffset = Vector2.new(
            mousePos.X - MainFrame.AbsolutePosition.X,
            mousePos.Y - MainFrame.AbsolutePosition.Y
        )
        
        isDragging = true
    end
end)

-- And replace the UserInputService.InputChanged handler with this:
UserInputService.InputChanged:Connect(function(input)
    if isDragging and 
       (input.UserInputType == Enum.UserInputType.MouseMovement or 
        input.UserInputType == Enum.UserInputType.Touch) then
        
        local mousePos = UserInputService:GetMouseLocation()
        local newPosition = UDim2.new(
            0, 
            mousePos.X - dragOffset.X,
            0, 
            mousePos.Y - dragOffset.Y
        )
        
        -- Set position directly
        MainFrame.Position = newPosition
    end
    
    -- Keep the existing resize code here...
    if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local deltaX = input.Position.X - resizeStartPos.X
        local deltaY = input.Position.Y - resizeStartPos.Y
        
        local newWidth = math.clamp(resizeStartSize.X.Offset + deltaX, config.minSize.X, config.maxSize.X)
        local newHeight = math.clamp(resizeStartSize.Y.Offset + deltaY, config.minSize.Y, config.maxSize.Y)
        
        MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

-- Add this TitleBar.InputEnded connection to handle releasing the mouse:
TitleBar.InputEnded:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or 
        input.UserInputType == Enum.UserInputType.Touch) then
        
        isDragging = false
    end
end)

-- Also add a global InputEnded connection to ensure dragging stops even if released outside the TitleBar:
UserInputService.InputEnded:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or 
        input.UserInputType == Enum.UserInputType.Touch) then
        
        isDragging = false
    end
end)

-- You can remove the previous InputEnded connection for TitleBar
-- as we're handling it in the InputBegan's Changed event

-- Resizing functionality
ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = true
        resizeStartPos = input.Position
        resizeStartSize = MainFrame.Size
    end
end)

ResizeHandle.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = false
        resizeStartPos = nil
        resizeStartSize = nil
        expandedSize = MainFrame.Size -- Remember the new size
    end
end)

-- Move and resize handlers
-- Replace the current InputChanged event handler with this:
UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        -- Calculate new position directly without tweening
        local newPosition = UDim2.new(
            0, 
            input.Position.X - dragOffset.X, 
            0, 
            input.Position.Y - dragOffset.Y
        )
        
        -- Apply new position immediately
        MainFrame.Position = newPosition
    end
    
    if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local deltaX = input.Position.X - resizeStartPos.X
        local deltaY = input.Position.Y - resizeStartPos.Y
        
        local newWidth = math.clamp(resizeStartSize.X.Offset + deltaX, config.minSize.X, config.maxSize.X)
        local newHeight = math.clamp(resizeStartSize.Y.Offset + deltaY, config.minSize.Y, config.maxSize.Y)
        
        -- Apply resize immediately
        MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

-- Pin toggle function with animation
PinButton.MouseButton1Click:Connect(function()
    isPinned = not isPinned
    
    -- Animate color change
    local pinTween = TweenService:Create(PinButton, animationInfo, {
        ImageColor3 = isPinned and config.accentColor or Color3.fromRGB(185, 187, 190)
    })
    pinTween:Play()
    
    -- Add pop animation
    local sizeTween = TweenService:Create(PinButton, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {
        Size = UDim2.new(0, 28, 0, 28)
    })
    sizeTween:Play()
    
    sizeTween.Completed:Connect(function()
        local revertTween = TweenService:Create(PinButton, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 25, 0, 25)
        })
        revertTween:Play()
    end)
end)

-- Minimize/Expand button
MinimizeButton.MouseButton1Click:Connect(function()
    if isCollapsed then
        expandPanel()
    else
        collapsePanel()
    end
    
    -- Add click animation
    local sizeTween = TweenService:Create(MinimizeButton, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {
        Size = UDim2.new(0, 28, 0, 28)
    })
    sizeTween:Play()
    
    sizeTween.Completed:Connect(function()
        local revertTween = TweenService:Create(MinimizeButton, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 25, 0, 25)
        })
        revertTween:Play()
    end)
end)

-- Close button with fade animation
CloseButton.MouseButton1Click:Connect(function()
    -- Animate closing
    local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset + MainFrame.Size.X.Offset/2, 
                             MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + MainFrame.Size.Y.Offset/2)
    })
    closeTween:Play()
    
    -- Fade out
    local fadeTween = TweenService:Create(MainFrame, TweenInfo.new(0.3), {
        BackgroundTransparency = 1
    })
    fadeTween:Play()
    
    -- Destroy after animation completes
    closeTween.Completed:Connect(function()
        ScreenGui:Destroy()
    end)
end)

-- Hover effects for buttons
local function applyHoverEffect(button)
    button.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(button, TweenInfo.new(0.2), {
            ImageColor3 = Color3.fromRGB(255, 255, 255)
        })
        hoverTween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local defaultColor = button == PinButton and (isPinned and config.accentColor or Color3.fromRGB(185, 187, 190)) or Color3.fromRGB(185, 187, 190)
        local leaveTween = TweenService:Create(button, TweenInfo.new(0.2), {
            ImageColor3 = defaultColor
        })
        leaveTween:Play()
    end)
end

applyHoverEffect(PinButton)
applyHoverEffect(MinimizeButton)
applyHoverEffect(CloseButton)

-- Add intro animation when GUI first appears
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(config.initialPosition.X.Scale, config.initialPosition.X.Offset + config.initialSize.X.Offset/2, 
                              config.initialPosition.Y.Scale, config.initialPosition.Y.Offset + config.initialSize.Y.Offset/2)
MainFrame.BackgroundTransparency = 1

-- Play intro animation
local introSizeTween = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = config.initialSize,
    Position = config.initialPosition
})
introSizeTween:Play()

local introFadeTween = TweenService:Create(MainFrame, TweenInfo.new(0.5), {
    BackgroundTransparency = config.transparency
})
introFadeTween:Play()

-- FPS Counter
RunService.RenderStepped:Connect(function()
    table.insert(frameRates, os.clock())
    
    -- Only keep the last second of frames for FPS calculation
    local currentTime = os.clock()
    while #frameRates > 0 and frameRates[1] < currentTime - 1 do
        table.remove(frameRates, 1)
    end
end)

-- Update stats periodically
spawn(function()
    while wait(config.updateInterval) do
        if not isCollapsed then
            updateStats()
        end
    end
end)