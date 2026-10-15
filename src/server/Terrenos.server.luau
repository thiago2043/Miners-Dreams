local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Construcao = require(ServerScriptService:WaitForChild("Construcao"))
local Terreno = require(script.Parent.Terreno)

local baseplate = workspace:WaitForChild("Baseplate")

assert(
	workspace:FindFirstChild("Terrenos") == nil,
	"Já existe uma pasta Terrenos no Workspace. Confira antes de criar outra."
)

local pastaTerrenos = Instance.new("Folder")
pastaTerrenos.Name = "Terrenos"
pastaTerrenos.Parent = workspace

local quantidadeTerrenos = Players.MaxPlayers
local colunas = math.ceil(math.sqrt(quantidadeTerrenos))
local distanciaEntreTerrenos = 80

local alturaChao = baseplate.Position.Y + baseplate.Size.Y / 2

local modelosIniciais = {
	workspace:WaitForChild("MineradoraBasica"),
	workspace:WaitForChild("EsteiraBasica"),
	workspace:WaitForChild("FornalhaBasica"),
}

local correiaOriginal = modelosIniciais[2]:WaitForChild("Correia")

local origemDaFabrica = CFrame.new(
	correiaOriginal.Position.X,
	alturaChao,
	correiaOriginal.Position.Z
)

local terrenos = {}
local terrenoPorJogador = {}

local function atribuirTerreno(jogador)
	if jogador.Parent ~= Players or terrenoPorJogador[jogador] then return end
	for _, terreno in terrenos do
		if terreno:Atribuir(jogador, modelosIniciais, origemDaFabrica) then
			terrenoPorJogador[jogador] = terreno
			Construcao.Restaurar(jogador)
			if jogador.Character then
				local personagem = jogador.Character
				task.spawn(function() terreno:PosicionarPersonagem(personagem) end)
			end
			return
		end
	end
	warn("Nenhum terreno disponível para " .. jogador.Name)
end

local function liberarTerreno(jogador)
	local terreno = terrenoPorJogador[jogador]
	if not terreno then return end
	terrenoPorJogador[jogador] = nil
	terreno:Liberar()
end

for id = 1, quantidadeTerrenos do
	local coluna = (id - 1) % colunas
	local linha = math.floor((id - 1) / colunas)
	local x = (coluna - (colunas - 1) / 2) * distanciaEntreTerrenos
	local z = 80 + linha * distanciaEntreTerrenos
	table.insert(terrenos, Terreno.new(id, CFrame.new(x, alturaChao + 0.5, z), pastaTerrenos))
end

Players.PlayerAdded:Connect(atribuirTerreno)
Players.PlayerRemoving:Connect(liberarTerreno)

for _, jogador in Players:GetPlayers() do
	atribuirTerreno(jogador)
end