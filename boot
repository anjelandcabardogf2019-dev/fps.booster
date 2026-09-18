-- LocalScript
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CLICK_DELAY = 0.05
local MAX_DISTANCE = 1000

local clicked = false
local isDetectionActive = false

-- State tracking for sequence input
local inputBuffer = ""
local TARGET_ENABLE = ".d"
local TARGET_DISABLE = ".c"

-- Function to check raycast under crosshair
local function getHeadUnderCrosshair()
	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

	local ray = camera:ViewportPointToRay(center.X, center.Y)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		player.Character
	}

	local result = workspace:Raycast(
		ray.Origin,
		ray.Direction * MAX_DISTANCE,
		params
	)

	if not result then
		return nil
	end

	local hit = result.Instance

	if hit.Name ~= "Head" then
		return nil
	end

	local character = hit.Parent
	local targetPlayer = Players:GetPlayerFromCharacter(character)

	if targetPlayer and targetPlayer ~= player then
		return hit
	end

	return nil
end

local function M1()
	-- Put your legitimate M1/shoot function here.
	-- Example:
	-- weapon:Activate()
end

-- Keypress sequence listener
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Ignore inputs if player is typing in chat or a TextBox
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		local key = input.KeyCode
		local char = nil

		-- Resolve key press to character string
		if key == Enum.KeyCode.Period then
			char = "."
		elseif #key.Name == 1 then
			local isShiftPressed = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) 
				or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

			if isShiftPressed then
				char = key.Name:upper()
			else
				char = key.Name:lower()
			end
		end

		if char then
			local testBuffer = inputBuffer .. char

			-- Check if testBuffer matches the beginning of either target string
			local matchesEnable = (TARGET_ENABLE:sub(1, #testBuffer) == testBuffer)
			local matchesDisable = (TARGET_DISABLE:sub(1, #testBuffer) == testBuffer)

			if matchesEnable or matchesDisable then
				inputBuffer = testBuffer

				-- Check for exact matches to execute toggle
				if inputBuffer == TARGET_ENABLE then
					isDetectionActive = true
					inputBuffer = ""
				elseif inputBuffer == TARGET_DISABLE then
					isDetectionActive = false
					inputBuffer = ""
				end
			else
				-- Reset buffer on wrong keypress (restart if the wrong key was a '.')
				if char == "." then
					inputBuffer = "."
				else
					inputBuffer = ""
				end
			end
		end
	end
end)

-- Main execution loop
RunService.RenderStepped:Connect(function()
	if not isDetectionActive then
		clicked = false
		return
	end

	local head = getHeadUnderCrosshair()

	if head and not clicked then
		clicked = true

		-- M1 down
		M1()

		-- Release after CLICK_DELAY
		task.delay(CLICK_DELAY, function()
			-- M1 release logic here
		end)
	elseif not head then
		clicked = false
	end
end)
