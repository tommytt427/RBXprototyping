local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local towers = require(ReplicatedStorage:WaitForChild("TowerInventory"))
local gui = script.Parent
local getDataFunc = ReplicatedStorage:WaitForChild("GetData")
local interactItemFunc = ReplicatedStorage:WaitForChild("InteractItem")
local rollTowerFunc = ReplicatedStorage:WaitForChild("RollTower")
local roll = gui.Canvas.Container.Main.SidePanel.Roll
local exit = gui.Canvas.Container.Main.Close
local resultFrame = gui.Canvas.Container.Main.ResultFrame -- Add this frame to your GUI
local resultImage = resultFrame.TowerImage
local resultName = resultFrame.TowerName

local function toggleShop()
	gui.Canvas.Visible = not gui.Canvas.Visible
end

local function displayRollResult(towerName)
	local tower = towers[towerName]
	if tower then
		resultImage.Image = tower.Image
		resultName.Text = tower.Name
		resultFrame.Visible = true
		-- Add animation or effects here
		task.wait(3) -- Display result for 3 seconds
		resultFrame.Visible = false
	end
end

-- ... (previous code remains the same)

local function rollTower()
	local success, result = pcall(function()
		return rollTowerFunc:InvokeServer()
	end)

	if success then
		if result then
			displayRollResult(result)
		else
			print("Not enough Studs to roll or other server-side issue")
			-- Display a message to the player that they can't roll
		end
	else
		warn("Error while rolling tower:", result)
		-- Display an error message to the user
	end
end

-- ... (rest of the code remains the same)

local function setupShop()
	local prompt = Instance.new("ProximityPrompt")
	prompt.RequiresLineOfSight = false
	prompt.ActionText = "Recruiting"
	prompt.Parent = workspace:WaitForChild("ShopPart")

	prompt.Triggered:Connect(toggleShop)
	exit.Activated:Connect(toggleShop)
	roll.Activated:Connect(rollTower)

	resultFrame.Visible = false
end

setupShop()