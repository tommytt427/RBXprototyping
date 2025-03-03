local tower = script.Parent
local mobs = workspace.Mobs

-- Define the range limits for each axis
local rangeX = 15.222
local negrangeX = -15.222
local rangeY = 40
local negrangeY = -40
local rangeZ = 35.45
local negrangeZ = -4.68

local currentTarget = nil

local function IsTargetWithinRange(target)
	local towerCFrame = tower.HumanoidRootPart.CFrame
	local towerPosition = towerCFrame.Position
	local towerLookVector = towerCFrame.LookVector

	local targetPosition = target.HumanoidRootPart.Position
	local relativePosition = targetPosition - towerPosition

	-- Convert relative position to local space relative to the tower's facing direction
	local localPositionX = relativePosition:Dot(towerCFrame.RightVector)
	local localPositionY = relativePosition:Dot(towerCFrame.UpVector)
	local localPositionZ = relativePosition:Dot(towerLookVector)

	-- Check if the target is within the specified ranges on each axis
	return localPositionX <= rangeX and localPositionY <= rangeY and localPositionZ <= rangeZ and
		localPositionX >= negrangeX and localPositionY >= negrangeY and localPositionZ >= negrangeZ
end

local function FindNearestTarget()
	local towerCFrame = tower.HumanoidRootPart.CFrame
	local towerPosition = towerCFrame.Position
	local towerLookVector = towerCFrame.LookVector

	local nearestTarget = nil
	local nearestDistance = math.huge

	for _, target in ipairs(mobs:GetChildren()) do
		local targetPosition = target.HumanoidRootPart.Position
		local relativePosition = targetPosition - towerPosition

		-- Convert relative position to local space relative to the tower's facing direction
		local localPositionX = relativePosition:Dot(towerCFrame.RightVector)
		local localPositionY = relativePosition:Dot(towerCFrame.UpVector)
		local localPositionZ = relativePosition:Dot(towerLookVector)

		-- Check if the target is within the specified ranges on each axis
		if localPositionX <= rangeX and localPositionY <= rangeY and localPositionZ <= rangeZ and
			localPositionX >= negrangeX and localPositionY >= negrangeY and localPositionZ >= negrangeZ then
			local distance = relativePosition.Magnitude

			-- Determine the nearest target
			if distance < nearestDistance then
				nearestDistance = distance
				nearestTarget = target
			end

			print("Target within range: ", target.Name, "Distance: ", distance)
		end
	end

	if nearestTarget then
		print("Nearest target: ", nearestTarget.Name)
	else
		print("No targets within range.")
	end

	return nearestTarget
end

while true do
	if currentTarget and currentTarget:FindFirstChildOfClass("Humanoid") then
		-- Continue attacking the current target if it's still alive and within range
		if currentTarget.Humanoid.Health > 0 and IsTargetWithinRange(currentTarget) then
			currentTarget.Humanoid:TakeDamage(25)
			task.wait(0.5)
		else
			currentTarget = nil -- Target is dead or out of range, reset current target
		end
	else
		-- Find a new target if there is no current target
		currentTarget = FindNearestTarget()
	end

	task.wait(0.1)
end
