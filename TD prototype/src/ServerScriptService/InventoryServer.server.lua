local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.DataManager)

local MAX_SELECTED_TOWERS = 11

ReplicatedStorage.InteractItem.OnServerInvoke = function(player, itemName)
	local playerData = DataManager.GetPlayerData(player)
	if not playerData then return end

	local isSelected = table.find(playerData.SelectedTowers, itemName)
	local isOwned = table.find(playerData.OwnedTowers, itemName)

	if isOwned then
		if isSelected then
			if #playerData.SelectedTowers > 1 then
				table.remove(playerData.SelectedTowers, table.find(playerData.SelectedTowers, itemName))
			end
		else
			if #playerData.SelectedTowers < MAX_SELECTED_TOWERS then
				table.insert(playerData.SelectedTowers, itemName)
			end
		end
		DataManager.UpdatePlayerData(player, playerData)
		return playerData
	end
	return false
end