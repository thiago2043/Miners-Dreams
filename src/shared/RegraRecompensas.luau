local Premios = require(script.Parent.RecompensasRenascimento)
local Regra = {}
local ordem = { Soltador = 1, Vendedor = 2, Modificador = 3 }

function Regra.Garantidas(ciclo)
	assert(type(ciclo) == "number" and ciclo >= 1 and ciclo % 1 == 0, "Ciclo invalido.")
	local marco = math.min(50, math.ceil(ciclo / 5) * 5)
	local lote = {}
	for _, premio in Premios do
		if premio.Lote == marco then table.insert(lote, premio) end
	end
	table.sort(lote, function(a, b)
		if ordem[a.Tipo] ~= ordem[b.Tipo] then return ordem[a.Tipo] < ordem[b.Tipo] end
		return (a.Codigo or a.Id) < (b.Codigo or b.Id)
	end)
	local passo = (ciclo - 1) % 5 + 1
	local duplas = 10 - #lote
	local quantidade = if passo > duplas then 2 else 1
	local inicio = passo - 1 + math.max(0, passo - 1 - duplas)
	local resultado = {}
	for i = 1, quantidade do
		table.insert(resultado, lote[(inicio + i - 1) % #lote + 1])
	end
	return resultado
end

return Regra
