local R = game:GetService("ReplicatedStorage")
local Premios = require(R.Shared.RecompensasRenascimento)
local Personalizacao = require(R.Shared.PersonalizacaoMaquina)
local Recompensas = {}

local function quantidade(n)
	return type(n)=="number" and n>=0 and n<2^53 and n%1==0
end

-- Trabalha no perfil proposto; uma falha nao altera o ciclo atual.
function Recompensas.Aplicar(novo, anterior, vidas)
	local faltantes={}
	for _, premio in Premios do
		local salvo = novo.RecompensasReencarnacao[premio.Id]
		local total = salvo and salvo.Quantidade or 0
		assert(quantidade(total), "Quantidade de recompensa invalida.")
		if total==0 then table.insert(faltantes,premio) end
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
	for _ = 1, vidas do
		local premio = if #faltantes>0 then table.remove(faltantes,math.random(1,#faltantes)) else Premios[math.random(1,#Premios)]
		local total = novo.Inventory[premio.Id]+1
		assert(quantidade(total), "Limite de recompensas atingido.")
		novo.Inventory[premio.Id] = total
		novo.RecompensasReencarnacao[premio.Id] = {Quantidade=total}
	end
end
return Recompensas
