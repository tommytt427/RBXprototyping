local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local events = ReplicatedStorage:WaitForChild("Events")


local round = {}
local info = workspace.Info
local mob = require(script.Parent.Mob)

local votes = {
}

function round.StartGame()
	local map = round.LoadMap()


	info.GameRunning.Value = true

	local totalMobs = 0
	local totalMobsKilled = 0


	for i = 3, 0, -1 do
		if i == 1 then
			info.Message.Value = "-OP START-"
			wait(2)
		elseif i == 2 then
			info.Message.Value = "--OP START--"
			wait(2)
		elseif i == 3 then
			info.Message.Value = "---OP START---"
			wait(2)
		end
	end

	for wave = 4, 5 do

		info.WaveCount.Value = wave
		info.Message.Value = ""


		round.GetWave(wave, map)

		repeat
			task.wait(1)
		until

		#workspace.Mobs:GetChildren() == 0 or not info.GameRunning.Value

		if info.GameRunning.Value and wave == 5 then
			info.Message.Value = "VICTORY"
		end

		if not info.GameRunning.Value then
			info.Message.Value = "OPERATION FAILED"
			break
		end

	end

end


function round.LoadMap()
	local votedMap = round.ToggleVoting()
	local mapFolder = ServerStorage.Maps:FindFirstChild(votedMap)

	if not mapFolder then
		mapFolder = ServerStorage.Maps.Ruins
	end

	local newMap = mapFolder:Clone()

	-- Create a new "Map" folder in the workspace if it doesn't exist
	local workspaceMapFolder = workspace:FindFirstChild("Map")
	if not workspaceMapFolder then
		workspaceMapFolder = Instance.new("Folder")
		workspaceMapFolder.Name = "Map"
		workspaceMapFolder.Parent = workspace
	end

	-- Set the parent of the new map to the "Map" folder
	newMap.Parent = workspaceMapFolder

	-- Check if spawnBox exists before trying to destroy baseSpawn
	local spawnBox = workspace:FindFirstChild("spawnBox")
	if spawnBox and spawnBox:FindFirstChild("baseSpawn") then
		spawnBox.baseSpawn:Destroy()
	else
		warn("spawnBox or baseSpawn not found")
	end

	-- Ensure the Base exists in the new map
	local base = newMap:FindFirstChild("Base")
	if base and base:FindFirstChild("Humanoid") then
		base.Humanoid.HealthChanged:Connect(function(health)
			if health <= 0 then
				info.GameRunning.Value = false
			end
		end)
	else
		warn("Base or Base Humanoid not found in the new map")
	end

	return newMap
end

function round.ToggleVoting()
	local maps = ServerStorage.Maps:GetChildren()
	votes = {}
	for i, map in ipairs(maps) do
		votes[map.Name] = {}
	end
	
	info.Voting.Value = true
	
	for i = 10, 1, -1 do
		info.Message.Value = "Map voting (" .. i .. ")"
		task.wait(1)
	end
	
	local winVote = nil
	local winScore = 0
	for name, map in pairs(votes) do
		if #map > winScore then
			winScore = #map
			winVote = name
		end
	end
	
	if not winVote then
		local n = math.random(#maps)
		winVote = maps[n].Name
		
	end
	
	info.Voting.Value = false
	return winVote
end

function round.ProcessVote(player, vote)
	for name, mapVotes in pairs(votes) do
		local oldVote = table.find(mapVotes, player.UserId)
		if oldVote then
			table.remove(mapVotes, oldVote)
			print("Switching vote from", oldVote)
			break
		end
	end

	print("Processed vote for", vote)
	table.insert(votes[vote], player.UserId)
	-- Remove this line: votes[vote] = player.UserId
	
	events:WaitForChild("UpdateVoteCount"):FireAllClients(votes)
end

events:WaitForChild("VoteForMap").OnServerEvent:Connect(round.ProcessVote)


function round.GetWave(wave, map)
	print("OPERATION STARTING: ", wave)
	if wave < 5 then
		mob.Spawn("Grunt", 2 * wave, map)
		-- Testing for collisions
		wait(5)
		mob.Spawn("Swordsman", 1 * wave, map)
	elseif wave == 5 then
		mob.Spawn("Swordsman", 1, map)
	end
	
	
end



return round