local R = game:GetService("ReplicatedStorage")
local Catalogo = require(R.Shared.CatalogoMaquinas)
local Premios = require(R.Shared.RecompensasRenascimento)
local Regra = require(R.Shared.RegraRecompensas)
local Personalizacao = require(R.Shared.PersonalizacaoMaquina)
local Recompensas = {}

local function quantidade(n)
	return type(n)=="number" and n>=0 and n<2^53 and n%1==0
end

-- Trabalha no perfil proposto; uma falha nao altera o ciclo atual.
function Recompensas.Aplicar(novo, anterior, vidas)
	assert(quantidade(vidas) and vidas >= 1, "Quantidade de vidas invalida.")
	local naPlot, variantesNaPlot = {}, {}
	for _, registro in anterior.MaquinasColocadas or {} do
		local id = registro.MaquinaId
		local item = Catalogo[id]
		if item and item.Obtencao then
			naPlot[id] = (naPlot[id] or 0) + 1
			if registro.Modificacoes and next(registro.Modificacoes) then
				variantesNaPlot[id] = variantesNaPlot[id] or {}
				table.insert(variantesNaPlot[id], registro.Modificacoes)
			end
		end
	end
	local function devolver(id, total)
		assert(quantidade(total), "Quantidade de peça permanente inválida.")
		local variantes = {}
		for _, origem in {(anterior.InventarioPersonalizado or {})[id] or {}, variantesNaPlot[id] or {}} do
			for _, dados in origem do table.insert(variantes, Personalizacao.new(dados):ObterDados()) end
		end
		assert(#variantes <= total, "Variantes de recompensa invalidas.")
		novo.Inventory[id] = total
		if #variantes > 0 then novo.InventarioPersonalizado[id] = variantes end
	end
	for id, item in Catalogo do
		if item.Receita then
			local estoque = (anterior.Inventory or {})[id] or 0
			assert(quantidade(estoque), "Estoque de craft inválido.")
			devolver(id, estoque + (naPlot[id] or 0))
		end
	end
	local disponiveis={}
	for _, premio in Premios do
		local salvo = novo.RecompensasReencarnacao[premio.Id]
		devolver(premio.Id, if salvo == nil then 0 else salvo.Quantidade)
		if salvo then table.insert(disponiveis, premio) end
	end
	local function entregar(premio)
		local total = novo.Inventory[premio.Id]+1
		assert(quantidade(total), "Limite de recompensas atingido.")
		novo.Inventory[premio.Id] = total
		if not novo.RecompensasReencarnacao[premio.Id] then table.insert(disponiveis, premio) end
		novo.RecompensasReencarnacao[premio.Id] = {Quantidade=total}
	end
	for _, premio in Regra.Garantidas((anterior.Reencarnacoes or 0) + 1) do
		entregar(premio)
	end
	for _ = 2, vidas do
		entregar(disponiveis[math.random(1,#disponiveis)])
	end
end

function Recompensas.Migrar(dados)
	if dados.VersaoRecompensasRenascimento == 1 then return end
	dados.RecompensasReencarnacao = dados.RecompensasReencarnacao or {}
	dados.Inventory = dados.Inventory or {}
	local ciclos = dados.Reencarnacoes or 0
	assert(quantidade(ciclos), "Ciclos de renascimento invalidos.")
	-- Recupera apenas tipos faltantes. As copias e personalizacoes antigas permanecem no perfil.
	for ciclo = 1, math.min(ciclos, 50) do
		for _, premio in Regra.Garantidas(ciclo) do
			local salvo = dados.RecompensasReencarnacao[premio.Id]
			if salvo == nil then
				dados.RecompensasReencarnacao[premio.Id] = {Quantidade=1}
				dados.Inventory[premio.Id] = (dados.Inventory[premio.Id] or 0) + 1
			else
				assert(quantidade(salvo.Quantidade), "Quantidade de recompensa invalida.")
			end
		end
	end
	dados.VersaoRecompensasRenascimento = 1
end
return Recompensas
