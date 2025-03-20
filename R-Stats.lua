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

-- Dragging functionality
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if not isPinned then
            isDragging = true
            dragOffset = input.Position - TitleBar.AbsolutePosition
        end
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
        dragOffset = nil
    end
end)

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
UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local newPosition = UDim2.new(0, input.Position.X - dragOffset.X, 0, input.Position.Y - dragOffset.Y)
        
        -- Add smooth animation to dragging
        local dragTween = TweenService:Create(MainFrame, TweenInfo.new(0.1), {
            Position = newPosition
        })
        dragTween:Play()
    end
    
    if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local deltaX = input.Position.X - resizeStartPos.X
        local deltaY = input.Position.Y - resizeStartPos.Y
        
        local newWidth = math.clamp(resizeStartSize.X.Offset + deltaX, config.minSize.X, config.maxSize.X)
        local newHeight = math.clamp(resizeStartSize.Y.Offset + deltaY, config.minSize.Y, config.maxSize.Y)
        
        -- Apply resize immediately (without animation for better UX)
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