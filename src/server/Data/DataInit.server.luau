-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ProfileStore
local ProfileStore = require(ServerScriptService.Libraries.ProfileStore)

local function GetStoreName()
	return RunService:IsStudio() and "Test" or "Live"
end

local Template = require(ServerScriptService.Data.Template)
local DataManager = require(ServerScriptService.Data.DataManager)
local Construcao = require(ServerScriptService:WaitForChild("Construcao"))

-- Access profile store
local PlayerStore = ProfileStore.New(GetStoreName(), Template)

-- Add leaderstats and sycronhronize player data
local function Initialize(player:Player, profile: typeof(PlayerStore:StartSessionAsync()))
	
	DataManager.ObterDados(player):Sincronizar()

	-- Leaderstats
	local leaderstats = Instance.new("Folder", player)
	leaderstats.Name = "leaderstats"
	
	local Gold = Instance.new("NumberValue", leaderstats)
	Gold.Name = "Gold"
	Gold.Value = profile.Data.Gold
	
	local Gems = Instance.new("NumberValue", leaderstats)
	Gems.Name = "Gems"
	Gems.Value = profile.Data.Gems
	
	-- Sync player data
	--ReplicatedStorage.UpdateGold:FireClient(player, profile.Data.Gold)
	--ReplicatedStorage.UpdateGems:FireClient(player, profile.Data.Gems)
	
	Construcao.Restaurar(player)

end

-- Creates and stores a profile
local function PlayerAdded(player: Player)
	
	-- Start a new profile session
	local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	
	-- Sanity check to ensure profile exists
	if profile ~= nil then
		
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from template
		
		-- Handles session-locking
		profile.OnSessionEnd:Connect(function()
			DataManager.RemoverPerfil(player)
			player:Kick("Data error occured. plase rejoin.")
		end)
		
		-- Save profile for later use
		if player.Parent == Players then
			DataManager.RegistrarPerfil(player, profile)
			Initialize(player, profile)
		else
			profile:EndSession()
		end
		
	else
		-- Server shuts down while player is joining
		player:Kick("Data error occured. plase rejoin.")
	end
	
end

-- Early joiners

for _, player in Players:GetPlayers() do
	task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	profile:EndSession()
	DataManager.RemoverPerfil(player)
end)
