local r = require("@lune/roblox")
local sinal = require("./suporte/interface").Sinal
local passo, destruindo = sinal(), sinal()
local estrada = {}
local pista = {Name = "Pista", Parent = estrada}
local apoio = pista
local personagem
local mundo = {WaitForChild = function(_, nome)
	assert(nome == "Cenario")
	return {WaitForChild = function(_, filho) assert(filho == "Estrada"); return estrada end}
end}
function mundo:Raycast(origem, direcao, consulta)
	assert(consulta.RespectCanCollide and consulta.FilterDescendantsInstances[1] == personagem)
	assert(origem.Y == 3 and direcao.Y == -3.5)
	return apoio and {Instance = apoio}
end

local jogador = {}
local carregar = require("./suporte/carregador")({Vector3 = r.Vector3}, {})

-- A trilha deve preservar a posição transversal nas duas curvas e nas quatro junções.
local M = carregar("src/shared/Mapa")
local reta = M.Fim - M.Inicio
for _, raio in {6.1, 8, 10, 12, 13.9} do
	for _, fps in {24, 60, 144} do
		local arco = math.pi * raio
		local distancia = M.Velocidade / fps
		for _, juncao in {0, reta, reta + arco, 2 * reta + arco} do
			local s = juncao - 2
			local posicao = M.Ponto(s, raio) + r.Vector3.new(0, 3, 0)
			for _ = 1, math.ceil((4 + arco) / distancia) do
				s += distancia
				posicao += assert(M.DeslocamentoEstrada(posicao, distancia))
				local esperado = M.Ponto(s, raio) + r.Vector3.new(0, 3, 0)
				assert((posicao - esperado).Magnitude < .01, "A curva desviou a faixa ou a altura")
			end
		end
	end
end
assert(not M.DeslocamentoEstrada(r.Vector3.new(14.1, 3, M.Inicio + 1), 1))
assert(not M.DeslocamentoEstrada(r.Vector3.new(0, 3, M.Fim + 14.1), 1))

local raiz = {Size = r.Vector3.new(2, 2, 1), AssemblyLinearVelocity = r.Vector3.new(9, 0, 6)}
setmetatable(raiz, {__index = function(self, nome) if nome == "Position" then return self.CFrame.Position end end})
local humanoide = {RootPart = raiz, Health = 100, FloorMaterial = r.Enum.Material.SmoothPlastic,
	HipHeight = 2, RigType = r.Enum.HumanoidRigType.R15}
personagem = {FindFirstChildOfClass = function(_, classe) assert(classe == "Humanoid"); return humanoide end}
jogador.Character = personagem
local posicao = r.Vector3.new(13.5, 3, M.Fim - .1)
local pose = r.CFrame.new(posicao) * r.CFrame.Angles(0, 1, 0)
raiz.CFrame = pose

-- O mock do script fornece o sinal do ciclo de vida do LocalScript.
local fonte = require("@lune/fs").readFile("src/client/TransporteEstrada.client.luau")
local ambiente = {
	game = {GetService = function(_, nome)
		return ({Players = {LocalPlayer = jogador}, RunService = {PreSimulation = passo}, ReplicatedStorage = {Shared = {Mapa = {}}}})[nome]
	end},
	script = {Destroying = destruindo}, require = function() return M end,
	Enum = r.Enum, Vector3 = r.Vector3, workspace = mundo, RaycastParams = {new = function() return {} end},
}
require("@lune/luau").load(fonte, {environment = ambiente})()
passo:Fire(1 / 30)
assert(raiz.CFrame == pose + M.DeslocamentoEstrada(posicao, M.Velocidade / 30))
assert(raiz.AssemblyLinearVelocity == r.Vector3.new(9, 0, 6))
raiz.CFrame = pose
humanoide.Jump = true
passo:Fire(1 / 30); assert(raiz.CFrame == pose)
humanoide.Jump, humanoide.FloorMaterial = false, r.Enum.Material.Air
passo:Fire(1 / 30); assert(raiz.CFrame == pose)
humanoide.FloorMaterial, apoio = r.Enum.Material.SmoothPlastic, {Name = "Pista"}
passo:Fire(1 / 30); assert(raiz.CFrame == pose)
apoio = pista
destruindo:Fire()
passo:Fire(1 / 30); assert(raiz.CFrame == pose)
print("TRANSPORTE_ESTRADA_OK: arcos, junções, bordas, apoio e pulo.")
