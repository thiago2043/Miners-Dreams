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
function E.Limites(config,nivel)
	return config.ValorMinimo and I.multiplicarArredondado(config.ValorMinimo,({"1","0.8","0.6","0.4","0.2","0"})[nivel+1]),
		config.ValorMaximo and I.multiplicarArredondado(config.ValorMaximo,U.Fator(nivel))
end
return E
