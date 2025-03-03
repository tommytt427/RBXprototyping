local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local hoveredInstance = nil
local selectedTower = nil
local towerToSpawn = nil
local canPlace = false
local rotation = 0
local placedTowers = 0
local maxTowers = 11
local lastTouch = tick()

local modules = ReplicatedStorage:WaitForChild("Modules")
local health = require(modules:WaitForChild("Health"))
local credit = Players.LocalPlayer:WaitForChild("Credits")


local functions = ReplicatedStorage:WaitForChild("Functions")
local requestTowerFunction = functions:WaitForChild("RequestTower")
local towers = ReplicatedStorage:WaitForChild("Towers")
local meleeTowers = towers:WaitForChild("Melee")
local rangedTowers = towers:WaitForChild("Ranged")
local spawnTowerFunction = functions:WaitForChild("SpawnTower")
local sellTowerFunction = functions:WaitForChild("SellTower")
local getDataFunction = functions:WaitForChild("GetData")

local gui = script.Parent
local info = workspace:WaitForChild("Info")


local tower = {}

local rangeIndicators = {}

local towerGuiVisibility = {}

local placedTowerTypes = {}
local upgradedTowerOrigins = {}


local smoothMousePosition = Vector2.new()
local smoothnessFactor = 0.15

local function SmoothMousePosition(newMousePosition)
	smoothMousePosition = smoothMousePosition:Lerp(newMousePosition, smoothnessFactor)
	return smoothMousePosition
end

local function MouseRaycast(exclude)
	local mousePosition = UserInputService:GetMouseLocation()
	local smoothMousePos = SmoothMousePosition(mousePosition)
	local mouseRay = camera:ViewportPointToRay(smoothMousePos.X, smoothMousePos.Y)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = exclude
	
	local raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
	return raycastResult, smoothMousePos
end


local function CreateRangeIndicator(tower)
	local config = tower.Config

	for _, indicator in ipairs(rangeIndicators) do
		indicator:Destroy()
	end

	table.clear (rangeIndicators)

	local hitboxesFolder = tower:FindFirstChild("MainHitboxCopy")

	for _, hitbox in ipairs(hitboxesFolder:GetChildren()) do
		if hitbox:IsA("BasePart") then
			local clonedHitbox = hitbox:Clone()
			local weld = Instance.new("WeldConstraint")
			clonedHitbox.CFrame = tower.HumanoidRootPart.CFrame *CFrame.new(config.XCframe.Value,config.YCframe.Value,config.ZCframe.Value) * CFrame.Angles(0, math.rad(180), 0)
			weld.Part0 = tower.HumanoidRootPart
			weld.Part1 = clonedHitbox
			weld.Parent = tower.HumanoidRootPart


			local marker = Instance.new("BoolValue")
			marker.Name = "IsWelded"
			marker.Value = true
			marker.Parent = clonedHitbox

			clonedHitbox.Anchored = true
			clonedHitbox.CanCollide = false
			clonedHitbox.CanQuery = false
			clonedHitbox.CanTouch = false
			clonedHitbox.Transparency = 0.8

			clonedHitbox.Parent = workspace.Camera

			table.insert(rangeIndicators, clonedHitbox)

		end
	end
end


local function PartTransparency(number)
	for i, tower in pairs(workspace.Towers:GetChildren()) do
		for i, part in pairs(tower:GetChildren()) do
			if part.Name == "Border" then
				part.Transparency = number
			end
		end
	end
end

local function RemovePlaceHolderTower()
	if towerToSpawn then
		towerToSpawn:Destroy()
		towerToSpawn = nil
		rotation = 0
		gui.Controls.Visible = false
		PartTransparency(0.99)
	end
end


local function AddPlaceHolderTower(name)
	local towerExists = meleeTowers:FindFirstChild(name) or rangedTowers:FindFirstChild(name)
	if towerExists and (not placedTowerTypes[name] or placedTowerTypes[name] <= 0) then
		RemovePlaceHolderTower()
		towerToSpawn = towerExists:Clone()
		towerToSpawn.Parent = workspace

		for i, object in ipairs(towerToSpawn:GetDescendants()) do
			if object:IsA("BasePart") then
				object.Anchored = true
				object.CollisionGroup = "Tower"
				object.Material = Enum.Material.ForceField
			end
			PartTransparency(1)
		end

		gui.Controls.Visible = true
	end
end

local function ColorPlaceholderTower(color)
	for i, object in ipairs(towerToSpawn:GetDescendants()) do
		if object:IsA("BasePart") then
			object.CollisionGroup = "Tower"
			object.Color = color
		end
	end
end



local function CreateTowerButton(tower, parent)
    local button = gui.Towers.ImageUI.Template:Clone()
    local config = tower:WaitForChild("Config")

    button.Name = tower.Name
    button.Image = config.Image.Texture
    button.Visible = true
    button.Price.Text = config.Price.Value

    button.Parent = gui.Towers.ImageUI
    button.Activated:Connect(function()
        local allowedToSpawn = requestTowerFunction:InvokeServer(tower.Name)
        if allowedToSpawn then
            AddPlaceHolderTower(tower.Name)
        end
    end)

    return button
end

local function SetupTowerButtons()
	local playerData = getDataFunction:InvokeServer()
	if not playerData or not playerData.SelectedTowers then
		warn("Failed to get player data or SelectedTowers is missing")
		return
	end

	for _, towerName in ipairs(playerData.SelectedTowers) do
		local tower = meleeTowers:FindFirstChild(towerName) or rangedTowers:FindFirstChild(towerName)
		if tower then
			CreateTowerButton(tower, gui.Towers.ImageUI)
		else
			warn("Tower not found:", towerName)
		end
	end
end



--[[for i, tower in pairs(rangedTowers:GetChildren()) do
	if tower:IsA("Model") then
		local button = gui.Towers.ImageUI.Template:Clone()
		local config = tower:WaitForChild("Config")

		button.Name = tower.Name
		button.Image = config.Image.Texture
		button.Visible = true
		button.Price.Text = config.Price.Value

		button.Parent = gui.Towers.ImageUI
		button.Activated:Connect(function()
			local allowedToSpawn = requestTowerFunction:InvokeServer(tower.Name)
			if allowedToSpawn then
				AddPlaceHolderTower(tower.Name)
			end
		end)
	end
end]]

-- Function to check if the tower is of Melee or Ranged type
local function IsMeleeTower(towerName)
	return meleeTowers:FindFirstChild(towerName) ~= nil
end

-- Function to select tower showing the UI
local function toggleTowerInfo()
	workspace.Camera:ClearAllChildren()
	gui.Towers.TextUI.Title.Text = "Deployment Limit:" .. (maxTowers - placedTowers)
	if selectedTower then
		CreateRangeIndicator(selectedTower)
		gui.Selection.Visible = true

		local config = selectedTower.Config
		gui.Selection.Stats.Attack.Attack.Text = config.Damage.Value
		gui.Selection.Stats.Defense.Defense.Text = config.Defense.Value
		gui.Selection.Stats.Immunity.Immunity.Text = config.Immunity.Value
		gui.Selection.Stats.Block.Block.Text = config.Block.Value
		gui.Selection.Title.TowerName.Text = selectedTower.Name
		gui.Selection.Stats.Range.Image = config.ImageNewRange.Image
		gui.Selection.Title.TowerImage.Image = config.Image.Texture
		gui.Selection.Title.TowerType.Image = config.TowerType.Texture
		gui.Selection.Title.OwnerName.Text = config.Owner.Value

		if config.Owner.Value == Players.LocalPlayer.Name then
			gui.Selection.Action.Visible = true

			-- Check the upgrade level and show appropriate buttons
			local upgradeLevel = config:FindFirstChild("UpgradeLevel")
			if upgradeLevel then
				if upgradeLevel.Value == 0 then
					gui.Selection.Action.E1.Visible = true
					gui.Selection.Action.E2.Visible = false
				elseif upgradeLevel.Value == 1 then
					gui.Selection.Action.E1.Visible = false
					gui.Selection.Action.E2.Visible = true
				else
					gui.Selection.Action.E1.Visible = false
					gui.Selection.Action.E2.Visible = false
				end
			else
				-- If UpgradeLevel doesn't exist, assume it's a new tower
				gui.Selection.Action.E1.Visible = true
				gui.Selection.Action.E2.Visible = false
			end
		else
			gui.Selection.Action.Visible = false
		end
	else
		gui.Selection.Visible = false
	end
end

local function UpgradeTower(upgradeLevel)
	if selectedTower then
		local upgradeTower = selectedTower.Config.Upgrade.Value
		local allowedToUpgrade = spawnTowerFunction:InvokeServer(upgradeTower.Name, selectedTower.PrimaryPart.CFrame, selectedTower)

		if allowedToUpgrade then
			-- Store the original tower type if it's the first upgrade
			if not upgradedTowerOrigins[selectedTower.Name] then
				upgradedTowerOrigins[upgradeTower.Name] = selectedTower.Name
			else
				-- For subsequent upgrades, maintain the original tower type
				upgradedTowerOrigins[upgradeTower.Name] = upgradedTowerOrigins[selectedTower.Name]
			end

			selectedTower = allowedToUpgrade

			-- Set the upgrade level
			local newUpgradeLevel = Instance.new("IntValue")
			newUpgradeLevel.Name = "UpgradeLevel"
			newUpgradeLevel.Value = upgradeLevel
			newUpgradeLevel.Parent = selectedTower.Config
			toggleTowerInfo()
		end
	end
end

local function spawnNewTower()
	if canPlace then
		local placedTower = spawnTowerFunction:InvokeServer(towerToSpawn.Name, towerToSpawn.PrimaryPart.CFrame)
		if placedTower then
			placedTowers += 1
			placedTowerTypes[towerToSpawn.Name] = (placedTowerTypes[towerToSpawn.Name] or 0) + 1

			-- Remove tower button from UI
			local towerButton = gui.Towers.ImageUI:FindFirstChild(towerToSpawn.Name)
			if towerButton then
				towerButton.Visible = false
			end

			local placedTowerModel = workspace.Towers:WaitForChild(placedTower.Name, 5)
			if placedTowerModel then
				selectedTower = placedTowerModel

				-- Set initial upgrade level
				local upgradeLevel = Instance.new("IntValue")
				upgradeLevel.Name = "UpgradeLevel"
				upgradeLevel.Value = 0
				upgradeLevel.Parent = selectedTower.Config

				toggleTowerInfo()
			end
			RemovePlaceHolderTower()
		end
	end
end

gui.Controls.Cancel.Activated:Connect(RemovePlaceHolderTower)


gui.Selection.Action.E1.Activated:Connect(function()
	UpgradeTower(1)
end)

gui.Selection.Action.E2.Activated:Connect(function()
	UpgradeTower(2)
end)

gui.Selection.Action.RETREAT.Activated:Connect(function()
	if selectedTower then
		local soldTower = sellTowerFunction:InvokeServer(selectedTower)
		if soldTower then
			placedTowers -= 1

			-- Determine the original tower type
			local originalTowerType = upgradedTowerOrigins[selectedTower.Name] or selectedTower.Name

			placedTowerTypes[originalTowerType] = (placedTowerTypes[originalTowerType] or 1) - 1

			-- Add tower button back to UI if all of this type have been sold
			if placedTowerTypes[originalTowerType] <= 0 then
				local towerButton = gui.Towers.ImageUI:FindFirstChild(originalTowerType)
				if towerButton then
					towerButton.Visible = true
				end
			end

			-- Clear the upgrade origin if it exists
			upgradedTowerOrigins[selectedTower.Name] = nil

			selectedTower = nil
			toggleTowerInfo()
		end
	end
end)


local towerspawn = true
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if towerToSpawn then
		if input.UserInputType == Enum.UserInputType.MouseButton1 and towerspawn == true then
			towerspawn = false
			spawnNewTower()
			task.wait(0.05)
			towerspawn = true
			
		elseif input.UserInputType == Enum.UserInputType.Touch and towerspawn == true then
			local timeSinceLastTouched = tick() - lastTouch
			if timeSinceLastTouched <= 0.25 then
				towerspawn = false
				-- double tapped
				spawnNewTower()
				task.wait(0.05)
				towerspawn = true
			end
			lastTouch = tick()
			
		elseif input.KeyCode == Enum.KeyCode.R then
			rotation += 90
		elseif input.KeyCode == Enum.KeyCode.C then
			RemovePlaceHolderTower()
		end
		
	elseif hoveredInstance and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		local model = hoveredInstance:FindFirstAncestorOfClass("Model")

		if model and model.Parent == workspace.Towers then
			selectedTower = model
		else
			selectedTower = nil
		end

		toggleTowerInfo()
	end
end)

RunService.RenderStepped:Connect(function()
	local result = MouseRaycast({towerToSpawn})
	if result and result.Instance then
		if towerToSpawn then
			hoveredInstance = nil
			local parent = result.Instance.Parent
			local inTowerArea = false
			local isHigherFloor = false

			while parent do
				if parent.Name == "TowerArea" then
					if result.Instance:IsDescendantOf(parent:FindFirstChild("HigherFloor")) then
						isHigherFloor = true
					end
					inTowerArea = true
					break
				end
				parent = parent.Parent
			end

			if inTowerArea then
				if (isHigherFloor and not IsMeleeTower(towerToSpawn.Name)) or (not isHigherFloor and IsMeleeTower(towerToSpawn.Name)) then
					canPlace = true
					ColorPlaceholderTower(Color3.new(0, 1, 0))
				else
					canPlace = false
					ColorPlaceholderTower(Color3.new(1, 0, 0))
				end
			else
				canPlace = false
				ColorPlaceholderTower(Color3.new(1, 0, 0))
			end

			local targetPart = result.Instance
			local targetCF = targetPart.CFrame
			local towerHeight = towerToSpawn.Humanoid.HipHeight + (towerToSpawn.PrimaryPart.Size.Y / 2) + 1
			local placeCFrame = CFrame.new(targetCF.Position + Vector3.new(0, towerHeight, 0)) * CFrame.Angles(0, math.rad(rotation), 0)

			towerToSpawn:SetPrimaryPartCFrame(placeCFrame)
		else
			hoveredInstance = result.Instance
		end
	else
		hoveredInstance = nil
	end
end)



local function DisplayEndScreen(status)
	local screen = gui.EndScreen
	
	if status == "OPERATION FAILED" then
		
		
		screen.Failure:Play()
		screen.Content.Title.TextColor3 = Color3.new(1, 1, 1)
		screen.ContentVictory.Visible = false
		
		
	elseif status == "VICTORY" then
		
		
		screen.Victory:Play()
		screen.Content.Title.TextColor3 = Color3.new(1, 1, 1)
		screen.ImageColor3 = Color3.new(1, 1, 1)
		screen.BackgroundColor3 = Color3.new(1,1,1)
		screen.Content.Loss.Visible = false
		screen.Content.Title.Visible = false
	end
	
	local info = workspace.Info
	local studs = math.round(info.WaveCount.Value / 2)
	if info.Message.Value == "VICTORY" then
		studs = 400
	end
	
	screen.ContentVictory.Studs.Text = "Studs: " .. studs
	screen.Visible = true
	
	local events = ReplicatedStorage:WaitForChild("Events")
	local exitEvent = events:WaitForChild("ExitGame")
	local clicked
	clicked = screen.Exit.Activated:Connect(function()
		clicked:Disconnect()
		exitEvent:FireServer()
		screen.Visible = false
	end)
end

local function SetupGameGui()
	if not info.GameRunning.Value then
		return
	end
	
	gui.Voting.Visible = false
	gui.Info.Health.Visible = true
	gui.Info.Stats.Visible = true
	gui.Towers.Visible = true
	
	local map = workspace.Map:FindFirstChildOfClass("Folder")
	if map then

		health.Setup(map:WaitForChild("Base"), gui.Info.Health)
	else
		workspace.Map.ChildAdded:Connect(function(newMap)
			health.Setup(newMap:WaitForChild("Base"), gui.Info.Health)
		end)
	end
	workspace.Mobs.ChildAdded:Connect(function(mob)
		health.Setup(mob)
	end)
	
	


	info.WaveCount.Changed:Connect(function(change)
		gui.Info.Stats.EnemyCount.Text = "Wave:" .. change
	end)

	credit.Changed:Connect(function(change)
		gui.Info.Stats.Credits.Text = "Credits: " .. credit.Value
	end)

	gui.Info.Stats.Credits.Text = "Credits: " .. credit.Value


	gui.Towers.TextUI.Title.Text = "Deployment Limit:" .. (maxTowers - placedTowers)
	
	SetupTowerButtons()

end

local function SetupVoteGui()
	if not info.Voting.Value then
		return
	end
	
	
	gui.Voting.Visible = true
	local events = ReplicatedStorage:WaitForChild("Events")
	local voteEvent = events:WaitForChild("VoteForMap")
	local voteCountUpdate = events:WaitForChild("UpdateVoteCount")
	
	
	-- toggle voting
	--receive button presses
	local maps = gui.Voting.Maps:GetChildren()
	
	for i, button in ipairs(maps) do
		if button:IsA("ImageButton") then
			button.Activated:Connect(function()
				voteEvent:FireServer(button.Name)
			end)
		end
	end
	
	voteCountUpdate.OnClientEvent:Connect(function(mapScores)
		for name, voteInfo in pairs(mapScores) do
			local button = gui.Voting.Maps:FindFirstChild(name)
			if button then
				button.Vote.Text = #voteInfo
			end
			
		end
	end)
end



local function LoadGui()
	gui.Info.Message.Text = info.Message.Value
	info.Message.Changed:Connect(function(change)
		gui.Info.Message.Text = change
		if change == "" then
			gui.Info.Message.Visible = false
		else
			gui.Info.Message.Visible = true

			if change == "VICTORY" or change == "OPERATION FAILED" then
				DisplayEndScreen(change)
			end
		end
	end)
	
	SetupVoteGui()
	SetupGameGui()
	
	info.GameRunning.Changed:Connect(SetupGameGui)
	info.Voting.Changed:Connect(SetupVoteGui)
	
end

LoadGui()