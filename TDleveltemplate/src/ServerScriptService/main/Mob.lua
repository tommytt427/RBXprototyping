local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")
local mob = {}
local totalMobsKilled = 0


local function InitializeHitbox(mob)
	if not mob or not mob:FindFirstChild("HumanoidRootPart") then
		return false
	end

	local hitboxesFolder = mob:FindFirstChild("MainHitbox")
	if not hitboxesFolder then
		return false
	end

	for _, hitbox in ipairs(hitboxesFolder:GetChildren()) do
		if hitbox:IsA("BasePart") and not hitbox:FindFirstChild("IsWelded") then
			hitbox.CFrame = mob.HumanoidRootPart.CFrame *CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0)
			local weld = Instance.new("WeldConstraint")
			
			weld.Part0 = mob.HumanoidRootPart
			weld.Part1 = hitbox
			weld.Parent = mob.HumanoidRootPart


			local marker = Instance.new("BoolValue")
			marker.Name = "IsWelded"
			marker.Value = true
			marker.Parent = hitbox

			hitbox.Anchored = false
			hitbox.CanCollide = false
			hitbox.CanQuery = false
			hitbox.CanTouch = false
			hitbox.Transparency = 0.9
		end
	end
end

local function IsTargetWithinHitbox(target, mob)
	if not mob or not mob:FindFirstChild("HumanoidRootPart") then
		return false
	end

	local hitboxes = mob:FindFirstChild("MainHitbox")
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

local function FindNearestTarget(mob)
	if not mob or not mob:FindFirstChild("HumanoidRootPart") then
		return nil
	end

	local nearestTarget = nil
	local nearestDistance = math.huge

	for _, target in ipairs(workspace.Mobs:GetChildren()) do
		if target:FindFirstChild("HumanoidRootPart") and IsTargetWithinHitbox(target, mob) then
			local distance = (mob.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestTarget = target
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


function mob.Move(mob, map)
	local waypointFolder = map.Waypoints
	local humanoid = mob:WaitForChild("Humanoid")

	local waypoints = map.Waypoints

	for waypoint = 1, #waypoints:GetChildren() do
		mob.MovingTo.Value = waypoint

		local targetReached = false
		while not targetReached do
			if mob:FindFirstChild("Blocked") then
				-- If blocked, wait until unblocked
				humanoid:MoveTo(mob.HumanoidRootPart.Position)
				task.wait(0.1)
			else
				-- Move towards the waypoint
				humanoid:MoveTo(waypoints[waypoint].Position)

				-- Wait for movement to complete or to be blocked
				local moveConnection
				moveConnection = humanoid.MoveToFinished:Connect(function()
					targetReached = true
					moveConnection:Disconnect()
				end)

				while not targetReached and not mob:FindFirstChild("Blocked") do
					task.wait(0.1)
				end

				if mob:FindFirstChild("Blocked") then
					moveConnection:Disconnect()
				end
			end
		end
	end

	mob:Destroy()
	totalMobsKilled += 1

	map.Base.Humanoid:TakeDamage(1)
end

function mob.Spawn(name, quantity, map)	
	print(name, map)
	local mobExists = ServerStorage.Mobs:FindFirstChild(name)
	
	if mobExists then
		for i=1, quantity do
			task.wait(.5)
			
		local mobClone = mobExists:Clone()
		mobClone.Parent = workspace
		--set location to "Spawner" located in folder "Ruins"
		local spawner = map:FindFirstChild("Spawner")
			mobClone:SetPrimaryPartCFrame(spawner.CFrame)
			mobClone.Parent = workspace.Mobs
			mobClone.HumanoidRootPart:SetNetworkOwner(nil)
			
			local movingTo = Instance.new("IntValue")
			movingTo.Name = "MovingTo"
			movingTo.Parent = mobClone
			
			--physics service
			for i, object in ipairs(mobClone:GetDescendants()) do
				if object:IsA("BasePart") then
					object.CollisionGroup = "Mob"
				end
			end
			
			--removing body parts
			mobClone.Humanoid.Died:Connect(function()
				task.wait(0.5)
				mobClone:Destroy()
				totalMobsKilled += 1
			end)
			
		
		InitializeHitbox(mobClone)
		
		coroutine.wrap(mob.Move)(mobClone, map)
		end
	else
			warn("Mob does not exist")
	end
end

return mob