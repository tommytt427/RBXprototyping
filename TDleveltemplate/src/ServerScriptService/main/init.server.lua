
local Players = game:GetService("Players")


local round = require(script.Round)

local mob = require(script.Mob)
local tower = require(script.Tower)


local minPlayers = 1

Players.PlayerAdded:Connect(function(player)
	local currentPlayers = #Players:GetPlayers()
	
	if currentPlayers >= minPlayers then
		round.StartGame()
	else
		workspace.Info.Message.Value = "Waiting for " .. (minPlayers - currentPlayers) .. "players"
	end
end)