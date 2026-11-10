-- Valores de um perfil novo: kit no inventario e terreno vazio. Reconciliar inclui campos ausentes sem apagar
-- o progresso salvo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CatalogoMaquinas = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local inventario = {}
for maquinaId in CatalogoMaquinas do inventario[maquinaId] = 0 end
inventario.MineradoraBasica = 1
inventario.Esteira2x2 = 10
inventario.FornalhaBasica = 1

return {
	TamanhoBloco = require(ReplicatedStorage.Shared.Medidas).Bloco,
	VersaoHitboxes = 2,
	Dinheiro = "0",
	GeracaoProgresso = 0,
	NomeJogador = "",
	Monitoramento = {Tempo=0,Amostras={},Eventos={},Alteracoes={},Bytes={}},
	Recordes = { Vidas = "1", DinheiroPorSegundo = "0", Minerio = "0", Dinheiro = "0" },
	-- Operacoes e vidas sao contadores diferentes: saltar vidas nao multiplica o custo dos proximos ciclos.
	Reencarnacoes = 0, Vidas = 1,
	Upgrades = {Extracao=0,Fundicao=0,Motores=0,Calibracao=0}, VelocidadeMotores=0, ExpansaoPlot=0, VersaoExpansaoPlot=2,
	-- Quantidades de recompensas permanentes, devolvidas ao inventario a cada renascimento.
	RecompensasReencarnacao = {},
	VersaoRecompensasRenascimento = 1,
	Inventory = inventario,
	-- As variantes guardam apenas diferencas por unidade; MaquinasColocadas guarda tipo, canto e orientacao das
	-- pecas que o jogador realmente colocou no terreno.
	InventarioPersonalizado = {},
	MaquinasColocadas = {},
-- Cada blueprint e um conjunto salvo de pecas com configuracoes e distancias relativas.
  Blueprints = {},
Configuracoes = {},
  Atalhos = {},
  Janelas = {},
}
