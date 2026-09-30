--// ADMIN PANEL LOCALSCRIPT
--// For your own Roblox game / Studio testing

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==================================================
-- DEFAULTS
--==================================================

local DEFAULT_FLY_SPEED = 50
local DEFAULT_WALK_SPEED = 16
local DEFAULT_TPWALK = 2
local DEFAULT_SPIN_SPEED = 180
local DEFAULT_FOV = 70
local DEFAULT_MAX_ZOOM = 128
local DEFAULT_MIN_ZOOM = 0.5

--==================================================
-- STATES
--==================================================

local flyEnabled = false
local noclipEnabled = false
local infiniteJumpEnabled = false
local speedEnabled = false
local spinEnabled = false
local tpwalkEnabled = false
local antiFlingEnabled = false
local fovEnabled = false
local maxZoomEnabled = false
local minZoomEnabled = false

local flingEnabled = false
local espEnabled = false
local loopbringEnabled = false

local pathfinderToolEnabled = false
local pathfindPlayerEnabled = false

--==================================================
-- VALUES
--==================================================

local flySpeed = DEFAULT_FLY_SPEED
local speedValue = DEFAULT_WALK_SPEED
local tpwalkValue = DEFAULT_TPWALK
local spinSpeed = DEFAULT_SPIN_SPEED
local fovValue = DEFAULT_FOV
local maxZoomValue = DEFAULT_MAX_ZOOM
local minZoomValue = DEFAULT_MIN_ZOOM

--==================================================
-- CHARACTER
--==================================================

local character
local humanoid
local rootPart

local function updateCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
end

updateCharacter()

--==================================================
-- CONNECTIONS
--==================================================

local flyConnection
local noclipConnection
local infiniteJumpConnection
local spinConnection
local tpwalkConnection
local antiFlingConnection
local fovConnection
local zoomConnection
local flingConnection
local loopbringConnection
local pathfindPlayerConnection
local pingConnection

--==================================================
-- ORIGINAL VALUES
--==================================================

local originalWalkSpeed = DEFAULT_WALK_SPEED
local originalFOV = DEFAULT_FOV
local originalMaxZoom = DEFAULT_MAX_ZOOM
local originalMinZoom = DEFAULT_MIN_ZOOM

--==================================================
-- TARGET DATA
--==================================================

local selectedTargets = {}

-- Snapshots are taken when features are enabled.
local activeEspTargets = {}
local activeLoopbringTargets = {}
local activeFlingTargets = {}

local savedFlingCFrame = nil
local flingIndex = 1
local flingLastTime = 0

-- Fling orbit settings.
-- 3600 RPM = 60 revolutions per second.
local FLING_ORBIT_RADIUS = 0.3
local FLING_ORBIT_RPM = 3600
local FLING_ORBIT_ANGULAR_SPEED =
    (FLING_ORBIT_RPM / 60) * (math.pi * 2)
local flingOrbitAngle = 0

local loopbringIndex = 1
local loopbringLastTime = 0

local flingRemote =
	ReplicatedStorage:FindFirstChild("AdminFling")

local loopbringRemote =
	ReplicatedStorage:FindFirstChild("AdminLoopbring")

-- Player selected specifically for Pathfind Player.
local pathfindTarget = nil

--==================================================
-- PATHFIND STATE
--==================================================

-- Pathfinder Tool
local toolPathGeneration = 0
local toolPathWaypoints = {}
local toolWaypointIndex = 1
local toolDestination = nil

-- Pathfind Player
local playerPathGeneration = 0
local playerPathWaypoints = {}
local playerWaypointIndex = 1
local playerPathLastCalculation = 0

--==================================================
-- GUI
--==================================================

local oldGui = playerGui:FindFirstChild("CustomAdminPanel")

if oldGui then
	oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomAdminPanel"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.DisplayOrder = 100
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

--==================================================
-- COLORS
--==================================================

local BLUE_DARK = Color3.fromRGB(20, 70, 150)
local BLUE = Color3.fromRGB(40, 110, 220)
local BLUE_LIGHT = Color3.fromRGB(90, 160, 255)
local WHITE = Color3.fromRGB(255, 255, 255)
local DARK = Color3.fromRGB(20, 30, 50)
local GRAY = Color3.fromRGB(180, 190, 205)
local GREEN = Color3.fromRGB(50, 200, 100)
local RED = Color3.fromRGB(220, 70, 70)

--==================================================
-- HELPER FUNCTIONS
--==================================================

local function addCorner(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
	return corner
end

local function addStroke(object, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Parent = object
	return stroke
end

local function makeGradient(object)
	local gradient = Instance.new("UIGradient")

	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, BLUE_DARK),
		ColorSequenceKeypoint.new(1, BLUE_LIGHT)
	})

	gradient.Rotation = 45
	gradient.Parent = object

	return gradient
end

local function createTextButton(parent, text, height)
	local button = Instance.new("TextButton")

	button.Size = UDim2.new(1, 0, 0, height or 38)
	button.BackgroundColor3 = BLUE
	button.TextColor3 = WHITE
	button.Text = text
	button.TextSize = 14
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Parent = parent

	addCorner(button, 8)
	addStroke(button, WHITE, 1)

	return button
end

local function createToggle(parent, text)
	local button =
		createTextButton(parent, text .. ": OFF", 38)

	button:SetAttribute("ToggleName", text)

	return button
end

local function setToggleVisual(button, name, enabled)
	button.Text =
		name .. ": " .. (enabled and "ON" or "OFF")

	if enabled then
		button.BackgroundColor3 = GREEN
	else
		button.BackgroundColor3 = BLUE
	end
end

local function createLabel(parent, text, height)
	local label = Instance.new("TextLabel")

	label.Size = UDim2.new(1, 0, 0, height or 25)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = WHITE
	label.TextSize = 14
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent

	return label
end

local function createNumberBox(parent, placeholder, defaultValue)
	local box = Instance.new("TextBox")

	box.Size = UDim2.new(1, 0, 0, 34)
	box.BackgroundColor3 = Color3.fromRGB(245, 248, 255)
	box.TextColor3 = DARK
	box.PlaceholderColor3 =
		Color3.fromRGB(100, 110, 125)
	box.PlaceholderText = placeholder
	box.Text = tostring(defaultValue)
	box.TextSize = 14
	box.Font = Enum.Font.Gotham
	box.ClearTextOnFocus = false
	box.Parent = parent

	addCorner(box, 7)
	addStroke(box, WHITE, 1)

	return box
end

local function makeDraggable(handle, target)
	local dragging = false
	local dragStart
	local startPosition

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			dragStart = input.Position
			startPosition = target.Position

			input.Changed:Connect(function()
				if input.UserInputState ==
					Enum.UserInputState.End then

					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - dragStart

		target.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end)
end

--==================================================
-- OPEN BUTTON
--==================================================

local openButton = Instance.new("TextButton")

openButton.Name = "OpenButton"
openButton.Size = UDim2.fromOffset(52, 52)
openButton.Position = UDim2.new(0, 15, 0.5, -26)
openButton.BackgroundColor3 = BLUE
openButton.Text = "A"
openButton.TextColor3 = WHITE
openButton.TextSize = 25
openButton.Font = Enum.Font.GothamBlack
openButton.Parent = screenGui

addCorner(openButton, 15)
addStroke(openButton, WHITE, 2)
makeGradient(openButton)

--==================================================
-- MAIN PANEL
--==================================================

local panel = Instance.new("Frame")

panel.Name = "AdminPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.92, 0, 0.82, 0)
panel.BackgroundColor3 = DARK
panel.Parent = screenGui

addCorner(panel, 12)
addStroke(panel, WHITE, 2)

--==================================================
-- MOBILE FLY CONTROLS
--==================================================

local flyControls = Instance.new("Frame")
flyControls.Name = "MobileFlyControls"
flyControls.AnchorPoint = Vector2.new(1, 1)
flyControls.Position = UDim2.new(1, -14, 1, -14)
flyControls.Size = UDim2.fromOffset(150, 105)
flyControls.BackgroundTransparency = 1
flyControls.Visible = false
flyControls.ZIndex = 50
flyControls.Parent = screenGui

local flyUpButton = Instance.new("TextButton")
flyUpButton.Size = UDim2.fromOffset(68, 46)
flyUpButton.Position = UDim2.fromOffset(76, 0)
flyUpButton.BackgroundColor3 = GREEN
flyUpButton.Text = "▲"
flyUpButton.TextColor3 = WHITE
flyUpButton.TextSize = 24
flyUpButton.Font = Enum.Font.GothamBlack
flyUpButton.AutoButtonColor = true
flyUpButton.ZIndex = 51
flyUpButton.Parent = flyControls
addCorner(flyUpButton, 12)
addStroke(flyUpButton, WHITE, 1)

local flyDownButton = Instance.new("TextButton")
flyDownButton.Size = UDim2.fromOffset(68, 46)
flyDownButton.Position = UDim2.fromOffset(76, 53)
flyDownButton.BackgroundColor3 = BLUE
flyDownButton.Text = "▼"
flyDownButton.TextColor3 = WHITE
flyDownButton.TextSize = 24
flyDownButton.Font = Enum.Font.GothamBlack
flyDownButton.AutoButtonColor = true
flyDownButton.ZIndex = 51
flyDownButton.Parent = flyControls
addCorner(flyDownButton, 12)
addStroke(flyDownButton, WHITE, 1)

local function bindHoldButton(button, setter)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			setter(true)
		end
	end)

	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			setter(false)
		end
	end)
end

bindHoldButton(flyUpButton, function(value)
	flyUpHeld = value
end)

bindHoldButton(flyDownButton, function(value)
	flyDownHeld = value
end)

--==================================================
-- TITLE BAR
--==================================================

local titleBar = Instance.new("Frame")

titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = BLUE_DARK
titleBar.Parent = panel

addCorner(titleBar, 12)

local title = Instance.new("TextLabel")

title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(12, 0)
title.Size = UDim2.new(0, 130, 1, 0)
title.Text = "ADMIN PANEL"
title.TextColor3 = WHITE
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

--==================================================
-- PING
--==================================================

local pingLabel = Instance.new("TextLabel")

pingLabel.BackgroundTransparency = 1
pingLabel.Position = UDim2.fromOffset(145, 0)
pingLabel.Size = UDim2.new(0, 105, 1, 0)
pingLabel.Text = "Ping: -- ms"
pingLabel.TextColor3 = WHITE
pingLabel.TextSize = 13
pingLabel.Font = Enum.Font.GothamBold
pingLabel.TextXAlignment = Enum.TextXAlignment.Left
pingLabel.Parent = titleBar

local minimizeButton = Instance.new("TextButton")

minimizeButton.Size = UDim2.fromOffset(40, 35)
minimizeButton.Position = UDim2.new(1, -85, 0, 5)
minimizeButton.BackgroundColor3 = BLUE
minimizeButton.Text = "−"
minimizeButton.TextColor3 = WHITE
minimizeButton.TextSize = 22
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.Parent = titleBar

addCorner(minimizeButton, 7)

local closeButton = Instance.new("TextButton")

closeButton.Size = UDim2.fromOffset(40, 35)
closeButton.Position = UDim2.new(1, -43, 0, 5)
closeButton.BackgroundColor3 = RED
closeButton.Text = "X"
closeButton.TextColor3 = WHITE
closeButton.TextSize = 15
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = titleBar

addCorner(closeButton, 7)

makeDraggable(titleBar, panel)

--==================================================
-- CONTENT AREA
--==================================================

local sideBar = Instance.new("Frame")

sideBar.Position = UDim2.new(0, 0, 0, 45)
sideBar.Size = UDim2.new(0, 100, 1, -45)
sideBar.BackgroundColor3 = Color3.fromRGB(25, 45, 80)
sideBar.Parent = panel

local tabContent = Instance.new("Frame")

tabContent.Position = UDim2.new(0, 100, 0, 45)
tabContent.Size = UDim2.new(1, -100, 1, -45)
tabContent.BackgroundTransparency = 1
tabContent.Parent = panel

--==================================================
-- TABS
--==================================================

local mainTabButton =
	createTextButton(sideBar, "Main", 42)

mainTabButton.Position = UDim2.fromOffset(7, 10)
mainTabButton.Size = UDim2.new(1, -14, 0, 42)

local targetTabButton =
	createTextButton(sideBar, "Target", 42)

targetTabButton.Position = UDim2.fromOffset(7, 60)
targetTabButton.Size = UDim2.new(1, -14, 0, 42)

local mainPage = Instance.new("ScrollingFrame")

mainPage.Size = UDim2.fromScale(1, 1)
mainPage.BackgroundTransparency = 1
mainPage.BorderSizePixel = 0
mainPage.ScrollBarThickness = 5
mainPage.CanvasSize = UDim2.new()
mainPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
mainPage.Parent = tabContent

local mainLayout = Instance.new("UIListLayout")

mainLayout.Padding = UDim.new(0, 7)
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Parent = mainPage

local mainPadding = Instance.new("UIPadding")

mainPadding.PaddingTop = UDim.new(0, 10)
mainPadding.PaddingBottom = UDim.new(0, 10)
mainPadding.PaddingLeft = UDim.new(0, 10)
mainPadding.PaddingRight = UDim.new(0, 10)
mainPadding.Parent = mainPage

local targetPage = Instance.new("ScrollingFrame")

targetPage.Size = UDim2.fromScale(1, 1)
targetPage.BackgroundTransparency = 1
targetPage.BorderSizePixel = 0
targetPage.ScrollBarThickness = 5
targetPage.CanvasSize = UDim2.new()
targetPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
targetPage.Visible = false
targetPage.Parent = tabContent

local targetLayout = Instance.new("UIListLayout")

targetLayout.Padding = UDim.new(0, 7)
targetLayout.SortOrder = Enum.SortOrder.Name
targetLayout.Parent = targetPage

local targetPadding = Instance.new("UIPadding")

targetPadding.PaddingTop = UDim.new(0, 10)
targetPadding.PaddingBottom = UDim.new(0, 10)
targetPadding.PaddingLeft = UDim.new(0, 10)
targetPadding.PaddingRight = UDim.new(0, 10)
targetPadding.Parent = targetPage

local function showTab(name)
	if name == "Main" then
		mainPage.Visible = true
		targetPage.Visible = false

		mainTabButton.BackgroundColor3 = GREEN
		targetTabButton.BackgroundColor3 = BLUE
	else
		mainPage.Visible = false
		targetPage.Visible = true

		mainTabButton.BackgroundColor3 = BLUE
		targetTabButton.BackgroundColor3 = GREEN
	end
end

--==================================================
-- RESPONSIVE / MOBILE LAYOUT
--==================================================

local function updateResponsiveLayout()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
	local mobile = UserInputService.TouchEnabled and viewport.X <= 800

	if mobile then
		panel.Size = UDim2.new(0.96, 0, 0.88, 0)
		titleBar.Size = UDim2.new(1, 0, 0, 50)
		title.TextSize = 14
		title.Size = UDim2.new(0, 115, 1, 0)
		pingLabel.Visible = false
		minimizeButton.Size = UDim2.fromOffset(42, 40)
		minimizeButton.Position = UDim2.new(1, -92, 0, 5)
		closeButton.Size = UDim2.fromOffset(42, 40)
		closeButton.Position = UDim2.new(1, -46, 0, 5)

		-- Put tabs across the top so the content has useful width.
		sideBar.Position = UDim2.new(0, 0, 0, 50)
		sideBar.Size = UDim2.new(1, 0, 0, 50)
		tabContent.Position = UDim2.new(0, 0, 0, 100)
		tabContent.Size = UDim2.new(1, 0, 1, -100)

		mainTabButton.Position = UDim2.fromOffset(7, 4)
		mainTabButton.Size = UDim2.new(0.5, -10, 0, 42)
		targetTabButton.Position = UDim2.new(0.5, 3, 0, 4)
		targetTabButton.Size = UDim2.new(0.5, -10, 0, 42)

		flyControls.Visible = flyEnabled
	else
		panel.Size = UDim2.new(0.92, 0, 0.82, 0)
		titleBar.Size = UDim2.new(1, 0, 0, 45)
		title.TextSize = 16
		title.Size = UDim2.new(0, 130, 1, 0)
		pingLabel.Visible = true
		minimizeButton.Size = UDim2.fromOffset(40, 35)
		minimizeButton.Position = UDim2.new(1, -85, 0, 5)
		closeButton.Size = UDim2.fromOffset(40, 35)
		closeButton.Position = UDim2.new(1, -43, 0, 5)

		sideBar.Position = UDim2.new(0, 0, 0, 45)
		sideBar.Size = UDim2.new(0, 100, 1, -45)
		tabContent.Position = UDim2.new(0, 100, 0, 45)
		tabContent.Size = UDim2.new(1, -100, 1, -45)

		mainTabButton.Position = UDim2.fromOffset(7, 10)
		mainTabButton.Size = UDim2.new(1, -14, 0, 42)
		targetTabButton.Position = UDim2.fromOffset(7, 60)
		targetTabButton.Size = UDim2.new(1, -14, 0, 42)

		flyControls.Visible = false
	end
end

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveLayout)
end

mainTabButton.MouseButton1Click:Connect(function()
	showTab("Main")
end)

targetTabButton.MouseButton1Click:Connect(function()
	showTab("Target")
end)

showTab("Main")

--==================================================
-- MAIN TAB
--==================================================

local flyToggle = createToggle(mainPage, "Fly")
local flySpeedBox =
	createNumberBox(mainPage, "Fly Speed", DEFAULT_FLY_SPEED)

local noclipToggle =
	createToggle(mainPage, "Noclip")

local infiniteJumpToggle =
	createToggle(mainPage, "Infinite Jump")

local speedToggle =
	createToggle(mainPage, "Speed")

local speedBox =
	createNumberBox(mainPage, "Walk Speed", DEFAULT_WALK_SPEED)

local spinToggle =
	createToggle(mainPage, "Spin")

local spinBox =
	createNumberBox(mainPage, "Spin Speed", DEFAULT_SPIN_SPEED)

local tpwalkToggle =
	createToggle(mainPage, "TPWalk")

local tpwalkBox =
	createNumberBox(mainPage, "TPWalk Speed", DEFAULT_TPWALK)

createLabel(mainPage, "Chat", 25)

local sayBox = Instance.new("TextBox")

sayBox.Size = UDim2.new(1, 0, 0, 38)
sayBox.BackgroundColor3 = Color3.fromRGB(245, 248, 255)
sayBox.TextColor3 = DARK
sayBox.PlaceholderText = "Type a message..."
sayBox.Text = ""
sayBox.TextSize = 14
sayBox.Font = Enum.Font.Gotham
sayBox.ClearTextOnFocus = false
sayBox.Parent = mainPage

addCorner(sayBox, 7)
addStroke(sayBox, WHITE, 1)

local sayButton =
	createTextButton(mainPage, "Say", 38)

local antiFlingToggle =
	createToggle(mainPage, "AntiFling")

local fovToggle =
	createToggle(mainPage, "FOV")

local fovBox =
	createNumberBox(mainPage, "FOV", DEFAULT_FOV)

local maxZoomToggle =
	createToggle(mainPage, "MaxZoom")

local maxZoomBox =
	createNumberBox(mainPage, "Max Zoom", DEFAULT_MAX_ZOOM)

local minZoomToggle =
	createToggle(mainPage, "MinZoom")

local minZoomBox =
	createNumberBox(mainPage, "Min Zoom", DEFAULT_MIN_ZOOM)

--==================================================
-- PATHFINDER TOOL
--==================================================

local pathfinderToolToggle =
	createToggle(mainPage, "Pathfinder Tool")

createLabel(
	mainPage,
	"Player Pathfind Search",
	25
)

local pathfindSearchBox = Instance.new("TextBox")

pathfindSearchBox.Size =
	UDim2.new(1, 0, 0, 38)

pathfindSearchBox.BackgroundColor3 =
	Color3.fromRGB(245, 248, 255)

pathfindSearchBox.TextColor3 = DARK

pathfindSearchBox.PlaceholderColor3 =
	Color3.fromRGB(100, 110, 125)

pathfindSearchBox.PlaceholderText =
	"Type username, e.g. Ric"

pathfindSearchBox.Text = ""
pathfindSearchBox.TextSize = 14
pathfindSearchBox.Font = Enum.Font.Gotham
pathfindSearchBox.ClearTextOnFocus = false
pathfindSearchBox.Parent = mainPage

addCorner(pathfindSearchBox, 7)
addStroke(pathfindSearchBox, WHITE, 1)

local pathfindResults = Instance.new("Frame")

pathfindResults.Size =
	UDim2.new(1, 0, 0, 0)

pathfindResults.BackgroundTransparency = 1
pathfindResults.AutomaticSize = Enum.AutomaticSize.Y
pathfindResults.Parent = mainPage

local pathfindResultsLayout =
	Instance.new("UIListLayout")

pathfindResultsLayout.Padding = UDim.new(0, 4)
pathfindResultsLayout.SortOrder = Enum.SortOrder.Name
pathfindResultsLayout.Parent = pathfindResults

local pathfindTargetLabel =
	createLabel(
		mainPage,
		"Pathfind Target: NONE",
		25
	)

local pathfindPlayerToggle =
	createToggle(
		mainPage,
		"Pathfind Player"
	)

--==================================================
-- CHARACTER HELPERS
--==================================================

local function getAliveCharacter(targetPlayer)
	if not targetPlayer then
		return nil, nil
	end

	local targetCharacter =
		targetPlayer.Character

	if not targetCharacter then
		return nil, nil
	end

	local targetHumanoid =
		targetCharacter:FindFirstChildOfClass("Humanoid")

	local targetRoot =
		targetCharacter:FindFirstChild("HumanoidRootPart")

	if not targetHumanoid or not targetRoot then
		return nil, nil
	end

	if targetHumanoid.Health <= 0 then
		return nil, nil
	end

	return targetCharacter, targetRoot
end

--==================================================
-- FLY
--==================================================

local flyUpHeld = false
local flyDownHeld = false

local function stopFly()
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end

	flyUpHeld = false
	flyDownHeld = false

	if humanoid then
		humanoid.PlatformStand = false
	end

	if rootPart then
		rootPart.AssemblyLinearVelocity = Vector3.zero
	end
end

local function startFly()
	stopFly()

	if not humanoid or not rootPart then
		return
	end

	-- The Humanoid's MoveDirection is already camera/joystick-relative,
	-- so it works with both keyboard movement and the mobile thumbstick.
	flyConnection = RunService.RenderStepped:Connect(function()
		if not flyEnabled or not character or not humanoid or not rootPart then
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		humanoid.PlatformStand = true

		local moveDirection = humanoid.MoveDirection
		local direction = Vector3.zero

		if moveDirection.Magnitude > 0.001 then
			-- Preserve the exact direction the player is moving in,
			-- including the mobile joystick's diagonal movement.
			direction = moveDirection.Unit
		end

		-- PC vertical controls.
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			direction += Vector3.yAxis
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
			or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			direction -= Vector3.yAxis
		end

		-- Mobile vertical controls.
		if flyUpHeld then
			direction += Vector3.yAxis
		end

		if flyDownHeld then
			direction -= Vector3.yAxis
		end

		if direction.Magnitude > 0.001 then
			rootPart.AssemblyLinearVelocity = direction.Unit * flySpeed
		else
			rootPart.AssemblyLinearVelocity = Vector3.zero
		end
	end)
end

--==================================================
-- NOCLIP
--==================================================

local function stopNoclip()
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end

	if character then
		for _, object in ipairs(
			character:GetDescendants()
		) do
			if object:IsA("BasePart") then
				object.CanCollide = true
			end
		end
	end
end

local function startNoclip()
	stopNoclip()

	noclipConnection =
		RunService.Stepped:Connect(function()
			if not noclipEnabled
				or not character then
				return
			end

			for _, object in ipairs(
				character:GetDescendants()
			) do
				if object:IsA("BasePart") then
					object.CanCollide = false
				end
			end
		end)
end

--==================================================
-- INFINITE JUMP
--==================================================

local function stopInfiniteJump()
	if infiniteJumpConnection then
		infiniteJumpConnection:Disconnect()
		infiniteJumpConnection = nil
	end
end

local function startInfiniteJump()
	stopInfiniteJump()

	infiniteJumpConnection =
		UserInputService.JumpRequest:Connect(
			function()
				if infiniteJumpEnabled
					and humanoid then

					humanoid:ChangeState(
						Enum.HumanoidStateType.Jumping
					)
				end
			end
		)
end

--==================================================
-- SPEED
--==================================================

local function applySpeed()
	if humanoid then
		humanoid.WalkSpeed =
			speedEnabled
			and speedValue
			or originalWalkSpeed
	end
end

--==================================================
-- SPIN
--==================================================

local function stopSpin()
	if spinConnection then
		spinConnection:Disconnect()
		spinConnection = nil
	end
end

local function startSpin()
	stopSpin()

	spinConnection =
		RunService.RenderStepped:Connect(
			function(deltaTime)
				if not spinEnabled
					or not rootPart then
					return
				end

				rootPart.CFrame =
					rootPart.CFrame *
					CFrame.Angles(
						0,
						math.rad(spinSpeed)
							* deltaTime,
						0
					)
			end
		)
end

--==================================================
-- TPWALK
--==================================================

local function stopTPWalk()
	if tpwalkConnection then
		tpwalkConnection:Disconnect()
		tpwalkConnection = nil
	end
end

local function startTPWalk()
	stopTPWalk()

	tpwalkConnection =
		RunService.Heartbeat:Connect(
			function()
				if not tpwalkEnabled then
					return
				end

				if not character
					or not humanoid
					or not rootPart then
					return
				end

				local moveDirection =
					humanoid.MoveDirection

				if moveDirection.Magnitude > 0 then
					rootPart.CFrame =
						rootPart.CFrame +
						moveDirection * tpwalkValue
				end
			end
		)
end

--==================================================
-- ANTI FLING
--==================================================

local function stopAntiFling()
	if antiFlingConnection then
		antiFlingConnection:Disconnect()
		antiFlingConnection = nil
	end
end

local function startAntiFling()
	stopAntiFling()

	antiFlingConnection =
		RunService.Heartbeat:Connect(
			function()
				if not antiFlingEnabled
					or not rootPart then
					return
				end

				local velocity =
					rootPart.AssemblyLinearVelocity

				if velocity.Magnitude > 100 then
					rootPart.AssemblyLinearVelocity =
						velocity.Unit * 100
				end

				local angular =
					rootPart.AssemblyAngularVelocity

				if angular.Magnitude > 100 then
					rootPart.AssemblyAngularVelocity =
						angular.Unit * 100
				end
			end
		)
end

--==================================================
-- FOV
--==================================================

local function stopFOV()
	if fovConnection then
		fovConnection:Disconnect()
		fovConnection = nil
	end

	local camera =
		workspace.CurrentCamera

	if camera then
		camera.FieldOfView = originalFOV
	end
end

local function startFOV()
	stopFOV()

	local camera =
		workspace.CurrentCamera

	if camera then
		originalFOV = camera.FieldOfView
	end

	fovConnection =
		RunService.RenderStepped:Connect(
			function()
				if not fovEnabled then
					return
				end

				local currentCamera =
					workspace.CurrentCamera

				if currentCamera then
					currentCamera.FieldOfView =
						fovValue
				end
			end
		)
end

--==================================================
-- ZOOM
--==================================================

local function stopZoom()
	if zoomConnection then
		zoomConnection:Disconnect()
		zoomConnection = nil
	end

	player.CameraMaxZoomDistance =
		originalMaxZoom

	player.CameraMinZoomDistance =
		originalMinZoom
end

local function startZoom()
	stopZoom()

	originalMaxZoom =
		player.CameraMaxZoomDistance

	originalMinZoom =
		player.CameraMinZoomDistance

	zoomConnection =
		RunService.RenderStepped:Connect(
			function()
				if maxZoomEnabled then
					player.CameraMaxZoomDistance =
						maxZoomValue
				end

				if minZoomEnabled then
					player.CameraMinZoomDistance =
						minZoomValue
				end
			end
		)
end

--==================================================
-- TARGET SELECTION
--==================================================

local targetRows = {}

local function isSelected(targetPlayer)
	return selectedTargets[targetPlayer] == true
end

local function selectTarget(targetPlayer)
	selectedTargets[targetPlayer] = true
end

local function deselectTarget(targetPlayer)
	selectedTargets[targetPlayer] = nil
end

local function getSortedSelectedTargets()
	local list = {}

	for targetPlayer, selected in pairs(
		selectedTargets
	) do
		if selected
			and targetPlayer.Parent == Players then

			table.insert(list, targetPlayer)
		end
	end

	table.sort(list, function(a, b)
		return string.lower(a.Name)
			< string.lower(b.Name)
	end)

	return list
end

--==================================================
-- TARGET PAGE
--==================================================

local targetInfo =
	createLabel(
		targetPage,
		"Select player(s) for Fling, ESP and Loopbring.",
		40
	)

targetInfo.TextWrapped = true

local targetListFrame =
	Instance.new("Frame")

targetListFrame.Size =
	UDim2.new(1, 0, 0, 0)

targetListFrame.BackgroundTransparency = 1
targetListFrame.AutomaticSize = Enum.AutomaticSize.Y
targetListFrame.Parent = targetPage

local targetListLayout =
	Instance.new("UIListLayout")

targetListLayout.Padding = UDim.new(0, 5)
targetListLayout.SortOrder = Enum.SortOrder.Name
targetListLayout.Parent = targetListFrame

local function refreshTargetButton(targetPlayer)
	local row = targetRows[targetPlayer]

	if not row then
		return
	end

	if isSelected(targetPlayer) then
		row.Text =
			targetPlayer.Name ..
			"  [SELECTED]"

		row.BackgroundColor3 = GREEN
	else
		row.Text = targetPlayer.Name
		row.BackgroundColor3 = BLUE
	end
end

local function createPlayerButton(targetPlayer)
	local row =
		createTextButton(
			targetListFrame,
			targetPlayer.Name,
			36
		)

	targetRows[targetPlayer] = row

	row.MouseButton1Click:Connect(function()
		if isSelected(targetPlayer) then
			deselectTarget(targetPlayer)
		else
			selectTarget(targetPlayer)
		end

		refreshTargetButton(targetPlayer)
	end)

	refreshTargetButton(targetPlayer)
end

local function rebuildTargetList()
	for targetPlayer, row in pairs(
		targetRows
	) do
		if row then
			row:Destroy()
		end

		targetRows[targetPlayer] = nil
	end

	local players =
		Players:GetPlayers()

	table.sort(players, function(a, b)
		return string.lower(a.Name)
			< string.lower(b.Name)
	end)

	for _, targetPlayer in ipairs(players) do
		if targetPlayer ~= player then
			createPlayerButton(targetPlayer)
		end
	end
end

--==================================================
-- ESP
--==================================================

local espObjects = {}

local function removeESP(targetPlayer)
	local object =
		espObjects[targetPlayer]

	if object then
		object:Destroy()
		espObjects[targetPlayer] = nil
	end
end

local function createESP(targetPlayer)
	if targetPlayer == player then
		return
	end

	removeESP(targetPlayer)

	local targetCharacter =
		targetPlayer.Character

	if not targetCharacter then
		return
	end

	local highlight =
		Instance.new("Highlight")

	highlight.Name = "AdminESP"
	highlight.FillTransparency = 0.65
	highlight.OutlineTransparency = 0
	highlight.DepthMode =
		Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = targetCharacter
	highlight.Parent = targetCharacter

	espObjects[targetPlayer] =
		highlight
end

local function clearAllESP()
	for targetPlayer in pairs(
		espObjects
	) do
		removeESP(targetPlayer)
	end

	table.clear(activeEspTargets)
end

local function startESP()
	clearAllESP()

	local selected =
		getSortedSelectedTargets()

	for _, targetPlayer in ipairs(
		selected
	) do
		activeEspTargets[targetPlayer] =
			true

		createESP(targetPlayer)
	end
end

local function stopESP()
	clearAllESP()
end

--==================================================
-- FLING
--==================================================

local function saveFlingPosition()
	if rootPart then
		savedFlingCFrame =
			rootPart.CFrame
	end
end

local function restoreFlingPosition()
	if not savedFlingCFrame then
		return
	end

	if not rootPart then
		savedFlingCFrame = nil
		return
	end

	rootPart.CFrame =
		savedFlingCFrame

	rootPart.AssemblyLinearVelocity =
		Vector3.zero

	rootPart.AssemblyAngularVelocity =
		Vector3.zero

	savedFlingCFrame = nil
end

local function localPlayerFling(targetPlayer, deltaTime)
	if not rootPart then
		return false
	end

	local _, targetRoot = getAliveCharacter(targetPlayer)
	if not targetRoot then
		return false
	end

	-- Keep the local player on a tiny circular path around the target.
	-- The angle advances at exactly 3600 RPM (60 revolutions/second).
	flingOrbitAngle =
		(flingOrbitAngle + FLING_ORBIT_ANGULAR_SPEED * deltaTime)
		% (math.pi * 2)

	local offset =
		Vector3.new(
			math.cos(flingOrbitAngle) * FLING_ORBIT_RADIUS,
			0,
			math.sin(flingOrbitAngle) * FLING_ORBIT_RADIUS
		)

	local orbitPosition = targetRoot.Position + offset

	-- Face the target while orbiting around it.
	rootPart.CFrame =
		CFrame.lookAt(
			orbitPosition,
			targetRoot.Position
		)

	-- Match the requested orbital speed physically as well.
	rootPart.AssemblyLinearVelocity =
		Vector3.new(
			-math.sin(flingOrbitAngle),
			0,
			math.cos(flingOrbitAngle)
		) * (
			FLING_ORBIT_ANGULAR_SPEED *
			FLING_ORBIT_RADIUS
		)

	rootPart.AssemblyAngularVelocity =
		Vector3.new(
			0,
			FLING_ORBIT_ANGULAR_SPEED,
			0
		)

	return true
end

local function flingTarget(targetPlayer, deltaTime)
	if not targetPlayer
		or targetPlayer.Parent ~= Players then
		return false
	end

	return localPlayerFling(
		 targetPlayer,
		 deltaTime
	)
end

local function getActiveFlingList()
	local list = {}

	for targetPlayer in pairs(
		activeFlingTargets
	) do
		if targetPlayer.Parent == Players then
			table.insert(list, targetPlayer)
		end
	end

	table.sort(list, function(a, b)
		return string.lower(a.Name)
			< string.lower(b.Name)
	end)

	return list
end

local function startFling()
	if flingConnection then
		flingConnection:Disconnect()
	end

	saveFlingPosition()

	flingIndex = 1
	flingLastTime = 0
	flingOrbitAngle = 0

	flingConnection =
		RunService.Heartbeat:Connect(
			function(deltaTime)
				if not flingEnabled then
					return
				end

				local targets =
					getActiveFlingList()

				if #targets == 0 then
					return
				end

				if flingIndex > #targets then
					flingIndex = 1
				end

				local currentTarget =
					targets[flingIndex]

				-- Orbit the active target continuously.
				-- With one selected target this is a continuous
				-- 3600 RPM orbit at a 0.3 stud radius.
				if not flingTarget(
					currentTarget,
					deltaTime
				) then
					flingIndex += 1
					flingOrbitAngle = 0
				end
			end
		)
end

local function stopFling()
	if flingConnection then
		flingConnection:Disconnect()
		flingConnection = nil
	end

	flingOrbitAngle = 0

	if rootPart then
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end

	restoreFlingPosition()
end

--==================================================
-- LOOPBRING
-- SERVER FIRST / CFRAME FALLBACK
--==================================================

local function cframeBringTarget(targetPlayer)
	if not rootPart then
		return
	end

	local targetCharacter, targetRoot =
		getAliveCharacter(targetPlayer)

	if not targetCharacter
		or not targetRoot then
		return
	end

	-- Client-side CFrame fallback.
	-- This can only reliably affect another player's
	-- character if the game/network ownership allows it.
	local desiredCFrame =
		rootPart.CFrame *
		CFrame.new(0, 0, -4)

	pcall(function()
		targetCharacter:PivotTo(
			desiredCFrame
		)
	end)
end

local function loopbringTarget(targetPlayer)
	if not targetPlayer
		or targetPlayer.Parent ~= Players then
		return
	end

	-- Preferred method:
	-- server moves the target to the admin.
	if loopbringRemote
		and loopbringRemote:IsA("RemoteEvent") then

		loopbringRemote:FireServer(
			targetPlayer
		)

		-- Give the server method a chance to
		-- perform the operation.
		task.delay(0.08, function()
			if not loopbringEnabled then
				return
			end

			if targetPlayer.Parent ~= Players then
				return
			end

			local _, targetRoot =
				getAliveCharacter(targetPlayer)

			if not targetRoot or not rootPart then
				return
			end

			-- If the target is still far away,
			-- attempt the CFrame fallback.
			if (
				targetRoot.Position -
				rootPart.Position
			).Magnitude > 8 then

				cframeBringTarget(
					targetPlayer
				)
			end
		end)

	else
		-- No server RemoteEvent exists.
		cframeBringTarget(targetPlayer)
	end
end

local function getActiveLoopbringList()
	local list = {}

	for targetPlayer in pairs(
		activeLoopbringTargets
	) do
		if targetPlayer.Parent == Players then
			table.insert(list, targetPlayer)
		end
	end

	table.sort(list, function(a, b)
		return string.lower(a.Name)
			< string.lower(b.Name)
	end)

	return list
end

local function startLoopbring()
	if loopbringConnection then
		loopbringConnection:Disconnect()
	end

	loopbringIndex = 1
	loopbringLastTime = 0

	loopbringConnection =
		RunService.Heartbeat:Connect(
			function()
				if not loopbringEnabled then
					return
				end

				local targets =
					getActiveLoopbringList()

				if #targets == 0 then
					return
				end

				local now = os.clock()

				if now -
					loopbringLastTime >= 0.25 then

					loopbringLastTime =
						now

					if loopbringIndex > #targets then
						loopbringIndex = 1
					end

					loopbringTarget(
						targets[loopbringIndex]
					)

					loopbringIndex += 1
				end
			end
		)
end

local function stopLoopbring()
	if loopbringConnection then
		loopbringConnection:Disconnect()
		loopbringConnection = nil
	end

	table.clear(activeLoopbringTargets)
end

--==================================================
-- PATHFINDER TOOL
--==================================================

local pathfinderTool

local function clearToolPath()
	toolPathGeneration += 1

	toolPathWaypoints = {}
	toolWaypointIndex = 1
	toolDestination = nil

	if humanoid then
		humanoid:MoveTo(
			rootPart and rootPart.Position
				or Vector3.zero
		)
	end
end

local function computeToolPath(destination)
	if not rootPart then
		return nil
	end

	local path =
		PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = true,
			AgentCanClimb = true
		})

	local success =
		pcall(function()
			path:ComputeAsync(
				rootPart.Position,
				destination
			)
		end)

	if success
		and path.Status ==
			Enum.PathStatus.Success then

		return path:GetWaypoints()
	end

	return nil
end

local function startToolPath(destination)
	-- Every new click gets a completely new
	-- generation number.
	toolPathGeneration += 1

	local thisGeneration =
		toolPathGeneration

	toolDestination =
		destination

	toolPathWaypoints = {}
	toolWaypointIndex = 1

	if not humanoid
		or humanoid.Health <= 0 then
		return
	end

	local waypoints =
		computeToolPath(destination)

	if thisGeneration ~=
		toolPathGeneration then
		return
	end

	if waypoints
		and #waypoints > 0 then

		toolPathWaypoints =
			waypoints

		toolWaypointIndex = 2
	else
		toolPathWaypoints = {}
		toolWaypointIndex = 1
	end

	task.spawn(function()
		while
			pathfinderToolEnabled
			and thisGeneration ==
				toolPathGeneration
		do
			if not humanoid
				or humanoid.Health <= 0 then
				break
			end

			local waypoint =
				toolPathWaypoints[
					toolWaypointIndex
				]

			if waypoint then
				if waypoint.Action ==
					Enum.PathWaypointAction.Jump then

					humanoid.Jump = true
				end

				humanoid:MoveTo(
					waypoint.Position
				)

				local distance =
					(
						rootPart.Position -
						waypoint.Position
					).Magnitude

				if distance < 4 then
					toolWaypointIndex += 1
				end
			else
				if toolDestination then
					humanoid:MoveTo(
						toolDestination
					)

					if (
						rootPart.Position -
						toolDestination
					).Magnitude < 4 then

						break
					end
				end
			end

			task.wait(0.08)
		end
	end)
end

local function removePathfinderTool()
	clearToolPath()

	if pathfinderTool then
		pathfinderTool:Destroy()
		pathfinderTool = nil
	end
end

local function createPathfinderTool()
	removePathfinderTool()

	local backpack =
		player:FindFirstChildOfClass(
			"Backpack"
		)

	if not backpack then
		return
	end

	local tool = Instance.new("Tool")

	tool.Name = "Pathfinder"
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool.ToolTip = "Click to move"
	tool.Parent = backpack

	pathfinderTool = tool

	tool.Activated:Connect(function()
		if not pathfinderToolEnabled then
			return
		end

		local mouse =
			player:GetMouse()

		if not mouse
			or not mouse.Hit then
			return
		end

		local destination =
			mouse.Hit.Position

		-- IMPORTANT:
		-- This immediately replaces the previous point.
		startToolPath(destination)
	end)
end

local function setPathfinderTool(enabled)
	pathfinderToolEnabled =
		enabled

	if enabled then
		createPathfinderTool()
	else
		removePathfinderTool()
	end
end

--==================================================
-- PLAYER SEARCH
--==================================================

local function clearPathfindResults()
	for _, object in ipairs(
		pathfindResults:GetChildren()
	) do
		if object:IsA("TextButton") then
			object:Destroy()
		end
	end
end

local function updatePathfindTargetLabel()
	if pathfindTarget
		and pathfindTarget.Parent == Players then

		pathfindTargetLabel.Text =
			"Pathfind Target: " ..
			pathfindTarget.Name
	else
		pathfindTarget = nil

		pathfindTargetLabel.Text =
			"Pathfind Target: NONE"
	end
end

--==================================================
-- PATHFIND PLAYER
--==================================================

local function clearPlayerPath()
	-- Invalidate every old path task.
	playerPathGeneration += 1

	playerPathWaypoints = {}
	playerWaypointIndex = 1
	playerPathLastCalculation = 0

	if humanoid and rootPart then
		humanoid:MoveTo(
			rootPart.Position
		)
	end
end

local function setPathfindTarget(newTarget)
	-- Immediately invalidate the old target/path.
	clearPlayerPath()

	pathfindTarget = newTarget

	updatePathfindTargetLabel()

	-- If Pathfind Player is currently ON,
	-- immediately begin following the new target.
	if pathfindPlayerEnabled
		and pathfindTarget then

		playerPathLastCalculation = 0
	end
end

local function calculatePlayerPath()
	if not pathfindPlayerEnabled
		or not pathfindTarget
		or pathfindTarget.Parent ~= Players
		or not rootPart
		or not humanoid then

		return false
	end

	local _, targetRoot =
		getAliveCharacter(
			pathfindTarget
		)

	if not targetRoot then
		clearPlayerPath()
		return false
	end

	local path =
		PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = true,
			AgentCanClimb = true
		})

	local success =
		pcall(function()
			path:ComputeAsync(
				rootPart.Position,
				targetRoot.Position
			)
		end)

	if success
		and path.Status ==
			Enum.PathStatus.Success then

		playerPathWaypoints =
			path:GetWaypoints()

		playerWaypointIndex = 2
	else
		playerPathWaypoints = {}
		playerWaypointIndex = 1
	end

	playerPathLastCalculation =
		os.clock()

	return true
end

local function updatePlayerPathfind()
	if not pathfindPlayerEnabled then
		return
	end

	if not pathfindTarget
		or pathfindTarget.Parent ~= Players then

		pathfindPlayerEnabled = false

		setToggleVisual(
			pathfindPlayerToggle,
			"Pathfind Player",
			false
		)

		pathfindTarget = nil
		clearPlayerPath()
		updatePathfindTargetLabel()

		return
	end

	if not rootPart
		or not humanoid
		or humanoid.Health <= 0 then
		return
	end

	local _, targetRoot =
		getAliveCharacter(
			pathfindTarget
		)

	if not targetRoot then
		clearPlayerPath()
		return
	end

	-- Recalculate frequently so moving targets
	-- are continuously followed.
	if os.clock() -
		playerPathLastCalculation >= 0.35
		or #playerPathWaypoints == 0 then

		calculatePlayerPath()
	end

	local waypoint =
		playerPathWaypoints[
			playerWaypointIndex
		]

	if waypoint then
		local distance =
			(
				rootPart.Position -
				waypoint.Position
			).Magnitude

		if distance < 4 then
			playerWaypointIndex += 1

			waypoint =
				playerPathWaypoints[
					playerWaypointIndex
				]
		end

		if waypoint then
			if waypoint.Action ==
				Enum.PathWaypointAction.Jump then

				humanoid.Jump = true
			end

			humanoid:MoveTo(
				waypoint.Position
			)

			return
		end
	end

	-- No waypoint left:
	-- directly follow the CURRENT target.
	humanoid:MoveTo(
		targetRoot.Position
	)
end

local function stopPathfindPlayer()
	if pathfindPlayerConnection then
		pathfindPlayerConnection:Disconnect()
		pathfindPlayerConnection = nil
	end

	clearPlayerPath()
end

local function startPathfindPlayer()
	stopPathfindPlayer()

	if not pathfindTarget then
		return
	end

	pathfindPlayerEnabled = true
	playerPathLastCalculation = 0

	pathfindPlayerConnection =
		RunService.Heartbeat:Connect(
			updatePlayerPathfind
		)
end

local function createPathfindResult(targetPlayer)
	local button =
		createTextButton(
			pathfindResults,
			targetPlayer.Name,
			34
		)

	button.MouseButton1Click:Connect(function()
		-- ONLY ONE Pathfind Player target.
		--
		-- If Pathfind Player is already ON,
		-- the old path is immediately deleted
		-- and the new player becomes the target.

		setPathfindTarget(
			targetPlayer
		)
	end)
end

local function updatePathfindSearch()
	clearPathfindResults()

	local search =
		string.lower(
			pathfindSearchBox.Text
		)

	if search == "" then
		return
	end

	local matches = {}

	for _, targetPlayer in ipairs(
		Players:GetPlayers()
	) do
		if targetPlayer ~= player then
			local username =
				string.lower(
					targetPlayer.Name
				)

			if string.sub(
				username,
				1,
				#search
			) == search then

				table.insert(
					matches,
					targetPlayer
				)
			end
		end
	end

	table.sort(matches, function(a, b)
		return string.lower(a.Name)
			< string.lower(b.Name)
	end)

	for _, targetPlayer in ipairs(
		matches
	) do
		createPathfindResult(
			targetPlayer
		)
	end
end

pathfindSearchBox:
	GetPropertyChangedSignal("Text"):
	Connect(updatePathfindSearch)

--==================================================
-- FLING TOGGLE
--==================================================

local flingToggle =
	createToggle(
		targetPage,
		"Fling"
	)

flingToggle.MouseButton1Click:Connect(
	function()
		if not flingEnabled then
			local selected =
				getSortedSelectedTargets()

			if #selected == 0 then
				flingToggle.Text =
					"Fling: SELECT TARGETS"

				task.delay(1, function()
					if not flingEnabled then
						setToggleVisual(
							flingToggle,
							"Fling",
							false
						)
					end
				end)

				return
			end

			flingEnabled = true

			-- Fling gets its OWN snapshot.
			table.clear(
				activeFlingTargets
			)

			for _, targetPlayer in ipairs(
				selected
			) do
				activeFlingTargets[
					targetPlayer
				] = true
			end

			setToggleVisual(
				flingToggle,
				"Fling",
				true
			)

			startFling()
		else
			flingEnabled = false

			setToggleVisual(
				flingToggle,
				"Fling",
				false
			)

			stopFling()

			table.clear(
				activeFlingTargets
			)
		end
	end
)

--==================================================
-- ESP TOGGLE
--==================================================

local espToggle =
	createToggle(
		targetPage,
		"ESP"
	)

espToggle.MouseButton1Click:Connect(
	function()
		if not espEnabled then
			local selected =
				getSortedSelectedTargets()

			if #selected == 0 then
				espToggle.Text =
					"ESP: SELECT TARGETS"

				task.delay(1, function()
					if not espEnabled then
						setToggleVisual(
							espToggle,
							"ESP",
							false
						)
					end
				end)

				return
			end

			espEnabled = true

			table.clear(
				activeEspTargets
			)

			for _, targetPlayer in ipairs(
				selected
			) do
				activeEspTargets[
					targetPlayer
				] = true
			end

			setToggleVisual(
				espToggle,
				"ESP",
				true
			)

			for targetPlayer in pairs(
				activeEspTargets
			) do
				createESP(
					targetPlayer
				)
			end
		else
			espEnabled = false

			setToggleVisual(
				espToggle,
				"ESP",
				false
			)

			stopESP()
		end
	end
)

--==================================================
-- LOOPBRING TOGGLE
--==================================================

local loopbringToggle =
	createToggle(
		targetPage,
		"Loopbring"
	)

loopbringToggle.MouseButton1Click:Connect(
	function()
		if not loopbringEnabled then
			local selected =
				getSortedSelectedTargets()

			if #selected == 0 then
				loopbringToggle.Text =
					"Loopbring: SELECT TARGETS"

				task.delay(1, function()
					if not loopbringEnabled then
						setToggleVisual(
							loopbringToggle,
							"Loopbring",
							false
						)
					end
				end)

				return
			end

			loopbringEnabled = true

			-- Snapshot selection.
			table.clear(
				activeLoopbringTargets
			)

			for _, targetPlayer in ipairs(
				selected
			) do
				activeLoopbringTargets[
					targetPlayer
				] = true
			end

			setToggleVisual(
				loopbringToggle,
				"Loopbring",
				true
			)

			startLoopbring()
		else
			loopbringEnabled = false

			setToggleVisual(
				loopbringToggle,
				"Loopbring",
				false
			)

			stopLoopbring()
		end
	end
)

--==================================================
-- MAIN BUTTON CONNECTIONS
--==================================================

flyToggle.MouseButton1Click:Connect(
	function()
		flyEnabled = not flyEnabled

		setToggleVisual(
			flyToggle,
			"Fly",
			flyEnabled
		)

		if flyEnabled then
			flySpeed =
				tonumber(
					flySpeedBox.Text
				)
				or DEFAULT_FLY_SPEED

			flyControls.Visible = UserInputService.TouchEnabled
			startFly()
		else
			stopFly()
			flyControls.Visible = false

			if rootPart then
				rootPart.AssemblyLinearVelocity =
					Vector3.zero
			end
		end
	end
)

flySpeedBox.FocusLost:Connect(
	function()
		local value =
			tonumber(
				flySpeedBox.Text
			)

		if value ~= nil then
			flySpeed = value
		end
	end
)

noclipToggle.MouseButton1Click:Connect(
	function()
		noclipEnabled = not noclipEnabled

		setToggleVisual(
			noclipToggle,
			"Noclip",
			noclipEnabled
		)

		if noclipEnabled then
			startNoclip()
		else
			stopNoclip()
		end
	end
)

infiniteJumpToggle.MouseButton1Click:Connect(
	function()
		infiniteJumpEnabled =
			not infiniteJumpEnabled

		setToggleVisual(
			infiniteJumpToggle,
			"Infinite Jump",
			infiniteJumpEnabled
		)

		if infiniteJumpEnabled then
			startInfiniteJump()
		else
			stopInfiniteJump()
		end
	end
)

speedToggle.MouseButton1Click:Connect(
	function()
		if not speedEnabled then
			originalWalkSpeed =
				humanoid
				and humanoid.WalkSpeed
				or 16

			speedValue =
				tonumber(
					speedBox.Text
				)
				or DEFAULT_WALK_SPEED

			speedEnabled = true
		else
			speedEnabled = false
		end

		setToggleVisual(
			speedToggle,
			"Speed",
			speedEnabled
		)

		applySpeed()
	end
)

speedBox.FocusLost:Connect(
	function()
		local value =
			tonumber(
				speedBox.Text
			)

		if value ~= nil then
			speedValue = value

			if speedEnabled then
				applySpeed()
			end
		end
	end
)

spinToggle.MouseButton1Click:Connect(
	function()
		spinEnabled =
			not spinEnabled

		setToggleVisual(
			spinToggle,
			"Spin",
			spinEnabled
		)

		if spinEnabled then
			spinSpeed =
				tonumber(
					spinBox.Text
				)
				or DEFAULT_SPIN_SPEED

			startSpin()
		else
			stopSpin()
		end
	end
)

spinBox.FocusLost:Connect(
	function()
		local value =
			tonumber(
				spinBox.Text
			)

		if value ~= nil then
			spinSpeed = value
		end
	end
)

tpwalkToggle.MouseButton1Click:Connect(
	function()
		tpwalkEnabled =
			not tpwalkEnabled

		setToggleVisual(
			tpwalkToggle,
			"TPWalk",
			tpwalkEnabled
		)

		if tpwalkEnabled then
			tpwalkValue =
				tonumber(
					tpwalkBox.Text
				)
				or DEFAULT_TPWALK

			startTPWalk()
		else
			stopTPWalk()
		end
	end
)

tpwalkBox.FocusLost:Connect(
	function()
		local value =
			tonumber(
				tpwalkBox.Text
			)

		if value ~= nil then
			tpwalkValue = value
		end
	end
)

sayButton.MouseButton1Click:Connect(
	function()
		local message =
			sayBox.Text

		if message == "" then
			return
		end

		local textChannels =
			TextChatService:
				FindFirstChild(
					"TextChannels"
				)

		if textChannels then
			local general =
				textChannels:
					FindFirstChild(
						"RBXGeneral"
					)

			if general then
				pcall(function()
					general:SendAsync(
						message
					)
				end)
			end
		end

		-- TextBox intentionally remains unchanged.
	end
)

antiFlingToggle.MouseButton1Click:Connect(
	function()
		antiFlingEnabled =
			not antiFlingEnabled

		setToggleVisual(
			antiFlingToggle,
			"AntiFling",
			antiFlingEnabled
		)

		if antiFlingEnabled then
			startAntiFling()
		else
			stopAntiFling()
		end
	end
)

fovToggle.MouseButton1Click:Connect(
	function()
		if not fovEnabled then
			local camera =
				workspace.CurrentCamera

			if camera then
				originalFOV =
					camera.FieldOfView
			end

			fovValue =
				tonumber(
					fovBox.Text
				)
				or DEFAULT_FOV

			fovEnabled = true

			setToggleVisual(
				fovToggle,
				"FOV",
				true
			)

			startFOV()
		else
			fovEnabled = false

			setToggleVisual(
				fovToggle,
				"FOV",
				false
			)

			stopFOV()
		end
	end
)

fovBox.FocusLost:Connect(
	function()
		local value =
			tonumber(
				fovBox.Text
			)

		if value ~= nil then
			fovValue = value
		end
	end
)

maxZoomToggle.MouseButton1Click:Connect(
	function()
		if not maxZoomEnabled then
			originalMaxZoom =
				player.CameraMaxZoomDistance

			maxZoomValue =
				tonumber(
					maxZoomBox.Text
				)
				or DEFAULT_MAX_ZOOM

			maxZoomEnabled = true

			setToggleVisual(
				maxZoomToggle,
				"MaxZoom",
				true
			)

			if not zoomConnection then
				startZoom()
			end
		else
			maxZoomEnabled = false

			setToggleVisual(
				maxZoomToggle,
				"MaxZoom",
				false
			)

			if not minZoomEnabled then
				stopZoom()
			end
		end
	end
)

maxZoomBox.FocusLost:Connect(
	function()
		local value =
			tonumber(
				maxZoomBox.Text
			)

		if value ~= nil then
			maxZoomValue = value
		end
	end
)

minZoomToggle.MouseButton1Click:Connect(
	function()
		if not minZoomEnabled then
			originalMinZoom =
				player.CameraMinZoomDistance

			minZoomValue =
				tonumber(
					minZoomBox.Text
				)
				or DEFAULT_MIN_ZOOM

			minZoomEnabled = true

			setToggleVisual(
				minZoomToggle,
				"MinZoom",
				true
			)

			if not zoomConnection then
				startZoom()
			end
		else
			minZoomEnabled = false

			setToggleVisual(
				minZoomToggle,
				"MinZoom",
				false
			)

			if not maxZoomEnabled then
				stopZoom()
			end
		end
	end
)

minZoomBox.FocusLost:Connect(
	function()
		local value =
			tonumber(
				minZoomBox.Text
			)

		if value ~= nil then
			minZoomValue = value
		end
	end
)

--==================================================
-- PATHFINDER BUTTONS
--==================================================

pathfinderToolToggle.MouseButton1Click:Connect(
	function()
		pathfinderToolEnabled =
			not pathfinderToolEnabled

		setToggleVisual(
			pathfinderToolToggle,
			"Pathfinder Tool",
			pathfinderToolEnabled
		)

		setPathfinderTool(
			pathfinderToolEnabled
		)
	end
)

pathfindPlayerToggle.MouseButton1Click:Connect(
	function()
		if not pathfindPlayerEnabled then
			if not pathfindTarget
				or pathfindTarget.Parent ~= Players then

				pathfindPlayerToggle.Text =
					"Pathfind Player: SELECT TARGET"

				task.delay(1, function()
					if not pathfindPlayerEnabled then
						setToggleVisual(
							pathfindPlayerToggle,
							"Pathfind Player",
							false
						)
					end
				end)

				return
			end

			pathfindPlayerEnabled = true

			setToggleVisual(
				pathfindPlayerToggle,
				"Pathfind Player",
				true
			)

			startPathfindPlayer()
		else
			pathfindPlayerEnabled = false

			setToggleVisual(
				pathfindPlayerToggle,
				"Pathfind Player",
				false
			)

			stopPathfindPlayer()
		end
	end
)

--==================================================
-- PING UPDATE
--==================================================

local function updatePing()
	local ping =
		player:GetNetworkPing()

	if ping then
		local milliseconds =
			math.floor(
				ping * 1000 + 0.5
			)

		pingLabel.Text =
			"Ping: " ..
			milliseconds ..
			" ms"
	end
end

pingConnection =
	RunService.Heartbeat:Connect(
		updatePing
	)

--==================================================
-- PLAYER JOIN/LEAVE
--==================================================

Players.PlayerAdded:Connect(
	function(targetPlayer)
		task.wait(0.2)

		if targetPlayer ~= player then
			createPlayerButton(
				targetPlayer
			)
		end

		updatePathfindSearch()
	end
)

Players.PlayerRemoving:Connect(
	function(targetPlayer)
		selectedTargets[targetPlayer] = nil

		removeESP(targetPlayer)

		activeEspTargets[
			targetPlayer
		] = nil

		activeLoopbringTargets[
			targetPlayer
		] = nil

		activeFlingTargets[
			targetPlayer
		] = nil

		if pathfindTarget ==
			targetPlayer then

			pathfindTarget = nil
			pathfindPlayerEnabled = false

			setToggleVisual(
				pathfindPlayerToggle,
				"Pathfind Player",
				false
			)

			stopPathfindPlayer()

			updatePathfindTargetLabel()
		end

		if targetRows[targetPlayer] then
			targetRows[targetPlayer]:Destroy()
			targetRows[targetPlayer] = nil
		end

		updatePathfindSearch()
	end
)

--==================================================
-- CHARACTER RESPAWN
--==================================================

player.CharacterAdded:Connect(
	function(newCharacter)
		character = newCharacter

		humanoid =
			newCharacter:WaitForChild(
				"Humanoid"
			)

		rootPart =
			newCharacter:WaitForChild(
				"HumanoidRootPart"
			)

		-- Old fling position belongs
		-- to the old character.
		if flingEnabled then
			savedFlingCFrame = nil
		end

		-- Old paths belong to the old character.
		clearToolPath()
		clearPlayerPath()

		task.wait(0.25)

		if flyEnabled then
			startFly()
		end

		if noclipEnabled then
			startNoclip()
		end

		if infiniteJumpEnabled then
			startInfiniteJump()
		end

		if speedEnabled then
			applySpeed()
		end

		if spinEnabled then
			startSpin()
		end

		if tpwalkEnabled then
			startTPWalk()
		end

		if antiFlingEnabled then
			startAntiFling()
		end

		if pathfinderToolEnabled then
			createPathfinderTool()
		end

		if pathfindPlayerEnabled
			and pathfindTarget then

			startPathfindPlayer()
		end
	end
)

--==================================================
-- MINIMIZE / OPEN
--==================================================

local panelVisible = true

local function setPanelVisible(visible)
	panelVisible = visible
	panel.Visible = visible
end

openButton.MouseButton1Click:Connect(
	function()
		setPanelVisible(true)
	end
)

minimizeButton.MouseButton1Click:Connect(
	function()
		setPanelVisible(false)
	end
)

--==================================================
-- CLOSE CONFIRMATION
--==================================================

local confirmation =
	Instance.new("Frame")

confirmation.AnchorPoint =
	Vector2.new(0.5, 0.5)

confirmation.Position =
	UDim2.fromScale(0.5, 0.5)

confirmation.Size =
	UDim2.new(0.86, 0, 0, 160)

confirmation.BackgroundColor3 = DARK
confirmation.Visible = false
confirmation.ZIndex = 100
confirmation.Active = true
confirmation.Parent = screenGui

addCorner(confirmation, 12)
addStroke(
	confirmation,
	WHITE,
	2
)

local confirmationText =
	Instance.new("TextLabel")

confirmationText.BackgroundTransparency = 1
confirmationText.Position =
	UDim2.fromOffset(10, 15)

confirmationText.Size =
	UDim2.new(1, -20, 0, 60)

confirmationText.Text =
	"Do you want to remove this admin panel?"

confirmationText.TextColor3 = WHITE
confirmationText.TextSize = 15
confirmationText.Font =
	Enum.Font.GothamBold

confirmationText.TextWrapped = true
confirmationText.ZIndex = 101
confirmationText.TextTransparency = 0
confirmationText.Visible = true
confirmationText.Parent = confirmation

local yesButton =
	Instance.new("TextButton")

yesButton.Size =
	UDim2.new(0.42, 0, 0, 38)

yesButton.Position =
	UDim2.new(0.05, 0, 1, -50)

yesButton.BackgroundColor3 = RED
yesButton.Text = "Remove GUI"
yesButton.TextColor3 = WHITE
yesButton.Font =
	Enum.Font.GothamBold

yesButton.TextSize = 14
yesButton.ZIndex = 101
yesButton.TextTransparency = 0
yesButton.Visible = true
yesButton.Active = true
yesButton.AutoButtonColor = true
yesButton.Parent = confirmation

addCorner(yesButton, 7)

local cancelButton =
	Instance.new("TextButton")

cancelButton.Size =
	UDim2.new(0.42, 0, 0, 38)

cancelButton.Position =
	UDim2.new(0.53, 0, 1, -50)

cancelButton.BackgroundColor3 = BLUE
cancelButton.Text = "Cancel"
cancelButton.TextColor3 = WHITE
cancelButton.Font =
	Enum.Font.GothamBold

cancelButton.TextSize = 14
cancelButton.ZIndex = 101
cancelButton.TextTransparency = 0
cancelButton.Visible = true
cancelButton.Active = true
cancelButton.AutoButtonColor = true
cancelButton.Parent = confirmation

addCorner(cancelButton, 7)

closeButton.MouseButton1Click:Connect(
	function()
		confirmation.Visible = true
	end
)

cancelButton.MouseButton1Click:Connect(
	function()
		confirmation.Visible = false
	end
)

yesButton.MouseButton1Click:Connect(
	function()
		-- Stop every active feature.
		flyEnabled = false
		noclipEnabled = false
		infiniteJumpEnabled = false
		speedEnabled = false
		spinEnabled = false
		tpwalkEnabled = false
		antiFlingEnabled = false
		fovEnabled = false
		maxZoomEnabled = false
		minZoomEnabled = false

		flingEnabled = false
		espEnabled = false
		loopbringEnabled = false

		pathfinderToolEnabled = false
		pathfindPlayerEnabled = false

		stopFly()
		stopNoclip()
		stopInfiniteJump()
		stopSpin()
		stopTPWalk()
		stopAntiFling()
		stopFOV()
		stopZoom()
		stopFling()
		stopLoopbring()
		stopPathfindPlayer()

		removePathfinderTool()
		clearAllESP()

		-- Restore every character/camera property changed by the admin panel.
		if humanoid then
			humanoid.WalkSpeed = originalWalkSpeed or DEFAULT_WALK_SPEED
			humanoid.PlatformStand = false
		end

		local currentCamera = workspace.CurrentCamera
		if currentCamera then
			currentCamera.FieldOfView = originalFOV or DEFAULT_FOV
		end

		player.CameraMaxZoomDistance = originalMaxZoom or DEFAULT_MAX_ZOOM
		player.CameraMinZoomDistance = originalMinZoom or DEFAULT_MIN_ZOOM

		if rootPart then
			rootPart.AssemblyLinearVelocity =
				Vector3.zero

			rootPart.AssemblyAngularVelocity =
				Vector3.zero
		end

		screenGui:Destroy()
	end
)

--==================================================
-- INITIALIZE
--==================================================

updateResponsiveLayout()
rebuildTargetList()
updatePathfindSearch()
updatePathfindTargetLabel()
updatePing()

print("Admin Panel loaded.")