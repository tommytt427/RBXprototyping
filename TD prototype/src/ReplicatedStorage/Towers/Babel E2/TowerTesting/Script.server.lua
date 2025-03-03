local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = ReplicatedStorage:WaitForChild("Events")
local spawnTowerEvent = events:WaitForChild("SpawnTower")
local animateTowerEvent = events:WaitForChild("AnimateTower")
local functions = ReplicatedStorage:WaitForChild("Functions")
local requestTowerFunction = functions:WaitForChild("RequestTower")


local maxTowers = 11
local tower = {} -- Table to keep track of towers



local function IsTargetWithinRange(target, tower, rangeX, rangeY, rangeZ, negrangeX, negrangeY, negrangeZ)
	if not tower or not tower:FindFirstChild("HumanoidRootPart") then
		return false
	end

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

local function FindNearestTarget(tower, rangeX, rangeY, rangeZ, negrangeX, negrangeY, negrangeZ)
	if not tower or not tower:FindFirstChild("HumanoidRootPart") then
		return nil
	end

	local towerCFrame = tower.HumanoidRootPart.CFrame
	local towerPosition = towerCFrame.Position
	local towerLookVector = towerCFrame.LookVector

	local nearestTarget = nil

	for _, target in ipairs(workspace.Mobs:GetChildren()) do
		if target:FindFirstChild("HumanoidRootPart") then
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
				if distance <= rangeX then
					rangeX = distance
					nearestTarget = target
				elseif distance <= rangeY then
					rangeY = distance
					nearestTarget = target
				elseif distance <= rangeZ then
					rangeZ = distance
					nearestTarget = target
				elseif distance >= negrangeX then
					negrangeX = distance
					nearestTarget = target
				elseif distance >= negrangeY then
					negrangeY = distance
					nearestTarget = target
				elseif distance >= negrangeZ then
					negrangeZ = distance
					nearestTarget = target
				end

				print("Target within range: ", target.Name, "Distance: ", distance)
			end
		end
	end

	if nearestTarget then
		print("Nearest target: ", nearestTarget.Name)
	else
		print("No targets within range.")
	end

	return nearestTarget
end

function tower.Attack(newTower, player)
	local config = newTower.Config
	local currentTarget = nil

	while true do
		if currentTarget and currentTarget:FindFirstChildOfClass("Humanoid") and currentTarget.Humanoid.Health > 0 then
			-- Continue attacking the current target if it's still alive and within range
			if IsTargetWithinRange(currentTarget, newTower, config.RangeX.Value, config.RangeY.Value, config.RangeZ.Value,
				config.NegRangeX.Value, config.NegRangeY.Value, config.NegRangeZ.Value) then
				animateTowerEvent:FireAllClients(newTower, "Attack")
				currentTarget.Humanoid:TakeDamage(config.Damage.Value)

				if currentTarget.Humanoid.Health <= 0 then
					player.Credits.Value += 1
				end
				task.wait(config.Cooldown.Value)
			else
				currentTarget = nil -- Target is dead or out of range, reset current target
			end
		else
			-- Find a new target if there is no current target
			currentTarget = FindNearestTarget(newTower, config.RangeX.Value, config.RangeY.Value, config.RangeZ.Value,
				config.NegRangeX.Value, config.NegRangeY.Value, config.NegRangeZ.Value)
		end

		task.wait(0.1)

	end
end

function tower.Spawn(player, name, cframe)
	local allowedToSpawn = tower.CheckSpawn(player, name)

	if allowedToSpawn then
		local newTower = ReplicatedStorage.Towers[name]:Clone()
		newTower.HumanoidRootPart.CFrame = cframe
		newTower.Parent = workspace.Towers


		for _, object in ipairs(newTower:GetDescendants()) do
			if object:IsA("BasePart") then
				object.CollisionGroup = "Tower"
			end
		end

		player.Credits.Value -= newTower.Config.Price.Value
		player.placedTowers.Value += 1

		-- Start attacking
		coroutine.wrap(tower.Attack)(newTower, player)
	else
		warn("Requested tower does not exist:", name)
	end
end

spawnTowerEvent.OnServerEvent:Connect(tower.Spawn)

function tower.CheckSpawn(player, name)
	local towerExists = ReplicatedStorage.Towers:FindFirstChild(name)

	if towerExists then
		if towerExists.Config.Price.Value <= player.Credits.Value then
			if player.placedTowers.Value < maxTowers then
				return true
			else
				warn("Player has reached max limit")
			end
		else
			warn("Player does not have sufficient funds")
		end
	else
		warn("Tower does not exist")
	end
	return false
end

requestTowerFunction.OnServerInvoke = tower.CheckSpawn

return tower
