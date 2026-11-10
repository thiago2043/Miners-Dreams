local Catalogo = require(game:GetService("ReplicatedStorage").Shared.CatalogoMaquinas)
local Template = require(script.Parent.Template)
local Premios = require(script.Parent.PremiosRenascimento)
local Migracao = {}

local function copiar(valor)
	if type(valor) ~= "table" then return valor end
	local novo = {}
	for chave, item in valor do novo[chave] = copiar(item) end
	return novo
end

local function filtrarPecas(pecas)
	if pecas == nil then return end
	assert(type(pecas) == "table", "Lista de pecas invalida.")
	for i = #pecas, 1, -1 do
		assert(type(pecas[i]) == "table", "Registro de peca invalido.")
		if not Catalogo[pecas[i].MaquinaId] then table.remove(pecas, i) end
	end
end

local function limpar(dados)
	for _, campo in { "Inventory", "InventarioPersonalizado" } do
		local inventario = dados[campo]
		if inventario ~= nil then
			assert(type(inventario) == "table", "Inventario invalido.")
			for id in inventario do
				if not Catalogo[id] then inventario[id] = nil end
			end
		end
	end
	filtrarPecas(dados.MaquinasColocadas)
	if dados.Blueprints ~= nil then
		assert(type(dados.Blueprints) == "table", "Blueprints invalidos.")
		for i = #dados.Blueprints, 1, -1 do
			local blueprint = dados.Blueprints[i]
			assert(type(blueprint) == "table" and type(blueprint.Pecas) == "table", "Blueprint invalido.")
			filtrarPecas(blueprint.Pecas)
			if #blueprint.Pecas == 0 then table.remove(dados.Blueprints, i) end
		end
	end
end

-- Trabalha em uma copia para uma falha nao alterar o perfil que ainda pode ser salvo.
function Migracao.Preparar(dados)
	assert(type(dados) == "table", "Perfil invalido.")
	local novo = {}
	for chave, valor in dados do
		if Template[chave] ~= nil or chave == "BackupGrade4" or chave == "BackupHitboxes" or chave == "BackupHitboxesV2" then
			novo[chave] = copiar(valor)
		end
	end
	limpar(novo)
	Premios.Migrar(novo)
	if novo.BackupGrade4 ~= nil then
		assert(type(novo.BackupGrade4) == "table", "Backup de grade invalido.")
		limpar(novo.BackupGrade4)
	end
	return novo
end

return Migracao
