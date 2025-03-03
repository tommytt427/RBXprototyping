local elevator = script.Parent
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SafeTeleport = require(ServerScriptService.SafeTeleport)

local elevatorEvent = ReplicatedStorage:WaitForChild("Elevator")

local movingEvent = ReplicatedStorage:WaitForChild("MovingElevator")
local playersWaiting = {}
local countdownRunning = false
local gui = elevator.Screen.SurfaceGui
local config = elevator.Config


local moving = false

local function Setup()
	playersWaiting = {}
	moving = false	
	gui.Title.Text = #playersWaiting .. " out of " .. config.MaxPlayers.Value .. " players"
	gui.Status.Text = "Waiting..."

end

local function TeleportPlayers()
	local placeId = 18761979304
	local server = TeleportService:ReserveServer(placeId)
	local options = Instance.new("TeleportOptions")
	
	options.ReservedServerAccessCode = server
	SafeTeleport(placeId, playersWaiting, options)
	print("Finished teleport.")
	
end

local function MoveElevator()
	for i, player in pairs(playersWaiting) do
		movingEvent:FireClient(player)
	end
	moving = true
	gui.Status.Text = "Teleporting..."
	TeleportPlayers()
	task.wait(10)
	Setup()
end



local function RunCountdown()
	countdownRunning = true
	for i = 30, 1, -1 do
		gui.Status.Text = "Starting in: " .. i
		task.wait(1)
		if #playersWaiting < 1 then
			countdownRunning = false
			Setup()
			return
		end
	end
	MoveElevator()
	countdownRunning = false
end




elevator.Entrance.Touched:Connect(function(part)
	local player = Players:GetPlayerFromCharacter(part.Parent)
	local isWaiting = table.find(playersWaiting, player)
	
	
	
	if player and not isWaiting and #playersWaiting < config.MaxPlayers.Value and not moving then
		table.insert(playersWaiting, player)
		gui.Title.Text = #playersWaiting .. " out of " .. config.MaxPlayers.Value .. " players"
		player.Character.PrimaryPart.CFrame = elevator.TeleportIn.CFrame
		elevatorEvent:FireClient(player, elevator)
		if not countdownRunning then
			RunCountdown()
		end
	end
end)


elevatorEvent.OnServerEvent:Connect(function(player)
	local isWaiting = table.find(playersWaiting, player)
	if isWaiting then
		table.remove(playersWaiting, isWaiting)
	end
	
	gui.Title.Text = #playersWaiting .. " out of " .. config.MaxPlayers.Value .. " players"
	
	if player.Character then
		player.Character.PrimaryPart.CFrame = elevator.TeleportOut.CFrame
	end
end)