local Inteiro = require(script.Parent.InteiroGrande)
local Progressao = require(script.Parent.ProgressaoLogaritmica)

local expoenteInicial = 308
local escala = Progressao.new("1" .. string.rep("0", expoenteInicial))
local RegraAscensao = { PassoAscensao = 100, PassoTransicao = 10 }

function RegraAscensao.Calcular(saldo, ascensoes, transicoes)
	if not Inteiro.eValido(saldo) or type(ascensoes) ~= "number" or type(transicoes) ~= "number"
		or ascensoes < 0 or ascensoes > math.floor((2^53 - expoenteInicial - 100) / RegraAscensao.PassoAscensao) or ascensoes % 1 ~= 0
		or transicoes < ascensoes or transicoes >= 2^53 or transicoes % 1 ~= 0 then return nil end
	local digitos = saldo:gsub("^0+", "")
	local expoente = expoenteInicial + RegraAscensao.PassoAscensao * ascensoes
	local disponiveis = math.max(0, 1 + math.floor((#digitos - 1 - expoente) / RegraAscensao.PassoTransicao))
	if transicoes + disponiveis >= 2^53 then return nil end
	return {
		Ascensoes = ascensoes, Transicoes = transicoes, Disponiveis = disponiveis,
		Expoente = expoente, ProximoMarco = expoente + RegraAscensao.PassoTransicao * disponiveis,
		Fracao = escala:FracaoAteMarco(saldo, expoente - expoenteInicial),
	}
end

return RegraAscensao
