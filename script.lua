local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local isScriptActive = true

-- Anti AFK Fallback
if getgenv then
	if not getgenv().AntiAFK then
		getgenv().AntiAFK = true
		player.Idled:Connect(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
else
	player.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end

-- ==========================================
-- AFK STATS (Exakt wie in deinem alten Skript)
-- ==========================================
local function SafeGetNumber(val)
	if type(val) == "number" then return val end
	if type(val) == "string" then
		local clean = val:gsub(",", ""):gsub(" ", "")
		local num = tonumber(clean)
		if num then return num end
		local numPart, suffix = clean:match("^([%d%.]+)([KMBkmb]?)$")
		if numPart then
			local n = tonumber(numPart) or 0
			local s = suffix:upper()
			if s == "K" then return n * 1e3
			elseif s == "M" then return n * 1e6
			elseif s == "B" then return n * 1e9
			end
			return n
		end
	end
	return 0
end

local leaderstats = player:WaitForChild("leaderstats", 10)
local winsValueObject = leaderstats and leaderstats:WaitForChild("Wins", 10)
local startWins = winsValueObject and SafeGetNumber(winsValueObject.Value) or 0
local afkStartTime = 0
local sessionTimerConnection = nil
local hiddenGuis = {}
local isAfkMode = false

-- True Blackout Variables
local originalCameraType = workspace.CurrentCamera.CameraType
local originalCameraCFrame = workspace.CurrentCamera.CFrame
local voidPart = nil

local FlySpeed = 16
local SpeedMode = "Semi"
local LoopTour = true
local LoopDelay = 0.7
local AutoRespawn = false
local RespawnDelay = 2.5

local WebhookURL = ""
local WebhookEnabled = false
local DiscordMessageID = nil
local lastWebhookTime = 0
local isInitializingWebhook = false
local currentTotalWins = 0
local currentGainedWins = 0

-- ==========================================
-- 1. ALLE CHECKPOINTS 
-- ==========================================
local Checkpoints = {
    -- Start & Gang
	"-397.47,503.80,0.95",   -- 1
    "-396.96,503.80,57.24",  -- 2
    "-396.94,503.80,133.88", -- 3
	"-397.90,499.87,196.74", -- 4 
    "-397.02,499.87,433.09", -- 5 (Warten auf Welle)
    
    -- Treppe (High Speed 220)
    "-394.69,499.73,474.50", -- 6
    "-355.05,499.73,477.39", -- 7
    "-357.42,526.80,568.32", -- 8 
    "-446.37,527.09,563.81", -- 9
    "-443.14,553.90,478.43", -- 10
    "-354.03,553.26,476.76", -- 11
    "-357.37,580.87,568.33", -- 12
    "-441.78,580.87,566.04", -- 13
    "-441.01,607.83,479.27", -- 14
    "-398.50,607.87,478.47", -- 15
    "-400.26,607.66,609.08", -- 16 (Ende der Treppe)
    
    -- Neuer Parkour 1 
    "-401.13,607.66,618.87", -- 17
    "-401.85,607.66,667.71", -- 18
    "-401.13,607.66,785.36", -- 19
    "-401.68,607.22,827.41", -- 20
    "-401.50,607.22,856.80", -- 21
    
    -- Neuer Parkour 2 
    "-308.54,607.22,997.43", -- 22
    "-398.91,607.64,1247.42", -- 23
    "-401.48,607.22,1276.12", -- 24
    
    -- Neuer Parkour 3 
    "-400.91,607.24,1296.96", 
    "-401.27,618.58,1331.78", 
    "-401.90,607.22,1428.11", 
	"-388.21,607.22,1476.79", 
    "-363.63,628.00,1542.67", 
    "-365.48,628.01,1603.37", 
	"-364.86,605.10,1692.39", 
    "-367.13,605.10,1755.59", 
    "-371.84,616.56,1791.44", 
	"-380.90,607.22,1858.28", 
    "-386.45,607.22,1920.93", 
    "-388.23,618.74,1958.19", 
	"-392.42,607.22,2042.20", 
    "-397.98,607.35,2104.63", 
    "-401.05,607.22,2220.42", 
	"-401.88,607.22,2274.80", 
    "-400.44,618.61,2316.29", 
    "-402.05,623.16,2367.50", 
	"-415.75,623.16,2404.16", 
    "-417.34,626.47,2417.88"
}

-- ==========================================
-- 2. OBJEKTE FÜR DIE AMPELN SUCHEN
-- ==========================================
local echtesTor = nil
local startPosition = nil
local welle = nil

task.spawn(function()
    pcall(function()
        local stage2 = Workspace:WaitForChild("WORLD 2", 10):WaitForChild("Stage2", 10)
        local fakeWand = stage2:FindFirstChild("TransparentWallStage2")
        if fakeWand then fakeWand:Destroy() end

        echtesTor = stage2:WaitForChild("MovingWalls", 10):WaitForChild("MovingWall1", 10)
    end)
    
    while isScriptActive do
        if echtesTor then
            local pfadMitte = Vector3.new(-397.5, echtesTor.Position.Y, echtesTor.Position.Z)
            local aktuellerAbstand = (echtesTor.Position - pfadMitte).Magnitude
            if not startPosition then
                startPosition = echtesTor.Position
            else
                local besterAbstand = (startPosition - pfadMitte).Magnitude
                if aktuellerAbstand > besterAbstand then
                    startPosition = echtesTor.Position
                end
            end
        end
        task.wait(0.2)
    end
end)


local isAutoFlying = false
local isWHeld = false

local function SetWHeld(state)
	if isWHeld == state then return end
	isWHeld = state
	if state then
		if keypress then keypress(0x57)
		else VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game) end
	else
		if keyrelease then keyrelease(0x57)
		else VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game) end
	end
end

RunService.Heartbeat:Connect(function()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and isAutoFlying and isWHeld and hum.Health > 0 then
		hum:Move(camera.CFrame.LookVector, false)
	end
end)

local function UpdateDynamicSpeed()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
	    if SpeedMode == "Legit" then
	        FlySpeed = hum.WalkSpeed
	    elseif SpeedMode == "Semi" then
		    FlySpeed = hum.WalkSpeed + 50
		elseif SpeedMode == "Rage" then
		    FlySpeed = 300
		end
	end
end

local function SetupSpeedListener(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then
		hum:GetPropertyChangedSignal("WalkSpeed"):Connect(UpdateDynamicSpeed)
		UpdateDynamicSpeed()
	end
end

player.CharacterAdded:Connect(SetupSpeedListener)
if player.Character then task.spawn(SetupSpeedListener, player.Character) end

-- ==========================================
-- 3. TRUE BLACKOUT & UI SETUP
-- ==========================================
local function setExtremePerformance(enable)
    local cam = workspace.CurrentCamera
    if not cam then return end
    
    if enable then
        originalCameraType = cam.CameraType
        originalCameraCFrame = cam.CFrame
        
        if not voidPart or not voidPart.Parent then
            voidPart = Instance.new("Part")
            voidPart.Size = Vector3.new(5, 1, 5)
            voidPart.Position = Vector3.new(0, 500000, 0)
            voidPart.Anchored = true
            voidPart.Transparency = 1
            voidPart.CanCollide = false
            voidPart.Parent = workspace
        end
        
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = CFrame.new(voidPart.Position + Vector3.new(0, 5, 0), voidPart.Position)
        
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    else
        cam.CameraType = Enum.CameraType.Custom
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                cam.CameraSubject = hum
            end
        end
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        
        if voidPart then 
            voidPart:Destroy() 
            voidPart = nil
        end
    end
end

local function FormatCompactNumber(number)
	local num = tonumber(number)
	if not num then return "0" end
	if num >= 1e9 then return string.format("%.2fB", num / 1e9)
	elseif num >= 1e6 then return string.format("%.2fM", num / 1e6)
	elseif num >= 1e3 then return string.format("%.2fK", num / 1e3)
	else return tostring(num) end
end

local function FormatTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local gui = Instance.new("ScreenGui")
gui.Name = "ToniUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local PANEL_W = 370
local TITLE_H = 52
local BODY_H = 320
local PADDING = 10

local mainPanel = Instance.new("Frame", gui)
mainPanel.Size = UDim2.new(0, PANEL_W, 0, TITLE_H + BODY_H + 4)
mainPanel.Position = UDim2.new(0.698, 0, 0.098, 0)
mainPanel.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
mainPanel.BorderSizePixel = 0
mainPanel.Active = true
mainPanel.Draggable = true
mainPanel.ZIndex = 2
Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 12)

local titleBar = Instance.new("Frame", mainPanel)
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 3
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -90, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🦴 Auto WIN + AntiAFK"
titleLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 17
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 4

local destroyBtn = Instance.new("TextButton", titleBar)
destroyBtn.Size = UDim2.new(0, 28, 0, 28)
destroyBtn.Position = UDim2.new(1, -38, 0.5, -14)
destroyBtn.BackgroundColor3 = Color3.fromRGB(160, 25, 25)
destroyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
destroyBtn.Font = Enum.Font.GothamBlack
destroyBtn.Text = "❌"
destroyBtn.ZIndex = 10
Instance.new("UICorner", destroyBtn).CornerRadius = UDim.new(0, 6)

local discordBtn = Instance.new("TextButton", titleBar)
discordBtn.Size = UDim2.new(0, 28, 0, 28)
discordBtn.Position = UDim2.new(1, -74, 0.5, -14)
discordBtn.BackgroundColor3 = Color3.fromRGB(114, 137, 218)
discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
discordBtn.Font = Enum.Font.GothamBlack
discordBtn.Text = "W"
discordBtn.ZIndex = 10
Instance.new("UICorner", discordBtn).CornerRadius = UDim.new(0, 6)

local discordPanel = Instance.new("Frame", gui)
discordPanel.Size = UDim2.new(0, 320, 0, 220)
discordPanel.Position = UDim2.new(0.5, -160, 0.5, -110)
discordPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
discordPanel.Visible = false
discordPanel.ZIndex = 50
Instance.new("UICorner", discordPanel).CornerRadius = UDim.new(0, 10)

local discordStroke = Instance.new("UIStroke", discordPanel)
discordStroke.Color = Color3.fromRGB(114, 137, 218)
discordStroke.Thickness = 2

local dcTitle = Instance.new("TextLabel", discordPanel)
dcTitle.Size = UDim2.new(1, 0, 0, 40)
dcTitle.Position = UDim2.new(0, 0, 0, 10)
dcTitle.BackgroundTransparency = 1
dcTitle.Text = "Discord Webhook"
dcTitle.TextColor3 = Color3.fromRGB(114, 137, 218)
dcTitle.Font = Enum.Font.GothamBlack
dcTitle.TextSize = 18
dcTitle.ZIndex = 51

local dcClose = Instance.new("TextButton", discordPanel)
dcClose.Size = UDim2.new(0, 25, 0, 25)
dcClose.Position = UDim2.new(1, -35, 0, 15)
dcClose.BackgroundColor3 = Color3.fromRGB(160, 25, 25)
dcClose.TextColor3 = Color3.fromRGB(255, 255, 255)
dcClose.Text = "X"
dcClose.Font = Enum.Font.GothamBold
dcClose.ZIndex = 51
Instance.new("UICorner", dcClose).CornerRadius = UDim.new(0, 6)
dcClose.MouseButton1Click:Connect(function() discordPanel.Visible = false end)

discordBtn.MouseButton1Click:Connect(function() discordPanel.Visible = not discordPanel.Visible end)

local dcInput = Instance.new("TextBox", discordPanel)
dcInput.Size = UDim2.new(1, -40, 0, 35)
dcInput.Position = UDim2.new(0, 20, 0, 60)
dcInput.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
dcInput.TextColor3 = Color3.fromRGB(220, 220, 220)
dcInput.PlaceholderText = "Paste Webhook URL here..."
dcInput.Text = ""
dcInput.Font = Enum.Font.Gotham
dcInput.TextSize = 13
dcInput.ClearTextOnFocus = false
dcInput.TextXAlignment = Enum.TextXAlignment.Left
dcInput.ZIndex = 51
Instance.new("UICorner", dcInput).CornerRadius = UDim.new(0, 6)
dcInput.FocusLost:Connect(function() WebhookURL = dcInput.Text end)

local dcToggleBtn = Instance.new("TextButton", discordPanel)
dcToggleBtn.Size = UDim2.new(1, -40, 0, 35)
dcToggleBtn.Position = UDim2.new(0, 20, 0, 105)
dcToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
dcToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
dcToggleBtn.Text = "Status: Disabled"
dcToggleBtn.Font = Enum.Font.GothamBold
dcToggleBtn.TextSize = 14
dcToggleBtn.ZIndex = 51
Instance.new("UICorner", dcToggleBtn).CornerRadius = UDim.new(0, 6)
dcToggleBtn.MouseButton1Click:Connect(function()
    WebhookEnabled = not WebhookEnabled
    if WebhookEnabled then
        dcToggleBtn.Text = "Status: Enabled"
        dcToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 130)
        dcToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        dcToggleBtn.Text = "Status: Disabled"
        dcToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        dcToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

local dcTestBtn = Instance.new("TextButton", discordPanel)
dcTestBtn.Size = UDim2.new(1, -40, 0, 35)
dcTestBtn.Position = UDim2.new(0, 20, 0, 150)
dcTestBtn.BackgroundColor3 = Color3.fromRGB(114, 137, 218)
dcTestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dcTestBtn.Text = "Test Webhook"
dcTestBtn.Font = Enum.Font.GothamBold
dcTestBtn.TextSize = 14
dcTestBtn.ZIndex = 51
Instance.new("UICorner", dcTestBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UICorner", destroyBtn).CornerRadius = UDim.new(0, 6)

local bodyFrame = Instance.new("Frame", mainPanel)
bodyFrame.Size = UDim2.new(1, 0, 0, BODY_H)
bodyFrame.Position = UDim2.new(0, 0, 0, TITLE_H + 4)
bodyFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 24)
bodyFrame.BorderSizePixel = 0
bodyFrame.ZIndex = 3
Instance.new("UICorner", bodyFrame).CornerRadius = UDim.new(0, 12)

local statusLabel = Instance.new("TextLabel", bodyFrame)
statusLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
statusLabel.Position = UDim2.new(0, 0, 0, PADDING)
statusLabel.Size = UDim2.new(1, 0, 0, 44)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Text = "Bereit für den Durchlauf!"
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
statusLabel.TextSize = 15
statusLabel.ZIndex = 4
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)

local btn = Instance.new("TextButton", bodyFrame)
btn.Size = UDim2.new(1, -20, 0, 45)
btn.Position = UDim2.new(0, 10, 0, 64)
btn.BackgroundColor3 = Color3.fromRGB(0, 170, 130)
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBlack
btn.TextSize = 18
btn.Text = "▶  Start Tour"
btn.ZIndex = 4
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

local afkBtn = Instance.new("TextButton", bodyFrame)
afkBtn.Size = UDim2.new(1, -20, 0, 45)
afkBtn.Position = UDim2.new(0, 10, 0, 119)
afkBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 65)
afkBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
afkBtn.Font = Enum.Font.GothamBlack
afkBtn.TextSize = 15
afkBtn.Text = "🌙  Enable True Blackout (L)"
afkBtn.ZIndex = 4
Instance.new("UICorner", afkBtn).CornerRadius = UDim.new(0, 10)

local modeBtn = Instance.new("TextButton", bodyFrame)
modeBtn.Size = UDim2.new(1, -20, 0, 45)
modeBtn.Position = UDim2.new(0, 10, 0, 174)
modeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 80)
modeBtn.TextColor3 = Color3.fromRGB(200, 150, 255)
modeBtn.Font = Enum.Font.GothamBlack
modeBtn.TextSize = 15
modeBtn.Text = "⚡  Speed Mode: Semi"
modeBtn.ZIndex = 4
Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 10)

local sliderFrame = Instance.new("Frame", bodyFrame)
sliderFrame.Size = UDim2.new(1, -20, 0, 50)
sliderFrame.Position = UDim2.new(0, 10, 0, 229)
sliderFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
sliderFrame.ZIndex = 4
Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 8)

local sliderTitle = Instance.new("TextLabel", sliderFrame)
sliderTitle.Size = UDim2.new(1, -20, 0, 20)
sliderTitle.Position = UDim2.new(0, 10, 0, 5)
sliderTitle.BackgroundTransparency = 1
sliderTitle.Text = "Loop Delay: " .. LoopDelay .. "s"
sliderTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
sliderTitle.Font = Enum.Font.GothamBold
sliderTitle.TextSize = 13
sliderTitle.TextXAlignment = Enum.TextXAlignment.Left
sliderTitle.ZIndex = 5

local sliderBg = Instance.new("TextButton", sliderFrame)
sliderBg.Size = UDim2.new(1, -20, 0, 8)
sliderBg.Position = UDim2.new(0, 10, 0, 32)
sliderBg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
sliderBg.Text = ""
sliderBg.AutoButtonColor = false
sliderBg.ZIndex = 5
Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

local sliderFill = Instance.new("Frame", sliderBg)
sliderFill.Size = UDim2.new(math.clamp(LoopDelay / 5, 0, 1), 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
sliderFill.ZIndex = 6
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

local isDraggingSlider = false
sliderBg.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then isDraggingSlider = true end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then isDraggingSlider = false end
end)
UserInputService.InputChanged:Connect(function(input)
	if isDraggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
		local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
		sliderFill.Size = UDim2.new(pos, 0, 1, 0)
		LoopDelay = math.floor(pos * 50) / 10
		sliderTitle.Text = "Loop Delay: " .. tostring(LoopDelay) .. "s"
	end
end)

-- ==========================================
-- AFK SCREEN SETUP (Im Main GUI wie in deinem alten Skript)
-- ==========================================
local uiAddedConnection = nil

local afkOverlay = Instance.new("Frame", gui)
afkOverlay.Size = UDim2.new(1, 0, 1, 0)
afkOverlay.Position = UDim2.new(0, 0, 0, 0)
afkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- TRUE BLACKOUT
afkOverlay.BackgroundTransparency = 0.6
afkOverlay.BorderSizePixel = 0
afkOverlay.Active = true
afkOverlay.Visible = false
afkOverlay.ZIndex = 500

local afkIndicator = Instance.new("Frame", afkOverlay)
afkIndicator.Size = UDim2.new(0, 360, 0, 275)
afkIndicator.Position = UDim2.new(0.5, -180, 0.5, -137)
afkIndicator.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
afkIndicator.BorderSizePixel = 0
afkIndicator.ZIndex = 501
Instance.new("UICorner", afkIndicator).CornerRadius = UDim.new(0, 12)

local indStroke = Instance.new("UIStroke", afkIndicator)
indStroke.Color = Color3.fromRGB(0, 255, 200)
indStroke.Transparency = 0.5
indStroke.Thickness = 2

local afkTitle = Instance.new("TextLabel", afkIndicator)
afkTitle.Size = UDim2.new(1, 0, 0, 50)
afkTitle.Position = UDim2.new(0, 0, 0, 5)
afkTitle.BackgroundTransparency = 1
afkTitle.Text = "🌙  TRUE BLACKOUT"
afkTitle.TextColor3 = Color3.fromRGB(0, 255, 200)
afkTitle.Font = Enum.Font.GothamBlack
afkTitle.TextSize = 24
afkTitle.ZIndex = 502

local timeValueLabel = Instance.new("TextLabel", afkIndicator)
timeValueLabel.Size = UDim2.new(1, 0, 0, 25)
timeValueLabel.Position = UDim2.new(0, 0, 0, 60)
timeValueLabel.BackgroundTransparency = 1
timeValueLabel.Text = "Past Time: 00:00:00"
timeValueLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
timeValueLabel.Font = Enum.Font.GothamBold
timeValueLabel.TextSize = 16
timeValueLabel.ZIndex = 502

local currentWinsLabel = Instance.new("TextLabel", afkIndicator)
currentWinsLabel.Size = UDim2.new(1, 0, 0, 25)
currentWinsLabel.Position = UDim2.new(0, 0, 0, 90)
currentWinsLabel.BackgroundTransparency = 1
currentWinsLabel.Text = "Current Wins: 0"
currentWinsLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
currentWinsLabel.Font = Enum.Font.GothamBold
currentWinsLabel.TextSize = 16
currentWinsLabel.ZIndex = 502

local gainedWinsLabel = Instance.new("TextLabel", afkIndicator)
gainedWinsLabel.Size = UDim2.new(1, 0, 0, 25)
gainedWinsLabel.Position = UDim2.new(0, 0, 0, 120)
gainedWinsLabel.BackgroundTransparency = 1
gainedWinsLabel.Text = "Gained Wins: +0"
gainedWinsLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
gainedWinsLabel.Font = Enum.Font.GothamBlack
gainedWinsLabel.TextSize = 16
gainedWinsLabel.ZIndex = 502

local modeBtnAfk = Instance.new("TextButton", afkIndicator)
modeBtnAfk.Size = UDim2.new(0, 200, 0, 38)
modeBtnAfk.Position = UDim2.new(0.5, -100, 1, -105)
modeBtnAfk.BackgroundColor3 = Color3.fromRGB(60, 30, 80)
modeBtnAfk.TextColor3 = Color3.fromRGB(200, 150, 255)
modeBtnAfk.Font = Enum.Font.GothamBlack
modeBtnAfk.TextSize = 14
modeBtnAfk.Text = "Speed Mode: Semi"
modeBtnAfk.ZIndex = 502
Instance.new("UICorner", modeBtnAfk).CornerRadius = UDim.new(0, 8)

local exitAfkBtn = Instance.new("TextButton", afkIndicator)
exitAfkBtn.Size = UDim2.new(0, 200, 0, 42)
exitAfkBtn.Position = UDim2.new(0.5, -100, 1, -55)
exitAfkBtn.BackgroundColor3 = Color3.fromRGB(170, 35, 35)
exitAfkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
exitAfkBtn.Font = Enum.Font.GothamBlack
exitAfkBtn.TextSize = 14
exitAfkBtn.Text = "RESTORE UI (L)"
exitAfkBtn.ZIndex = 502
Instance.new("UICorner", exitAfkBtn).CornerRadius = UDim.new(0, 8)

local function SetExternalUiVisible(visible)
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, visible) end)
	local playerGui = player:FindFirstChild("PlayerGui")
	if playerGui then
		if not visible then
			for _, child in ipairs(playerGui:GetChildren()) do
				if child:IsA("ScreenGui") and child.Name ~= "ToniUI" and child.Enabled == true then
					child.Enabled = false
					table.insert(hiddenGuis, child)
				end
			end
			if not uiAddedConnection then
				uiAddedConnection = playerGui.ChildAdded:Connect(function(child)
					if child:IsA("ScreenGui") and child.Name ~= "ToniUI" then
						task.wait()
						if child.Enabled then
							child.Enabled = false
							table.insert(hiddenGuis, child)
						end
					end
				end)
			end
		else
			if uiAddedConnection then
				uiAddedConnection:Disconnect()
				uiAddedConnection = nil
			end
			for _, child in ipairs(hiddenGuis) do
				if child and child.Parent then child.Enabled = true end
			end
			table.clear(hiddenGuis)
		end
	end
end

-- ==========================================
-- ==========================================
-- DISCORD WEBHOOK LOGIK
-- ==========================================
local HttpService = game:GetService("HttpService")
local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local function GetEmbedData(elapsed, current, gained)
    return {
        username = "Auto-Farm Stats",
        avatar_url = "https://i.imgur.com/AffbTAr.png",
        embeds = {{
            title = "🌙 True Blackout Session",
            color = 65450,
            fields = {
                {name = "⏱️ Time Elapsed", value = FormatTime(elapsed), inline = true},
                {name = "🏆 Current Wins", value = FormatCompactNumber(current), inline = true},
                {name = "📈 Session Gained", value = "+" .. FormatCompactNumber(gained), inline = true}
            },
            footer = {text = "Live Updates • Every 60s"},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
end

local function InitDiscordMessage(elapsed, current, gained)
    if not req then return nil, "No REQ Function" end
    if WebhookURL == "" then return nil, "Empty URL" end
    
    local proxyUrl = WebhookURL:gsub("discord.com", "webhook.lewisakura.moe"):gsub("discordapp.com", "webhook.lewisakura.moe")
    if not string.find(proxyUrl, "?") then
        proxyUrl = proxyUrl .. "?wait=true"
    else
        proxyUrl = proxyUrl .. "&wait=true"
    end
    
    local success, response = pcall(function()
        return req({
            Url = proxyUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(GetEmbedData(elapsed, current, gained))
        })
    end)
    
    if not success then return nil, "PCall Error" end
    if type(response) ~= "table" then return nil, "No Response Table" end
    
    local code = response.StatusCode or response.Status or response.code or 0
    if code == 200 or code == 204 then
        if response.Body and response.Body ~= "" then
            local s, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
            if s and data and data.id then
                return data.id, "OK"
            end
        end
        return "SUCCESS_NO_ID", "OK_NO_ID"
    end
    
    local errMsg = response.StatusMessage or response.Error or ("HTTP " .. tostring(code))
    return nil, errMsg
end

local function UpdateDiscordMessage(msgId, elapsed, current, gained)
    if not req or WebhookURL == "" or not msgId or msgId == "SUCCESS_NO_ID" then return end
    local proxyUrl = WebhookURL:gsub("discord.com", "webhook.lewisakura.moe"):gsub("discordapp.com", "webhook.lewisakura.moe")
    
    pcall(function()
        req({
            Url = proxyUrl .. "/messages/" .. msgId,
            Method = "PATCH",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(GetEmbedData(elapsed, current, gained))
        })
    end)
end

dcTestBtn.MouseButton1Click:Connect(function()
    if WebhookURL ~= "" then
        dcTestBtn.Text = "Sending..."
        task.spawn(function()
            local id, err = InitDiscordMessage(0, currentTotalWins, currentGainedWins)
            if id then
                dcTestBtn.Text = "Success!"
            else
                local shortErr = string.sub(tostring(err), 1, 15)
                dcTestBtn.Text = "Err: " .. shortErr
            end
            task.wait(4)
            dcTestBtn.Text = "Test Webhook"
        end)
    end
end)

-- ==========================================
-- UPDATE LOGIK
-- ==========================================
local function UpdateAFKStats()
	pcall(function()
		if winsValueObject and winsValueObject.Parent then
			local totalRaw = winsValueObject.Value
			local total = SafeGetNumber(totalRaw)
			local gained = total - startWins
			currentTotalWins = total
			currentGainedWins = gained
			currentWinsLabel.Text = "Current Wins: " .. FormatCompactNumber(total)
			gainedWinsLabel.Text = "Gained Wins: +" .. FormatCompactNumber(gained)
		else
			currentWinsLabel.Text = "Current Wins: N/A"
			gainedWinsLabel.Text = "Gained Wins: +0"
		end
	end)
end

local function ToggleAfkMode()
    isAfkMode = not isAfkMode
    
    local success, err = pcall(function()
        if isAfkMode then
            mainPanel.Visible = false
            afkOverlay.Visible = true
            afkStartTime = os.time()
            
            pcall(function() setExtremePerformance(true) end)
            pcall(function() collectgarbage("collect") end)
            
            pcall(function() SetExternalUiVisible(false) end)
            
            if winsValueObject and winsValueObject.Parent then 
                startWins = SafeGetNumber(winsValueObject.Value) 
            end
            
            UpdateAFKStats()
            pcall(function() UpdateDynamicSpeed() end)
            
            if setfpscap then pcall(function() setfpscap(15) end) end
            
            if sessionTimerConnection then sessionTimerConnection:Disconnect() end
            
            DiscordMessageID = nil
            isInitializingWebhook = false
            lastWebhookTime = os.time()
            
            sessionTimerConnection = RunService.Heartbeat:Connect(function()
                local elapsed = os.time() - afkStartTime
                timeValueLabel.Text = "Past Time: " .. FormatTime(elapsed)
                UpdateAFKStats()
                
                local cam = workspace.CurrentCamera
                if cam and voidPart and cam.CameraType ~= Enum.CameraType.Scriptable then
                    cam.CameraType = Enum.CameraType.Scriptable
                    cam.CFrame = CFrame.new(voidPart.Position + Vector3.new(0, 5, 0), voidPart.Position)
                end
                
                if WebhookEnabled and WebhookURL ~= "" then
                    if not DiscordMessageID then
                        if not isInitializingWebhook then
                            isInitializingWebhook = true
                            task.spawn(function()
                                DiscordMessageID = InitDiscordMessage(elapsed, currentTotalWins, currentGainedWins)
                                lastWebhookTime = os.time()
                            end)
                        end
                    elseif (os.time() - lastWebhookTime) >= 60 then
                        lastWebhookTime = os.time()
                        task.spawn(function()
                            UpdateDiscordMessage(DiscordMessageID, elapsed, currentTotalWins, currentGainedWins)
                        end)
                    end
                end
            end)
        else
            if sessionTimerConnection then
                sessionTimerConnection:Disconnect()
                sessionTimerConnection = nil
            end
            
            pcall(function() setExtremePerformance(false) end)
            if setfpscap then pcall(function() setfpscap(60) end) end
            pcall(function() SetExternalUiVisible(true) end)
            
            afkOverlay.Visible = false
            mainPanel.Visible = true
        end
    end)
    
    if not success then
        warn("AFK MODE ERROR:", tostring(err))
    end
end

afkBtn.MouseButton1Click:Connect(function() ToggleAfkMode() end)
exitAfkBtn.MouseButton1Click:Connect(function() ToggleAfkMode() end)

local function ToggleMode()
    if SpeedMode == "Legit" then
        SpeedMode = "Semi"
    elseif SpeedMode == "Semi" then
        SpeedMode = "Rage"
    else
        SpeedMode = "Legit"
    end
    modeBtn.Text = "⚡  Speed Mode: " .. SpeedMode
    modeBtnAfk.Text = "Speed Mode: " .. SpeedMode
    UpdateDynamicSpeed()
end

modeBtn.MouseButton1Click:Connect(ToggleMode)
modeBtnAfk.MouseButton1Click:Connect(ToggleMode)

-- Anti-Kick Simulator (Drückt Pfeiltaste Hoch alle 60 Sek)
task.spawn(function()
    while isScriptActive do
        task.wait(60)
        if isAfkMode then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Up, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Up, false, game)
            end)
        end
    end
end)


-- ==========================================
-- 4. DIE NEUE KUGELSICHERE FLUG-LOGIK
-- ==========================================
local function StopAutoFly()
	isAutoFlying = false
	SetWHeld(false)
	local char = player.Character
	local rootPart = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if rootPart then pcall(function() rootPart.Anchored = false; rootPart.Velocity = Vector3.zero end) end
	if humanoid then pcall(function() humanoid.PlatformStand = false end) end
	btn.Text = "▶  Start Tour"
	btn.BackgroundColor3 = Color3.fromRGB(0, 170, 130)
	statusLabel.Text = "Bereit."
end

local function StartAutoFly()
	if isAutoFlying then StopAutoFly(); return end
	if #Checkpoints < 1 then return end
	isAutoFlying = true
	btn.Text = "⏸  Stop Tour"
	btn.BackgroundColor3 = Color3.fromRGB(180, 35, 35)

	task.spawn(function()
		while isAutoFlying and isScriptActive do
			local char = player.Character
			if not char or not char.Parent or not char:FindFirstChild("Humanoid") or not char:FindFirstChild("HumanoidRootPart") or char.Humanoid.Health <= 0 then
			    statusLabel.Text = "⏳ Warte auf vollständigen Respawn..."
			    char = player.CharacterAdded:Wait()
			    task.wait(0.5)
			end
			
			local rootPart = char:WaitForChild("HumanoidRootPart", 10)
			local humanoid = char:WaitForChild("Humanoid", 10)
			if not rootPart or not humanoid then task.wait(0.5); continue end
			
			-- 🚀 NEU: 1/8 Sekunde (0.125s) extra Ladezeit, damit der Roblox-Teleport 100% klappt!
			task.wait(0.125)
			
			-- BUG-SCHUTZ
			local spawnPos = Vector3.new(-397.51, 506.24, -176.57) 
			local distZumSpawn = (rootPart.Position - spawnPos).Magnitude
			
			-- 🚀 NEU: 5x größerer Radius (250 Studs Toleranz!)
			if distZumSpawn > 250 then
			    statusLabel.Text = "⚠️ Teleport-Bug erkannt! Erzwinge Respawn..."
			    if humanoid then humanoid.Health = 0 end 
			    task.wait(2)
			    continue
			end
			
			local totalCPs = #Checkpoints
			local breakDueToDeath = false

			for i = 1, totalCPs do
				if not isAutoFlying or not isScriptActive then break end
				
				if humanoid.Health <= 0 or not rootPart.Parent then 
				    breakDueToDeath = true
				    break 
				end

				if i <= totalCPs - 2 then SetWHeld(true) else SetWHeld(false) end

				local posData = string.split(Checkpoints[i], ",")
				local targetPos = Vector3.new(tonumber(posData[1]), tonumber(posData[2]), tonumber(posData[3]))
				local dist = (rootPart.Position - targetPos).Magnitude
				
				local isCorridor = (i == 5)
				local isStairsStart = (i == 6) 
				local isOnStairs = (i >= 6 and i <= 16)
				
				-- =======================================
				-- AMPEL 1: GANG-TÜR
				-- =======================================
				if isCorridor then
				    pcall(function()
				        local fw = Workspace["WORLD 2"].Stage2:FindFirstChild("TransparentWallStage2")
				        if fw then fw:Destroy() end
				    end)

				    statusLabel.Text = "⏳ Warte auf offenes Tor..."
				    while isAutoFlying and isScriptActive and humanoid.Health > 0 do
				        if echtesTor and startPosition then
				            local abstand = (echtesTor.Position - startPosition).Magnitude
				            if abstand <= 2 then break end
				        else
				            break 
				        end
				        task.wait(0.01)
				    end
				    if humanoid.Health > 0 then statusLabel.Text = "🚀 Tor offen! (Speed 135)" end
				    
				-- =======================================
				-- AMPEL 2: TREPPEN-WELLE MIT "ABBRUCH-GEHIRN"
				-- =======================================
				elseif isStairsStart then
				    statusLabel.Text = "⏳ Analysiere Welle..."
				    
				    if not welle or not welle.Parent then
				        pcall(function() welle = Workspace["Pieges & Lava"].Lava_Stage3.LavaPart end)
				    end
				    
				    local waveSafe = false
				    
				    if welle then
				        local y1 = welle.Position.Y
				        task.wait(0.2) 
				        local y2 = welle.Position.Y
				        
				        if y2 < 360 then
				            waveSafe = true
				        elseif (y2 - y1) > 1 then
				            waveSafe = false
				        else
				            statusLabel.Text = "🔴 Welle fällt... Warte..."
				            local letzteY = y2
				            
				            while isAutoFlying and isScriptActive and humanoid.Health > 0 do
				                local aktuelleY = welle.Position.Y
				                
				                if aktuelleY < 350 then
				                    waveSafe = true
				                    break
				                elseif (aktuelleY - letzteY) > 2 then
				                    waveSafe = false
				                    break
				                end
				                
				                letzteY = aktuelleY
				                task.wait(0.05) 
				            end
				        end
				    else
				        statusLabel.Text = "⚠️ Welle nicht gefunden! Überspringe..."
				        task.wait(1)
				        waveSafe = true
				    end
				    
				    if waveSafe then
				        if humanoid.Health > 0 then statusLabel.Text = "🌊 Welle sicher! Vollgas!" end
				    else
				        statusLabel.Text = "⚠️ Welle zu hoch! Abbruch zum Safe-Spot!"
				        
				        local altTarget = Vector3.new(-413.42, 502.67, 433.61)
				        local altDist = (rootPart.Position - altTarget).Magnitude
				        UpdateDynamicSpeed()
				        local altSpeed = math.clamp(FlySpeed, 10, 500)
				        local timeToReachAlt = altDist / altSpeed

				        humanoid.PlatformStand = true
				        rootPart.Anchored = false
				        
				        local bvAlt = Instance.new("BodyVelocity")
				        bvAlt.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				        bvAlt.Parent = rootPart
				        local bgAlt = Instance.new("BodyGyro")
				        bgAlt.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
				        bgAlt.P = 10000
				        bgAlt.Parent = rootPart
				        
				        local tAlt = 0
				        while isAutoFlying and isScriptActive and tAlt < (timeToReachAlt + 2) and (rootPart.Position - altTarget).Magnitude > 5 do
				            if humanoid.Health <= 0 or not rootPart.Parent then
				                breakDueToDeath = true
				                break
				            end
				            local dtAlt = task.wait()
				            tAlt = tAlt + dtAlt
				            
				            UpdateDynamicSpeed()
				            altSpeed = math.clamp(FlySpeed, 10, 500)
				            local dirAlt = (altTarget - rootPart.Position)
				            if dirAlt.Magnitude > 0 then
				                bvAlt.Velocity = dirAlt.Unit * altSpeed
				                bgAlt.CFrame = CFrame.new(rootPart.Position, altTarget)
				            end
				        end
				        
				        if bvAlt then pcall(function() bvAlt:Destroy() end) end
				        if bgAlt then pcall(function() bgAlt:Destroy() end) end
				        if rootPart and rootPart.Parent then 
				            pcall(function() rootPart.Velocity = Vector3.zero; rootPart.RotVelocity = Vector3.zero end) 
				        end
				        
				        break 
				    end
				    
				else
				    statusLabel.Text = "✈️ Fliege zu Checkpoint " .. i
				end
				
				if humanoid.Health <= 0 or breakDueToDeath then breakDueToDeath = true; break end
				
				-- =======================================
				-- SPEED VERGABE 
				-- =======================================
				local activeSpeed = math.clamp(FlySpeed, 10, 500)
				
				if isCorridor then 
				    activeSpeed = 135 
				elseif isOnStairs then 
				    if SpeedMode == "Legit" then
				        UpdateDynamicSpeed()
				        activeSpeed = math.clamp(FlySpeed, 10, 500)
				    else
				        activeSpeed = 220 
				    end
				else
				    UpdateDynamicSpeed()
				    activeSpeed = math.clamp(FlySpeed, 10, 500)
				end
				
				local timeToReach = dist / activeSpeed

				humanoid.PlatformStand = true
				rootPart.Anchored = false
				
				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				bv.Parent = rootPart
				local bg = Instance.new("BodyGyro")
				bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
				bg.P = 10000
				bg.Parent = rootPart
				
				local t = 0
				
				while isAutoFlying and isScriptActive and t < (timeToReach + 2) and (rootPart.Position - targetPos).Magnitude > 5 do
				    if humanoid.Health <= 0 or not rootPart.Parent then
				        breakDueToDeath = true
				        break
				    end
				    
					local dt = task.wait()
					t = t + dt
					
					if isCorridor then
					    activeSpeed = 135
					elseif isOnStairs then
					    if SpeedMode == "Legit" then
					        UpdateDynamicSpeed()
					        activeSpeed = math.clamp(FlySpeed, 10, 500)
					    else
					        activeSpeed = 220
					    end
					else
					    UpdateDynamicSpeed()
					    activeSpeed = math.clamp(FlySpeed, 10, 500)
					end
					
					local dir = (targetPos - rootPart.Position)
					if dir.Magnitude > 0 then
						bv.Velocity = dir.Unit * activeSpeed
						bg.CFrame = CFrame.new(rootPart.Position, targetPos)
					end
				end
				
				if bv then pcall(function() bv:Destroy() end) end
				if bg then pcall(function() bg:Destroy() end) end
				if rootPart and rootPart.Parent then 
				    pcall(function() rootPart.Velocity = Vector3.zero; rootPart.RotVelocity = Vector3.zero end) 
				end
				
				if breakDueToDeath then break end
			end

			if breakDueToDeath or (humanoid and humanoid.Health <= 0) then
			    SetWHeld(false)
			    task.wait(1)
			    continue
			end

			if not isAutoFlying or not isScriptActive then break end
			if humanoid then pcall(function() humanoid.PlatformStand = false end) end
			if rootPart then pcall(function() rootPart.Anchored = false end) end
			SetWHeld(false)

			task.wait(0.1) 
			if humanoid and humanoid.Health > 0 then
				pcall(function() humanoid.Jump = true; humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
			end
			
			if keypress then
				keypress(0x20)
				task.wait(0.05)
				keyrelease(0x20)
			else
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
				task.wait(0.05)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
			end

			if not isAutoFlying or not isScriptActive then break end
			if AutoRespawn then
				local rTimer = 0
				while isAutoFlying and isScriptActive and rTimer < RespawnDelay do
					rTimer = rTimer + task.wait()
				end
				if not isAutoFlying or not isScriptActive then break end
				if humanoid then humanoid.Health = 0 end
			end

			if not isAutoFlying or not isScriptActive then break end
			if LoopTour then
				if LoopDelay > 0 then task.wait(LoopDelay) end
			else
				break
			end
		end
		if isScriptActive then
			StopAutoFly()
		end
	end)
end

btn.MouseButton1Click:Connect(function()
	StartAutoFly()
end)

destroyBtn.MouseButton1Click:Connect(function()
	isScriptActive = false
	isAutoFlying = false
	if isAfkMode then setExtremePerformance(false) end
	SetWHeld(false)
	local char = player.Character
	local rootPart = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChild("Humanoid")
	if rootPart then pcall(function() rootPart.Anchored = false; rootPart.Velocity = Vector3.zero end) end
	if humanoid then pcall(function() humanoid.PlatformStand = false end) end
	gui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.K and not isAfkMode then
		mainPanel.Visible = not mainPanel.Visible
	end
	if input.KeyCode == Enum.KeyCode.L then
	    ToggleAfkMode()
	end
end)
