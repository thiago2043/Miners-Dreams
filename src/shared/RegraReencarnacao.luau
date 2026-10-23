local ProgressaoLogaritmica = require(script.Parent.ProgressaoLogaritmica)
local RegraReencarnacao = {}
RegraReencarnacao.__index = RegraReencarnacao

-- 1qd usa a escala curta: 10^15. A escala nao depende dos dados nem dos elementos da interface.
function RegraReencarnacao.new()
	return setmetatable({ _escala = ProgressaoLogaritmica.new("1000000000000000") }, RegraReencarnacao)
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
	local disponiveis = math.max(0, avaliacao.MarcosAtingidos - reencarnacoes)
	if vidas + disponiveis >= 2 ^ 53 - 1 then return nil, "Limite de vidas atingido." end
	local expoente = 15 + reencarnacoes
	return {
		Reencarnacoes = reencarnacoes, Vidas = vidas, VidasDisponiveis = disponiveis,
		VidasPuladas = math.max(0, disponiveis - 1), VidaDestino = vidas + disponiveis,
		ExpoenteRequisito = expoente, ExpoenteMarcoAtual = disponiveis > 0 and expoente + disponiveis - 1 or 0,
		ExpoenteProximoMarco = disponiveis > 0 and expoente + disponiveis or expoente,
		Fracao = disponiveis > 0 and avaliacao.Fracao or self._escala:FracaoAteMarco(saldo, reencarnacoes),
	}
end

return RegraReencarnacao
