local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CatalogoMaquinas = require(ReplicatedStorage.Shared.CatalogoMaquinas)
local inventario = {}
for maquinaId in CatalogoMaquinas do inventario[maquinaId] = 0 end

return {
	Dinheiro = "0", Gold = 10, Gems = 5,
	Inventory = inventario,
	MaquinasColocadas = {},
}
