local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = ReplicatedStorage:WaitForChild("Events")
local animateTowerEvent = events:WaitForChild("AnimateTower")
local functions = ReplicatedStorage:WaitForChild("Functions")
local requestTowerFunction = functions:WaitForChild("RequestTower")
local spawnTowerFunction = functions:WaitForChild("SpawnTower")
local sellTowerFunction = functions:WaitForChild("SellTower")


local map = workspace.Ruins
local maxTowers = 11
local tower = {}


local function InitializeHitbox(tower)
	local config = tower.Config
	if not tower or not tower:FindFirstChild("HumanoidRootPart") then
		return false
	end

	local hitboxesFolder = tower:FindFirstChild("MainHitbox")
	if not hitboxesFolder then
		return false
	end

	for _, hitbox in ipairs(hitboxesFolder:GetChildren()) do
		if hitbox:IsA("BasePart") and not hitbox:FindFirstChild("IsWelded") then
			local weld = Instance.new("WeldConstraint")
			hitbox.CFrame = tower.HumanoidRootPart.CFrame *CFrame.new(config.XCframe.Value,config.YCframe.Value,config.ZCframe.Value) * CFrame.Angles(0, math.rad(180), 0)
			weld.Part0 = tower.HumanoidRootPart
			weld.Part1 = hitbox
			weld.Parent = tower.HumanoidRootPart


			local marker = Instance.new("BoolValue")
			marker.Name = "IsWelded"
			marker.Value = true
			marker.Parent = hitbox

			hitbox.Anchored = true
			hitbox.CanCollide = false
			hitbox.CanQuery = false
			hitbox.CanTouch = false
			hitbox.Transparency = 1
		end
	end
end

local function IsTargetWithinHitbox(target, tower)
	if not tower or not tower:FindFirstChild("HumanoidRootPart") then
		return false
	end

	local hitboxes = tower:FindFirstChild("MainHitbox")
	if not hitboxes then
		return false
	end

	for _, hitbox in ipairs(hitboxes:GetChildren()) do
		if hitbox:IsA("BasePart") then
			local parts = workspace:GetPartsInPart(hitbox)
			for _, detectedPart in ipairs(parts) do
				if detectedPart:IsDescendantOf(target) then
					return true
				end
			end
		end
	end

	return false
end




--[[local function FindNearestTarget(tower)
	if not tower or not tower:FindFirstChild("HumanoidRootPart") then
		return nil
	end

	local nearestTarget = nil
	local nearestDistance = math.huge

	for _, target in ipairs(workspace.Mobs:GetChildren()) do
		if target:FindFirstChild("HumanoidRootPart") then
			local distance = (tower.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestTarget = target
			end
		end
	end
	return nearestTarget
end
]]--

function tower.FindTarget(newTower, mode)
	local bestTarget = nil
	local bestWaypoint = nil
	local bestDistance = nil
	local bestHealth = nil
	local maxDistance = math.huge

	if not newTower or not newTower:FindFirstChild("HumanoidRootPart") then
		return nil
	end

	for _, target in ipairs(workspace.Mobs:GetChildren()) do
		if target:FindFirstChild("HumanoidRootPart") then
			local distanceToMob = (target.HumanoidRootPart.Position - newTower.HumanoidRootPart.Position).Magnitude
			local distanceToWaypoint = (target.HumanoidRootPart.Position - map.Waypoints[target.MovingTo.Value].Position).Magnitude

			if distanceToMob <= maxDistance then
				if mode == "Near" then
					maxDistance = distanceToMob
					bestTarget = target
				elseif mode == "Strong" then
					if not bestHealth or target.Humanoid.Health > bestHealth then
						bestHealth = target.Humanoid.Health
						bestTarget = target
					end
				elseif mode == "First" then
					if not bestWaypoint or target.MovingTo.Value >= bestWaypoint then
						bestWaypoint = target.MovingTo.Value
						if not bestDistance or distanceToWaypoint < bestDistance then
							bestDistance = distanceToWaypoint
							bestTarget = target
						end
					end

				end
			end
		end
	end
	return bestTarget
end

function tower.Attack(newTower, player)
	local config = newTower:FindFirstChild("Config")
	if not config then
		return
	end

	local targetMode = config:FindFirstChild("TargetMode")
	if not targetMode then
		return
	end

	local currentTarget = tower.FindTarget(newTower, targetMode.Value)

	while true do
		if not newTower or not newTower.Parent then
			break
		end

		if currentTarget and currentTarget:FindFirstChildOfClass("Humanoid") and currentTarget.Humanoid.Health > 0 then
			if IsTargetWithinHitbox(currentTarget, newTower) then
				animateTowerEvent:FireAllClients(newTower, "Attack", currentTarget)
				currentTarget.Humanoid:TakeDamage(config.Damage.Value)

				if currentTarget.Humanoid.Health <= 0 then
					player.Credits.Value += 1
				end
				task.wait(config.Cooldown.Value)
			else
				currentTarget = nil
			end
		else
			currentTarget = tower.FindTarget(newTower, targetMode.Value)
		end

		task.wait(0.1)
	end
end

function tower.Sell(player, model)
	if model and model:FindFirstChild("Config") then
		if model.Config.Owner.Value == player.Name then 
			player.placedTowers.Value -= 1
			player.Credits.Value += math.floor(model.Config.Price.Value / math.floor(3))
			model:Destroy()
			return true
		end
	end

	warn("Unable to sell this tower")
	return false
end

sellTowerFunction.OnServerInvoke = tower.Sell

function tower.Spawn(player, name, cframe, previous)
	local allowedToSpawn = tower.CheckSpawn(player, name, previous)

	if allowedToSpawn then
		local newTower
		if previous then
			previous:Destroy()
			newTower = ReplicatedStorage.Towers.Upgrades:FindFirstChild(name):Clone()
		else
			newTower = ReplicatedStorage.Towers.Melee:FindFirstChild(name) or ReplicatedStorage.Towers.Ranged:FindFirstChild(name)
			if newTower then
				newTower = newTower:Clone()
				player.placedTowers.Value += 1
			end
		end

		if not newTower then
			warn("Requested tower does not exist: ", name)
			return false
		end

		-- Add Owner to Config
		local ownerValue = Instance.new("StringValue")
		ownerValue.Name = "Owner"
		ownerValue.Value = player.Name
		ownerValue.Parent = newTower.Config

		-- Add TargetMode to Config
		local targetMode = Instance.new("StringValue")
		targetMode.Name = "TargetMode"
		targetMode.Value = "First"
		targetMode.Parent = newTower.Config

		-- Set tower position and parent
		newTower.HumanoidRootPart.CFrame = cframe
		newTower.Parent = workspace.Towers



		for _, object in ipairs(newTower:GetDescendants()) do
			if object:IsA("BasePart") then
				object.CollisionGroup = "Tower"
			end
		end

		-- Initialize hitbox
		InitializeHitbox(newTower)

		-- Deduct the tower's price from player credits
		player.Credits.Value -= newTower.Config.Price.Value

		-- Start tower attack coroutine
		coroutine.wrap(tower.Attack)(newTower, player)

		return newTower
	else
		warn("Requested tower does not exist: ", name)
		return false
	end
end

spawnTowerFunction.OnServerInvoke = tower.Spawn

function tower.CheckSpawn(player, name, previous)
	local towerExists = ReplicatedStorage.Towers.Melee:FindFirstChild(name) or ReplicatedStorage.Towers.Ranged:FindFirstChild(name)
		or ReplicatedStorage.Towers.Upgrades:FindFirstChild(name, true)

	if towerExists then
		if towerExists.Config.Price.Value <= player.Credits.Value then
			if previous or player.placedTowers.Value < maxTowers then
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
