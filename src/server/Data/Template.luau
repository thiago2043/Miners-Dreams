-- Valores de um perfil novo: kit no inventario e terreno vazio. Reconciliar inclui campos ausentes sem apagar
-- o progresso salvo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CatalogoMaquinas = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local inventario = {}
-- Inicia cada tipo do catalogo com quantidade zero e concede abaixo apenas o kit de tres pecas. O
-- modificador continua disponivel para compra, sem unidade inicial.
for maquinaId in CatalogoMaquinas do inventario[maquinaId] = 0 end
inventario.MineradoraBasica = 1
inventario.EsteiraBasica = 1
inventario.FornalhaBasica = 1

return {
	-- Dinheiro e a moeda da fabrica em texto decimal. Gold e Gems sao numeros do exercicio de dados e nao
	-- financiam as compras do jogo.
	Dinheiro = "0", Gold = 10, Gems = 5,
	Inventory = inventario,
	-- As variantes guardam apenas diferencas por unidade; MaquinasColocadas guarda tipo, canto e orientacao das
	-- pecas que o jogador realmente colocou no terreno.
	InventarioPersonalizado = {},
	MaquinasColocadas = {},
}
