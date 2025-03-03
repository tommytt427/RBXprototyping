local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local towers = require(ReplicatedStorage:WaitForChild("TowerInventory"))
local gui = script.Parent
local getDataFunc = ReplicatedStorage:WaitForChild("GetData")
local interactItemFunc = ReplicatedStorage:WaitForChild("InteractItem")



local mainGui = playerGui:WaitForChild("MainGui")
local inventoryGui = playerGui:WaitForChild("Inventory")

local inventoryButton = gui.InventoryButton
local exit = gui.InventoryFrame.Container.Main.Close
local nav = gui.InventoryFrame.Container.Navigation.List
local studs = gui.InventoryFrame.Container.Main.Studs
local limit = gui.InventoryFrame.Container.Main.TowerLimit
local itemsFrame = gui.InventoryFrame.Container.Main.Container
local playerData = {}

local function getItemStatus(itemName)
	if table.find(playerData.SelectedTowers, itemName) then
		return "Equipped"
	elseif table.find(playerData.OwnedTowers, itemName) then
		return "Owned"
	end
end

local function clearItems()
	for _, item in pairs(itemsFrame:GetChildren()) do
		if item:IsA("Frame") and item.Name ~= "Item" then
			item:Destroy()
		end
	end
end

local function interactItem(itemName)
	local data = interactItemFunc:InvokeServer(itemName)
	if data then
		playerData = data
		updateItems()
	end
end

function updateItems()
	clearItems()
	studs.Text = tostring(playerData.Studs)
	limit.Text = #playerData.SelectedTowers .. "/11"

	local playerTowers = {}
	for _, towerName in ipairs(playerData.SelectedTowers) do
		table.insert(playerTowers, towerName)
	end
	for _, towerName in ipairs(playerData.OwnedTowers) do
		if not table.find(playerTowers, towerName) then
			table.insert(playerTowers, towerName)
		end
	end

	for _, towerName in ipairs(playerTowers) do
		local tower = towers[towerName]
		--find any old buttons
		local oldButton = itemsFrame:FindFirstChild(tower.Name)
		if oldButton then
			oldButton:Destroy()
		end
		if tower then
			--creating new button
			local newButton = itemsFrame.Item:Clone()
			newButton.Name = tower.Name
			newButton.TowerName.Text = tower.Name
			newButton.Default.ItemImage.Image = tower.Image
			newButton.Equipped.ItemImage.Image = tower.Image
			newButton.Equipped.UIStroke.Transparency = 1
			newButton.Visible = true
			newButton.Parent = itemsFrame
			
			local status = getItemStatus(tower.Name)
			
			if status == "Equipped" then
				newButton.Equipped.UIStroke.Transparency = 0
			elseif status == "Owned" then
				newButton.Equipped.UIStroke.Transparency = 1
			end
			newButton.Activated:Connect(function()
				interactItem(tower.Name)
			end)
		end
	end
end


local function toggleInventory()
	gui.InventoryFrame.Visible = not gui.InventoryFrame.Visible
	if gui.InventoryFrame.Visible then
		playerData = getDataFunc:InvokeServer()
		updateItems()
	end
end

local function setupInventory()
	exit.Activated:Connect(toggleInventory)

	-- Connect to a button in the main GUI
	
	inventoryButton.Activated:Connect(toggleInventory)
end

ReplicatedStorage.DataChanged.OnClientEvent:Connect(function(newData)
	playerData = newData
	updateItems()
end)

print("InventoryClient script started")
setupInventory()