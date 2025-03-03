local Block = game.Workspace.Part

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local HRP = character.HumanoidRootPart
		local Weld = Instance.new("Weld")
		Weld.Parent = Block
		Block.CFrame = HRP.CFrame
		
		Weld.Part0 = HRP
		Weld.Part1 = Block
		
		Weld.C0 = Block.CFrame
		Weld.C1 = HRP.CFrame
	end)
end)
