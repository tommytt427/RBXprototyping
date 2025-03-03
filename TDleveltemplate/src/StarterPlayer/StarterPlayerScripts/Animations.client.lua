local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local events = ReplicatedStorage:WaitForChild("Events")
local animateTowerEvent = events:WaitForChild("AnimateTower")
local TweenService = game:GetService("TweenService")

local function fireProjectile(tower, target)
	local projectile = Instance.new("Part")
	
	projectile.Size = Vector3.new(0.1,0.1,0.1)
	projectile.CFrame = tower.Head.CFrame
	
	projectile.Anchored = true
	projectile.CanCollide = false
	projectile.Transparency = 1
	projectile.Parent = workspace.Camera
	
	local fire = Instance.new("Fire")
	fire.Size = 2
	fire.Heat = 0.1
	fire.Color = tower.Config.Trail.Value
	fire.Parent = projectile
	
	local projectileTween = TweenService:Create(projectile, TweenInfo.new(0.5), {Position = target.HumanoidRootPart.Position})
	
	projectileTween:Play()
	
	Debris:AddItem(projectile, 0.5)
end


local function setAnimation(object, animName)
	local humanoid = object:WaitForChild("Humanoid")
	local animationsFolder = object:WaitForChild("Animations")
	
	if humanoid and animationsFolder then
		local animationObject = animationsFolder:WaitForChild(animName)
		
		if animationObject then
			local animator = humanoid:FindFirstChild("Animator") or Instance.new("Animator", humanoid)
			
			local playingTracks = animator:GetPlayingAnimationTracks()
			for i, track in pairs(playingTracks) do 
				if track.Name == animName then 
					return track
				end
			end
			
			local animationTrack = animator:LoadAnimation(animationObject)
			return animationTrack
		end
	end
end


local function playAnimation(object, animName)
	local animationTrack = setAnimation(object, animName)
	
	if animationTrack then
		animationTrack:Play()
	else
		warn("Animation track does not exist")
		return
	end
end



workspace.Mobs.ChildAdded:Connect(function(object)
	playAnimation(object, "testWalk")
end)

workspace.Towers.ChildAdded:Connect(function(object)
	playAnimation(object, "Idle")
end)

animateTowerEvent.OnClientEvent:Connect(function(tower, animName, target)
	playAnimation(tower, animName)
	
	if target then
		if tower.Config:FindFirstChild("Trail") then
			fireProjectile(tower, target)
		end
		if tower.HumanoidRootPart:FindFirstChild("Attack") then
			tower.HumanoidRootPart.Attack:Play()
		end
	end
end)