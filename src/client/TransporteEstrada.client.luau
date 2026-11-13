local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Mapa = require(game:GetService("ReplicatedStorage").Shared.Mapa)

local jogador = Players.LocalPlayer
local estrada = workspace:WaitForChild("Cenario"):WaitForChild("Estrada")
local consulta = RaycastParams.new()
consulta.RespectCanCollide = true
consulta.FilterType = Enum.RaycastFilterType.Exclude
local personagemIgnorado

local conexao = RunService.PreSimulation:Connect(function(delta)
	local personagem = jogador.Character
	local humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
	local raiz = humanoide and humanoide.RootPart
	if not raiz or raiz.Anchored or humanoide.Health <= 0 or humanoide.Sit
		or humanoide.Jump or humanoide.FloorMaterial == Enum.Material.Air then return end

	local deslocamento = Mapa.DeslocamentoEstrada(raiz.Position, Mapa.Velocidade * math.min(delta, .05))
	if not deslocamento then return end

	if personagem ~= personagemIgnorado then
		personagemIgnorado = personagem
		consulta.FilterDescendantsInstances = {personagem}
	end
	local altura = raiz.Size.Y / 2 + humanoide.HipHeight
	if humanoide.RigType == Enum.HumanoidRigType.R6 then
		local perna = personagem:FindFirstChild("Left Leg")
		if not perna then return end
		altura += perna.Size.Y
	end
	local apoio = workspace:Raycast(raiz.Position, Vector3.new(0, -altura - .5, 0), consulta)
	if apoio and apoio.Instance.Parent == estrada and apoio.Instance.Name == "Pista" then
		raiz.CFrame += deslocamento
	end
end)

script.Destroying:Connect(function() conexao:Disconnect() end)
