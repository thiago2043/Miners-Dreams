local I=require(script.Parent.InteiroGrande)
local U=require(script.Parent.Upgrades)
local E={}
function E.Nivel(jogador,id)
	local n=jogador and jogador:GetAttribute("Upgrade_"..id)
	return U.Valido(n) and n or 0
end
function E.Extracao(valor,nivel) return I.multiplicarArredondado(valor,U.Fator(nivel)) end
function E.Fundicao(valor,nivel) return I.multiplicarArredondado(valor,U.Fator(nivel)) end
function E.Velocidade(velocidade,nivel) return velocidade*(1+nivel*U.PercentualPorNivel/100) end
function E.MultiplicadorTotalModificador(componente)
	local fator = componente.Multiplicador or "1"
	if componente.MultiplicadoresFaixas then return fator end
	local total = fator
	for _ = 2, componente.Etapas or 1 do
		total = I.multiplicarDecimal(total, fator)
	end
	return total
end
function E.UsosModificador(limite,nivel)
	if limite == nil then return nil end
	return math.min(2^53 - 1, math.floor(limite * (1 + nivel*U.PercentualPorNivel/100) + .5))
end
return E
