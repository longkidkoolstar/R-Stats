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
    resizeHandleSize = 15,
    savePositionKey = "RStatsPosition", -- Key for saving position data
    saveThemeKey = "RStatsTheme" -- Key for saving theme data
}

-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local startTime = os.time()
local frameRates = {}
local isPinned = false
local isDragging = false
local isResizing = false
local dragOffset = nil
local resizeStartSize = nil
local resizeStartPos = nil
local lastPosition = nil
local lastSize = nil
local currentTheme = {
    background = config.backgroundColor,
    text = config.textColor,
    accent = config.accentColor,
    transparency = config.transparency
}

-- Functions for saving/loading position and theme
local function savePosition()
    local positionData = {
        X = MainFrame.Position.X.Offset,
        Y = MainFrame.Position.Y.Offset,
        Width = MainFrame.Size.X.Offset,
        Height = MainFrame.Size.Y.Offset,
        isPinned = isPinned
    }

    -- Use pcall to handle errors
    pcall(function()
        -- For studio testing, use writefile
        if writefile then
            writefile(config.savePositionKey .. ".json", HttpService:JSONEncode(positionData))
        end

        -- For game environment, can use Player data store
        -- local dataStore = DataStoreService:GetDataStore("RStatsSettings")
        -- dataStore:SetAsync(LocalPlayer.UserId .. "_" .. config.savePositionKey, positionData)
    end)
end

local function loadPosition()
    local positionData = nil

    -- Use pcall to handle errors
    pcall(function()
        -- For studio testing, use readfile
        if readfile and isfile and isfile(config.savePositionKey .. ".json") then
            positionData = HttpService:JSONDecode(readfile(config.savePositionKey .. ".json"))
        end

        -- For game environment, can use Player data store
        -- local dataStore = DataStoreService:GetDataStore("RStatsSettings")
        -- positionData = dataStore:GetAsync(LocalPlayer.UserId .. "_" .. config.savePositionKey)
    end)

    if positionData then
        lastPosition = UDim2.new(0, positionData.X, 0, positionData.Y)
        lastSize = UDim2.new(0, positionData.Width, 0, positionData.Height)
        isPinned = positionData.isPinned
        return true
    end

    return false
end

local function saveTheme()
    local themeData = {
        background = {
            R = currentTheme.background.R,
            G = currentTheme.background.G,
            B = currentTheme.background.B
        },
        text = {
            R = currentTheme.text.R,
            G = currentTheme.text.G,
            B = currentTheme.text.B
        },
        accent = {
            R = currentTheme.accent.R,
            G = currentTheme.accent.G,
            B = currentTheme.accent.B
        },
        transparency = currentTheme.transparency
    }

    -- Use pcall to handle errors
    pcall(function()
        -- For studio testing, use writefile
        if writefile then
            writefile(config.saveThemeKey .. ".json", HttpService:JSONEncode(themeData))
        end

        -- For game environment, can use Player data store
        -- local dataStore = DataStoreService:GetDataStore("RStatsSettings")
        -- dataStore:SetAsync(LocalPlayer.UserId .. "_" .. config.saveThemeKey, themeData)
    end)
end

local function loadTheme()
    local themeData = nil

    -- Use pcall to handle errors
    pcall(function()
        -- For studio testing, use readfile
        if readfile and isfile and isfile(config.saveThemeKey .. ".json") then
            themeData = HttpService:JSONDecode(readfile(config.saveThemeKey .. ".json"))
        end

        -- For game environment, can use Player data store
        -- local dataStore = DataStoreService:GetDataStore("RStatsSettings")
        -- themeData = dataStore:GetAsync(LocalPlayer.UserId .. "_" .. config.saveThemeKey)
    end)

    if themeData then
        currentTheme.background = Color3.new(themeData.background.R, themeData.background.G, themeData.background.B)
        currentTheme.text = Color3.new(themeData.text.R, themeData.text.G, themeData.text.B)
        currentTheme.accent = Color3.new(themeData.accent.R, themeData.accent.G, themeData.accent.B)
        currentTheme.transparency = themeData.transparency
        return true
    end

    return false
end

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
StatsContainer.Size = UDim2.new(1, -20, 1, -(config.titleBarHeight + 40))
StatsContainer.Position = UDim2.new(0, 10, 0, config.titleBarHeight + 40)
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
StatsTabButton.Size = UDim2.new(0.3, 0, 1, 0)
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
CheatsTabButton.Size = UDim2.new(0.3, 0, 1, 0)
CheatsTabButton.Position = UDim2.new(0.35, 0, 0, 0)
CheatsTabButton.BackgroundColor3 = config.accentColor
CheatsTabButton.BackgroundTransparency = 0.8
CheatsTabButton.Text = "Cheats"
CheatsTabButton.TextColor3 = config.textColor
CheatsTabButton.TextSize = 14
CheatsTabButton.Font = config.font
CheatsTabButton.Parent = TabsContainer

-- Settings Tab Button
local SettingsTabButton = Instance.new("TextButton")
SettingsTabButton.Name = "SettingsTabButton"
SettingsTabButton.Size = UDim2.new(0.3, 0, 1, 0)
SettingsTabButton.Position = UDim2.new(0.7, 0, 0, 0)
SettingsTabButton.BackgroundColor3 = config.accentColor
SettingsTabButton.BackgroundTransparency = 0.8
SettingsTabButton.Text = "Settings"
SettingsTabButton.TextColor3 = config.textColor
SettingsTabButton.TextSize = 14
SettingsTabButton.Font = config.font
SettingsTabButton.Parent = TabsContainer

-- Corner Rounding for Tabs
local TabUICorner = Instance.new("UICorner")
TabUICorner.CornerRadius = UDim.new(0, 4)
TabUICorner.Parent = StatsTabButton
TabUICorner:Clone().Parent = CheatsTabButton
TabUICorner:Clone().Parent = SettingsTabButton

-- Create Cheats Container
local CheatsContainer = Instance.new("Frame")
CheatsContainer.Name = "CheatsContainer"
CheatsContainer.Size = UDim2.new(1, -20, 1, -(config.titleBarHeight + 40))
CheatsContainer.Position = UDim2.new(0, 10, 0, config.titleBarHeight + 40)
CheatsContainer.BackgroundTransparency = 1
CheatsContainer.BorderSizePixel = 0
CheatsContainer.Visible = false -- Initially hidden
CheatsContainer.Parent = MainFrame

-- Create Settings Container
local SettingsContainer = Instance.new("Frame")
SettingsContainer.Name = "SettingsContainer"
SettingsContainer.Size = UDim2.new(1, -20, 1, -(config.titleBarHeight + 40))
SettingsContainer.Position = UDim2.new(0, 10, 0, config.titleBarHeight + 40)
SettingsContainer.BackgroundTransparency = 1
SettingsContainer.BorderSizePixel = 0
SettingsContainer.Visible = false -- Initially hidden
SettingsContainer.Parent = MainFrame

-- Create a ScrollingFrame for settings
local SettingsScroll = Instance.new("ScrollingFrame")
SettingsScroll.Name = "SettingsScroll"
SettingsScroll.Size = UDim2.new(1, 0, 1, 0)
SettingsScroll.Position = UDim2.new(0, 0, 0, 0)
SettingsScroll.BackgroundTransparency = 1
SettingsScroll.BorderSizePixel = 0
SettingsScroll.ScrollBarThickness = 4
SettingsScroll.ScrollBarImageColor3 = config.accentColor
SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, 250) -- Will adjust based on content
SettingsScroll.Parent = SettingsContainer

-- Create a UIListLayout for organized settings
local SettingsList = Instance.new("UIListLayout")
SettingsList.Padding = UDim.new(0, 10)
SettingsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SettingsList.SortOrder = Enum.SortOrder.LayoutOrder
SettingsList.Parent = SettingsScroll

-- Function to create a settings section
local function createSettingsSection(title, layoutOrder)
    local SectionFrame = Instance.new("Frame")
    SectionFrame.Name = title .. "Section"
    SectionFrame.Size = UDim2.new(0.95, 0, 0, 30) -- Height will be adjusted by content
    SectionFrame.BackgroundColor3 = Color3.fromRGB(64, 68, 75)
    SectionFrame.BackgroundTransparency = 0.7
    SectionFrame.BorderSizePixel = 0
    SectionFrame.LayoutOrder = layoutOrder
    SectionFrame.AutomaticSize = Enum.AutomaticSize.Y
    SectionFrame.Parent = SettingsScroll

    -- Section corner rounding
    local SectionCorner = Instance.new("UICorner")
    SectionCorner.CornerRadius = UDim.new(0, 6)
    SectionCorner.Parent = SectionFrame

    -- Section title
    local SectionTitle = Instance.new("TextLabel")
    SectionTitle.Name = "Title"
    SectionTitle.Size = UDim2.new(1, 0, 0, 30)
    SectionTitle.Position = UDim2.new(0, 0, 0, 0)
    SectionTitle.BackgroundTransparency = 1
    SectionTitle.Font = config.font
    SectionTitle.Text = title
    SectionTitle.TextColor3 = config.textColor
    SectionTitle.TextSize = 16
    SectionTitle.Parent = SectionFrame

    -- Content container
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "Content"
    ContentFrame.Size = UDim2.new(1, 0, 0, 0)
    ContentFrame.Position = UDim2.new(0, 0, 0, 30)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.AutomaticSize = Enum.AutomaticSize.Y
    ContentFrame.Parent = SectionFrame

    -- Content layout
    local ContentList = Instance.new("UIListLayout")
    ContentList.Padding = UDim.new(0, 8)
    ContentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ContentList.SortOrder = Enum.SortOrder.LayoutOrder
    ContentList.Parent = ContentFrame

    -- Add padding at the bottom
    local BottomPadding = Instance.new("UIPadding")
    BottomPadding.PaddingBottom = UDim.new(0, 10)
    BottomPadding.Parent = ContentFrame

    return ContentFrame
end

-- Function to create a color picker setting
local function createColorPicker(parent, name, initialColor, layoutOrder, callback)
    local SettingFrame = Instance.new("Frame")
    SettingFrame.Name = name .. "Setting"
    SettingFrame.Size = UDim2.new(0.9, 0, 0, 35)
    SettingFrame.BackgroundTransparency = 1
    SettingFrame.LayoutOrder = layoutOrder
    SettingFrame.Parent = parent

    -- Setting label
    local SettingLabel = Instance.new("TextLabel")
    SettingLabel.Name = "Label"
    SettingLabel.Size = UDim2.new(0.6, 0, 1, 0)
    SettingLabel.Position = UDim2.new(0, 0, 0, 0)
    SettingLabel.BackgroundTransparency = 1
    SettingLabel.Font = config.font
    SettingLabel.Text = name
    SettingLabel.TextColor3 = config.textColor
    SettingLabel.TextSize = 14
    SettingLabel.TextXAlignment = Enum.TextXAlignment.Left
    SettingLabel.Parent = SettingFrame

    -- Color display
    local ColorDisplay = Instance.new("Frame")
    ColorDisplay.Name = "ColorDisplay"
    ColorDisplay.Size = UDim2.new(0.35, 0, 0.8, 0)
    ColorDisplay.Position = UDim2.new(0.65, 0, 0.1, 0)
    ColorDisplay.BackgroundColor3 = initialColor
    ColorDisplay.BorderSizePixel = 0
    ColorDisplay.Parent = SettingFrame

    -- Color display corner rounding
    local ColorCorner = Instance.new("UICorner")
    ColorCorner.CornerRadius = UDim.new(0, 4)
    ColorCorner.Parent = ColorDisplay

    -- Color picker functionality
    ColorDisplay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Simple color picker with preset colors
            local ColorPickerFrame = Instance.new("Frame")
            ColorPickerFrame.Name = "ColorPicker"
            ColorPickerFrame.Size = UDim2.new(0, 180, 0, 100)
            ColorPickerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            ColorPickerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
            ColorPickerFrame.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
            ColorPickerFrame.BorderSizePixel = 0
            ColorPickerFrame.ZIndex = 100
            ColorPickerFrame.Parent = MainFrame

            -- Color picker corner rounding
            local PickerCorner = Instance.new("UICorner")
            PickerCorner.CornerRadius = UDim.new(0, 6)
            PickerCorner.Parent = ColorPickerFrame

            -- Color grid layout
            local ColorGrid = Instance.new("UIGridLayout")
            ColorGrid.CellSize = UDim2.new(0, 30, 0, 30)
            ColorGrid.CellPadding = UDim2.new(0, 5, 0, 5)
            ColorGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
            ColorGrid.VerticalAlignment = Enum.VerticalAlignment.Center
            ColorGrid.SortOrder = Enum.SortOrder.LayoutOrder
            ColorGrid.Parent = ColorPickerFrame

            -- Preset colors
            local colors = {
                Color3.fromRGB(47, 49, 54),   -- Discord dark
                Color3.fromRGB(114, 137, 218), -- Discord blurple
                Color3.fromRGB(255, 255, 255), -- White
                Color3.fromRGB(0, 0, 0),       -- Black
                Color3.fromRGB(255, 0, 0),     -- Red
                Color3.fromRGB(0, 255, 0),     -- Green
                Color3.fromRGB(0, 0, 255),     -- Blue
                Color3.fromRGB(255, 255, 0),   -- Yellow
                Color3.fromRGB(255, 0, 255),   -- Magenta
                Color3.fromRGB(0, 255, 255),   -- Cyan
                Color3.fromRGB(255, 165, 0),   -- Orange
                Color3.fromRGB(128, 0, 128)    -- Purple
            }

            -- Create color buttons
            for i, color in ipairs(colors) do
                local ColorButton = Instance.new("TextButton")
                ColorButton.Name = "Color" .. i
                ColorButton.BackgroundColor3 = color
                ColorButton.BorderSizePixel = 0
                ColorButton.Text = ""
                ColorButton.ZIndex = 101
                ColorButton.Parent = ColorPickerFrame

                -- Color button corner rounding
                local ButtonCorner = Instance.new("UICorner")
                ButtonCorner.CornerRadius = UDim.new(0, 4)
                ButtonCorner.Parent = ColorButton

                -- Color selection
                ColorButton.MouseButton1Click:Connect(function()
                    ColorDisplay.BackgroundColor3 = color
                    if callback then callback(color) end
                    ColorPickerFrame:Destroy()
                end)
            end

            -- Close picker when clicking outside
            local closeConnection
            closeConnection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local mousePos = UserInputService:GetMouseLocation()
                    local framePos = ColorPickerFrame.AbsolutePosition
                    local frameSize = ColorPickerFrame.AbsoluteSize

                    if mousePos.X < framePos.X or mousePos.X > framePos.X + frameSize.X or
                       mousePos.Y < framePos.Y or mousePos.Y > framePos.Y + frameSize.Y then
                        ColorPickerFrame:Destroy()
                        closeConnection:Disconnect()
                    end
                end
            end)
        end
    end)

    return ColorDisplay
end

-- Function to create a slider setting
local function createSlider(parent, name, min, max, initialValue, layoutOrder, callback)
    local SettingFrame = Instance.new("Frame")
    SettingFrame.Name = name .. "Setting"
    SettingFrame.Size = UDim2.new(0.9, 0, 0, 35)
    SettingFrame.BackgroundTransparency = 1
    SettingFrame.LayoutOrder = layoutOrder
    SettingFrame.Parent = parent

    -- Setting label
    local SettingLabel = Instance.new("TextLabel")
    SettingLabel.Name = "Label"
    SettingLabel.Size = UDim2.new(0.4, 0, 1, 0)
    SettingLabel.Position = UDim2.new(0, 0, 0, 0)
    SettingLabel.BackgroundTransparency = 1
    SettingLabel.Font = config.font
    SettingLabel.Text = name
    SettingLabel.TextColor3 = config.textColor
    SettingLabel.TextSize = 14
    SettingLabel.TextXAlignment = Enum.TextXAlignment.Left
    SettingLabel.Parent = SettingFrame

    -- Slider background
    local SliderBG = Instance.new("Frame")
    SliderBG.Name = "SliderBG"
    SliderBG.Size = UDim2.new(0.5, 0, 0.3, 0)
    SliderBG.Position = UDim2.new(0.4, 0, 0.35, 0)
    SliderBG.BackgroundColor3 = Color3.fromRGB(64, 68, 75)
    SliderBG.BorderSizePixel = 0
    SliderBG.Parent = SettingFrame

    -- Slider background corner rounding
    local SliderBGCorner = Instance.new("UICorner")
    SliderBGCorner.CornerRadius = UDim.new(0, 4)
    SliderBGCorner.Parent = SliderBG

    -- Slider fill
    local SliderFill = Instance.new("Frame")
    SliderFill.Name = "SliderFill"
    SliderFill.Size = UDim2.new((initialValue - min) / (max - min), 0, 1, 0)
    SliderFill.BackgroundColor3 = config.accentColor
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBG

    -- Slider fill corner rounding
    local SliderFillCorner = Instance.new("UICorner")
    SliderFillCorner.CornerRadius = UDim.new(0, 4)
    SliderFillCorner.Parent = SliderFill

    -- Value display
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Name = "Value"
    ValueLabel.Size = UDim2.new(0.1, 0, 1, 0)
    ValueLabel.Position = UDim2.new(0.9, 0, 0, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Font = config.font
    ValueLabel.Text = tostring(initialValue)
    ValueLabel.TextColor3 = config.textColor
    ValueLabel.TextSize = 14
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = SettingFrame

    -- Slider functionality
    local isDragging = false

    SliderBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true

            -- Update on initial click
            local relativeX = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
            local newValue = min + (max - min) * relativeX
            newValue = math.floor(newValue * 100) / 100 -- Round to 2 decimal places

            SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
            ValueLabel.Text = tostring(newValue)

            if callback then callback(newValue) end
        end
    end)

    SliderBG.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativeX = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
            local newValue = min + (max - min) * relativeX
            newValue = math.floor(newValue * 100) / 100 -- Round to 2 decimal places

            SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
            ValueLabel.Text = tostring(newValue)

            if callback then callback(newValue) end
        end
    end)

    return {
        setValue = function(value)
            local normalizedValue = (value - min) / (max - min)
            SliderFill.Size = UDim2.new(normalizedValue, 0, 1, 0)
            ValueLabel.Text = tostring(value)
        end
    }
end

-- Function to create a button setting
local function createButton(parent, name, text, layoutOrder, callback)
    local Button = Instance.new("TextButton")
    Button.Name = name .. "Button"
    Button.Size = UDim2.new(0.9, 0, 0, 30)
    Button.Position = UDim2.new(0.05, 0, 0, 0)
    Button.BackgroundColor3 = config.accentColor
    Button.BackgroundTransparency = 0.5
    Button.BorderSizePixel = 0
    Button.Font = config.font
    Button.Text = text
    Button.TextColor3 = config.textColor
    Button.TextSize = 14
    Button.LayoutOrder = layoutOrder
    Button.Parent = parent

    -- Button corner rounding
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 4)
    ButtonCorner.Parent = Button

    -- Button hover effect
    Button.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(Button, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.3
        })
        hoverTween:Play()
    end)

    Button.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(Button, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.5
        })
        leaveTween:Play()
    end)

    -- Button click effect
    Button.MouseButton1Click:Connect(function()
        local clickTween = TweenService:Create(Button, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {
            Size = UDim2.new(0.85, 0, 0, 30)
        })
        clickTween:Play()

        clickTween.Completed:Connect(function()
            local revertTween = TweenService:Create(Button, TweenInfo.new(0.1), {
                Size = UDim2.new(0.9, 0, 0, 30)
            })
            revertTween:Play()

            if callback then callback() end
        end)
    end)

    return Button
end

-- Create theme settings section
local themeSection = createSettingsSection("Theme Settings", 1)

-- Background color picker
local backgroundColorPicker = createColorPicker(themeSection, "Background Color", currentTheme.background, 1, function(color)
    currentTheme.background = color
    MainFrame.BackgroundColor3 = color
end)

-- Text color picker
local textColorPicker = createColorPicker(themeSection, "Text Color", currentTheme.text, 2, function(color)
    currentTheme.text = color
    -- Update all text elements
    local function updateTextColor(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                if child.TextColor3 == config.textColor then
                    child.TextColor3 = color
                end
            end
            updateTextColor(child)
        end
    end
    updateTextColor(MainFrame)
    config.textColor = color
end)

-- Accent color picker
local accentColorPicker = createColorPicker(themeSection, "Accent Color", currentTheme.accent, 3, function(color)
    currentTheme.accent = color
    -- Update accent-colored elements
    StatsTabButton.BackgroundColor3 = color
    CheatsTabButton.BackgroundColor3 = color
    SettingsTabButton.BackgroundColor3 = color
    Icon.BackgroundColor3 = color
    UserSymbol.TextColor3 = color
    UsernameLabel.TextColor3 = color
    config.accentColor = color
end)

-- Transparency slider
local transparencySlider = createSlider(themeSection, "Transparency", 0, 1, currentTheme.transparency, 4, function(value)
    currentTheme.transparency = value
    MainFrame.BackgroundTransparency = value
    config.transparency = value
end)

-- Save theme button
createButton(themeSection, "SaveTheme", "Save Theme", 5, function()
    saveTheme()
    -- Show confirmation
    local notification = Instance.new("TextLabel")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0.8, 0, 0, 30)
    notification.Position = UDim2.new(0.1, 0, 0.5, 0)
    notification.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    notification.BackgroundTransparency = 0.5
    notification.Font = config.font
    notification.Text = "Theme saved!"
    notification.TextColor3 = Color3.fromRGB(255, 255, 255)
    notification.TextSize = 14
    notification.ZIndex = 100
    notification.Parent = MainFrame

    -- Notification corner rounding
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 4)
    NotifCorner.Parent = notification

    -- Auto-remove notification
    delay(2, function()
        local fadeTween = TweenService:Create(notification, TweenInfo.new(0.5), {
            BackgroundTransparency = 1,
            TextTransparency = 1
        })
        fadeTween:Play()

        fadeTween.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end)

-- Reset theme button
createButton(themeSection, "ResetTheme", "Reset Theme", 6, function()
    -- Reset to default theme
    currentTheme.background = Color3.fromRGB(47, 49, 54)
    currentTheme.text = Color3.fromRGB(220, 221, 222)
    currentTheme.accent = Color3.fromRGB(114, 137, 218)
    currentTheme.transparency = 0.1

    -- Update UI
    MainFrame.BackgroundColor3 = currentTheme.background
    MainFrame.BackgroundTransparency = currentTheme.transparency

    -- Update color pickers
    backgroundColorPicker.BackgroundColor3 = currentTheme.background
    textColorPicker.BackgroundColor3 = currentTheme.text
    accentColorPicker.BackgroundColor3 = currentTheme.accent

    -- Update transparency slider
    transparencySlider.setValue(currentTheme.transparency)

    -- Update config
    config.backgroundColor = currentTheme.background
    config.textColor = currentTheme.text
    config.accentColor = currentTheme.accent
    config.transparency = currentTheme.transparency

    -- Update all text elements
    local function updateTextColor(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                if child.TextColor3 ~= config.accentColor then
                    child.TextColor3 = config.textColor
                end
            end
            updateTextColor(child)
        end
    end
    updateTextColor(MainFrame)

    -- Update accent-colored elements
    StatsTabButton.BackgroundColor3 = config.accentColor
    CheatsTabButton.BackgroundColor3 = config.accentColor
    SettingsTabButton.BackgroundColor3 = config.accentColor
    Icon.BackgroundColor3 = config.accentColor
    UserSymbol.TextColor3 = config.accentColor
    UsernameLabel.TextColor3 = config.accentColor
end)

-- Create position settings section
local positionSection = createSettingsSection("Position Settings", 2)

-- Save position button
createButton(positionSection, "SavePosition", "Save Position", 1, function()
    savePosition()
    -- Show confirmation
    local notification = Instance.new("TextLabel")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0.8, 0, 0, 30)
    notification.Position = UDim2.new(0.1, 0, 0.5, 0)
    notification.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    notification.BackgroundTransparency = 0.5
    notification.Font = config.font
    notification.Text = "Position saved!"
    notification.TextColor3 = Color3.fromRGB(255, 255, 255)
    notification.TextSize = 14
    notification.ZIndex = 100
    notification.Parent = MainFrame

    -- Notification corner rounding
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 4)
    NotifCorner.Parent = notification

    -- Auto-remove notification
    delay(2, function()
        local fadeTween = TweenService:Create(notification, TweenInfo.new(0.5), {
            BackgroundTransparency = 1,
            TextTransparency = 1
        })
        fadeTween:Play()

        fadeTween.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end)

-- Reset position button
createButton(positionSection, "ResetPosition", "Reset Position", 2, function()
    -- Reset to default position
    local resetTween = TweenService:Create(MainFrame, animationInfo, {
        Position = config.initialPosition,
        Size = config.initialSize
    })
    resetTween:Play()

    -- Update expanded size
    expandedSize = config.initialSize
end)

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
    SettingsContainer.Visible = false
    StatsTabButton.BackgroundTransparency = 0.5
    CheatsTabButton.BackgroundTransparency = 0.8
    SettingsTabButton.BackgroundTransparency = 0.8
end)

CheatsTabButton.MouseButton1Click:Connect(function()
    StatsContainer.Visible = false
    CheatsContainer.Visible = true
    SettingsContainer.Visible = false
    StatsTabButton.BackgroundTransparency = 0.8
    CheatsTabButton.BackgroundTransparency = 0.5
    SettingsTabButton.BackgroundTransparency = 0.8
end)

SettingsTabButton.MouseButton1Click:Connect(function()
    StatsContainer.Visible = false
    CheatsContainer.Visible = false
    SettingsContainer.Visible = true
    StatsTabButton.BackgroundTransparency = 0.8
    CheatsTabButton.BackgroundTransparency = 0.8
    SettingsTabButton.BackgroundTransparency = 0.5
end)

-- Initialize with Stats tab open
StatsContainer.Visible = true
CheatsContainer.Visible = false
SettingsContainer.Visible = false
StatsTabButton.BackgroundTransparency = 0.5
CheatsTabButton.BackgroundTransparency = 0.8
SettingsTabButton.BackgroundTransparency = 0.8
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
    -- Save position before closing
    savePosition()

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

-- Create tooltip function
local function createTooltip(parent, text)
    -- Create tooltip
    local Tooltip = Instance.new("TextLabel")
    Tooltip.Name = "Tooltip"
    Tooltip.Size = UDim2.new(0, 0, 0, 0) -- Start with zero size for animation
    Tooltip.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
    Tooltip.BackgroundTransparency = 0.1
    Tooltip.BorderSizePixel = 0
    Tooltip.Font = config.font
    Tooltip.Text = text
    Tooltip.TextColor3 = config.textColor
    Tooltip.TextSize = 14
    Tooltip.Visible = false
    Tooltip.ZIndex = 100
    Tooltip.Parent = MainFrame

    -- Tooltip corner rounding
    local TooltipCorner = Instance.new("UICorner")
    TooltipCorner.CornerRadius = UDim.new(0, 4)
    TooltipCorner.Parent = Tooltip

    -- Show tooltip on hover
    parent.MouseEnter:Connect(function()
        Tooltip.Position = UDim2.new(0, parent.AbsolutePosition.X - MainFrame.AbsolutePosition.X,
                                     0, parent.AbsolutePosition.Y - MainFrame.AbsolutePosition.Y + 30)
        Tooltip.Size = UDim2.new(0, 0, 0, 24)
        Tooltip.TextTransparency = 1
        Tooltip.Visible = true

        -- Measure text size
        local textSize = game:GetService("TextService"):GetTextSize(
            text,
            Tooltip.TextSize,
            Tooltip.Font,
            Vector2.new(1000, 100)
        )

        -- Animate tooltip
        local showTween = TweenService:Create(Tooltip, TweenInfo.new(0.2), {
            Size = UDim2.new(0, textSize.X + 16, 0, 24),
            TextTransparency = 0
        })
        showTween:Play()
    end)

    -- Hide tooltip when mouse leaves
    parent.MouseLeave:Connect(function()
        local hideTween = TweenService:Create(Tooltip, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 0, 0, 24),
            TextTransparency = 1
        })
        hideTween:Play()

        hideTween.Completed:Connect(function()
            Tooltip.Visible = false
        end)
    end)

    return Tooltip
end

-- Hover effects for buttons
local function applyHoverEffect(button, tooltipText)
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

    -- Add tooltip if text is provided
    if tooltipText then
        createTooltip(button, tooltipText)
    end
end

-- Add tooltips to buttons
applyHoverEffect(PinButton, "Pin window")
applyHoverEffect(MinimizeButton, "Minimize window")
applyHoverEffect(CloseButton, "Close window")
createTooltip(StatsTabButton, "Performance statistics")
createTooltip(CheatsTabButton, "Game modifications")
createTooltip(SettingsTabButton, "Customize appearance")

-- Load saved position and theme
local hasLoadedPosition = loadPosition()
local hasLoadedTheme = loadTheme()

-- Apply loaded theme if available
if hasLoadedTheme then
    -- Update UI with loaded theme
    MainFrame.BackgroundColor3 = currentTheme.background

    -- Update all text elements
    local function updateTextColor(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                if child.TextColor3 == config.textColor then
                    child.TextColor3 = currentTheme.text
                end
            end
            updateTextColor(child)
        end
    end

    -- Update accent-colored elements
    StatsTabButton.BackgroundColor3 = currentTheme.accent
    CheatsTabButton.BackgroundColor3 = currentTheme.accent
    SettingsTabButton.BackgroundColor3 = currentTheme.accent
    Icon.BackgroundColor3 = currentTheme.accent
    UserSymbol.TextColor3 = currentTheme.accent
    UsernameLabel.TextColor3 = currentTheme.accent

    -- Update config
    config.backgroundColor = currentTheme.background
    config.textColor = currentTheme.text
    config.accentColor = currentTheme.accent
    config.transparency = currentTheme.transparency
end

-- Add intro animation when GUI first appears
MainFrame.Size = UDim2.new(0, 0, 0, 0)

-- Set initial position based on saved position or default
local startPosition
local targetPosition
local targetSize

if hasLoadedPosition then
    startPosition = UDim2.new(lastPosition.X.Scale, lastPosition.X.Offset + lastSize.X.Offset/2,
                              lastPosition.Y.Scale, lastPosition.Y.Offset + lastSize.Y.Offset/2)
    targetPosition = lastPosition
    targetSize = lastSize
    expandedSize = lastSize -- Update expanded size
else
    startPosition = UDim2.new(config.initialPosition.X.Scale, config.initialPosition.X.Offset + config.initialSize.X.Offset/2,
                              config.initialPosition.Y.Scale, config.initialPosition.Y.Offset + config.initialSize.Y.Offset/2)
    targetPosition = config.initialPosition
    targetSize = config.initialSize
end

MainFrame.Position = startPosition
MainFrame.BackgroundTransparency = 1

-- Play intro animation
local introSizeTween = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = targetSize,
    Position = targetPosition
})
introSizeTween:Play()

local introFadeTween = TweenService:Create(MainFrame, TweenInfo.new(0.5), {
    BackgroundTransparency = config.transparency
})
introFadeTween:Play()

-- Update pin button if position was loaded with pinned state
if hasLoadedPosition and isPinned then
    PinButton.ImageColor3 = config.accentColor
end

-- Optimized FPS Counter
local lastFpsUpdate = os.clock()
local frameCount = 0
local currentFps = 0

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1

    local currentTime = os.clock()
    local elapsed = currentTime - lastFpsUpdate

    -- Update FPS calculation every 0.5 seconds instead of every frame
    if elapsed >= 0.5 then
        currentFps = math.floor(frameCount / elapsed)
        frameCount = 0
        lastFpsUpdate = currentTime
    end
end)

-- Update stats periodically
spawn(function()
    while wait(config.updateInterval) do
        if not isCollapsed then
            -- Use the pre-calculated FPS value
            FPSValue.Text = currentFps .. " fps"

            -- Set text color based on FPS
            if currentFps > 45 then
                FPSValue.TextColor3 = Color3.fromRGB(87, 242, 135) -- Green
            elseif currentFps > 30 then
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
    end
end)