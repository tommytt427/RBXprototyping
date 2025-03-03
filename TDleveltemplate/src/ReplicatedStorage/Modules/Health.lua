local Players = game:GetService("Players")

local health = {}

function health.Setup(model, screenGui)
	local newHealthBar = script.HealthGui:Clone()
	newHealthBar.Adornee = model:WaitForChild("Head")
	newHealthBar.Parent = Players.LocalPlayer.PlayerGui:WaitForChild("Billboards")

	if model.Name == "Base" then
		newHealthBar.MaxDistance = 100
		newHealthBar.Size = UDim2.new(0, 200, 0, 20)
	else
		newHealthBar.MaxDistance = 30
		newHealthBar.Size = UDim2.new(0, 100, 0, 20)
	end

	health.updateHealth(newHealthBar, model)
	if screenGui then
		health.updateHealth(screenGui, model)
	end

	model.Humanoid.HealthChanged:Connect(function()
		health.updateHealth(newHealthBar, model)
		if screenGui then
			health.updateHealth(screenGui, model)
		end
	end)
end

function health.updateHealth(gui, model)
	local humanoid = model:WaitForChild("Humanoid")

	if humanoid and gui then
		local percent = humanoid.Health / humanoid.MaxHealth

		local currentHealthBar = gui:FindFirstChild("CurrentHealth")
		local titleLabel = gui:FindFirstChild("Title")

		if currentHealthBar then
			currentHealthBar.Size = UDim2.new(math.max(percent,0), 0, 1, 0)
		end

		if titleLabel then
			if humanoid.Health <= 0 then
				if model.Name == "Base" then 
					titleLabel.Text = "RETREAT..."
				else
					titleLabel.Text = model.Name .. " INCAPACITATED"
					task.wait(0.5)
					gui:Destroy()
				end
			else
				titleLabel.Text = model.Name
			end
		end
	end
end

return health
