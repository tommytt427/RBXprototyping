local ReplicatedStorage = game:GetService("ReplicatedStorage")

local elevatorEvent = ReplicatedStorage:WaitForChild("Elevator")
local movingEvent = ReplicatedStorage:WaitForChild("MovingElevator")
local gui = script.Parent
local exitBtn = gui.Exit
local camera = workspace.CurrentCamera



movingEvent.OnClientEvent:Connect(function()
	exitBtn.Visible = false
end)
-- for adding the buttons, others



elevatorEvent.OnClientEvent:Connect(function(elevator)
	exitBtn.Visible = true
	camera.CameraType = Enum.CameraType.Scriptable 
	camera.CFrame = elevator.Camera.CFrame
	
end)

exitBtn.Activated:Connect(function()
	local player = game.Players.LocalPlayer
	
	
	exitBtn.Visible = false
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = player.Character.Humanoid
	
	elevatorEvent:FireServer()
end)



