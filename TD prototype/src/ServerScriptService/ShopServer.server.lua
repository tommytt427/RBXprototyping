local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local DataManager = require(ServerScriptService.DataManager)
local towers = require(ReplicatedStorage:WaitForChild("TowerInventory"))

local rollTowerFunc = Instance.new("RemoteFunction")
rollTowerFunc.Name = "RollTower"
rollTowerFunc.Parent = ReplicatedStorage

-- Define rarity tiers and their probabilities
local rarityTiers = {
	{name = "Common", probability = 0.6, towers = {}},
	{name = "Rare", probability = 0.3, towers = {}},
	{name = "Epic", probability = 0.09, towers = {}},
	{name = "Legendary", probability = 0.01, towers = {}}
}

-- Populate rarity tiers with towers
for name, tower in pairs(towers) do
	table.insert(rarityTiers[tower.rarity].towers, name)
end

local function getRandomTower()
	local rand = math.random()
	local cumulativeProbability = 0

	for _, tier in ipairs(rarityTiers) do
		cumulativeProbability = cumulativeProbability + tier.probability
		if rand <= cumulativeProbability then
			return tier.towers[math.random(1, #tier.towers)]
		end
	end

	return rarityTiers[1].towers[math.random(1, #rarityTiers[1].towers)] -- Fallback to common
end

local ROLL_COST = 50 -- Set the cost for each roll

rollTowerFunc.OnServerInvoke = function(player)
	local playerData = DataManager.GetPlayerData(player)

	if not playerData then
		warn("No player data found for " .. player.Name)
		return nil
	end

	print("Player " .. player.Name .. " has " .. playerData.Studs .. " Studs")

	if playerData.Studs >= ROLL_COST then
		playerData.Studs = playerData.Studs - ROLL_COST

		local newTower = getRandomTower()
		print("Rolled tower: " .. newTower)

		if not table.find(playerData.OwnedTowers, newTower) then
			table.insert(playerData.OwnedTowers, newTower)
			print("Added " .. newTower .. " to player's owned towers")
		else
			print(newTower .. " already owned by player")
		end

		DataManager.UpdatePlayerData(player, playerData)

		return newTower
	else
		print("Player " .. player.Name .. " doesn't have enough Studs to roll")
		return nil -- Not enough studs
	end
end

Players.PlayerAdded:Connect(DataManager.LoadData)
Players.PlayerRemoving:Connect(DataManager.SaveData)

ReplicatedStorage.GetData.OnServerInvoke = DataManager.GetPlayerData