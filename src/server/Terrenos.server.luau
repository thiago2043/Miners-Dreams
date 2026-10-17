-- Cria as plots vazias e acompanha entrada/saida de jogadores; a restauracao aguarda os dados sem bloquear a
-- criacao dos terrenos.
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
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
-- A raiz quadrada arredondada para cima distribui as plots em linhas e colunas. O espacamento de 80 studs
-- deixa separacao entre pisos de 64 studs.
local colunas = math.ceil(math.sqrt(quantidadeTerrenos))
local distanciaEntreTerrenos = 80

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

-- Converte cada id em coluna pelo resto da divisao e linha pela divisao inteira. O deslocamento centraliza
-- as colunas e coloca os pisos sobre a Baseplate.
for id = 1, quantidadeTerrenos do
	local coluna = (id - 1) % colunas
	local linha = math.floor((id - 1) / colunas)
	local x = (coluna - (colunas - 1) / 2) * distanciaEntreTerrenos
	local z = 80 + linha * distanciaEntreTerrenos
	table.insert(terrenos, Terreno.new(id, CFrame.new(x, alturaChao + 0.5, z), pastaTerrenos))
end

-- Conecta entradas futuras e, abaixo, atribui plots aos jogadores ja presentes. A guarda dentro de
-- atribuirTerreno evita entregar duas plots ao mesmo jogador.
Players.PlayerAdded:Connect(atribuirTerreno)
Players.PlayerRemoving:Connect(liberarTerreno)

for _, jogador in Players:GetPlayers() do
	atribuirTerreno(jogador)
end
