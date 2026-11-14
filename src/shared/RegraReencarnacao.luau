local ProgressaoLogaritmica = require(script.Parent.ProgressaoLogaritmica)
local RegraReencarnacao = {}
RegraReencarnacao.__index = RegraReencarnacao
RegraReencarnacao.PrimeiroRequisito = "1000000000000000000000"

-- 1Sx = 10^21; cada marco seguinte multiplica o requisito por mil.
function RegraReencarnacao.new()
	return setmetatable({ _escala = ProgressaoLogaritmica.new(RegraReencarnacao.PrimeiroRequisito) }, RegraReencarnacao)
end

local function inteiro(valor, minimo)
	return type(valor) == "number" and valor >= minimo and valor % 1 == 0 and valor < 2 ^ 53 - 1
end

-- Reencarnacoes conta operacoes; vidas conta o total com os saltos. Um salto de cinco vidas aumenta
-- o requisito somente uma vez. O cliente consulta esta regra, mas o servidor a calcula novamente.
function RegraReencarnacao:Calcular(saldo, reencarnacoes, vidas)
	if not inteiro(reencarnacoes, 0) or not inteiro(vidas, 1) then return nil, "Progressao indisponivel." end
	local avaliacao, erro = self._escala:Avaliar(saldo)
	if not avaliacao then return nil, erro end
	local marcos=avaliacao.MarcosAtingidos>0 and math.floor((avaliacao.MarcosAtingidos-1)/3)+1 or 0
	local disponiveis = math.max(0, marcos - reencarnacoes)
	if vidas + disponiveis >= 2 ^ 53 - 1 then return nil, "Limite de vidas atingido." end
	local expoente = 21 + reencarnacoes*3
	return {
		Reencarnacoes = reencarnacoes, Vidas = vidas, VidasDisponiveis = disponiveis,
		VidasPuladas = math.max(0, disponiveis - 1), VidaDestino = vidas + disponiveis,
		ExpoenteRequisito = expoente, ExpoenteMarcoAtual = disponiveis > 0 and expoente + (disponiveis - 1)*3 or 0,
		ExpoenteProximoMarco = disponiveis > 0 and expoente + disponiveis*3 or expoente,
		Fracao = disponiveis > 0 and ((avaliacao.MarcosAtingidos-1)%3+avaliacao.Fracao)/3 or self._escala:FracaoAteMarco(saldo, reencarnacoes*3),
	}
end

return RegraReencarnacao
