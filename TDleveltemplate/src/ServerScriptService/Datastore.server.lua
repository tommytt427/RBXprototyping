local DataStoreService = game:GetService("DataStoreService")
local database = DataStoreService:GetDataStore("database")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local functions = ReplicatedStorage:WaitForChild("Functions")
local events = ReplicatedStorage:WaitForChild("Events")
local getDataFunc = functions:WaitForChild("GetData")
local exitEvent = events:WaitForChild("ExitGame")


local RunService = game:GetService("RunService")

local data = {}
local MAX_SELECTED_TOWERS = 11
-- Load player's data
local function LoadData(player)
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
		print("Data has been retrieved")
		if not playerData then
			print("New player, giving default data")
			playerData = {
				["Studs"] = 400,
				["SelectedTowers"] = {"Eloria"},
				["OwnedTowers"] = {"Babel", "Fallen Angel"}
			}
		end
		data[player.UserId] = playerData
	else
		warn("Unable to get data for player", player.UserId)
		player:Kick("Problem getting your data.")
	end
end

Players.PlayerAdded:Connect(LoadData)

-- Save player's data
local function saveData(player)
	if data[player.UserId] then
		local success, errorMessage
		local attempt = 1
		
		local info = workspace.Info
		local studs = math.round(info.WaveCount.Value / 2)
		if info.Message.Value == "VICTORY" then
			studs = 400
		end
		data[player.UserId].Studs = studs
		
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
			print("Data has been saved for player", player.UserId)
		else
			warn("Unable to save data for player", player.UserId)
		end
	else
		warn("No session data for", player.UserId)
	end
end

exitEvent.OnServerEvent:Connect(function(player)
	saveData(player)
	data[player.UserId] = nil
end)


--auto saving
game:BindToClose(function()
	if not RunService:IsStudio() then
	for index, player in pairs(Players:GetPlayers()) do
		task.spawn(function()
			saveData(player)
		end)
		end		
	else
		print("Shutting down the server in studio")
	end
end)






getDataFunc.OnServerInvoke = function(player)
	return data[player.UserId]
end