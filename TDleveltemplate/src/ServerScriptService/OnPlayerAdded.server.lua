local Players = game:GetService("Players")

local PhysicsService = game:GetService("PhysicsService")






Players.PlayerAdded:Connect(function(player)
	
	local Credits = Instance.new("IntValue")
	Credits.Name = "Credits"
	Credits.Value = 500
	Credits.Parent = player
	
	local placedTowers = Instance.new("IntValue")
	placedTowers.Name = "placedTowers"
	placedTowers.Value = 0
	placedTowers.Parent = player
	
	
	
	
	player.CharacterAdded:Connect(function(character)
		for i, object in ipairs(character:GetDescendants()) do
			if object:IsA("BasePart") then
				object.CollisionGroup = "Player"
			end
		end
	end)
	
	while true do
		if player:FindFirstChild("Credits") then
			player.Credits.Value += 1
		end
		task.wait(1) -- Adjust the wait time as needed
	end
end)