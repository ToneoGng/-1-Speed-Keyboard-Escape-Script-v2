local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local leaderstats = player:WaitForChild("leaderstats", 10)
local winsValueObject = leaderstats and leaderstats:WaitForChild("Wins", 10)
local startWins = winsValueObject and winsValueObject.Value or 0
local afkStartTime = 0
local sessionTimerConnection = nil
local hiddenGuis = {}

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

local FlySpeed = 125
local LoopTour = true
local LoopDelay = 0.65
local AutoRespawn = false
local RespawnDelay = 2.5
local CPEndAction = "Jump"

local Checkpoints = {
	"-395.64,504.70,-26.95", "-395.92,503.80,-0.96", "-397.33,509.51,13.61",
	"-398.18,511.03,27.23", "-399.94,508.31,42.49", "-401.95,503.75,58.01",
	"-403.67,510.16,79.68", "-404.58,510.91,93.48", "-405.64,507.73,109.64",
	"-406.67,503.76,125.43", "-407.96,510.60,140.38", "-408.72,510.42,151.98",
	"-409.95,505.64,166.91", "-412.31,499.77,181.48", "-413.38,502.67,191.36",
}

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
	if hum and isAutoFlying and isWHeld then
		hum:Move(camera.CFrame.LookVector, false)
	end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "ToniUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local PANEL_W = 370
local TITLE_H = 52
local STATUS_H = 44
local CREDITS_H = 30
local BTN_H = 45
local PADDING = 10
local BODY_H = PADDING + STATUS_H + PADDING + CREDITS_H + PADDING + BTN_H + PADDING + BTN_H + PADDING

local mainPanel = Instance.new("Frame", gui)
mainPanel.Size = UDim2.new(0, PANEL_W, 0, TITLE_H + BODY_H + 4)
mainPanel.Position = UDim2.new(0.698, 0, 0.098, 0)
mainPanel.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.Active = true
mainPanel.Draggable = true
mainPanel.ZIndex = 2
Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 12)

local titleBar = Instance.new("Frame", mainPanel)
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 3
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "✦  Auto WIN + AntiAFK"
titleLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 17
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 4

local titleAccent = Instance.new("Frame", titleBar)
titleAccent.Size = UDim2.new(1, 0, 0, 2)
titleAccent.Position = UDim2.new(0, 0, 1, -2)
titleAccent.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
titleAccent.BorderSizePixel = 0
titleAccent.ZIndex = 4

local destroyBtn = Instance.new("TextButton", titleBar)
destroyBtn.Size = UDim2.new(0, 28, 0, 28)
destroyBtn.Position = UDim2.new(1, -38, 0.5, -14)
destroyBtn.BackgroundColor3 = Color3.fromRGB(160, 25, 25)
destroyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
destroyBtn.Font = Enum.Font.GothamBlack
destroyBtn.TextSize = 16
destroyBtn.Text = "✕"
destroyBtn.ZIndex = 10
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
statusLabel.Size = UDim2.new(1, 0, 0, STATUS_H)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Text = "⬡  Status: Active"
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
statusLabel.TextSize = 17
statusLabel.ZIndex = 4
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)

local creditsLabel = Instance.new("TextLabel", bodyFrame)
creditsLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
creditsLabel.Position = UDim2.new(0, 0, 0, PADDING + STATUS_H + PADDING)
creditsLabel.Size = UDim2.new(1, 0, 0, CREDITS_H)
creditsLabel.Font = Enum.Font.GothamBlack
creditsLabel.Text = "Made by Toni den Alpha"
creditsLabel.TextSize = 18
creditsLabel.ZIndex = 4
Instance.new("UICorner", creditsLabel).CornerRadius = UDim.new(0, 6)

local btn = Instance.new("TextButton", bodyFrame)
btn.Size = UDim2.new(1, -20, 0, BTN_H)
btn.Position = UDim2.new(0, 10, 0, PADDING + STATUS_H + PADDING + CREDITS_H + PADDING)
btn.BackgroundColor3 = Color3.fromRGB(0, 170, 130)
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBlack
btn.TextSize = 18
btn.Text = "▶  Start Tour"
btn.ZIndex = 4
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

local afkBtn = Instance.new("TextButton", bodyFrame)
afkBtn.Size = UDim2.new(1, -20, 0, BTN_H)
afkBtn.Position = UDim2.new(0, 10, 0, PADDING + STATUS_H + PADDING + CREDITS_H + PADDING + BTN_H + PADDING)
afkBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 65)
afkBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
afkBtn.Font = Enum.Font.GothamBlack
afkBtn.TextSize = 16
afkBtn.Text = "🌙  Enable AFK Screen"
afkBtn.ZIndex = 4
Instance.new("UICorner", afkBtn).CornerRadius = UDim.new(0, 10)

local initScreen = Instance.new("Frame", gui)
initScreen.Size = UDim2.new(1, 0, 1, 0)
initScreen.Position = UDim2.new(0, 0, 0, 0)
initScreen.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
initScreen.BorderSizePixel = 0
initScreen.ZIndex = 200         
initScreen.ClipsDescendants = true

local card = Instance.new("Frame", initScreen)
card.Size = UDim2.new(0, 380, 0, 240)
card.Position = UDim2.new(0.5, -190, 0.5, -120)
card.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
card.BorderSizePixel = 0
card.ZIndex = 204
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)

local cardTopLine = Instance.new("Frame", card)
cardTopLine.Size = UDim2.new(1, 0, 0, 3)
cardTopLine.Position = UDim2.new(0, 0, 0, 0)
cardTopLine.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
cardTopLine.BorderSizePixel = 0
cardTopLine.ZIndex = 205
Instance.new("UICorner", cardTopLine).CornerRadius = UDim.new(0, 16)

local badge = Instance.new("TextLabel", card)
badge.Size = UDim2.new(0, 100, 0, 20)
badge.Position = UDim2.new(0.5, -50, 0, 18)
badge.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
badge.Text = "LOADING"
badge.TextColor3 = Color3.fromRGB(0, 255, 200)
badge.Font = Enum.Font.GothamBold
badge.TextSize = 10
badge.BorderSizePixel = 0
badge.ZIndex = 206
Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)

local initTitle = Instance.new("TextLabel", card)
initTitle.Size = UDim2.new(1, 0, 0, 40)
initTitle.Position = UDim2.new(0, 0, 0, 48)
initTitle.BackgroundTransparency = 1
initTitle.Text = "Auto WIN + AntiAFK"
initTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
initTitle.Font = Enum.Font.GothamBlack
initTitle.TextSize = 24
initTitle.ZIndex = 206

local initSub = Instance.new("TextLabel", card)
initSub.Size = UDim2.new(1, 0, 0, 20)
initSub.Position = UDim2.new(0, 0, 0, 88)
initSub.BackgroundTransparency = 1
initSub.Text = "Tour • Anti AFK • UI Hider Engine"
initSub.TextColor3 = Color3.fromRGB(110, 115, 135)
initSub.Font = Enum.Font.Gotham
initSub.TextSize = 12
initSub.ZIndex = 206

local loadBg = Instance.new("Frame", card)
loadBg.Size = UDim2.new(0.8, 0, 0, 4)
loadBg.Position = UDim2.new(0.1, 0, 0, 130)
loadBg.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
loadBg.BorderSizePixel = 0
loadBg.ZIndex = 206
Instance.new("UICorner", loadBg).CornerRadius = UDim.new(1, 0)

local loadFill = Instance.new("Frame", loadBg)
loadFill.Size = UDim2.new(0, 0, 1, 0)
loadFill.Position = UDim2.new(0, 0, 0, 0)
loadFill.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
loadFill.BorderSizePixel = 0
loadFill.ZIndex = 207
Instance.new("UICorner", loadFill).CornerRadius = UDim.new(1, 0)

local pctLabel = Instance.new("TextLabel", card)
pctLabel.Size = UDim2.new(0, 50, 0, 16)
pctLabel.Position = UDim2.new(0.9, -50, 0, 110)
pctLabel.BackgroundTransparency = 1
pctLabel.Text = "0%"
pctLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
pctLabel.Font = Enum.Font.GothamBold
pctLabel.TextSize = 11
pctLabel.TextXAlignment = Enum.TextXAlignment.Right
pctLabel.ZIndex = 207

local loadText = Instance.new("TextLabel", card)
loadText.Size = UDim2.new(1, -40, 0, 20)
loadText.Position = UDim2.new(0, 20, 0, 142)
loadText.BackgroundTransparency = 1
loadText.Text = "Initializing framework..."
loadText.TextColor3 = Color3.fromRGB(95, 100, 120)
loadText.Font = Enum.Font.Gotham
loadText.TextSize = 11
loadText.ZIndex = 206

local dotsFrame = Instance.new("Frame", card)
dotsFrame.Size = UDim2.new(0, 110, 0, 6)
dotsFrame.Position = UDim2.new(0.5, -55, 0, 180)
dotsFrame.BackgroundTransparency = 1
dotsFrame.ZIndex = 206

local dots = {}
for d = 1, 6 do
	local dot = Instance.new("Frame", dotsFrame)
	dot.Size = UDim2.new(0, 6, 0, 6)
	dot.Position = UDim2.new(0, (d - 1) * 20, 0, 0)
	dot.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	dot.BorderSizePixel = 0
	dot.ZIndex = 207
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	dots[d] = dot
end

local initCredits = Instance.new("TextLabel", card)
initCredits.Size = UDim2.new(1, 0, 0, 20)
initCredits.Position = UDim2.new(0, 0, 1, -24)
initCredits.BackgroundTransparency = 1
initCredits.Text = "by Toni den Alpha"
initCredits.TextColor3 = Color3.fromRGB(55, 60, 80)
initCredits.Font = Enum.Font.GothamBold
initCredits.TextSize = 10
initCredits.ZIndex = 206

local infoScreen = Instance.new("Frame", gui)
infoScreen.Size = UDim2.new(1, 0, 1, 0)
infoScreen.Position = UDim2.new(0, 0, 0, 0)
infoScreen.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
infoScreen.BorderSizePixel = 0
infoScreen.ZIndex = 300
infoScreen.Visible = false

local infoContainer = Instance.new("Frame", infoScreen)
infoContainer.Size = UDim2.new(0, 460, 0, 320)
infoContainer.Position = UDim2.new(0.5, -230, 0.5, -160)
infoContainer.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
infoContainer.BorderSizePixel = 0
infoContainer.ZIndex = 301
Instance.new("UICorner", infoContainer).CornerRadius = UDim.new(0, 14)

local infoTopLine = Instance.new("Frame", infoContainer)
infoTopLine.Size = UDim2.new(1, 0, 0, 3)
infoTopLine.Position = UDim2.new(0, 0, 0, 0)
infoTopLine.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
infoTopLine.BorderSizePixel = 0
infoTopLine.ZIndex = 302
Instance.new("UICorner", infoTopLine).CornerRadius = UDim.new(0, 14)

local infoTitle = Instance.new("TextLabel", infoContainer)
infoTitle.Size = UDim2.new(1, 0, 0, 40)
infoTitle.Position = UDim2.new(0, 0, 0, 24)
infoTitle.BackgroundTransparency = 1
infoTitle.Text = "📋  Info & How to Use"
infoTitle.TextColor3 = Color3.fromRGB(0, 255, 200)
infoTitle.Font = Enum.Font.GothamBlack
infoTitle.TextSize = 22
infoTitle.ZIndex = 302

local infoBox = Instance.new("Frame", infoContainer)
infoBox.Size = UDim2.new(1, -40, 0, 150)
infoBox.Position = UDim2.new(0, 20, 0, 80)
infoBox.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
infoBox.BorderSizePixel = 0
infoBox.ZIndex = 302
Instance.new("UICorner", infoBox).CornerRadius = UDim.new(0, 10)

local infoText = Instance.new("TextLabel", infoBox)
infoText.Size = UDim2.new(1, -24, 1, -24)
infoText.Position = UDim2.new(0, 12, 0, 12)
infoText.BackgroundTransparency = 1
infoText.Text = "⚠️  Requirement Reminder:\n\n•  You need to be World 2!\n\nEnsure you have loaded into the correct world before execution to prevent mechanism alignment issues."
infoText.TextColor3 = Color3.fromRGB(230, 235, 245)
infoText.Font = Enum.Font.GothamMedium
infoText.TextSize = 15
infoText.TextWrapped = true
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.ZIndex = 303

local infoCloseBtn = Instance.new("TextButton", infoContainer)
infoCloseBtn.Size = UDim2.new(1, -40, 0, 46)
infoCloseBtn.Position = UDim2.new(0, 20, 0, 250)
infoCloseBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 130)
infoCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
infoCloseBtn.Font = Enum.Font.GothamBlack
infoCloseBtn.TextSize = 14
infoCloseBtn.Text = "ACKNOWLEDGE AND CONTINUE"
infoCloseBtn.ZIndex = 303
Instance.new("UICorner", infoCloseBtn).CornerRadius = UDim.new(0, 10)

local afkOverlay = Instance.new("Frame", gui)
afkOverlay.Size = UDim2.new(1, 0, 1, 0)
afkOverlay.Position = UDim2.new(0, 0, 0, 0)
afkOverlay.BackgroundColor3 = Color3.fromRGB(4, 4, 6)
afkOverlay.BorderSizePixel = 0
afkOverlay.ZIndex = 500
afkOverlay.Visible = false

local afkCenteredContainer = Instance.new("Frame", afkOverlay)
afkCenteredContainer.Size = UDim2.new(0, 580, 0, 440)
afkCenteredContainer.Position = UDim2.new(0.5, -290, 0.5, -220)
afkCenteredContainer.BackgroundTransparency = 1

local afkTitle = Instance.new("TextLabel", afkCenteredContainer)
afkTitle.Size = UDim2.new(1, 0, 0, 50)
afkTitle.Position = UDim2.new(0, 0, 0, 0)
afkTitle.BackgroundTransparency = 1
afkTitle.Text = "🌙  AFK MODE ACTIVE"
afkTitle.TextColor3 = Color3.fromRGB(0, 255, 200)
afkTitle.Font = Enum.Font.GothamBlack
afkTitle.TextSize = 28

local afkSub = Instance.new("TextLabel", afkCenteredContainer)
afkSub.Size = UDim2.new(1, 0, 0, 25)
afkSub.Position = UDim2.new(0, 0, 0, 50)
afkSub.BackgroundTransparency = 1
afkSub.Text = "All background UI hidden • Engine safe throttled to 15 FPS"
afkSub.TextColor3 = Color3.fromRGB(110, 115, 130)
afkSub.Font = Enum.Font.GothamMedium
afkSub.TextSize = 13

local statsBox = Instance.new("Frame", afkCenteredContainer)
statsBox.Size = UDim2.new(1, 0, 0, 240)
statsBox.Position = UDim2.new(0, 0, 0, 100)
statsBox.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
statsBox.BorderSizePixel = 0
Instance.new("UICorner", statsBox).CornerRadius = UDim.new(0, 14)

local function CreateGiantStatRow(parent, labelText, initialValue, yOffset, isAccent)
	local rowFrame = Instance.new("Frame", parent)
	rowFrame.Size = UDim2.new(1, -40, 0, 60)
	rowFrame.Position = UDim2.new(0, 20, 0, yOffset)
	rowFrame.BackgroundTransparency = 1

	local label = Instance.new("TextLabel", rowFrame)
	label.Size = UDim2.new(0.4, 0, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(140, 145, 160)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left

	local value = Instance.new("TextLabel", rowFrame)
	value.Size = UDim2.new(0.6, 0, 1, 0)
	value.Position = UDim2.new(0.4, 0, 0, 0)
	value.BackgroundTransparency = 1
	value.Text = initialValue
	value.TextColor3 = isAccent and Color3.fromRGB(0, 255, 200) or Color3.fromRGB(255, 255, 255)
	value.Font = Enum.Font.GothamBlack
	value.TextSize = 24
	value.TextXAlignment = Enum.TextXAlignment.Right

	return value
end

local timeValueLabel = CreateGiantStatRow(statsBox, "TIME ELAPSED", "00:00:00", 20, false)
local currentWinsLabel = CreateGiantStatRow(statsBox, "CURRENT TOTAL WINS", "0", 90, false)
local gainedWinsLabel = CreateGiantStatRow(statsBox, "SESSION WINS GAINED", "+0", 160, true)

local exitAfkBtn = Instance.new("TextButton", afkCenteredContainer)
exitAfkBtn.Size = UDim2.new(1, 0, 0, 54)
exitAfkBtn.Position = UDim2.new(0, 0, 0, 365)
exitAfkBtn.BackgroundColor3 = Color3.fromRGB(170, 35, 35)
exitAfkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
exitAfkBtn.Font = Enum.Font.GothamBlack
exitAfkBtn.TextSize = 15
exitAfkBtn.Text = "RESTORE INTERFACE AND FOCUS"
exitAfkBtn.ZIndex = 502
Instance.new("UICorner", exitAfkBtn).CornerRadius = UDim.new(0, 10)

local function FormatCompactNumber(number)
	local num = tonumber(number)
	if not num then return "0" end
	
	if num >= 1e9 then
		return string.format("%.2fB", num / 1e9)
	elseif num >= 1e6 then
		return string.format("%.2fM", num / 1e6)
	elseif num >= 1e3 then
		return string.format("%.2fK", num / 1e3)
	else
		return tostring(num)
	end
end

local function FormatTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function SetExternalUiVisible(visible)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, visible)
	end)

	local playerGui = player:FindFirstChild("PlayerGui")
	if playerGui then
		if not visible then
			for _, child in ipairs(playerGui:GetChildren()) do
				if child:IsA("ScreenGui") and child.Name ~= "ToniUI" and child.Enabled == true then
					child.Enabled = false
					table.insert(hiddenGuis, child)
				end
			end
		else
			for _, child in ipairs(hiddenGuis) do
				if child and child.Parent then
					child.Enabled = true
				end
			end
			table.clear(hiddenGuis)
		end
	end
end

local function UpdateAFKStats()
	if winsValueObject then
		local total = winsValueObject.Value
		local gained = total - startWins
		currentWinsLabel.Text = FormatCompactNumber(total)
		gainedWinsLabel.Text = "+" .. FormatCompactNumber(gained)
	else
		currentWinsLabel.Text = "N/A"
		gainedWinsLabel.Text = "+0"
	end
end

afkBtn.MouseButton1Click:Connect(function()
	mainPanel.Visible = false
	afkOverlay.Visible = true
	afkStartTime = os.time()
	
	SetExternalUiVisible(false)
	
	if winsValueObject then startWins = winsValueObject.Value end
	UpdateAFKStats()
	
	if setfpscap then setfpscap(15) end
	
	sessionTimerConnection = RunService.Heartbeat:Connect(function()
		local elapsed = os.time() - afkStartTime
		timeValueLabel.Text = FormatTime(elapsed)
		UpdateAFKStats()
	end)
end)

exitAfkBtn.MouseButton1Click:Connect(function()
	if sessionTimerConnection then
		sessionTimerConnection:Disconnect()
		sessionTimerConnection = nil
	end
	
	if setfpscap then setfpscap(60) end
	
	SetExternalUiVisible(true)
	
	afkOverlay.Visible = false
	mainPanel.Visible = true
end)

local function StopAutoFly()
	isAutoFlying = false
	SetWHeld(false)
	local char = player.Character
	local rootPart = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if rootPart then rootPart.Anchored = false; rootPart.Velocity = Vector3.zero end
	if humanoid then humanoid.PlatformStand = false end
	btn.Text = "▶  Start Tour"
	btn.BackgroundColor3 = Color3.fromRGB(0, 170, 130)
end

local function StartAutoFly()
	if isAutoFlying then StopAutoFly(); return end
	if #Checkpoints < 1 then return end
	isAutoFlying = true
	btn.Text = "⏸  Stop Tour"
	btn.BackgroundColor3 = Color3.fromRGB(180, 35, 35)

	task.spawn(function()
		while isAutoFlying do
			local char = player.Character or player.CharacterAdded:Wait()
			local rootPart = char:WaitForChild("HumanoidRootPart")
			local humanoid = char:WaitForChild("Humanoid")
			local totalCPs = #Checkpoints

			for i = 1, totalCPs do
				if not isAutoFlying then break end
				if i <= totalCPs - 2 then SetWHeld(true) else SetWHeld(false) end

				local posData = string.split(Checkpoints[i], ",")
				local targetPos = Vector3.new(tonumber(posData[1]), tonumber(posData[2]), tonumber(posData[3]))
				local dist = (rootPart.Position - targetPos).Magnitude
				local speed = math.clamp(FlySpeed, 10, 500)
				local timeToReach = dist / speed

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
				while isAutoFlying and t < (timeToReach + 2) and (rootPart.Position - targetPos).Magnitude > 5 do
					local dt = task.wait()
					t = t + dt
					local dir = (targetPos - rootPart.Position)
					if dir.Magnitude > 0 then
						bv.Velocity = dir.Unit * speed
						bg.CFrame = CFrame.new(rootPart.Position, targetPos)
					end
				end
				bv:Destroy()
				bg:Destroy()
				rootPart.Velocity = Vector3.zero
				rootPart.RotVelocity = Vector3.zero
				if not isAutoFlying then break end
			end

			if not isAutoFlying then break end
			humanoid.PlatformStand = false
			rootPart.Anchored = false
			SetWHeld(false)

			if CPEndAction == "Jump" then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				task.wait(0.2)
			elseif CPEndAction == "D Tap" then
				if keypress then
					keypress(0x44); task.wait(0.1); keyrelease(0x44)
				else
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.D, false, game)
					task.wait(0.1)
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game)
				end
			end

			if not isAutoFlying then break end
			if AutoRespawn then
				local rTimer = 0
				while isAutoFlying and rTimer < RespawnDelay do
					rTimer = rTimer + task.wait()
				end
				if not isAutoFlying then break end
				humanoid.Health = 0
				local newChar = player.CharacterAdded:Wait()
				local newRoot = newChar:WaitForChild("HumanoidRootPart")
				local safeSpawnPos = Vector3.new(-0.28, 10.23, 2.96)
				while isAutoFlying do
					if newRoot and newRoot.Parent then
						if (newRoot.Position - safeSpawnPos).Magnitude <= 30 then break end
					end
					task.wait(0.2)
				end
			end

			if not isAutoFlying then break end
			if LoopTour then
				if LoopDelay > 0 then task.wait(LoopDelay) end
			else
				break
			end
		end
		StopAutoFly()
	end)
end

btn.MouseButton1Click:Connect(function()
	StartAutoFly()
end)

destroyBtn.MouseButton1Click:Connect(function()
	if sessionTimerConnection then sessionTimerConnection:Disconnect() end
	if setfpscap then setfpscap(60) end
	SetExternalUiVisible(true)
	StopAutoFly()
	gui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.K and not afkOverlay.Visible and not infoScreen.Visible then
		mainPanel.Visible = not mainPanel.Visible
	end
end)

card.BackgroundTransparency = 1
card.Position = UDim2.new(0.5, -190, 0.53, -120)
for _, obj in ipairs(card:GetDescendants()) do
	if obj:IsA("TextLabel") then obj.TextTransparency = 1 end
	if obj:IsA("Frame") then obj.BackgroundTransparency = 1 end
end

task.spawn(function()
	task.wait(0.15)
	TweenService:Create(card, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundTransparency = 0, Position = UDim2.new(0.5, -190, 0.5, -120) }):Play()
	for _, obj in ipairs(card:GetDescendants()) do
		if obj:IsA("TextLabel") then
			TweenService:Create(obj, TweenInfo.new(0.5, Enum.EasingStyle.Quart), { TextTransparency = 0 }):Play()
		elseif obj:IsA("Frame") then
			TweenService:Create(obj, TweenInfo.new(0.5, Enum.EasingStyle.Quart), { BackgroundTransparency = 0 }):Play()
		end
	end
end)

task.spawn(function()
	local t = 0
	while true do
		t = t + 0.018
		local hue = t % 1
		local brightness = 0.65 + 0.35 * math.abs(math.sin(t * math.pi * 2.8))
		local saturation = 0.65 + 0.35 * math.abs(math.sin(t * math.pi * 1.9))
		local size = 19 + math.floor(3 * math.sin(t * math.pi * 2.3))
		local spaces = math.floor(math.abs(math.sin(t * math.pi * 1.5)) * 2)
		local spacer = string.rep(" ", spaces)
		creditsLabel.Text = spacer .. "Made by Toni den Alpha" .. spacer
		creditsLabel.TextColor3 = Color3.fromHSV(hue, saturation, brightness)
		creditsLabel.TextSize = size

		titleAccent.BackgroundColor3 = Color3.fromHSV((hue + 0.33) % 1, 1, 1)
		if initScreen.Visible then cardTopLine.BackgroundColor3 = Color3.fromHSV(hue, 1, 1) end
		if infoScreen.Visible then infoTopLine.BackgroundColor3 = Color3.fromHSV(hue, 1, 1) end
		task.wait(0.03)
	end
end)

player.Idled:Connect(function()
	statusLabel.Text = "⚡  Kick blocked!"
	task.wait(2)
	statusLabel.Text = "⬡  Status: Active"
end)

local loadSteps = {
	{ text = "Parsing codebase configuration...", pct = 0.18 },
	{ text = "Hooking system environment...",    pct = 0.35 },
	{ text = "Setting persistent Anti-AFK...",   pct = 0.52 },
	{ text = "Mapping network checkpoints...",    pct = 0.68 },
	{ text = "Rendering execution nodes...",      pct = 0.85 },
	{ text = "Safe deployment complete.",          pct = 1.00 },
}

infoCloseBtn.MouseButton1Click:Connect(function()
	infoScreen.Visible = false
	SetExternalUiVisible(true)
	
	mainPanel.Position = UDim2.new(0.698, 0, -0.06, 0)
	mainPanel.Visible = true
	TweenService:Create(mainPanel, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.698, 0, 0.098, 0) }):Play()
end)

task.spawn(function()
	task.wait(0.5)
	for stepIndex, step in ipairs(loadSteps) do
		loadText.Text = step.text
		pctLabel.Text = math.floor(step.pct * 100) .. "%"
		TweenService:Create(dots[stepIndex], TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(0, 255, 200) }):Play()
		TweenService:Create(loadFill, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(step.pct, 0, 1, 0) }):Play()
		task.wait(0.45)
	end

	task.wait(0.25)
	badge.Text = "READY"
	task.wait(0.4)

	for _, obj in ipairs(initScreen:GetDescendants()) do
		if obj:IsA("TextLabel") then TweenService:Create(obj, TweenInfo.new(0.4, Enum.EasingStyle.Quart), { TextTransparency = 1 }):Play()
		elseif obj:IsA("Frame") then TweenService:Create(obj, TweenInfo.new(0.4, Enum.EasingStyle.Quart), { BackgroundTransparency = 1 }):Play() end
	end
	TweenService:Create(initScreen, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
	task.wait(0.5)
	initScreen.Visible = false

	SetExternalUiVisible(false)
	infoScreen.Visible = true
end)
