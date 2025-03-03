local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = {}
local database = DataStoreService:GetDataStore("database")
local data = {}

function DataManager.LoadData(player)
	local success, playerData
	local attempt = 1

	repeat
		success, playerData = pcall(function()
			return database:GetAsync(player.UserId)
		end)

		attempt += 1
		if not success then 
			warn(playerData)
			task.wait(1)
		end
	until success or attempt == 3

	if success then
		print("Data has been retrieved for", player.Name)
		if not playerData then
			print("New player, giving default data")
			playerData = {
				["Studs"] = 400,
				["SelectedTowers"] = {"Eloria"},
			}
		end
		data[player.UserId] = playerData
		ReplicatedStorage.DataChanged:FireClient(player, playerData)
	else
		warn("Unable to get data for player", player.UserId)
		player:Kick("Problem getting your data.")
	end
end

function DataManager.SaveData(player)
	if data[player.UserId] then
		local success, errorMessage
		local attempt = 1
		repeat
			success, errorMessage = pcall(function()
				database:SetAsync(player.UserId, data[player.UserId])
			end)
			attempt += 1
			if not success then 
				warn(errorMessage)
				task.wait(1)
			end
		until success or attempt == 3

		if success then
			print("Data has been saved for player", player.Name, player.UserId)
		else
			warn("Unable to save data for player", player.UserId)
		end
	else
		warn("No session data for", player.UserId)
	end
end

function DataManager.GetPlayerData(player)
	return data[player.UserId]
end

function DataManager.UpdatePlayerData(player, newData)
	data[player.UserId] = newData
	ReplicatedStorage.DataChanged:FireClient(player, newData)
	DataManager.SaveData(player)
end

return DataManager