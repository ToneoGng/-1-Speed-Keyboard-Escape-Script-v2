local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local leaderstats = player:WaitForChild("leaderstats", 10)
local winsValueObject = leaderstats and leaderstats:WaitForChild("Wins", 10)
local startWins = winsValueObject and winsValueObject.Value or 0
local afkStartTime = 0
local scriptStartTime = os.time()
local sessionTimerConnection = nil
local hiddenGuis = {}

local webhookUrl = ""
local webhookEnabled = false
local currentWebhookMessageId = nil
local isScriptActive = true

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

local FlySpeed = 16
local LoopTour = true
local LoopDelay = 0.7
local AutoRespawn = false
local RespawnDelay = 2.5
local CPEndAction = "Jump"

local Checkpoints = {
	"-399.31,503.80,6.78", "-403.53,503.80,74.53", "-408.98,503.80,124.51", 
	"-412.58,503.18,177.27", "-412.31,498.80,186.98", "-412.31,498.80,192.98",
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

local function UpdateDynamicSpeed()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		FlySpeed = hum.WalkSpeed + 20
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
if player.Character then
	task.spawn(SetupSpeedListener, player.Character)
end

local function GetWebhookInfo(url)
	local clean = url:gsub("^%s*(.-)%s*$", "%1")
	clean = clean:gsub("discord%.com", "webhook.lewisakura.moe")
	clean = clean:gsub("discordapp%.com", "webhook.lewisakura.moe")
	local baseUrl, query = clean:match("^([^?]+)(%?.*)$")
	if not baseUrl then
		baseUrl = clean
		query = ""
	end
	return baseUrl, query
end

local function SendOrUpdateWebhook(embedData, forceSend)
	if (not webhookEnabled and not forceSend) or webhookUrl == "" or not requestFunc then return end
	
	local baseUrl, query = GetWebhookInfo(webhookUrl)
	local payload = {
		username = "Toni's Engine",
		avatar_url = "https://i.imgur.com/k23x3Z8.png",
		embeds = embedData
	}
	
	if currentWebhookMessageId then
		local success, response = pcall(function()
			return requestFunc({
				Url = baseUrl .. "/messages/" .. currentWebhookMessageId .. query,
				Method = "PATCH",
				Headers = {["Content-Type"] = "application/json"},
				Body = HttpService:JSONEncode(payload)
			})
		end)
		
		if success and response and response.StatusCode == 200 then
			return
		else
			currentWebhookMessageId = nil
		end
	end
	
	if not currentWebhookMessageId then
		local separator = (query == "") and "?wait=true" or (query .. "&wait=true")
		local success, response = pcall(function()
			return requestFunc({
				Url = baseUrl .. separator,
				Method = "POST",
				Headers = {["Content-Type"] = "application/json"},
				Body = HttpService:JSONEncode(payload)
			})
		end)
		
		if success and response and (response.StatusCode == 200 or response.StatusCode == 201) then
			pcall(function()
				local decoded = HttpService:JSONDecode(response.Body)
				if decoded and decoded.id then
					currentWebhookMessageId = decoded.id
				end
			end)
		end
	end
end

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
local SLIDER_H = 50
local BODY_H = PADDING + STATUS_H + PADDING + CREDITS_H + PADDING + BTN_H + PADDING + BTN_H + PADDING + SLIDER_H + PADDING

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
titleLabel.Size = UDim2.new(1, -90, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🦴 Auto WIN + AntiAFK"
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
destroyBtn.Text = "❌"
destroyBtn.ZIndex = 10
Instance.new("UICorner", destroyBtn).CornerRadius = UDim.new(0, 6)

local webhookMenuBtn = Instance.new("TextButton", titleBar)
webhookMenuBtn.Size = UDim2.new(0, 28, 0, 28)
webhookMenuBtn.Position = UDim2.new(1, -74, 0.5, -14)
webhookMenuBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
webhookMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
webhookMenuBtn.Font = Enum.Font.GothamBlack
webhookMenuBtn.TextSize = 14
webhookMenuBtn.Text = "🌐"
webhookMenuBtn.ZIndex = 10
Instance.new("UICorner", webhookMenuBtn).CornerRadius = UDim.new(0, 6)

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
statusLabel.Text = "Made with Love 💕"
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
statusLabel.TextSize = 17
statusLabel.ZIndex = 4
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)

local creditsLabel = Instance.new("TextLabel", bodyFrame)
creditsLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
creditsLabel.Position = UDim2.new(0, 0, 0, PADDING + STATUS_H + PADDING)
creditsLabel.Size = UDim2.new(1, 0, 0, CREDITS_H)
creditsLabel.Font = Enum.Font.GothamBlack
creditsLabel.Text = "Made by Toni✌️"
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

local sliderFrame = Instance.new("Frame", bodyFrame)
sliderFrame.Size = UDim2.new(1, -20, 0, SLIDER_H)
sliderFrame.Position = UDim2.new(0, 10, 0, PADDING + STATUS_H + PADDING + CREDITS_H + PADDING + BTN_H + PADDING + BTN_H + PADDING)
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
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDraggingSlider = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDraggingSlider = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
		sliderFill.Size = UDim2.new(pos, 0, 1, 0)
		LoopDelay = math.floor(pos * 50) / 10 -- Range 0 to 5 seconds
		sliderTitle.Text = "Loop Delay: " .. tostring(LoopDelay) .. "s"
	end
end)

local initScreen = Instance.new("Frame", gui)
initScreen.Size = UDim2.new(1, 0, 1, 0)
initScreen.Position = UDim2.new(0, 0, 0, 0)
initScreen.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
initScreen.BorderSizePixel = 0
initScreen.ZIndex = 200         
initScreen.ClipsDescendants = true

local card = Instance.new("Frame", initScreen)
card.Size = UDim2.new(0, 420, 0, 260)
card.Position = UDim2.new(0.5, -210, 0.5, -130)
card.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
card.BorderSizePixel = 0
card.ZIndex = 204
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)

local cardStroke = Instance.new("UIStroke", card)
cardStroke.Color = Color3.fromRGB(0, 255, 200)
cardStroke.Transparency = 0.5
cardStroke.Thickness = 2

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
initCredits.Text = "by Toni✌️"
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
infoContainer.Size = UDim2.new(0, 540, 0, 380)
infoContainer.Position = UDim2.new(0.5, -270, 0.5, -190)
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
infoTitle.Size = UDim2.new(1, 0, 0, 50)
infoTitle.Position = UDim2.new(0, 0, 0, 24)
infoTitle.BackgroundTransparency = 1
infoTitle.Text = "📋  Info & How to Use"
infoTitle.TextColor3 = Color3.fromRGB(0, 255, 200)
infoTitle.Font = Enum.Font.GothamBlack
infoTitle.TextSize = 26
infoTitle.ZIndex = 302

local infoBox = Instance.new("Frame", infoContainer)
infoBox.Size = UDim2.new(1, -50, 0, 180)
infoBox.Position = UDim2.new(0, 25, 0, 90)
infoBox.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
infoBox.BorderSizePixel = 0
infoBox.ZIndex = 302
Instance.new("UICorner", infoBox).CornerRadius = UDim.new(0, 10)

local infoText = Instance.new("TextLabel", infoBox)
infoText.Size = UDim2.new(1, -30, 1, -30)
infoText.Position = UDim2.new(0, 15, 0, 15)
infoText.BackgroundTransparency = 1
infoText.Text = "⚠️  Requirement Reminder:\n\n•  You need to be World 2!\n\nEnsure you have loaded into the correct world before execution to prevent mechanism alignment issues."
infoText.TextColor3 = Color3.fromRGB(230, 235, 245)
infoText.Font = Enum.Font.GothamMedium
infoText.TextSize = 17
infoText.TextWrapped = true
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.ZIndex = 303

local infoCloseBtn = Instance.new("TextButton", infoContainer)
infoCloseBtn.Size = UDim2.new(1, -50, 0, 54)
infoCloseBtn.Position = UDim2.new(0, 25, 0, 290)
infoCloseBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 130)
infoCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
infoCloseBtn.Font = Enum.Font.GothamBlack
infoCloseBtn.TextSize = 16
infoCloseBtn.Text = "ACKNOWLEDGE AND CONTINUE"
infoCloseBtn.ZIndex = 303
Instance.new("UICorner", infoCloseBtn).CornerRadius = UDim.new(0, 10)

local webhookScreen = Instance.new("Frame", gui)
webhookScreen.Size = UDim2.new(1, 0, 1, 0)
webhookScreen.Position = UDim2.new(0, 0, 0, 0)
webhookScreen.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
webhookScreen.BorderSizePixel = 0
webhookScreen.ZIndex = 400
webhookScreen.Visible = false

local webhookContainer = Instance.new("Frame", webhookScreen)
webhookContainer.Size = UDim2.new(0, 460, 0, 380)
webhookContainer.Position = UDim2.new(0.5, -230, 0.5, -190)
webhookContainer.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
webhookContainer.BorderSizePixel = 0
webhookContainer.ZIndex = 401
Instance.new("UICorner", webhookContainer).CornerRadius = UDim.new(0, 14)

local webhookTopLine = Instance.new("Frame", webhookContainer)
webhookTopLine.Size = UDim2.new(1, 0, 0, 3)
webhookTopLine.Position = UDim2.new(0, 0, 0, 0)
webhookTopLine.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
webhookTopLine.BorderSizePixel = 0
webhookTopLine.ZIndex = 402
Instance.new("UICorner", webhookTopLine).CornerRadius = UDim.new(0, 14)

local webhookTitle = Instance.new("TextLabel", webhookContainer)
webhookTitle.Size = UDim2.new(1, 0, 0, 40)
webhookTitle.Position = UDim2.new(0, 0, 0, 20)
webhookTitle.BackgroundTransparency = 1
webhookTitle.Text = "🌐  Webhook Configuration"
webhookTitle.TextColor3 = Color3.fromRGB(88, 101, 242)
webhookTitle.Font = Enum.Font.GothamBlack
webhookTitle.TextSize = 22
webhookTitle.ZIndex = 402

local webhookUrlInput = Instance.new("TextBox", webhookContainer)
webhookUrlInput.Size = UDim2.new(1, -40, 0, 45)
webhookUrlInput.Position = UDim2.new(0, 20, 0, 80)
webhookUrlInput.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
webhookUrlInput.TextColor3 = Color3.fromRGB(255, 255, 255)
webhookUrlInput.PlaceholderText = "Enter Discord Webhook URL here..."
webhookUrlInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 115)
webhookUrlInput.Font = Enum.Font.GothamMedium
webhookUrlInput.TextSize = 13
webhookUrlInput.Text = ""
webhookUrlInput.ClearTextOnFocus = false
webhookUrlInput.ZIndex = 403
Instance.new("UICorner", webhookUrlInput).CornerRadius = UDim.new(0, 8)

local webhookInfoLabel = Instance.new("TextLabel", webhookContainer)
webhookInfoLabel.Size = UDim2.new(1, -40, 0, 40)
webhookInfoLabel.Position = UDim2.new(0, 20, 0, 135)
webhookInfoLabel.BackgroundTransparency = 1
webhookInfoLabel.Text = "Sends an automated update every 60 seconds with your current Total Wins, Session Wins Gained, and Session Uptime."
webhookInfoLabel.TextColor3 = Color3.fromRGB(150, 155, 170)
webhookInfoLabel.Font = Enum.Font.Gotham
webhookInfoLabel.TextSize = 12
webhookInfoLabel.TextWrapped = true
webhookInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
webhookInfoLabel.ZIndex = 403

local toggleWebhookBtn = Instance.new("TextButton", webhookContainer)
toggleWebhookBtn.Size = UDim2.new(1, -40, 0, 45)
toggleWebhookBtn.Position = UDim2.new(0, 20, 0, 185)
toggleWebhookBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 65)
toggleWebhookBtn.TextColor3 = Color3.fromRGB(150, 155, 170)
toggleWebhookBtn.Font = Enum.Font.GothamBlack
toggleWebhookBtn.TextSize = 14
toggleWebhookBtn.Text = "❌  WEBHOOK DISABLED"
toggleWebhookBtn.ZIndex = 403
Instance.new("UICorner", toggleWebhookBtn).CornerRadius = UDim.new(0, 8)

local testWebhookBtn = Instance.new("TextButton", webhookContainer)
testWebhookBtn.Size = UDim2.new(1, -40, 0, 45)
testWebhookBtn.Position = UDim2.new(0, 20, 0, 240)
testWebhookBtn.BackgroundColor3 = Color3.fromRGB(50, 55, 80)
testWebhookBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
testWebhookBtn.Font = Enum.Font.GothamBlack
testWebhookBtn.TextSize = 14
testWebhookBtn.Text = "🧪  TEST WEBHOOK"
testWebhookBtn.ZIndex = 403
Instance.new("UICorner", testWebhookBtn).CornerRadius = UDim.new(0, 8)

local webhookCloseBtn = Instance.new("TextButton", webhookContainer)
webhookCloseBtn.Size = UDim2.new(1, -40, 0, 46)
webhookCloseBtn.Position = UDim2.new(0, 20, 0, 305)
webhookCloseBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
webhookCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
webhookCloseBtn.Font = Enum.Font.GothamBlack
webhookCloseBtn.TextSize = 14
webhookCloseBtn.Text = "SAVE & CLOSE"
webhookCloseBtn.ZIndex = 403
Instance.new("UICorner", webhookCloseBtn).CornerRadius = UDim.new(0, 10)

local afkOverlay = Instance.new("Frame", gui)
afkOverlay.Size = UDim2.new(1, 0, 1, 0)
afkOverlay.Position = UDim2.new(0, 0, 0, 0)
afkOverlay.BackgroundColor3 = Color3.fromRGB(4, 4, 6)
afkOverlay.BorderSizePixel = 0
afkOverlay.ZIndex = 500
afkOverlay.Visible = false

local afkCenteredContainer = Instance.new("Frame", afkOverlay)
afkCenteredContainer.Size = UDim2.new(0, 580, 0, 490)
afkCenteredContainer.Position = UDim2.new(0.5, -290, 0.5, -245)
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
statsBox.Size = UDim2.new(1, 0, 0, 290)
statsBox.Position = UDim2.new(0, 0, 0, 100)
statsBox.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
statsBox.BorderSizePixel = 0
Instance.new("UICorner", statsBox).CornerRadius = UDim.new(0, 14)

local function CreateGiantStatRow(parent, labelText, initialValue, yOffset, isAccent)
	local rowFrame = Instance.new("Frame", parent)
	rowFrame.Size = UDim2.new(1, -40, 0, 50)
	rowFrame.Position = UDim2.new(0, 20, 0, yOffset)
	rowFrame.BackgroundTransparency = 1

	local label = Instance.new("TextLabel", rowFrame)
	label.Size = UDim2.new(0.5, 0, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(140, 145, 160)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left

	local value = Instance.new("TextLabel", rowFrame)
	value.Size = UDim2.new(0.5, 0, 1, 0)
	value.Position = UDim2.new(0.5, 0, 0, 0)
	value.BackgroundTransparency = 1
	value.Text = initialValue
	value.TextColor3 = isAccent and Color3.fromRGB(0, 255, 200) or Color3.fromRGB(255, 255, 255)
	value.Font = Enum.Font.GothamBlack
	value.TextSize = 20
	value.TextXAlignment = Enum.TextXAlignment.Right

	return value
end

local timeValueLabel = CreateGiantStatRow(statsBox, "TIME ELAPSED", "00:00:00", 20, false)
local currentWinsLabel = CreateGiantStatRow(statsBox, "CURRENT TOTAL WINS", "0", 85, false)
local gainedWinsLabel = CreateGiantStatRow(statsBox, "SESSION WINS GAINED", "+0", 150, true)
local dynamicFlySpeedLabel = CreateGiantStatRow(statsBox, "CURRENT ENGINE SPEED", "0", 215, true)

local exitAfkBtn = Instance.new("TextButton", afkCenteredContainer)
exitAfkBtn.Size = UDim2.new(1, 0, 0, 54)
exitAfkBtn.Position = UDim2.new(0, 0, 0, 415)
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
	dynamicFlySpeedLabel.Text = tostring(math.floor(FlySpeed))
end

afkBtn.MouseButton1Click:Connect(function()
	mainPanel.Visible = false
	afkOverlay.Visible = true
	afkStartTime = os.time()
	
	SetExternalUiVisible(false)
	
	if winsValueObject then startWins = winsValueObject.Value end
	UpdateAFKStats()
	UpdateDynamicSpeed()
	
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

webhookMenuBtn.MouseButton1Click:Connect(function()
	mainPanel.Visible = false
	webhookScreen.Visible = true
	webhookUrlInput.Text = webhookUrl
end)

webhookUrlInput.FocusLost:Connect(function()
	webhookUrl = webhookUrlInput.Text
end)

toggleWebhookBtn.MouseButton1Click:Connect(function()
	webhookEnabled = not webhookEnabled
	if webhookEnabled then
		toggleWebhookBtn.Text = "✅  WEBHOOK ENABLED"
		toggleWebhookBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 130)
		toggleWebhookBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		toggleWebhookBtn.Text = "❌  WEBHOOK DISABLED"
		toggleWebhookBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 65)
		toggleWebhookBtn.TextColor3 = Color3.fromRGB(150, 155, 170)
	end
end)

testWebhookBtn.MouseButton1Click:Connect(function()
	webhookUrl = webhookUrlInput.Text
	if webhookUrl ~= "" then
		local data = {{
			["title"] = "🚀 Webhook Configuration Verified",
			["description"] = "Connection to the webhook was successful! This message will act as your anchor. All future live updates will dynamically edit this embed to prevent channel spam.",
			["color"] = tonumber(0x00FFC8),
			["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			["author"] = {
				["name"] = player.Name .. " • System Test",
				["icon_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
			},
			["footer"] = {
				["text"] = "Toni • Auto WIN Framework"
			}
		}}
		SendOrUpdateWebhook(data, true)
		
		local oldText = testWebhookBtn.Text
		testWebhookBtn.Text = "✅  TEST SENT"
		task.delay(2, function()
			testWebhookBtn.Text = oldText
		end)
	end
end)

webhookCloseBtn.MouseButton1Click:Connect(function()
	webhookUrl = webhookUrlInput.Text
	webhookScreen.Visible = false
	mainPanel.Visible = true
end)

task.spawn(function()
	while isScriptActive do
		task.wait(60)
		if not isScriptActive then break end
		if webhookEnabled and webhookUrl ~= "" and requestFunc then
			local currentWins = winsValueObject and winsValueObject.Value or 0
			local gained = currentWins - startWins
			local elapsed = os.time() - scriptStartTime
			
			local data = {{
				["title"] = "📊 Live Session Statistics",
				["color"] = tonumber(0x00FFC8),
				["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
				["author"] = {
					["name"] = player.Name .. " • Live Session",
					["icon_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
				},
				["fields"] = {
					{["name"] = "🏆 Current Total Wins", ["value"] = "```\n" .. FormatCompactNumber(currentWins) .. "\n```", ["inline"] = true},
					{["name"] = "📈 Session Gains", ["value"] = "```diff\n+ " .. FormatCompactNumber(gained) .. "\n```", ["inline"] = true},
					{["name"] = "⏱️ Session Uptime", ["value"] = "```\n" .. FormatTime(elapsed) .. "\n```", ["inline"] = false},
					{["name"] = "⚙️ Engine Speed", ["value"] = "```\n" .. tostring(math.floor(FlySpeed)) .. " FPS\n```", ["inline"] = true},
					{["name"] = "📡 Status", ["value"] = "```yaml\nActive and Farming\n```", ["inline"] = true}
				},
				["footer"] = {
					["text"] = "Toni • Auto WIN Framework"
				}
			}}
			
			SendOrUpdateWebhook(data, false)
		end
	end
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
	
	if isScriptActive then
		local data = {{
			["title"] = "⏸️ Session Paused",
			["description"] = "The automatic flight tour has been paused or stopped by the user.",
			["color"] = tonumber(0xFFB000),
			["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			["author"] = {
				["name"] = player.Name .. " • Session Manager",
				["icon_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
			},
			["footer"] = {
				["text"] = "Toni • Auto WIN Framework"
			}
		}}
		SendOrUpdateWebhook(data, false)
	end
end

local function StartAutoFly()
	if isAutoFlying then StopAutoFly(); return end
	if #Checkpoints < 1 then return end
	isAutoFlying = true
	btn.Text = "⏸  Stop Tour"
	btn.BackgroundColor3 = Color3.fromRGB(180, 35, 35)

	local data = {{
		["title"] = "▶️ Session Started",
		["description"] = "The automatic flight tour has been initiated successfully.",
		["color"] = tonumber(0x00FFC8),
		["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		["author"] = {
			["name"] = player.Name .. " • Session Manager",
			["icon_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
		},
		["footer"] = {
			["text"] = "Toni • Auto WIN Framework"
		}
	}}
	SendOrUpdateWebhook(data, false)

	task.spawn(function()
		while isAutoFlying and isScriptActive do
			local char = player.Character or player.CharacterAdded:Wait()
			local rootPart = char:WaitForChild("HumanoidRootPart")
			local humanoid = char:WaitForChild("Humanoid")
			local totalCPs = #Checkpoints

			for i = 1, totalCPs do
				if not isAutoFlying or not isScriptActive then break end
				if i <= totalCPs - 2 then SetWHeld(true) else SetWHeld(false) end

				local posData = string.split(Checkpoints[i], ",")
				local targetPos = Vector3.new(tonumber(posData[1]), tonumber(posData[2]), tonumber(posData[3]))
				local dist = (rootPart.Position - targetPos).Magnitude
				UpdateDynamicSpeed()
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
				while isAutoFlying and isScriptActive and t < (timeToReach + 2) and (rootPart.Position - targetPos).Magnitude > 5 do
					local dt = task.wait()
					t = t + dt
					UpdateDynamicSpeed()
					speed = math.clamp(FlySpeed, 10, 500)
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
				if not isAutoFlying or not isScriptActive then break end
			end

			if not isAutoFlying or not isScriptActive then break end
			humanoid.PlatformStand = false
			rootPart.Anchored = false
			SetWHeld(false)

			-- Out of velocity fly into a jump
			task.wait(0.1) -- small delay to allow physics to update and character to ground
			if humanoid then
				humanoid.Jump = true
				pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
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
				humanoid.Health = 0
				local newChar = player.CharacterAdded:Wait()
				local newRoot = newChar:WaitForChild("HumanoidRootPart")
				local safeSpawnPos = Vector3.new(-0.28, 10.23, 2.96)
				while isAutoFlying and isScriptActive do
					if newRoot and newRoot.Parent then
						if (newRoot.Position - safeSpawnPos).Magnitude <= 30 then break end
					end
					task.wait(0.2)
				end
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

	if sessionTimerConnection then sessionTimerConnection:Disconnect() end
	if setfpscap then setfpscap(60) end
	SetExternalUiVisible(true)
	
	isAutoFlying = false
	SetWHeld(false)
	local char = player.Character
	local rootPart = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if rootPart then rootPart.Anchored = false; rootPart.Velocity = Vector3.zero end
	if humanoid then humanoid.PlatformStand = false end

	local data = {{
		["title"] = "🛑 Script Terminated",
		["description"] = "The Auto WIN UI and script have been fully closed by the user.",
		["color"] = tonumber(0xFF3333),
		["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		["author"] = {
			["name"] = player.Name .. " • Session Manager",
			["icon_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
		},
		["footer"] = {
			["text"] = "Toni • Auto WIN Framework"
		}
	}}
	SendOrUpdateWebhook(data, false)

	gui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.K and not afkOverlay.Visible and not infoScreen.Visible and not webhookScreen.Visible then
		mainPanel.Visible = not mainPanel.Visible
	end
end)

card.BackgroundTransparency = 1
card.Position = UDim2.new(0.5, -190, 0.53, -120)
for _, obj in ipairs(card:GetDescendants()) do
	if obj:IsA("TextLabel") then obj.TextTransparency = 1 end
	if obj:IsA("Frame") then obj.BackgroundTransparency = 1 end
	if obj:IsA("UIStroke") then obj.Transparency = 1 end
end

task.spawn(function()
	task.wait(0.15)
	TweenService:Create(card, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundTransparency = 0, Position = UDim2.new(0.5, -210, 0.5, -130) }):Play()
	for _, obj in ipairs(card:GetDescendants()) do
		if obj:IsA("TextLabel") then
			TweenService:Create(obj, TweenInfo.new(0.5, Enum.EasingStyle.Quart), { TextTransparency = 0 }):Play()
		elseif obj:IsA("Frame") then
			TweenService:Create(obj, TweenInfo.new(0.5, Enum.EasingStyle.Quart), { BackgroundTransparency = 0 }):Play()
		elseif obj:IsA("UIStroke") then
			TweenService:Create(obj, TweenInfo.new(0.5, Enum.EasingStyle.Quart), { Transparency = 0.5 }):Play()
		end
	end
end)

task.spawn(function()
	local t = 0
	while isScriptActive do
		t = t + 0.018
		local hue = t % 1
		local brightness = 0.65 + 0.35 * math.abs(math.sin(t * math.pi * 2.8))
		local saturation = 0.65 + 0.35 * math.abs(math.sin(t * math.pi * 1.9))
		local size = 19 + math.floor(3 * math.sin(t * math.pi * 2.3))
		local spaces = math.floor(math.abs(math.sin(t * math.pi * 1.5)) * 2)
		local spacer = string.rep(" ", spaces)
		creditsLabel.Text = spacer .. "Made by Toni✌️" .. spacer
		creditsLabel.TextColor3 = Color3.fromHSV(hue, saturation, brightness)
		creditsLabel.TextSize = size

		titleAccent.BackgroundColor3 = Color3.fromHSV((hue + 0.33) % 1, 1, 1)
		if initScreen.Visible then cardTopLine.BackgroundColor3 = Color3.fromHSV(hue, 1, 1) end
		if infoScreen.Visible then infoTopLine.BackgroundColor3 = Color3.fromHSV(hue, 1, 1) end
		if webhookScreen.Visible then webhookTopLine.BackgroundColor3 = Color3.fromHSV(hue, 1, 1) end
		task.wait(0.03)
	end
end)

player.Idled:Connect(function()
	if not isScriptActive then return end
	statusLabel.Text = "⚡  Kick blocked!"
	task.wait(2)
	statusLabel.Text = "Made with love 💕"
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
	SetExternalUiVisible(false)
	task.wait(0.5)
	for stepIndex, step in ipairs(loadSteps) do
		if not isScriptActive then return end
		loadText.Text = step.text
		pctLabel.Text = math.floor(step.pct * 100) .. "%"
		TweenService:Create(dots[stepIndex], TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(0, 255, 200) }):Play()
		TweenService:Create(loadFill, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(step.pct, 0, 1, 0) }):Play()
		task.wait(0.45)
	end

	if not isScriptActive then return end
	task.wait(0.25)
	badge.Text = "READY"
	task.wait(0.4)

	-- Fade out the card elements, keep dark background to prevent UI gap
	for _, obj in ipairs(initScreen:GetDescendants()) do
		if obj:IsA("TextLabel") then TweenService:Create(obj, TweenInfo.new(0.4, Enum.EasingStyle.Quart), { TextTransparency = 1 }):Play()
		elseif obj:IsA("Frame") then TweenService:Create(obj, TweenInfo.new(0.4, Enum.EasingStyle.Quart), { BackgroundTransparency = 1 }):Play()
		elseif obj:IsA("UIStroke") then TweenService:Create(obj, TweenInfo.new(0.4, Enum.EasingStyle.Quart), { Transparency = 1 }):Play() end
	end
	
	task.wait(0.5)
	
	initScreen.Visible = false
	infoScreen.Visible = true
end)
