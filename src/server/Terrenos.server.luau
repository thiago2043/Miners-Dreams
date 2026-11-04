-- Cria as plots vazias e acompanha entrada/saida de jogadores; a restauracao aguarda os dados sem bloquear a
-- criacao dos terrenos.
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Terreno = require(script.Parent.Terreno)
local Mapa = require(game:GetService("ReplicatedStorage").Shared.Mapa)

local baseplate = workspace:WaitForChild("Baseplate")

assert(
	workspace:FindFirstChild("Terrenos") == nil,
	"Já existe uma pasta Terrenos no Workspace. Confira antes de criar outra."
)

local pastaTerrenos = Instance.new("Folder")
pastaTerrenos.Name = "Terrenos"
pastaTerrenos.Parent = workspace

local quantidadeTerrenos = Mapa.QuantidadePlots

local alturaChao = baseplate.Position.Y + baseplate.Size.Y / 2

local terrenos = {}
local terrenoPorJogador = {}

-- Procura a primeira plot disponivel para um jogador ainda presente e sem terreno. Agenda a restauracao
-- separadamente para nao bloquear a atribuicao e posiciona o personagem que ja existir.
local function atribuirTerreno(jogador)
	if jogador.Parent ~= Players or terrenoPorJogador[jogador] then return end
	for _, terreno in terrenos do
		if terreno:Atribuir(jogador) then
			terrenoPorJogador[jogador] = terreno
			-- A espera pelos recursos da construcao nao deve impedir a criacao e atribuicao das plots.
			task.spawn(function()
				local Construcao = require(ServerScriptService:WaitForChild("Construcao"))
				if terrenoPorJogador[jogador] == terreno then Construcao.Restaurar(jogador) end
			end)
			if jogador.Character then
				local personagem = jogador.Character
				task.spawn(function() terreno:PosicionarPersonagem(personagem) end)
			end
			return
		end
	end
	warn("Nenhum terreno disponível para " .. jogador.Name)
end

-- Consulta o terreno associado ao jogador que saiu, remove essa associacao e pede a liberacao da plot. Nao faz
-- nada quando ele nao chegou a receber um terreno.
local function liberarTerreno(jogador)
	local terreno = terrenoPorJogador[jogador]
	if not terreno then return end
	terrenoPorJogador[jogador] = nil
	terreno:Liberar()
end

-- As origens das duas fileiras fazem as expansoes crescerem para fora da estrada.
for id = 1, quantidadeTerrenos do
	table.insert(terrenos, Terreno.new(id, Mapa.CFramePlot(id, alturaChao + 0.5), pastaTerrenos))
end

-- Conecta entradas futuras e, abaixo, atribui plots aos jogadores ja presentes. A guarda dentro de
-- atribuirTerreno evita entregar duas plots ao mesmo jogador.
Players.PlayerAdded:Connect(atribuirTerreno)
Players.PlayerRemoving:Connect(liberarTerreno)

for _, jogador in Players:GetPlayers() do
	atribuirTerreno(jogador)
end
