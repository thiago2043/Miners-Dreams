local R = game:GetService("ReplicatedStorage")
local Catalogo = require(R.Shared.CatalogoMaquinas)
local Personalizacao = require(R.Shared.PersonalizacaoMaquina)
local Premios = {}

function Premios.Entregar(dados)
	local transicoes = dados.Transicoes or 0
	if transicoes == 0 then return end
	local entregues = dados.RecompensasAscensao or {}
	local catalogadas = {}
	for id, item in Catalogo do
		local marco = item.TransicaoAscensao
		if item.Obtencao == "Ascensão" and marco then
			assert(type(marco) == "number" and marco >= 1 and marco % 1 == 0 and not catalogadas[marco],
				"Cada transição deve ter uma única máquina de Ascensão.")
			catalogadas[marco] = id
		end
	end
	for marco, id in catalogadas do
		local chave = tostring(marco)
		if marco <= transicoes and not entregues[chave] then
			local quantidade = (dados.Inventory[id] or 0) + 1
			assert(quantidade >= 1 and quantidade < 2^53 and quantidade % 1 == 0, "Estoque de Ascensão inválido.")
			dados.Inventory[id], entregues[chave] = quantidade, true
		end
	end
	dados.RecompensasAscensao = entregues
end

function Premios.Preservar(novo, anterior)
	local porTipo = {}
	for _, registro in anterior.MaquinasColocadas or {} do
		local item = Catalogo[registro.MaquinaId]
		if item and item.Obtencao == "Ascensão" then
			local registros = porTipo[registro.MaquinaId] or {}
			table.insert(registros, registro)
			porTipo[registro.MaquinaId] = registros
		end
	end
	for id, item in Catalogo do
		if item.Obtencao ~= "Ascensão" then continue end
		local quantidade = (anterior.Inventory or {})[id] or 0
		local variantes = {}
		local estoque = (anterior.InventarioPersonalizado or {})[id] or {}
		assert(quantidade >= #estoque and quantidade % 1 == 0, "Estoque de Ascensão inválido.")
		for _, variante in estoque do
			table.insert(variantes, Personalizacao.new(variante):ObterDados())
		end
		for _, registro in porTipo[id] or {} do
			quantidade += 1
			if registro.Modificacoes and next(registro.Modificacoes) then
				table.insert(variantes, Personalizacao.new(registro.Modificacoes):ObterDados())
			end
		end
		assert(quantidade < 2^53, "Limite de estoque de Ascensão atingido.")
		novo.Inventory[id] = quantidade
		if #variantes > 0 then novo.InventarioPersonalizado[id] = variantes end
	end
end

return Premios
