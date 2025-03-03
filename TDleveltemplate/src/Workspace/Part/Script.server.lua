-- << Initial Setup >> 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RaycastHitbox = require(ReplicatedStorage.RaycastHitboxV4)

local Players = game:GetService("Players")

-- We will construct a new hitbox for our part
local newHitbox = RaycastHitbox.new(script.Parent)

-- We can use SetPoints to create new DmgPoints artificially
newHitbox:SetPoints(script.Parent, {Vector3.new(0, 3, 0), Vector3.new(-5, 3, 0), Vector3.new(5, 3, 0)})

-- Makes a new event listener for raycast hits
newHitbox.OnHit:Connect(function(hit, humanoid)
	print(hit)
	humanoid:TakeDamage(50)
end)



Players.PlayerAdded:Connect(function(player)
	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {player} --- remember to define our character!
	Params.FilterType = Enum.RaycastFilterType.Exclude

	-- We will construct a new hitbox for our sword
	newHitbox.RaycastParams = Params --- Define our RaycastParams

	--- The raycasts will no longer damage your character or any objects you put in the ignore list!
end)


-- Let's just run it on a loop, cause why not?
while true do
	newHitbox:HitStart()
	wait(5)
	newHitbox:HitStop()
	wait(0.5)
end
