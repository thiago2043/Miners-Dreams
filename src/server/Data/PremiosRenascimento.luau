local R = game:GetService("ReplicatedStorage")
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
	local disponiveis={}
	for _, premio in Premios do
		local salvo = novo.RecompensasReencarnacao[premio.Id]
		local total = salvo and salvo.Quantidade or 0
		assert(quantidade(total), "Quantidade de recompensa invalida.")
		if total>0 then table.insert(disponiveis,premio) end
		local variantes = {}
		for _, dados in (anterior.InventarioPersonalizado or {})[premio.Id] or {} do
			table.insert(variantes, Personalizacao.new(dados):ObterDados())
		end
		for _, registro in anterior.MaquinasColocadas or {} do
			if registro.MaquinaId==premio.Id and registro.Modificacoes and next(registro.Modificacoes) then
				table.insert(variantes, Personalizacao.new(registro.Modificacoes):ObterDados())
			end
		end
		assert(#variantes<=total, "Variantes de recompensa invalidas.")
		novo.Inventory[premio.Id] = total
		if #variantes>0 then novo.InventarioPersonalizado[premio.Id] = variantes end
	end
	local function entregar(premio)
		local total = novo.Inventory[premio.Id]+1
		assert(quantidade(total), "Limite de recompensas atingido.")
		novo.Inventory[premio.Id] = total
		novo.RecompensasReencarnacao[premio.Id] = {Quantidade=total}
		if total == 1 then table.insert(disponiveis, premio) end
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
			local total = salvo and salvo.Quantidade or 0
			assert(quantidade(total), "Quantidade de recompensa invalida.")
			if total == 0 then
				dados.RecompensasReencarnacao[premio.Id] = {Quantidade=1}
				dados.Inventory[premio.Id] = (dados.Inventory[premio.Id] or 0) + 1
			end
		end
	end
	dados.VersaoRecompensasRenascimento = 1
end
return Recompensas
